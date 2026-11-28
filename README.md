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
The library calculates the rewards of a strategy for you, for wins and for losses.

**coins = the game mode's set reward × the map's difficulty scaling × (1 + the modifiers' bonus)**

**gems and unit EXP = the game mode's set reward × (1 + the modifiers' bonus)**

The map's difficulty only scales **coins**. It never changes gems (Frost, Hardcore and Voidcore) or unit EXP, and Voidcore's coins are not scaled by the map either.

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

| Map difficulty | Scaling (coins only) |
|---|---|
| Very Easy | 0.5× |
| Easy | 0.85× |
| Normal | 1× |
| Hard | 1.25× |
| Insane | 1.5× |

Each modifier adds a percentage, and the bonuses of all active modifiers add up (the Info window shows the total as **REWARDS +NN%**), with one limit described below the table.

| Modifier | Bonus | Modifier | Bonus |
|---|---|---|---|
| Broke | +30% | Flying | +20% |
| Healthy | +30% | Fog | +20% |
| Speedy | +25% | Inflation | +20% |
| Quarantine | +20% | Committed, Exploding, Hidden, Limitation | +10% |
| Glass | +5% | | |

**Cap:** Glass, Exploding, Limitation, Committed, Speedy and Flying together can add at most **+50%**. For example, Speedy + Flying + Exploding is 25 + 20 + 10 = 55%, which counts as 50%. The other six modifiers (Broke, Healthy, Fog, Inflation, Quarantine and Hidden) have no cap and add on top, so Speedy + Flying + Exploding + Fog is 50% + 20% = 70%. The most all twelve modifiers can add is +180%. The Info window shows **(CAP)** next to the total when the cap is cutting something off.

The modifiers are **added together first** (+30% and +10% make 1.4×, not 1.3 × 1.1), and that total is then **multiplied** with the map scaling. For example, an Insane map (1.5×) with +30% modifiers pays 1.5 × 1.3 = 1.95× the game mode's set coins, but gems and unit EXP only get the 1.3×. Hard and Insane maps only pay their bonus for a win, which is why only win strategies are calculated. All of these numbers live in `lib\RewardDatabase.ahk` and `lib\ModifierDatabase.ahk`; change them there if the game changes.

**Special game modes** pay fixed rewards. Map difficulty and modifiers never change them:

| Game mode | Coins | Gems | EXP |
|---|---|---|---|
| Pizza Party | 1,150 | | 215 |
| Badlands II | 1,400 | | 185 |
| Polluted Wasteland II | 1,450 | 125 | 215 |

**Win or lose.** Every strategy says which it is with `result=win` or `result=lose` in its `[Info]` section (no `result` line means `win`; saving a recording asks you).

- **Win strategy:** the totals above, scaled by the map and the modifiers. Nothing is typed in.
- **Lose strategy:** add `wave=` (the wave the strategy reaches before it loses) to the `[Info]` section and the rewards are calculated from that wave. Do not type rewards. Saving a recording that loses asks you for the wave.
- A game mode that has no formulas yet shows `?` for its rewards. Add its formulas to `ModeFormulas` in `lib\RewardDatabase.ahk`.

Every reward of a game mode follows one formula, and the **triumph bonus** is only paid for a win:

**reward at a wave = A ÷ (1 + (W ÷ wave − 1) ^ p)**, plus the **triumph bonus B** on a win

`A` is the reward at the last wave, `W` is the wave the formula ends at (a wave past `W` counts as `W`), and `p` is how steeply it grows. Unit EXP always has `p = 1`, so it grows in a straight line with the wave. At the last wave the wave part is exactly `A`, so a win pays `A + B`, which is the totals table above. Reaching wave 12 of a 25-wave Casual game, for example, pays `400 ÷ (1 + (25 ÷ 12 − 1) ^ 1.3)` = 189.6, which is **189 coins**, and 9.6, which is **9 EXP**.

**Rounding.** Every amount is rounded **down** to a whole number, as the game does. Hardcore at wave 30, for example, works out to 137.8 gems, and the game pays 137. This is `RewardRound` in `lib\RewardDatabase.ahk` (change `Floor` to `Round` there to round to the nearest number instead).

| Game mode | Coins `A`, `W`, `p`, `B` | Gems `A`, `W`, `p`, `B` | Unit EXP `A`, `W`, `B` |
|---|---|---|---|
| Casual | 400, 25, 1.3, +50 | | 20, 25, +30 |
| Easy | 250, 20, 1.3, +50 | | 10, 25, +15 |
| Intermediate | 500, 30, 1.3, +100 | | 35, 25, +40 |
| Molten | 550, 35, 2.4, +400 | | 55, 35, +65 |
| Fallen | 700, 40, 2.4, +650 | | 85, 40, +100 |
| Frost | 800, 40, 2.4, +1,200 | +45 (win only) | 85, 40, +110 |
| Hardcore | | 150, 45, 3.5, +250 | 160, 45, +190 |
| Voidcore | +1,000 (win only) | 250, 50, 3, +450 | 190, 50, +230 |
| Pizza Party | 450, 40, 3, +700 | | 95, 40, +120 |
| Badlands II | 550, 30, 3, +850 | | 85, 30, +100 |
| Polluted Wasteland II | 500, 25, 3, +950 | +125 (win only) | 95, 25, +120 |

Rewards marked "win only" pay nothing on a loss. On a loss, only the Very Easy (0.5×) and Easy (0.85×) map reductions apply, and only to coins; the Hard and Insane bonuses are for a triumph only, modifiers only count on wins, and the special game modes are never scaled. A losing strategy with no `wave=` line shows `?` for its rewards.

**On the card.** When map scaling or modifiers change a number, the original reward is shown small and grey with a red streak through it, and the new number sits under it in the normal colour. For example, a Voidcore win on a Normal map with Hidden (+10%) shows `1000` struck through and `1100` under it. Hover a plate to see which scaling was applied. Saving modifiers in the Info window updates the card instantly; no Refresh is needed. The `.strat` file is never changed by any of this.

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

A strategy that loses says which wave it reaches, and its rewards are calculated from that:

```ini
[Info]
result=lose
wave=12
```

### `[Info]` keys

All keys are optional. Leave a value empty or omit the key if it is unknown; the strategy still loads normally.

> **Important: do not type rewards into a `.strat` file.** The macro calculates them itself ([Rewards](#rewards)): a win from the game mode, map and modifiers, and a loss from its `wave=` line. Any `coins`, `gems` or `exp` lines in a file are ignored. Never write numbers that already include a map or modifier bonus; the bonus would be counted twice.

| Key | Description |
|---|---|
| `title`, `author`, `desc` | Descriptive text shown on the card. |
| `result` | `win` or `lose` (also accepts `loss`, `lost`, `defeat`). A win pays the full rewards; a loss pays what the wave it reaches is worth. Defaults to `win`. |
| `wave` | **Lose strategies only.** The wave the strategy reaches before it loses, as a whole number (for example `30`). The rewards of the loss are calculated from it. Ignored on win strategies. |
| `time` | Free text shown on the card. |

### `[Settings]` keys

| Key | Description |
|---|---|
| `map` | Map to play. Its difficulty rating scales the rewards of a win (not for the special game modes). |
| `difficulty` | Game mode: Easy, Casual, Intermediate, Molten, Fallen, Frost, Hardcore, Voidcore, or the special modes Pizza Party, Badlands II and Polluted Wasteland II. |
| `requiredTowers` | Comma-separated towers to equip before joining. |
| `modifiers` | The strategy's modifiers, comma-separated, by name or short code (e.g. `Hidden, Fog` or `Hid, Fog`). Normally edited from the Info window. They add a reward bonus on wins. Not allowed in the special game modes (they are ignored and removed when you save). |

### Library icons

Icons are loaded from `Resources\Images`:

- Difficulty: `<difficulty>.png` (e.g. `Molten.png`, `Frost.png`)
- Rewards: `coins_<size>.png` and `gems_<size>.png`; unit EXP always uses `exp.png`
- Empty state: `coins_none.png` and `gems_none.png`
- Clock next to the run time: `clock.png`
- Maps: `MapIcons\<Map Name>.png`
- Towers: `TowerIcons\<Tower Name>.png`
- Modifiers: `ModifierIcons\<Modifier>.png`, plus `<Modifier>_Gray.png` for the off state

Maps, towers and modifiers are listed in `lib\MapDatabase.ahk`, `lib\TowerDatabase.ahk` and `lib\ModifierDatabase.ahk`. To add a map or tower, add a line to its list there; a missing icon file shows the initials of the map or tower (or the short code of a modifier) instead.

---

## Project Layout

| Path | What it holds |
|---|---|
| `Main.ahk` | Start-up only: settings, the main window and its controls, hotkeys, and the `#Include` lines for everything below. |
| `src\` | The program's functions, one module per job (table below). |
| `lib\` | Libraries and data tables: Gdip, OCR, JSON, image search, and the map, tower, modifier and reward databases. |
| `submacros\` | Separate scripts that run alongside the macro: the watchdog and the tool macros. |
| `Strategies\` | Your `.strat` files. |
| `Resources\` | Images used for image search and the UI. |

| Module (`src\`) | Job |
|---|---|
| `Util.ahk` | Small helpers: lists, formatting, screen scaling, key names. |
| `Vision.ahk` | Image search and reading text on screen (OCR). |
| `Gfx.ahk` | Drawing helpers for the custom UI: gradient buttons, card frames, scroll thumbs, message boxes. |
| `Logging.ahk` | The audit log (file and viewer) and the Debug Console overlay. |
| `Discord.ahk` | The webhook queue, sending messages, and the bot's chat commands. |
| `Process.ahk` | Safe reload, exit handling, the watchdog and sub-macros. |
| `Settings.ahk` | Saving and checking settings, including the Discord / webhook settings and their tests. |
| `Window.ahk` | The main window: tabs, dragging, hover effects, links, help popups, tool launchers. |
| `Library.ahk` | The strategy library: cards, order, Load / Add / Remove, live reward updates. |
| `StratInfo.ahk` | The strategy Info window: view and edit title, author, description and modifiers. |
| `Recording.ahk` | Recording a strategy: its hotkeys, captured inputs and saving the file. |
| `Playback.ahk` | Loading and running strategies: the Strategy 1 / 2 slots, rotation, executing steps. |
| `Towers.ahk` | Tower actions: place, upgrade, sell, clone, targets, abilities, DJ tracks, indicators, special map paths. |
| `Lobby.ahk` | The lobby and the match: Roblox start / stop, joining, parties, ready, restart, reconnect, daily rewards. |

The modules contain **functions only**; nothing runs from them. Code that must run when the macro starts stays in `Main.ahk`. To add a function, put it in the module whose job it matches. To add a module, create the file in `src\` and add one `#Include src\<name>.ahk` line to `Main.ahk`.

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
