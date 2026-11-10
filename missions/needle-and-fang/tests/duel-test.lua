-- State/contract tests under DCS Lua 5.1; not a native AI combat simulation.
local output=print
local now,queue,units,groups,flags,messages,commands,marks,c,eventHandler
local function reset(opts)
 opts=opts or {};eventHandler=nil;now=0;queue={};units={};groups={};flags={};messages={};commands={};marks={}
 dofile('.build/config.lua');dofile('.build/mission.lua');c=NEEDLE_FANG_CONFIG
 env={mission=mission,info=function()end}
 for _,side in pairs(mission.coalition)do for _,country in pairs(side.country or {})do for _,cat in ipairs({'helicopter','vehicle'})do for _,d in pairs((country[cat]or{}).group or{})do
  local g={units={},data=d};groups[d.name]=g
  function g:getController()return {
   setOption=function(_,id,value)if opts.taskError and d.name=='FANG'then error('injected native controller failure')end;g.option=value end,
   setCommand=function(_,cmd)g.command=cmd;g.starts=(g.starts or 0)+1 end,
   setOnOff=function(_,value)g.on=value end}end
  for _,ud in pairs(d.units)do
   local u={life=100,id=ud.unitId,name=ud.name,air=false,p={x=ud.x,y=0,z=ud.y},type=ud.type};units[ud.name]=u;g.units[#g.units+1]=u
   function u:isExist()return self.life>0 end;function u:getLife()return self.life end;function u:inAir()return self.air end
   function u:getName()return self.name end;function u:getTypeName()return self.type end;function u:getPoint()return self.p end
  end
 end end end end
 Unit={getByName=function(n)return units[n]end};Group={getByName=function(n)return groups[n]end}
 coalition={getPlayers=function()return opts.renamed and {units['Other pilot']}or{}end}
 world={event={S_EVENT_DEAD=8,S_EVENT_UNIT_LOST=30},addEventHandler=function(h)eventHandler=h end}
 land={getHeight=function(p)if opts.slope and p.x==c.blueFarp.x+15 then return 100 end;return 40 end,getSurfaceType=function()return opts.water and 3 or 1 end}
 trigger={action={outTextForCoalition=function(_,text)messages[#messages+1]=text end,setUserFlag=function(k,v)flags[k]=v end,markToCoalition=function(id,text,p)marks[id]={text=text,p=p}end}}
 missionCommands={addSubMenuForCoalition=function(_,name,parent)assert(name=='Duel'and not parent);return name end,addCommandForCoalition=function(_,name,parent,fn)assert(parent=='Duel'and name=='Status / objectives'and not commands[name]);commands[name]=fn end}
 timer={getTime=function()return now end,scheduleFunction=function(fn,arg,t)queue[#queue+1]={fn=fn,arg=arg,t=t}end}
 dofile('src/duel.lua')
end
local function advance(to)
 while true do table.sort(queue,function(a,b)return a.t<b.t end);local item=queue[1];if not item or item.t>to then break end;table.remove(queue,1);now=item.t;local nt=item.fn(item.arg,now);if nt then item.t=nt;queue[#queue+1]=item end end
 now=to
end
local function kill(n,emit)units[n].life=0;if emit then eventHandler:onEvent({id=world.event.S_EVENT_DEAD,initiator=units[n]})end end
reset();advance(600);assert(NEEDLE_FANG.phase=='ready'and not groups.FANG.command and not flags[950]and not flags[951])
units['NEEDLE-1'].air=true;advance(601);assert(groups.FANG.command.id=='Start'and groups.FANG.starts==1)
advance(650);assert(groups.FANG.starts==1 and not NEEDLE_FANG.airborneReported)
units['FANG-1'].air=true;advance(651);assert(NEEDLE_FANG.airborneReported)
local count=#messages;advance(670);assert(#messages==count)
output('PASS: no pad timer; player takeoff releases Hind once; actual airborne report is distinct and not repeated')
reset();advance(1);kill('RED-OBJECTIVE-1');advance(2);assert(flags[952]and flags[950]and NEEDLE_FANG.phase=='won'and units['FANG-1'].life>0)
count=#messages;advance(30);assert(#messages==count)
output('PASS: enemy ground target alone wins immediately; no Hind kill or recovery required')
reset();advance(1);kill('FANG-1');advance(2);assert(flags[953]and not flags[950]and NEEDLE_FANG.phase=='ready')
kill('RED-OBJECTIVE-1');advance(3);assert(flags[950])
output('PASS: Hind kill alone never ends round; subsequent ground target kill wins')
reset();advance(1);kill('RED-OBJECTIVE-1',true);assert(flags[950]);kill('BLUE-OBJECTIVE-1',true);advance(2);assert(flags[950]and not flags[951])
reset();advance(1);kill('BLUE-OBJECTIVE-1',true);assert(flags[951]);kill('RED-OBJECTIVE-1',true);advance(2);assert(flags[951]and not flags[950])
output('PASS: first observed ground-target death ends the race immediately and later losses cannot reverse it')
reset();advance(1);kill('NEEDLE-1',true);kill('RED-OBJECTIVE-1',true);assert(flags[951]and not flags[950])
output('PASS: confirmed player death ends the round; a later ground kill cannot award a posthumous win')
reset();advance(1);kill('BLUE FARP AMMO SERVICE-1',true);kill('RED FARP AMMO SERVICE-1',true);advance(2);assert(not flags[950]and not flags[951])
output('PASS: unarmed FARP logistics losses are not duel objectives')
reset();advance(1);kill('BLUE-OBJECTIVE-1');kill('RED-OBJECTIVE-1');kill('FANG-1');advance(2)
assert(flags[951]and not flags[950]and NEEDLE_FANG.phase=='failed')
output('PASS: friendly defended-vehicle loss fails immediately and wins no simultaneous destruction tie')
reset();local player=units['NEEDLE-1'];units['NEEDLE-1']=nil;advance(90);assert(NEEDLE_FANG.phase=='waiting'and not flags[951])
units['NEEDLE-1']=player;advance(91);assert(NEEDLE_FANG.phase=='ready');units['NEEDLE-1']=nil;advance(101);assert(not flags[951]);advance(102);assert(flags[951]and not flags[950])
output('PASS: delayed player tolerated; acquired player loss fails after a separate grace period')
reset();local hind=units['FANG-1'];units['FANG-1']=nil;advance(100);assert(not flags[953]and not flags[950]and NEEDLE_FANG.phase=='waiting')
units['FANG-1']=hind;advance(101);assert(NEEDLE_FANG.phase=='ready'and not flags[953])
output('PASS: missing initial enemy never counts as a kill or awards false victory')
reset({renamed=true});units['Other pilot']=units['NEEDLE-1'];units['Other pilot'].name='Other pilot';units['NEEDLE-1']=nil;advance(1)
assert(NEEDLE_FANG.phase=='ready'and NEEDLE_FANG.playerName=='Other pilot')
units['Other pilot'].air=true;advance(2);assert(groups.FANG.command)
output('PASS: renamed occupied Kiowa is acquired and can start the duel')
reset({taskError=true});advance(1);assert(flags[951]and not flags[950])
reset({water=true});advance(1);assert(flags[951]and not flags[950])
reset({slope=true});advance(1);assert(flags[951]and not flags[950])
output('PASS: mandatory native AI setup error and invalid fixed terrain report failure instead of a false playable start')
reset();advance(1)
local player=groups.NEEDLE.data;local hind=groups.FANG.data
assert(player.units[1].skill=='Player'and hind.uncontrolled and hind.units[1].type=='Mi-24V')
assert(player.units[1].payload.pylons[1].CLSID=='OH58D_M3P_L500'and player.units[1].payload.pylons[5].CLSID=='OH58D_FIM_92_R')
assert(player.units[1].payload.fuel==181.4)
assert(math.abs(math.sqrt((c.redAsset.x-c.blueAsset.x)^2+(c.redAsset.y-c.blueAsset.y)^2)/1852-8)<0.0001)
assert(player.NavTargetPoints[1].x==c.redAsset.x and player.NavTargetPoints[1].y==c.redAsset.y and player.NavTargetPoints[1].text_comment=='1T|1|UNK')
for _,p in pairs(player.route.points)do assert(math.sqrt((p.x-c.redAsset.x)^2+(p.y-c.redAsset.y)^2)>500)end
local p=player.route.points[1];local u=player.units[1];assert(p.type=='TakeOffGroundHot'and p.action=='From Ground Area Hot'and p.alt==0 and p.alt_type=='RADIO'and not p.linkUnit and not p.helipadId and not u.parking and not u.parking_id and u.alt==0 and u.alt_type=='RADIO','player must start on the ground at zero AGL with no parking link')
local p=hind.route.points[1];local u=hind.units[1];assert(p.type=='TakeOffGroundHot'and p.action=='From Ground Area Hot'and p.alt==0 and p.alt_type=='RADIO'and not p.linkUnit and not p.helipadId and not u.parking and u.alt==0 and u.alt_type=='RADIO')
local pads=0;for _,side in pairs(mission.coalition)do for _,country in pairs(side.country or{})do for _,g in pairs((country.static or{}).group or{})do for _,u in pairs(g.units)do
 if u.type=='SINGLE_HELIPAD'or u.type=='FARP'then pads=pads+1;local p=u.unitId==200 and c.blueFarp or c.redFarp;assert(u.type=='SINGLE_HELIPAD'and u.shape_name=='FARP'and u.x==p.x and u.y==p.y)end
end end end end;assert(pads==2)
assert(groups['BLUE-OBJECTIVE'].data.units[1].type=='tt_DSHK'and groups['RED-OBJECTIVE'].data.units[1].type=='tt_DSHK')
assert(groups['RED-OBJECTIVE'].data.hidden and mission.forcedOptions.labels==0 and mission.forcedOptions.optionsView=='optview_onlyallies')
output('PASS: gun/Stinger loadout, BLUE and RED zero-AGL ground starts on their own helipads, 8 nm spacing and target-only prepoint match the mission contract')
local tasks=hind.route.points[1].task.params.tasks
assert(tasks[1].id=='EngageTargetsInZone'and tasks[1].params.targetTypes[1]=='Helicopters')
assert(tasks[2].id=='EngageGroup'and tasks[2].params.groupId==groups['BLUE-OBJECTIVE'].data.groupId and tasks[2].params.weaponType==9663676414)
assert(not groups.FANG.task,'Script must not inject live player positions into attack tasks')
commands['Status / objectives']();local text=messages[#messages];assert(text:find('position unknown')and not text:find('FANG%-1')and not text:find('RED%-OBJECTIVE'))
assert(marks[8202].p.x==c.redAsset.x and marks[8202].p.z==c.redAsset.y)
output('PASS: Hind has native vehicle attack and helicopter encounter tasks; status gives no aircraft coordinates or internal enemy names')
local cleared,scripts=0,0
a_remove_scene_objects=function(id,mask)assert(mask==1 and scripts==0);local found=false;for _,z in pairs(mission.triggers.zones)do if z.zoneId==id then found=true;assert(z.radius==(z.name:find('BLUE')and 200 or 160))end end;assert(found);cleared=cleared+1 end
getValueResourceByKey=function(key)return key end;a_do_script_file=function()assert(cleared==2);scripts=scripts+1 end
assert(loadstring(mission.trig.actions[1]))();assert(cleared==2 and scripts==2)
for _,entry in ipairs({{'BLUE FARP',c.blueFarp,'M 818'},{'RED FARP',c.redFarp,'Ural-375'}})do
 local g=groups[entry[1]..' AMMO SERVICE'];assert(g and not g.data.lateActivation and g.units[1].type==entry[3])
 local p=g.units[1].p;assert(math.sqrt((p.x-entry[2].x)^2+(p.z-entry[2].y)^2)<150)
 local found=false;for _,side in pairs(mission.coalition)do for _,country in pairs(side.country or{})do for _,st in pairs((country.static or{}).group or{})do if st.name==entry[1]..' AMMO CANOPY'then assert(st.units[1].type=='FARP Ammo Dump Coating');found=true end end end end;assert(found)
end
output('PASS: both FARPs have immediate nearby ammunition trucks/canopies; trees-only clearings precede scripts')

-- Verify the complete departure service chain and the actual packed warehouse.
dofile('.build/warehouses.lua')
assert(warehouses.warehouses[200].coalition=='BLUE'and warehouses.warehouses[200].unlimitedMunitions and warehouses.warehouses[200].unlimitedFuel)
local types={['AMMO SERVICE']='M 818',COMMS='Hummer',FUEL='M978 HEMTT Tanker',['GROUND POWER']='M 818',['REPAIR SERVICE']='M 818'}
for role,type in pairs(types)do
 local g=groups['BLUE FARP '..role];assert(g and not g.data.lateActivation and g.units[1].type==type)
 local p=g.units[1].p;local d=math.sqrt((p.x-c.blueFarp.x)^2+(p.z-c.blueFarp.y)^2);assert(d>40 and d<150)
end
local structures={['AMMO CANOPY']='FARP Ammo Dump Coating',['COMMAND POST']='FARP CP Blindage',['FUEL DEPOT']='FARP Fuel Depot',['REPAIR TENT']='FARP Tent'}
for _,country in pairs(mission.coalition.blue.country)do for _,g in pairs((country.static or{}).group or{})do
 for role,type in pairs(structures)do if g.name=='BLUE FARP '..role then local u=g.units[1];assert(u.type==type and math.sqrt((u.x-c.blueFarp.x)^2+(u.y-c.blueFarp.y)^2)<150);structures[role]=nil end end
end end
assert(not next(structures))
assert(groups.NEEDLE.data.units[1].Radio[2].channels[1]==c.blueFrequency)
output('PASS: BLUE departure FARP has same-side ammo, command, fuel, ground-power and repair support plus unlimited packed stocks and matching VHF preset')

reset();advance(1);commands['Status / objectives']();assert(messages[#messages]:find('LANDED')and messages[#messages]:find('local/intercom'))
units['NEEDLE-1'].air=true;commands['Status / objectives']();assert(messages[#messages]:find('AIRBORNE')and messages[#messages]:find('Ground Crew will be hidden'))
kill('RED-OBJECTIVE-1',true);units['NEEDLE-1'].air=false;commands['Status / objectives']();assert(messages[#messages]:find('LANDED')and messages[#messages]:find('round won'))
output('PASS: Ground Crew diagnostic distinguishes native landed/airborne state and remains available after the round')
local hiddenCount=0
for _,country in pairs(mission.coalition.red.country)do for _,category in ipairs({'helicopter','plane','vehicle','ship','static'})do for _,g in pairs((country[category]or{}).group or{})do assert(g.hiddenOnPlanner==true and g.hidden==true and g.hiddenOnMFD==true);hiddenCount=hiddenCount+1 end end end
assert(hiddenCount==5)
assert(groups.NEEDLE.data.NavTargetPoints[1].text_comment=='1T|1|UNK')
output('PASS: every red aircraft/objective/service/static group is hidden on planner; player 1T intelligence remains')
output('ALL NEEDLE AND FANG TESTS PASSED (simulated APIs; not native AI combat)')
