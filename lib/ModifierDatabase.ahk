; ======================================================================================================================
; Modifier list for the Strategy Info window
;
;   ModifierList()               -> [[name, code, full name], ...] all 12 modifiers, in display order (6 per row);
;                                   "name" is the icon file name, "full name" is what the hover tooltip shows
;   ModifierBonus(code)          -> reward bonus in % of one modifier (Bro 30, Hea 30, Spe 25, Fly/Fog/Inf/Qua 20, Com/Exp/Hid/Lim 10, Gla 5)
;   ModifierBonusFromCodes(codes)-> total bonus of a list of modifier codes: they add up, but Glass, Exploding, Limitation,
;                                   Committed, Speedy and Flying together are capped at +50%
;   ModifierCapReached(codes)    -> true when those six would have given more than the cap
;   ModifierIconPath(name, gray) -> Resources/Images/ModifierIcons/<Name>.png (or <Name>_Gray.png when gray = true and
;                                   that file exists), or "" when the icon has not been added yet
;
; A strat's modifiers= line holds the short codes (Gla, Hid, Exp, ...); NormalizeModifierToken() in Main.ahk turns
; whatever is written there into one of the codes below.
; ======================================================================================================================

ModifierList() {
    static list := [
        ["Glass", "Gla", "Glass"], ["Hidden", "Hid", "Hidden Enemies"], ["Exploding", "Exp", "Exploding Enemies"], ["Limitation", "Lim", "Limitation Makes Creativity"], ["Committed", "Com", "Committed"], ["Flying", "Fly", "Flying Enemies"],
        ["Fog", "Fog", "Fog"], ["Quarantine", "Qua", "Quarantine"], ["Inflation", "Inf", "Inflation"], ["Broke", "Bro", "Broke"], ["Speedy", "Spe", "Speedy Enemies"], ["Healthy", "Hea", "Healthy Enemies"]
    ]
    return list
}

; Reward bonus (in %) each modifier adds in the game. They stack (the strat's bonus is the sum), except that the six
; modifiers listed under ModifierIsCapped share a cap of +50%.
ModifierBonus(code) {
    static bonus := Map("Bro", 30, "Hea", 30, "Spe", 25, "Fly", 20, "Fog", 20, "Inf", 20, "Qua", 20,
                        "Com", 10, "Exp", 10, "Hid", 10, "Lim", 10, "Gla", 5)
    return bonus.Has(code) ? bonus[code] : 0
}

; The most the six capped modifiers can add together, in %.
ModifierCapLimit() {
    return 50
}

; Glass, Exploding, Limitation, Committed, Speedy and Flying: any combination of them gives at most ModifierCapLimit().
ModifierIsCapped(code) {
    static capped := Map("Gla", true, "Exp", true, "Lim", true, "Com", true, "Spe", true, "Fly", true)
    return capped.Has(code)
}

; Total reward bonus (in %) of a list of modifier codes (each code once): the capped six are added up and cut off at
; the cap, and every other modifier is added on top without a cap.
;   Speedy + Flying + Exploding = 25 + 20 + 10 = 55, capped to 50;  with Fog on top: 50 + 20 = 70
ModifierBonusFromCodes(codes) {
    capped := 0, others := 0
    for code in codes {
        if (ModifierIsCapped(code))
            capped += ModifierBonus(code)
        else
            others += ModifierBonus(code)
    }
    return Min(capped, ModifierCapLimit()) + others
}

; True when the capped six together would have added more than the cap (so the cap is cutting something off).
ModifierCapReached(codes) {
    capped := 0
    for code in codes {
        if (ModifierIsCapped(code))
            capped += ModifierBonus(code)
    }
    return capped > ModifierCapLimit()
}

ModifierIconPath(name, gray := false) {
    name := RegExReplace(Trim(name), '[\\/:*?"<>|]', "")
    if (name = "")
        return ""
    base := "Resources/Images/ModifierIcons/" name
    if (gray && FileExist(base "_Gray.png"))
        return base "_Gray.png"
    return FileExist(base ".png") ? base ".png" : ""
}

; ---- Reading a strat's modifiers= line (moved here from Main.ahk) -----------------------------------------------------

; Total reward bonus (in %) of a strat's modifiers= line, e.g. "Hid, Fog" -> 30. Same rule as the Info window's
; "REWARDS +NN%": every known modifier counts once, anything unknown adds nothing, and Glass / Exploding / Limitation /
; Committed / Speedy / Flying together are capped at +50% (see ModifierBonusFromCodes in lib\ModifierDatabase.ahk).
ModifierBonusTotal(raw) {
    seen := Map(), codes := []
    for tok in StrSplit(RegExReplace(raw, "[;|]", ","), ",", " `t") {
        if (tok = "" || StrLower(tok) = "none")
            continue
        code := NormalizeModifierToken(tok)
        if (!seen.Has(code)) {
            seen[code] := true
            codes.Push(code)
        }
    }
    return ModifierBonusFromCodes(codes)
}

NormalizeModifierToken(token) {
    tok := Trim(token)
    if (tok = "")
        return ""
    tokLower := StrLower(tok)

    static modMap := [
        { code: "Gla", prefix: "gl", name: "glass" },
        { code: "Hid", prefix: "hi", name: "hidden" },
        { code: "Exp", prefix: "ex", name: "exploding" },
        { code: "Lim", prefix: "li", name: "limitation" },
        { code: "Com", prefix: "co", name: "committed" },
        { code: "Fly", prefix: "fl", name: "flying" },
        { code: "Fog", prefix: "fo", name: "fog",        aliases: ["foggy"] },
        { code: "Qua", prefix: "qu", name: "quarantine", aliases: ["arm", "armored"] },
        { code: "Inf", prefix: "in", name: "inflation",  aliases: ["reg", "regeneration"] },
        { code: "Bro", prefix: "br", name: "broke",      aliases: ["slo", "slow"] },
        { code: "Spe", prefix: "sp", name: "speedy" },
        { code: "Hea", prefix: "he", name: "healthy",    aliases: ["str", "strong"] }
    ]

    for item in modMap {
        if (tokLower = StrLower(item.code)
            || tokLower = item.prefix
            || tokLower = item.name
            || (StrLen(tokLower) >= 2 && SubStr(tokLower, 1, 2) = item.prefix)
            || InStr(item.name, tokLower) = 1) {
            return item.code
        }
        if (item.HasProp("aliases")) {
            for alias in item.aliases {
                if (tokLower = alias || (StrLen(tokLower) >= 3 && InStr(alias, tokLower) = 1))
                    return item.code
            }
        }
    }

    if (StrLen(tok) >= 3)
        return StrUpper(SubStr(tok, 1, 1)) . StrLower(SubStr(tok, 2, 2))
    return tok
}
