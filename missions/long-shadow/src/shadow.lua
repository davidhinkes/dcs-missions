-- Long Shadow: covert convoy interception. Native AI drives and fights; this
-- script times the departure, judges the result and turns the drone's view
-- into progress reports. Requires LONG_SHADOW_CONFIG loaded first.
LONG_SHADOW={phase='waiting',seen={},calls={},minDirect=math.huge}
local S,C=LONG_SHADOW,assert(LONG_SHADOW_CONFIG,'Missing Long Shadow config')
local NM=1852

local function say(text)
  trigger.action.outTextForCoalition(2,'LONG SHADOW: '..text,20)
  env.info('[LONG_SHADOW] '..text)
end
local function unit(name)
  local u=Unit.getByName(name)
  if u and u:isExist() and u:getLife()>0 then return u end
end
local function terminal()return S.phase=='won' or S.phase=='failed' end
local function flat(a,b)return math.sqrt((a.x-b.x)^2+(a.z-b.z)^2)end
local function vec3(p)return {x=p.x,y=land.getHeight({x=p.x,y=p.y}),z=p.y}end
local function isConvoy(name)return type(name)=='string' and name:find('^MAGPIE ')~=nil end

local function finish(success,reason)
  if terminal() then return end
  S.phase=success and 'won' or 'failed';S.result=reason
  trigger.action.setUserFlag(success and 960 or 961,1)
  if success then trigger.action.setUserFlag(962,1) end
  say((success and 'MISSION SUCCESS: ' or 'MISSION FAILED: ')..reason)
end

-- Departure time: fixed override for tests/replay, else random in the briefed window.
-- DCS Lua 5.1 on Windows uses the C runtime rand(): the first draw after
-- seeding with nearby values is almost identical (about 0.0013-0.10 for
-- seeds 1-1000, i.e. always near H+4). Discard a few draws first.
for _=1,3 do math.random() end
S.departureDelay=LONG_SHADOW_DEPARTURE_DELAY or (C.departureMinSeconds+math.random()*(C.departureMaxSeconds-C.departureMinSeconds))
S.departAt=timer.getTime()+S.departureDelay

---------------------------------------------------------------------------
-- Distance measurement (road where DCS can path it, otherwise labelled direct)
---------------------------------------------------------------------------
local function roadLength(from,to)
  -- from is a 3D point (x,z); to is a planar config point (x,y).
  if land.findPathOnRoads then
    local ok,path=pcall(land.findPathOnRoads,'roads',from.x,from.z,to.x,to.y)
    if ok and type(path)=='table' and #path>0 then
      local total,px,py=0,from.x,from.z
      for _,p in ipairs(path)do total=total+math.sqrt((p.x-px)^2+(p.y-py)^2);px,py=p.x,p.y end
      total=total+math.sqrt((to.x-px)^2+(to.y-py)^2)
      return total,'by road'
    end
  end
  return math.sqrt((to.x-from.x)^2+(to.y-from.z)^2),'direct'
end
local function measure(hvt)
  local p=hvt:getPoint()
  local ap={x=C.attackPoint.x,z=C.attackPoint.y}
  local direct=flat(p,ap)
  S.minDirect=math.min(S.minDirect,direct)
  local newlyPassed=false
  -- Passed: close to 1T, or clearly receding after a close approach.
  if not S.passed and (direct<=C.passRadius or (S.minDirect<1500 and direct>S.minDirect+C.passRecede)) then
    S.passed=true;newlyPassed=true
  end
  local v=hvt:getVelocity();local speed=math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
  local r={p=p,speed=speed,passed=S.passed,newlyPassed=newlyPassed}
  if S.passed then
    r.toDest,r.destLabel=roadLength(p,C.destination)
  else
    r.toAttack,r.attackLabel=roadLength(p,C.attackPoint)
  end
  return r
end
local function speedText(r,remaining)
  if r.speed<2 then return 'convoy halted' end
  return string.format('%d kt, ETA %s about %d min',math.floor(r.speed*1.94384+0.5),r.passed and 'Hama' or '1T',math.max(1,math.floor(remaining/r.speed/60+0.5)))
end
local function progressText(r)
  if r.passed then
    return string.format('MAGPIE convoy is past 1T, %.1f nm %s from Hama, %s.',r.toDest/NM,r.destLabel,speedText(r,r.toDest))
  end
  return string.format('MAGPIE convoy is %.1f nm %s short of 1T, %s.',r.toAttack/NM,r.attackLabel,speedText(r,r.toAttack))
end

---------------------------------------------------------------------------
-- Pontiac (optional support): any fault disables reports, never the mission.
---------------------------------------------------------------------------
local function droneAlive()return unit(C.drone.unit)~=nil end
local function droneCall(fn)
  if S.droneDisabled then return end
  local ok,err=pcall(fn)
  if not ok then
    S.droneDisabled=true
    env.info('[LONG_SHADOW] Pontiac support disabled: '..tostring(err))
    say('Pontiac support unavailable. No further convoy reports; MAGPIE is still your target.')
  end
end
local function pontiac(text)say('Pontiac: '..text)end
local function crossed(list,value,prefix)
  -- Report only the tightest newly crossed threshold; latch every crossed one.
  local hit
  for _,th in ipairs(list)do
    if value<=th*NM and not S.calls[prefix..th] then S.calls[prefix..th]=true;hit=th end
  end
  return hit
end
local function droneTrack()
  if not droneAlive() then
    if S.droneSeen and not S.droneLostReported then S.droneLostReported=true;say('Pontiac lost. No further convoy reports; MAGPIE is still your target.')end
    return
  end
  if not S.droneSeen then S.droneSeen=true end
  local hvt=unit(C.hvt)
  if not S.seen.hvt or not hvt then return end
  if not S.departureReported then
    S.departureReported=true
    local r=measure(hvt)
    for _,th in ipairs(C.approachCallsNm)do if (r.toAttack or 0)<=th*NM then S.calls['a'..th]=true end end
    pontiac('MAGPIE is moving. Five-vehicle convoy rolling north out of Homs on the M5; MAGPIE in the UAZ, third in column. '..progressText(r))
    return
  end
  local r=measure(hvt)
  if r.newlyPassed then
    for _,th in ipairs(C.approachCallsNm)do S.calls['a'..th]=true end
    pontiac('MAGPIE convoy passing 1T now. '..progressText(r));return
  end
  if r.passed then
    if crossed(C.destinationCallsNm,r.toDest,'d') then pontiac(progressText(r)..(r.toDest<=2*NM and ' Running out of road.' or '')) end
  elseif crossed(C.approachCallsNm,r.toAttack,'a') then
    pontiac(progressText(r))
  end
end
local function convoyReport()
  if terminal() then say(S.result..(S.phase=='won' and ' Recovery to FARP JUNIPER is optional.' or ' Restart the mission for another attempt.'));return end
  if S.droneDisabled or not droneAlive() then say('Pontiac unavailable; no convoy picture. MAGPIE is still at large.');return end
  if not S.activated then pontiac('MAGPIE is still in the compound; convoy not moving yet. Expected departure is within the briefed window.');return end
  local hvt=unit(C.hvt)
  if not hvt then pontiac('Convoy forming up at the Homs exit.');return end
  droneCall(function()
    local r=measure(hvt);local escorts=0
    for i=1,#C.convoyTypes do if i~=C.hvtIndex and unit(C.convoyGroup..'-'..i) then escorts=escorts+1 end end
    pontiac(progressText(r)..string.format(' %d escort vehicle%s remaining. %s',escorts,escorts==1 and '' or 's',S.alerted and 'Convoy is alerted and running.' or 'Convoy appears unaware.'))
  end)
end

---------------------------------------------------------------------------
-- Alert reaction (optional): the convoy dashes for Hama once it is in a fight.
---------------------------------------------------------------------------
local function alert(cause)
  if S.alerted or terminal() or not S.seen.hvt then return end
  S.alerted=true
  env.info('[LONG_SHADOW] Convoy alerted: '..tostring(cause))
  local ok,err=pcall(function()
    local hvt=assert(unit(C.hvt),'MAGPIE unavailable for alert reroute')
    local grp=assert(Group.getByName(C.convoyGroup),'convoy group unavailable')
    local p=hvt:getPoint()
    local function wp(x,y,name)return {x=x,y=y,type='Turning Point',action='On Road',speed=C.alertSpeed,speed_locked=true,name=name,task={id='ComboTask',params={tasks={}}}}end
    local points={wp(p.x,p.z,'ALERT DASH')}
    if not S.passed then points[#points+1]=wp(C.attackPoint.x,C.attackPoint.y,'M5 ORONTES CROSSING') end
    points[#points+1]=wp(C.destination.x,C.destination.y,'HAMA SOUTH - DESTINATION')
    grp:getController():setTask({id='Mission',params={route={points=points}}})
  end)
  if not ok then env.info('[LONG_SHADOW] Alert reroute failed (convoy keeps its route): '..tostring(err)) end
  if not S.droneDisabled and droneAlive() then pontiac('Convoy is reacting - it is speeding up toward Hama.') end
end

---------------------------------------------------------------------------
-- Diagnostics: log route-point surface and road fit; never fails the mission.
---------------------------------------------------------------------------
local function logSites()
  for _,key in ipairs({'farp','convoyStart','talbiseh','attackPoint','destination'})do
    local p=C[key];local text=key..': surface='..tostring(land.getSurfaceType({x=p.x,y=p.y}))
    if land.getClosestPointOnRoads then
      local ok,rx,ry=pcall(land.getClosestPointOnRoads,'roads',p.x,p.y)
      if ok and rx then text=text..string.format(', nearest road %.0f m',math.sqrt((rx-p.x)^2+(ry-p.y)^2)) end
    end
    env.info('[LONG_SHADOW] Site check '..text)
  end
  local h=land.getHeight({x=C.farp.x,y=C.farp.y});local worst=0
  for _,o in ipairs({{15,0},{-15,0},{0,15},{0,-15}})do worst=math.max(worst,math.abs(land.getHeight({x=C.farp.x+o[1],y=C.farp.y+o[2]})-h))end
  S.farpSlope=worst
  env.info(string.format('[LONG_SHADOW] FARP JUNIPER height %.1f m, max 15 m height difference %.1f m',h,worst))
end

---------------------------------------------------------------------------
-- Main loop
---------------------------------------------------------------------------
local function tick(_,now)
  if terminal() then return nil end
  local player=unit(S.playerName or C.player)
  if not player and coalition and coalition.getPlayers then
    for _,candidate in ipairs(coalition.getPlayers(2) or {})do
      if candidate:isExist() and candidate:getLife()>0 and candidate:getTypeName()=='OH58D' then player=candidate;S.playerName=candidate:getName();break end
    end
  end
  if player then S.seen.player=true end
  if S.seen.player and not player then
    S.missingAt=S.missingAt or now
    if now-S.missingAt>=C.playerMissingGrace then finish(false,'Your Kiowa was lost.');return nil end
  else S.missingAt=nil end
  if player and not S.ready then
    S.ready=true;if S.phase=='waiting' then S.phase='ready' end
    pcall(logSites)
    trigger.action.markToCoalition(8301,'1T: proposed attack point - M5 Orontes crossing (likely convoy passage)',vec3(C.attackPoint),2,true)
    trigger.action.markToCoalition(8302,'Intel: convoy departure area - M5 northern exit of Homs',vec3(C.convoyStart),2,true)
    trigger.action.markToCoalition(8303,'Intel: convoy destination - Hama southern entrance',vec3(C.destination),2,true)
    trigger.action.markToCoalition(8304,'FARP JUNIPER - optional recovery',vec3(C.farp),2,true)
    say('Destroy MAGPIE\'s vehicle (UAZ, third in the convoy) before it reaches Hama. 1T is the proposed attack point; plan your own approach. Reports: F10 Other > Pontiac.'
      ..((S.farpSlope or 0)>2.5 and ' NOTE: the JUNIPER pad site measured uneven; please report it.' or ''))
    if droneAlive() then pontiac('On station over the M5. Eyes on MAGPIE\'s compound in northern Homs; I will call when the convoy moves.') end
  end
  if not S.activated and now>=S.departAt then
    local grp=assert(Group.getByName(C.convoyGroup),'MAGPIE convoy group missing')
    grp:activate()
    S.activated=true;S.activatedAt=now;S.phase=S.ready and 'rolling' or S.phase
    env.info(string.format('[LONG_SHADOW] Convoy activated at mission time %.0f s (delay %.0f s)',now,S.departureDelay))
  end
  local hvt=unit(C.hvt)
  if S.activated and not S.seen.hvt then
    if hvt then S.seen.hvt=true
    elseif now-S.activatedAt>C.activationTimeout then error('MAGPIE vehicle did not appear after activation') end
  end
  -- No result while an acquired player is missing (loss grace still running).
  if S.seen.player and not player then return now+1 end
  if S.seen.hvt then
    if not hvt then finish(true,'MAGPIE\'s vehicle destroyed. Target eliminated.');return nil end
    if flat(hvt:getPoint(),{x=C.destination.x,z=C.destination.y})<=C.arrivalRadius then finish(false,'MAGPIE reached Hama. The window has closed.');return nil end
  end
  if S.ready and (not S.nextReport or now>=S.nextReport) then
    S.nextReport=now+C.reportInterval;droneCall(droneTrack)
  end
  return now+1
end

-- Death events latch results in observed order; HIT/SHOT events alert the convoy.
if world and world.addEventHandler and world.event then
  world.addEventHandler({onEvent=function(_,e)
    if terminal() then return end
    local ok,err=pcall(function()
      local E=world.event
      local initiator=e.initiator and e.initiator.getName and e.initiator:getName()
      if e.id==E.S_EVENT_DEAD or e.id==E.S_EVENT_UNIT_LOST then
        if initiator==C.hvt and S.seen.hvt then finish(true,'MAGPIE\'s vehicle destroyed. Target eliminated.')
        elseif initiator==(S.playerName or C.player) and S.seen.player then finish(false,'Your Kiowa was destroyed.')
        elseif isConvoy(initiator) then alert('escort destroyed') end
      elseif e.id==E.S_EVENT_HIT then
        local target=e.target and e.target.getName and e.target:getName()
        if isConvoy(target) then alert('convoy vehicle hit') end
      elseif e.id==E.S_EVENT_SHOT or e.id==E.S_EVENT_SHOOTING_START then
        if isConvoy(initiator) then alert('convoy opened fire') end
      end
    end)
    if not ok then env.info('[LONG_SHADOW] Event handling error: '..tostring(err)) end
  end})
end

local menu=missionCommands.addSubMenuForCoalition(2,'Pontiac')
missionCommands.addCommandForCoalition(2,'Convoy report',menu,convoyReport)
timer.scheduleFunction(function(_,now)
  local ok,nextTime=pcall(tick,nil,now)
  if not ok then env.info('[LONG_SHADOW] Mandatory setup error: '..tostring(nextTime));finish(false,'Mission setup failed (convoy did not start); see dcs.log.');return nil end
  return nextTime
end,nil,timer.getTime()+1)
