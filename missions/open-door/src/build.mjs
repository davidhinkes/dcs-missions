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
    Object.assign(u,{alt:0,alt_type:'RADIO',speed:0,skill:i==='1'?skill:'High',x:pos.x+(type==='OH58D'?(Number(i)-1)*60:0),y:pos.y,psi:-u.heading,onboard_num:String(20+Number(i)),callsign:{1:1,2:type==='OH58D'?1:2,3:Number(i),name:(type==='OH58D'?'Anvil1':'Springfield2')+i}});
    delete u.parking;delete u.parking_id;
    delete u.datalinks;
  }
  Object.assign(g,{frequency:251,modulation:0,communication:true,radioSet:true,start_time:0,uncontrolled:false,tasks:{}});
  g.route.points={1:wp(pos,'FARP FOOTHOLD - HOT ON GROUND',0,0)};g.route.points[1].ETA_locked=true;
  Object.assign(g.route.points[1],{type:'TakeOffGroundHot',action:'From Ground Area Hot',alt:0,alt_type:'RADIO'});
  return g;
}
const flight=heli('LATCH','OH58D',4,c.home,'Player');
flight.route.points[2]=wp(c.hold,'IP - BLACK HAWK HOLD');
flight.route.points[3]=wp(c.plannedLZ,'PLANNED LZ - CHECK F10 ACTUAL LZ');
flight.route.points[4]=wp(c.home,'FARP FOOTHOLD - RETURN');
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
hawk.units[1].payload={pylons:{},fuel:c.blackHawkFuelKg,flare:30,chaff:0,gun:100};hawk.units[1].livery_id='standard';
hawk.route.points[2]=wp(c.hold,'SAFE HOLD - AWAIT CLEARANCE',200,50);
hawk.route.points[2].task={id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'Orbit',params:{pattern:'Circle',altitude:600,speed:40}}}}};
const usa=Object.values(m.coalition.blue.country).find(x=>x.name==='USA');
usa.static={group:{}};
const padSpecs=[...[1,2,3,4].map(i=>[99+i,{x:c.home.x+(i-1)*60,y:c.home.y},'FOOTHOLD PAD '+i,c.homeFrequency]),[200,c.transportPad,'FOOTHOLD TRANSPORT PAD',c.transportFrequency],...[1,2,3,4].map(i=>[399+i,{x:c.alternateFarp.x+(i-1)*60,y:c.alternateFarp.y},'KEYSTONE PAD '+i,c.alternateFarp.frequency])];
for(const [id,p,name,freq]of padSpecs){
  usa.static.group[id]={name,groupId:id,x:p.x,y:p.y,heading:0,dead:false,route:{points:{1:{x:p.x,y:p.y,alt:0,speed:0,type:'',action:''}}},units:{1:{name,unitId:id,type:'SINGLE_HELIPAD',shape_name:'FARP',category:'Heliports',x:p.x,y:p.y,heading:0,heliport_frequency:freq,heliport_modulation:0,heliport_callsign_id:id===200?3:2,canCargo:false}}};
}
let staticId=300;
for(const [prefix,p]of [['FOOTHOLD',c.home],['TRANSPORT',c.transportPad],['KEYSTONE',c.alternateFarp]])for(const [label,type,dx,dy]of [
  ['FUEL DEPOT','FARP Fuel Depot',90,-90],['AMMO CANOPY','FARP Ammo Dump Coating',90,110],
  ['REPAIR TENT','FARP Tent',-50,-85],['COMMAND POST','FARP CP Blindage',-50,85]]){
  const id=staticId++,x=p.x+dx,y=p.y+dy,name=prefix+' '+label;
  usa.static.group[id]={name,groupId:id,x,y,heading:0,dead:false,route:{points:{1:{x,y,alt:0,speed:0,type:'',action:''}}},units:{1:{name,unitId:id,type,category:'Fortifications',x,y,heading:0,canCargo:false}}};
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
for(const [prefix,p]of [['FOOTHOLD',c.home],['TRANSPORT',c.transportPad],['KEYSTONE',c.alternateFarp]]){
  for(const [suffix,type,count,dx,dy]of [['FUEL','M978 HEMTT Tanker',1,85,-55],['SERVICE','M 818',3,60,65],['COMMS','Hummer',1,90,-75]]){
    const support=ground(prefix+' '+suffix,type,count,{x:p.x+dx,y:p.y+dy},'blue','USA',false);
    support.hidden=false;support.hiddenOnMFD=false;
  }
}
for(const [name,p,radius]of [['HOSTAGE BUILDING',c.building,50],['KNOWN STRELA',c.sam,50],['PLANNED LZ',c.plannedLZ,500],['FOOTHOLD',c.home,500],['KEYSTONE PLANNED',c.alternateFarp,300]])addTriggerZone(m,{name,...p,radius});
const distance=Math.hypot(c.building.x-c.home.x,c.building.y-c.home.y)/1852;
const brief=`OPERATION OPEN DOOR
Syria / fictional village hostage rescue / single-player OH-58D flight of four

SITUATION
Six hostages are held in the identified village building. Satellite intelligence precisely locates the building and a Strela-10 launcher. These are fixed intelligence points, not live tracking. Other guards and reinforcements are hidden. Labels are OFF and F10 units are friendly-only. No fighter aircraft or other air support is available.

FLIGHT
Anvil 1-1: you. All four Kiowas start hot ON THE GROUND at four separate, visible native DCS helipads in FARP FOOTHOLD, 60 m apart. Native hot-ground starts use zero terrain-relative altitude; no copied barometric spawn height. Lifeline has its own fifth pad. Set your physical collective fully down before Fly. Fuel tanker/depot, ammunition trucks/canopy, ground crew, command post and repair tent are present from mission start, with unlimited warehouse resources. Use Ground Crew while parked; shut down for repairs. Lead and #2 each carry two Hellfires and a .50-cal gun with 500 rounds. #3/#4 each carry the gun plus seven M151 rockets. Fuel: ${(c.fuelKg/0.45359237).toFixed(0)} lb (${c.fuelKg} kg) each (within the checked 333.69 kg capacity; hover/gross weight and endurance need cockpit verification). Lead PDU enabled. Use normal wingman radio commands. Monitor fuel and preserve a reserve; fuel-capacity compliance is not an endurance guarantee.
Native trees-only scenery zones clear all five departure pads, the service areas and an initial 600 m lane toward the IP at mission start. Buildings and terrain are retained. Tree clearance and ground fit still need visual confirmation in DCS.
Lifeline is one built-in AI UH-60A Black Hawk on its own nearby pad. It starts following you when you lift off and holds back as you approach the village. No UH-60L mod or external scripts need installation by players.

NAVIGATION / INTELLIGENCE
WP1 FOOTHOLD. WP2 IP / transport hold. WP3 PLANNED LZ. WP4 HOME (FOOTHOLD). Enemy sites are TARGET POINTS ONLY, not flight-route waypoints.
MMS TARGET POINTS: 1T = STRELA-10 (SA13); 2T = HOSTAGE BUILDING (UNK, NO FIRE). These are separate Navigation Target Fix Points in the aircraft target database. To slew the MMS, select PREPT on its Mode Selector, use Manual/Slave as needed until the advisory reads PREPT, press R2 PPT, enter 1T or 2T on the multifunction keyboard and press Enter. Target-point loading and sensor alignment need cockpit verification; neither point is an automatic lock or authorization to fire. TIS/TV selection is independent.
Choose a terrain-masked approach. The building is a protected no-fire location. The exact hostage building and Strela are marked on F10 and stored as 1T/2T; all coordinates identify mission objects in DCS planar metres: building x=${c.building.x}, east=${c.building.y}; Strela x=${c.sam.x}, east=${c.sam.y}. F10 places them geographically and mission-start messages provide lat/lon when available.
FOOTHOLD is now the departure and final recovery FARP, 15 nm from the village, with fixed pads that are never moved under starting aircraft. KEYSTONE remains an alternate service base about 25 nm from the village and 10 nm behind FOOTHOLD. Its complete camp footprint is checked for land, slope and scenery during initialization; it can shift by up to 1 nm to find an open site. Use the actual F10 KEYSTONE marker. KEYSTONE radio: ${c.alternateFarp.frequency.toFixed(3)} AM. Both bases offer spaced visible helipads, fuel, ammunition, ground crew and repairs with unlimited pad resources. Landing at KEYSTONE does not complete the rescue: escort Lifeline back to FOOTHOLD.
Departure to objective: ${distance.toFixed(1)} nm, about ${(distance/90*60).toFixed(0)} minutes at 90 knots. Return is the same distance: approximately 30 nm round trip before combat, holding and three minutes on the ground. Allow roughly 30-45 minutes overall. The village is an authored mission compound; terrain/scenery appearance still needs flight verification.

EXECUTION
Clear the Strela and the guards around the compound/LZ, positively identifying targets before firing. Hostages can die from fire, explosions or destruction of their building. Continue rescuing survivors after casualties. Lifeline will never enter merely because defenders are killed: use F10 > Other > OPEN DOOR > Transport > Clear Black Hawk to land. Clearance is rejected while the known Strela or close defenders still threaten the site. The actual LZ is terrain/scenery-checked near WP3; the F10 LZ marker and requested green smoke identify it.
Once Lifeline is landed within 80 m of the LZ and below 1 m/s, the simulated team needs ${c.rescueSeconds} seconds to secure the survivors and board. Cover it. A local threat, movement or wave-off resets rescue progress; re-clear once safe. Ground-team movement and boarding are represented by timing/messages, not passenger animation. Neutral infantry models stand in for hostages and do not fight.
Enemy reinforcements begin moving about three minutes after your flight enters 8 km of the compound. Defeating every enemy is optional. Keep the approaches clear while Lifeline is on the ground.
After boarding Lifeline returns to its own pad at FOOTHOLD. Escort it home. It must land there for ${c.returnSeconds} seconds to count the rescued hostages: six is full success; one to five is partial success. No survivors, Black Hawk loss or player helicopter loss is failure. Flying continues after the result.

F10 / RADIOS
OPEN DOOR > Transport: clearance; hold / wave off; abort and return. OPEN DOOR > Rescue: status; mark actual LZ green.
Wave-off returns Lifeline to its hold and resets the rescue timer; it needs fresh clearance. Abort before boarding cancels the extraction and returns empty (mission failure once home). After boarding, abort/wave-off returns home with those aboard. Do not fire on the marked hostage building.
UHF package 251.000 AM. FOOTHOLD ${c.homeFrequency.toFixed(3)} AM; transport pad ${c.transportFrequency.toFixed(3)} AM. KEYSTONE alternate 128.500 AM. Ground servicing still needs DCS confirmation.

BUILD STATUS
Development build. Automated checks do not certify native UH-60A follow, temporary landing, takeoff/recovery, terrain placement or actual combat. Requires an in-simulator sortie. Requires Syria and OH-58D only.
`;
setBriefing(m,'Operation OPEN DOOR - Black Hawk Hostage Rescue',brief);m.descriptionBlueTask=brief;
const configLua='OPEN_DOOR_CONFIG = '+serializeLuaAssignment('config',c).replace(/^config\s*=\s*/,'');
fs.writeFileSync(path.join(base,'.build/config.lua'),configLua);
await loadScripts(s,s.dictionary,[{filePath:path.join(base,'.build/config.lua')},{filePath:path.join(base,'src/rescue.lua')}]);
// Native Mission Editor action: zone ID, objects_mask=1 (TREES ONLY).
// Keep occupied pads fixed; clear the camp and a 600 m initial departure lane.
// The pinned authoring library does not compile this predicate, so retain both
// editor records and their native compiled form without modifying the submodule.
const clearings=[
  addTriggerZone(m,{name:'FOOTHOLD TREE CLEARING',x:c.home.x+90,y:c.home.y,radius:260}),
  addTriggerZone(m,{name:'FOOTHOLD TRANSPORT TREE CLEARING',...c.transportPad,radius:220})
];
const heading=Math.atan2(c.hold.y-c.home.y,c.hold.x-c.home.x);
for(const d of [250,400,550])clearings.push(addTriggerZone(m,{
  name:'FOOTHOLD DEPARTURE CLEARING '+d,
  x:c.home.x+90+Math.cos(heading)*d,y:c.home.y+Math.sin(heading)*d,radius:150
}));
const loader=m.trigrules[1],scriptActions=Object.values(loader.actions);
assert.equal(loader.comment,'Load Scripts');
loader.comment='FOOTHOLD tree clearance, then load scripts';
loader.actions=Object.fromEntries([
  ...clearings.map(z=>({predicate:'a_remove_scene_objects',zone:z.zoneId,objects_mask:1})),
  ...scriptActions
].map((a,i)=>[i+1,a]));
m.trig.actions[1]=clearings.map(z=>`a_remove_scene_objects(${z.zoneId},1);`).join('')+m.trig.actions[1];
const covered=p=>clearings.some(z=>Math.hypot(p.x-z.x,p.y-z.y)<z.radius-30);
for(const [id,p]of padSpecs)if(id<400)assert(covered(p),'Starting pad requires tree clearance');
for(const g of Object.values(usa.static.group))if(g.name.startsWith('FOOTHOLD')||g.name.startsWith('TRANSPORT'))for(const u of Object.values(g.units))assert(covered(u),'Departure facility requires tree clearance');
for(let d=0;d<=600;d+=25)assert(covered({x:c.home.x+90+Math.cos(heading)*d,y:c.home.y+Math.sin(heading)*d}),'Departure lane requires continuous clearance');
for(const z of clearings)assert(Math.hypot(z.x-c.building.x,z.y-c.building.y)>20000,'Clearings must remain local to departure');
refresh(s);const report=validateMission(s.document);assert.equal(report.errors.length,0,JSON.stringify(report));
assert.equal(Object.keys(flight.units).length,4);assert(c.fuelKg<=333.69);assert(distance>14&&distance<16);
assert.equal(hawk.units[1].type,'UH-60A');assert.equal(hawk.uncontrolled,true);
assert.equal(flight.NavTargetPoints[1].x,c.sam.x);assert.equal(flight.NavTargetPoints[2].x,c.building.x);
assert.equal(Object.keys(flight.route.points).length,4);
for(const p of Object.values(flight.route.points))for(const target of [c.sam,c.building])assert(Math.hypot(p.x-target.x,p.y-target.y)>100,'Enemy site must not be a route waypoint');
assert(Math.abs(distance-15)<0.01);
const warehouse=()=>({coalition:'BLUE',size:100,speed:16.666666,periodicity:30,unlimitedMunitions:true,unlimitedAircrafts:true,unlimitedFuel:true,OperatingLevel_Air:10,OperatingLevel_Fuel:10,OperatingLevel_Eqp:10,aircrafts:{},weapons:{},suppliers:{},gasoline:{InitFuel:100},methanol_mixture:{InitFuel:100},diesel:{InitFuel:100},jet_fuel:{InitFuel:100},dynamicSpawn:false,dynamicCargo:false,allowHotStart:true});
const zip=new AdmZip(s.sourceBytes);zip.updateFile('warehouses',Buffer.from(serializeLuaAssignment('warehouses',{airports:{},warehouses:Object.fromEntries(padSpecs.map(([id])=>[id,warehouse()]))})));s.sourceBytes=zip.toBuffer();
await saveSessionAs(s,path.join(base,'dist/Operation-Open-Door-Syria-OH58D.miz'),true);
fs.writeFileSync(path.join(base,'dist/Operation-Open-Door-Briefing.txt'),brief);
fs.writeFileSync(path.join(base,'.build/mission.lua'),serializeLuaAssignment('mission',m));
fs.writeFileSync(path.join(base,'.build/mission.json'),JSON.stringify(m));
console.log(JSON.stringify({mission:'OPEN DOOR',validation:report,departureNm:distance,groups:s.document.groups.length}));
