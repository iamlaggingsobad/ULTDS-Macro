# Unlimited Macro

Automation macro for Roblox **Tower Defense Simulator**. Record strategies, replay them, and loop matches hands-free.

> Based on *Ultimate Macro* by Darksen, licensed under GPL-3.0. See [License](#license).

---

## Features

### Automation
- **Record and replay** – Capture tower placements, upgrades, abilities and other actions, then play them back.
- **Smart game handling** – Detects the end of a match, verifies the map, and uses Restart or Play Again to keep looping.
- **Strategy rotation** – Alternate between two strategies after a set number of runs or minutes.
- **Auto-equip towers** – Equips the towers a strategy requires before joining.
- **Timescale support** – Uses 1.5x and 2x Timescale tickets, and stops requesting them once they run out.
- **Playtime rewards** – Collects daily and playtime rewards from the lobby.
- **Night events** – Full Night 3 and Night 4 support, including the "Your Loadout" step.
- **Advanced towers** – Split upgrade paths and special towers such as Hacker and Juggernaut.
- **VIP servers** – Paste a private server link to run in your own server.

### Strategy Library
- Strategies are stored in the `Strategies` folder next to `Main.ahk` and displayed as cards showing game mode, coins, gems and unit EXP.
- **Add** imports a `.strat` file, **Open folder** browses the library, **Refresh** reloads it, and **Remove** deletes a strategy.
- Strategies you record appear alongside imported ones (saved in `%AppData%\Unlimited_Macro\Recordings`).
- **Strategy Modifiers editor** – Toggle modifiers (Glass, Hidden, Exploding, and more) and the `modifiers=` line of the selected strategy is updated automatically. A one-time `.bak` backup is created before the first edit.

### Reward Detection
End-of-match Coins, Gems and EXP are read through a multi-step pipeline whose results are cross-checked:

1. Read-only Roblox memory read (`lib/RobloxMemory.ahk`, configured via `Resources/client_layout.txt`)
2. Adaptive OCR
3. Up to three retries

Detailed output is written to `%AppData%\Unlimited_Macro\Logs\reward_debug.log`.

### Discord Integration
- Webhook logging with screenshots and currency statistics (screenshots capture the primary monitor only).
- Optional bot mode with `!start`, `!stop`, `!status` and `!screenshot` commands.
- Optional @mention on win, on loss, and when Timescale tickets run out.

### Reliability and Logging
- Ready button is clicked at the centre of the detected button.
- Restart detection compares both button images and uses the better match.
- Tower placement and cloning retry automatically and log each attempt.
- **Audit log** – Errors, retries and recoveries are saved to `Logs\audit_log.tsv`. Open it from **Tools → Open Audit Log**.
- **Settings auto-save** – Checkboxes, hotkeys and inputs on the Settings and Discord tabs save in the background. Legacy Mode is applied only through **Save all settings**, since it reloads the macro.

---

## Requirements

| Area | Requirement |
|---|---|
| Operating system | Windows 10 or 11 |
| Runtime | [AutoHotkey v2.0](https://www.autohotkey.com/) (v1.1 is not supported). A 64-bit executable is also included in `submacros`. |
| Resolution | 1920x1080 recommended |
| Display scaling | 100% |
| Language pack | English (US), required for OCR |
| Taskbar | Must be visible (auto-hide disabled) |

**Roblox and TDS settings**

- UI Scale: **Large**
- Screen Shake: **Disabled**
- Prefer Vertical Upgrades: **Enabled**
- No custom fonts
- Roblox in **windowed mode** (not fullscreen)
- Roblox on your **primary monitor**, so webhook screenshots capture the game

---

## Installation

1. Download the `.zip` and extract **all files** to a folder. Do not run the macro from inside the archive.
2. Install AutoHotkey v2.0.
3. Run `Main.ahk`.

---

## Strategy File Format

Strategies are `.strat` files made of an `[Info]` section and a `[Settings]` section.

```ini
[Info]
title=My Strat
author=Your name
desc=Short description
coins=1425, large
gems=0
exp=120
time=~14m 20s

[Settings]
map=Dead ahead
difficulty=Molten
requiredTowers=Demoman, DJ, Hacker, Shotgunner, Juggernaut
```

### `[Info]` keys

All keys are optional. Leave a value empty or omit the key if it is unknown; the strategy still loads normally.

| Key | Description |
|---|---|
| `title`, `author`, `desc` | Descriptive text shown on the card. |
| `coins`, `gems` | An amount, a tier (`small`, `medium`, `large`, `largest`), or both in any order (e.g. `1425, large`). The amount is displayed under the icon and the tier selects the icon. With only an amount, the tier is chosen automatically (see `RewardTiers` in `Main.ahk`). |
| `exp` | Unit EXP, as a number. |
| `time` | Free text shown on the card. |

Missing values appear greyed out with a `-`; an explicit `0` appears greyed out as `0`.

### `[Settings]` keys

| Key | Description |
|---|---|
| `map` | Map to play. |
| `difficulty` | Difficulty name. Use `Night3` or `Night4` for Night events (`N4` is still accepted). The Easy or Hard variant is selected from the strategy. |
| `requiredTowers` | Comma-separated towers to equip before joining. |

### Library icons

Icons are loaded from `Resources\Images`:

- Difficulty: `<difficulty>.png` (e.g. `Molten.png`, `Night4.png`)
- Rewards: `coins_<size>.png` and `gems_<size>.png`; unit EXP always uses `exp.png`
- Empty state: `coins_none.png` and `gems_none.png`

---

## Data and Security

- User data (settings, recordings, logs) is stored in `%AppData%\Unlimited_Macro`.
- Webhook URLs and bot tokens are saved in plain text in that folder. Do not share it.
- In Discord bot mode, anyone who can post in the configured channel can run bot commands. Keep that channel private.

---

## Disclaimer

Automating input in Roblox may violate the game's rules. Use at your own risk.

## License

Released under the GPL-3.0 license. See `LICENSE`. Based on *Ultimate Macro* by Darksen.
