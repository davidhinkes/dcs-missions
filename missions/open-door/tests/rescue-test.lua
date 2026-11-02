-- Tests state transitions with a simulated DCS API, not aircraft flight dynamics.
local printResult=print
local now,queue,units,groups,commands,flags,messages,marks,activated,smokes,statics
local function reset(opts)
  opts=opts or{};now=0;queue={};units={};groups={};commands={};flags={};messages={};marks={};activated={};smokes={};statics={}
  dofile('.build/config.lua');dofile('.build/mission.lua')
  env={mission=mission,info=function()end,error=function()end}
  local function addGroup(d)
    local g={name=d.name,units={},active=not d.lateActivation}
    function g:isExist()return true end
    function g:getUnits()return self.units end
    for _,data in pairs(d.units)do
      local u={name=data.name,p={x=data.x,y=data.alt or 40,z=data.y},air=false,life=100,v=0,g=g}
      function u:isExist()return self.life>0 and self.g.active end
      function u:getLife()return self.life end
      function u:getPoint()return self.p end
      function u:inAir()return self.air end
      function u:getVelocity()return {x=self.v,y=0,z=0}end
      function u:destroy()self.life=0 end
      units[u.name]=u;g.units[#g.units+1]=u
    end
    function g:getController()return {
      setOnOff=function(_,v)self.on=v end,setTask=function(_,t)self.task=t end,
      setCommand=function(_,c)self.command=c end,setOption=function(_,k,v)self.option={k,v}end
    }end
    groups[d.name]=g;return g
  end
  for _,side in pairs(mission.coalition)do for _,country in pairs(side.country or{})do for _,cat in ipairs({'helicopter','vehicle'})do for _,g in pairs((country[cat]or{}).group or{})do addGroup(g)end end end end
  Unit={getByName=function(n)return units[n]end}
  Group={Category={GROUND=2},getByName=function(n)return groups[n]end}
  Object={Category={SCENERY=5}}
  land={getHeight=function()return 40 end,getSurfaceType=function()return opts.water and 3 or 1 end}
  world={VolumeType={SPHERE=0},searchObjects=function(_,volume,fn)
    if opts.blockLZ and volume.params.radius==18 and math.abs(volume.params.point.x-OPEN_DOOR_CONFIG.plannedLZ.x)<(opts.blockRadius or 1)then fn({})end
    if opts.blockForward and math.abs(volume.params.point.x-OPEN_DOOR_CONFIG.alternateFarp.x)<300 then fn({})end
  end}
  coalition={addGroup=function(_,_,g)if opts.noServices then error('service unavailable')end;return addGroup(g)end,addStaticObject=function(_,u)statics[u.name]=u;return u end}
  trigger={smokeColor={Green=0},action={
    outTextForCoalition=function(_,s)messages[#messages+1]=s end,
    setUserFlag=function(k,v)flags[k]=v end,
    markToCoalition=function(id,text,p)marks[id]={text=text,p=p}end,
    smoke=function(p)smokes[#smokes+1]=p end,
    activateGroup=function(g)g.active=true;activated[g.name]=now end
  }}
  missionCommands={
    addSubMenuForCoalition=function(_,name,parent)return (parent and parent..'/'or'')..name end,
    addCommandForCoalition=function(_,name,parent,fn)local key=parent..'/'..name;assert(not commands[key],'Duplicate menu path');commands[key]=fn end
  }
  timer={getTime=function()return now end,scheduleFunction=function(fn,arg,t)queue[#queue+1]={fn=fn,arg=arg,t=t}end}
  dofile('src/rescue.lua')
end
local function advance(to)
  while true do table.sort(queue,function(a,b)return a.t<b.t end);local item=queue[1]
    if not item or item.t>to then break end
    table.remove(queue,1);now=item.t;local nextTime=item.fn(item.arg,now);if nextTime then item.t=nextTime;queue[#queue+1]=item end
  end
  now=to
end
local function move(n,p,air,speed)local u=units[n];u.p={x=p.x,y=p.y or 40,z=p.z or p.y};u.air=air or false;u.v=speed or 0 end
local function cmd(name)assert(commands['OPEN DOOR/'..name],'Missing menu '..name)()end
local function clearThreats()
  for n,u in pairs(units)do if n:match('^WATCHTOWER')or n:match('^GUARD')then u.life=0 end end
end
local function launchAndHold()
  move('LATCH-1',{x=OPEN_DOOR_CONFIG.home.x+1000,y=OPEN_DOOR_CONFIG.home.y},true,45);advance(4)
  assert(OPEN_DOOR.launched and groups.LIFELINE.command.id=='Start' and groups.LIFELINE.task.id=='Follow')
  move('LATCH-1',{x=OPEN_DOOR_CONFIG.building.x-9000,y=OPEN_DOOR_CONFIG.building.y},true,45);advance(6)
  assert(OPEN_DOOR.phase=='holding')
end
local function beginLanding()
  reset();advance(2);launchAndHold();clearThreats();cmd('Transport/Clear Black Hawk to land');assert(OPEN_DOOR.phase=='ingress')
end
local function land()
  move('LIFELINE-1',OPEN_DOOR.lz,false,0);advance(now+2);assert(OPEN_DOOR.phase=='rescue')
end
local function home()
  move('LIFELINE-1',OPEN_DOOR.home,false,0);advance(now+2);advance(now+20)
end
reset();advance(600);assert(OPEN_DOOR.phase=='ready' and not OPEN_DOOR.launched and not activated.RELIEF)
assert(groups.HOSTAGES.on==false and groups['HOSTAGE-BUILDING'].on==false)
assert(mission.forcedOptions.labels==0 and mission.forcedOptions.optionsView=='optview_onlyallies')
local pads={};local flightGroups={};local support={}
for _,country in pairs(mission.coalition.blue.country)do
  for _,g in pairs((country.static or{}).group or{})do for _,u in pairs(g.units)do pads[u.unitId]=u end end
  for _,g in pairs((country.helicopter or{}).group or{})do flightGroups[g.name]=g end
  for _,g in pairs((country.vehicle or{}).group or{})do support[g.name]=g end
end
for _,g in pairs(flightGroups)do
  local start=g.route.points[1]
  assert(start.type=='TakeOffGroundHot' and start.action=='From Ground Area Hot' and start.alt==0 and start.alt_type=='RADIO')
  assert(not start.helipadId and not start.linkUnit,'Ground starts must not use conflicting parking links')
  for _,u in pairs(g.units)do
    assert(u.alt==0 and u.alt_type=='RADIO' and not u.parking and not u.parking_id,'No copied BARO height or parking assignment')
    local matching=0
    for _,p in pairs(pads)do if p.type=='SINGLE_HELIPAD' and p.x==u.x and p.y==u.y then matching=matching+1;assert(p.shape_name=='FARP')end end
    assert(matching==1,'Every helicopter must start on exactly one real visible helipad')
  end
end
for i=1,4 do local u=flightGroups.LATCH.units[i];for j=i+1,4 do local v=flightGroups.LATCH.units[j];assert(math.abs(u.x-v.x)>=60)end end
for _,prefix in ipairs({'FOOTHOLD','TRANSPORT'})do
  for _,suffix in ipairs({' FUEL',' SERVICE',' COMMS'})do assert(support[prefix..suffix]and not support[prefix..suffix].lateActivation)end
  local facilities={};for _,u in pairs(pads)do if u.name:match('^'..prefix..' ')then facilities[u.type]=true end end
  assert(facilities['FARP Fuel Depot']and facilities['FARP Ammo Dump Coating']and facilities['FARP Tent']and facilities['FARP CP Blindage'])
end
for id=100,103 do for _,name in ipairs({'FOOTHOLD FUEL','FOOTHOLD SERVICE','FOOTHOLD COMMS'})do
  for _,u in pairs(support[name].units)do local p=pads[id];assert(math.sqrt((p.x-u.x)^2+(p.y-u.y)^2)<=150)end
end end
printResult('PASS: departure helipads, separated zero-AGL hot-ground starts and complete startup FARP services')
local nav=groups.LATCH -- The runtime mock records flight control; inspect source mission for imported targets.
local points=nil
for _,country in pairs(mission.coalition.blue.country)do for _,g in pairs((country.helicopter or{}).group or{})do if g.name=='LATCH'then points=g.NavTargetPoints end end end
assert(points and points[1].text_comment=='1T|1|SA13' and points[2].text_comment=='2T|1|UNK')
assert(points[1].x==OPEN_DOOR_CONFIG.sam.x and points[1].y==OPEN_DOOR_CONFIG.sam.y)
assert(points[2].x==OPEN_DOOR_CONFIG.building.x and points[2].y==OPEN_DOOR_CONFIG.building.y)
assert(#flightGroups.LATCH.route.points==4 and flightGroups.LATCH.route.points[2].name:match('IP'))
for _,p in pairs(flightGroups.LATCH.route.points)do for _,target in ipairs({OPEN_DOOR_CONFIG.sam,OPEN_DOOR_CONFIG.building})do
  assert(math.sqrt((p.x-target.x)^2+(p.y-target.y)^2)>100,'Enemy target must not be a route waypoint')
end end
printResult('PASS: separate Kiowa 1T/2T target points match the SAM and protected building')
assert(OPEN_DOOR.alternate and marks[8205])
local f=OPEN_DOOR.alternate;local b=OPEN_DOOR_CONFIG.building
assert(math.abs(math.sqrt((f.x-b.x)^2+(f.z-b.y)^2)/1852-25)<0.1)
for i=1,4 do assert(statics['KEYSTONE PAD '..i].unitId==399+i)end
for _,name in ipairs({'KEYSTONE FUEL','KEYSTONE SERVICE','KEYSTONE COMMS'})do
  assert(groups[name].active)
  for _,u in pairs(groups[name].units)do for i=1,4 do local p=statics['KEYSTONE PAD '..i];assert(math.sqrt((u.p.x-p.x)^2+(u.p.z-p.y)^2)<=150)end end
end
local departurePos=OPEN_DOOR_CONFIG.home;assert(math.abs(math.sqrt((departurePos.x-b.x)^2+(departurePos.y-b.y)^2)/1852-15)<0.01)
assert(not statics['FOOTHOLD PAD 1'],'Departure pads must not relocate beneath starting aircraft')
printResult('PASS: FOOTHOLD departure is 15 nm from objective; KEYSTONE alternate is about 25 nm from objective, four native pads and all service vehicles within 150 m')
local countries=mission.coalition.neutrals.country;local un=false;local neutralBuilding=false
for _,c in pairs(countries)do if c.name=='UN Peacekeepers'then assert(c.id==7);un=true;for _,g in pairs(c.vehicle.group)do if g.name=='HOSTAGE-BUILDING'then neutralBuilding=true end end end end
assert(un and neutralBuilding,'Hostages and protected building must be neutral to prevent premature guard attacks')
printResult('PASS: startup waits indefinitely, hostages disabled/neutral, labels and map restricted')
reset();advance(2);launchAndHold();clearThreats();advance(120);assert(OPEN_DOOR.phase=='holding' and not OPEN_DOOR.cleared)
printResult('PASS: defeating defenders never grants automatic extraction clearance')
reset();advance(2);launchAndHold();cmd('Transport/Clear Black Hawk to land');assert(OPEN_DOOR.phase=='holding')
units['WATCHTOWER-1'].life=0;cmd('Transport/Clear Black Hawk to land');assert(OPEN_DOOR.phase=='holding')
clearThreats();cmd('Transport/Clear Black Hawk to land');assert(OPEN_DOOR.phase=='ingress')
local landing=groups.LIFELINE.task.params.route.points[2].task.params.tasks[1]
assert(landing.id=='Land' and landing.params.durationFlag==false and landing.params.point.x==OPEN_DOOR.lz.x)
printResult('PASS: known SAM and close guards block clearance; native Land task uses actual LZ')
beginLanding();land();advance(186);assert(not OPEN_DOOR.boarded);advance(188);assert(OPEN_DOOR.boarded and OPEN_DOOR.onboard==6 and flags[920])
assert(OPEN_DOOR.phase=='return' and not flags[921])
local recovery=groups.LIFELINE.task.params.route.points[4];assert(recovery.type=='Land' and recovery.linkUnit==200)
home();assert(OPEN_DOOR.phase=='complete' and flags[921] and not flags[922])
printResult('PASS: three-minute boarding then linked FARP recovery, twenty-second full-success hold')
beginLanding();land();units['HOSTAGES-2']:destroy();units['HOSTAGES-4']:destroy();advance(188);assert(OPEN_DOOR.onboard==4);home()
assert(OPEN_DOOR.phase=='partial' and flags[922] and not flags[921])
printResult('PASS: hostage casualties allow remaining four to return for partial success')
beginLanding();land();advance(80);cmd('Transport/Hold / wave off');assert(OPEN_DOOR.phase=='holding' and not OPEN_DOOR.rescueAt)
advance(200);assert(not OPEN_DOOR.boarded);cmd('Transport/Clear Black Hawk to land');land();local started=now
advance(started+178);assert(not OPEN_DOOR.boarded);advance(started+180);assert(OPEN_DOOR.boarded)
printResult('PASS: wave-off resets progress and requires fresh explicit clearance')
beginLanding();land();advance(80);move('LIFELINE-1',OPEN_DOOR.lz,false,2);advance(82);assert(not OPEN_DOOR.rescueAt)
move('LIFELINE-1',OPEN_DOOR.lz,true,0);advance(300);assert(not OPEN_DOOR.boarded)
land();local started=now;advance(started+180);assert(OPEN_DOOR.boarded)
printResult('PASS: movement/takeoff prevents boarding and resets rescue timing')
beginLanding();move('LIFELINE-1',{x=OPEN_DOOR.lz.x+81,z=OPEN_DOOR.lz.z},false,0);advance(210);assert(not OPEN_DOOR.rescueAt)
printResult('PASS: landed outside 80 m LZ radius does not start rescue')
beginLanding();land();local threat=units['GUARD-WEST-1'];threat.life=100;move(threat.name,OPEN_DOOR.lz,false,0);advance(20)
assert(OPEN_DOOR.phase=='holding' and not OPEN_DOOR.rescueAt)
printResult('PASS: renewed close ground threat forces wave-off')
reset();advance(2);units['HOSTAGE-BUILDING-1']:destroy();advance(4);assert(OPEN_DOOR.phase=='failed' and flags[923])
printResult('PASS: destruction of hostage building kills occupants and fails extraction')
reset();advance(2);for i=1,6 do units['HOSTAGES-'..i]:destroy()end;advance(4);assert(flags[923])
printResult('PASS: no surviving hostages fails mission')
reset();advance(2);units['LIFELINE-1']:destroy();advance(4);assert(flags[923])
reset();advance(2);units['LATCH-1']:destroy();advance(4);assert(flags[923])
printResult('PASS: player or Black Hawk loss fails mission')
beginLanding();land();advance(188);units['LIFELINE-1']:destroy();advance(190);assert(flags[923] and OPEN_DOOR.onboard==0)
printResult('PASS: Black Hawk loss after boarding loses passengers, never counts success')
reset();local player=units['LATCH-1'];units['LATCH-1']=nil;advance(300);assert(not flags[923]);units['LATCH-1']=player;advance(302);assert(OPEN_DOOR.playerSeen)
printResult('PASS: delayed player spawn is not treated as player death')
reset({blockLZ=true});advance(2);assert(OPEN_DOOR.phase=='ready' and OPEN_DOOR.lz.x~=OPEN_DOOR_CONFIG.plannedLZ.x)
assert(marks[8201].p.x==OPEN_DOOR_CONFIG.building.x and marks[8202].p.x==OPEN_DOOR_CONFIG.sam.x)
cmd('Rescue/Mark actual LZ (green)');assert(smokes[1].x==OPEN_DOOR.lz.x)
printResult('PASS: LZ avoids scenery while precise intelligence remains fixed; smoke marks actual LZ')
reset({blockLZ=true,blockRadius=400});advance(2);assert(OPEN_DOOR.phase=='ready' and math.abs(OPEN_DOOR.lz.x-OPEN_DOOR_CONFIG.plannedLZ.x)>=400)
reset({water=true});advance(2);assert(OPEN_DOOR.phase=='failed' and flags[923])
printResult('PASS: extended LZ search survives an obstructed first 300 m; invalid main-site terrain is reported')
reset();advance(2);launchAndHold();move('LATCH-1',{x=OPEN_DOOR_CONFIG.building.x-7000,y=OPEN_DOOR_CONFIG.building.y},true,45);advance(8)
assert(OPEN_DOOR.alertAt==8);advance(186);assert(not activated.RELIEF);advance(188);assert(activated.RELIEF==188 and activated['RELIEF-TRUCKS']==188)
local destination=groups.RELIEF.task.params.route.points[2]
assert(math.sqrt((destination.x-OPEN_DOOR_CONFIG.building.x)^2+(destination.y-OPEN_DOOR_CONFIG.building.y)^2)<350)
printResult('PASS: ground reinforcement timing starts at village alert, not mission launch')
reset();advance(2);launchAndHold();cmd('Transport/Abort and return');assert(OPEN_DOOR.phase=='return');home();assert(OPEN_DOOR.phase=='failed')
printResult('PASS: abort before boarding returns empty and does not award success')
reset();advance(2);local n=0;for k in pairs(commands)do n=n+1;assert(not k:match('GUARD')and not k:match('WATCHTOWER'))end;assert(n==5)
assert(commands['OPEN DOOR/Transport/Hold / wave off']and commands['OPEN DOOR/Rescue/Status'])
printResult('PASS: F10 hierarchy has five unique commands and discloses no internal enemy identities')
reset({blockForward=true});advance(2);assert(OPEN_DOOR.alternate and math.abs(OPEN_DOOR.alternate.x-OPEN_DOOR_CONFIG.alternateFarp.x)>=300)
assert(marks[8205].p.x==OPEN_DOOR.alternate.x)
assert(marks[8201].p.x==OPEN_DOOR_CONFIG.building.x and marks[8202].p.x==OPEN_DOOR_CONFIG.sam.x)
printResult('PASS: forward camp relocates as one footprint around scenery; intel targets remain fixed')
-- Execute the generated native action sequence with recording stubs. This
-- checks serialization and ordering, not the engine's rendered tree removal.
local cleared,scripts=0,0
a_remove_scene_objects=function(id,mask)
  assert(scripts==0 and mask==1)
  local found=false
  for _,z in pairs(mission.triggers.zones)do if z.zoneId==id then found=true;assert(z.name:match('FOOTHOLD'))end end
  assert(found);cleared=cleared+1
end
getValueResourceByKey=function(key)return key end
a_do_script_file=function()assert(cleared==5);scripts=scripts+1 end
assert(loadstring(mission.trig.actions[1]))()
assert(cleared==5 and scripts==2)
for i=1,5 do local a=mission.trigrules[1].actions[i];assert(a.predicate=='a_remove_scene_objects' and a.objects_mask==1)end
printResult('PASS: five native trees-only clearings execute before both mission scripts')
printResult('ALL OPEN DOOR LOGIC TESTS PASSED (mock DCS API; not a flight test)')
