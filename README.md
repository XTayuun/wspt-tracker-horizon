# WSPTracker (Ashita v4)

A lightweight Weapon Skill Point and Killing Blow tracker designed specifically for HorizonXI. 

## Features
- **Auto-Installation**: Automatically creates necessary configuration files on first load.
- **Trial Tracking**: Monitors Weapon Skill points, including skillchain bonuses (Lv.1: 2pts, Lv.2: 3pts, Lv.3: 5pts).
- **DRK Unlock Mode**: Dedicated mode for the "Blade of Darkness" quest that tracks only standard melee killing blows.
- **On-Screen Display**: A clean ImGui window with a progress bar and status alerts.
- **Preset System**: Quick-load targets for various weapons using custom commands.

## Default Presets
The following presets are automatically generated and can be called using `/wspt <name>`:

| Preset Name | Target Value | Typical Use Case |
| :--- | :--- | :--- |
| `trial` | 300 | Standard Latent/Trial Weapons |
| `break` | 500 | "Break" weapons (formerly Destroyer) |
| `relic` | 100 | Relic Weapon stages |
| `mythic` | 250 | Mythic Weapon stages |
| `empyrean` | 1500 | Empyrean Weapon stages |
| `magian` | 400 | Specific Magian Trials |

## Commands
| Command | Description |
| :--- | :--- |
| `/wspt trial` | Switches to standard WS Trial mode (300 pt target). |
| `/wspt drk` | Switches to DRK Unlock mode (100 melee kills target). |
| `/wspt <preset>` | Loads a custom target (e.g., `/wspt break` for 500 pts). |
| `/wspt target <num>` | Manually sets a custom point target. |
| `/wspt set <num>` | Manually sets your current point progress. |
| `/wspt reset` | Resets current progress to 0. |

## Customization
You can add your own custom weapon targets by editing the `presets.json` file located in:  
`Ashita 4/config/addons/WSPTracker/presets.json`.
