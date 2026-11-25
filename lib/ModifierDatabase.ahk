; ======================================================================================================================
; Modifier list for the Strategy Info window
;
;   ModifierList()               -> [[name, code, full name], ...] all 12 modifiers, in display order (6 per row);
;                                   "name" is the icon file name, "full name" is what the hover tooltip shows
;   ModifierBonus(code)          -> reward bonus in % of one modifier (Bro 30, Hea 30, Spe 25, Fly/Fog/Inf/Qua 20, Com/Exp/Hid/Lim 10, Gla 5)
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

; Reward bonus (in %) each modifier adds in the game. They all stack, so the strat's bonus is the sum.
ModifierBonus(code) {
    static bonus := Map("Bro", 30, "Hea", 30, "Spe", 25, "Fly", 20, "Fog", 20, "Inf", 20, "Qua", 20,
                        "Com", 10, "Exp", 10, "Hid", 10, "Lim", 10, "Gla", 5)
    return bonus.Has(code) ? bonus[code] : 0
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
