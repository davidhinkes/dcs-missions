import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {createHash,randomUUID} from 'node:crypto';

const digest=bytes=>createHash('sha256').update(bytes).digest('hex');
export function resolveMissionsDir({override=process.env.DCS_MISSIONS_DIR,home=os.homedir()}={}){
  if(override){
    if(!path.isAbsolute(override))throw Error('DCS_MISSIONS_DIR must be an absolute path.');
    return path.resolve(override);
  }
  const profiles=['DCS','DCS.openbeta'].map(n=>path.join(home,'Saved Games',n)).filter(p=>fs.existsSync(p));
  if(profiles.length!==1)throw Error('Set DCS_MISSIONS_DIR to the full path of your active DCS Missions folder (profile missing or ambiguous).');
  return path.join(profiles[0],'Missions');
}

export function installMission(source,missionsDir){
  const filename=path.basename(source);
  if(!filename.endsWith('.miz'))throw Error('Only .miz mission files can be deployed.');
  const bytes=fs.readFileSync(source),sha256=digest(bytes);
  fs.mkdirSync(missionsDir,{recursive:true});
  const destination=path.join(missionsDir,filename);
  let backup=null;
  if(fs.existsSync(destination)){
    const previous=fs.readFileSync(destination),previousHash=digest(previous);
    if(previousHash===sha256)return {destination,sha256,backup,changed:false};
    const backupDir=path.join(missionsDir,'.mission-backups');
    fs.mkdirSync(backupDir,{recursive:true});
    backup=path.join(backupDir,filename+'.'+previousHash+'.bak');
    // Preserve every distinct previous file, including manual Mission Editor edits.
    if(!fs.existsSync(backup))fs.writeFileSync(backup,previous,{flag:'wx'});
    if(digest(fs.readFileSync(backup))!==previousHash)throw Error('Backup verification failed; installed mission was not replaced.');
  }
  const temporary=path.join(missionsDir,'.'+filename+'.'+randomUUID()+'.tmp');
  try{
    fs.writeFileSync(temporary,bytes,{flag:'wx'});
    if(digest(fs.readFileSync(temporary))!==sha256)throw Error('Copy verification failed; installed mission was not replaced.');
    fs.renameSync(temporary,destination);
    if(digest(fs.readFileSync(destination))!==sha256)throw Error('Installed mission hash does not match the build.');
  }finally{
    if(fs.existsSync(temporary))fs.unlinkSync(temporary);
  }
  return {destination,sha256,backup,changed:true};
}
