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
- Strategies are stored in the `Strategies` folder next to `Main.ahk` and shown as cards. Each card has five icon plates with their value underneath: **game mode**, **map** (picture and difficulty rating), **coins**, **gems** and **unit EXP**. Hover a plate to see its name. Special modes (Badlands II, Pizza Party, Polluted Wasteland II) come with their own map.
- The strategy that is **currently loaded** (the last one you pressed **Load** on, or the one strategy rotation has swapped to) has a soft slate-blue border and a slightly blue background. Before anything is loaded, the strategy in slot 1 is highlighted.
- **Add** imports a `.strat` file, **Open folder** browses the library and **Refresh** reloads it. Strategies you record appear alongside imported ones (saved in `%AppData%\Unlimited_Macro\Recordings`).
- On each card, the **up / down arrows** move it in the list (the order is saved), the **pencil** opens the `.strat` file (right-click it to change the program) and the **trash can** deletes the strategy.
- **Info window** – Press **Info** on a card to see the required towers (hover a square for the tower's name) and the strategy's modifiers. Press **Edit** (it becomes **Cancel** while editing) to change the title, author, description and modifiers, click a modifier to turn it on (colour icon on a lighter square) or off (grayscale icon on a darker square), then press **Save changes**. The `.strat` file and the card update immediately; **Cancel** discards your changes.
- **Rewards** – The card works out the coins, gems and EXP of a winning strategy from its game mode, map and modifiers, and updates live when you change the modifiers. See [Rewards](#rewards).

### Rewards
The library calculates the rewards of a **winning** strategy for you.

**coins and gems = the game mode's set reward × the map's difficulty scaling × (1 + the modifiers' bonus)**

**unit EXP = the game mode's set reward × (1 + the modifiers' bonus)** (the map's difficulty never changes unit EXP)

| Game mode | Coins | Gems | EXP |
|---|---|---|---|
| Easy | 300 | | 25 |
| Casual | 450 | | 50 |
| Intermediate | 600 | | 75 |
| Molten | 950 | | 120 |
| Fallen | 1,350 | | 185 |
| Frost | 2,000 | 45 | 195 |
| Hardcore | | 400 | 350 |
| Voidcore | 1,000 | 700 | 420 |

| Map difficulty | Scaling (coins and gems only) |
|---|---|
| Very Easy | 0.5× |
| Easy | 0.85× |
| Normal | 1× |
| Hard | 1.25× |
| Insane | 1.5× |

Each modifier adds a percentage, and the bonuses of all active modifiers add up (the Info window shows the total as **REWARDS +NN%**).

| Modifier | Bonus | Modifier | Bonus |
|---|---|---|---|
| Broke | +30% | Flying | +20% |
| Healthy | +30% | Fog | +20% |
| Speedy | +25% | Inflation | +20% |
| Quarantine | +20% | Committed, Exploding, Hidden, Limitation | +10% |
| Glass | +5% | | |

The modifiers are **added together first** (+30% and +10% make 1.4×, not 1.3 × 1.1), and that total is then **multiplied** with the map scaling. For example, an Insane map (1.5×) with +30% modifiers pays 1.5 × 1.3 = 1.95× the game mode's set coins and gems, but unit EXP only gets the 1.3×. Hard and Insane maps only pay their bonus for a win, which is why only win strategies are calculated. All of these numbers live in `lib\RewardDatabase.ahk` and `lib\ModifierDatabase.ahk`; change them there if the game changes.

**Special game modes** pay fixed rewards. Map difficulty and modifiers never change them:

| Game mode | Coins | Gems | EXP |
|---|---|---|---|
| Pizza Party | 1,150 | | 215 |
| Badlands II | 1,400 | | 185 |
| Polluted Wasteland II | 1,450 | 125 | 215 |

**Win or lose.** The rewards above are only for wins, so every strategy says which it is with `result=win` or `result=lose` in its `[Info]` section (no `result` line means `win`; saving a recording asks you).

- **Win strategy:** the rewards are always calculated. `coins`, `gems` and `exp` in the `[Info]` section are ignored, so there is nothing to type in.
- **Lose strategy:** nothing is calculated. Type the rewards the strategy actually earned into the `[Info]` section (they already include whatever the game paid for that map) and they are shown exactly as written.
- Game modes without a reward table here (the Night events) also show the typed rewards.

**On the card.** When map scaling or modifiers change a number, the game mode's set reward is shown small and grey with a red streak through it, and the new number sits under it in the normal colour. For example, a Voidcore win on a Normal map with Hidden (+10%) shows `1000` struck through and `1100` under it. Hover a plate to see which scaling was applied. Saving modifiers in the Info window updates the card instantly; no Refresh is needed. The `.strat` file is never changed by any of this.

**Failsafes.** Special game modes cannot use modifiers: the Info window refuses to turn them on (it shows **REWARDS FIXED**) and removes any that are in the file when you save, and the Record tab clears and locks the modifier list when you pick a special mode. On a lose strategy the Info window shows **REWARDS NO BONUS**.

**Icon sizes.** The coin and gem icon is chosen from the amount:

| | Small | Medium | Large | Largest |
|---|---|---|---|---|
| Coins | 1–499 | 500–1,499 | 1,500–2,999 | 3,000+ |
| Gems | 1–99 | 100–299 | 300–599 | 600+ |

Unit EXP always uses the same icon. The ranges are `RewardTiers` in `lib\RewardDatabase.ahk`.

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
- **Debug Console** – The log overlay at the bottom right of the screen shows only the newest lines, and each line fades away after 10 seconds. Change that with `OverlayLifetime` (seconds, `0` = never fade) under `[Options]` in the settings file, or untick **Debug Console** in the Settings tab to hide the overlay completely. Saving changes in the strategy Info window is written to the audit log only and never appears on screen.
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
result=win
time=~6m 7s

[Settings]
map=Dead ahead
difficulty=Molten
requiredTowers=Demoman, DJ, Hacker, Shotgunner, Juggernaut
modifiers=Hidden, Fog
```

A strategy that loses carries its own rewards instead:

```ini
[Info]
result=lose
coins=120
gems=0
exp=15
```

### `[Info]` keys

All keys are optional. Leave a value empty or omit the key if it is unknown; the strategy still loads normally.

> **Important: the rewards in a `.strat` file are never boosted.** On a **win** strategy the macro calculates the rewards itself ([Rewards](#rewards)) and ignores `coins`, `gems` and `exp`. On a **lose** strategy, write the rewards the strategy actually earns; they are shown as written and no bonus is ever added to them. Never write numbers that already include a map or modifier bonus.

| Key | Description |
|---|---|
| `title`, `author`, `desc` | Descriptive text shown on the card. |
| `result` | `win` or `lose` (also accepts `loss`, `lost`, `defeat`). Decides whether the rewards are calculated (win, the default) or typed in (lose). |
| `coins`, `gems` | **Lose strategies only.** An amount, a tier (`small`, `medium`, `large`, `largest`), or both in any order (e.g. `1425, large`). The amount is displayed under the icon and the tier selects the icon; the tier name itself is never shown. With only an amount, the tier is chosen automatically (see [Icon sizes](#rewards)). Ignored on win strategies. |
| `exp` | **Lose strategies only.** Unit EXP, as a number. Ignored on win strategies. |
| `time` | Free text shown on the card. |

Library card display of typed rewards (lose strategies and the Night events):

- `coins` / `gems` with an amount show that amount. Empty or missing values show a greyed-out `0`.
- `coins` / `gems` with only a tier (e.g. `large`) show the tier's icon with `?`, because the amount is unknown.
- `exp` left blank or missing shows `?`; an explicit `0` shows a greyed-out `0`.

### `[Settings]` keys

| Key | Description |
|---|---|
| `map` | Map to play. Its difficulty rating scales the rewards of a win (not for the special game modes). |
| `difficulty` | Game mode: Easy, Casual, Intermediate, Molten, Fallen, Frost, Hardcore, Voidcore, or the special modes Pizza Party, Badlands II and Polluted Wasteland II. Use `Night3` or `Night4` for Night events (`N4` is still accepted). The Easy or Hard variant is selected from the strategy. |
| `requiredTowers` | Comma-separated towers to equip before joining. |
| `modifiers` | The strategy's modifiers, comma-separated, by name or short code (e.g. `Hidden, Fog` or `Hid, Fog`). Normally edited from the Info window. They add a reward bonus on wins. Not allowed in the special game modes (they are ignored and removed when you save). |

### Library icons

Icons are loaded from `Resources\Images`:

- Difficulty: `<difficulty>.png` (e.g. `Molten.png`, `Night4.png`)
- Rewards: `coins_<size>.png` and `gems_<size>.png`; unit EXP always uses `exp.png`
- Empty state: `coins_none.png` and `gems_none.png`
- Clock next to the run time: `clock.png`
- Maps: `MapIcons\<Map Name>.png`
- Towers: `TowerIcons\<Tower Name>.png`
- Modifiers: `ModifierIcons\<Modifier>.png`, plus `<Modifier>_Gray.png` for the off state

Maps, towers and modifiers are listed in `lib\MapDatabase.ahk`, `lib\TowerDatabase.ahk` and `lib\ModifierDatabase.ahk`. To add a map or tower, add a line to its list there; a missing icon file shows the initials of the map or tower (or the short code of a modifier) instead.

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
