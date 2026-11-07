import {hideEnemyGroupsFromPlanner} from '../../../shared/tools/planner.mjs';
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
const clone=x=>structuredClone(x);
const supportTemplates=JSON.parse(fs.readFileSync(path.join(base,'src/templates/air-support.json'),'utf8'));
const templates=JSON.parse(fs.readFileSync(path.join(base,'src/templates/mission-templates.json'),'utf8'));
fs.mkdirSync(path.join(base,'dist'),{recursive:true});
fs.mkdirSync(path.join(base,'.build'),{recursive:true});
const s=newSession('Syria',8*3600); const m=s.mission;
for(const key of ['weather','groundControl','version','coalitions'])m[key]=clone(templates.settings[key]);
m.requiredModules=clone(templates.requiredModules);
m.forcedOptions.labels=0;
m.forcedOptions.optionsView='optview_onlyallies';
m.coalitions={blue:{1:2},red:{1:0},neutrals:{}};
m.date={Year:2026,Month:6,Day:14}; m.weather.qnh=760;m.weather.season.temperature=22;
m.weather.wind={atGround:{speed:1,dir:270},at2000:{speed:3,dir:270},at8000:{speed:6,dir:270}};
m.weather.clouds={base:3000,density:0,thickness:200,iprecptns:0};
m.map={centerX:20000,centerY:10000,zoom:90000};
const extraction={x:42000,y:16000}, recovery={x:-1802.8537883092722,y:1000};
const haven={x:19948.236328125,y:6806.8149414062};
const havenPads=[[-30,-30],[30,-30],[-30,30],[30,30]].map(([dx,dy],i)=>({id:100+i,name:'HAVEN PAD '+(i+1),x:haven.x+dx,y:haven.y+dy}));
const empty=()=>({id:'ComboTask',params:{tasks:{}}});
function wp(x,y,alt,speed,name,task=empty()){return {x,y,alt,alt_type:'BARO',speed,speed_locked:true,ETA:0,ETA_locked:false,type:'Turning Point',action:'Turning Point',name,task};}
function aircraft(name,type,side,count,start,alt,speed,heading,template,skill){
 const g=addAircraftGroup(m,['OH58D','Mi-24V'].includes(type)?'helicopter':'plane',{side,country:side==='blue'?'USA':'Russia',name,type,count,x:start.x,y:start.y,altitudeMetres:alt,heading,skill,task:type==='OH58D'?'CAS':'CAP'});
 for(const u of Object.values(g.units)){const id=u.unitId,n=u.name,x=u.x,y=u.y,h=u.heading;Object.assign(u,clone(template),{unitId:id,name:n,x,y,heading:h,psi:-h,skill,alt,alt_type:'BARO',speed,onboard_num:String(10+id)});delete u.datalinks;delete u.parking;delete u.parking_id;u.callsign=side==='blue'?{1:type==='OH58D'?1:3,2:1,3:id===g.units[1].unitId?1:2,name:(type==='OH58D'?'Anvil':'Uzi')+'1'+(id===g.units[1].unitId?1:2)}:100+id;}
 Object.assign(g,{start_time:0,communication:true,frequency:251,modulation:0,radioSet:true,uncontrolled:false,tasks:{}});
 g.route.points={1:wp(start.x,start.y,alt,speed,'START')};g.route.points[1].ETA_locked=true;
 return g;
}
const oh=clone(templates.units.oh58);
oh.payload.pylons={1:{CLSID:'OH58D_M3P_L500'},5:{CLSID:'OH58D_AGM_114_R'}};
oh.payload.fuel=270;
oh.Radio[1].channels[1]=251;
const player=aircraft('RESCUE','OH58D','blue',2,{x:19948.236328125,y:6806.8149414062},33.384346008301,0,19,oh,'Player');
player.route.points[2]=wp(36000,13000,500,45,'IP - COVER CHECK');
player.route.points[3]=wp(extraction.x,extraction.y,300,35,'SPARROW SEARCH AREA - APPROXIMATE');
player.route.points[4]=wp(recovery.x,recovery.y,300,45,'FARP LANTERN - MEDICAL HANDOVER');
Object.assign(player.route.points[1],{type:'TakeOffParkingHot',action:'From Parking Area Hot',helipadId:100,linkUnit:100,name:'FARP HAVEN - HOT START'});
player.units[1].AddPropAircraft.PDU=true;
player.units[2].skill='High';
player.units[2].payload.pylons={1:{CLSID:'OH58D_M3P_L500'},5:{CLSID:'{M260_M151}'}};

player.units[2].AddPropAircraft.tacNet=1;
player.uncontrollable=false; player.hidden=false; player.dynSpawnTemplate=false;
const overwatchPoint={x:extraction.x-3*1852,y:extraction.y};
const overwatch=aircraft('LONGBOW','OH58D','blue',2,{x:player.x,y:player.y},33.384346008301,0,19,oh,'Excellent');
overwatch.uncontrolled=true;overwatch.task='CAS';
overwatch.route.points={1:clone(player.route.points[1]),2:wp(overwatchPoint.x,overwatchPoint.y,200,45,'LONGBOW OVERWATCH - 3 NM SOUTH'),3:clone(player.route.points[4])};
overwatch.route.points[2].alt_type='RADIO';
Object.assign(overwatch.route.points[3],{x:player.x,y:player.y,alt:0,type:'Land',action:'Landing',helipadId:100,linkUnit:100,name:'HAVEN RECOVERY'});
for(const [i,u]of Object.entries(overwatch.units)){

  u.callsign={1:1,2:2,3:Number(i),name:'Anvil2'+i};
}
overwatch.route.points[1].task={id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'WrappedAction',params:{action:{id:'Option',params:{name:0,value:4}}}}}}};
const blueCountry=Object.values(m.coalition.blue.country).find(c=>c.name==='USA');
blueCountry.static={group:{}};
for(const p of havenPads){
  blueCountry.static.group[p.id]={name:p.name,groupId:p.id,x:p.x,y:p.y,heading:0,dead:false,hidden:false,route:{points:{1:{x:p.x,y:p.y,alt:0,speed:0,type:'',action:''}}},units:{1:{name:p.name,unitId:p.id,type:'SINGLE_HELIPAD',shape_name:'FARP',category:'Heliports',x:p.x,y:p.y,heading:0,heliport_frequency:128.5,heliport_modulation:0,heliport_callsign_id:2,canCargo:false}}};
}
for(const [g,offset]of [[player,0],[overwatch,2]]){
  const start=havenPads[offset];g.x=start.x;g.y=start.y;
  Object.assign(g.route.points[1],{x:start.x,y:start.y,alt:0,alt_type:'RADIO',speed:0,type:'TakeOffGroundHot',action:'From Ground Area Hot',name:start.name+' - HOT ON GROUND'});
  delete g.route.points[1].helipadId;delete g.route.points[1].linkUnit;
  for(const [i,u]of Object.entries(g.units)){
    const p=havenPads[offset+Number(i)-1];Object.assign(u,{x:p.x,y:p.y,alt:0,alt_type:'RADIO',speed:0});delete u.parking;delete u.parking_id;
  }
}
Object.assign(overwatch.route.points[3],{x:havenPads[2].x,y:havenPads[2].y,linkUnit:102,helipadId:102});

const carrierDistanceNm=70; // 20 nm closer on the original offshore bearing.
const carrierScale=carrierDistanceNm/100;
const carrierPos={x:extraction.x+(167472.43724066-extraction.x)*carrierScale,y:extraction.y-Math.sqrt((100*1852)**2-(167472.43724066-extraction.x)**2)*carrierScale};
const carrier=addGroundGroup(m,'ship',{name:'STENNIS',type:'Stennis',side:'blue',country:'USA',count:1,...carrierPos,heading:270,skill:'Excellent'});
const carrierId=carrier.units[1].unitId;
carrier.units[1].frequency=127500000;carrier.units[1].modulation=0;
carrier.route.points={1:wp(carrierPos.x,carrierPos.y,0,12.86,'CARRIER STATION'),2:wp(carrierPos.x,carrierPos.y-40000,0,12.86,'FLIGHT OPERATIONS')};carrier.route.points[1].ETA_locked=true;
carrier.route.points[1].task={id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'WrappedAction',params:{action:{id:'ActivateBeacon',params:{type:4,AA:false,unitId:carrierId,modeChannel:'X',channel:74,system:3,callsign:'JCS',bearing:true,frequency:1161000000}}}},2:{number:2,enabled:true,auto:false,id:'WrappedAction',params:{action:{id:'ActivateICLS',params:{channel:11,type:131584,unitId:carrierId}}}}}}};
const cap=aircraft('GUARDIAN','FA-18C_hornet','blue',2,carrierPos,0,0,270,clone(templates.units.hornet),'High');
cap.lateActivation=true;
Object.assign(cap.route.points[1],{type:'TakeOffParkingHot',action:'From Parking Area Hot',helipadId:carrierId,linkUnit:carrierId});
for(const [i,u] of Object.entries(cap.units)){u.x=carrierPos.x;u.y=carrierPos.y;u.alt=0;u.parking=String(i);u.parking_id=String(i);u.payload.pylons[3]={CLSID:'{FPU_8A_FUEL_TANK}'};u.payload.pylons[7]={CLSID:'{FPU_8A_FUEL_TANK}'};}
const engage={number:1,enabled:true,auto:false,id:'EngageTargetsInZone',params:{x:42000,y:16000,zoneRadius:25000,targetTypes:{1:'Air'},priority:0}};
cap.route.points[1].task={id:'ComboTask',params:{tasks:{1:clone(engage)}}};
cap.route.points[1].task.params.tasks[1].params.targetTypes={1:'Planes',2:'Helicopters'};
cap.route.points[2]=wp(carrierPos.x-15000,carrierPos.y+15000,5500,230,'CLIMB / PUSH');
cap.route.points[3]=wp(42000,16000,5500,230,'RESCUE CAP',{id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'ControlledTask',params:{task:{id:'Orbit',params:{pattern:'Circle',speed:180,altitude:5500}},stopCondition:{duration:1200}}}}}});
cap.route.points[4]=wp(carrierPos.x,carrierPos.y,0,100,'STENNIS RECOVERY');Object.assign(cap.route.points[4],{type:'Land',action:'Landing',helipadId:carrierId,linkUnit:carrierId});
const cas=aircraft('BRUISER','FA-18C_hornet','blue',2,carrierPos,0,0,270,clone(templates.units.hornet),'High');
cas.task='CAS';cas.lateActivation=true;cas.route=clone(cap.route);
cas.route.points[1].task={id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'WrappedAction',params:{action:{id:'Option',params:{name:0,value:4}}}}}}};
cas.route.points[2]=wp(carrierPos.x-15000,carrierPos.y+15000,2500,230,'CAS TRANSIT');
cas.route.points[3]=wp(33000,8000,2500,200,'CAS HOLD - AWAIT ANVIL CLEARANCE',{id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'ControlledTask',params:{task:{id:'Orbit',params:{pattern:'Circle',speed:180,altitude:2500}},stopCondition:{duration:1500}}}}}});
for(const [i,u] of Object.entries(cas.units)){u.parking=String(Number(i)+2);u.parking_id=u.parking;u.callsign={1:4,2:2,3:Number(i),name:'Colt2'+i};u.payload={fuel:4900,flare:60,chaff:60,gun:100,pylons:{1:clone(cap.units[1].payload.pylons[1]),2:{CLSID:'LAU_117_AGM_65F'},3:{CLSID:'LAU_117_AGM_65F'},5:{CLSID:'{FPU_8A_FUEL_TANK}'},7:{CLSID:'LAU_117_AGM_65F'},8:{CLSID:'LAU_117_AGM_65F'},9:clone(cap.units[1].payload.pylons[9])}};}
const sead=aircraft('WEASEL','FA-18C_hornet','blue',2,carrierPos,0,0,270,clone(templates.units.hornet),'High');
sead.task='SEAD';sead.lateActivation=true;sead.route=clone(cap.route);
sead.route.points[2]=wp(80000,-35000,5000,250,'COASTAL SEAD PUSH');
sead.route.points[3]=wp(65000,-26000,5000,220,'SEAD STANDOFF',{id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'ControlledTask',params:{task:{id:'Orbit',params:{pattern:'Circle',speed:180,altitude:5000}},stopCondition:{duration:900}}}}}});
for(const [i,u] of Object.entries(sead.units)){u.parking=String(Number(i)+4);u.parking_id=u.parking;u.callsign={1:6,2:3,3:Number(i),name:'Ford3'+i};u.payload=clone(cap.units[i].payload);u.payload.pylons[2]={CLSID:'{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}'};u.payload.pylons[8]={CLSID:'{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}'};}
const hawkeye=aircraft('OVERLORD','E-2C','blue',1,carrierPos,0,0,270,supportTemplates.e2,'High');
hawkeye.task='AWACS';hawkeye.route=clone(cap.route);Object.assign(hawkeye.route.points[1],{type:'TakeOff',action:'From Runway'});
hawkeye.route.points[1].task={id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:true,id:'AWACS',params:{}}}}};
hawkeye.units[1].payload={pylons:{},fuel:5624,flare:60,chaff:120,gun:100};delete hawkeye.units[1].parking;delete hawkeye.units[1].parking_id;hawkeye.units[1].callsign={1:1,2:1,3:1,name:'Overlord11'};
// Deck parking/link fields determine actual spots; remove generic formation offsets.
for(const g of [cap,cas,sead,hawkeye])for(const u of Object.values(g.units)){u.x=carrierPos.x;u.y=carrierPos.y;}
hawkeye.route.points[2]=wp(90000,-50000,7500,130,'OFFSHORE RADAR STATION');
hawkeye.route.points[3]=wp(120000,-50000,7500,130,'AWACS HOLD',{id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'ControlledTask',params:{task:{id:'Orbit',params:{pattern:'Race-Track',point:{x:90000,y:-50000},point2:{x:120000,y:-50000},speed:130,altitude:7500}},stopCondition:{duration:7200}}}}}});
const hinds=aircraft('HIND-PATROL','Mi-24V','red',2,{x:51000,y:26000},1800,55,240,supportTemplates.hind,'Average');hinds.task='CAS';hinds.lateActivation=true;
hinds.route.points[1].task={id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'EngageTargetsInZone',params:{x:42000,y:16000,zoneRadius:18000,targetTypes:{1:'Helicopters'},priority:0}}}}};
hinds.route.points[2]=wp(48000,20000,200,55,'PATROL EAST');hinds.route.points[2].alt_type='RADIO';
hinds.route.points[3]=wp(47000,12000,200,50,'PATROL SOUTH',{id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'Orbit',params:{pattern:'Race-Track',point:{x:48000,y:20000},point2:{x:47000,y:12000},speed:50,altitude:1500}}}}});hinds.route.points[3].alt_type='RADIO';
for(const u of Object.values(hinds.units))u.payload.fuel=Number(u.payload.fuel);
const mig=aircraft('VIPER','MiG-29 Fulcrum','red',2,{x:42000,y:48000},4500,230,270,clone(templates.units.mig29),'Average');
mig.lateActivation=true;mig.route.points[1].task={id:'ComboTask',params:{tasks:{1:clone(engage)}}};
mig.route.points[2]=wp(42000,16000,4500,230,'CONTEST EXTRACTION',{id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'Orbit',params:{pattern:'Circle',speed:200,altitude:4500}}}}});
for(const prefix of ['HAVEN','LANTERN'])for(const [suffix,type,count] of [['FUEL','M978 HEMTT Tanker',1],['SERVICE','M 818',3],['COMMS','Hummer',1]]){
 const pos=prefix==='HAVEN'?haven:recovery;
 const g=addGroundGroup(m,'vehicle',{name:prefix+' '+suffix,type,side:'blue',country:'USA',count,x:pos.x+100,y:pos.y+50,heading:0,skill:'Average',spacingMetres:12});g.lateActivation=true;
}
for(const [name,type,side,count,p] of [['MEDICAL SUPPORT','M 818','blue',1,recovery],['SURVIVOR','Soldier M4','blue',1,extraction],['HUNTER-NORTH','tt_DSHK','red',2,{x:44700,y:17000}],['HUNTER-EAST','tt_DSHK','red',2,{x:41000,y:19000}]]){
 const g=addGroundGroup(m,'vehicle',{name,type,side,country:side==='blue'?'USA':'Russia',count,x:p.x,y:p.y,heading:180,skill:'Average',spacingMetres:35});
 g.lateActivation=true;if(name==='SURVIVOR'){g.hidden=true;g.hiddenOnMFD=true;}
}
for(const [name,composition,x,y] of [
 ['HUNTER-WEST',[{type:'tt_DSHK',count:2}],39500,17600],
 ['CHECKPOINT',[{type:'BRDM-2',count:2},{type:'Ural-375',count:2}],39000,22000],
 ['REINFORCEMENTS',[{type:'tt_DSHK',count:2},{type:'Ural-375',count:2}],46500,18000]
]){
 const g=addGroundGroup(m,'vehicle',{name,type:composition[0].type,count:1,composition,side:'red',country:'Russia',x,y,heading:180,spacingMetres:30,skill:'Average'});g.lateActivation=true;
}
for(const [name,type,x,y] of [['COAST-SA6-NORTH','Kub 1S91 str',59708.15840042,-12442.068703575],['COAST-STRELA-CENTRAL','Strela-10M3',43434.245040351,5335.1690961685]]){
 const sam=addGroundGroup(m,'vehicle',{name,type,side:'red',country:'Russia',count:1,x,y,heading:270,skill:'High',spacingMetres:40,...(name==='COAST-SA6-NORTH'?{composition:[{type:'Kub 1S91 str',count:1},{type:'Kub 2P25 ln',count:3}]}:{})});sam.route.points[1].speed=0;
 if(name==='COAST-SA6-NORTH'){
  sam.route.points[1].task={id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'WrappedAction',params:{action:{id:'Option',params:{name:9,value:2}}}}}}};
  sead.route.points[1].task={id:'ComboTask',params:{tasks:{1:{number:1,enabled:true,auto:false,id:'EngageGroup',params:{groupId:sam.groupId,visible:true,priority:0,weaponType:32768}}}}};
 }

 const truck=addGroundGroup(m,'vehicle',{name:name+' SUPPORT',type:'Ural-375',side:'red',country:'Russia',count:1,x:x+45,y:y+30,heading:0,skill:'Average'});truck.route.points[1].speed=0;
}
addTriggerZone(m,{name:'EXTRACTION',...extraction,radius:2500}); // Search region; rescue.lua owns the crash sites.
addTriggerZone(m,{name:'RECOVERY',...recovery,radius:250});
addTriggerZone(m,{name:'PACKAGE GATE',...extraction,radius:6000});
const brief=`OPERATION GREEN LANTERN\nSyria / fictional Latakia-area rescue / single-player rescue flight of two plus a two-ship overwatch flight\n\nYou are Anvil 1-1, with engines running on your own helipad at FARP HAVEN, approximately 13 nautical miles southwest of the pickup-zone center. You lead Anvil 1, a pair of OH-58Ds: you carry two Hellfires and a gun; Anvil 1-2 carries a gun and seven M151 rockets. LONGBOW is a separate two-ship AI Kiowa flight, each with two Hellfires and a gun, Excellent skill and missile-only scripted attack assignments. All four start hot on four separate visible SINGLE_HELIPAD objects in a 60 m-spaced square at HAVEN. Each aircraft is explicitly placed on its own pad at zero terrain-relative altitude; there are no shared parking slots. Longbow waits for your takeoff, then transits to an overwatch area centered 3 nm south of WP3. Its orbit is terrain-relative in height and is an area hold, not an exact hover point. Check systems and weapons, then depart when ready. Use the normal wingman radio commands to direct attacks or rejoin. FARP ATC: HAVEN 128.500 MHz AM; LANTERN 127.500 MHz AM. Both FARPs provide fuel, ammunition, repairs and ground power. Park on or close to the pad and use the Ground Crew radio menu; shut down for repairs. Fly the route toward WP2, then WP3. Plan about 9 minutes inbound at 90 knots, plus preflight checks, extraction and approximately 17 minutes outbound to FARP LANTERN. Guardian launches from STENNIS when you lift off, and BRUISER launches three minutes later; the pursuit waits for your approach. You can launch Guardian earlier using F10 Other > Air Support > Launch carrier package.\n\nMISSION\nRecover downed pilot Sparrow, then land in the landing pad at WP4 (FARP LANTERN casualty collection point, approximately 25 nm southwest of the pickup area). LANTERN is a separate field site with a fixed landing pad, medical tent and support vehicle. WP4 is exactly at the pad; it does not relocate during setup. After pickup, fly southwest into friendly territory for medical handover. WP3 is the centre of a 2.5 km search region, not Sparrow's position. Each mission start picks one of several possible crash sites inside that region, then places Sparrow on a safe landing site within 200 m of it, so he may be up to about 2.4 km from WP3. His exact unit icon and position are hidden on the F10 map; the F10 search marker and circle stay centred on WP3. Within about 15 km of him, F10 Other > Rescue > Contact Sparrow (direction fix) gives a rough grid bearing and range from your position; the fix is deliberately approximate, sharpens as you close and can be repeated every 30 seconds. When within 2 km of Sparrow himself, use Request survivor smoke (green), then visually locate him. There is no green smoke until requested.\n\nPICKUP\nLand within 400 m of Sparrow, below 1 m/s ground speed, and remain still. Pickup is automatic and simulated: hold for 20 seconds within 100 m, with additional approach time at 3 m/s beyond that distance (up to two minutes total at 400 m). The run and boarding are simulated; no passenger animation or native troop-carrying feature is required. Moving or taking off resets the timer. At FARP LANTERN, fly directly to the WP4 landing pad and hold on the ground for 15 seconds within 100 m to complete the rescue.\n\nCOORDINATION\nTwo F/A-18Cs, Guardian, are based aboard USS STENNIS, initially ${carrierDistanceNm} nm northwest of the extraction area. Request the air package before departure using F10; the shorter inbound route from HAVEN takes less time than the carrier aircraft transit. Automatic launch at your takeoff remains a fallback. Allow approximately 12-18 minutes for launch, climb and transit (planning estimate; actual AI timing varies). Depart HAVEN at about 90 knots and hold at the IP if Guardian has not checked in. An E-2C Hawkeye, OVERLORD, launches from STENNIS at mission start and establishes an offshore radar orbit at about 25,000 ft. Contact AWACS on 251.000 MHz AM via the normal radio menu.\n\nWave 1: WEASEL (two F/A-18Cs, two AGM-88C HARMs each) launches with Guardian and attacks the radar-guided coastal SA-6. F10 offers a generic WEASEL radar-suppression request. A confirmed tracking-radar kill is reported; radar silence alone is not confirmation. HARMs cannot defeat the IR-guided Strela-10, which remains a BRUISER or Kiowa target.\n\nGuardian conducts the fighter sweep and provides air cover against MiGs, holds on station for up to 20 minutes unless fuel or combat requires earlier recovery, and returns to STENNIS. Wave 2: BRUISER, two F/A-18Cs with four AGM-65F Mavericks each and internal guns, launches three minutes after Guardian. They hold southwest of extraction awaiting your clearance. F10 Other > Air Support offers Request CAS near me, Request radar suppression, and Hold fire / cancel CAS. A request assigns a 5 km search area centered on your position at the time of the call; it does not reveal enemy unit names, group names or target counts. Move to a useful observation position before requesting support. Requests are queued until BRUISER is within 20 km of targets in that area. Attack assignments are deferred if an enemy vehicle is within 700 m of Sparrow or any of the four OH-58s. This is a scripted separation check, not a guarantee against collateral damage after weapons release. Both flights recover aboard STENNIS. The carrier maintains a steady flight-operations course; its distance changes during the sortie. STENNIS: TACAN 74X, ICLS 11, ATC 127.500 MHz AM.\n\nLONGBOW OVERWATCH\nF10 Other > Overwatch: Engage vehicles near me requests one vehicle attack within 2 km of your position at the time of the call; Hold fire / resume overwatch cancels pending attacks; Return to HAVEN recalls the pair. They hold fire until requested, use Hellfires only, require a shooter within 6.5 km slant range and a terrain sight line, and exclude targets within 700 m of Sparrow or any friendly Kiowa. Native AI may reposition to attack; the script breaks off if the lead approaches within 4 km of Sparrow, on unsafe proximity, target loss or after 90 seconds. These limits do not guarantee a stationary shot, hit or safety after missile release. One attack request does not authorize automatic follow-on targets. Longbow returns to HAVEN after Sparrow boards; Anvil delivers him to the fixed WP4 LANTERN pad. Native launch, orbit, missile guidance and four-pad usage require a DCS sortie.\n\nTHREATS\nTwo pairs of DShK technicals begin hunting Sparrow when you come within 8 km of him. Patrols are positioned around his actual crash site, not WP3. A western patrol adds two more technicals; an eastern checkpoint has two BRDM-2 scout cars and two trucks. Four minutes after the hunt starts, two technicals and two trucks reinforce the area. Destroying every vehicle is optional; prioritize clearing the pickup and recovering Sparrow. Two Mi-24V Hinds activate at the same gate and patrol east/south of extraction, searching for your helicopters. They carry rockets and cannon; Guardian can engage them when detected. Two MiG-29s launch into the fight 75 seconds after you cross 6 km from WP3, the search-region centre, attempting to penetrate the extraction area. Coastal air defenses: an SA-6 battery north of Latakia (one tracking radar and three launchers) and a Strela-10 team west of extraction, each with a soft support truck. Their positions are taken from existing Syria mission ground placements. Bruiser transits at 2500 m MSL and can face short-range SAM fire; Guardian remains higher for the fighter sweep. Use WEASEL radar suppression for radar threats. BRUISER requests cover the area near your helicopter, allowing you to request support against threats you encounter along the route. Killing the support truck does not neutralize the missile launcher. The technicals can kill Sparrow; a vehicle within 80 m for 20 seconds also captures him. Prioritize the rescue over destroying every enemy.\n\nLOADOUT / COMMS\nOH-58D: Anvil 1-1 and both Longbow helicopters each carry two Hellfires and an M3P .50-cal gun with 500 rounds. Anvil 1-2 carries the same gun plus seven M151 rockets. All four carry 30 flares and 270 kg fuel (about 81% of the 333.69 kg tank capacity). This is a fuel-capacity check, not a verified gross-weight or hover-performance check. Check the DCS loadout weight and cockpit performance calculations before takeoff. Plan approximately 25 minutes cruise plus ground time, combat and recovery. Monitor actual fuel time remaining and preserve a 20-minute reserve; shorten the attack or divert to LANTERN if needed. Use the MMS laser to designate light vehicles. Guardian: air-to-air loadout with two external fuel tanks for the carrier transit. UHF 251.000 MHz AM. Scripted coordination appears as text; no voice files. F10 Other > Rescue provides Status / return directions, Contact Sparrow (direction fix) and Request survivor smoke (green), only. WP4 and the F10 LANTERN marker coincide with the fixed medical landing pad. No recovery smoke command or automatic recovery smoke is used.\n\nCONDITIONS\nUnit labels are forced OFF. The F10 map is restricted to friendly units only; enemy assets are hidden. The Sparrow search-region marker and circle around WP3 and the exact LANTERN landing-pad marker remain available. 08:00 local, clear, light wind, QNH 1013 hPa / 29.92 inHg. Rescue fails if Sparrow is killed/captured, your helicopter is destroyed, or 25 minutes elapse after the hunt starts without pickup. A successful return sets mission-success flag 902; failure sets 903. Flying continues after the result.\n\nRequires Syria and OH-58D. No UH-60L, MIST, MOOSE, or other mod required. Terrain positions and AI behavior still require an in-simulator flight check.`;
setBriefing(m,'Operation GREEN LANTERN - OH-58D Rescue',brief);m.descriptionBlueTask=brief;
hideEnemyGroupsFromPlanner(m);
await loadScripts(s,s.dictionary,[{filePath:path.join(base,'src/rescue.lua')}]);
// Native trees-only clearance prepares the fixed starting pads before Lua runs.
// The pinned authoring compiler does not support this action; retain both forms.
const havenClearing=addTriggerZone(m,{name:'HAVEN TREES ONLY CLEARING',...haven,radius:200});
const loader=m.trigrules[1];
loader.actions=Object.fromEntries([{predicate:'a_remove_scene_objects',zone:havenClearing.zoneId,objects_mask:1},...Object.values(loader.actions)].map((a,i)=>[i+1,a]));
m.trig.actions[1]=`a_remove_scene_objects(${havenClearing.zoneId},1);`+m.trig.actions[1];
refresh(s);const report=validateMission(s.document);if(report.errors.length)throw Error(JSON.stringify(report));
assert(Math.abs(Math.hypot(carrierPos.x-extraction.x,carrierPos.y-extraction.y)/1852-carrierDistanceNm)<1e-8);
for(const g of [cap,cas,sead,hawkeye]){
  for(const u of Object.values(g.units))assert(Math.hypot(u.x-carrierPos.x,u.y-carrierPos.y)<1,'Carrier aircraft must start on the moved ship');
  for(const i of [1,4]){
    const p=g.route.points[i];assert.equal(p.linkUnit,carrierId);assert.equal(p.helipadId,carrierId);
    assert(Math.hypot(p.x-carrierPos.x,p.y-carrierPos.y)<1,'Carrier launch/recovery must match the moved ship');
  }
}
assert.equal(Object.keys(player.units).length,2);assert.equal(Object.keys(overwatch.units).length,2);
const starters=[...Object.values(player.units),...Object.values(overwatch.units)];
for(const [i,u]of starters.entries()){
 const p=havenPads[i];assert.equal(u.x,p.x);assert.equal(u.y,p.y);assert.equal(u.alt,0);assert.equal(u.alt_type,'RADIO');assert(!('parking'in u)&&!('parking_id'in u));
 for(const v of starters.slice(i+1))assert(Math.hypot(u.x-v.x,u.y-v.y)>=60-1e-8,'Starting helicopters must be physically separated');
}
for(const g of [player,overwatch]){const p=g.route.points[1];assert.equal(p.type,'TakeOffGroundHot');assert.equal(p.action,'From Ground Area Hot');assert(!p.linkUnit&&!p.helipadId);}
assert(Math.abs(Math.hypot(overwatchPoint.x-extraction.x,overwatchPoint.y-extraction.y)/1852-3)<1e-8);
for(const u of Object.values(overwatch.units)){assert.equal(u.skill,'Excellent');assert.equal(u.payload.pylons[5].CLSID,'OH58D_AGM_114_R');}
assert.equal(player.route.points[4].x,recovery.x);assert.equal(player.route.points[4].y,recovery.y);
const out=path.join(base,'dist/Operation-Green-Lantern-Syria-OH58D.miz');
const warehouse=()=>({coalition:'BLUE',size:100,speed:16.666666,periodicity:30,unlimitedMunitions:true,unlimitedAircrafts:true,unlimitedFuel:true,OperatingLevel_Air:10,OperatingLevel_Fuel:10,OperatingLevel_Eqp:10,aircrafts:{},weapons:{},suppliers:{},gasoline:{InitFuel:100},methanol_mixture:{InitFuel:100},diesel:{InitFuel:100},jet_fuel:{InitFuel:100},dynamicSpawn:false,dynamicCargo:false,allowHotStart:false});
const archive=new AdmZip(s.sourceBytes);archive.updateFile('warehouses',Buffer.from(serializeLuaAssignment('warehouses',{airports:{},warehouses:{...Object.fromEntries(havenPads.map(p=>[p.id,warehouse()])),200:warehouse(),[carrierId]:warehouse()}})));s.sourceBytes=archive.toBuffer();
await saveSessionAs(s,out,true);
fs.writeFileSync(path.join(base,'dist/Operation-Green-Lantern-Briefing.txt'),brief);
fs.writeFileSync(path.join(base,'.build/mission.json'),JSON.stringify(m));
fs.writeFileSync(path.join(base,'.build/mission.lua'),serializeLuaAssignment('mission',m));
console.log(JSON.stringify({out,validation:report,groups:s.document.groups.map(g=>({name:g.name,units:g.units.length}))},null,2));
