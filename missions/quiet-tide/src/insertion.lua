QUIET_TIDE={phase='setup',inserted=false}
local S,C=QUIET_TIDE,assert(QUIET_TIDE_CONFIG)
local function say(t)trigger.action.outTextForCoalition(2,'QUIET TIDE: '..t,20);env.info('[QUIET_TIDE] '..t)end
local function alive(n)local u=Unit.getByName(n);if u and u:isExist() and u:getLife()>0 then return u end end
-- The player's Kiowa: ANVIL-1, or the occupied OH-58D if the slot was renamed.
local function playerUnit()
 local u=alive(S.playerName or 'ANVIL-1')
 if not u and coalition and coalition.getPlayers then
  for _,c in ipairs(coalition.getPlayers(2) or {})do if c:isExist() and c:getLife()>0 and c:getTypeName()=='OH58D' then u=c;S.playerName=c:getName();break end end
 end
 return u
end
local function ctrl(n)local g=Group.getByName(n);if g and g:isExist()then return g:getController()end end
local function dist(a,b)return math.sqrt((a.x-b.x)^2+(a.z-b.z)^2)end
local function ground(p)return {x=p.x,y=land.getHeight({x=p.x,y=p.y}),z=p.y}end
local function terminal()return S.phase=='complete' or S.phase=='failed' or S.phase=='aborted'end
local function endMission(phase,text)S.phase=phase;S.result=text;trigger.action.setUserFlag(phase=='complete' and 940 or phase=='aborted' and 942 or 941,1);say(text)end
local function wp(p,name,speed,alt)
 return {x=p.x,y=p.z,alt=alt or p.y+200,alt_type='BARO',speed=speed or 45,speed_locked=true,type='Turning Point',action='Turning Point',name=name,task={id='ComboTask',params={tasks={}}}}
end
local function orbit(p,name,alt,speed)
 local w=wp(p,name,speed,alt);w.task.params.tasks={{number=1,enabled=true,auto=false,id='Orbit',params={pattern='Circle',speed=speed or 45,altitude=alt}}};return w
end
local function route(group,points)local c=assert(ctrl(group),'Controller unavailable: '..group);c:setTask({id='Mission',params={route={points=points}}})end
local threats={}
for _,country in pairs(env.mission.coalition.red.country or{})do for _,g in pairs((country.vehicle or{}).group or{})do for _,u in pairs(g.units)do threats[#threats+1]=u.name end end end
table.sort(threats)
local function clearSite(p)
 local surface=land.getSurfaceType({x=p.x,y=p.z});if surface~=1 and surface~=4 and surface~=5 then return false end
 for _,o in ipairs({{25,0},{-25,0},{0,25},{0,-25}})do
  local q={x=p.x+o[1],y=p.z+o[2]};local k=land.getSurfaceType(q)
  if (k~=1 and k~=4 and k~=5)or math.abs(land.getHeight(q)-p.y)>2.5 then return false end
 end
 local blocked=false
 world.searchObjects(Object.Category.SCENERY,{id=world.VolumeType.SPHERE,params={point=p,radius=20}},function()blocked=true;return false end)
 return not blocked
end
local function findLZ()
 for r=0,1000,100 do for angle=0,330,30 do
  local p=ground({x=C.lz.x+r*math.cos(math.rad(angle)),y=C.lz.y+r*math.sin(math.rad(angle))})
  if clearSite(p)then return p end
 end end
 error('No clear insertion site within 1 km; native terrain/site check required')
end
local function safeLZ()
 for _,name in ipairs(threats)do local u=alive(name);if u and dist(u:getPoint(),S.lz)<500 then return false end end
 return true
end
local function supportCall(fn)
 local ok,err=pcall(fn)
 if not ok then S.supportDisabled=true;S.strikeAt=nil;S.strikeTarget=nil;pcall(function()local c=ctrl('SWORD');if c then c:resetTask();c:setOption(0,4)end end);env.info('[QUIET_TIDE] Optional support fault: '..tostring(err));say('SWORD support unavailable; continue insertion without air support.')end
end
local function holdFire()
 S.strikeAt=nil;S.strikeTarget=nil
 local c=ctrl('SWORD');if c then c:resetTask();c:setOption(0,4)end
end
local function strikeSafe(target)
 for _,name in ipairs({'ANVIL-1','ANVIL-2','LIFELINE-1',S.playerName or 'ANVIL-1'})do local u=alive(name);if u and dist(u:getPoint(),target:getPoint())<700 then return false end end
 return not S.inserted and dist(target:getPoint(),S.lz)<=2500
end
local function updateStrike(now)
 if S.supportDisabled or S.supportRTB then return end
 if S.strikeTarget then
  local u=alive(S.strikeTarget)
  if not u or not strikeSafe(u)or now-S.strikeAt>=90 then holdFire();say('SWORD task ended; holding fire.')end
 elseif S.strikeAt then
  if now-S.strikeAt>=90 then holdFire();say('SWORD request expired; request again if required.');return end
  local shooter=alive('SWORD-1')or alive('SWORD-2');if not shooter or dist(shooter:getPoint(),S.lz)>20000 then return end
  for _,name in ipairs(threats)do local u=alive(name);if u and strikeSafe(u)then
   local c=assert(ctrl('SWORD'));c:setOption(0,0);c:pushTask({id='AttackUnit',params={unitId=u:getID(),weaponType=9663676414,expend='One',attackQty=1,attackQtyLimit=true}})
   S.strikeTarget=name;say('SWORD assigned one target near the LZ. Keep clear; attack success unconfirmed.');return
  end end
 end
end
local function returnToShip(group,unit,ship,shipId)
 local u=assert(alive(unit),'Aircraft unavailable');local boat=assert(alive(ship),'Recovery ship unavailable')
 local p=boat:getPoint();local final=wp(p,'SHIP RECOVERY',group=='SWORD'and 100 or 35,p.y)
 final.type='Land';final.action='Landing';final.linkUnit=shipId;final.helipadId=shipId
 route(group,{wp(u:getPoint(),'RETURN',group=='SWORD'and 180 or 45),wp({x=p.x-2000,y=p.y,z=p.z},'SHIP APPROACH',group=='SWORD'and 140 or 40),final})
end
local function goHome(aborted)
 S.phase='return';S.aborted=aborted or false;S.insertionAt=nil;S.homeAt=nil
 returnToShip('LIFELINE','LIFELINE-1','TARAWA-1',C.tarawaId)
 supportCall(holdFire)
 say(S.inserted and 'SEAL team deployed. Lifeline returning empty to TARAWA; escort and recover.' or 'Insertion aborted. Lifeline returning with the team aboard. Recover to TARAWA.')
end
local function holdTransport()
 S.phase='holding';S.insertionAt=nil;S.halfReported=false
 local u=assert(alive('LIFELINE-1'))
 route('LIFELINE',{wp(u:getPoint(),'WAVE OFF'),orbit(ground(C.hold),'OFFSHORE HOLD',350,45)})
 say('Lifeline holding offshore. Explicit insertion clearance required.')
end
local function clearTransport()
 if terminal()then say(S.result);return end
 if S.phase=='return'then say('Lifeline is returning.');return end
 if S.phase=='ready'then say('Take off first; Lifeline will launch automatically.');return end
 if S.phase=='inserting'then say('Lifeline already cleared; cover the LZ.');return end
 local lead=playerUnit();if not lead or dist(lead:getPoint(),S.lz)>8000 then say('Move within 8 km of the actual insertion site.');return end
 if not safeLZ()then say('Insertion site threatened. Clear nearby hostile ground units first.');return end
 local u=assert(alive('LIFELINE-1'));local land=wp(S.lz,'SEAL INSERTION',30)
 land.task.params.tasks={{number=1,enabled=true,auto=false,id='Land',params={point={x=S.lz.x,y=S.lz.z},durationFlag=false,duration=C.insertionSeconds,combatLandingFlag=false}}}
 route('LIFELINE',{wp(u:getPoint(),'CLEARED IN'),land});S.phase='inserting';S.insertionAt=nil;S.halfReported=false
 say('Lifeline cleared in. Deployment starts only after a stationary landing at the actual LZ.')
end
local function status()
 if terminal()then say(S.result);return end
 local action=S.phase=='ready'and 'Take off; scout the insertion site.' or S.phase=='holding'and 'Scout and clear the actual LZ; explicitly clear Lifeline.' or S.phase=='inserting'and 'Cover Lifeline through a continuous landed minute.' or 'Escort Lifeline and land aboard TARAWA.'
 say('Phase: '..S.phase..'. '..action..' SEALs '..(S.inserted and 'ashore.' or 'aboard Lifeline.')..(S.supportDisabled and ' Air support unavailable.' or ''))
end
local function setup()
 S.lz=findLZ()
 -- Report map/route intelligence independently of enemy units; no automatic target markers.
 trigger.action.markToCoalition(8400,'ACTUAL SEAL INSERTION - clear Lifeline explicitly',S.lz,2,true)
 local menu=missionCommands.addSubMenuForCoalition(2,'Insertion')
 missionCommands.addCommandForCoalition(2,'Status / next action',menu,status)
 missionCommands.addCommandForCoalition(2,'Clear transport to insert',menu,clearTransport)
 missionCommands.addCommandForCoalition(2,'Wave off / hold',menu,function()if terminal()then return end;if S.phase=='ready'then say('Lifeline still aboard TARAWA.')elseif S.inserted or S.phase=='return'then say('Lifeline returning to ship.')else holdTransport()end end)
 missionCommands.addCommandForCoalition(2,'Abort / return to ship',menu,function()if terminal()then return end;if S.phase=='ready'then say('Take off before returning; team remains aboard.')else goHome(not S.inserted)end end)
 local air=missionCommands.addSubMenuForCoalition(2,'Air Support')
 missionCommands.addCommandForCoalition(2,'Request one strike near LZ',air,function()supportCall(function()
  if terminal()or S.inserted or S.supportRTB or S.supportDisabled then say('SWORD strike unavailable.');return end
  if S.strikeAt then say('SWORD already has a request.');return end
  S.strikeAt=timer.getTime();say('SWORD request queued for one safe target; expires in 90 seconds.')
 end)end)
 missionCommands.addCommandForCoalition(2,'Cancel / hold fire',air,function()supportCall(holdFire);say('SWORD hold fire requested; released weapons cannot be recalled.')end)
 missionCommands.addCommandForCoalition(2,'Return Hornets to carrier',air,function()supportCall(function()holdFire();S.supportRTB=true;returnToShip('SWORD',alive('SWORD-1')and 'SWORD-1'or'SWORD-2','STENNIS-1',C.stennisId);say('SWORD returning to STENNIS.')end)end)
 S.phase='ready'
 supportCall(function()local c=assert(ctrl('SWORD'));c:setOption(0,4);c:setCommand({id='Start',params={}})end)
 say('Ready. SWORD launch requested. Take off from TARAWA, scout the LZ, then clear Lifeline. Native deck operations are a test objective.')
end
local function onDeck(u,ship)
 if u:inAir()or dist(u:getPoint(),ship:getPoint())>C.shipRadius then return false end
 local a,b=u:getVelocity(),ship:getVelocity()
 return math.sqrt((a.x-b.x)^2+(a.z-b.z)^2)<2
end
local function tick(_,now)
 if terminal()then return nil end
 if S.phase=='setup'then local ok,err=pcall(setup);if not ok then endMission('failed','Setup failed: '..tostring(err));return nil end end
 local lead,hawk,boat=playerUnit(),alive('LIFELINE-1'),alive('TARAWA-1')
 -- A brief player disappearance (slot change, respawn) is tolerated for playerMissingGrace seconds.
 if lead then S.leadSeen=true;S.leadMissingAt=nil
 elseif S.leadSeen then S.leadMissingAt=S.leadMissingAt or now;if now-S.leadMissingAt>=C.playerMissingGrace then endMission('failed','lead lost; insertion failed.');return nil end end
 for name,u in pairs({transport=hawk or false,ship=boat or false})do
  if u then S[name..'Seen']=true elseif S[name..'Seen']then endMission('failed',name..' lost; insertion failed.');return nil end
 end
 if not lead or not hawk or not boat then return now+2 end
 if not S.positionsChecked then
  for _,p in ipairs({boat:getPoint(),alive('STENNIS-1')and alive('STENNIS-1'):getPoint()or nil})do
   local k=land.getSurfaceType({x=p.x,y=p.z});if k~=2 and k~=3 then endMission('failed','Initial ship placement is not water. Validate ship coordinates in DCS.');return nil end
  end
  S.positionsChecked=true
 end
 if S.phase=='ready'and lead:inAir()then
  local c=assert(ctrl('LIFELINE'));c:setCommand({id='Start',params={}});c:setOption(0,4);holdTransport()
 end
 if not S.supportDisabled then supportCall(function()updateStrike(now)end)end
 if S.phase=='inserting'then
  if not safeLZ()then holdTransport();say('Threat near the insertion site. Wave-off; fresh clearance required.')
  elseif not hawk:inAir()and dist(hawk:getPoint(),S.lz)<=C.lzRadius then
   local v=hawk:getVelocity();local speed=math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
   if speed<1 then
    if not S.insertionAt then S.insertionAt=now;S.halfReported=false;say('Lifeline down. Deploying six SEALs; hold for one minute.')end
    if now-S.insertionAt>=C.insertionSeconds then S.inserted=true;trigger.action.setUserFlag(943,1);goHome(false)
    elseif now-S.insertionAt>=C.insertionSeconds/2 and not S.halfReported then S.halfReported=true;say('Lifeline: deployment halfway complete.')end
   else S.insertionAt=nil;S.halfReported=false end
  else S.insertionAt=nil;S.halfReported=false end
 end
 if S.phase=='return'then
  if onDeck(lead,boat)and onDeck(hawk,boat)then S.homeAt=S.homeAt or now;if now-S.homeAt>=C.recoverySeconds then endMission(S.inserted and 'complete'or'aborted',S.inserted and 'Success: six SEALs ashore; lead and transport recovered aboard TARAWA.'or'Aborted: team returned aboard TARAWA; no insertion completed.');return nil end
  else S.homeAt=nil end
 end
 -- Ship markers follow the vessels; initial mission waypoints are not authoritative.
 if not S.markAt or now-S.markAt>=30 then
  trigger.action.removeMark(8401);trigger.action.markToCoalition(8401,'TARAWA - ACTUAL MOVING RECOVERY',boat:getPoint(),2,true);S.markAt=now
 end
 return now+2
end
timer.scheduleFunction(function(a,now)local ok,nextTime=pcall(tick,a,now);if not ok then env.error('[QUIET_TIDE] '..tostring(nextTime));endMission('failed','Mission logic error; inspect DCS log.');return nil end;return nextTime end,nil,timer.getTime()+2)
