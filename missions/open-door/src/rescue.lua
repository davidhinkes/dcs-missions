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
-- The player's Kiowa: LATCH-1, or the occupied OH-58D if the slot was renamed.
local function playerUnit()
  local u=alive(S.playerName or 'LATCH-1')
  if not u and coalition and coalition.getPlayers then
    for _,candidate in ipairs(coalition.getPlayers(2) or {})do
      if candidate:isExist() and candidate:getLife()>0 and candidate:getTypeName()=='OH58D' then u=candidate;S.playerName=candidate:getName();break end
    end
  end
  return u
end
local function stopLaser(announce)
  local laser=S.laser;S.laser=nil
  if laser then local ok,err=pcall(function()laser:destroy()end);if not ok then env.info('[OPEN_DOOR] Laser cleanup failed: '..tostring(err))end end
  S.laserTarget=nil
  if announce then say('Sentinel: laser off.')end
end
-- Optional support must never terminate the rescue's timer or F10 callbacks.
local function droneCall(fn,allowDisabled)
  if S.droneDisabled and not allowDisabled then say('Sentinel support unavailable. Continue the rescue.');return end
  local ok,err=pcall(fn)
  if not ok then
    S.droneDisabled=true;S.droneOnStation=false;stopLaser(false)
    env.info('[OPEN_DOOR] Drone support disabled: '..tostring(err))
    say('Sentinel support unavailable. Laser off; continue the rescue.')
  end
end
local function laserPoint(u)local p=u:getPoint();return {x=p.x,y=p.y+1,z=p.z}end
local function eligibleLaser(u,drone)
  local p=laserPoint(u);local source=drone:getPoint()
  if distance(p,point(C.building))<C.drone.protectedRadius then return false end
  for i=1,C.hostages do local h=alive('HOSTAGES-'..i);if h and distance(p,h:getPoint())<C.drone.protectedRadius then return false end end
  for _,name in ipairs({'LATCH-1','LATCH-2','LATCH-3','LATCH-4','LIFELINE-1',S.playerName or 'LATCH-1'})do
    local h=alive(name);if h and distance(p,h:getPoint())<C.drone.friendlyRadius then return false end
  end
  local dx,dy,dz=p.x-source.x,p.y-source.y,p.z-source.z
  return dx*dx+dy*dy+dz*dz<=C.drone.maxRange^2 and land.isVisible(source,p)
end
local laserTargets={'WATCHTOWER-1','GUARD-WEST-1','GUARD-EAST-1','GUARD-FOOT-1','GUARD-FOOT-2','GUARD-FOOT-3','GUARD-FOOT-4','RELIEF-1','RELIEF-2','RELIEF-TRUCKS-1','RELIEF-TRUCKS-2'}
local function targetReport(u)
  local p=u:getPoint();local base=point(C.building)
  local angle=(math.deg(math.atan2(p.z-base.z,p.x-base.x))+360)%360
  local directions={'north','northeast','east','southeast','south','southwest','west','northwest'}
  local direction=directions[math.floor((angle+22.5)/45)%8+1]
  local kind=S.laserTarget and S.laserTarget:match('^GUARD%-FOOT') and 'Infantry' or 'Vehicle'
  local text=string.format('%s, %.0f m grid %s of the hostage building. ',kind,math.floor(distance(base,p)/10+0.5)*10,direction)

  local lat,lon
  if coord and coord.LOtoLL then lat,lon=coord.LOtoLL(p);text=text..string.format('Target %.6f latitude, %.6f longitude. ',lat,lon)end
  local player=playerUnit()
  if player then
    local from=player:getPoint();local bearing=math.deg(math.atan2(p.z-from.z,p.x-from.x));local reference='grid'
    if lat and coord and coord.LOtoLL then
      local a,b=coord.LOtoLL(from);a=math.rad(a);local c=math.rad(lat);local delta=math.rad(lon-b)
      bearing=math.deg(math.atan2(math.sin(delta)*math.cos(c),math.cos(a)*math.sin(c)-math.sin(a)*math.cos(c)*math.cos(delta)));reference='true'
    end
    text=text..string.format('From your Kiowa: %03d degrees %s, %.1f nm. ',math.floor((bearing+360)%360+0.5)%360,reference,distance(from,p)/1852)
  end
  if text=='' then text='Target coordinates unavailable. 'end
  return text
end
local function laserStatus()
  if not alive('SENTINEL-1')then stopLaser(false);say('Sentinel lost / unavailable. Laser off.');return end
  if S.droneDisabled then say('Sentinel support unavailable. Laser off.');return end
  if not S.laser then say('Sentinel: '..(S.droneOnStation and 'on station' or S.droneDispatched and 'in transit / outside station envelope' or 'holding 15 nm staging')..'. Laser off. Code '..C.drone.laserCode..'.');return end
  local u=alive(S.laserTarget)
  if u then say('Sentinel: lasing, code '..C.drone.laserCode..'. '..targetReport(u)..'Identify before firing.')else stopLaser(false);say('Sentinel: target lost. Laser off.')end
end
local function sendDrone()
  if terminal()then say('Sentinel: mission ended.');return end
  local drone,ctrl=alive('SENTINEL-1'),controller('SENTINEL')
  if not drone or not ctrl then say('Sentinel unavailable.');return end
  if S.droneDispatched then say('Sentinel: already tasked to the objective.');return end
  local function wp(p,name)
    return {x=p.x,y=p.z,alt=C.drone.altitude,alt_type='BARO',speed=C.drone.speed,speed_locked=true,type='Turning Point',action='Turning Point',name=name,task={id='ComboTask',params={tasks={}}}}
  end
  local start,station=wp(drone:getPoint(),'SENTINEL TRANSIT'),wp(point(C.building),'SENTINEL ON STATION')
  start.task.params.tasks={
    {number=1,enabled=true,auto=false,id='WrappedAction',params={action={id='Option',params={name=0,value=4}}}}
  }
  station.task.params.tasks={
    {number=1,enabled=true,auto=false,id='Orbit',params={pattern='Circle',speed=C.drone.speed,altitude=C.drone.altitude}}
  }
  ctrl:setTask({id='Mission',params={route={points={start,station}}}})
  S.droneDispatched=true
  say('Sentinel inbound from 15 nm staging at 20,000 ft MSL. Allow roughly seven minutes; laser available on arrival.')
end
local function designateNext()
  if terminal()then say('Sentinel: mission ended; laser off.');return end
  local drone=alive('SENTINEL-1')
  stopLaser(false)
  if not drone then say('Sentinel unavailable. Continue the rescue without drone support.');return end
  if not S.droneOnStation then say('Sentinel inbound automatically. Await the on-station report.');return end
  if not Spot or not Spot.createLaser or not land.isVisible then say('Sentinel laser support unavailable.');return end
  for offset=1,#laserTargets do
    local index=((S.laserIndex or 0)+offset-1)%#laserTargets+1
    local u=alive(laserTargets[index])
    if u and eligibleLaser(u,drone)then
      S.laser=Spot.createLaser(drone,{x=0,y=0,z=0},laserPoint(u),C.drone.laserCode)
      if not S.laser then say('Sentinel: unable to create laser spot.');return end
      S.laserTarget=laserTargets[index];S.laserIndex=index;laserStatus();return
    end
  end
  say('Sentinel: no safe visible target in range. Laser off.')
end
local function updateLaser()
  if not S.laser then return end
  local drone,u=alive('SENTINEL-1'),alive(S.laserTarget)
  if not S.droneOnStation or not drone or not u or not eligibleLaser(u,drone)then stopLaser(false);say('Sentinel: designation lost or unsafe. Laser off; request a new target.');return end
  S.laser:setPoint(laserPoint(u))
end
local function result(phase,text)
  if terminal()then return end
  stopLaser(false)
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
    if clear(p,vehicle and 8 or 18,vehicle and 6 or 2.5)then return p end
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
local alternateStatics={}
for _,country in pairs(env.mission.coalition.blue.country or{})do
  for _,g in pairs((country.static or{}).group or{})do for _,u in pairs(g.units)do
    if u.name:match('^KEYSTONE ')then alternateStatics[#alternateStatics+1]={data=copy(u),country=country.id}end
  end end
end
local function setupAlternateFarp()
  local footprint={}
  for _,t in ipairs(alternateStatics)do footprint[#footprint+1]={x=t.data.x-C.alternateFarp.x,z=t.data.y-C.alternateFarp.y,radius=t.data.type=='SINGLE_HELIPAD'and 18 or 12}end
  for name,t in pairs(templates)do if name:match('^KEYSTONE ')then for _,u in pairs(t.data.units)do footprint[#footprint+1]={x=u.x-C.alternateFarp.x,z=u.y-C.alternateFarp.y,radius=8}end end end
  local selected=nil
  for r=0,C.alternateFarp.searchRadius,100 do
    for a=0,345,15 do
      local candidate=point({x=C.alternateFarp.x+r*math.cos(math.rad(a)),y=C.alternateFarp.y+r*math.sin(math.rad(a))})
      local centerHeight=land.getHeight({x=candidate.x+90,y=candidate.z});local suitable=true
      for _,o in ipairs(footprint)do
        local p=point({x=candidate.x+o.x,y=candidate.z+o.z})
        if math.abs(p.y-centerHeight)>4 or not clear(p,o.radius,2.5)then suitable=false;break end
      end
      if suitable then selected=candidate;break end
    end
    if selected then break end
  end
  assert(selected,'No open, sufficiently level site for the complete KEYSTONE camp within 1 nm')
  local dx,dz=selected.x-C.alternateFarp.x,selected.z-C.alternateFarp.y
  -- Same names and unit IDs replace only the alternate base's planned objects;
  -- the pad warehouse IDs remain stable. No aircraft starts at this base.
  for _,t in ipairs(alternateStatics)do
    local u=copy(t.data);u.x=u.x+dx;u.y=u.y+dz;u.dead=false
    assert(coalition.addStaticObject(t.country,u),'Failed to place '..u.name)
  end
  for name,t in pairs(templates)do if name:match('^KEYSTONE ')then
    local g=copy(t.data);g.x=g.x+dx;g.y=g.y+dz
    for _,u in pairs(g.units)do u.x=u.x+dx;u.y=u.y+dz end
    g.route.points[1].x=g.x;g.route.points[1].y=g.y
    assert(coalition.addGroup(t.country,Group.Category.GROUND,g),'Failed to place '..name)
  end end
  S.alternate=selected
  trigger.action.markToCoalition(8205,'FARP KEYSTONE - FUEL / AMMO / REPAIR - 128.500 AM',selected,2,true)
  say('KEYSTONE ready: alternate refuel/rearm/repair base marked on F10. Use the actual marker for its location. Radio 128.500 AM.')
end
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
  local final=waypoint(S.home,'FOOTHOLD TRANSPORT PAD',30)
  final.type='Land';final.action='Landing';final.alt=S.home.y;final.helipadId=200;final.linkUnit=200
  ctrl:setTask({id='Mission',params={route={points={waypoint(bh:getPoint(),'EGRESS',50),waypoint(point(C.hold),'FRIENDLY CORRIDOR',50),waypoint(approach,'RECOVERY',40),final}}}})
  S.phase='return';S.rescueAt=nil;S.aborted=aborted or false;S.recoveryReported=false;S.liftReported=false
  say(S.onboard>0 and 'Lifeline loaded and returning to FOOTHOLD. Escort us home.' or 'Extraction aborted. Lifeline returning empty; hostages remain at the compound.')
end
local function waveOff()
  if terminal()then say('Operation has ended.');return end
  if S.boarded then returnHome(false);return end
  if not S.launched then say('Lifeline is still at FOOTHOLD.');return end
  if S.phase=='return'then say('Lifeline is already returning to FOOTHOLD.');return end
  hold();say('Lifeline waving off to the hold. Rescue progress reset; fresh clearance required.')
end
local function requestLand()
  if terminal()then say('Operation has ended.');return end
  if S.boarded or S.phase=='return'then say('Lifeline is returning to FOOTHOLD.');return end
  if not S.launched then say('Lifeline launches when the Kiowa lead takes off.');return end
  if S.phase=='ingress' or S.phase=='rescue'then say('Lifeline already cleared; cover the landing area.');return end
  local lead=playerUnit();if not lead or distance(lead:getPoint(),point(C.building))>10000 then say('Move closer to the objective before clearing the extraction.');return end
  if not safe()then say('Extraction area is not secure. Neutralize the known SAM and close defenders before clearing Lifeline.');return end
  local ctrl=controller('LIFELINE');local bh=alive('LIFELINE-1');if not ctrl or not bh then return end
  -- Native temporary-ground-landing task, indefinite until rescue completion or wave-off.
  local landTask={number=1,enabled=true,auto=false,id='Land',params={point={x=S.lz.x,y=S.lz.z},durationFlag=false,duration=C.rescueSeconds,combatLandingFlag=false}}
  ctrl:setTask({id='Mission',params={route={points={waypoint(bh:getPoint(),'CLEAR TO LAND'),waypoint(S.lz,'EXTRACTION LZ',30,{id='ComboTask',params={tasks={landTask}}})}}}})
  S.phase='ingress';S.cleared=true;S.rescueAt=nil;S.approachReported=false;S.halfwayReported=false
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
  text=text..(S.alternate and ' KEYSTONE services ready, 128.500 AM; see F10.' or ' KEYSTONE site preparation unavailable; use FOOTHOLD.')
  say(text..' '..(S.phase=='holding' and 'Clear through Transport when safe.' or S.phase=='return' and 'Escort to the transport pad at FOOTHOLD.' or ''))
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
  local alternateOK,alternateError=pcall(setupAlternateFarp)
  if not alternateOK then env.info('[OPEN_DOOR] Alternate base preparation: '..tostring(alternateError));say('KEYSTONE preparation could not find a safe complete camp. Use FOOTHOLD; do not rely on the planned alternate site.')end
  local surface=land.getSurfaceType({x=C.building.x,y=C.building.y})
  assert(surface==1 or surface==4 or surface==5,'Hostage compound is not on land')
  S.lz=findClear(C.plannedLZ,1500,false);S.home=point(C.transportPad)
  disable('HOSTAGES');disable('HOSTAGE-BUILDING');for i=1,3 do disable('VILLAGE-'..i)end
  -- FARP service units and facilities are present at mission start. They must not
  -- depend on this extraction setup succeeding or on delayed spawning.
  trigger.action.markToCoalition(8201,'SATELLITE INTEL: HOSTAGE BUILDING - NO FIRE',point(C.building),2,true)
  trigger.action.markToCoalition(8202,'SATELLITE INTEL: STRELA-10',point(C.sam),2,true)
  trigger.action.markToCoalition(8203,'EXTRACTION LZ - LIFELINE',S.lz,2,true)
  trigger.action.markToCoalition(8204,'FOOTHOLD - BLACK HAWK RECOVERY PAD',S.home,2,true)
  local trans=missionCommands.addSubMenuForCoalition(2,'Transport')
  local rescue=missionCommands.addSubMenuForCoalition(2,'Rescue')
  local droneMenu=missionCommands.addSubMenuForCoalition(2,'Drone')
  missionCommands.addCommandForCoalition(2,'Designate next target',droneMenu,function()droneCall(designateNext)end)
  missionCommands.addCommandForCoalition(2,'Laser status',droneMenu,function()droneCall(laserStatus,true)end)
  missionCommands.addCommandForCoalition(2,'Stop lasing',droneMenu,function()stopLaser(true)end)
  missionCommands.addCommandForCoalition(2,'Clear Black Hawk to land',trans,requestLand)
  missionCommands.addCommandForCoalition(2,'Hold / wave off',trans,waveOff)
  missionCommands.addCommandForCoalition(2,'Abort and return',trans,function()if not terminal()then if S.launched then returnHome(not S.boarded)else say('Lifeline is still at FOOTHOLD.')end end end)
  missionCommands.addCommandForCoalition(2,'Status',rescue,status)
  missionCommands.addCommandForCoalition(2,'Mark actual LZ (green)',rescue,smoke)
  S.phase='ready'
  droneCall(sendDrone) -- Automatic transit from staging at mission initialization.
  say('Ready. Exact hostage building and Strela are preplanned points / F10 intelligence markers. Lifeline follows after your takeoff and waits for explicit clearance.')
  if coord and coord.LOtoLL then
    local lat,lon=coord.LOtoLL(point(C.building));say(string.format('HOSTAGE BUILDING: %.6f latitude, %.6f longitude.',lat,lon))
    lat,lon=coord.LOtoLL(point(C.sam));say(string.format('STRELA-10: %.6f latitude, %.6f longitude.',lat,lon))
  end
end
local function tick(_,now)
  if terminal()then return nil end
  if S.phase=='setup'then local ok,err=pcall(setup);if not ok then result('failed','Setup failed: '..tostring(err));return nil end end
  if not S.droneDisabled then droneCall(function()
    local sentinel=alive('SENTINEL-1')
    local radius=S.droneOnStation and C.drone.stationExitRadius or C.drone.stationRadius
    local altitudeTolerance=S.droneOnStation and 750 or 500
    local arrived=S.droneDispatched and sentinel and distance(sentinel:getPoint(),point(C.building))<=radius and math.abs(sentinel:getPoint().y-C.drone.altitude)<=altitudeTolerance
    if arrived and not S.droneArrivalReported then
      say('Sentinel on station at high altitude. Laser designation available, code '..C.drone.laserCode..'.')
      S.droneArrivalReported=true
    end
    S.droneOnStation=arrived or false
    updateLaser()
  end)end
  local player=playerUnit()
  -- A brief disappearance (slot change, respawn) is tolerated for playerMissingGrace seconds.
  if player then S.playerSeen=true;S.playerMissingAt=nil
  elseif S.playerSeen then
    S.playerMissingAt=S.playerMissingAt or now
    if now-S.playerMissingAt>=C.playerMissingGrace then result('failed','Kiowa lead lost.');return nil end
  end
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
    if S.phase=='ingress' and bh:inAir() and distance(bh:getPoint(),S.lz)<=1500 and not S.approachReported then
      S.approachReported=true;say('Lifeline: approaching the extraction LZ. Cover our final approach.')
    end
    if not safe()then waveOff()
    elseif not bh:inAir()and speed(bh)<1 and distance(bh:getPoint(),S.lz)<=80 then
      if not S.rescueAt then S.rescueAt=now;S.halfwayReported=false;S.phase='rescue';say('Lifeline down. Team conducting rescue; cover us for three minutes.')end
      if now-S.rescueAt>=C.rescueSeconds/2 and now-S.rescueAt<C.rescueSeconds and not S.halfwayReported then
        S.halfwayReported=true;say('Lifeline: rescue halfway complete. Keep the landing zone covered.')
      end
      if now-S.rescueAt>=C.rescueSeconds then
        S.onboard=livingHostages();S.boarded=true
        for i=1,C.hostages do local u=alive('HOSTAGES-'..i);if u then u:destroy()end end
        trigger.action.setUserFlag(920,1);returnHome(false)
      end
    else
      if S.rescueAt then say('Lifeline: rescue interrupted. We need three continuous minutes stationary at the LZ; timer reset.')end
      S.rescueAt=nil;S.halfwayReported=false;S.phase='ingress'
    end
  end
  if S.phase=='return'then
    if S.boarded and bh:inAir() and not S.liftReported then
      S.liftReported=true;say('Lifeline: airborne with '..S.onboard..' survivors. Returning to FOOTHOLD; escort us home.')
    end
    if distance(bh:getPoint(),S.home)<=2000 and not S.recoveryReported then
      S.recoveryReported=true;say('Lifeline: approaching FOOTHOLD recovery. Keep the transport pad clear.')
    end
    if not bh:inAir()and speed(bh)<1 and distance(bh:getPoint(),S.home)<=120 then
      S.homeAt=S.homeAt or now
      if now-S.homeAt>=C.returnSeconds then
        if S.onboard==C.hostages then result('complete','Full success: all six hostages safely returned to FOOTHOLD.')
        elseif S.onboard>0 then result('partial','Partial success: '..S.onboard..' of six hostages safely returned to FOOTHOLD.')
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
