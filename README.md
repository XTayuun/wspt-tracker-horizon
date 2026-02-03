# wspt-tracker-horizon
Tracks weapon skill points accumulation for trial weapons, latent effect weapons, or melee kills for DRK unlock


# WSPTracker (Ashita v4)

A lightweight Weapon Skill Point and Killing Blow tracker designed specifically for HorizonXI. 

## Features
- **Auto-Installation**: Automatically creates necessary configuration files on first load.
- **Trial Tracking**: Monitors Weapon Skill points, including skillchain bonuses (Lv.1: 2pts, Lv.2: 3pts, Lv.3: 5pts).
- **DRK Unlock Mode**: Dedicated mode for the "Blade of Darkness" quest that tracks only standard melee killing blows.
- **On-Screen Display**: A clean ImGui window with a progress bar and status alerts.
- **Preset System**: Quick-load targets for various weapons (Destroyer, Mythic, etc.).

## Installation
1. Download the `WSPTracker` folder to your `Ashita/addons/` directory.
2. Log into Final Fantasy XI.
3. Type `/addon load wsptracker`.

## Commands
| Command | Description |
| :--- | :--- |
| `/wspt trial` | Switches to standard WS Trial mode (300 pt target). |
| `/wspt break` | Switches to standard weapon break (ex. Destroyers) mode (500 pt target). |
| `/wspt drk` | Switches to DRK Unlock mode (100 melee kills target). |
| `/wspt <preset>` | Loads a custom target from `presets.json` (e.g., `/wspt destroyer`). |
| `/wspt target <num>` | Manually sets a custom point target. |
| `/wspt set <num>` | Manually sets your current point progress. |
| `/wspt reset` | Resets current progress to 0. |

## Customization
You can add your own custom weapon targets by editing the `presets.json` file located in:  
`Ashita 4/config/addons/WSPTracker/presets.json`
