import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {resolveMissionsDir,installMission} from './deploy.mjs';

function sandbox(t){
  const parent=path.resolve(import.meta.dirname,'../../work/deploy-tests');
  fs.mkdirSync(parent,{recursive:true});
  const p=fs.mkdtempSync(path.join(parent,'case-'));
  t.after(()=>{if(path.dirname(p)!==parent)throw Error('Unexpected test cleanup path');fs.rmSync(p,{recursive:true,force:true});});
  return p;
}
test('detects one standard profile and rejects missing or ambiguous profiles',t=>{
  const home=sandbox(t);
  assert.throws(()=>resolveMissionsDir({home,override:''}),/missing or ambiguous/);
  fs.mkdirSync(path.join(home,'Saved Games','DCS'),{recursive:true});
  assert.equal(resolveMissionsDir({home,override:''}),path.join(home,'Saved Games','DCS','Missions'));
  fs.mkdirSync(path.join(home,'Saved Games','DCS.openbeta'));
  assert.throws(()=>resolveMissionsDir({home,override:''}),/missing or ambiguous/);
  assert.equal(resolveMissionsDir({home,override:path.join(home,'custom')}),path.join(home,'custom'));
  assert.throws(()=>resolveMissionsDir({home,override:'relative'}),/absolute/);
});
test('copies verified bytes, preserves manual edits, and avoids duplicate backups on unchanged deployment',t=>{
  const p=sandbox(t),source=path.join(p,'mission.miz'),target=path.join(p,'Missions');
  fs.writeFileSync(source,'build one');
  const first=installMission(source,target);
  assert.equal(fs.readFileSync(first.destination,'utf8'),'build one');
  assert.equal(first.backup,null);
  fs.writeFileSync(first.destination,'manual editor changes');
  fs.writeFileSync(source,'build two');
  const second=installMission(source,target);
  assert.equal(fs.readFileSync(second.backup,'utf8'),'manual editor changes');
  assert.equal(fs.readFileSync(second.destination,'utf8'),'build two');
  assert.equal(installMission(source,target).changed,false);
  assert.equal(fs.readdirSync(path.join(target,'.mission-backups')).length,1);
  assert.deepEqual(fs.readdirSync(target).sort(),['.mission-backups','mission.miz']);
});
test('a damaged pre-existing backup blocks replacement of the installed mission',t=>{
  const p=sandbox(t),source=path.join(p,'mission.miz'),target=path.join(p,'Missions');
  fs.writeFileSync(source,'first');installMission(source,target);
  fs.writeFileSync(source,'second');const result=installMission(source,target);
  fs.writeFileSync(result.backup,'damaged backup');
  fs.writeFileSync(result.destination,'first');
  assert.throws(()=>installMission(source,target),/Backup verification failed/);
  assert.equal(fs.readFileSync(result.destination,'utf8'),'first');
});
