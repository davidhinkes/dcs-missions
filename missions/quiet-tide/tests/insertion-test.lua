-- Simulated DCS API: tests orchestration, not deck compatibility or native AI flight.
local output=print
local now,queue,units,groups,commands,messages,flags,marks,config
local function reset(opts)
 opts=opts or {};now=0;queue={};units={};groups={};commands={};messages={};flags={};marks={}
 dofile('.build/config.lua');dofile('.build/mission.lua');config=QUIET_TIDE_CONFIG
 env={mission=mission,info=function()end,error=function()end}
 for _,side in pairs(mission.coalition)do for _,country in pairs(side.country or{})do for _,cat in ipairs({'helicopter','plane','vehicle','ship'})do for _,d in pairs((country[cat]or{}).group or{})do
  local g={name=d.name,units={}};groups[d.name]=g
  function g:isExist()return true end
  function g:getController()return {
   setTask=function(_,t)g.task=t end,
   setCommand=function(_,c)if opts.supportError and d.name=='SWORD'then error('native support error')end;g.command=c end,
   setOption=function(_,k,v)g.option=v end,
   resetTask=function()g.attacks={}end,
   pushTask=function(_,t)g.attacks=g.attacks or{};g.attacks[#g.attacks+1]=t end}end
  for _,ud in pairs(d.units)do
   local u={p={x=ud.x,y=ud.alt or 0,z=ud.y},v={x=0,y=0,z=0},life=100,air=false,id=ud.unitId};units[ud.name]=u;g.units[#g.units+1]=u
   function u:isExist()return self.life>0 end;function u:getLife()return self.life end
   function u:getPoint()return self.p end;function u:getVelocity()return self.v end
   function u:inAir()return self.air end;function u:getID()return self.id end
  end
 end end end end
 Unit={getByName=function(n)return units[n]end};Group={getByName=function(n)return groups[n]end}
 Object={Category={SCENERY=5}}
 land={getHeight=function()return 40 end,getSurfaceType=function(p)if opts.dryShip then return 1 end;return p.y<0 and 3 or 1 end}
 world={VolumeType={SPHERE=0},searchObjects=function(_,volume,fn)if opts.blockLZ then fn({})end end}
 trigger={action={outTextForCoalition=function(_,t)messages[#messages+1]=t end,setUserFlag=function(k,v)flags[k]=v end,markToCoalition=function(id,text,p)marks[id]={text=text,p=p}end,removeMark=function(id)marks[id]=nil end}}
 missionCommands={addSubMenuForCoalition=function(_,name,parent)assert(not parent and(name=='Insertion'or name=='Air Support'));return name end,addCommandForCoalition=function(_,name,parent,fn)local key=parent..'/'..name;assert(not commands[key]);commands[key]=fn end}
 timer={getTime=function()return now end,scheduleFunction=function(fn,arg,t)queue[#queue+1]={fn=fn,arg=arg,t=t}end}
 dofile('src/insertion.lua')
end
local function advance(to)
 while true do table.sort(queue,function(a,b)return a.t<b.t end);local item=queue[1];if not item or item.t>to then break end;table.remove(queue,1);now=item.t;local nextTime=item.fn(item.arg,now);if nextTime then item.t=nextTime;queue[#queue+1]=item end end
 now=to
end
local function cmd(n)assert(commands[n],n)()end
local function move(n,p,air,v)units[n].p={x=p.x,y=p.y,z=p.z};units[n].air=air or false;units[n].v=v or{x=0,y=0,z=0}end
local function launch()
 move('ANVIL-1',{x=config.lz.x,y=150,z=config.lz.y-5000},true);advance(now+2)
 assert(QUIET_TIDE.phase=='holding' and groups.LIFELINE.command.id=='Start')
end
local function insert()
 launch();cmd('Insertion/Clear transport to insert');assert(QUIET_TIDE.phase=='inserting')
 move('LIFELINE-1',QUIET_TIDE.lz,false);advance(now+2);advance(now+config.insertionSeconds)
 assert(QUIET_TIDE.inserted and QUIET_TIDE.phase=='return' and flags[943])
end
reset();advance(2);assert(QUIET_TIDE.phase=='ready' and groups.SWORD.command.id=='Start')
local count=0;for _ in pairs(commands)do count=count+1 end;assert(count==7)
local ids={};local aircraft={}
for _,country in pairs(mission.coalition.blue.country)do for _,cat in ipairs({'ship','helicopter','plane'})do for _,g in pairs((country[cat]or{}).group or{})do aircraft[g.name]=g;for _,u in pairs(g.units)do assert(not ids[u.unitId]);ids[u.unitId]=true end end end end
assert(aircraft.TARAWA.units[1].type=='LHA_Tarawa' and aircraft.STENNIS.units[1].type=='Stennis')
assert(aircraft.ANVIL.units[1].skill=='Player' and aircraft.ANVIL.units[2].skill=='High')
local pads={};for _,g in ipairs({aircraft.ANVIL,aircraft.LIFELINE})do assert(g.route.points[1].linkUnit==aircraft.TARAWA.units[1].unitId and g.route.points[1].type=='TakeOffParkingHot');for _,u in pairs(g.units)do assert(not pads[u.parking]);pads[u.parking]=true end end
assert(aircraft.SWORD.route.points[1].linkUnit==aircraft.STENNIS.units[1].unitId)
local support=aircraft.SWORD.route.points[2];assert(math.sqrt((support.x-config.lz.x)^2+(support.y-config.lz.y)^2)<18000,'Support hold outside tasking range')
output('PASS: native ship types, separate deck slots, player skill, unique unit IDs, host links and seven shallow commands')
advance(600);assert(QUIET_TIDE.phase=='ready' and not groups.LIFELINE.command)
launch();advance(now+60);assert(QUIET_TIDE.phase=='holding')
cmd('Insertion/Clear transport to insert');assert(QUIET_TIDE.phase=='inserting')
move('LIFELINE-1',QUIET_TIDE.lz,false);advance(now+2);advance(now+30)
move('LIFELINE-1',QUIET_TIDE.lz,true);advance(now+2);assert(not QUIET_TIDE.insertionAt and not QUIET_TIDE.inserted)
move('LIFELINE-1',QUIET_TIDE.lz,false);advance(now+2);advance(now+60);assert(QUIET_TIDE.inserted)
local final=groups.LIFELINE.task.params.route.points[3];assert(final.linkUnit==config.tarawaId and final.type=='Land')
-- Recovery must follow the real moving ship, reject hovering and match deck velocity.
move('TARAWA-1',{x=config.ship.x+6000,y=0,z=config.ship.y},false,{x=6,y=0,z=0})
for _,name in ipairs({'ANVIL-1','LIFELINE-1'})do move(name,{x=config.ship.x,y=20,z=config.ship.y},false,{x=6,y=0,z=0})end
advance(now+30);assert(QUIET_TIDE.phase=='return')
for _,name in ipairs({'ANVIL-1','LIFELINE-1'})do move(name,{x=config.ship.x+6000,y=20,z=config.ship.y},true,{x=6,y=0,z=0})end
advance(now+30);assert(QUIET_TIDE.phase=='return')
for _,name in ipairs({'ANVIL-1','LIFELINE-1'})do units[name].air=false;units[name].v.x=0 end
advance(now+30);assert(QUIET_TIDE.phase=='return')
for _,name in ipairs({'ANVIL-1','LIFELINE-1'})do units[name].v.x=6 end
advance(now+2);advance(now+20);assert(QUIET_TIDE.phase=='complete' and flags[940])
output('PASS: no automatic clearance, continuous insertion timer/reset, linked RTB and actual moving-deck dual recovery with relative-speed check')
reset();advance(2);launch();move('SENTRY-WEST-1',QUIET_TIDE.lz,false)
cmd('Insertion/Clear transport to insert');assert(QUIET_TIDE.phase=='holding')
units['SENTRY-WEST-1'].life=0;cmd('Insertion/Clear transport to insert');assert(QUIET_TIDE.phase=='inserting')
move('SENTRY-EAST-1',QUIET_TIDE.lz,false);advance(now+2);assert(QUIET_TIDE.phase=='holding')
output('PASS: close defenders block clearance and force wave-off; fresh clearance required')
reset();advance(2);launch();cmd('Insertion/Abort / return to ship');assert(QUIET_TIDE.phase=='return' and not QUIET_TIDE.inserted)
for _,name in ipairs({'ANVIL-1','LIFELINE-1'})do move(name,units['TARAWA-1'].p,false)end
advance(now+2);advance(now+20);assert(QUIET_TIDE.phase=='aborted' and flags[942]and not flags[940])
output('PASS: empty insertion abort cannot award mission success')
reset({supportError=true});advance(2);assert(QUIET_TIDE.supportDisabled and QUIET_TIDE.phase=='ready');insert();assert(not flags[941])
reset();advance(2);launch();cmd('Air Support/Request one strike near LZ');advance(now+92);assert(not QUIET_TIDE.strikeAt)
cmd('Air Support/Request one strike near LZ');move('SWORD-1',{x=config.lz.x,y=3000,z=config.lz.y-10000},true);advance(now+2)
assert(QUIET_TIDE.strikeTarget and #groups.SWORD.attacks==1)
move('ANVIL-2',units[QUIET_TIDE.strikeTarget].p,true);advance(now+2);assert(not QUIET_TIDE.strikeTarget and groups.SWORD.option==4)
output('PASS: optional Hornet failure preserves insertion; requests expire, assign one target and cancel on friendly proximity')
reset();local lead=units['ANVIL-1'];units['ANVIL-1']=nil;advance(20);assert(QUIET_TIDE.phase=='ready');units['ANVIL-1']=lead;advance(22);lead.life=0;advance(24);assert(QUIET_TIDE.phase=='failed')
reset();advance(2);units['LIFELINE-1'].life=0;advance(4);assert(flags[941])
reset({blockLZ=true});advance(2);assert(QUIET_TIDE.phase=='failed')
reset({dryShip=true});advance(2);assert(QUIET_TIDE.phase=='failed')
output('PASS: delayed player tolerated; acquired player/transport loss, invalid LZ and dry ship placement fail explicitly')
output('ALL QUIET TIDE TESTS PASSED - simulated API, no native flight certified')
