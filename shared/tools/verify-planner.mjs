import {verifyPlannerArchive} from './planner.mjs';

const filename=process.argv[2];
if(!filename)throw Error('Specify the mission archive to check.');
console.log(`VERIFY planner: all ${verifyPlannerArchive(filename)} enemy groups hidden in the packed mission`);
