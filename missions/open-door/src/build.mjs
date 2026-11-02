import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import AdmZip from '../../../vendor/dcs-mcp/node_modules/adm-zip/adm-zip.js';
import {serializeLuaAssignment} from '../../../vendor/dcs-mcp/dist/miz/serializer.js';
import {newSession,saveSessionAs,refresh} from '../../../vendor/dcs-mcp/dist/miz/sessions.js';
import {addAircraftGroup,addGroundGroup,addTriggerZone,setBriefing} from '../../../vendor/dcs-mcp/dist/miz/authoring.js';
import {loadScripts} from '../../../vendor/dcs-mcp/dist/miz/frameworks.js';
import {validateMission} from '../../../vendor/dcs-mcp/dist/miz/validator.js';
const base=path.resolve(import.meta.dirname,'..');
const c=JSON.parse(fs.readFileSync(path.join(base,'src/config.json'),'utf8'));
const t=JSON.parse(fs.readFileSync(path.join(base,'src/templates.json'),'utf8'));
const clone=x=>structuredClone(x);
for(const d of ['dist','.build'])fs.mkdirSync(path.join(base,d),{recursive:true});
const s=newSession('Syria',8*3600),m=s.mission;
for(const k of ['weather','groundControl','version','coalitions'])m[k]=clone(t.settings[k]);
m.requiredModules=clone(t.requiredModules);
m.coalitions={blue:{1:2},red:{1:0},neutrals:{1:7}};
m.date={Year:2026,Month:6,Day:15};
m.forcedOptions.labels=0;m.forcedOptions.optionsView='optview_onlyallies';
m.weather.qnh=760;m.weather.season.temperature=22;
m.weather.wind={atGround:{speed:1,dir:270},at2000:{speed:3,dir:270},at8000:{speed:6,dir:270}};
m.weather.clouds={base:3000,density:0,thickness:200,iprecptns:0};
m.map={centerX:44000,centerY:14000,zoom:105000};
const combo=()=>({id:'ComboTask',params:{tasks:{}}});
const wp=(p,name,alt=180,speed=46)=>({x:p.x,y:p.y,alt,alt_type:'RADIO',speed,speed_locked:true,ETA:0,ETA_locked:false,type:'Turning Point',action:'Turning Point',name,task:combo()});
function heli(name,type,count,pos,skill){
  const g=addAircraftGroup(m,'helicopter',{name,type,count,side:'blue',country:'USA',...pos,altitudeMetres:pos.alt??33,heading:17,skill,task:type==='OH58D'?'CAS':'Transport'});
  for(const [i,u]of Object.entries(g.units)){
    if(type==='OH58D'){const identity=clone(u);Object.assign(u,clone(t.oh58),identity);}
    Object.assign(u,{alt:pos.alt??33,alt_type:'BARO',speed:0,skill:i==='1'?skill:'High',x:pos.x,y:pos.y,parking:String(i),parking_id:String(i),onboard_num:String(20+Number(i)),callsign:{1:1,2:type==='OH58D'?1:2,3:Number(i),name:(type==='OH58D'?'Anvil1':'Springfield2')+i}});
    delete u.datalinks;
  }
  Object.assign(g,{frequency:251,modulation:0,communication:true,radioSet:true,start_time:0,uncontrolled:false,tasks:{}});
  g.route.points={1:wp(pos,'FARP KEYSTONE',pos.alt??33,0)};g.route.points[1].alt_type='BARO';g.route.points[1].ETA_locked=true;
  return g;
}
const flight=heli('LATCH','OH58D',4,c.home,'Player');
Object.assign(flight.route.points[1],{type:'TakeOffParkingHot',action:'From Parking Area Hot',helipadId:100,linkUnit:100});
flight.route.points[2]=wp(c.hold,'IP - BLACK HAWK HOLD');
flight.route.points[3]=wp(c.sam,'INTEL - STRELA-10 (DO NOT OVERFLY)');
flight.route.points[4]=wp(c.building,'INTEL - HOSTAGE BUILDING (NO FIRE)');
flight.route.points[5]=wp(c.plannedLZ,'PLANNED LZ - CHECK F10 ACTUAL LZ');
flight.route.points[6]=wp(c.home,'FARP KEYSTONE - RETURN');
// OH-58D manual section 24.4: Navigation Target Fix Points use #T|quantity|subtype.
// These load into the aircraft's target-point database, independently of route waypoints.
flight.NavTargetPoints={
  1:{index:1,x:c.sam.x,y:c.sam.y,text_comment:'1T|1|SA13'},
  2:{index:2,x:c.building.x,y:c.building.y,text_comment:'2T|1|UNK'}
};
for(const [i,u]of Object.entries(flight.units)){
  u.payload.pylons={1:{CLSID:'OH58D_M3P_L500'},5:{CLSID:Number(i)<=2?'OH58D_AGM_114_R':'{M260_M151}'}};
  u.payload.fuel=c.fuelKg;u.Radio[1].channels[1]=251;
  u.AddPropAircraft??={};u.AddPropAircraft.PDU=true;
}
const hawk=heli('LIFELINE','UH-60A',1,c.transportPad,'High');hawk.uncontrolled=true;
Object.assign(hawk.route.points[1],{type:'TakeOffParkingHot',action:'From Parking Area Hot',helipadId:200,linkUnit:200});
hawk.units[1].payload={pylons:{},fuel:c.blackHawkFuelKg,flare:30,chaff:0,gun:100};hawk.units[1].livery_id='standard';
hawk.route.points[2]=wp(c.hold,'SAFE HOLD - AWAIT CLEARANCE',200,50);
hawk.route.points[2].task={id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'Orbit',params:{pattern:'Circle',altitude:600,speed:40}}}}};
const usa=Object.values(m.coalition.blue.country).find(x=>x.name==='USA');
usa.static={group:{}};
for(const [id,p,name,freq]of [[100,c.home,'FARP KEYSTONE',128.5],[200,c.transportPad,'KEYSTONE TRANSPORT PAD',127.5]]){
  usa.static.group[id]={name,groupId:id,x:p.x,y:p.y,heading:0,dead:false,route:{points:{1:{x:p.x,y:p.y,alt:0,speed:0,type:'',action:''}}},units:{1:{name,unitId:id,type:'FARP',shape_name:'FARPS',category:'Heliports',x:p.x,y:p.y,heading:0,heliport_frequency:freq,heliport_modulation:0,heliport_callsign_id:id===100?2:3,canCargo:false}}};
}
function ground(name,type,count,p,side='red',country='Russia',late=false){
  const g=addGroundGroup(m,'vehicle',{name,type,count,...p,side,country,...(side==='neutrals'?{countryId:7}:{}),heading:180,spacingMetres:18,skill:'Average'});
  g.hidden=true;g.hiddenOnMFD=true;g.lateActivation=late;return g;
}
ground('WATCHTOWER','Strela-10M3',1,c.sam);
ground('GUARD-WEST','tt_DSHK',1,{x:c.building.x-220,y:c.building.y-130});
ground('GUARD-EAST','tt_DSHK',1,{x:c.building.x+240,y:c.building.y+180});
ground('GUARD-FOOT','Infantry AK',4,{x:c.building.x+100,y:c.building.y-80});
const qrf=ground('RELIEF','tt_DSHK',2,{x:c.building.x+2400,y:c.building.y+1600},'red','Russia',true);
const trucks=ground('RELIEF-TRUCKS','Ural-375',2,{x:c.building.x+2600,y:c.building.y+1600},'red','Russia',true);
// A deliberately authored fictional village: the protected building and nearby structures
// are mission objects, not an unverified claim about a particular scenery building.
ground('HOSTAGE-BUILDING','house1arm',1,c.building,'neutrals','UN Peacekeepers');
for(const [i,dx,dy]of [[1,160,130],[2,-160,100],[3,180,-170]])ground('VILLAGE-'+i,'house2arm',1,{x:c.building.x+dx,y:c.building.y+dy},'neutrals','UN Peacekeepers');
const people=ground('HOSTAGES','Soldier M4',6,c.building,'neutrals','UN Peacekeepers');
for(const [i,u]of Object.entries(people.units)){u.x=c.building.x+(Number(i)%3-1)*3;u.y=c.building.y+(Math.floor((Number(i)-1)/3)-0.5)*3;u.playerCanDrive=false;}
for(const [prefix,p]of [['KEYSTONE',c.home],['TRANSPORT',c.transportPad]]){
  for(const [suffix,type,count,dx,dy]of [['FUEL','M978 HEMTT Tanker',1,85,0],['SERVICE','M 818',3,60,65],['COMMS','Hummer',1,-70,45]])ground(prefix+' '+suffix,type,count,{x:p.x+dx,y:p.y+dy},'blue','USA',true);
}
for(const [name,p,radius]of [['HOSTAGE BUILDING',c.building,50],['KNOWN STRELA',c.sam,50],['PLANNED LZ',c.plannedLZ,500],['KEYSTONE',c.home,500]])addTriggerZone(m,{name,...p,radius});
const distance=Math.hypot(c.building.x-c.home.x,c.building.y-c.home.y)/1852;
const brief=`OPERATION OPEN DOOR
Syria / fictional village hostage rescue / single-player OH-58D flight of four

SITUATION
Six hostages are held in the identified village building. Satellite intelligence precisely locates the building and a Strela-10 launcher. These are fixed intelligence points, not live tracking. Other guards and reinforcements are hidden. Labels are OFF and F10 units are friendly-only. No fighter aircraft or other air support is available.

FLIGHT
Anvil 1-1: you. All four Kiowas start hot on separate FARP KEYSTONE pads. Lead and #2 each carry two Hellfires and a .50-cal gun with 500 rounds. #3/#4 each carry the gun plus seven M151 rockets. Fuel: ${c.fuelKg} kg each (within the checked 333.69 kg capacity; hover/gross weight and endurance need cockpit verification). Lead PDU enabled. Use normal wingman radio commands. Monitor fuel and preserve a reserve; fuel-capacity compliance is not an endurance guarantee.
Lifeline is one built-in AI UH-60A Black Hawk on its own nearby pad. It starts following you when you lift off and holds back as you approach the village. No UH-60L mod or external scripts need installation by players.

NAVIGATION / INTELLIGENCE
WP1 KEYSTONE. WP2 IP / transport hold. WP3 STRELA-10. WP4 HOSTAGE BUILDING. WP5 PLANNED LZ. WP6 HOME.
MMS TARGET POINTS: 1T = STRELA-10 (SA13); 2T = HOSTAGE BUILDING (UNK, NO FIRE). These are separate Navigation Target Fix Points in the aircraft target database. To slew the MMS, select PREPT on its Mode Selector, use Manual/Slave as needed until the advisory reads PREPT, press R2 PPT, enter 1T or 2T on the multifunction keyboard and press Enter. Target-point loading and sensor alignment need cockpit verification; neither point is an automatic lock or authorization to fire. TIS/TV selection is independent.
WP3 and WP4 are target reference points: do not follow the route blindly over the SAM or hostage building. Choose a terrain-masked approach. The building is a protected no-fire location. The exact hostage building and Strela are also marked on F10; all coordinates identify mission objects in DCS planar metres: building x=${c.building.x}, east=${c.building.y}; Strela x=${c.sam.x}, east=${c.sam.y}. F10 places them geographically and mission-start messages provide lat/lon when available.
Departure to objective: ${distance.toFixed(1)} nm, about ${(distance/90*60).toFixed(0)} minutes at 90 knots. Return is the same distance: approximately 50 nm round trip before combat, holding and three minutes on the ground. Allow roughly 45-60 minutes overall. The village is an authored mission compound; terrain/scenery appearance still needs flight verification.

EXECUTION
Clear the Strela and the guards around the compound/LZ, positively identifying targets before firing. Hostages can die from fire, explosions or destruction of their building. Continue rescuing survivors after casualties. Lifeline will never enter merely because defenders are killed: use F10 > Other > OPEN DOOR > Transport > Clear Black Hawk to land. Clearance is rejected while the known Strela or close defenders still threaten the site. The actual LZ is terrain/scenery-checked near WP5; the F10 LZ marker and requested green smoke identify it.
Once Lifeline is landed within 80 m of the LZ and below 1 m/s, the simulated team needs ${c.rescueSeconds} seconds to secure the survivors and board. Cover it. A local threat, movement or wave-off resets rescue progress; re-clear once safe. Ground-team movement and boarding are represented by timing/messages, not passenger animation. Neutral infantry models stand in for hostages and do not fight.
Enemy reinforcements begin moving about three minutes after your flight enters 8 km of the compound. Defeating every enemy is optional. Keep the approaches clear while Lifeline is on the ground.
After boarding Lifeline returns to its own pad at KEYSTONE. Escort it home. It must land there for ${c.returnSeconds} seconds to count the rescued hostages: six is full success; one to five is partial success. No survivors, Black Hawk loss or player helicopter loss is failure. Flying continues after the result.

F10 / RADIOS
OPEN DOOR > Transport: clearance; hold / wave off; abort and return. OPEN DOOR > Rescue: status; mark actual LZ green.
Wave-off returns Lifeline to its hold and resets the rescue timer; it needs fresh clearance. Abort before boarding cancels the extraction and returns empty (mission failure once home). After boarding, abort/wave-off returns home with those aboard. Do not fire on the marked hostage building.
UHF package 251.000 AM. KEYSTONE 128.500 AM; transport pad 127.500 AM. Both pads have service vehicles/warehouses; ground servicing still needs DCS confirmation.

BUILD STATUS
Development build. Automated checks do not certify native UH-60A follow, temporary landing, takeoff/recovery, terrain placement or actual combat. Requires an in-simulator sortie. Requires Syria and OH-58D only.
`;
setBriefing(m,'Operation OPEN DOOR - Black Hawk Hostage Rescue',brief);m.descriptionBlueTask=brief;
const configLua='OPEN_DOOR_CONFIG = '+serializeLuaAssignment('config',c).replace(/^config\s*=\s*/,'');
fs.writeFileSync(path.join(base,'.build/config.lua'),configLua);
await loadScripts(s,s.dictionary,[{filePath:path.join(base,'.build/config.lua')},{filePath:path.join(base,'src/rescue.lua')}]);
refresh(s);const report=validateMission(s.document);assert.equal(report.errors.length,0,JSON.stringify(report));
assert.equal(Object.keys(flight.units).length,4);assert(c.fuelKg<=333.69);assert(distance>24&&distance<26);
assert.equal(hawk.units[1].type,'UH-60A');assert.equal(hawk.uncontrolled,true);
assert.equal(flight.route.points[3].x,c.sam.x);assert.equal(flight.route.points[4].x,c.building.x);
const warehouse=()=>({coalition:'BLUE',size:100,speed:16.666666,periodicity:30,unlimitedMunitions:true,unlimitedAircrafts:true,unlimitedFuel:true,OperatingLevel_Air:10,OperatingLevel_Fuel:10,OperatingLevel_Eqp:10,aircrafts:{},weapons:{},suppliers:{},gasoline:{InitFuel:100},methanol_mixture:{InitFuel:100},diesel:{InitFuel:100},jet_fuel:{InitFuel:100},dynamicSpawn:false,dynamicCargo:false,allowHotStart:true});
const zip=new AdmZip(s.sourceBytes);zip.updateFile('warehouses',Buffer.from(serializeLuaAssignment('warehouses',{airports:{},warehouses:{100:warehouse(),200:warehouse()}})));s.sourceBytes=zip.toBuffer();
await saveSessionAs(s,path.join(base,'dist/Operation-Open-Door-Syria-OH58D.miz'),true);
fs.writeFileSync(path.join(base,'dist/Operation-Open-Door-Briefing.txt'),brief);
fs.writeFileSync(path.join(base,'.build/mission.lua'),serializeLuaAssignment('mission',m));
fs.writeFileSync(path.join(base,'.build/mission.json'),JSON.stringify(m));
console.log(JSON.stringify({mission:'OPEN DOOR',validation:report,departureNm:distance,groups:s.document.groups.length}));
