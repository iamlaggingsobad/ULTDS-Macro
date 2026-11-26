; ======================================================================================================================
; Reward database for the strategy library
;
;   ModeRewards(mode)            -> [coins, gems, exp] a WIN pays in that game mode, or "" when the mode has no table
;   RatingScalePct(rating)       -> map difficulty scaling in % (Very Easy 50, Easy 85, Normal 100, Hard 125, Insane 150)
;   RewardResult(raw)            -> "win" or "lose" from a strat's [Info] result= line (empty / unknown = "win")
;   RewardTiers(kind)            -> icon size ranges for "coins" and "gems"
;   RewardSizeFor(kind, amount)  -> "small" / "medium" / "large" / "largest" for an amount (the icon to draw)
;   ComputeRewards(strat)        -> the coins / gems / exp the library card shows for a strat
;
; HOW REWARDS ARE WORKED OUT (see ComputeRewards)
;   WIN strategy (result=win, or no result= line)
;     coins and gems = the game mode's set reward  x  map difficulty scaling  x  (1 + modifier bonus)
;     unit EXP       = the game mode's set reward  x  (1 + modifier bonus)      (map difficulty never changes EXP)
;     The coins= / gems= / exp= lines in the strat's [Info] section are IGNORED: they cannot be typed in.
;   LOSE strategy (result=lose)
;     The rewards written in the strat's [Info] section are shown exactly as typed. Map scaling and modifier
;     bonuses are never applied, because they only apply to wins.
;   Special game modes (Pizza Party, Badlands II, Polluted Wasteland II)
;     Their rewards are fixed. Map difficulty and modifiers can never change them, so both are ignored.
;   Game modes without a table here (the Night events) use the typed rewards, like a lose strategy.
;
; The numbers below are the ones to change if the game changes.
; ======================================================================================================================

; Rewards of a WIN per game mode: [coins, gems, exp]. Mode names are matched ignoring case.
ModeRewards(mode) {
    static table := 0
    if (!table) {
        table := Map()
        table.CaseSense := "Off"
        table["Easy"]         := [300, 0, 25]
        table["Casual"]       := [450, 0, 50]
        table["Intermediate"] := [600, 0, 75]
        table["Molten"]       := [950, 0, 120]
        table["Fallen"]       := [1350, 0, 185]
        table["Frost"]        := [2000, 45, 195]
        table["Hardcore"]     := [0, 400, 350]
        table["Voidcore"]     := [1000, 700, 420]
        ; special game modes: fixed rewards (no map or modifier scaling)
        table["Pizza Party"]           := [1150, 0, 215]
        table["Badlands II"]           := [1400, 0, 185]
        table["Polluted Wasteland II"] := [1450, 125, 215]
    }
    return table.Has(mode) ? table[mode] : ""
}

; Map difficulty rating -> reward scaling in percent (50 = 0.5x). Unknown ratings do not scale.
; Hard and Insane maps only pay their bonus for a WIN; that is why only win strategies are calculated at all.
RatingScalePct(rating) {
    static scale := Map("Very Easy", 50, "Easy", 85, "Normal", 100, "Hard", 125, "Insane", 150)
    return scale.Has(rating) ? scale[rating] : 100
}

; Total multiplier as a number out of 10000 (10000 = 1.0x), so the maths stays in whole numbers.
;   1. the bonuses of all active modifiers are ADDED together first:  +30% and +10% = 1 + 0.30 + 0.10 = 1.4x
;   2. that total is MULTIPLIED with the map scaling (coins and gems only; for unit EXP the map scaling is 100%):
;                                                                     Insane map (1.5x) with +30% = 1.5 x 1.3 = 1.95x
RewardMultiplier(scalePct, bonusPct) {
    return scalePct * (100 + bonusPct)
}

; "win" unless the strat says it loses. Accepts lose / loss / lost / defeat (any case).
RewardResult(raw) {
    v := StrLower(Trim(raw))
    return (v = "lose" || v = "loss" || v = "lost" || v = "defeat") ? "lose" : "win"
}

; Icon size ranges, smallest to largest, as [name, minimum amount]. They pick the coin / gem icon for an amount
; (a computed reward, or a typed amount that comes without a tier name). Chosen around the rewards the game pays:
;   coins  small 1-499 | medium 500-1,499 | large 1,500-2,999 | largest 3,000+
;          (Easy / Casual = small, Intermediate to Fallen, Voidcore and the special modes = medium,
;           Frost = large, Frost on an Insane map or with modifiers = largest)
;   gems   small 1-99 | medium 100-299 | large 300-599 | largest 600+
;          (Frost 45 = small, Polluted Wasteland 125 = medium, Hardcore 400 = large, Voidcore 700 = largest)
; Unit EXP has no tiers: it always uses the same icon.
RewardTiers(kind) {
    static tiers := Map(
        "coins", [["small", 0], ["medium", 500], ["large", 1500], ["largest", 3000]],
        "gems",  [["small", 0], ["medium", 100], ["large", 300],  ["largest", 600]]
    )
    return tiers.Has(kind) ? tiers[kind] : []
}

RewardSizeFor(kind, amount) {
    tiers := RewardTiers(kind)
    if (tiers.Length = 0 || amount = "" || amount <= 0)
        return ""
    size := tiers[1][1]
    for t in tiers {
        if (amount >= t[2])
            size := t[1]
    }
    return size
}

; The rewards the library card shows for a strat (a record from the library loader, with .difficulty .map .modifiers
; .result and the typed .coins .gems .exp). Returns
;   {win, special, computed, scalePct, bonus, coins: R, gems: R, exp: R}      (scalePct applies to coins and gems only)
; with R = {orig, amount, size, text, active, changed}
;   orig    the game mode's set reward (or the typed amount when nothing is calculated)
;           (not called "base": that name is reserved on every AutoHotkey v2 object)
;   amount  the reward after map scaling and modifier bonus
;   size    icon size for coins / gems ("" for exp or when there is none)
;   text    what is printed under the icon
;   active  true = coloured, false = grey (nothing earned)
;   changed true when amount differs from orig (the card then shows both numbers)
ComputeRewards(strat) {
    modeName := strat.difficulty != "" ? strat.difficulty : "Easy"
    special := SpecialModeName(modeName)
    table := ModeRewards(special != "" ? special : modeName)
    out := {win: strat.result != "lose", special: special != "", computed: false, scalePct: 100, bonus: 0}

    ; lose strategies and modes without a table: the typed rewards, exactly as written, with no scaling
    if (!out.win || !IsObject(table)) {
        for kind in ["coins", "gems", "exp"] {
            t := strat.%kind%
            out.%kind% := {orig: t.amount, amount: t.amount, size: t.size, text: t.text, active: t.active, changed: false}
        }
        return out
    }

    out.computed := true
    if (!out.special) {                   ; special modes: fixed rewards, no map scaling and no modifiers
        info := strat.map != "" ? GetMapInfo(strat.map) : ""
        if (info)
            out.scalePct := RatingScalePct(info.rating)
        out.bonus := ModifierBonusTotal(strat.modifiers)
    }
    for i, kind in ["coins", "gems", "exp"] {
        orig := table[i]
        ; map difficulty scales coins and gems only; unit EXP is changed by the modifiers alone
        mult := RewardMultiplier(kind = "exp" ? 100 : out.scalePct, out.bonus)
        amount := orig > 0 ? Round(orig * mult / 10000) : 0
        size := (kind != "exp" && amount > 0) ? RewardSizeFor(kind, amount) : ""
        out.%kind% := {orig: orig, amount: amount, size: size, text: String(amount), active: amount > 0, changed: amount != orig}
    }
    return out
}
