import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import AdmZip from '../../../vendor/dcs-mcp/node_modules/adm-zip/adm-zip.js';
import {newSession,saveSessionAs,refresh} from '../../../vendor/dcs-mcp/dist/miz/sessions.js';
import {addAircraftGroup,addGroundGroup,addTriggerZone,setBriefing} from '../../../vendor/dcs-mcp/dist/miz/authoring.js';
import {loadScripts} from '../../../vendor/dcs-mcp/dist/miz/frameworks.js';
import {serializeLuaAssignment} from '../../../vendor/dcs-mcp/dist/miz/serializer.js';
import {validateMission} from '../../../vendor/dcs-mcp/dist/miz/validator.js';
const base=path.resolve(import.meta.dirname,'..');
const c=JSON.parse(fs.readFileSync(path.join(base,'src/config.json')));
const t=JSON.parse(fs.readFileSync(path.join(base,'src/templates.json')));
for(const d of ['dist','.build'])fs.mkdirSync(path.join(base,d),{recursive:true});
const s=newSession('Syria',8*3600),m=s.mission;
for(const k of ['weather','groundControl','version','coalitions'])m[k]=structuredClone(t.settings[k]);
m.requiredModules=structuredClone(t.requiredModules);
m.coalitions={blue:{1:2},red:{1:0},neutrals:{1:7}};
m.date={Year:2026,Month:6,Day:15};m.forcedOptions.labels=0;m.forcedOptions.optionsView='optview_onlyallies';
m.weather.qnh=760;m.weather.season.temperature=20;
m.weather.clouds={base:3000,thickness:200,density:0,iprecptns:0};
m.weather.wind={atGround:{speed:1,dir:270},at2000:{speed:2,dir:270},at8000:{speed:4,dir:270}};
m.map={centerX:(c.blueAsset.x+c.redAsset.x)/2,centerY:c.blueAsset.y,zoom:25000};
const combo=()=>({id:'ComboTask',params:{tasks:{}}});
const wp=(p,name,alt=120,speed=45)=>({x:p.x,y:p.y,alt,alt_type:'RADIO',speed,speed_locked:true,ETA:0,ETA_locked:false,type:'Turning Point',action:'Turning Point',name,task:combo()});
function helicopter(name,type,side,pos,template,skill){
 const g=addAircraftGroup(m,'helicopter',{name,type,side,country:side==='blue'?'USA':'Russia',count:1,...pos,altitudeMetres:0,heading:side==='blue'?0:180,skill,task:'CAS'});
 const u=g.units[1],identity=structuredClone(u);Object.assign(u,structuredClone(template),identity);
 Object.assign(u,{x:pos.x,y:pos.y,alt:0,alt_type:'RADIO',speed:0,skill,psi:-u.heading,onboard_num:side==='blue'?'11':'21'});
 delete u.parking;delete u.parking_id;delete u.datalinks;
 if(side==='blue')u.callsign={1:1,2:1,3:1,name:'Anvil11'};else u.callsign=121;
 Object.assign(g,{start_time:0,uncontrolled:side==='red',frequency:251,modulation:0,communication:true,radioSet:true,tasks:{}});
 g.route.points={1:{...wp(pos,name+' HOT ON GROUND',0,0),type:'TakeOffGroundHot',action:'From Ground Area Hot',ETA_locked:true}};
 return g;
}
const player=helicopter('NEEDLE','OH58D','blue',c.blueFarp,t.oh58,'Player');
player.units[1].payload={pylons:{1:{CLSID:'OH58D_M3P_L500'},5:{CLSID:'OH58D_FIM_92_R'}},fuel:c.playerFuelKg,flare:30,chaff:0,gun:100};
player.units[1].AddPropAircraft??={};player.units[1].AddPropAircraft.PDU=true;player.units[1].Radio[1].channels[1]=251;
player.units[1].Radio[2].channels[1]=c.blueFrequency; // VHF AM preset for the departure FARP
// The enemy objective is a target fix, never a route that forces an overflight.
player.NavTargetPoints={1:{index:1,x:c.redAsset.x,y:c.redAsset.y,text_comment:'1T|1|UNK'}};
const midpoint={x:(c.blueAsset.x+c.redAsset.x)/2,y:c.blueAsset.y-1800};
player.route.points[2]=wp(midpoint,'MANEUVER REFERENCE - OPTIONAL');
player.route.points[3]=wp(c.blueFarp,'HOME FARP - OPTIONAL RECOVERY');
const hind=helicopter('FANG','Mi-24V','red',c.redFarp,t.hind,'High');
hind.units[1].payload={pylons:{2:{CLSID:'{6A4B9E69-64FE-439a-9163-3A87FB6A4D81}'},5:{CLSID:'{6A4B9E69-64FE-439a-9163-3A87FB6A4D81}'}},fuel:c.hindFuelKg,flare:192,chaff:0,gun:100};
hind.route.points[2]=wp({x:c.blueAsset.x+4500,y:c.blueAsset.y+1200},'ATTACK INGRESS',120,55);
hind.route.points[3]=wp({x:c.blueAsset.x+1800,y:c.blueAsset.y+800},'OBJECTIVE ATTACK AREA',120,50);
hind.route.points[3].task.params.tasks={1:{number:1,enabled:true,auto:false,id:'Orbit',params:{pattern:'Circle',speed:45,altitude:600}}};
hind.route.points[4]={...wp(c.redFarp,'FANG RECOVERY',0,40),type:'Land',action:'Landing',helipadId:201,linkUnit:201};
function asset(name,side,p){
 const g=addGroundGroup(m,'vehicle',{name,type:'tt_DSHK',side,country:side==='blue'?'USA':'Russia',count:1,...p,heading:side==='blue'?0:180,skill:'High'});
 g.hidden=side==='red';g.hiddenOnMFD=side==='red';g.units[1].playerCanDrive=false;
 g.route.points[1].speed=0;g.route.points[1].task.params.tasks={1:{number:1,enabled:true,auto:false,id:'WrappedAction',params:{action:{id:'Option',params:{name:0,value:2}}}},2:{number:2,enabled:true,auto:false,id:'WrappedAction',params:{action:{id:'Option',params:{name:8,value:0}}}}};
 return g;
}
const friendly=asset('BLUE-OBJECTIVE','blue',c.blueAsset),enemy=asset('RED-OBJECTIVE','red',c.redAsset);
// Both sides know the fixed defended-asset position, but aircraft are detected natively.
hind.route.points[1].task.params.tasks={
 1:{number:1,enabled:true,auto:false,id:'EngageTargetsInZone',params:{x:(c.blueAsset.x+c.redAsset.x)/2,y:c.blueAsset.y,zoneRadius:11000,targetTypes:{1:'Helicopters'},priority:0}},
 2:{number:2,enabled:true,auto:false,id:'EngageGroup',params:{groupId:friendly.groupId,visible:true,priority:1,weaponType:9663676414}}
};
const pads=[[200,'BLUE FARP','blue',c.blueFarp,c.blueFrequency],[201,'RED FARP','red',c.redFarp,c.redFrequency]];
for(const [id,name,side,p,frequency]of pads){
 const country=Object.values(m.coalition[side].country)[0];country.static??={group:{}};
 country.static.group[id]={name,groupId:id,x:p.x,y:p.y,heading:0,dead:false,route:{points:{1:{x:p.x,y:p.y,alt:0,speed:0,type:'',action:''}}},units:{1:{name,unitId:id,type:'SINGLE_HELIPAD',shape_name:'FARP',category:'Heliports',x:p.x,y:p.y,heading:0,heliport_frequency:frequency,heliport_modulation:0,heliport_callsign_id:side==='blue'?2:1,canCargo:false}}};
}
// Unarmed logistics are service assets, never additional duel objectives.
for(const [i,[,name,side,p]]of pads.entries()){
 const support=addGroundGroup(m,'vehicle',{name:name+' AMMO SERVICE',type:side==='blue'?'M 818':'Ural-375',side,country:side==='blue'?'USA':'Russia',count:1,x:p.x+70,y:p.y-50,heading:0,skill:'Average'});
 support.route.points[1].speed=0;support.hidden=side==='red';support.hiddenOnMFD=side==='red';support.units[1].playerCanDrive=false;
 assert(Math.hypot(support.units[1].x-p.x,support.units[1].y-p.y)<150);
}
// Complete the occupied BLUE FARP's service chain, not just its ammo stock.
for(const [role,type,dx,dy]of [
 ['COMMS','Hummer',-70,-50],['FUEL','M978 HEMTT Tanker',-70,50],
 ['GROUND POWER','M 818',-90,0],['REPAIR SERVICE','M 818',0,-90]
]){
 const p=c.blueFarp,g=addGroundGroup(m,'vehicle',{name:'BLUE FARP '+role,type,side:'blue',country:'USA',count:1,x:p.x+dx,y:p.y+dy,heading:0,skill:'Average'});
 g.route.points[1].speed=0;g.units[1].playerCanDrive=false;
 assert(Math.hypot(g.units[1].x-p.x,g.units[1].y-p.y)<150);
}
for(const [i,[,name,side,p]]of pads.entries()){
 const id=300+i,x=p.x+70,y=p.y+50,country=Object.values(m.coalition[side].country)[0];
 country.static.group[id]={name:name+' AMMO CANOPY',groupId:id,x,y,heading:0,dead:false,route:{points:{1:{x,y,alt:0,speed:0,type:'',action:''}}},units:{1:{name:name+' AMMO CANOPY',unitId:id,type:'FARP Ammo Dump Coating',category:'Fortifications',x,y,heading:0,canCargo:false}}};
}
for(const [i,[role,type,dx,dy]]of [
 ['COMMAND POST','FARP CP Blindage',-90,-90],['FUEL DEPOT','FARP Fuel Depot',90,-90],['REPAIR TENT','FARP Tent',-90,90]
].entries()){
 const id=310+i,x=c.blueFarp.x+dx,y=c.blueFarp.y+dy,country=Object.values(m.coalition.blue.country)[0],name='BLUE FARP '+role;
 country.static.group[id]={name,groupId:id,x,y,heading:0,dead:false,route:{points:{1:{x,y,alt:0,speed:0,type:'',action:''}}},units:{1:{name,unitId:id,type,category:'Fortifications',x,y,heading:0,canCargo:false}}};
 assert(Math.hypot(dx,dy)<150);
}
// Fictional outbuildings supply local cover; they are not additional objectives.
for(const [prefix,p]of [['BLUE',c.blueAsset],['RED',c.redAsset]]){
 const g=addGroundGroup(m,'vehicle',{name:prefix+' COVER',type:'house1arm',side:'neutrals',country:'UN Peacekeepers',countryId:7,count:1,x:p.x+45,y:p.y+35,heading:0,skill:'Average'});
 g.hidden=true;g.hiddenOnMFD=true;g.route.points[1].speed=0;
}
c.blueObjectiveId=friendly.units[1].unitId;c.redObjectiveId=enemy.units[1].unitId;
const distance=Math.hypot(c.redAsset.x-c.blueAsset.x,c.redAsset.y-c.blueAsset.y)/1852;
const brief=`OPERATION NEEDLE AND FANG - DEVELOPMENT DUEL
Syria / 08:00 local / one player OH-58D versus one AI Mi-24V

OBJECTIVE
Destroy the enemy defended DShK technical to win immediately. If your technical is destroyed first, you lose immediately. Killing the Hind is optional and does not end the round. Native target-death event order decides the race; if both targets vanish between checks without an ordered event, friendly loss takes precedence. Loss of your aircraft also fails the mission. The first result is final, without a required recovery. Flying remains possible after the round ends.

START / LOADOUT
You are Anvil 1-1, NEEDLE, hot on a visible single helipad at BLUE FARP. FANG starts hot on its own RED FARP. Both use fixed zero-AGL ground starts; no stacked parking allocations. Two Stingers and an M3P .50-cal gun with 500 rounds, 30 flares, ${c.playerFuelKg} kg fuel (about 400 lb). Use Stingers against the Hind and the gun against the unarmored enemy technical. There are no Hellfires, wingmen, jets or additional combat units. Each FARP has an unarmed ammunition service truck and ammo canopy, separate from the defended target. The technical can shoot back; avoid a prolonged stationary hover in its sight line. Check actual gross weight, hover capability and fuel reserve in the cockpit. BLUE FARP is your serviced departure/recovery base: ammunition truck/canopy, command Hummer/post, M978 fuel tanker/depot, M818 ground-power/repair trucks and repair tent are all present from mission start within 150 m, with unlimited pad warehouse resources. RED FARP retains its ammunition service. Land and park on your pad, then use Ground Crew > Rearm & Refuel to replenish Stingers and gun ammunition. VHF AM preset 1 is BLUE FARP 128.500; package UHF remains 251.000. Rearm/refuel interaction still needs native DCS confirmation after this service revision; only the defended technical decides the round, not logistics losses.

GEOGRAPHY / INTELLIGENCE
The defended vehicles are ${distance.toFixed(1)} nm apart, roughly five to six minutes at 90 kt before searching or combat. FARPs are near their own objectives; allow about 15-25 minutes for the duel, without a mission deadline. Both vehicles remain at their briefing-time positions beside authored outbuildings; terrain/forest concealment and landing fit require flight inspection. Your map shows friendly units only and labels are off. The exact RED OBJECTIVE marker and Kiowa target point 1T are fixed intelligence; the Hind's position is unknown. No live enemy tracking, scripted spotting or automatic aircraft coordinates are provided.

MMS PREPOINT
Select MMS PREPT, R2 PPT, enter 1T and press Enter. The stored record is 1T|1|UNK and identifies the defended technical, not the Hind. It is not a weapons lock. Cockpit import/alignment requires native verification. The enemy asset is not on your flight route: WP2 is an optional maneuver reference, WP3 is your home pad. No route forces you to fly over the technical.

ENEMY BEHAVIOR
The Hind's native launch is released after your first takeoff; waiting on the pad does not start its attack. It then hunts your defended vehicle and may engage your Kiowa if detected. Both sides know the fixed objective locations. Native sensing controls the air encounter: the script never feeds your live aircraft coordinates to the Hind. The Hind carries two S-8 rocket pods and its native gun, without ATGMs, High skill and ${c.hindFuelKg} kg fuel. Launch, terrain masking, attack behavior and firing effectiveness need a DCS sortie; a launch request is not proof of takeoff. Ground objectives may defend themselves from mission start.

CONTROL / REPORTS
F10 Other > Duel > Status / objectives is the only mission command. Status reports your asset's condition and confirmed enemy losses, without giving Hind location or enemy group names. One-time reports announce engagement release, observed Hind takeoff and confirmed destroyed objectives. A confirmed Hind kill is optional and never ends the round by itself. Missing enemy units at initial loading never award a victory. Objective or mandatory AI task setup failure reports failure instead of a false success. No recovery smoke.

RADIOS / FIRST FLIGHT CHECK
Package 251.000 AM; BLUE FARP ${c.blueFrequency.toFixed(3)} AM. Requires Syria and OH-58D only; AI Mi-24V is a built-in asset. No external framework or hook is needed to play. Inspect both starts/pads, ground-unit/building fit and both FARP clearings, then observe the Hind's real departure and ability to attack your technical/engage your Kiowa. Verify Stinger acquisition, gun effectiveness, terrain and fuel. This first slice has not been flown; archive/mock checks do not establish a fair or playable native dogfight. Restart the mission after updates.
`;
setBriefing(m,'Operation NEEDLE AND FANG - Kiowa versus Hind',brief);m.descriptionBlueTask=brief;
fs.writeFileSync(path.join(base,'.build/config.lua'),serializeLuaAssignment('NEEDLE_FANG_CONFIG',c));
await loadScripts(s,s.dictionary,[{filePath:path.join(base,'.build/config.lua')},{filePath:path.join(base,'src/duel.lua')}]);
// Native trees-only clearance is local to the two starting FARPs, not the hunt area.
const zones=[c.blueFarp,c.redFarp].map((p,i)=>addTriggerZone(m,{name:(i?'RED':'BLUE')+' FARP TREES ONLY',...p,radius:160}));
const loader=m.trigrules[1];loader.actions=Object.fromEntries([...zones.map(z=>({predicate:'a_remove_scene_objects',zone:z.zoneId,objects_mask:1})),...Object.values(loader.actions)].map((a,i)=>[i+1,a]));
m.trig.actions[1]=zones.map(z=>`a_remove_scene_objects(${z.zoneId},1);`).join('')+m.trig.actions[1];
refresh(s);const report=validateMission(s.document);assert.equal(report.errors.length,0,JSON.stringify(report));
assert(Math.abs(distance-8)<1e-8);assert(c.playerFuelKg<=333.69);
for(const [g,p]of [[player,c.blueFarp],[hind,c.redFarp]]){
 const u=g.units[1],w=g.route.points[1];assert.equal(u.x,p.x);assert.equal(u.y,p.y);assert.equal(u.alt,0);assert.equal(u.alt_type,'RADIO');assert.equal(w.type,'TakeOffGroundHot');assert(!u.parking&&!u.parking_id&&!w.linkUnit&&!w.helipadId);
}
assert.equal(player.units[1].skill,'Player');assert(hind.uncontrolled);
assert.equal(player.NavTargetPoints[1].x,c.redAsset.x);
for(const p of Object.values(player.route.points))assert(Math.hypot(p.x-c.redAsset.x,p.y-c.redAsset.y)>500);
const warehouse=coalition=>({coalition,size:100,speed:16.666666,periodicity:30,unlimitedMunitions:true,unlimitedAircrafts:true,unlimitedFuel:true,OperatingLevel_Air:10,OperatingLevel_Fuel:10,OperatingLevel_Eqp:10,aircrafts:{},weapons:{},suppliers:{},gasoline:{InitFuel:100},methanol_mixture:{InitFuel:100},diesel:{InitFuel:100},jet_fuel:{InitFuel:100},dynamicSpawn:false,dynamicCargo:false,allowHotStart:true});
const zip=new AdmZip(s.sourceBytes);zip.updateFile('warehouses',Buffer.from(serializeLuaAssignment('warehouses',{airports:{},warehouses:{200:warehouse('BLUE'),201:warehouse('RED')}})));s.sourceBytes=zip.toBuffer();
await saveSessionAs(s,path.join(base,'dist/Operation-Needle-and-Fang-Syria-OH58D.miz'),true);
// Exercise the actual packed stock file in regression tests, not a parallel mock.
fs.writeFileSync(path.join(base,'.build/warehouses.lua'),new AdmZip(path.join(base,'dist/Operation-Needle-and-Fang-Syria-OH58D.miz')).readAsText('warehouses'));
fs.writeFileSync(path.join(base,'.build/mission.lua'),serializeLuaAssignment('mission',m));fs.writeFileSync(path.join(base,'.build/mission.json'),JSON.stringify(m));
fs.writeFileSync(path.join(base,'dist/Operation-Needle-and-Fang-Briefing.txt'),brief);
console.log(JSON.stringify({mission:'NEEDLE AND FANG',validation:report,objectiveSeparationNm:distance,groups:s.document.groups.length}));
