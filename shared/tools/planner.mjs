import assert from 'node:assert/strict';
import AdmZip from '../../vendor/dcs-mcp/node_modules/adm-zip/adm-zip.js';
import {parseLuaAssignment} from '../../vendor/dcs-mcp/dist/miz/lua.js';

function* enemyGroups(mission){
  // Current collection missions put the player on blue and opposition on red.
  for(const country of Object.values(mission.coalition?.red?.country??{})){
    for(const category of Object.values(country)){
      if(!category||typeof category!=='object'||!category.group)continue;
      for(const group of Object.values(category.group))yield group;
    }
  }
}

/** Hide enemy map objects/routes without changing player intelligence or AI tasks. */
export function hideEnemyGroupsFromPlanner(mission){
  for(const group of enemyGroups(mission)){
    group.hiddenOnPlanner=true;group.hidden=true;group.hiddenOnMFD=true;
  }
}

export function checkPlannerVisibility(mission){
  let count=0;
  for(const group of enemyGroups(mission)){
    assert.equal(group.hiddenOnPlanner,true,`Enemy group '${group.name}' is visible in Mission Planner`);
    assert.equal(group.hidden,true,`Enemy group '${group.name}' lacks hidden map setting`);
    assert.equal(group.hiddenOnMFD,true,`Enemy group '${group.name}' lacks hidden MFD setting`);
    count++;
  }
  return count;
}

/** Check the delivered archive; checking the source object alone can miss packing errors. */
export function verifyPlannerArchive(filename){
  const source=new AdmZip(filename).readAsText('mission');
  return checkPlannerVisibility(parseLuaAssignment(source,'mission'));
}
