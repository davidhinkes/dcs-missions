import {hideEnemyGroupsFromPlanner} from '../../../shared/tools/planner.mjs';
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {newSession,saveSessionAs,refresh} from '../../../vendor/dcs-mcp/dist/miz/sessions.js';
import {addAircraftGroup,addGroundGroup,addTriggerZone,setBriefing} from '../../../vendor/dcs-mcp/dist/miz/authoring.js';
import {loadScripts} from '../../../vendor/dcs-mcp/dist/miz/frameworks.js';
import {serializeLuaAssignment} from '../../../vendor/dcs-mcp/dist/miz/serializer.js';
import {validateMission} from '../../../vendor/dcs-mcp/dist/miz/validator.js';
import {toDcs,dm} from './projection.mjs';

const base=path.resolve(import.meta.dirname,'..');
const c=JSON.parse(fs.readFileSync(path.join(base,'src/config.json')));
const t=JSON.parse(fs.readFileSync(path.join(base,'src/templates.json')));
for(const d of ['dist','.build'])fs.mkdirSync(path.join(base,d),{recursive:true});
const g=c.geography;
// Every runtime/builder position derives from the one lat/lon table in config.
for(const key of ['farp','convoyStart','talbiseh','attackPoint','destination','droneOrbit'])c[key]=toDcs(g[key]);
const dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
const headingDeg=(a,b)=>(Math.atan2(b.y-a.y,b.x-a.x)*180/Math.PI+360)%360;
const nm=m=>m/1852;

const s=newSession('Syria',7*3600),m=s.mission;
for(const k of ['weather','groundControl','version','coalitions'])m[k]=structuredClone(t.settings[k]);
m.requiredModules=structuredClone(t.requiredModules);
m.coalitions={blue:{1:2},red:{1:0},neutrals:{1:7}};
m.date={Year:2026,Month:4,Day:18};m.forcedOptions.labels=0;m.forcedOptions.optionsView='optview_onlyallies';
m.weather.qnh=760;m.weather.season.temperature=17;
m.weather.clouds={base:3000,thickness:200,density:0,iprecptns:0};
m.weather.wind={atGround:{speed:2,dir:300},at2000:{speed:4,dir:290},at8000:{speed:8,dir:280}};
m.map={centerX:c.attackPoint.x,centerY:(c.farp.y+c.attackPoint.y)/2,zoom:60000};
const combo=()=>({id:'ComboTask',params:{tasks:{}}});
const option=(number,name,value)=>({number,enabled:true,auto:false,id:'WrappedAction',params:{action:{id:'Option',params:{name,value}}}});

// --- Player: one Kiowa, hot on a single visible helipad, no planned route. ---
const player=addAircraftGroup(m,'helicopter',{name:'SHADOW',type:'OH58D',side:'blue',country:'USA',count:1,...c.farp,altitudeMetres:0,heading:headingDeg(c.farp,c.attackPoint),skill:'Player',task:'CAS'});
{
  const u=player.units[1],identity=structuredClone(u);Object.assign(u,structuredClone(t.oh58),identity);
  Object.assign(u,{x:c.farp.x,y:c.farp.y,alt:0,alt_type:'RADIO',speed:0,skill:'Player',psi:-u.heading,onboard_num:'31',callsign:{1:1,2:3,3:1,name:'Anvil31'}});
  delete u.parking;delete u.parking_id;delete u.datalinks;
  u.payload={pylons:{1:{CLSID:'OH58D_M3P_L500'},5:{CLSID:'OH58D_AGM_114_R'}},fuel:c.playerFuelKg,flare:30,chaff:0,gun:100};
  u.AddPropAircraft??={};u.AddPropAircraft.PDU=true;
  u.Radio[1].channels[1]=251;u.Radio[2].channels[1]=c.farpFrequency;
}
Object.assign(player,{start_time:0,uncontrolled:false,frequency:251,modulation:0,communication:true,radioSet:true,tasks:{}});
// User choice: the start point is the ONLY route point. The pilot plans their
// own hide/approach in the Mission Planner; intelligence is one target point.
player.route.points={1:{x:c.farp.x,y:c.farp.y,alt:0,alt_type:'RADIO',speed:0,speed_locked:true,ETA:0,ETA_locked:true,
  type:'TakeOffGroundHot',action:'From Ground Area Hot',name:'FARP JUNIPER - HOT ON GROUND',formation_template:'',task:combo()}};
// OH-58D target fix point (#T|quantity|subtype), separate from route waypoints.
player.NavTargetPoints={1:{index:1,x:c.attackPoint.x,y:c.attackPoint.y,text_comment:'1T|1|UNK'}};

// --- FARP JUNIPER: one native helipad; no service promise in this slice. ---
const usa=Object.values(m.coalition.blue.country).find(x=>x.name==='USA');
usa.static??={group:{}};
usa.static.group[200]={name:'FARP JUNIPER',groupId:200,x:c.farp.x,y:c.farp.y,heading:0,dead:false,route:{points:{1:{x:c.farp.x,y:c.farp.y,alt:0,speed:0,type:'',action:''}}},
  units:{1:{name:'FARP JUNIPER',unitId:200,type:'SINGLE_HELIPAD',shape_name:'FARP',category:'Heliports',x:c.farp.x,y:c.farp.y,heading:0,heliport_frequency:c.farpFrequency,heliport_modulation:0,heliport_callsign_id:2,canCargo:false}}};

// --- PONTIAC: unarmed MQ-9 already on station; Lua turns its view into reports. ---
const drone=addAircraftGroup(m,'plane',{name:'PONTIAC',type:'MQ-9 Reaper',side:'blue',country:'USA',count:1,...c.droneOrbit,altitudeMetres:c.drone.altitude,heading:0,skill:'Excellent',task:'Reconnaissance'});
Object.assign(drone.units[1],{speed:c.drone.speed,payload:{pylons:{},fuel:c.drone.fuelKg,flare:0,chaff:0,gun:0},callsign:{1:8,2:1,3:1,name:'Pontiac11'},onboard_num:'81'});
Object.assign(drone.route.points[1],{type:'Turning Point',action:'Turning Point',alt_type:'BARO',speed:c.drone.speed,name:'PONTIAC ORBIT - ON STATION AT START'});
drone.route.points[1].task.params.tasks={1:option(1,0,4),2:{number:2,enabled:true,auto:false,id:'Orbit',params:{pattern:'Circle',speed:c.drone.speed,altitude:c.drone.altitude}}};

// --- MAGPIE convoy: one late-activated column; Lua activates it at departure. ---
const convoyTypes=['BRDM-2','tt_DSHK','UAZ-469','Ural-375','Ural-375 ZU-23'];
const hvtIndex=3;
const convoy=addGroundGroup(m,'vehicle',{name:'MAGPIE CONVOY',side:'red',country:'Russia',type:'BRDM-2',count:1,
  composition:convoyTypes.map(type=>({type,count:1})),...c.convoyStart,heading:headingDeg(c.convoyStart,c.talbiseh),skill:'Good'});
convoy.units[hvtIndex].name='MAGPIE HVT';
for(const u of Object.values(convoy.units))u.playerCanDrive=false;
convoy.lateActivation=true;
const road=(p,name,speed=c.convoySpeed)=>({x:p.x,y:p.y,alt:0,alt_type:'BARO',type:'Turning Point',action:'On Road',speed,speed_locked:true,ETA:0,ETA_locked:false,name,formation_template:'',task:combo()});
convoy.route.points={
  1:{...road(c.convoyStart,'HOMS NORTH - DEPARTURE'),ETA_locked:true},
  2:road(c.talbiseh,'M5 TALBISEH'),
  3:road(c.attackPoint,'M5 ORONTES CROSSING'),
  4:road(c.destination,'HAMA SOUTH - DESTINATION')
};
// Weapons free; do not disperse off the road when attacked (it would stall the run).
convoy.route.points[1].task.params.tasks={1:option(1,0,2),2:option(2,8,0)};

hideEnemyGroupsFromPlanner(m);

// --- Runtime config for Lua: planar points plus names shared with tests. ---
const runtime={...c,convoyTypes,hvtIndex,convoyGroup:'MAGPIE CONVOY',hvt:'MAGPIE HVT',player:'SHADOW-1',drone:{...c.drone,unit:'PONTIAC-1',group:'PONTIAC'}};
delete runtime.geography;
// The serializer writes JS arrays 0-indexed; Lua ipairs/# need 1-based lists.
const luaList=a=>Object.fromEntries(a.map((v,i)=>[i+1,v]));
for(const key of ['convoyTypes','approachCallsNm','destinationCallsNm'])runtime[key]=luaList(runtime[key]);
for(const key of ['farp','convoyStart','talbiseh','attackPoint','destination','droneOrbit'])runtime[key]={x:c[key].x,y:c[key].y};
fs.writeFileSync(path.join(base,'.build/config.lua'),serializeLuaAssignment('LONG_SHADOW_CONFIG',runtime));

// --- Briefing, generated from the same configuration. ---
const legs={farpTo1T:nm(dist(c.farp,c.attackPoint)),startTo1T:nm(dist(c.convoyStart,c.attackPoint)),oneTToHama:nm(dist(c.attackPoint,c.destination)),farpToHama:nm(dist(c.farp,c.destination))};
const kph=v=>Math.round(v*3.6),kt=v=>Math.round(v*1.94384);
const minutesAt=(metres,v)=>Math.round(metres/v/60);
const depMin=c.departureMinSeconds/60,depMax=c.departureMaxSeconds/60;
const brief=`OPERATION LONG SHADOW - DEVELOPMENT TEST SLICE
Syria / 07:00 local / single-player OH-58D

SITUATION
MAGPIE is a weapons-network coordinator who has spent the winter in a guarded compound in northern Homs. A source reports he moves to Hama this morning by road, in a small escorted convoy on the M5 highway. Ground forces cannot reach him and a strike from altitude would be seen coming. One Kiowa, flown low and patient, can. This is a fictional scenario.

MISSION
Covertly reach the M5 corridor, find and follow the convoy, and destroy MAGPIE's vehicle before it reaches Hama. Destroying the MAGPIE vehicle wins immediately. Escorts are optional. You fail if MAGPIE reaches the southern entrance of Hama (within ${c.arrivalRadius} m of the destination) or if your Kiowa is lost.

INTELLIGENCE
- Departure: the M5 at the northern exit of Homs, ${dm(g.convoyStart)}. Expected to roll between H+${depMin} and H+${depMax} minutes (mission time); the exact time is not known.
- Route: north on the M5 through Talbiseh and Ar-Rastan to Hama. About ${legs.startTo1T.toFixed(1)} nm (straight line) from departure to 1T, then ${legs.oneTToHama.toFixed(1)} nm to Hama.
- Destination: Hama southern entrance on the M5, ${dm(g.destination)}.
- Proposed attack point 1T: where the M5 is expected to cross the Orontes north of Ar-Rastan, ${dm(g.attackPoint)}. This is the convoy's most likely passage point, converted from real-world coordinates; check it against the road on your map. It is a suggestion, not a requirement - attack wherever you like.
- Convoy: five vehicles in column, about ${kph(c.convoySpeed)} km/h (${kt(c.convoySpeed)} kt), so roughly ${minutesAt(dist(c.convoyStart,c.attackPoint),c.convoySpeed)} minutes from departure to 1T. Order of march: BRDM-2 scout car (14.5 mm), DShK technical, MAGPIE in the UAZ-469 jeep (third vehicle), Ural truck, Ural with ZU-23 cannon at the rear. The ZU-23 and the heavy machine guns are dangerous inside about 2 km; stay outside that and use terrain and towns to hide.
- If the convoy is fired on, or fires at you, it will try to run for Hama at about ${kph(c.alertSpeed)} km/h. A clean first shot is best.

PLANNING
Your flight plan has no waypoints except your start at FARP JUNIPER. Plan your own route, hide and battle positions in the Mission Planner. 1T is about ${legs.farpTo1T.toFixed(1)} nm from FARP JUNIPER; Hama is about ${legs.farpToHama.toFixed(1)} nm. Enemy units are hidden from the Mission Planner and your F10 map shows friendly units only, with labels off.

MMS PREPOINT
Select MMS PREPT, R2 PPT, enter 1T and press Enter to slew to the proposed attack point. It marks a place on the road, not a vehicle and not a weapons lock.

PONTIAC (MQ-9) SUPPORT
Pontiac 1-1 is an unarmed MQ-9 already orbiting high over the M5 east of the road at ${Math.round(c.drone.altitude*3.28084/1000)},000 ft. It watches MAGPIE and calls the convoy's progress automatically: departure, then distance short of 1T at ${c.approachCallsNm.join(', ')} nm, passing 1T, and distance from Hama at ${c.destinationCallsNm.join(', ')} nm once past. Each call gives road distance (or straight-line, labelled, if road data is unavailable), speed in knots and an ETA. It also reports if the convoy is alerted. Pontiac does NOT give coordinates or lase; finding and identifying the convoy is your job. F10 Other > Pontiac > Convoy report gives an update at any time. If Pontiac is lost, the mission continues without reports.

START / LOADOUT
You are Anvil 3-1 (SHADOW), hot on the ground at FARP JUNIPER, a covert single pad on the Houla plain west of the Orontes. Two AGM-114 Hellfires on the right pylon, M3P .50-cal with 500 rounds on the left, 30 flares, PDU, ${c.playerFuelKg} kg (about 400 lb) fuel. There is no rearm or refuel service. Check gross weight, hover margin and fuel reserve in the cockpit. UHF preset 1 is 251.000; VHF AM preset 1 is the FARP frequency ${c.farpFrequency.toFixed(3)}. Recovery to JUNIPER after the shot is optional.

DEVELOPMENT STATUS
Not yet flown. Coordinates were converted offline; the convoy's road following, Pontiac's orbit, the FARP site and the vehicle types UAZ-469 and Ural-375 ZU-23 need an in-game check. See the mission flight checklist.
`;
setBriefing(m,'Operation LONG SHADOW - follow and strike',brief);m.descriptionBlueTask=brief;

await loadScripts(s,s.dictionary,[{filePath:path.join(base,'.build/config.lua')},{filePath:path.join(base,'src/shadow.lua')}]);
// Native trees-only clearing around the single occupied departure pad, before the scripts.
const zone=addTriggerZone(m,{name:'FARP JUNIPER TREES ONLY',...c.farp,radius:150});
const loader=m.trigrules[1];
loader.actions=Object.fromEntries([{predicate:'a_remove_scene_objects',zone:zone.zoneId,objects_mask:1},...Object.values(loader.actions)].map((a,i)=>[i+1,a]));
m.trig.actions[1]=`a_remove_scene_objects(${zone.zoneId},1);`+m.trig.actions[1];

refresh(s);const report=validateMission(s.document);assert.equal(report.errors.length,0,JSON.stringify(report));
// Contract assertions on the source object (tests repeat them on the packed output).
assert.equal(Object.keys(player.route.points).length,1,'Player must have no planned waypoints beyond the start');
assert.equal(player.route.points[1].type,'TakeOffGroundHot');
assert(dist(c.farp,c.attackPoint)>15000&&dist(c.farp,c.attackPoint)<22000,'FARP should be about 10 nm from 1T');
assert(dist(c.farp,c.convoyStart)>15000,'FARP must stay well clear of the convoy road');
assert(c.playerFuelKg<=333.69);
assert.equal(convoy.units[hvtIndex].type,'UAZ-469');
assert(convoy.lateActivation&&convoy.hiddenOnPlanner);

const out=path.join(base,'dist/Operation-Long-Shadow-Syria-OH58D.miz');
await saveSessionAs(s,out,true);
fs.writeFileSync(path.join(base,'.build/mission.lua'),serializeLuaAssignment('mission',m));
fs.writeFileSync(path.join(base,'dist/Operation-Long-Shadow-Briefing.txt'),brief);
console.log(JSON.stringify({mission:'LONG SHADOW',validation:report,legsNm:Object.fromEntries(Object.entries(legs).map(([k,v])=>[k,+v.toFixed(2)])),groups:s.document.groups.length}));
