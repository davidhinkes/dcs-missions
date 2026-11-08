-- State/contract tests under DCS-compatible Lua 5.1 with simulated APIs.
-- Not a native AI, road-following, sensor or weapons simulation.
local output=print
local now,queue,units,groups,flags,messages,commands,marks,c,eventHandler,opts
local NM=1852
local function convoyRoute()
  return {c.convoyStart,c.talbiseh,c.attackPoint,c.destination}
end
local function reset(o)
 opts=o or {};eventHandler=nil;now=0;queue={};units={};groups={};flags={};messages={};commands={};marks={}
 dofile('.build/config.lua');dofile('.build/mission.lua');c=LONG_SHADOW_CONFIG
 env={mission=mission,info=function()end}
 LONG_SHADOW_DEPARTURE_DELAY=opts.random and nil or (opts.delay or 300)
 for _,side in pairs(mission.coalition)do for _,country in pairs(side.country or {})do for _,cat in ipairs({'helicopter','plane','vehicle'})do for _,d in pairs((country[cat]or{}).group or{})do
  local g={units={},data=d,active=not d.lateActivation,speed=c.convoySpeed,leg=1};groups[d.name]=g
  function g:isExist()return true end
  function g:activate()if opts.noActivate then error('injected activation failure')end;self.active=true
   if not opts.noSpawn then for _,u in ipairs(self.units)do units[u.name]=u end end end
  function g:getController()return {setTask=function(_,task)g.task=task;g.speed=task.params.route.points[1].speed
   -- Re-route from current position: next target is the first non-start point.
   g.route={};for i=2,#task.params.route.points do local p=task.params.route.points[i];g.route[#g.route+1]={x=p.x,y=p.y}end;g.leg=1 end}end
  for _,ud in pairs(d.units)do
   local u={life=100,name=ud.name,air=false,p={x=ud.x,y=0,z=ud.y},v={x=0,y=0,z=0},type=ud.type,group=g}
   g.units[#g.units+1]=u
   if g.active then units[ud.name]=u end
   function u:isExist()return self.life>0 end;function u:getLife()return self.life end;function u:inAir()return self.air end
   function u:getName()return self.name end;function u:getTypeName()return self.type end;function u:getPoint()return self.p end
   function u:getVelocity()if opts.velocityError and self.name=='MAGPIE HVT' then error('injected drone sensor fault')end;return self.v end
  end
 end end end end
 local cg=groups['MAGPIE CONVOY'];cg.route={};for i=2,4 do local p=convoyRoute()[i];cg.route[#cg.route+1]={x=p.x,y=p.y}end
 Unit={getByName=function(n)return units[n]end};Group={getByName=function(n)return groups[n]end}
 coalition={getPlayers=function()return opts.renamed and {units['Other pilot']}or{}end}
 world={event={S_EVENT_SHOT=1,S_EVENT_HIT=2,S_EVENT_DEAD=8,S_EVENT_SHOOTING_START=23,S_EVENT_UNIT_LOST=30},addEventHandler=function(h)eventHandler=h end}
 land={getHeight=function(p)if opts.slope and p.x==c.farp.x+15 then return 100 end;return 40 end,getSurfaceType=function()return 1 end}
 if not opts.noRoads then
  land.findPathOnRoads=function(kind,x1,y1,x2,y2)assert(kind=='roads');return {{x=(x1+x2)/2,y=(y1+y2)/2},{x=x2,y=y2}}end
  land.getClosestPointOnRoads=function(_,x,y)return x+10,y end
 end
 trigger={action={outTextForCoalition=function(_,text)messages[#messages+1]=text end,setUserFlag=function(k,v)flags[k]=v end,markToCoalition=function(id,text,p)marks[id]={text=text,p=p}end}}
 missionCommands={addSubMenuForCoalition=function(_,name,parent)assert(name=='Pontiac'and not parent and not commands.menu);commands.menu=name;return name end,
  addCommandForCoalition=function(_,name,parent,fn)assert(parent=='Pontiac'and name=='Convoy report'and not commands[name]);commands[name]=fn end}
 timer={getTime=function()return now end,scheduleFunction=function(fn,arg,t)queue[#queue+1]={fn=fn,arg=arg,t=t}end}
 dofile('src/shadow.lua')
end
-- Move the whole column as one point along its route at the commanded speed.
local function move(dt)
 local g=groups['MAGPIE CONVOY'];if not g.active or g.halted then return end
 local budget=g.speed*dt
 while budget>0 and g.route[g.leg] do
  local target=g.route[g.leg];local u=g.units[1].p;local dx,dz=target.x-u.x,target.y-u.z;local d=math.sqrt(dx*dx+dz*dz)
  local step=math.min(d,budget)
  for _,unit in ipairs(g.units)do unit.p={x=u.x+(d>0 and dx/d*step or 0),y=0,z=u.z+(d>0 and dz/d*step or 0)};unit.v=d>0 and {x=dx/d*g.speed,y=0,z=dz/d*g.speed}or{x=0,y=0,z=0}end
  budget=budget-step;if step>=d then g.leg=g.leg+1 end
 end
 if not g.route[g.leg] then for _,unit in ipairs(g.units)do unit.v={x=0,y=0,z=0}end end
end
local function advance(to)
 while now<to do
  move(1);now=now+1
  table.sort(queue,function(a,b)return a.t<b.t end)
  while queue[1] and queue[1].t<=now do local item=table.remove(queue,1);local nt=item.fn(item.arg,now);if nt then item.t=nt;queue[#queue+1]=item end;table.sort(queue,function(a,b)return a.t<b.t end)end
 end
end
local function kill(n,emit)units[n].life=0;local u=units[n];units[n]=nil;if emit then eventHandler:onEvent({id=world.event.S_EVENT_DEAD,initiator=u})end end
local function count(pattern)local n=0;for _,m in ipairs(messages)do if m:find(pattern)then n=n+1 end end;return n end
local function last()return messages[#messages]end
local function hvtTo1T()local p=units['MAGPIE HVT'].p;return math.sqrt((p.x-c.attackPoint.x)^2+(p.z-c.attackPoint.y)^2)end

-- Config lists must be 1-based for ipairs (serializer writes JS arrays from 0).
dofile('.build/config.lua')
assert(#LONG_SHADOW_CONFIG.approachCallsNm==6 and LONG_SHADOW_CONFIG.approachCallsNm[1]==8 and not LONG_SHADOW_CONFIG.approachCallsNm[0])
assert(#LONG_SHADOW_CONFIG.destinationCallsNm==4 and LONG_SHADOW_CONFIG.destinationCallsNm[1]==6 and #LONG_SHADOW_CONFIG.convoyTypes==5 and LONG_SHADOW_CONFIG.convoyTypes[1]=='BRDM-2')
output('PASS: runtime lists are 1-based, so the first threshold and first vehicle are not skipped')

-- 1. Waiting, departure and the full drone call sequence, ending in escape.
reset();advance(60)
assert(LONG_SHADOW.phase=='ready'and not units['MAGPIE HVT']and not flags[960]and not flags[961])
commands['Convoy report']();assert(last():find('still in the compound'))
assert(count('On station over the M5')==1)
advance(299);assert(not LONG_SHADOW.activated)
advance(306);assert(LONG_SHADOW.activated and units['MAGPIE HVT']and count('MAGPIE is moving')==1)
assert(last():find('short of 1T')and last():find('by road')and last():find('third in column'))
output('PASS: convoy holds until the departure time, then Pontiac reports the departure once with road distance and ETA')
advance(3000)
local approach,passing,dest=0,count('passing 1T now'),0
for _,m in ipairs(messages)do if m:find('short of 1T')and not m:find('MAGPIE is moving')then approach=approach+1 end;if m:find('from Hama')and not m:find('passing')then dest=dest+1 end end
assert(approach==6,'approach calls '..approach)
for _,th in ipairs({8,6,4,3,2,1})do local found=false;for _,m in ipairs(messages)do local d=m:match('is ([%d%.]+) nm by road short of 1T');if d and not m:find('MAGPIE is moving')and tonumber(d)<=th and tonumber(d)>th-0.6 then found=true end end;assert(found,'missing '..th..' nm call')end;assert(passing==1);assert(dest==4,'destination calls '..dest)
assert(flags[961]and not flags[960]and LONG_SHADOW.phase=='failed'and last():find('reached Hama'))
output('PASS: one call per approach threshold, one passing call, one call per Hama threshold; escape to Hama fails the mission')
-- Order: approach distances strictly decrease, then passing, then Hama calls.
local prev=math.huge;local seenPass=false
for _,m in ipairs(messages)do
 local d=m:match('is ([%d%.]+) nm by road short of 1T');if d then assert(not seenPass and tonumber(d)<prev);prev=tonumber(d)end
 if m:find('passing 1T now')then seenPass=true end
end
assert(seenPass)
local n=#messages;advance(3100);assert(#messages==n)
output('PASS: calls are ordered, never repeated, and stop after the result')

-- 2. HVT destruction wins, by polling or by event; results latch.
reset();advance(400);kill('MAGPIE HVT');advance(402);assert(flags[960]and flags[962]and LONG_SHADOW.phase=='won')
n=#messages;advance(3000);assert(#messages==n and not flags[961])
output('PASS: destroying MAGPIE wins immediately (polling); the convoy reaching Hama later cannot reverse it')
reset();advance(400);kill('MAGPIE HVT',true);assert(flags[960]);kill('SHADOW-1',true);advance(420);assert(flags[960]and not flags[961])
reset();advance(400);kill('SHADOW-1',true);assert(flags[961]);kill('MAGPIE HVT',true);advance(402);assert(flags[961]and not flags[960])
output('PASS: first observed death event decides; no posthumous win after confirmed player death')

-- 3. Escorts are optional; losing one alerts the convoy instead of ending the round.
reset();advance(400);local before=groups['MAGPIE CONVOY'].speed
kill('MAGPIE CONVOY-1',true);advance(401)
local g=groups['MAGPIE CONVOY'];assert(not flags[960]and not flags[961]and LONG_SHADOW.alerted and g.task and g.speed==c.alertSpeed and before==c.convoySpeed)
local pts=g.task.params.route.points;assert(pts[#pts].x==c.destination.x and pts[#pts].y==c.destination.y and pts[#pts].action=='On Road')
assert(pts[2].x==c.attackPoint.x,'unpassed reroute keeps the 1T crossing')
assert(count('speeding up')==1)
eventHandler:onEvent({id=world.event.S_EVENT_HIT,target=units['MAGPIE CONVOY-2']});advance(405);assert(count('speeding up')==1)
output('PASS: escort loss is not a result; the alerted convoy re-routes once to Hama at alert speed via 1T, reported once')
reset();advance(400);eventHandler:onEvent({id=world.event.S_EVENT_SHOT,initiator=units['MAGPIE CONVOY-5']});assert(LONG_SHADOW.alerted)
reset();advance(400);eventHandler:onEvent({id=world.event.S_EVENT_HIT,target=units['MAGPIE HVT']});assert(LONG_SHADOW.alerted and not flags[960])
reset();advance(100);eventHandler:onEvent({id=world.event.S_EVENT_SHOT,initiator={getName=function()return 'MAGPIE CONVOY-5'end}});assert(not LONG_SHADOW.alerted)
output('PASS: convoy fire or a hit alerts it; nothing alerts it before departure')
reset();advance(306);while hvtTo1T()>200 do advance(now+5)end;advance(now+60);assert(LONG_SHADOW.passed)
kill('MAGPIE CONVOY-4',true);local pts=groups['MAGPIE CONVOY'].task.params.route.points;assert(#pts==2 and pts[2].x==c.destination.x)
output('PASS: a post-1T alert re-routes straight to Hama')

-- 4. Optional drone: loss and faults never stop the mission.
reset();advance(400);kill('PONTIAC-1',true);advance(410);assert(count('Pontiac lost')==1)
advance(500);assert(count('Pontiac lost')==1)
commands['Convoy report']();assert(last():find('Pontiac unavailable'))
kill('MAGPIE HVT');advance(520);assert(flags[960])
output('PASS: drone loss is reported once, reports stop, and the strike still wins')
reset({velocityError=true});advance(400);assert(LONG_SHADOW.droneDisabled and count('Pontiac support unavailable')==1)
advance(3000);assert(flags[961]and not flags[960])
reset({velocityError=true});advance(400);kill('MAGPIE HVT');advance(402);assert(flags[960])
output('PASS: injected drone fault disables reports only; escape and strike results still work')
reset({noRoads=true});advance(310);assert(last():find('direct short of 1T')and not last():find('by road'))
output('PASS: without road pathing, distance is labelled direct rather than claimed as road distance')

-- 5. Mandatory setup failures and player availability.
reset({noActivate=true});advance(310);assert(flags[961]and last():find('setup failed'))
reset({noSpawn=true});advance(300+c.activationTimeout+2);assert(flags[961]and not flags[960])
output('PASS: convoy activation or spawn failure reports failure, never a false win')
reset();local p=units['SHADOW-1'];units['SHADOW-1']=nil;advance(120);assert(LONG_SHADOW.phase=='waiting'and not flags[961])
units['SHADOW-1']=p;advance(121);assert(LONG_SHADOW.phase=='ready')
advance(400);units['SHADOW-1']=nil;kill('MAGPIE HVT');advance(405);assert(not flags[960]and not flags[961])
advance(412);assert(flags[961]and not flags[960])
output('PASS: delayed player tolerated; no win while an acquired player is missing; loss after the grace period fails')
reset({renamed=true});units['Other pilot']=units['SHADOW-1'];units['Other pilot'].name='Other pilot';units['SHADOW-1']=nil;advance(2)
assert(LONG_SHADOW.phase=='ready'and LONG_SHADOW.playerName=='Other pilot')
output('PASS: renamed occupied Kiowa is acquired')
reset({slope=true});advance(2);assert(LONG_SHADOW.phase=='ready'and count('uneven')==1 and not flags[961])
output('PASS: uneven pad site is warned and logged without blocking the sortie')
for _=1,20 do reset({random=true});local d=LONG_SHADOW.departureDelay;assert(d>=c.departureMinSeconds and d<=c.departureMaxSeconds)end
output('PASS: random departure stays inside the briefed window')

-- 6. Information contract: no coordinates in reports; markers and target point.
reset();advance(400);commands['Convoy report']()
local text=last();assert(text:find('short of 1T')and text:find('4 escort vehicles')and text:find('unaware'))
for _,m in ipairs(messages)do assert(not m:find('latitude')and not m:find('N34')and not m:find('MAGPIE CONVOY%-'))end
assert(marks[8301].p.x==c.attackPoint.x and marks[8301].p.z==c.attackPoint.y and marks[8302].p.x==c.convoyStart.x and marks[8303].p.x==c.destination.x)
output('PASS: reports give distance/ETA only (no coordinates or internal names); 1T, departure and destination markers match config')

-- 7. Built mission contract.
reset();local player=groups.SHADOW.data;local u=player.units[1]
local count1=0;for _ in pairs(player.route.points)do count1=count1+1 end
assert(count1==1,'player route must contain only the start point')
local p1=player.route.points[1];assert(p1.type=='TakeOffGroundHot'and p1.action=='From Ground Area Hot'and p1.alt==0 and p1.alt_type=='RADIO'and not p1.linkUnit and not u.parking)
assert(u.x==c.farp.x and u.y==c.farp.y and u.skill=='Player'and u.type=='OH58D')
assert(u.payload.pylons[1].CLSID=='OH58D_M3P_L500'and u.payload.pylons[5].CLSID=='OH58D_AGM_114_R'and u.payload.fuel==181.4 and u.AddPropAircraft.PDU)
local tp=player.NavTargetPoints;assert(tp[1].x==c.attackPoint.x and tp[1].y==c.attackPoint.y and tp[1].text_comment=='1T|1|UNK'and not tp[2])
output('PASS: player has only its hot ground start, the Hellfire/gun loadout and a single 1T target point')
local cv=groups['MAGPIE CONVOY'].data
assert(cv.lateActivation and cv.hiddenOnPlanner and cv.hidden and cv.hiddenOnMFD)
local types={'BRDM-2','tt_DSHK','UAZ-469','Ural-375','Ural-375 ZU-23'}
for i,t in ipairs(types)do assert(cv.units[i].type==t)end;assert(cv.units[3].name=='MAGPIE HVT')
local r=cv.route.points;assert(r[1].x==c.convoyStart.x and r[3].x==c.attackPoint.x and r[4].x==c.destination.x and not r[5])
for i=1,4 do assert(r[i].action=='On Road'and r[i].speed==c.convoySpeed)end
local hidden=0;for _,country in pairs(mission.coalition.red.country)do for _,cat in ipairs({'helicopter','plane','vehicle','ship','static'})do for _,g in pairs((country[cat]or{}).group or{})do assert(g.hiddenOnPlanner and g.hidden and g.hiddenOnMFD);hidden=hidden+1 end end end
assert(hidden==1)
output('PASS: convoy is a hidden, late-activated five-vehicle on-road column with MAGPIE in the third (UAZ) slot')
local dr=groups.PONTIAC.data;local du=dr.units[1];local tasks=dr.route.points[1].task.params.tasks
assert(du.type=='MQ-9 Reaper'and not next(du.payload.pylons)and du.alt==c.drone.altitude and dr.route.points[1].type=='Turning Point')
assert(tasks[1].params.action.params.name==0 and tasks[1].params.action.params.value==4 and tasks[2].id=='Orbit')
output('PASS: Pontiac is an unarmed weapon-hold MQ-9 already orbiting at altitude')
local dist=function(a,b)return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)end
assert(dist(c.farp,c.attackPoint)/NM>8 and dist(c.farp,c.attackPoint)/NM<12)
assert(mission.forcedOptions.labels==0 and mission.forcedOptions.optionsView=='optview_onlyallies')
local cleared,scripts=0,0
a_remove_scene_objects=function(id,mask)assert(mask==1 and scripts==0);for _,z in pairs(mission.triggers.zones)do if z.zoneId==id then assert(z.radius==150 and z.x==c.farp.x)end end;cleared=cleared+1 end
getValueResourceByKey=function(key)return key end;a_do_script_file=function()assert(cleared==1);scripts=scripts+1 end
assert(loadstring(mission.trig.actions[1]))();assert(cleared==1 and scripts==2)
output('PASS: geometry, map options and trees-only FARP clearing ahead of both scripts match the contract')
output('ALL LONG SHADOW TESTS PASSED (simulated APIs; not native AI, roads or sensors)')
