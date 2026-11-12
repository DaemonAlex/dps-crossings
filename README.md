# dps-crossings

Level crossings for the Roxwood train lines. When a train comes, it turns the crossing signals
red and holds the traffic until the train has passed.

## Status

Not running on DelPerroSands. It was benched on 29 October 2026, and the Roxwood map it was made
for was removed from the server on 31 October 2026. The code is unfinished: holding traffic
works, but the lights and the arms never visibly changed in testing.

## What it is for

The Roxwood map has real crossing masts, arms and signals, but nothing drives them. Trains cut
straight through traffic. This script watches for a train and closes the crossing ahead of it.

## What it does

- **Arms the crossing.** When a train is within 180 m of a crossing, the crossing is armed. It
  clears when the train is 70 m past.
- **Holds traffic.** AI cars coming up to an armed road crossing are braked and held. A car that
  is already on the rails is let through so it does not block the train. Player cars are left
  alone.
- **Sets the lights.** The masts and signals are told to show red. In testing at Roxwood East
  nothing visible changed, and the arms did not drop. The test commands below were made to find
  out why.
- **Stays light.** A crossing is only watched while a player is within 250 m of it.

Six crossings are set up, all on the Roxwood map: Roxwood Station, LB Bay West, two LB Bay
footpaths, Roxwood East and Junction Approach. Footpath crossings get lights only.

## On its own, and with other scripts

**On its own.** It is client-only and needs `ox_lib`. It uses the masts and signals that are
already in the map. It does not spawn any. It reacts to any train the game is showing, so it does
not care which script runs the trains. A player near a crossing sees AI traffic stop for a train
and move off after it.

**With [dps-trains](https://github.com/DaemonAlex/dps-trains).** There is no code link. dps-trains
puts trains on the line and this script sees them like any other train.

## Requirements

- `ox_lib`
- A map with the crossing props at the positions in `config.lua` (the Roxwood map)

## Install

1. Put the folder in your resources and add `ensure dps-crossings` after `ox_lib`.
2. For a different map, replace `Config.crossings` in `config.lua` with your own positions.

## Configuration

`config.lua`:

| Setting | Meaning |
|---|---|
| `Config.crossings` | Each crossing: name, centre, whether it is a road, and where its props stand. |
| `Config.armDistance` / `Config.clearDistance` | How near a train arms the crossing, and how far past it clears. |
| `Config.holdRadius` | AI cars inside this distance of an armed crossing are braked. |
| `Config.holdClearRadius` | Cars this close are on the rails and are let through. |
| `Config.watchRadius` | A crossing is only watched while a player is this near. |
| `Config.toggleRoads` | Switch road nodes off while armed. Leave `false`: it stranded cars on the rails. |
| `Config.debug` | Print what the crossing logic is doing to F8. |

## Commands

These are test commands. Any player can run them, so lock them down before using this on a live
server.

| Command | What it does |
|---|---|
| `/xcross` | Turn debug printing on or off. |
| `/xprops` | List the props found at the nearest crossing. |
| `/xarm` / `/xclear` | Arm or clear the nearest crossing by hand. |
| `/xstate 0-3` | Put the nearest crossing's props into one traffic light state. |
| `/xanim dict clip` | Play an animation on the props, to look for the one that drops the arm. |

## Recent changes

- **12 November 2026.** README: status, what it is for, how it works alone and with paid scripts, other DPS scripts.
- **25 October 2026.** First commit, as it ran on DelPerroSands.
- **23 September 2026.** Cars already on the rails are let through. Switching road nodes off was
  turned off after it blocked the train twice.
- **21 September 2026.** Crossing positions marked in game.

## Author

Made by [DaemonAlex](https://github.com/DaemonAlex) for DelPerroSands.

## Other DPS scripts

All of these are made for DelPerroSands and run together on one Qbox server. Each one works on
its own. The ones marked "pairs with" do more when both are running.

| Script | What it does |
|---|---|
| [dps-inventory](https://github.com/DaemonAlex/dps-inventory) | The inventory: ox_inventory with equipment slots, backpacks, armour plates and a self status panel, in the DelPerroSands colours. |
| [dps-medical](https://github.com/DaemonAlex/dps-medical) | Patient records, illness and diagnostic tests. A companion to wasabi_ambulance. Pairs with dps-inventory: symptoms and diagnoses show on the status panel. |
| [dps-insurance](https://github.com/DaemonAlex/dps-insurance) | Ties m-Insurance into the MDT, impound, hospital and medical chart. Pairs with dps-medical. |
| [dps-studio](https://github.com/DaemonAlex/dps-studio) | Build rooms, doors and portals in game from one panel (`/studio`), with owners and managers so staff do not have to support them. |
| [dps-shops](https://github.com/DaemonAlex/dps-shops) | Shop clerks who greet and react to a robbery, then player-owned shops. |
| [dps-fleet](https://github.com/DaemonAlex/dps-fleet) | Vehicle browser and workshop on one panel: extras, liveries and mods for emergency vehicles. |
| [dps-parking](https://github.com/DaemonAlex/dps-parking) | Parking with valet, impound, violations and reserved spots. |
| [dps-vehiclepersistence](https://github.com/DaemonAlex/dps-vehiclepersistence) | Vehicles stay where they were parked. Pairs with dps-parking. |
| [dps-towjob](https://github.com/DaemonAlex/dps-towjob) | Queue-based tow job with jg-mechanic integration. |
| [dps-services](https://github.com/DaemonAlex/dps-services) | Request a tow and follow it live on the lb-phone and lb-tablet. Pairs with dps-towjob. |
| [dps-autoshops](https://github.com/DaemonAlex/dps-autoshops) | Self-service repair shops when no mechanic is on duty. |
| [dps-cityworker](https://github.com/DaemonAlex/dps-cityworker) | City infrastructure job and career. |
| [dps-ainpcs](https://github.com/DaemonAlex/dps-ainpcs) | NPCs you can talk to, with trust, quests and intel. |
| [dps-badpeds](https://github.com/DaemonAlex/dps-badpeds) | Police interaction with NPCs: stops, arrests, intel and jail records. |
| [dps-gangwars](https://github.com/DaemonAlex/dps-gangwars) | Ambient gang NPCs, territory population and war reinforcements. |
| [dps-rotations](https://github.com/DaemonAlex/dps-rotations) | Moves dealers, harvests and other spots on a fixed schedule. |
| [dps-trains](https://github.com/DaemonAlex/dps-trains) | The train system. Pairs with dps-trains-stock, dps-traintools and dps-transitapp. |
| [dps-transitapp](https://github.com/DaemonAlex/dps-transitapp) | Live train arrival boards on the lb-phone. |
| [dps-faceplant](https://github.com/DaemonAlex/dps-faceplant) | City help, reports and staff tools on the lb-phone and lb-tablet. |
| [dps-chat](https://github.com/DaemonAlex/dps-chat) | A command box for voice-only servers. No chat feed. |
| [dps-filmmode](https://github.com/DaemonAlex/dps-filmmode) | One key hides every HUD layer and gives a smooth free camera for recording. |
