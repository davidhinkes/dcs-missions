-- Exercise mission state transitions with a simulated DCS API, under DCS Lua 5.1.
local originalPrint=print
local now,queue,units,groups,flags,activated,messages,commands,blueSmokeTimes,statics,greenSmokeTimes,markers
local function makeUnit(d)
  local u={name=d.name,p={x=d.x,y=d.alt or 0,z=d.y},life=100,air=d.type=='OH58D' or d.type=='FA-18C_hornet' or d.type=='MiG-29 Fulcrum',velocity={x=0,y=0,z=0}}
  function u:isExist() return self.life>0 end
  function u:getID() return d.unitId end
  function u:getName()return self.name end
  function u:getAmmo()return {{count=self.missiles or 2,desc={category=1}}}end
  function u:getLife() return self.life end
  function u:getPoint() return self.p end
  function u:inAir() return self.air end
  function u:getVelocity() return self.velocity end
  function u:destroy() self.life=0 end
  units[u.name]=u;return u
end
local function addGroup(d)
  local g={units={},hidden=d.hidden,hiddenOnMFD=d.hiddenOnMFD};for i,u in pairs(d.units)do g.units[i]=makeUnit(u) end
  function g:getUnit(i)return self.units[i]end
  function g:getController()return {setCommand=function(_,cmd)self.command=cmd end,setOnOff=function()end,pushTask=function(_,t)self.attacks=self.attacks or {};table.insert(self.attacks,t)end,resetTask=function()self.attacks={}end,setTask=function(_,t) self.task=t end,setOption=function(_,k,v)self.option=v end}end
  groups[d.name]=g;return g
end
local function reset(water)
  now=0;queue={};units={};groups={};flags={};activated={};messages={};commands={};blueSmokeTimes={};statics={};greenSmokeTimes={};markers={}
  dofile('.build/mission.lua')
  env={mission=mission,info=function()end,error=function(t)error(t)end}
  Unit={getByName=function(n)return units[n]end}
  Group={Category={GROUND=2},getByName=function(n)return groups[n]end}
  Object={Category={SCENERY=5}}
  land={getHeight=function()return 40 end,getSurfaceType=function()return water and 3 or 1 end,isVisible=function()return true end}
  world={VolumeType={SPHERE=0},searchObjects=function()end}
  coalition={addGroup=function(_,_,g)return addGroup(g)end,addStaticObject=function(_,s)statics[s.name]=s;return s end}
  trigger={smokeColor={Green=0,Blue=4},action={
    outTextForCoalition=function(_,t)table.insert(messages,t)end,
    setUserFlag=function(k,v)flags[k]=v end,smoke=function(_,color)if color==4 then table.insert(blueSmokeTimes,now)end;if color==0 then table.insert(greenSmokeTimes,now)end end,markToCoalition=function(id,text,p)markers[id]={text=text,p=p}end,removeMark=function()end,
    activateGroup=function(g)for n,o in pairs(groups)do if o==g then activated[n]=now end end end}}
  missionCommands={
    addSubMenuForCoalition=function(_,name,parent)
      assert(parent==nil and (name=='Rescue' or name=='Air Support' or name=='Overwatch'),'Unexpected intermediate menu')
      return name
    end,
    addCommandForCoalition=function(_,name,parent,fn)
      local rescue=name=='Status / return directions' or name=='Request survivor smoke (green)'
      local overwatch=name=='Engage vehicles near me' or name=='Hold fire / resume overwatch' or name=='Return to HAVEN'
      assert(parent==(rescue and 'Rescue' or overwatch and 'Overwatch' or 'Air Support'),'Wrong command category')
      assert(not commands[name],'Duplicate command');commands[name]=fn
    end
  }
  timer={getTime=function()return now end,scheduleFunction=function(fn,arg,t)table.insert(queue,{fn=fn,arg=arg,t=t})end}
  for _,side in pairs(mission.coalition)do for _,c in pairs(side.country or {})do for _,cat in ipairs({'plane','helicopter','vehicle'})do for _,g in pairs((c[cat]or{}).group or{})do addGroup(g) end end end end
  units['RESCUE-1'].air=false;units['RESCUE-2'].air=false;units['LONGBOW-1'].air=false;units['LONGBOW-2'].air=false
  assert(loadfile('src/rescue.lua'))()
end
local function advance(to)
  while true do
    table.sort(queue,function(a,b)return a.t<b.t end)
    if not queue[1] or queue[1].t>to then break end
    local item=table.remove(queue,1);now=item.t;local nt=item.fn(item.arg,now)
    if nt then item.t=nt;table.insert(queue,item)end
  end
  now=to
end
local function move(name,p,air,speed)
  local u=units[name];u.p={x=p.x,y=p.y or 40,z=p.z};u.air=air;u.velocity={x=speed or 0,y=0,z=0}
end
local function isolateCAS(prefix)
 for _,name in ipairs({'COAST-SA6-NORTH','COAST-STRELA-CENTRAL','HUNTER-NORTH','HUNTER-EAST','HUNTER-WEST','CHECKPOINT','REINFORCEMENTS'})do
  if name~=prefix then for i=1,4 do local u=units[name..'-'..i];if u then u.life=0 end end end
 end
end
reset()
world.searchObjects=function(_,volume,callback)
  if volume.params.point.z>18000 and volume.params.radius>=40 then callback({}) end
end
advance(2)
assert(GREEN_LANTERN.phase=='ingress' and groups['HUNTER-EAST'] and not flags[903])
local commandCount=0;for _ in pairs(commands)do commandCount=commandCount+1 end;assert(commandCount==9)
originalPrint('PASS: nine unique commands directly under Rescue, Air Support and Overwatch; no mission-name wrapper')
originalPrint('PASS: patrol spawns where scenery prevents a helicopter-size clearing')
reset();advance(600);assert(GREEN_LANTERN.phase=='ingress' and not GREEN_LANTERN.huntAt and not activated.GUARDIAN)
originalPrint('PASS: ten minutes at FARP does not start the hunt or air package')
reset();advance(2);assert(GREEN_LANTERN.phase=='ingress')
move('RESCUE-1',{x=42000,z=10500},true,45);advance(4)
assert(activated.GUARDIAN==4 and GREEN_LANTERN.huntAt==4)
assert(groups['HUNTER-NORTH'].task.params.route.points[2].x==GREEN_LANTERN.pickup.x)
advance(78);assert(not activated.VIPER);advance(80);assert(activated.VIPER==80)
move('RESCUE-1',GREEN_LANTERN.pickup,false,0);advance(90);assert(not GREEN_LANTERN.boarded)
move('RESCUE-1',GREEN_LANTERN.pickup,true,0);advance(92);assert(not GREEN_LANTERN.pickupAt)
move('RESCUE-1',GREEN_LANTERN.pickup,false,0);advance(112);assert(not GREEN_LANTERN.boarded)
advance(114);assert(GREEN_LANTERN.boarded and flags[901]==1 and not flags[903])
move('RESCUE-1',{x=42807.4296875,z=6298.9243164063},false,0);advance(132)
assert(not flags[902], 'The old airfield must not complete the rescue')
move('RESCUE-1',GREEN_LANTERN.home,false,0);advance(150)
assert(GREEN_LANTERN.phase=='complete' and flags[902]==1)
originalPrint('PASS: hunt, coordinated cover/MiG timing, boarding interruption, pickup and delivery')
reset();advance(2);units['SURVIVOR-1']:destroy();advance(4);assert(flags[903]==1)
originalPrint('PASS: pilot killed failure')
reset();advance(2);move('HUNTER-NORTH-1',GREEN_LANTERN.pickup,false);advance(24);assert(flags[903]==1)
originalPrint('PASS: pilot captured failure')
reset();advance(4);units['RESCUE-1']:destroy();advance(16);assert(flags[903]==1)
originalPrint('PASS: rescue helicopter lost failure')
reset();advance(2);move('RESCUE-1',{x=42000,z=10500},true,45);advance(1504);assert(flags[903]==1)
originalPrint('PASS: rescue window expiry')
reset();local delayed=units['RESCUE-1'];units['RESCUE-1']=nil;advance(60)
assert(not flags[903] and not GREEN_LANTERN.huntAt)
units['RESCUE-1']=delayed;advance(62);assert(GREEN_LANTERN.playerSeen and not flags[903])
originalPrint('PASS: delayed player spawn does not fail; player is acquired when available')
reset();local renamed=units['RESCUE-1'];units['RESCUE-1']=nil
function renamed:getTypeName()return 'OH58D'end
function renamed:getName()return 'Renamed pilot'end
units['Renamed pilot']=renamed;coalition.getPlayers=function()return {renamed}end
advance(4);assert(GREEN_LANTERN.playerSeen and GREEN_LANTERN.playerName=='Renamed pilot' and not flags[903])
originalPrint('PASS: occupied OH-58 is discovered when its unit name differs')
reset();advance(2)
local pickup=GREEN_LANTERN.pickup
move('RESCUE-1',{x=pickup.x+401,z=pickup.z},false,0);advance(24);assert(not GREEN_LANTERN.boarded and not GREEN_LANTERN.pickupAt)
move('RESCUE-1',{x=pickup.x+90,z=pickup.z},false,0);advance(46);assert(GREEN_LANTERN.boarded)
originalPrint('PASS: pickup accepts 90 m and rejects 401 m')
reset();advance(2)
for _,prefix in ipairs({'HAVEN','LANTERN'}) do
 local pad=prefix=='HAVEN' and {x=19948.236328125,z=6806.8149414062} or GREEN_LANTERN.home
 for _,suffix in ipairs({'FUEL','SERVICE','COMMS'}) do
  local g=groups[prefix..' '..suffix];assert(g)
  for _,u in pairs(g.units) do
   local p=u:getPoint();assert(math.sqrt((p.x-pad.x)^2+(p.z-pad.z)^2)<150)
  end
 end
end
originalPrint('PASS: service vehicles at both FARPs are within 150 m of their pads')
reset();advance(2);assert(not activated.GUARDIAN)
units['RESCUE-1'].air=true;advance(4);assert(activated.GUARDIAN==4)
advance(100);assert(not activated.VIPER, 'MiGs must not launch just because carrier flight launched')
move('RESCUE-1',{x=42000,z=10500},true,45);advance(102)
advance(176);assert(not activated.VIPER);advance(178);assert(activated.VIPER)
originalPrint('PASS: carrier flight launches at takeoff; MiG timing remains tied to extraction approach')
reset();advance(2);units['RESCUE-1'].air=true;advance(4)
commands['Request CAS near me']()
advance(182);assert(not activated.BRUISER)
advance(184);assert(activated.BRUISER==184 and not groups.BRUISER.attacks)
local p=GREEN_LANTERN.pickup
move('RESCUE-1',{x=p.x-2500,z=p.z},true);advance(186);isolateCAS('HUNTER-NORTH')
commands['Request CAS near me']()
move('BRUISER-1',{x=p.x+10000,z=p.z},true)
move('HUNTER-NORTH-1',{x=p.x+100,z=p.z},false)
move('HUNTER-NORTH-2',{x=p.x+120,z=p.z},false)
advance(188);assert(not groups.BRUISER.attacks, 'CAS must hold when both targets are close to pilot')
move('HUNTER-NORTH-1',{x=p.x+1500,z=p.z},false)
advance(190);assert(groups.BRUISER.attacks[1].params.unitId==units['HUNTER-NORTH-1']:getID())
assert(groups.BRUISER.attacks[1].id=='AttackUnit' and groups.BRUISER.attacks[1].params.weaponType==9663676414)
commands['Hold fire / cancel CAS']();assert(#groups.BRUISER.attacks==0 and groups.BRUISER.option==4)
originalPrint('PASS: CAS wave delayed three minutes, queued requests, friendly-separation check, explicit target task and hold-fire cancellation')
reset();advance(2);units['RESCUE-1'].air=true;advance(4);advance(184)
local sam=units['COAST-SA6-NORTH-1'];local pt=sam:getPoint()
move('RESCUE-1',{x=pt.x+3000,z=pt.z},true)
commands['Request CAS near me']()
move('BRUISER-1',{x=pt.x+5000,z=pt.z},true)
advance(186);assert(groups.BRUISER.attacks[1].params.unitId==sam:getID())
assert(groups.BRUISER.attacks[1].params.unitId~=units['COAST-SA6-NORTH SUPPORT-1']:getID())
originalPrint('PASS: coastal SAM request targets launcher during ingress, outside extraction tasking radius')
reset();advance(2);assert(not activated.WEASEL and not activated['HIND-PATROL'])
units['RESCUE-1'].air=true;advance(4);assert(activated.WEASEL==4 and activated.GUARDIAN==4)
commands['Request radar suppression']()
assert(groups.WEASEL.attacks[1].params.weaponType==32768)
assert(groups.WEASEL.attacks[1].params.unitId==units['COAST-SA6-NORTH-1']:getID())
move('RESCUE-1',{x=42000,z=23000},true,45);advance(6);assert(activated['HIND-PATROL']==6)
assert(not activated.VIPER, 'Hinds should arrive before the separate MiG trigger')
units['COAST-SA6-NORTH-1']:destroy();advance(8);assert(GREEN_LANTERN.radarCleared)
originalPrint('PASS: SEAD package launch, HARM-only radar target, Hind patrol activation and confirmed SA-6 destruction')
reset();advance(2)
move('RESCUE-1',GREEN_LANTERN.pickup,false,0);advance(24)
assert(GREEN_LANTERN.boarded and #blueSmokeTimes==0)
advance(262);assert(#blueSmokeTimes==0)
advance(264);assert(#blueSmokeTimes==0)
commands['Status / return directions']();assert(messages[#messages]:find('grid bearing') and messages[#messages]:find('range'))
assert(not commands['Request recovery smoke (blue)'])
assert(GREEN_LANTERN.home.x==-1802.8537883092722 and GREEN_LANTERN.home.z==1000)
assert(statics['FARP LANTERN'].x==GREEN_LANTERN.home.x and statics['FARP LANTERN'].y==GREEN_LANTERN.home.z)
originalPrint('PASS: fixed WP4 recovery location; no recovery smoke or menu; bearing/range in status')
reset()
world.searchObjects=function(_,volume,callback)
 local p=volume.params.point
 if p.z>6846 and p.x>19898 and p.x<19998 then callback({})end
end
advance(2);assert(statics['HAVEN FARP Tent'])
originalPrint('PASS: logistics searches an alternate sector when the assigned sector is obstructed')
reset();advance(2);assert(GREEN_LANTERN.checkpoint and not GREEN_LANTERN.westPatrol)
move('RESCUE-1',{x=42000,z=23000},true,45);advance(4);assert(GREEN_LANTERN.westPatrol)
advance(242);assert(not GREEN_LANTERN.reinforcementAttempted)
advance(244);assert(GREEN_LANTERN.reinforcements and #groups.REINFORCEMENTS.units==4)
assert(groups.REINFORCEMENTS.task.params.route.points[2].x==GREEN_LANTERN.pickup.x)
originalPrint('PASS: checkpoint, western patrol and four-vehicle reinforcement timing')
reset();advance(2);move('RESCUE-1',GREEN_LANTERN.pickup,false,0);advance(300)
assert(GREEN_LANTERN.boarded and not GREEN_LANTERN.reinforcementAttempted)
originalPrint('PASS: reinforcements do not spawn after successful pickup')
reset();advance(2);units['RESCUE-1'].air=true;advance(4);advance(184)
local p=GREEN_LANTERN.pickup
move('BRUISER-1',{x=p.x+10000,z=p.z},true)
move('HUNTER-NORTH-1',{x=p.x+1500,z=p.z},false)
move('HUNTER-NORTH-2',{x=p.x+1500,z=p.z+20},false)
move('LONGBOW-2',{x=p.x+1500,z=p.z+50},true)
commands['Request CAS near me']();advance(188);assert(not groups.BRUISER.attacks)
originalPrint('PASS: CAS clearance protects the independent overwatch flight')
local locations={}
for seed=1,20 do
 math.randomseed(seed);reset();advance(2)
 local p=GREEN_LANTERN.pickup;assert((p.x-42000)^2+(p.z-16000)^2<=40000.0001)
 locations[string.format('%.1f,%.1f',p.x,p.z)]=true
 assert(markers[8101].p.x==42000 and markers[8101].p.z==16000)
 assert(groups.SURVIVOR.hidden and groups.SURVIVOR.hiddenOnMFD)
 assert(#greenSmokeTimes==0)
end
local variants=0;for _ in pairs(locations)do variants=variants+1 end;assert(variants>1)
commands['Request survivor smoke (green)']();assert(#greenSmokeTimes==0)
move('RESCUE-1',{x=42000,z=17000},true)
commands['Request survivor smoke (green)']();assert(#greenSmokeTimes==1)
originalPrint('PASS: varied pickup locations stay within 200 m; approximate marker, hidden unit and requested-only smoke')
local savedRandom=math.random
math.random=function(n)if n then return 1 end;return 0.5 end
reset();world.searchObjects=function(_,volume,callback)
 local p=volume.params.point
 if math.abs(p.x-42000)>1 or math.abs(p.z-16100)>1 then
  if p.x>41750 and p.x<42250 and p.z>15750 and p.z<16250 then callback({})end
 end
end
advance(2);assert(math.abs(GREEN_LANTERN.pickup.x-42000)<1 and math.abs(GREEN_LANTERN.pickup.z-16100)<1)
math.random=savedRandom
originalPrint('PASS: constrained fallback finds a narrow clearing without leaving the search area')
reset();advance(2)
for name in pairs(commands) do
 assert(not name:find('HUNTER') and not name:find('CHECKPOINT') and not name:find('REINFORCEMENTS') and not name:find('SA%-6') and not name:find('STRELA'))
end
units['RESCUE-1'].air=true;advance(4);advance(184)
commands['Request CAS near me']()
local p=GREEN_LANTERN.pickup
move('BRUISER-1',{x=p.x+10000,z=p.z},true);advance(186)
assert(not groups.BRUISER.attacks, 'Request at FARP must not select enemies at extraction')
move('RESCUE-1',{x=p.x-2500,z=p.z},true);advance(188);isolateCAS('HUNTER-NORTH')
move('HUNTER-NORTH-1',{x=p.x+1000,z=p.z},false)
move('HUNTER-NORTH-2',{x=p.x+8000,z=p.z},false)
commands['Request CAS near me']();advance(190)
assert(groups.BRUISER.attacks[1].params.unitId==units['HUNTER-NORTH-1']:getID())
for _,text in ipairs(messages) do assert(not text:find('HUNTER%-') and not text:find('COAST%-')) end
originalPrint('PASS: generic menus and radio calls disclose no unit names; CAS stays within the requested 5 km area')
reset();advance(2)
local p=GREEN_LANTERN.pickup
move('RESCUE-1',{x=p.x+400,z=p.z},false,0);advance(4)
assert(GREEN_LANTERN.pickupDuration==120)
advance(122);assert(not GREEN_LANTERN.boarded)
advance(124);assert(GREEN_LANTERN.boarded)
reset();advance(2);local p=GREEN_LANTERN.pickup
move('RESCUE-1',{x=p.x+300,z=p.z},false,0);advance(20)
move('RESCUE-1',{x=p.x+401,z=p.z},false,0);advance(22)
assert(not GREEN_LANTERN.pickupAt and not GREEN_LANTERN.pickupDuration and not GREEN_LANTERN.boarded)
originalPrint('PASS: 400 m pickup takes 120 s; moving outside pickup radius resets approach')

-- Explicitly fly the mock support pair; no native flight dynamics are simulated.
local function readyOverwatch()
 reset();advance(2);units['RESCUE-1'].air=true;advance(4)
 assert(groups.LONGBOW.command.id=='Start')
 move('RESCUE-1',{x=41000,z=18000},true)
 move('LONGBOW-1',{x=36444,z=16000,y=400},true,35)
 move('LONGBOW-2',{x=36444,z=16100,y=400},true,35)
 advance(6);assert(GREEN_LANTERN.owReady and not groups.LONGBOW.attacks)
 isolateCAS('HUNTER-NORTH')
 move('HUNTER-NORTH-1',{x=41000,z=16000},false)
 move('HUNTER-NORTH-2',{x=44000,z=16000},false)
 move('RESCUE-1',{x=41000,z=18000},true)
end
reset();advance(600);assert(not groups.LONGBOW.command and not GREEN_LANTERN.owLaunched)
readyOverwatch();commands['Engage vehicles near me']();advance(8)
assert(groups.LONGBOW.attacks[1].params.weaponType==131072)
assert(groups.LONGBOW.attacks[1].params.unitId==units['HUNTER-NORTH-1']:getID())
assert(groups.LONGBOW.attacks[1].params.attackQty==1)
units['HUNTER-NORTH-1']:destroy();advance(10);assert(not GREEN_LANTERN.owTarget and groups.LONGBOW.option==4)
advance(30);assert(#groups.LONGBOW.attacks==1,'No automatic follow-on attacks')
originalPrint('PASS: overwatch waits at FARP, launches on takeoff, holds 3 nm south and attacks one requested target using ATGM-only mask')
readyOverwatch();commands['Engage vehicles near me']();advance(8);commands['Hold fire / resume overwatch']()
assert(not GREEN_LANTERN.owArea and not GREEN_LANTERN.owTarget and groups.LONGBOW.option==4)
assert(groups.LONGBOW.task.params.route.points[2].task.params.tasks[1].id=='Orbit')
commands['Return to HAVEN']();assert(GREEN_LANTERN.owReturning)
assert(groups.LONGBOW.task.params.route.points[2].type=='Land' and groups.LONGBOW.task.params.route.points[2].linkUnit==100)
commands['Engage vehicles near me']();assert(not GREEN_LANTERN.owArea)
originalPrint('PASS: overwatch hold-fire restores orbit; recall links to HAVEN and blocks later attacks')
readyOverwatch();land.isVisible=function()return false end;commands['Engage vehicles near me']();advance(8);assert(not groups.LONGBOW.attacks)
land.isVisible=function()return true end
move('RESCUE-2',{x=41000,z=16050},true);advance(10);assert(not groups.LONGBOW.attacks)
move('RESCUE-2',{x=19948,z=6807},false);move('HUNTER-NORTH-1',{x=42000,z=16000},false);advance(12);assert(not groups.LONGBOW.attacks)
move('HUNTER-NORTH-1',{x=41000,z=16000},false);units['LONGBOW-1'].missiles=0;units['LONGBOW-2'].missiles=0;advance(14);assert(not groups.LONGBOW.attacks and not GREEN_LANTERN.owArea)
originalPrint('PASS: overwatch rejects masked shots, friendly/survivor proximity and empty missile loads')
readyOverwatch();commands['Engage vehicles near me']();advance(8)
move('LONGBOW-1',{x=39000,z=16000,y=400},true);advance(10);assert(not GREEN_LANTERN.owTarget and groups.LONGBOW.option==4)
readyOverwatch();commands['Engage vehicles near me']();advance(8);advance(98);assert(not GREEN_LANTERN.owTarget and groups.LONGBOW.option==4)
readyOverwatch();GREEN_LANTERN.boarded=true;advance(8);assert(GREEN_LANTERN.owReturning)
originalPrint('PASS: overwatch breaks off inside 4 km or after 90 seconds and returns after boarding')
readyOverwatch();groups.LONGBOW.getController=function()error('injected native API failure')end
commands['Engage vehicles near me']();advance(8);assert(GREEN_LANTERN.owDisabled and GREEN_LANTERN.phase~='failed')
originalPrint('PASS: optional overwatch API failure does not fail the rescue')
reset();advance(2)
for _,side in pairs(mission.coalition)do for _,country in pairs(side.country or{})do for _,g in pairs((country.helicopter or{}).group or{})do
 if g.name=='RESCUE' then assert(#g.units==2 and not g.units[3]);local wp=g.route.points[4];assert(wp.x==GREEN_LANTERN.home.x and wp.y==GREEN_LANTERN.home.z)end
 if g.name=='LONGBOW' then assert(#g.units==2 and g.uncontrolled and g.units[1].parking=='3' and g.units[2].parking=='4')end
end end end
assert(not commands['Request recovery smoke (blue)'] and #blueSmokeTimes==0)
originalPrint('PASS: two two-ship flights use distinct HAVEN pads; fixed cockpit WP4 equals actual medical landing location')

originalPrint('ALL MISSION LOGIC TESTS PASSED (mock DCS world; not a flight test)')
