; ======================================================================================================================
; Reward database for the strategy library
;
;   ModeFormulas(mode)           -> the reward formulas of a game mode (see below), or "" when the mode has none
;   ModeRewards(mode)            -> [coins, gems, exp] a WIN pays in that game mode, or "" when the mode has no formulas
;   LossReward(formula, wave)    -> what a formula pays for a LOSS that reaches that wave
;   RatingScalePct(rating)       -> map difficulty scaling in % (Very Easy 50, Easy 85, Normal 100, Hard 125, Insane 150)
;   RewardResult(raw)            -> "win" or "lose" from a strat's [Info] result= line (empty / unknown = "win")
;   RewardWave(raw)              -> the wave from a strat's [Info] wave= line (a number), or "" when missing
;   RewardTiers(kind)            -> icon size ranges for "coins" and "gems"
;   RewardSizeFor(kind, amount)  -> "small" / "medium" / "large" / "largest" for an amount (the icon to draw)
;   ComputeRewards(strat)        -> the coins / gems / exp the library card shows for a strat
;
; HOW REWARDS ARE WORKED OUT (see ComputeRewards)
;   Every reward of a game mode has a formula   A / (1 + (W / wave - 1) ^ p)   plus a triumph bonus B that is only
;   given for a WIN.   A = the reward at the last wave,  W = the wave the formula ends at (a wave past W counts as W),
;   p = how steeply it grows,  B = the triumph bonus.  Unit EXP always has p = 1 (a straight line).
;   At the last wave the wave term is exactly A, so a WIN pays A + B.
;
;   WIN strategy (result=win, or no result= line)
;     every reward = (A + B)  x  map difficulty scaling  x  (1 + modifier bonus)
;     The map only scales COINS. It never changes gems, unit EXP or Voidcore's coins (the fifth number of a formula
;     below is 1 when the map scales that reward). Modifiers change every reward.
;     The modifier bonuses add up, but Glass, Exploding, Limitation, Committed, Speedy and Flying together are
;     capped at +50% (see ModifierBonusFromCodes in lib\ModifierDatabase.ahk).
;   LOSE strategy (result=lose)
;     The wave= line of the strategy (the wave it reaches) goes into the formula, without the triumph bonus:
;       reward = A / (1 + (W / wave - 1) ^ p)  x  map scaling when that scaling is below 1x (map-scaled rewards only)
;     Only the Very Easy (0.5x) and Easy (0.85x) map reductions apply to a loss: the Hard and Insane bonuses are paid
;     for a triumph only, and modifiers only count on wins. With no wave= line the rewards show "?".
;   Special game modes (Pizza Party, Badlands II, Polluted Wasteland II)
;     Map difficulty and modifiers never change their rewards, so both are ignored (wins and losses).
;   Game modes without formulas (the Night events) use the coins= / gems= / exp= lines of the strat's [Info] section.
;
; Amounts are always rounded down to a whole number (RewardRound), as the game does.
;
; The numbers below are the ones to change if the game changes.
; ======================================================================================================================

; The reward formulas of a game mode, as a Map: reward -> [A, W, p, B, mapScaled]  (see the header).
;   A = reward at the last wave, W = wave the formula ends at, p = exponent, B = triumph bonus (win only),
;   mapScaled = 1 when the map's difficulty scales this reward, 0 when it does not. Only coins are scaled: gems, unit EXP,
;   Voidcore's coins and everything in the three special modes are never scaled.
;   A reward that is only given for a win (for example Frost's 45 gems) has A = 0 and only a B.
; Mode names are matched ignoring case.
ModeFormulas(mode) {
    static table := 0
    if (!table) {
        table := Map()
        table.CaseSense := "Off"
        table["Casual"]       := Map("coins", [400, 25, 1.3, 50, 1],  "exp", [20, 25, 1, 30, 0])
        table["Easy"]         := Map("coins", [250, 20, 1.3, 50, 1],  "exp", [10, 25, 1, 15, 0])
        table["Intermediate"] := Map("coins", [500, 30, 1.3, 100, 1], "exp", [35, 25, 1, 40, 0])
        table["Molten"]       := Map("coins", [550, 35, 2.4, 400, 1], "exp", [55, 35, 1, 65, 0])
        table["Fallen"]       := Map("coins", [700, 40, 2.4, 650, 1], "exp", [85, 40, 1, 100, 0])
        table["Frost"]        := Map("coins", [800, 40, 2.4, 1200, 1], "gems", [0, 1, 1, 45, 0], "exp", [85, 40, 1, 110, 0])
        table["Hardcore"]     := Map("gems", [150, 45, 3.5, 250, 0],  "exp", [160, 45, 1, 190, 0])
        table["Voidcore"]     := Map("coins", [0, 1, 1, 1000, 0], "gems", [250, 50, 3, 450, 0], "exp", [190, 50, 1, 230, 0])
        ; special game modes: never scaled by the map or the modifiers
        table["Pizza Party"]           := Map("coins", [450, 40, 3, 700, 0],  "exp", [95, 40, 1, 120, 0])
        table["Badlands II"]           := Map("coins", [550, 30, 3, 850, 0],  "exp", [85, 30, 1, 100, 0])
        table["Polluted Wasteland II"] := Map("coins", [500, 25, 3, 950, 0],  "gems", [0, 1, 1, 125, 0], "exp", [95, 25, 1, 120, 0])
    }
    return table.Has(mode) ? table[mode] : ""
}

; What a WIN pays: [coins, gems, exp] = A + B of every formula (a win is always at the last wave).
ModeRewards(mode) {
    formulas := ModeFormulas(mode)
    if (!IsObject(formulas))
        return ""
    totals := []
    for kind in ["coins", "gems", "exp"]
        totals.Push(formulas.Has(kind) ? formulas[kind][1] + formulas[kind][4] : 0)
    return totals
}

; What a LOSS pays: formula = [A, W, p, B] reached at `wave`. The triumph bonus B is not paid. The wave is kept
; between 1 and W (a wave past W counts as W, which also keeps the power below from going negative).
LossReward(formula, wave) {
    if (formula[1] <= 0)
        return 0
    w := Max(1, Min(wave, formula[2]))
    return formula[1] / (1 + (formula[2] / w - 1) ** formula[3])
}

; The wave from a strat's [Info] wave= line: a whole number, or "" when it is missing or not a number.
RewardWave(raw) {
    v := Trim(raw)
    return RegExMatch(v, "^\d{1,3}$") ? Integer(v) : ""
}

; Map difficulty rating -> reward scaling in percent (50 = 0.5x). Unknown ratings do not scale.
; Hard and Insane maps only pay their bonus for a WIN; that is why only win strategies are calculated at all.
RatingScalePct(rating) {
    static scale := Map("Very Easy", 50, "Easy", 85, "Normal", 100, "Hard", 125, "Insane", 150)
    return scale.Has(rating) ? scale[rating] : 100
}

; Every reward amount is rounded DOWN to a whole number, like the game does: Hardcore at wave 30 works out to 137.8 gems
; and the game pays 137. (The tiny 0.000001 only stops a value that should be exactly a whole number, such as 12, from
; being cut to 11 by floating-point noise.) To round to the nearest number instead, change Floor to Round here.
RewardRound(value) {
    return Floor(value + 0.000001)
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
; .result .wave and the typed .coins .gems .exp). Returns
;   {win, special, computed, scalePct, bonus, wave, coins: R, gems: R, exp: R}      (scalePct = the map's scaling; each R.scale is what was applied)
; with R = {orig, amount, size, text, active, changed, scale}
;   orig    the reward before map scaling and modifiers (a win: A + B; a loss: the formula at the strat's wave)
;           (not called "base": that name is reserved on every AutoHotkey v2 object)
;   amount  the reward after map scaling and modifier bonus
;   size    icon size for coins / gems ("" for exp or when there is none)
;   text    what is printed under the icon ("?" when it is not known)
;   active  true = coloured, false = grey (nothing earned)
;   changed true when amount differs from orig (the card then shows both numbers)
;   scale   the map scaling in % that was applied to this reward (100 when the map does not scale it)
ComputeRewards(strat) {
    modeName := strat.difficulty != "" ? strat.difficulty : "Easy"
    special := SpecialModeName(modeName)
    formulas := ModeFormulas(special != "" ? special : modeName)
    wave := HasProp(strat, "wave") ? strat.wave : ""
    out := {win: strat.result != "lose", special: special != "", computed: false, scalePct: 100, bonus: 0, wave: wave}

    ; modes without formulas (the Night events): the typed rewards, exactly as written
    if (!IsObject(formulas)) {
        for kind in ["coins", "gems", "exp"] {
            t := strat.%kind%
            out.%kind% := {orig: t.amount, amount: t.amount, size: t.size, text: t.text, active: t.active, changed: false, scale: 100}
        }
        return out
    }

    out.computed := true
    if (!out.special) {                   ; special modes: no map scaling and no modifiers
        info := strat.map != "" ? GetMapInfo(strat.map) : ""
        if (info)
            out.scalePct := RatingScalePct(info.rating)
        if (out.win)
            out.bonus := ModifierBonusTotal(strat.modifiers)
        else
            out.scalePct := Min(out.scalePct, 100)    ; a loss only gets the Very Easy / Easy reductions
    }

    for i, kind in ["coins", "gems", "exp"] {
        formula := formulas.Has(kind) ? formulas[kind] : ""
        ; the map only scales the rewards flagged for it (coins, but not Voidcore's coins); gems and unit EXP never
        scale := (IsObject(formula) && formula[5]) ? out.scalePct : 100

        if (out.win) {
            orig := IsObject(formula) ? formula[1] + formula[4] : 0
            amount := orig > 0 ? RewardRound(orig * RewardMultiplier(scale, out.bonus) / 10000) : 0
        } else if (wave = "") {
            out.%kind% := {orig: "", amount: "", size: "", text: "?", active: false, changed: false, scale: 100}
            continue                      ; a losing strategy needs its wave= line
        } else {
            raw := IsObject(formula) ? LossReward(formula, wave) : 0
            orig := RewardRound(raw)
            amount := RewardRound(raw * scale / 100)
        }
        size := (kind != "exp" && amount > 0) ? RewardSizeFor(kind, amount) : ""
        out.%kind% := {orig: orig, amount: amount, size: size, text: String(amount), active: amount > 0, changed: amount != orig, scale: scale}
    }
    return out
}
