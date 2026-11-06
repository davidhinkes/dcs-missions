-- State/contract tests under DCS Lua 5.1; not a native AI combat simulation.
local output=print
local now,queue,units,groups,flags,messages,commands,marks,c
local function reset(opts)
 opts=opts or {};now=0;queue={};units={};groups={};flags={};messages={};commands={};marks={}
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
local function kill(n)units[n].life=0 end
reset();advance(600);assert(NEEDLE_FANG.phase=='ready'and not groups.FANG.command and not flags[950]and not flags[951])
units['NEEDLE-1'].air=true;advance(601);assert(groups.FANG.command.id=='Start'and groups.FANG.starts==1)
advance(650);assert(groups.FANG.starts==1 and not NEEDLE_FANG.airborneReported)
units['FANG-1'].air=true;advance(651);assert(NEEDLE_FANG.airborneReported)
local count=#messages;advance(670);assert(#messages==count)
output('PASS: no pad timer; player takeoff releases Hind once; actual airborne report is distinct and not repeated')
reset();advance(1);kill('RED-OBJECTIVE-1');advance(2);assert(flags[952]and not flags[950]and NEEDLE_FANG.phase=='ready')
kill('FANG-1');advance(3);assert(flags[953]and flags[950]and NEEDLE_FANG.phase=='won')
count=#messages;advance(30);assert(#messages==count)
output('PASS: ground-first then Hind destruction wins once without requiring recovery')
reset();advance(1);kill('FANG-1');advance(2);assert(flags[953]and not flags[950])
kill('RED-OBJECTIVE-1');advance(3);assert(flags[950])
output('PASS: Hind-first then ground destruction also wins; either single kill alone is insufficient')
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
for _,g in ipairs({player,hind})do local p=g.route.points[1];local u=g.units[1];assert(p.type=='TakeOffGroundHot'and p.action=='From Ground Area Hot'and p.alt==0 and p.alt_type=='RADIO'and not p.linkUnit and not p.helipadId and not u.parking and u.alt==0 and u.alt_type=='RADIO')end
local pads=0;for _,side in pairs(mission.coalition)do for _,country in pairs(side.country or{})do for _,g in pairs((country.static or{}).group or{})do for _,u in pairs(g.units)do
 if u.type=='SINGLE_HELIPAD'then pads=pads+1;local p=u.unitId==200 and c.blueFarp or c.redFarp;assert(u.shape_name=='FARP'and u.x==p.x and u.y==p.y)end
end end end end;assert(pads==2)
assert(groups['BLUE-OBJECTIVE'].data.units[1].type=='tt_DSHK'and groups['RED-OBJECTIVE'].data.units[1].type=='tt_DSHK')
assert(groups['RED-OBJECTIVE'].data.hidden and mission.forcedOptions.labels==0 and mission.forcedOptions.optionsView=='optview_onlyallies')
output('PASS: gun/Stinger loadout, two exact visible ground-start pads, 8 nm spacing and target-only prepoint match the mission contract')
local tasks=hind.route.points[1].task.params.tasks
assert(tasks[1].id=='EngageTargetsInZone'and tasks[1].params.targetTypes[1]=='Helicopters')
assert(tasks[2].id=='EngageGroup'and tasks[2].params.groupId==groups['BLUE-OBJECTIVE'].data.groupId and tasks[2].params.weaponType==9663676414)
assert(not groups.FANG.task,'Script must not inject live player positions into attack tasks')
commands['Status / objectives']();local text=messages[#messages];assert(text:find('position unknown')and not text:find('FANG%-1')and not text:find('RED%-OBJECTIVE'))
assert(marks[8202].p.x==c.redAsset.x and marks[8202].p.z==c.redAsset.y)
output('PASS: Hind has native vehicle attack and helicopter encounter tasks; status gives no aircraft coordinates or internal enemy names')
local cleared,scripts=0,0
a_remove_scene_objects=function(id,mask)assert(mask==1 and scripts==0);local found=false;for _,z in pairs(mission.triggers.zones)do if z.zoneId==id then found=true;assert(z.radius==160)end end;assert(found);cleared=cleared+1 end
getValueResourceByKey=function(key)return key end;a_do_script_file=function()assert(cleared==2);scripts=scripts+1 end
assert(loadstring(mission.trig.actions[1]))();assert(cleared==2 and scripts==2)
output('PASS: two local trees-only FARP clearings execute before both mission scripts')
output('ALL NEEDLE AND FANG TESTS PASSED (simulated APIs; not native AI combat)')
