import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {resolveMissionsDir,installMission} from './deploy.mjs';

const root=path.resolve(import.meta.dirname,'../..');
const [action='build',name]=process.argv.slice(2);
if(action!=='setup'&&(typeof name!=='string'||!/^[a-z0-9-]+$/.test(name)))throw Error('Specify a mission folder name: node shared/tools/mission.mjs <build|test|verify|deploy> <mission-slug>.');
const dir=name?path.join(root,'missions',name):null;
const vendor=path.join(root,'vendor/dcs-mcp');
function run(exe,args,cwd=root,env=process.env){
  const r=spawnSync(exe,args,{cwd,env,stdio:'inherit'});
  if(r.error)throw r.error;
  if(r.status!==0)process.exit(r.status??1);
}
function lua(){
  const candidates=[process.env.DCS_LUA,
    'C:/Program Files (x86)/Steam/steamapps/common/DCSWorld/bin/luae.exe',
    'C:/Program Files/Eagle Dynamics/DCS World/bin/luae.exe',
    'C:/Program Files/Eagle Dynamics/DCS World/bin-mt/luae.exe'];
  const found=candidates.find(p=>p&&fs.existsSync(p));
  if(!found)throw Error('Set DCS_LUA to your DCS bin/luae.exe path, then rerun.');
  return found;
}
const build=()=>run(process.execPath,[path.join(dir,'src/build.mjs')]);
const config=()=>JSON.parse(fs.readFileSync(path.join(dir,'mission.json'),'utf8'));
function artifact(){
  const filename=config().artifact;
  if(typeof filename!=='string'||path.basename(filename)!==filename||!filename.endsWith('.miz'))throw Error('mission.json artifact must be a .miz filename.');
  return path.join(dir,'dist',filename);
}
const test=()=>run(lua(),[config().logicTest],dir);
const verify=()=>{
  run(process.execPath,[path.join(vendor,'scripts/verify-mission.mjs'),artifact()],root,{...process.env,DCS_LUA:lua()});
  // Run after setup/build: importing vendor-dependent verification here at
  // module load would break setup on a checkout without the submodule/packages.
  run(process.execPath,[path.join(root,'shared/tools/verify-planner.mjs'),artifact()]);
};
switch(action){
  case 'setup': {
    run('git',['submodule','update','--init','--recursive','--','vendor/dcs-mcp']);
    // Launch npm through Node, avoiding shell quoting and Windows .cmd execution.
    const npm=process.env.npm_execpath;
    if(!npm)throw Error('Run setup through npm: npm run setup');
    run(process.execPath,[npm,'ci','--prefix',vendor]);
    run(process.execPath,[path.join(vendor,'node_modules/typescript/bin/tsc')],vendor);
    break;
  }
  case 'build': build();break;
  case 'test': build();test();break;
  case 'verify': build();verify();break;
  case 'deploy': {
    const missionsDir=resolveMissionsDir();
    lua(); // Fail before building if the required verification runtime is unavailable.
    build();test();verify();
    console.log(JSON.stringify({deployment:installMission(artifact(),missionsDir),next:'Restart the mission in DCS to load this build.'},null,2));
    break;
  }
  default:throw Error('Expected setup, build, test, verify or deploy.');
}
