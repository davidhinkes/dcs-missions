-- Mandatory duel orchestration; native DCS AI performs all flight and combat.
NEEDLE_FANG={phase='waiting',seen={}}
local S=NEEDLE_FANG
local C=NEEDLE_FANG_CONFIG
local names={player='NEEDLE-1',friendly='BLUE-OBJECTIVE-1',enemy='RED-OBJECTIVE-1',hind='FANG-1'}
local function say(text)
  trigger.action.outTextForCoalition(2,'NEEDLE AND FANG: '..text,20)
  env.info('[NEEDLE_FANG] '..text)
end
local function unit(name)
  local u=Unit.getByName(name)
  if u and u:isExist() and u:getLife()>0 then return u end
end
local function finish(success,reason)
  if S.phase=='won' or S.phase=='failed' then return end
  S.phase=success and 'won' or 'failed'
  trigger.action.setUserFlag(success and 950 or 951,1)
  -- End native AI firing as a best-effort ceasefire; released weapons remain live.
  for _,name in ipairs({'FANG','BLUE-OBJECTIVE','RED-OBJECTIVE'})do
    pcall(function()local g=Group.getByName(name);if g then g:getController():setOption(0,4)end end)
  end
  say((success and 'MISSION SUCCESS: ' or 'MISSION FAILED: ')..reason)
end
local function status()
  local player=unit(S.playerName or names.player)
  local groundState=player and (player:inAir() and 'DCS reports your aircraft AIRBORNE: Ground Crew will be hidden until landed. ' or 'DCS reports your aircraft LANDED. Use the local/intercom Communications menu > Ground Crew, not a FARP radio-frequency call. ') or ''
  if S.phase=='waiting' then say('Waiting for all four duel units to load. No victory is awarded for missing initial units.');return end
  if S.phase=='failed' then say(groundState..'Mission failed. Restart for another attempt.');return end
  if S.phase=='won' then say(groundState..'Enemy ground target destroyed; round won. Optional recovery/rearm is at WP3.');return end
  say(groundState..(S.launched and 'Duel active. ' or 'Take off when ready to release the opposing helicopter. ')
    ..'Defended vehicle: '..(unit(names.friendly) and 'alive. ' or 'lost. ')
    ..'Enemy vehicle: '..(S.vehicleDestroyed and 'confirmed destroyed. ' or 'not confirmed destroyed. ')
    ..'Enemy helicopter: '..(S.hindDestroyed and 'confirmed destroyed.' or 'not confirmed destroyed; position unknown.'))
end
local function ground(p)return {x=p.x,y=land.getHeight({x=p.x,y=p.y}),z=p.y}end
local function validateSites()
  for _,p in ipairs({C.blueAsset,C.redAsset,C.blueFarp,C.redFarp})do
    local kind=land.getSurfaceType({x=p.x,y=p.y})
    assert(kind==1 or kind==4 or kind==5,'A fixed objective/FARP is not on land; inspect placement in DCS')
  end
  for _,p in ipairs({C.blueFarp,C.redFarp})do
    local h=land.getHeight({x=p.x,y=p.y})
    for _,offset in ipairs({{15,0},{-15,0},{0,15},{0,-15}})do
      assert(math.abs(land.getHeight({x=p.x+offset[1],y=p.y+offset[2]})-h)<=2.5,'A fixed FARP is too steep; inspect placement in DCS')
    end
  end
end
local function tick(_,now)
  if S.phase=='won' or S.phase=='failed' then return nil end
  local player=unit(S.playerName or names.player)
  if not player and coalition and coalition.getPlayers then
    for _,candidate in ipairs(coalition.getPlayers(2) or {})do
      if candidate:isExist() and candidate:getLife()>0 and candidate:getTypeName()=='OH58D' then player=candidate;S.playerName=candidate:getName();break end
    end
  end
  local friendly,enemy,hind=unit(names.friendly),unit(names.enemy),unit(names.hind)
  local current={player=player,friendly=friendly,enemy=enemy,hind=hind}
  for key,u in pairs(current)do if u then S.seen[key]=true end end
  -- Friendly loss always has precedence, even before initial setup is complete.
  if S.seen.friendly and not friendly then finish(false,'Your defended vehicle was destroyed.');return nil end
  if S.seen.player and not player then
    S.missingAt=S.missingAt or now
    if now-S.missingAt>=C.playerMissingGrace then finish(false,'Your Kiowa was lost.');return nil end
    return now+1
  end
  S.missingAt=nil
  if not S.ready then
    if not(S.seen.player and S.seen.friendly and S.seen.enemy and S.seen.hind)then return now+1 end
    validateSites()
    S.ready=true;S.phase='ready'
    trigger.action.markToCoalition(8201,'DEFEND: friendly technical',ground(C.blueAsset),2,true)
    trigger.action.markToCoalition(8202,'1T: enemy defended technical - fixed intelligence',ground(C.redAsset),2,true)
    trigger.action.markToCoalition(8203,'BLUE FARP - optional WP3 recovery',ground(C.blueFarp),2,true)
    local g=Group.getByName('FANG');assert(g,'Mandatory Hind group unavailable')
    g:getController():setOption(0,4) -- hold fire until the launch release
    for _,n in ipairs({'BLUE COVER','RED COVER'})do local cover=Group.getByName(n);if cover then cover:getController():setOnOff(false)end end
    say('Ready. Protect your technical; destroying the enemy ground target wins immediately. The helicopter kill is optional. Enemy target is 1T; take off to begin the hunt. Rearm at your FARP through Ground Crew.')
    -- Read-only native state evidence for a missing Ground Crew menu. It does
    -- not claim that a stocked warehouse has delivered ammunition.
    pcall(function()
      local base=Airbase and Airbase.getByName and Airbase.getByName('BLUE FARP')
      env.info('[NEEDLE_FANG] Departure services: playerInAir='..tostring(player:inAir())..', registeredFarp='..tostring(base~=nil)..', farpCoalition='..tostring(base and base:getCoalition() or 'unavailable'))
    end)
  end
  if not enemy and not S.vehicleDestroyed then
    S.vehicleDestroyed=true;trigger.action.setUserFlag(952,1)
    finish(true,'Enemy ground target destroyed. Round over; the helicopter kill is optional.');return nil
  end
  if not hind and not S.hindDestroyed then
    S.hindDestroyed=true;trigger.action.setUserFlag(953,1)
    say('Enemy helicopter confirmed destroyed. The round continues: destroy the enemy ground target and protect yours.')
  end
  if not S.launched and player and player:inAir() then
    S.launched=true;S.phase='active'
    if hind then
      local g=Group.getByName('FANG');assert(g,'Mandatory Hind group unavailable at launch')
      g:getController():setOption(0,2);g:getController():setCommand({id='Start'})
      say('Hunt started. The opposing helicopter has been released for launch; its position will not be reported.')
    end
  end
  if S.launched and hind and hind:inAir() and not S.airborneReported then
    S.airborneReported=true;say('Opposing helicopter airborne. Defend your asset; use cover and watch the approaches.')
  end
  return now+1
end
-- Death events resolve the race in observed event order, rather than making a
-- later friendly loss reverse an earlier ground-target kill between poll ticks.
if world and world.addEventHandler and world.event then
  world.addEventHandler({onEvent=function(_,e)
    if S.phase=='won' or S.phase=='failed' then return end
    if e.id~=world.event.S_EVENT_DEAD and e.id~=world.event.S_EVENT_UNIT_LOST then return end
    local ok,name=pcall(function()return e.initiator:getName()end)
    if not ok then return end
    if name==(S.playerName or names.player) and S.seen.player then finish(false,'Your Kiowa was destroyed. Round over.')
    elseif name==names.friendly then finish(false,'Your defended ground target was destroyed. Round over.')
    elseif name==names.enemy then
      S.vehicleDestroyed=true;trigger.action.setUserFlag(952,1)
      finish(true,'Enemy ground target destroyed. Round over; the helicopter kill is optional.')
    end
  end})
end
local menu=missionCommands.addSubMenuForCoalition(2,'Duel')
missionCommands.addCommandForCoalition(2,'Status / objectives',menu,status)
timer.scheduleFunction(function(_,now)
  local ok,nextTime=pcall(tick,nil,now)
  if not ok then env.info('[NEEDLE_FANG] Mandatory setup/task error: '..tostring(nextTime));finish(false,'Duel setup or AI task failed; see dcs.log.');return nil end
  return nextTime
end,nil,timer.getTime()+1)
