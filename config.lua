-- Roxwood level crossings.
--
-- Every position here came from Damon marking the spot in game with F3 on
-- 2026-09-21 (dps-whatobject's capture file). Captures within ~5m of each other
-- were the same prop grabbed twice and have been dropped.
--
-- The props themselves are vanilla: prop_traffic_rail_1a / _1c are the masts
-- whose arm drops, prop_traffic_rail_2 is the overhead, and prop_rail_signals03
-- / _04 are the trackside train signals. We look the objects up by model at
-- runtime rather than spawning our own, so the map keeps owning them.

Config = {}

-- Models we drive. Anything in the traffic_rail family is a road/ped mast or
-- overhead; the rail_signals family is the train's own signal.
Config.maskModels = {
    `prop_traffic_rail_1a`,
    `prop_traffic_rail_1c`,
    `prop_traffic_rail_2`,
}

Config.signalModels = {
    `prop_rail_signals03`,
    `prop_rail_signals04`,
}

-- How close a train has to be before the crossing arms, and how far past before
-- it clears. Metres, measured to the crossing centre.
Config.armDistance   = 180.0
Config.clearDistance = 70.0

-- How far from each marked position to look for that prop. The marks are
-- where Damon stood, not the prop's own origin, so this has slack in it.
Config.propSearchNear = 12.0

-- Only tick while a player is near a crossing; the radius a player has to be
-- inside for that crossing to be watched at all.
Config.watchRadius = 250.0

-- How often a watched crossing does its work, in milliseconds.
Config.tickInterval = 250

-- AI cars within this many metres of an armed road crossing get braked. The
-- lights alone did not stop anyone at Roxwood East, so this is what actually
-- keeps traffic off the rails.
Config.holdRadius = 45.0

-- Inside this many metres of the crossing centre a car is ON the rails and is
-- never braked - it is released so it can clear. Braking it there parked it
-- in front of the train (Roxwood East, 2026-09-23).
Config.holdClearRadius = 9.0

-- Disable the road nodes around an armed crossing? OFF. It strands any AI car
-- already inside the box - it loses its route and stops where it is, rails
-- included - and that is exactly how the train got blocked twice on
-- 2026-09-23. The per-car brake above is what holds traffic.
Config.toggleRoads = false

-- Crossings. `road = false` marks a footpath crossing: the arms and lights
-- still work, but no attempt is made to hold traffic, because there is no road.
Config.crossings = {
    {
        name = 'Roxwood Station',
        centre = vec3(-397.7, 7593.6, 6.4),
        road = true,
        props = {
            vec3(-405.82, 7606.00, 6.48),
            vec3(-381.64, 7577.00, 6.30),
            vec3(-413.00, 7601.34, 6.16),
        },
    },
    {
        name = 'LB Bay West',
        centre = vec3(-61.90, 7708.80, 6.40),
        road = true,
        props = {
            vec3(-61.90, 7708.80, 6.40),
        },
    },
    {
        name = 'LB Bay Footpath 1',
        centre = vec3(-1.44, 7774.82, 6.46),
        road = false,
        props = {
            vec3(-1.44, 7774.82, 6.46),
        },
    },
    {
        name = 'LB Bay Footpath 2',
        centre = vec3(56.28, 7799.28, 6.40),
        road = false,
        props = {
            vec3(56.28, 7799.28, 6.40),
            vec3(109.90, 7779.40, 5.92),
        },
    },
    {
        name = 'Roxwood East',
        centre = vec3(362.3, 7645.9, 4.6),
        road = true,
        props = {
            vec3(332.58, 7669.02, 4.54),
            vec3(392.06, 7622.78, 4.56),
        },
    },
    {
        name = 'Junction Approach',
        centre = vec3(604.0, 7348.0, 4.6),
        road = true,
        props = {
            vec3(594.78, 7346.98, 5.86),
            vec3(613.94, 7348.86, 4.60),
        },
    },
}

-- Debug draws markers on the found props and prints what the arming logic is
-- doing. /xcross toggles it at runtime, this is just the boot default.
Config.debug = false

-- Draw the floating marker over each crossing while debugging? Distracting
-- and unreal in the world (Damon, 2026-09-23); the F8 trace is enough.
Config.debugMarkers = false
