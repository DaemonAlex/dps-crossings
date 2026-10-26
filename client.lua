-- Roxwood level crossings.
--
-- Why this exists: the crossings are real vanilla props sitting in the Roxwood
-- map (masts with arms, overheads, trackside signals), but nothing drives them.
-- The base game only animates crossings that belong to its own tracks, and the
-- Roxwood lines are ours, so every crossing sits dead while trains cut through
-- traffic. This arms them from the train's real position.
--
-- No constant scanning: an ox_lib point per crossing wakes a tick only while a
-- player is near that crossing, and the tick sleeps again when they leave.

local trafficLightRed <const> = 2
local trafficLightNormal <const> = 3  -- hand the light back to the game

local state = {}     -- [index] = { armed = bool, props = {entity...} }
local debug = Config.debug

---Every train currently streamed on this client.
---Vehicle class 21 is Rail, which covers locomotives and carriages alike.
---@return table
local function nearbyTrains()
    local out = {}
    local pool = GetGamePool('CVehicle')
    for i = 1, #pool do
        local veh = pool[i]
        if DoesEntityExist(veh) and GetVehicleClass(veh) == 21 then
            out[#out + 1] = veh
        end
    end
    return out
end

---Find the crossing's real props once, by model, near each marked position.
---The map owns these objects, so we look them up instead of spawning our own -
---a spawned copy would sit inside the real one.
---@param crossing table
---@return table
local function findProps(crossing)
    local found, seen = {}, {}
    for i = 1, #crossing.props do
        local p = crossing.props[i]
        for _, model in ipairs(Config.maskModels) do
            local obj = GetClosestObjectOfType(p.x, p.y, p.z, Config.propSearchNear, model, false, false, false)
            if obj ~= 0 and DoesEntityExist(obj) and not seen[obj] then
                seen[obj] = true
                found[#found + 1] = obj
            end
        end
        for _, model in ipairs(Config.signalModels) do
            local obj = GetClosestObjectOfType(p.x, p.y, p.z, Config.propSearchNear, model, false, false, false)
            if obj ~= 0 and DoesEntityExist(obj) and not seen[obj] then
                seen[obj] = true
                found[#found + 1] = obj
            end
        end
    end
    return found
end

---Has every prop we expect at this crossing been found, and is each still valid?
---
---Scanning once was the first bug: the watch radius is 250m and props only
---stream in around 100m, so the first scan found nothing, cached that, and the
---crossing stayed dead forever. Damon caught it at Roxwood East, where one mast
---never dropped. So we keep rescanning until the count matches, and revalidate
---every tick because entities die when the player drives out of range.
---@param crossing table
---@param s table
---@return boolean
local function propsReady(crossing, s)
    if #s.props < #crossing.props then return false end
    for i = 1, #s.props do
        if not DoesEntityExist(s.props[i]) then return false end
    end
    return true
end

-- Forward declaration: setCrossing() below calls releaseTraffic(), which is
-- defined further down the file. Without this the call resolved to a nil
-- global and threw at every disarm.
local releaseTraffic

---@param crossing table
---@param s table
---@param arm boolean
local function setCrossing(crossing, s, arm, force)
    -- force exists because the test commands must re-apply even when the state
    -- already says armed: after a rescan the prop list can be different objects,
    -- and an early return left those new ones untouched.
    if s.armed == arm and not force then return end
    s.armed = arm

    for i = 1, #s.props do
        local obj = s.props[i]
        if DoesEntityExist(obj) then
            -- Crossing masts are traffic-light objects to the game, so this is
            -- what a driver's AI actually reads. Whether it also drops the arm
            -- is the open question - /xarm at a crossing answers it.
            if debug then print(('[crossings] %s light %s on prop %d model %d'):format(crossing.name, arm and 'RED' or 'normal', obj, GetEntityModel(obj))) end
            SetEntityTrafficlightOverride(obj, arm and trafficLightRed or trafficLightNormal)
        end
    end

    if crossing.road and not arm then
        releaseTraffic(crossing)
    end

    if crossing.road and Config.toggleRoads then
        local c = crossing.centre
        -- Switching the road off was meant to keep NEW traffic from turning
        -- onto the crossing. What it actually does is strip the road nodes from
        -- every AI car already inside the 80 m box, and a car with no nodes
        -- stops where it is - including on the rails, in front of the train
        -- (Roxwood East, 2026-09-23, twice). Off by default; the per-car brake
        -- in holdTraffic() is what holds traffic and it does not need this.
        if debug then print(('[crossings] %s roads %s'):format(crossing.name, arm and 'OFF' or 'on')) end
        SetRoadsInArea(c.x - 40.0, c.y - 40.0, c.z - 15.0, c.x + 40.0, c.y + 40.0, c.z + 15.0, not arm, false)
    end

    if debug then
        print(('[crossings] %s %s (%d props)'):format(crossing.name, arm and 'ARMED' or 'cleared', #s.props))
    end
end

---Physically hold AI traffic at an armed crossing.
---
---The traffic-light override is what a crossing SHOULD need, but Damon watched
---cars drive straight over an armed crossing at Roxwood East, so the lights are
---not enough on their own here. Braking the drivers directly is: it works
---whatever the mast does, and it leaves the player's own car alone.
---@param crossing table
local function holdTraffic(crossing)
    local c = crossing.centre
    local pool = GetGamePool('CVehicle')
    local held = 0
    for i = 1, #pool do
        local veh = pool[i]
        if DoesEntityExist(veh) and veh ~= cache.vehicle and GetVehicleClass(veh) ~= 21 then
            local d = #(GetEntityCoords(veh) - c)
            -- A car that is already ON the crossing must be let through, not
            -- braked where it stands: braking it parks it on the rails and
            -- the train hits it and stops dead (Roxwood East, 2026-09-23,
            -- train culled at node 163). Only cars still approaching are held.
            if d < Config.holdClearRadius then
                SetVehicleHandbrake(veh, false)
            elseif d < Config.holdRadius then
                local driver = GetPedInVehicleSeat(veh, -1)
                if driver ~= 0 and not IsPedAPlayer(driver) then
                    -- Temp action 1 is a plain brake-and-hold. The first
                    -- attempt used 6, which is brake-and-reverse - not what a
                    -- car waiting at a crossing should do. Re-issued every tick
                    -- so it lasts while armed and releases the moment we stop.
                    if debug then print(('[crossings] %s hold veh %d model %d driver %d'):format(crossing.name, veh, GetEntityModel(veh), driver)) end
                    TaskVehicleTempAction(driver, veh, 1, 1500)
                    SetVehicleHandbrake(veh, true)
                    held = held + 1
                end
            end
        end
    end
    return held
end

---Let traffic go again: the handbrake has to be taken back off by hand, or the
---cars sit there after the train has gone.
---@param crossing table
function releaseTraffic(crossing)
    local c = crossing.centre
    local pool = GetGamePool('CVehicle')
    for i = 1, #pool do
        local veh = pool[i]
        if DoesEntityExist(veh) and GetVehicleClass(veh) ~= 21 then
            if #(GetEntityCoords(veh) - c) < Config.holdRadius * 1.5 then
                if debug then print(('[crossings] %s release veh %d model %d'):format(crossing.name, veh, GetEntityModel(veh))) end
                SetVehicleHandbrake(veh, false)
            end
        end
    end
end

---One crossing's tick. Runs only while a player is inside its watch radius.
---@param index number
local function tick(index)
    local crossing = Config.crossings[index]
    local s = state[index]
    if not s then return end

    -- lib.points calls `nearby` every frame. Walking the vehicle pool that often
    -- would be the sort of constant scanning we avoid, so the work is throttled;
    -- a quarter second is far finer than a train covers ground.
    local now = GetGameTimer()
    if s.nextTick and now < s.nextTick then return end
    s.nextTick = now + Config.tickInterval

    -- Keep looking until every marked prop has been matched to a real object,
    -- then re-check them: a rescan is cheap next to a crossing that never arms.
    if not propsReady(crossing, s) then
        local before = #s.props
        s.props = findProps(crossing)
        if debug and #s.props ~= before then
            print(('[crossings] %s found %d of %d props'):format(crossing.name, #s.props, #crossing.props))
        end
        -- Props that streamed in after the crossing armed still need the light.
        if s.armed then
            for i = 1, #s.props do
                if DoesEntityExist(s.props[i]) then
                    if debug then print(('[crossings] %s late light on prop %d model %d'):format(crossing.name, s.props[i], GetEntityModel(s.props[i]))) end
                    SetEntityTrafficlightOverride(s.props[i], trafficLightRed)
                end
            end
        end
    end

    local nearest, nearestDist = nil, math.huge
    local trains = nearbyTrains()
    for i = 1, #trains do
        local d = #(GetEntityCoords(trains[i]) - crossing.centre)
        if d < nearestDist then nearest, nearestDist = trains[i], d end
    end

    -- A forced arm (/xarm) holds until /xclear. Without this the very next tick
    -- saw no train nearby and disarmed it a quarter second later, which is why
    -- the test looked like nothing happened at all.
    if not s.forced then
        if not nearest then
            setCrossing(crossing, s, false)
            return
        end

        if nearestDist <= Config.armDistance then
            setCrossing(crossing, s, true)
        elseif nearestDist >= Config.clearDistance and s.armed and nearestDist > Config.armDistance then
            setCrossing(crossing, s, false)
        end
    end

    if s.armed and crossing.road then
        local held = holdTraffic(crossing)
        if debug and held > 0 then
            print(('[crossings] %s holding %d vehicles'):format(crossing.name, held))
        end
    end

    -- The floating marker is its own switch: the console trace can stay on
    -- for a crash hunt without a blob hanging in the air over every crossing.
    if debug and Config.debugMarkers then
        DrawMarker(28, crossing.centre.x, crossing.centre.y, crossing.centre.z + 3.0, 0, 0, 0, 0, 0, 0,
            1.0, 1.0, 1.0, s.armed and 255 or 60, s.armed and 60 or 200, 60, 120, false, false, 0, false)
    end
end

CreateThread(function()
    for index, crossing in ipairs(Config.crossings) do
        state[index] = { armed = false, props = {} }

        lib.points.new({
            coords = crossing.centre,
            distance = Config.watchRadius,
            onEnter = function()
                if debug then print(('[crossings] watching %s'):format(crossing.name)) end
            end,
            onExit = function()
                local s = state[index]
                if s and s.armed then setCrossing(crossing, s, false) end
            end,
            nearby = function()
                tick(index)
            end,
        })
    end
    print(('[crossings] %d crossings loaded'):format(#Config.crossings))
end)

-- Everything below is for working out, in game, which lever actually moves the
-- arm. Remove once that is settled.

local function nearestCrossing()
    local me = GetEntityCoords(cache.ped)
    local best, bestIndex, bestDist = nil, nil, math.huge
    for index, crossing in ipairs(Config.crossings) do
        local d = #(me - crossing.centre)
        if d < bestDist then best, bestIndex, bestDist = crossing, index, d end
    end
    return best, bestIndex, bestDist
end

RegisterCommand('xcross', function()
    debug = not debug
    print(('[crossings] debug %s'):format(debug and 'on' or 'off'))
end, false)

RegisterCommand('xprops', function()
    local crossing, index, dist = nearestCrossing()
    if not crossing then return end
    local s = state[index]
    s.props = findProps(crossing)
    print(('[crossings] %s is %.0fm away, %d props:'):format(crossing.name, dist, #s.props))
    for i = 1, #s.props do
        local obj = s.props[i]
        local name = GetEntityArchetypeName and GetEntityArchetypeName(obj) or tostring(GetEntityModel(obj))
        local c = GetEntityCoords(obj)
        print(('   %s  handle %d  at %.2f, %.2f, %.2f'):format(name, obj, c.x, c.y, c.z))
    end
end, false)

RegisterCommand('xarm', function()
    local crossing, index = nearestCrossing()
    if not crossing then return end
    state[index].forced = true
    setCrossing(crossing, state[index], true, true)
    print(('[crossings] forced %s ARMED - arms, lights, and traffic should hold'):format(crossing.name))
end, false)

RegisterCommand('xclear', function()
    local crossing, index = nearestCrossing()
    if not crossing then return end
    state[index].forced = nil
    setCrossing(crossing, state[index], false, true)
    print(('[crossings] forced %s cleared'):format(crossing.name))
end, false)

-- /xstate <0-3> : put every prop at this crossing into one traffic light state.
-- Nothing visible happened at Roxwood East with state 2 (red) - not even the
-- lights - so this walks the other values to find out whether these masts
-- respond to the light system at all.
RegisterCommand('xstate', function(_, args)
    local value = tonumber(args[1])
    if not value then
        print('[crossings] usage: /xstate 0|1|2|3   (3 hands the light back to the game)')
        return
    end
    local crossing, index = nearestCrossing()
    if not crossing then return end
    local s = state[index]
    if not propsReady(crossing, s) then s.props = findProps(crossing) end
    for i = 1, #s.props do
        if DoesEntityExist(s.props[i]) then
            SetEntityTrafficlightOverride(s.props[i], value)
        end
    end
    print(('[crossings] set light state %d on %d props at %s - anything change?'):format(value, #s.props, crossing.name))
end, false)

-- Try an animation on the crossing's props: /xanim <dict> <clip>
-- Some vanilla props carry their own animation rather than reacting to the
-- traffic light. If /xarm reds the lights but leaves the arm up, this is how we
-- find the animation that drops it.
RegisterCommand('xanim', function(_, args)
    local dict, clip = args[1], args[2]
    if not dict or not clip then
        print('[crossings] usage: /xanim <dict> <clip>')
        return
    end
    RequestAnimDict(dict)
    local waited = 0
    while not HasAnimDictLoaded(dict) and waited < 2000 do Wait(50) waited = waited + 50 end
    if not HasAnimDictLoaded(dict) then
        print(('[crossings] anim dict %s never loaded - wrong name?'):format(dict))
        return
    end
    local crossing, index = nearestCrossing()
    local s = state[index]
    if not propsReady(crossing, s) then s.props = findProps(crossing) end
    for i = 1, #s.props do
        PlayEntityAnim(s.props[i], clip, dict, 1000.0, false, true, false, 0.0, 0)
    end
    print(('[crossings] played %s / %s on %d props at %s'):format(dict, clip, #s.props, crossing.name))
end, false)
