import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {newSession,saveSessionAs,refresh} from '../../../vendor/dcs-mcp/dist/miz/sessions.js';
import {addAircraftGroup,addGroundGroup,setBriefing} from '../../../vendor/dcs-mcp/dist/miz/authoring.js';
import {loadScripts} from '../../../vendor/dcs-mcp/dist/miz/frameworks.js';
import {serializeLuaAssignment} from '../../../vendor/dcs-mcp/dist/miz/serializer.js';
import {validateMission} from '../../../vendor/dcs-mcp/dist/miz/validator.js';
const base=path.resolve(import.meta.dirname,'..');
const c=JSON.parse(fs.readFileSync(path.join(base,'src/config.json')));
const t=JSON.parse(fs.readFileSync(path.join(base,'src/templates.json')));
const clone=structuredClone;
for(const d of ['dist','.build'])fs.mkdirSync(path.join(base,d),{recursive:true});
const s=newSession('Syria',5*3600+45*60),m=s.mission;
for(const k of ['weather','groundControl','version','coalitions'])m[k]=clone(t.settings[k]);
m.requiredModules=clone(t.requiredModules);m.coalitions={blue:{1:2},red:{1:0},neutrals:{}};
m.date={Year:2026,Month:6,Day:15};m.forcedOptions.labels=0;m.forcedOptions.optionsView='optview_onlyallies';
m.weather.qnh=760;m.weather.season.temperature=20;m.weather.clouds={base:3000,thickness:200,density:0,iprecptns:0};
m.weather.wind={atGround:{speed:2,dir:270},at2000:{speed:3,dir:270},at8000:{speed:5,dir:270}};
const combo=()=>({id:'ComboTask',params:{tasks:{}}});
const wp=(p,name,alt=200,speed=45)=>({x:p.x,y:p.y,alt,alt_type:'BARO',speed,speed_locked:true,ETA:0,ETA_locked:false,type:'Turning Point',action:'Turning Point',name,task:combo()});
function ship(name,type,p){
 const g=addGroundGroup(m,'ship',{name,type,side:'blue',country:'USA',count:1,x:p.x,y:p.y,heading:0,skill:'Excellent'});
 g.route.points={1:wp(p,name+' INITIAL',0,p.speed),2:wp({x:p.x+50000,y:p.y},'STEADY FLIGHT OPERATIONS',0,p.speed)};
 g.route.points[1].ETA_locked=true;g.units[1].frequency=(name==='TARAWA'?128.5:127.5)*1e6;g.units[1].modulation=0;
 return g;
}
const tarawa=ship('TARAWA','LHA_Tarawa',c.ship),stennis=ship('STENNIS','Stennis',c.carrier);
function aircraft(name,type,count,host,pads,template,player=false){
 const p=host.units[1];const g=addAircraftGroup(m,type==='OH58D'||type==='UH-60A'?'helicopter':'plane',{name,type,count,side:'blue',country:'USA',x:p.x,y:p.y,altitudeMetres:0,heading:0,skill:player?'Player':'High',task:type==='UH-60A'?'Transport':'CAS'});
 for(const [i,u] of Object.entries(g.units)){
  const identity=clone(u);if(template)Object.assign(u,clone(template),identity);
  Object.assign(u,{alt:0,alt_type:'BARO',speed:0,psi:0,skill:player&&i==='1'?'Player':'High',parking:String(pads[Number(i)-1]),parking_id:String(pads[Number(i)-1]),onboard_num:String(10+u.unitId),callsign:{1:name==='ANVIL'?1:name==='LIFELINE'?2:3,2:1,3:Number(i),name:(name==='ANVIL'?'Anvil':name==='LIFELINE'?'Springfield':'Uzi')+'1'+i}});delete u.datalinks;
 }
 Object.assign(g,{uncontrolled:!player,start_time:0,communication:true,frequency:251,modulation:0,radioSet:true,tasks:{}});
 g.route.points={1:{...wp(p,name+' DECK START',0,0),type:'TakeOffParkingHot',action:'From Parking Area Hot',helipadId:p.unitId,linkUnit:p.unitId,ETA_locked:true}};
 return g;
}
const kiowas=aircraft('ANVIL','OH58D',2,tarawa,[1,2],t.units.oh58,true);
for(const [i,u] of Object.entries(kiowas.units)){u.payload.pylons={1:{CLSID:'OH58D_M3P_L500'},5:{CLSID:i==='1'?'OH58D_AGM_114_R':'{M260_M151}'}};u.payload.fuel=c.fuelKg;u.AddPropAircraft??={};u.AddPropAircraft.PDU=true;u.Radio[1].channels[1]=251;}
kiowas.route.points[2]=wp(c.hold,'OFFSHORE HOLD',150,45);kiowas.route.points[3]=wp(c.lz,'PLANNED INSERTION - USE ACTUAL MARKER',150,40);
kiowas.route.points[4]={...wp(c.ship,'TARAWA RECOVERY - MOVING SHIP',0,35),type:'Land',action:'Landing',helipadId:tarawa.units[1].unitId,linkUnit:tarawa.units[1].unitId};
const hawk=aircraft('LIFELINE','UH-60A',1,tarawa,[3]);hawk.units[1].payload={pylons:{},fuel:1000,flare:30,chaff:0,gun:100};
hawk.route.points[2]=wp(c.hold,'AWAIT PLAYER CLEARANCE',250,45);
const hornets=aircraft('SWORD','FA-18C_hornet',2,stennis,[1,2],t.units.hornet);
for(const u of Object.values(hornets.units)){u.payload.pylons={1:clone(t.units.hornet.payload.pylons[1]),2:{CLSID:'LAU_117_AGM_65F'},5:{CLSID:'{FPU_8A_FUEL_TANK}'},8:{CLSID:'LAU_117_AGM_65F'},9:clone(t.units.hornet.payload.pylons[9])};u.payload.fuel=4900;}
hornets.route.points[1].task.params.tasks={1:{number:1,enabled:true,auto:false,id:'WrappedAction',params:{action:{id:'Option',params:{name:0,value:4}}}}};
const supportPoint={x:c.lz.x-5000,y:c.lz.y-15000};
assert(Math.hypot(supportPoint.x-c.lz.x,supportPoint.y-c.lz.y)<18000,'Support orbit must be inside tasking range');
hornets.route.points[2]=wp(supportPoint,'COASTAL SUPPORT HOLD',3000,180);
hornets.route.points[2].task.params.tasks={1:{number:1,enabled:true,auto:false,id:'Orbit',params:{pattern:'Circle',speed:180,altitude:3000}}};
const threats=[];
for(const [name,type,x,y,count] of [['SENTRY-WEST','tt_DSHK',c.lz.x-650,c.lz.y-450,1],['SENTRY-EAST','tt_DSHK',c.lz.x+750,c.lz.y+350,1],['PATROL','Infantry AK',c.lz.x+1300,c.lz.y+700,4]]){
 const g=addGroundGroup(m,'vehicle',{name,type,x,y,count,heading:180,side:'red',country:'Russia',skill:'Average',spacingMetres:15});g.hidden=true;g.hiddenOnMFD=true;threats.push(g);
}
c.tarawaId=tarawa.units[1].unitId;c.stennisId=stennis.units[1].unitId;
const distance=Math.hypot(c.lz.x-c.ship.x,c.lz.y-c.ship.y)/1852;
const brief=`OPERATION QUIET TIDE - FIRST PLAYABLE TEST SLICE
Syria, 15 June 2026, 05:45 local. Requires OH-58D and Syria; AI UH-60A, Tarawa and Stennis are built-in assets. No helicopter mod or Supercarrier requirement intended. Native deck compatibility is NOT YET VERIFIED.

TASK
Lead two hot-start Kiowas from TARAWA, scout a coastal approach, clear a safe insertion for six SEALs aboard LIFELINE, then escort the empty Black Hawk back to TARAWA and land yourself. The team remains ashore. Insertion is a ${c.insertionSeconds}-second landed abstraction; no infantry movement or passenger animation is promised. This first slice has one LZ and a small ground opposition; alternate LZ selection and dynamic alarm/escalation are not implemented.

DEPARTURE AND TIMING
Anvil lead and wingman occupy TARAWA slots 1/2; LIFELINE uses slot 3. Deck spacing, height and AI launch sequencing need actual DCS validation. Let the Hornets launch, take off carefully, and keep clear of LIFELINE. Lead has gun/two Hellfires; wingman gun/seven rockets; both ${c.fuelKg} kg fuel (about 400 lb). Capacity checked only; gross weight, deck hover performance and endurance require cockpit checks. Ships proceed north on steady courses. Direct initial ship-to-LZ distance ${distance.toFixed(1)} nm: roughly ${(distance/90*60).toFixed(0)} min each way at 90 kt, plus scouting/insertion/recovery. Plan 35-45 minutes, not a guaranteed endurance. Ships move; use their actual markers and linked recovery rather than initial WP4 coordinates.

CONTROL
F10 Other > Insertion: Status / next action; Clear transport to insert; Wave off / hold; Abort / return to ship. No mission-name wrapper. LIFELINE launches automatically after your takeoff, then holds offshore. It NEVER enters the LZ without explicit clearance. Stay within 8 km of the actual LZ to clear it; known hostile ground units within 500 m block clearance. Terrain clearance is a bounded runtime search within 1 km of planned WP3; actual marker is authoritative. A clear site is not proof of real rotor/forest clearance. Cover one continuous landed minute within 80 m at below 1 m/s; takeoff/motion or danger resets the insertion. After insertion, SEALs remain ashore and no further strike requests are accepted. Success requires LIFELINE and lead Kiowa landed near the actual moving TARAWA for 20 seconds with ship-relative horizontal speed below 2 m/s. Land on the deck; native inAir must report landed. Abort before insertion yields an aborted result on recovery, not success. Loss of lead/transport/TARAWA fails the mission; delayed initial unit availability is tolerated.

HORNET SUPPORT
SWORD's two Hornets launch automatically from STENNIS after mission initialization, orbit near the coast within tasking range, and hold fire until F10 Other > Air Support > Request one strike near LZ. Cancel / hold fire stops pending/assigned attacks; Return Hornets to carrier recalls them. Requests require a live flight within 20 km of the objective, select one known hostile vehicle/infantry unit within 2.5 km of actual LZ and outside 700 m of all three friendly helicopters. One request authorizes one target; pending requests time out after 90 seconds. Recheck safety during assignment, but released weapons cannot be recalled. Attack success and native AI timing require a sortie. Hornet loss or API faults do not fail insertion. No dynamic alarm system is implemented in this test slice; this is not a proven stealth simulation.

RADIOS AND INFORMATION
Package 251.000 AM; TARAWA 128.500 AM; STENNIS 127.500 AM. Labels off; friendly-only map. Planned LZ is briefing intelligence; ground enemies remain hidden. Reports are text only. No automatic sensor spotting or scripted AI copilot. Restart after installing updates.

FLIGHT CHECK ORDER
1. Spawn on deck: verify three separate helicopter slots, blade/obstacle clearance and stationary support start.
2. Observe Hornet departure; lift off and observe Black Hawk departure/offshore hold.
3. Scout actual LZ, explicitly clear insertion, verify native AI landing and timed deployment.
4. Observe empty transport departure and recovery onto moving TARAWA; land and verify result. Check fuel reserve.
5. Test wave-off/retry, abort and optional support loss. Builds and mocked tests do not certify these behaviors.
`;
setBriefing(m,'Operation QUIET TIDE - SEAL insertion',brief);m.descriptionBlueTask=brief;
fs.writeFileSync(path.join(base,'.build/config.lua'),serializeLuaAssignment('QUIET_TIDE_CONFIG',c));
await loadScripts(s,s.dictionary,[{filePath:path.join(base,'.build/config.lua')},{filePath:path.join(base,'src/insertion.lua')}]);
refresh(s);const report=validateMission(s.document);assert.equal(report.errors.length,0,JSON.stringify(report));
for(const [g,host] of [[kiowas,tarawa],[hawk,tarawa],[hornets,stennis]]){assert.equal(g.route.points[1].linkUnit,host.units[1].unitId);assert.equal(g.route.points[1].helipadId,host.units[1].unitId);assert.equal(g.route.points[1].type,'TakeOffParkingHot');}
assert.equal(new Set([...Object.values(kiowas.units),hawk.units[1]].map(u=>u.parking)).size,3);
assert.equal(kiowas.units[1].skill,'Player');assert.equal(hawk.uncontrolled,true);assert(c.fuelKg<=333.69);
await saveSessionAs(s,path.join(base,'dist/Operation-Quiet-Tide-Syria-OH58D.miz'),true);
fs.writeFileSync(path.join(base,'.build/mission.lua'),serializeLuaAssignment('mission',m));fs.writeFileSync(path.join(base,'.build/mission.json'),JSON.stringify(m));fs.writeFileSync(path.join(base,'dist/Operation-Quiet-Tide-Briefing.txt'),brief);
console.log(JSON.stringify({mission:'QUIET TIDE',validation:report,initialDistanceNm:distance,groups:s.document.groups.length}));
