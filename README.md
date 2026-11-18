# Ultimate Macro (TDS) - Personal Fork

An automation macro for Roblox **Tower Defense Simulator**: record strategies, replay them, and loop matches hands-free.

> Based on *Ultimate Macro* by Darksen, released under the GPL-3.0 license (see `LICENSE`).
> This is an unofficial personal-use fork with the changes listed below.

## Features

* **Record & Play Custom Strategies** - Record tower placements, upgrades, abilities and actions, then replay them.
* **Strategy Library** - Your strategies live in the `Strategies` folder and show up as cards with difficulty, reward and info icons.
* **Smart Game Handling** - Detects the end of a match, checks the map, and uses Restart or Play Again to loop.
* **Strategy Rotation** - Swap between two strategies after a set number of runs or minutes.
* **Auto-Equip Towers** - Equips the towers your strategy needs before joining.
* **Timescale Support** - 1.5x and 2x Timescale tickets.
* **Playtime Rewards** - Collects daily and playtime rewards from the lobby.
* **Night Event Support** - Night 3 and Night 4, including the "Your Loadout" step.
* **Discord Webhook** - Logs, screenshots and currency stats sent to your server.
* **Multiple Upgrade Paths** - Split-path towers and special towers (Hacker, Juggernaut and others).
* **VIP Server Support** - Paste a private server link to run in your own server.

## What's different in this fork

* **Strategies folder** - Put `.strat` files in `Strategies` next to `Main.ahk`. In the Main tab use **Add** to import a file, **Open folder** to browse it, **Refresh** to reload, and **Remove** on a card to delete a strat. Strategies you record are listed too (saved in `%AppData%\Ultimate_Macro\Recordings`).
* **Reward icons** - Add `coins=` and/or `gems=` to a strat's `[Info]` section. Valid values: `small`, `medium`, `large`, `largest`. If a currency is empty or missing, its icon is greyed out.
* **Night 4** - Use `difficulty=Night4` in strat files (the old `N4` value still works).
* **Loadout failsafe** - The "Your Loadout" button is clicked, checked, and retried. If Ready still isn't found, the loadout step runs once more before the macro reloads.
* **Primary-monitor screenshots** - Webhook screenshots capture only your main monitor, not every screen.
* **Images folder** - Library icons are in `Resources\Images`.
* **Credits tab removed.**

## Strategy file format

```ini
[Info]
title=My Strat
author=Your name
desc=Short description
income=~4000 coins/h, ~120 gems/h
coins=small
gems=small
time=20 minutes

[Settings]
map=Dead ahead
difficulty=Molten
requiredTowers=Demoman, DJ, Hacker, Shotgunner, Juggernaut
```

Library icons are loaded from `Resources\Images`:

* Difficulty icon: `<difficulty>.png` (for example `Molten.png`, `Night4.png`).
* Reward icons: `coins_<size>.png` and `gems_<size>.png`.
* Greyed-out icons: `coins_none.png` and `gems_none.png`.

## Requirements

* **Windows** 10/11
* **AutoHotkey v2.0** from [autohotkey.com](https://www.autohotkey.com/) (v1.1 will not work). A copy of the 64-bit executable is also in `submacros`.
* **Windows settings:**
  * Recommended resolution: **1920x1080**
  * Display scaling: **100%**
  * The **English (US)** language pack must be installed for text recognition (OCR).
* **Roblox & TDS settings:**
  * UI Scale: **Large**
  * Screen Shake: **Disabled**
  * Prefer Vertical Upgrades: **Enabled**
  * No custom fonts
* Run Roblox on your **primary monitor** so webhook screenshots show the game.

## Installation

1. Download the `.zip` and extract **all files** to a folder (don't run it from inside the zip).
2. Install AutoHotkey v2.0.
3. Run `Main.ahk`.

## Notes

* Your webhook URL and bot token are saved in plain text under `%AppData%\Ultimate_Macro`. Don't share that folder.
* In Discord bot mode, anyone who can post in the configured channel can use `!start`, `!stop`, `!status` and `!screenshot`. Keep that channel private.
* Automating input in Roblox may be against the rules of the game. Use it at your own risk.

## License

GPL-3.0. See `LICENSE`.
