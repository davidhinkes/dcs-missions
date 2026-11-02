import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';

const root=path.resolve(import.meta.dirname,'../..');
const [action='build',name='green-lantern']=process.argv.slice(2);
if(!/^[a-z0-9-]+$/.test(name))throw Error('Use a mission folder name containing letters, numbers and hyphens.');
const dir=path.join(root,'missions',name);
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
  case 'test': build();run(lua(),['tests/rescue-test.lua'],dir);break;
  case 'verify': {
    build();
    run(process.execPath,[path.join(vendor,'scripts/verify-mission.mjs'),path.join(dir,'dist/Operation-Green-Lantern-Syria-OH58D.miz')],root,{...process.env,DCS_LUA:lua()});
    break;
  }
  default:throw Error('Expected setup, build, test or verify.');
}
