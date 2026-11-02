-- Self-contained mission state machine. Requires config.lua loaded first.
OPEN_DOOR={phase='setup',launched=false,boarded=false,onboard=0,playerSeen=false}
local S,C=OPEN_DOOR,assert(OPEN_DOOR_CONFIG,'Missing Open Door config')
S.config=C
local function say(t)trigger.action.outTextForCoalition(2,'OPEN DOOR: '..t,18);env.info('[OPEN_DOOR] '..t)end
local function alive(n)local u=Unit.getByName(n);if u and u:isExist() and u:getLife()>0 then return u end end
local function distance(a,b)return math.sqrt((a.x-b.x)^2+(a.z-b.z)^2)end
local function point(p)return {x=p.x,y=land.getHeight({x=p.x,y=p.y}),z=p.y}end
local function speed(u)local v=u:getVelocity();return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)end
local function copy(t)if type(t)~='table'then return t end;local n={};for k,v in pairs(t)do n[k]=copy(v)end;return n end
local function group(n)return Group.getByName(n)end
local function controller(n)local g=group(n);if g and g:isExist()then return g:getController()end end
local function terminal()return S.phase=='complete' or S.phase=='partial' or S.phase=='failed'end
local function result(phase,text)
  if terminal()then return end
  S.phase=phase;S.failure=text
  trigger.action.setUserFlag(phase=='complete' and 921 or phase=='partial' and 922 or 923,1)
  say(text)
end
local function clear(p,radius,slope)
  local kind=land.getSurfaceType({x=p.x,y=p.z});if kind~=1 and kind~=4 and kind~=5 then return false end
  for _,o in ipairs({{25,0},{-25,0},{0,25},{0,-25}})do
    local q={x=p.x+o[1],y=p.z+o[2]};local k=land.getSurfaceType(q)
    if (k~=1 and k~=4 and k~=5) or math.abs(land.getHeight(q)-p.y)>slope then return false end
  end
  local blocked=false
  world.searchObjects(Object.Category.SCENERY,{id=world.VolumeType.SPHERE,params={point=p,radius=radius}},function()blocked=true;return false end)
  return not blocked
end
local function findClear(center,maxRadius,vehicle)
  for r=0,maxRadius,50 do for a=0,330,30 do
    local p=point({x=center.x+r*math.cos(math.rad(a)),y=center.y+r*math.sin(math.rad(a))})
    if clear(p,vehicle and 8 or 45,vehicle and 6 or 1.5)then return p end
  end end
  error('No clear site near '..center.x..','..center.y)
end
local function eachGroup(fn)
  for _,side in pairs(env.mission.coalition)do for _,country in pairs(side.country or{})do
    for _,category in ipairs({'helicopter','vehicle'})do for _,g in pairs((country[category]or{}).group or{})do fn(g,country.id)end end
  end end
end
local templates={}
eachGroup(function(g,country)templates[g.name]={data=copy(g),country=country}end)
local function disable(n)local c=controller(n);if c then c:setOnOff(false)end end
local function members(n)
  local t={};local g=group(n);if g then for _,u in pairs(g:getUnits()or{})do if u:isExist() and u:getLife()>0 then t[#t+1]=u end end end;return t
end
local enemies={'GUARD-WEST','GUARD-EAST','GUARD-FOOT','RELIEF','RELIEF-TRUCKS'}
local function safe()
  if alive('WATCHTOWER-1')then return false end
  for _,n in ipairs(enemies)do for _,u in ipairs(members(n))do
    if distance(u:getPoint(),S.lz)<C.safeRadius or distance(u:getPoint(),point(C.building))<350 then return false end
  end end
  return true
end
local function waypoint(p,name,speedMetres,task)
  return {x=p.x,y=p.z,alt=p.y+180,alt_type='BARO',speed=speedMetres or 45,speed_locked=true,ETA=0,ETA_locked=false,type='Turning Point',action='Turning Point',name=name,task=task or{id='ComboTask',params={tasks={}}}}
end
local function hold()
  local bh=alive('LIFELINE-1');local ctrl=controller('LIFELINE');if not bh or not ctrl then return end
  local p=point(C.hold)
  ctrl:setTask({id='Mission',params={route={points={waypoint(bh:getPoint(),'WAVE OFF'),waypoint(p,'HOLD',40,{id='ComboTask',params={tasks={{number=1,enabled=true,auto=false,id='Orbit',params={pattern='Circle',speed=40,altitude=p.y+250}}}}})}}}})
  S.phase='holding';S.rescueAt=nil;S.cleared=false
end
local function start()
  if S.launched then return end
  local ctrl=controller('LIFELINE');if not ctrl then return end
  ctrl:setCommand({id='Start',params={}})
  ctrl:setOption(0,4) -- Transport holds fire; it is not a gunship.
  ctrl:setTask({id='Follow',params={groupId=templates.LATCH.data.groupId,pos={x=-700,y=60,z=400},lastWptIndexFlag=false}})
  S.launched=true;S.phase='escort'
  say('Lifeline launching. Following the Kiowa flight; will hold outside the village until your clearance.')
end
local function returnHome(aborted)
  local bh=alive('LIFELINE-1');local ctrl=controller('LIFELINE');if not bh or not ctrl then return end
  local approach=point({x=C.transportPad.x+1800,y=C.transportPad.y+700})
  local final=waypoint(S.home,'KEYSTONE TRANSPORT PAD',30)
  final.type='Land';final.action='Landing';final.alt=S.home.y;final.helipadId=200;final.linkUnit=200
  ctrl:setTask({id='Mission',params={route={points={waypoint(bh:getPoint(),'EGRESS',50),waypoint(point(C.hold),'FRIENDLY CORRIDOR',50),waypoint(approach,'RECOVERY',40),final}}}})
  S.phase='return';S.rescueAt=nil;S.aborted=aborted or false
  say(S.onboard>0 and 'Lifeline loaded and returning to KEYSTONE. Escort us home.' or 'Extraction aborted. Lifeline returning empty; hostages remain at the compound.')
end
local function waveOff()
  if terminal()then say('Operation has ended.');return end
  if S.boarded then returnHome(false);return end
  if not S.launched then say('Lifeline is still at KEYSTONE.');return end
  if S.phase=='return'then say('Lifeline is already returning to KEYSTONE.');return end
  hold();say('Lifeline waving off to the hold. Rescue progress reset; fresh clearance required.')
end
local function requestLand()
  if terminal()then say('Operation has ended.');return end
  if S.boarded or S.phase=='return'then say('Lifeline is returning to KEYSTONE.');return end
  if not S.launched then say('Lifeline launches when the Kiowa lead takes off.');return end
  if S.phase=='ingress' or S.phase=='rescue'then say('Lifeline already cleared; cover the landing area.');return end
  local lead=alive('LATCH-1');if not lead or distance(lead:getPoint(),point(C.building))>10000 then say('Move closer to the objective before clearing the extraction.');return end
  if not safe()then say('Extraction area is not secure. Neutralize the known SAM and close defenders before clearing Lifeline.');return end
  local ctrl=controller('LIFELINE');local bh=alive('LIFELINE-1');if not ctrl or not bh then return end
  -- Native temporary-ground-landing task, indefinite until rescue completion or wave-off.
  local landTask={number=1,enabled=true,auto=false,id='Land',params={point={x=S.lz.x,y=S.lz.z},durationFlag=false,duration=C.rescueSeconds,combatLandingFlag=false}}
  ctrl:setTask({id='Mission',params={route={points={waypoint(bh:getPoint(),'CLEAR TO LAND'),waypoint(S.lz,'EXTRACTION LZ',30,{id='ComboTask',params={tasks={landTask}}})}}}})
  S.phase='ingress';S.cleared=true;S.rescueAt=nil
  say('Lifeline cleared to the landing zone. Cover our approach; rescue timing begins only after landing.')
end
local function livingHostages()
  local n=0;for i=1,C.hostages do if alive('HOSTAGES-'..i)then n=n+1 end end;return n
end
local function smoke()
  if S.lz then trigger.action.smoke(S.lz,trigger.smokeColor.Green);say('Actual extraction LZ marked with green smoke.')end
end
local function status()
  local text='Lifeline: '..S.phase..'. '
  if S.boarded then text=text..'Survivors aboard: '..S.onboard..'.'
  else text=text..'Hostages alive: '..livingHostages()..'.'end
  if S.rescueAt then text=text..' Rescue time remaining: '..math.max(0,C.rescueSeconds-math.floor(timer.getTime()-S.rescueAt))..' seconds.'end
  say(text..' '..(S.phase=='holding' and 'Clear through Transport when safe.' or S.phase=='return' and 'Escort to the transport pad at KEYSTONE.' or ''))
end
local function reinforcement()
  for _,name in ipairs({'RELIEF','RELIEF-TRUCKS'})do
    local g=group(name);if g then
      trigger.action.activateGroup(g)
      local p=point({x=C.building.x+(name=='RELIEF'and 100 or 400),y=C.building.y+(name=='RELIEF'and 50 or 200)})
      local first=waypoint(point({x=templates[name].data.x,y=templates[name].data.y}),'START',8)
      first.action='Off Road';first.alt=0
      local dest=waypoint(p,'APPROACH',8);dest.action='Off Road';dest.alt=0
      g:getController():setTask({id='Mission',params={route={points={first,dest}}}})
    end
  end
  S.reinforced=true;say('Movement reported on the village approaches. Maintain overwatch.')
end
local function setup()
  local surface=land.getSurfaceType({x=C.building.x,y=C.building.y})
  assert(surface==1 or surface==4 or surface==5,'Hostage compound is not on land')
  S.lz=findClear(C.plannedLZ,300,false);S.home=point(C.transportPad)
  disable('HOSTAGES');disable('HOSTAGE-BUILDING');for i=1,3 do disable('VILLAGE-'..i)end
  -- Service templates are moved only to local clear ground; fixed intelligence objects never move.
  for name,t in pairs(templates)do if name:match('^KEYSTONE ')or name:match('^TRANSPORT ')then
    local ok,err=pcall(function()
      local g=copy(t.data);g.lateActivation=false
      for _,u in pairs(g.units)do local p=findClear({x=u.x,y=u.y},100,true);u.x=p.x;u.y=p.z end
      g.x=g.units[1].x;g.y=g.units[1].y;g.route.points[1].x=g.x;g.route.points[1].y=g.y
      coalition.addGroup(t.country,Group.Category.GROUND,g)
    end)
    if not ok then env.info('[OPEN_DOOR] Optional service placement: '..tostring(err))end
  end end
  trigger.action.markToCoalition(8201,'SATELLITE INTEL: HOSTAGE BUILDING - NO FIRE',point(C.building),2,true)
  trigger.action.markToCoalition(8202,'SATELLITE INTEL: STRELA-10',point(C.sam),2,true)
  trigger.action.markToCoalition(8203,'EXTRACTION LZ - LIFELINE',S.lz,2,true)
  trigger.action.markToCoalition(8204,'KEYSTONE - BLACK HAWK RECOVERY PAD',S.home,2,true)
  local menu=missionCommands.addSubMenuForCoalition(2,'OPEN DOOR')
  local trans=missionCommands.addSubMenuForCoalition(2,'Transport',menu)
  local rescue=missionCommands.addSubMenuForCoalition(2,'Rescue',menu)
  missionCommands.addCommandForCoalition(2,'Clear Black Hawk to land',trans,requestLand)
  missionCommands.addCommandForCoalition(2,'Hold / wave off',trans,waveOff)
  missionCommands.addCommandForCoalition(2,'Abort and return',trans,function()if not terminal()then if S.launched then returnHome(not S.boarded)else say('Lifeline is still at KEYSTONE.')end end end)
  missionCommands.addCommandForCoalition(2,'Status',rescue,status)
  missionCommands.addCommandForCoalition(2,'Mark actual LZ (green)',rescue,smoke)
  S.phase='ready'
  say('Ready. Exact hostage building and Strela are preplanned points / F10 intelligence markers. Lifeline follows after your takeoff and waits for explicit clearance.')
  if coord and coord.LOtoLL then
    local lat,lon=coord.LOtoLL(point(C.building));say(string.format('HOSTAGE BUILDING: %.6f latitude, %.6f longitude.',lat,lon))
    lat,lon=coord.LOtoLL(point(C.sam));say(string.format('STRELA-10: %.6f latitude, %.6f longitude.',lat,lon))
  end
end
local function tick(_,now)
  if terminal()then return nil end
  if S.phase=='setup'then local ok,err=pcall(setup);if not ok then result('failed','Setup failed: '..tostring(err));return nil end end
  local player=alive('LATCH-1')
  if player then S.playerSeen=true elseif S.playerSeen then result('failed','Kiowa lead lost.');return nil end
  local bh=alive('LIFELINE-1')
  if bh then S.hawkSeen=true elseif S.hawkSeen then S.onboard=0;result('failed','Lifeline lost. Extraction failed.');return nil end
  if not player or not bh then return now+2 end
  if not S.boarded then
    if not alive('HOSTAGE-BUILDING-1')then for i=1,C.hostages do local u=alive('HOSTAGES-'..i);if u then u:destroy()end end end
    if livingHostages()==0 then result('failed','No hostages survived.');return nil end
  end
  if player:inAir()and not S.launched then start()end
  if S.launched and S.phase=='escort'and distance(player:getPoint(),point(C.building))<C.holdGate then hold();say('Lifeline holding outside the threat area. Clear us through F10 when safe.')end
  if not S.alertAt and distance(player:getPoint(),point(C.building))<C.alertRadius then S.alertAt=now;say('Village alerted. Expect possible ground reinforcements.')end
  if S.alertAt and not S.reinforced and not S.boarded and now-S.alertAt>=C.reinforcementDelay then reinforcement()end
  if S.phase=='ingress'or S.phase=='rescue'then
    if not safe()then waveOff()
    elseif not bh:inAir()and speed(bh)<1 and distance(bh:getPoint(),S.lz)<=80 then
      if not S.rescueAt then S.rescueAt=now;S.phase='rescue';say('Lifeline down. Team conducting rescue; cover us for three minutes.')end
      if now-S.rescueAt>=C.rescueSeconds then
        S.onboard=livingHostages();S.boarded=true
        for i=1,C.hostages do local u=alive('HOSTAGES-'..i);if u then u:destroy()end end
        trigger.action.setUserFlag(920,1);returnHome(false)
      end
    else S.rescueAt=nil;S.phase='ingress'end
  end
  if S.phase=='return'then
    if not bh:inAir()and speed(bh)<1 and distance(bh:getPoint(),S.home)<=120 then
      S.homeAt=S.homeAt or now
      if now-S.homeAt>=C.returnSeconds then
        if S.onboard==C.hostages then result('complete','Full success: all six hostages safely returned to KEYSTONE.')
        elseif S.onboard>0 then result('partial','Partial success: '..S.onboard..' of six hostages safely returned to KEYSTONE.')
        else result('failed','Lifeline returned without hostages. Extraction failed.')end
      end
    else S.homeAt=nil end
  end
  return now+2
end
timer.scheduleFunction(function(a,now)
  local ok,nextTime=pcall(tick,a,now)
  if not ok then env.error('[OPEN_DOOR] '..tostring(nextTime));result('failed','Mission script error; see DCS log.');return nil end
  return nextTime
end,nil,timer.getTime()+2)
