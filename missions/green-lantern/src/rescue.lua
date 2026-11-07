-- Self-contained mission logic. No external scripting framework required.
GREEN_LANTERN = { phase = 'setup', huntAt = nil, coverAt = nil, boarded = false }
local S = GREEN_LANTERN
local patrolCounts={['COAST-SA6-NORTH']=4,['COAST-STRELA-CENTRAL']=1,['HUNTER-NORTH']=2,['HUNTER-EAST']=2,['HUNTER-WEST']=2,['CHECKPOINT']=4,['REINFORCEMENTS']=4}
local pickup, home
local function say(text, seconds)
  trigger.action.outTextForCoalition(2, 'GREEN LANTERN: '..text, seconds or 15)
  env.info('[GREEN_LANTERN] '..text)
end
local function distance(a,b) return math.sqrt((a.x-b.x)^2+(a.z-b.z)^2) end
local function alive(name)
  local u = Unit.getByName(name)
  if u and u:isExist() and u:getLife() > 0 then return u end
end
local function copy(t)
  if type(t) ~= 'table' then return t end
  local n = {}; for k,v in pairs(t) do n[k] = copy(v) end; return n
end
local function template(name)
  for _,side in pairs(env.mission.coalition) do
    for _,country in pairs(side.country or {}) do
      for _,g in pairs((country.vehicle or {}).group or {}) do
        if g.name == name then return copy(g), country.id end
      end
    end
  end
  error('Missing ground template '..name)
end
local function ground(x,z) return {x=x,y=land.getHeight({x=x,y=z}),z=z} end
local function clearPoint(x,z,vehicle)
  local p = ground(x,z)
  local kind = land.getSurfaceType({x=x,y=z})
  if kind ~= 1 and kind ~= 4 and kind ~= 5 then return nil end
  for _,offset in ipairs({{30,0},{-30,0},{0,30},{0,-30},{20,20},{-20,-20}}) do
    local q = {x=x+offset[1],y=z+offset[2]}
    local surface = land.getSurfaceType(q)
    if surface ~= 1 and surface ~= 4 and surface ~= 5 then return nil end
    if math.abs(land.getHeight(q)-p.y)>(vehicle and 8 or 1.5) then return nil end
  end
  local blocked = false
  world.searchObjects(Object.Category.SCENERY,
    {id=world.VolumeType.SPHERE,params={point=p,radius=vehicle and 8 or 45}},
    function() blocked=true; return false end)
  if not blocked then return p end
end
local function findClear(x,z,radius,vehicle)
  local p = clearPoint(x,z,vehicle); if p then return p end
  local step=math.min(100,radius)
  for r=step,radius,step do
    for a=0,345,15 do
      local theta=math.rad(a); p=clearPoint(x+r*math.cos(theta),z+r*math.sin(theta),vehicle)
      if p then return p end
    end
  end
  error('No clear landing/ground site near '..x..','..z)
end
-- WP3 is the centre of a 2.5 km search region. Each start picks one crash
-- site, then randomizes Sparrow within 200 m of it. Every site disc lies
-- inside the promised region and at least 5 km from Longbow's station.
local searchCenter={x=42000,z=16000}
local regionRadius=2500
local crashSites={
  {name='centre',x=42000,z=16000},
  {name='north',x=44000,z=15400},
  {name='east',x=42400,z=18100},
  {name='west',x=41600,z=14000},
}
local function pickupNear(cx,cz)
  -- Sample uniformly over the site disc, rejecting unsuitable terrain.
  -- Never expand beyond the site's 200 m radius.
  for i=1,256 do
    local radius=200*math.sqrt(math.random())
    local angle=2*math.pi*math.random()
    local p=clearPoint(cx+radius*math.cos(angle),cz+radius*math.sin(angle))
    if p then return p end
  end
  -- A narrow clearing may be missed by random samples. Choose randomly among
  -- the valid grid candidates, still confined to the same site disc.
  local candidates={}
  for dx=-200,200,20 do
    for dz=-200,200,20 do
      if dx*dx+dz*dz<=200*200 then
        local p=clearPoint(cx+dx,cz+dz)
        if p then candidates[#candidates+1]=p end
      end
    end
  end
  if #candidates>0 then return candidates[math.random(#candidates)] end
end
local function randomPickup()
  -- Random site order; a site with no safe clearing falls through to the next.
  -- GREEN_LANTERN_SITE (1-4), if set before this script loads, forces the first
  -- choice for tests or replaying a reported sortie.
  local order,remaining={}, {}
  for i=1,#crashSites do remaining[i]=i end
  local forced=tonumber(GREEN_LANTERN_SITE)
  if forced and crashSites[forced] then
    order[1]=forced;table.remove(remaining,forced)
  end
  while #remaining>0 do order[#order+1]=table.remove(remaining,math.random(#remaining)) end
  for _,i in ipairs(order) do
    local site=crashSites[i]
    local p=pickupNear(site.x,site.z)
    if p then
      S.siteIndex=i;S.site=site.name
      env.info(string.format('[GREEN_LANTERN] Crash site %d (%s) selected; pickup x=%.1f z=%.1f',i,site.name,p.x,p.z))
      return p
    end
    env.info('[GREEN_LANTERN] Crash site '..site.name..' has no safe clearing; trying another')
  end
  error('No safe pickup clearing at any crash site inside the 2.5 km WP3 search region')
end
local function waypoint(p,speed)
  return {x=p.x,y=p.z,alt=p.y,alt_type='BARO',type='Turning Point',action='Off Road',
    speed=speed,speed_locked=true,ETA=0,ETA_locked=false,task={id='ComboTask',params={tasks={}}}}
end
local function spawnGround(name,p)
  local g,country=template(name); local ox,oy=g.x,g.y
  g.x=p.x;g.y=p.z;g.lateActivation=false;g.start_time=0
  if name=='SURVIVOR' then g.hidden=true;g.hiddenOnMFD=true end
  for _,u in pairs(g.units) do
    local service=name:match('^HAVEN ') or name:match('^LANTERN ')
    local q
    if name=='SURVIVOR' then q=p
    else q=findClear(p.x+u.x-ox,p.z+u.y-oy,service and 30 or 200,true) end
    u.x=q.x;u.y=q.z;u.heading=0
  end
  g.route={points={waypoint(p,0)}}
  local group=coalition.addGroup(country,Group.Category.GROUND,g)
  assert(group, 'Failed to spawn '..name)
  if name=='SURVIVOR' then group:getController():setOnOff(false) end
  return group
end
local function serviceFarp(prefix,pad)
  local occupied={}
  local function clearOfPads(p)
    if prefix~='HAVEN' then return true end
    for _,offset in ipairs({{-30,-30},{30,-30},{-30,30},{30,30}})do
      local d=distance(p,{x=pad.x+offset[1],z=pad.z+offset[2]})
      if d<30 or d>125 then return false end -- reserve 25 m for vehicle formation offsets
    end
    return true
  end
  local function servicePoint(angle)
    -- Keep logistics within the FARP service radius while clearing the pads.
    for r=prefix=='HAVEN' and 70 or 85,prefix=='HAVEN' and 80 or 105,10 do
      for a=angle-20,angle+20,10 do
        local t=math.rad(a)
        local p=clearPoint(pad.x+r*math.cos(t),pad.z+r*math.sin(t),true)
        local free=p~=nil and clearOfPads(p)
        if p then for _,q in ipairs(occupied) do if distance(p,q)<30 then free=false end end end
        if free then occupied[#occupied+1]=p;return p end
      end
    end
    -- An assigned sector may be forested or sloping. Search other bearings
    -- rather than abandon every remaining service object at this FARP.
    for r=70,prefix=='HAVEN' and 80 or 90,10 do
      for a=0,350,10 do
        local t=math.rad(a)
        local p=clearPoint(pad.x+r*math.cos(t),pad.z+r*math.sin(t),true)
        local free=p~=nil and clearOfPads(p)
        if p then for _,q in ipairs(occupied) do if distance(p,q)<30 then free=false end end end
        if free then occupied[#occupied+1]=p;return p end
      end
    end
    error('No service vehicle site at '..prefix..' sector '..angle)
  end
  for _,entry in ipairs({{'FUEL',30},{'SERVICE',150},{'COMMS',270}}) do
    spawnGround(prefix..' '..entry[1],servicePoint(entry[2]))
  end
  for _,entry in ipairs({{'FARP Tent',90},{'FARP Fuel Depot',210},{'FARP Ammo Dump Coating',330},{'FARP CP Blindage',0}}) do
    local p=servicePoint(entry[2])
    assert(coalition.addStaticObject(2,{name=prefix..' '..entry[1],type=entry[1],category='Fortifications',x=p.x,y=p.z,heading=0,dead=false}))
  end
  env.info('[GREEN_LANTERN] '..prefix..' logistics created: fuel, repair, rearm, power and communications')
end
local function requestPilotSmoke()
  if S.boarded then say('Sparrow is already aboard. Proceed to LANTERN.');return end
  if S.phase=='failed' or S.phase=='complete' then return end
  local u=alive(S.playerName or 'RESCUE-1')
  if not u or distance(u:getPoint(),pickup)>2000 then
    say('Sparrow: I can\'t see you yet. Get within 2 km of me before I pop smoke. Use Rescue > Contact Sparrow for a direction fix.');return
  end
  trigger.action.smoke(pickup,trigger.smokeColor.Green)
  say('Sparrow: GREEN smoke out. Land within 400 m of me and hold still. Allow up to two minutes for the simulated approach and boarding.',25)
end
local function gridBearing(from,to)
  return (math.deg(math.atan2(to.z-from.z,to.x-from.x))+360)%360
end
-- Survival-radio direction fix: approximate by design, sharper when closer.
local fixRange,fixCooldown=15000,30
local function contactSparrow()
  if S.boarded then say('Sparrow is already aboard. Proceed to LANTERN.');return end
  if S.phase=='failed' or S.phase=='complete' or not pickup then return end
  local u=alive(S.playerName or 'RESCUE-1')
  if not u then say('Sparrow: no contact.');return end
  local now=timer.getTime()
  if S.fixAt and now-S.fixAt<fixCooldown then
    say(string.format('Sparrow: saving battery. Try again in %d seconds.',math.ceil(fixCooldown-(now-S.fixAt))));return
  end
  local p=u:getPoint();local range=distance(p,pickup)
  if range>fixRange then say('Sparrow: no reply. His survival radio is short-range; close within about 15 km of the WP3 search region.');return end
  S.fixAt=now
  local errorDeg=math.min(20,3+2*range/1000)
  local reported=gridBearing(p,pickup)+(2*math.random()-1)*errorDeg
  reported=(math.floor(reported/5+0.5)*5)%360
  local km=math.max(0.5,math.floor(range*(0.8+0.4*math.random())/500+0.5)*0.5)
  S.lastFix={bearing=reported,km=km,error=errorDeg}
  say(string.format('Sparrow: Anvil, I hear you. Rough fix from your position: approximate grid bearing %03d, about %.1f km (plus or minus %d degrees and 20 percent). The fix sharpens as you close; request green smoke within 2 km.',reported,km,math.ceil(errorDeg)),25)
end
local function havenNavigation(u)
  if not home or not u then return 'FARP LANTERN is marked on the F10 map.' end
  local p=u:getPoint()
  local bearing=(math.deg(math.atan2(home.z-p.z,home.x-p.x))+360)%360
  local text=string.format('FARP LANTERN: approximate grid bearing %03d degrees, range %.1f nm.',math.floor(bearing+0.5)%360,distance(p,home)/1852)
  if coord and coord.LOtoLL then
    local lat,lon=coord.LOtoLL(home)
    text=text..string.format(' Position %.5f N, %.5f E.',lat,lon)
  end
  return text..' WP4 is the actual LANTERN landing pad; land within 100 m and hold 15 seconds.'
end
local function fail(reason)
  S.phase='failed';trigger.action.setUserFlag(903,1);say('MISSION FAILED: '..reason,40)
end
local function spawnExtra(name,x,z,pursue,radius)
  local ok,err=pcall(function()
    local g=spawnGround(name,findClear(x,z,radius or 1500,true))
    if pursue then
      g:getController():setTask({id='Mission',params={route={points={waypoint(g:getUnit(1):getPoint(),6),waypoint(pickup,6)}}}})
    end
  end)
  if not ok then env.info('[GREEN_LANTERN] Optional patrol '..name..' not placed: '..tostring(err)) end
  return ok
end
local function hunt(now)
  S.huntAt=now;S.phase='inbound'
  S.westPatrol=spawnExtra('HUNTER-WEST',pickup.x-2500,pickup.z+1600,true)
  local hinds=Group.getByName('HIND-PATROL')
  if hinds then trigger.action.activateGroup(hinds);S.hindsAt=now end
  for _,name in ipairs({'HUNTER-NORTH','HUNTER-EAST'}) do
    local g=Group.getByName(name)
    local lead=g and g:getUnit(1)
    if lead then
      g:getController():setTask({id='Mission',params={route={points={waypoint(lead:getPoint(),6),waypoint(pickup,6)}}}})
      g:getController():setOption(0,2) -- ground ROE: open fire
    end
  end
  say('Sparrow reports armed pickup patrols north, east and west. An eastern checkpoint has scout cars and trucks; reinforcements may follow. Two Hinds are also searching. Clear an approach and prioritize the rescue. Use Rescue > Contact Sparrow for a direction fix.')
end
local function activate(name)
  local g=Group.getByName(name);assert(g,'Missing flight '..name);trigger.action.activateGroup(g)
end
local function launchGuardian()
  if S.coverAt then say('Guardian has already been released from STENNIS.');return end
  activate('GUARDIAN');activate('WEASEL');S.coverAt=timer.getTime();S.seadAt=S.coverAt
  say('STENNIS: Guardian fighter sweep and Weasel SEAD released for launch. Bruiser CAS follows in three minutes. Overlord Hawkeye provides radar support on 251 AM. Hold at the IP until cover checks in.',30)
end
local function requestSEAD()
  if not S.seadAt then say('Launch the air package first using F10.');return end
  local target=alive('COAST-SA6-NORTH-1')
  if not target then say('Weasel: coastal SA-6 tracking radar is no longer present.');return end
  local g=Group.getByName('WEASEL')
  if g then
    g:getController():pushTask({id='AttackUnit',params={unitId=target:getID(),groupAttack=true,weaponType=32768,attackQtyLimit=true,attackQty=1,expend='One',altitudeEnabled=false,directionEnabled=false}})
    say('Weasel: coastal SA-6 re-attack requested with HARMs. Engagement depends on radar emissions and range. Strela remains a CAS target.')
  end
end
local casRequests={}
local function requestCAS()
  if S.boarded or S.phase=='complete' or S.phase=='failed' then say('Rescue attack phase is over.');return end
  local u=alive(S.playerName or 'RESCUE-1')
  if not u then say('Bruiser: unable to establish your position.');return end
  local p=u:getPoint()
  S.casArea={x=p.x,z=p.z}
  casRequests={}
  for patrol in pairs(patrolCounts) do casRequests[patrol]=true end
  S.casTarget=nil
  S.casHoldNotice=nil;S.casSearchFinished=false
  say('Bruiser: CAS requested within 5 km of your present position. Searching that area; attacks require separation from friendly forces. Hold outside the target area.',25)
end
local function holdCAS()
  casRequests={}
  S.casArea=nil
  local g=Group.getByName('BRUISER')
  if S.casAt and g then
    g:getController():setOption(0,4)
    g:getController():resetTask()
  end
  S.casTarget=nil
  say('Bruiser: hold fire. Pending attack requests cancelled. Weapons already released cannot be recalled.')
end
local function updateCAS(now)
  if S.coverAt and not S.casAt and now-S.coverAt>=180 then
    activate('BRUISER');S.casAt=now
    say('STENNIS: Wave 2, Bruiser CAS, released for carrier launch. Mavericks and guns available on request.')
  end
  if not S.casAt then return end
  local near=false
  for _,name in ipairs({'BRUISER-1','BRUISER-2'}) do
    local u=alive(name)
    if u then
      if distance(u:getPoint(),pickup)<=20000 then near=true end
      for requested in pairs(casRequests) do
        local target=alive(requested..'-1') or alive(requested..'-2')
        if target and distance(u:getPoint(),target:getPoint())<=20000 then near=true end
      end
    end
  end
  if not near then return end
  if not S.casOnStation then S.casOnStation=true;say('Bruiser: within tasking range. Request CAS near your position through F10 Other > Air Support.') end
  if S.casTarget and alive(S.casTarget) then return end
  S.casTarget=nil
  if S.boarded or S.phase=='complete' or S.phase=='failed' then return end
  for _,patrol in ipairs({'COAST-SA6-NORTH','COAST-STRELA-CENTRAL','HUNTER-NORTH','HUNTER-EAST','HUNTER-WEST','CHECKPOINT','REINFORCEMENTS'}) do
    if casRequests[patrol] then
      local remaining=false
      for i=1,patrolCounts[patrol] or 2 do
        local name=patrol..'-'..i
        local target=alive(name)
        if target and S.casArea and distance(target:getPoint(),S.casArea)<=5000 then
          remaining=true
          local point=target:getPoint()
          local inRange=false
          for _,name in ipairs({'BRUISER-1','BRUISER-2'}) do
            local jet=alive(name)
            if jet and distance(jet:getPoint(),point)<=20000 then inRange=true end
          end
          local separated=S.boarded or distance(point,pickup)>700
          for _,friendly in ipairs({'RESCUE-1','RESCUE-2','LONGBOW-1','LONGBOW-2'}) do
            local helo=alive(friendly)
            if helo and distance(point,helo:getPoint())<=700 then separated=false end
          end
          if separated and inRange then
            local g=Group.getByName('BRUISER')
            g:getController():setOption(0,2)
            g:getController():pushTask({id='AttackUnit',params={unitId=target:getID(),groupAttack=true,weaponType=9663676414,attackQtyLimit=true,attackQty=1,expend='One',altitudeEnabled=false,directionEnabled=false}})
            S.casTarget=name
            say('Bruiser: engaging a hostile vehicle in the requested area. Keep clear.')
            return
          elseif not separated and not S.casHoldNotice then
            S.casHoldNotice=true;say('Bruiser: target too close to Sparrow or the Kiowas. Attack deferred until all are more than 700 m clear.')
          end
        end
      end
      if not remaining then casRequests[patrol]=nil end
    end
  end
  if S.casArea and not next(casRequests) and not S.casSearchFinished then
    S.casSearchFinished=true
    say('Bruiser: no further eligible targets in the requested area. Request another search if needed.')
  end
end
-- Separate two-ship support flight. Native AI still flies and guides its weapons.
local owStation={x=36444,z=16000}
local rescueAircraft={'RESCUE-1','RESCUE-2','LONGBOW-1','LONGBOW-2'}
local function owGroup()return Group.getByName('LONGBOW')end
local function owHold()
  local g=owGroup();if not g then return end
  local altitude=land.getHeight({x=owStation.x,y=owStation.z})+300
  for dx=-1500,1500,500 do for dz=-1500,1500,500 do
    altitude=math.max(altitude,land.getHeight({x=owStation.x+dx,y=owStation.z+dz})+300)
  end end
  local u=alive('LONGBOW-1') or alive('LONGBOW-2');if not u then return end
  local first=waypoint(u:getPoint(),45);first.action='Turning Point'
  local hold=waypoint({x=owStation.x,z=owStation.z,y=altitude},35);hold.action='Turning Point'
  hold.task={id='ComboTask',params={tasks={{number=1,enabled=true,auto=false,id='Orbit',params={pattern='Circle',speed=35,altitude=altitude}}}}}
  g:getController():setOption(0,4)
  g:getController():setTask({id='Mission',params={route={points={first,hold}}}})
  S.owTarget=nil;S.owAttackAt=nil;S.owHolding=true
end
local function owReturn()
  S.owArea=nil;S.owReturning=true;S.owTarget=nil
  local g=owGroup();local u=alive('LONGBOW-1') or alive('LONGBOW-2');if not g or not u then return end
  local first=waypoint(u:getPoint(),45);first.action='Turning Point'
  local landing=waypoint(ground(19918.236328125,6836.8149414062),45)
  landing.type='Land';landing.action='Landing';landing.helipadId=102;landing.linkUnit=102
  g:getController():setOption(0,4);g:getController():setTask({id='Mission',params={route={points={first,landing}}}})
  say('Longbow: returning to HAVEN. Released weapons cannot be recalled.')
end
local function owRequest()
  if S.boarded or S.phase=='complete' or S.phase=='failed' or S.owReturning or S.owDisabled then say('Longbow: attack support unavailable.');return end
  local u=alive(S.playerName or 'RESCUE-1');if not u then return end
  S.owArea=copy(u:getPoint())
  say('Longbow: one vehicle attack requested within 2 km of your call position. Holding for range, sight line and friendly separation; no automatic follow-on attacks.')
end
local function owCancel()
  S.owArea=nil
  if S.owAirborne and not S.owReturning then owHold() end
  say('Longbow: hold fire and resume overwatch. Released missiles cannot be recalled.')
end
local function owSafe(point)
  if distance(point,pickup)<=700 then return false end
  for _,name in ipairs(rescueAircraft)do local u=alive(name);if u and distance(point,u:getPoint())<=700 then return false end end
  return true
end
local function owTick(_,now)
  if S.owDisabled then return nil end
  if not pickup then return now+2 end
  if S.boarded or S.phase=='complete' or S.phase=='failed' then
    if S.owLaunched and not S.owReturning then owReturn() end
    return nil
  end
  local g=owGroup();local lead=alive('LONGBOW-1') or alive('LONGBOW-2')
  if not g or not lead then if not S.owLost then S.owLost=true;say('Longbow unavailable; continue the rescue.');end;return nil end
  local player=alive(S.playerName or 'RESCUE-1')
  if not S.owLaunched and player and player:inAir() then
    g:getController():setCommand({id='Start'});S.owLaunched=true
    say('Longbow: launching for overwatch, three nautical miles south of the search area. Hellfires available through F10 Other > Overwatch.')
  end
  if not S.owLaunched or S.owReturning or not lead:inAir() then return now+2 end
  if not S.owAirborne then S.owAirborne=true;owHold() end
  if distance(lead:getPoint(),owStation)<1000 and not S.owReady then S.owReady=true;say('Longbow: in the overwatch area. Holding fire; request a vehicle attack when needed.') end
  if S.owTarget then
    local target=alive(S.owTarget)
    if not target or not owSafe(target:getPoint()) or distance(lead:getPoint(),pickup)<4000 or now-S.owAttackAt>=90 then
      say(not target and 'Longbow: assigned vehicle destroyed; returning to overwatch.' or 'Longbow: breaking off; attack conditions or time limit reached.')
      owHold()
    end
    return now+2
  end
  if not S.owReady or not S.owArea then return now+2 end
  local shooter,missiles
  for _,name in ipairs({'LONGBOW-1','LONGBOW-2'})do
    local u=alive(name)
    if u and u:inAir() then
      local ammo=u.getAmmo and u:getAmmo() or {};local count=0
      for _,a in pairs(ammo or {})do if a.desc and a.desc.category==1 then count=count+(a.count or 0) end end
      if count>0 then shooter=u;missiles=count;break end
    end
  end
  if not shooter then S.owArea=nil;say('Longbow: no airborne Hellfire shooter available.');return now+2 end
  local best,bestRange
  for patrol,count in pairs(patrolCounts)do for i=1,count do
    local u=alive(patrol..'-'..i)
    if u then local p=u:getPoint();local range=distance(p,S.owArea)
      local start=shooter:getPoint();local aim={x=p.x,y=p.y+2,z=p.z}
      local slant=math.sqrt(distance(p,start)^2+(aim.y-start.y)^2)
      if range<=2000 and (not bestRange or range<bestRange) and slant<=6500 and owSafe(p) and land.isVisible and land.isVisible(start,aim) then best=u;bestRange=range end
    end
  end end
  if best then
    g:getController():setOption(0,2)
    g:getController():pushTask({id='AttackUnit',params={unitId=best:getID(),groupAttack=true,weaponType=131072,attackQtyLimit=true,attackQty=1,expend='One',altitudeEnabled=false,directionEnabled=false}})
    S.owTarget=best:getName();S.owAttackAt=now;S.owArea=nil
    say('Longbow: engaging a hostile vehicle with Hellfires. Keep clear; native AI controls the firing position.')
  elseif not S.owUnableNotice or now-S.owUnableNotice>=30 then
    S.owUnableNotice=now;say('Longbow: no eligible vehicle with clear terrain sight line, missile range and friendly separation. Request remains pending; cancel through Overwatch to hold fire.')
  end
  return now+2
end
local function status()
  local u=alive('RESCUE-1'); local text='Phase: '..S.phase
  if u and pickup and not S.boarded then text=text..string.format('. WP3 search region centre %.1f km away.',distance(u:getPoint(),searchCenter)/1000) end
  if S.boarded then text=text..' Sparrow aboard. '..havenNavigation(u)
  else text=text..' Sparrow is somewhere within 2.5 km of WP3. Use Rescue > Contact Sparrow for a rough direction fix, then request green smoke within 2 km of him. Land within 400 m and hold still: 20 seconds close in, up to two minutes at maximum distance.' end
  if S.coverAt then text=text..' Guardian released from STENNIS.' else text=text..' Guardian launches at your takeoff, or via F10 launch request.' end
  text=text..(S.radarCleared and ' Coastal SA-6 tracking radar destroyed.' or S.seadAt and ' Weasel working coastal radar threat.' or ' Weasel SEAD waiting for package launch.')
  text=text..(S.casOnStation and ' Bruiser CAS in range.' or S.casAt and ' Bruiser CAS inbound.' or ' Bruiser CAS is wave 2, three minutes behind Guardian.')
  text=text..(S.owReturning and ' Longbow returning to HAVEN.' or S.owTarget and ' Longbow attacking.' or S.owReady and ' Longbow overwatch ready.' or ' Longbow staging/inbound.')
  say(text,25)
end
local function speed(u)
  local v=u:getVelocity();return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
end
local function tick(_,now)
  if S.phase=='failed' or S.phase=='complete' then return nil end
  local u=alive(S.playerName or 'RESCUE-1')
  -- DCS can delay creating the player unit while loading or selecting a slot.
  -- Discover the occupied OH-58 as a fallback if the editor changed its name.
  if not u and coalition.getPlayers then
    for _,candidate in ipairs(coalition.getPlayers(2) or {}) do
      if candidate:isExist() and candidate:getTypeName()=='OH58D' and candidate:getLife()>0 then
        u=candidate;S.playerName=candidate:getName();break
      end
    end
  end
  if not u then
    if S.playerSeen then
      S.playerMissingAt=S.playerMissingAt or now
      if now-S.playerMissingAt>=10 then fail('Rescue helicopter lost.');return nil end
    elseif not S.waitingNotice then
      S.waitingNotice=true
      say('Waiting for Anvil to enter the OH-58 pilot slot. Rescue timers will remain stopped.',25)
    end
    return now+2
  end
  if not S.playerSeen then
    S.playerSeen=true
    env.info('[GREEN_LANTERN] Player helicopter acquired: '..(S.playerName or 'RESCUE-1'))
  end
  S.playerMissingAt=nil
  local pos=u:getPoint();local range=distance(pos,pickup)
  if not S.huntAt and range<=8000 then hunt(now) end
  if S.huntAt and not S.reinforcementAttempted and not S.boarded and now-S.huntAt>=240 then
    S.reinforcementAttempted=true
    S.reinforcements=spawnExtra('REINFORCEMENTS',pickup.x+4500,pickup.z+2000,true)
    if S.reinforcements then say('Sparrow: more vehicles approaching from the east! Two armed pickups and two trucks. Bruiser can take them if you need help.') end
  end
  if not S.coverAt and u:inAir() then launchGuardian() end
  updateCAS(now)
  if S.seadAt then
    if alive('COAST-SA6-NORTH-1') then S.radarSeen=true
    elseif S.radarSeen and not S.radarCleared then
      S.radarCleared=true
      say('Overlord: coastal SA-6 launcher destroyed. IR-guided Strela may still be active; this is not an all-clear for low-level flight.')
    end
  end
  if not S.threatAt and distance(pos,searchCenter)<=6000 then
    S.threatAt=now
    say('Overlord: Anvil approaching extraction. Guardian, expedite cover; hostile fighters may respond.')
  end
  if S.threatAt and not S.migs and now-S.threatAt>=75 then
    activate('VIPER');S.migs=true;say('Overlord: two hostile MiGs approaching from the east. Guardian is cleared to intercept.')
  end
  if S.coverAt and not S.coverOnStation then
    for _,n in ipairs({'GUARDIAN-1','GUARDIAN-2'}) do
      local f=alive(n)
      if f and distance(f:getPoint(),pickup)<6000 then
        S.coverOnStation=true;say('Guardian: over the extraction area. Air cover established.');break
      end
    end
  end
  if not S.boarded then
    local pilot=alive('SURVIVOR-1')
    if not pilot then fail('Sparrow has been killed.');return nil end
    local threatened=false
    for _,n in ipairs({'HUNTER-NORTH-1','HUNTER-NORTH-2','HUNTER-EAST-1','HUNTER-EAST-2','HUNTER-WEST-1','HUNTER-WEST-2','REINFORCEMENTS-1','REINFORCEMENTS-2','REINFORCEMENTS-3','REINFORCEMENTS-4'}) do
      local h=alive(n);if h and distance(h:getPoint(),pickup)<=80 then threatened=true end
    end
    if threatened then
      if not S.captureAt then S.captureAt=now;say('Enemy vehicles are on Sparrow! Extract immediately!') end
      if now-S.captureAt>=20 then fail('Enemy patrol captured Sparrow.');return nil end
    else S.captureAt=nil end
    if S.huntAt and now-S.huntAt>=1500 then fail('Rescue window expired.');return nil end
    if range<=400 and not u:inAir() and speed(u)<1 then
      if not S.pickupAt then
        S.pickupAt=now
        S.pickupDuration=20+math.ceil(math.max(0,range-100)/3)
        say(string.format('Sparrow: moving to your helicopter. Hold position for about %d seconds for approach and boarding.',S.pickupDuration),25)
      end
      if now-S.pickupAt>=S.pickupDuration then
        S.boarded=true;S.phase='return';pilot:destroy();trigger.action.setUserFlag(901,1)
        trigger.action.removeMark(8101)
        if S.regionDrawn then pcall(trigger.action.removeMark,8103) end
        say('Sparrow aboard! '..havenNavigation(u)..' Land within 100 m of the pad and hold 15 seconds for medical handover.',40)
      end
    else
      if S.pickupAt then say('Boarding interrupted. Land and hold still beside Sparrow.') end
      S.pickupAt=nil
      S.pickupDuration=nil
    end
  elseif distance(pos,home)<=100 and not u:inAir() and speed(u)<1 then
    if not S.homeAt then S.homeAt=now;say('Medical team receiving Sparrow. Hold for 15 seconds.') end
    if now-S.homeAt>=15 then
      S.phase='complete';trigger.action.setUserFlag(902,1)
      say('MISSION SUCCESS. Sparrow is safely recovered. Good work, Anvil and Guardian!',45)
      return nil
    end
  else S.homeAt=nil end
  return now+2
end
local function initialize()
  pickup=randomPickup()
  home=ground(-1802.8537883092722,1000) -- Fixed pad: must match cockpit WP4 exactly.
  -- Build the receiving FARP at the fixed WP4 landing point; never relocate it.
  assert(coalition.addStaticObject(2,{
    name='FARP LANTERN',unitId=200,type='SINGLE_HELIPAD',shape_name='FARP',category='Heliports',
    x=home.x,y=home.z,heading=0,dead=false,
    heliport_frequency=127.5,heliport_modulation=0,heliport_callsign_id=1
  }),'Could not create FARP LANTERN')
  local medicalSite=findClear(home.x+140,home.z+80,200,true)
  assert(coalition.addStaticObject(2,{
    name='LANTERN MEDICAL TENT',type='FARP Tent',category='Fortifications',
    x=medicalSite.x,y=medicalSite.z,heading=0,dead=false
  }),'Could not create LANTERN medical tent')
  spawnGround('MEDICAL SUPPORT',findClear(home.x-140,home.z+80,200,true))
  for _,site in ipairs({{'HAVEN',ground(19948.236328125,6806.8149414062)},{'LANTERN',home}}) do
    local ok,err=pcall(serviceFarp,site[1],site[2])
    if not ok then
      env.error('[GREEN_LANTERN] Logistics placement issue: '..tostring(err))
      say(site[1]..' logistics setup incomplete; some ground services may be unavailable.')
    end
  end
  spawnGround('SURVIVOR',pickup)
  -- Patrols are placed relative to the chosen site. They are threats, not the
  -- objective: a site with no nearby vehicle ground must not abort the rescue.
  S.northPatrol=spawnExtra('HUNTER-NORTH',pickup.x+2700,pickup.z+1000,false,1000)
  S.eastPatrol=spawnExtra('HUNTER-EAST',pickup.x-1000,pickup.z+3000,false,1000)
  S.checkpoint=spawnExtra('CHECKPOINT',pickup.x-3000,pickup.z+6000,false)
  S.phase='ingress';S.pickup=pickup;S.home=home
  S.crashSites=crashSites;S.searchCenter=searchCenter;S.regionRadius=regionRadius
  env.info(string.format('[GREEN_LANTERN] LANTERN landing point x=%.3f z=%.3f',home.x,home.z))
  trigger.action.markToCoalition(8101,'SPARROW SEARCH REGION - within 2.5 km of WP3; Rescue > Contact Sparrow gives a rough fix; green smoke within 2 km of him',ground(searchCenter.x,searchCenter.z),2,true)
  if trigger.action.circleToAll then
    S.regionDrawn=pcall(trigger.action.circleToAll,2,8103,ground(searchCenter.x,searchCenter.z),regionRadius,{0,1,0,0.8},{0,1,0,0.08},2,true)
  end
  trigger.action.markToCoalition(8102,'FARP LANTERN - medical handover / WP4 landing pad / land within 100 m, hold 15 s / ATC 127.500 AM',home,2,true)
  local rescueMenu=missionCommands.addSubMenuForCoalition(2,'Rescue')
  local airMenu=missionCommands.addSubMenuForCoalition(2,'Air Support')
  local owMenu=missionCommands.addSubMenuForCoalition(2,'Overwatch')
  missionCommands.addCommandForCoalition(2,'Engage vehicles near me',owMenu,owRequest)
  missionCommands.addCommandForCoalition(2,'Hold fire / resume overwatch',owMenu,owCancel)
  missionCommands.addCommandForCoalition(2,'Return to HAVEN',owMenu,owReturn)
  missionCommands.addCommandForCoalition(2,'Status / return directions',rescueMenu,status)
  missionCommands.addCommandForCoalition(2,'Contact Sparrow (direction fix)',rescueMenu,contactSparrow)
  missionCommands.addCommandForCoalition(2,'Request survivor smoke (green)',rescueMenu,requestPilotSmoke)
  missionCommands.addCommandForCoalition(2,'Launch carrier package',airMenu,launchGuardian)
  missionCommands.addCommandForCoalition(2,'Request CAS near me',airMenu,requestCAS)
  missionCommands.addCommandForCoalition(2,'Request radar suppression',airMenu,requestSEAD)
  missionCommands.addCommandForCoalition(2,'Hold fire / cancel CAS',airMenu,holdCAS)
  say('Anvil: WP3 is the centre of Sparrow\'s 2.5 km search region, not his position. Use F10 Rescue > Contact Sparrow for a rough direction fix, then request GREEN smoke within 2 km of him. After pickup, deliver him to LANTERN, WP4 landing pad. Overlord 251 AM; F10 can launch the air package earlier.',30)
  timer.scheduleFunction(function(_,now)
    local ok,nextTime=pcall(tick,nil,now)
    if not ok then env.error('[GREEN_LANTERN] '..tostring(nextTime));fail('Mission script error; see dcs.log.');return nil end
    return nextTime
  end,nil,timer.getTime()+2)
  timer.scheduleFunction(function(_,now)
    local ok,result=pcall(owTick,nil,now)
    if not ok then
      S.owDisabled=true;pcall(owCancel)
      env.info('[GREEN_LANTERN] Optional overwatch disabled: '..tostring(result))
      say('Longbow tasking unavailable; rescue continues.')
      return nil
    end
    return result
  end,nil,timer.getTime()+2)
end
timer.scheduleFunction(function()
  local ok,err=pcall(initialize)
  if not ok then env.error('[GREEN_LANTERN] '..tostring(err));fail('Setup could not find a safe site or spawn a group; see dcs.log.') end
end,nil,timer.getTime()+2)
