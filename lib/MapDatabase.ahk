; ======================================================================================================================
; Map database + library colours
;
;   GetMapInfo(name)      -> {name, rating, color} for a map, or "" if the map is not in the database
;   ModeColorHex(mode)    -> RRGGBB background colour for a game mode badge (Fallen, Molten, ...)
;   ContrastTextHex(rgb)  -> "141414" or "FFFFFF", whichever reads better on that background
;   ShadeHex(rgb, f)      -> 0xFFRRGGBB darkened by factor f (used for the gradient bottom)
;   BadgeColors(rgb)      -> [top, bottom] light-to-dark gradient colours for a badge with white text
;
; To add a map, add a "Name|Rating" line to the list below. Ratings: Very Easy, Easy, Normal, Hard, Insane.
; Names are matched ignoring case, spaces and punctuation ("dead ahead" = "Dead Ahead" = "DeadAhead").
; ======================================================================================================================

MapDB() {
    static db := 0
    if (db)
        return db
    db := Map()
    raw := "
(
Abandoned City|Easy
Abyssal Trench|Hard
Autumn Falling|Easy
Black Spot Exchange|Insane
Candy Valley|Hard
Cataclysm|Hard
Chess Board|Normal
Construction Crazy|Hard
Coral Deep|Normal
Crossroads|Easy
Crystal Cave|Normal
Cyber City|Normal
Dead Ahead|Insane
Deserted Village|Normal
Dusty Bridges|Hard
Farm Lands|Normal
Forest Camp|Easy
Forgetten Docks|Hard
Four Seasons|Normal
Fungi Island|Easy
Gilded Path|Insane
Grass Isle|Easy
Harbor|Easy
Hot Spot|Insane
Iceville|Normal
Infernal Abyss|Insane
Lay By|Insane
Lighthaos|Normal
Marshlands|Normal
Mason Arch|Insane
Medieval Times|Normal
Meltdown|Normal
Midnight Issue|Normal
Moon Base|Normal
Nether|Normal
Necropolis|Easy
Night Station|Normal
Northern Lights|Easy
Pier Pressure|Normal
Portland|Easy
Retro Crossroads|Easy
Retro Lighthouse|Normal
Retro Rocket Arena|Easy
Retro Stained Temple|Easy
Retro The Heights|Hard
Retro Zone|Hard
Rocket Arena|Easy
Ruby Escort|Normal
Sacred Mountains|Hard
Simplicity|Normal
Sky Islands|Easy
Space City|Insane
Spring Fever|Normal
Stained Temple|Normal
Sugar Rush|Normal
Summer Castle|Very Easy
The Heights|Hard
Toyboard|Easy
Tropical Industries|Normal
Tropical Isles|Easy
U-Turn|Easy
Winter Abyss|Hard
Winter Bridges|Normal
Winter Stronghold|Insane
Wrecked Battlefield|Normal
Wrecked Battlefield II|Normal
Area 52|Normal
Atlas Colosseum|Hard
Derelict Outpost|Insane
Enchanted Forest|Insane
Happy Home of Robloxia|Normal
Honey Valley|Very Easy
Legacy Space City|Insane
Legacy Simplicity|Normal
Legacy Retro Zone|Normal
Musaceae Kingdom|Insane
The Heavens|Normal
Badlands II|Insane
Pizza Party|Insane
Polluted Wasteland II|Insane
Outskirts Commune|Normal
Unknown Garden|Normal
Wretched Front|Easy
)"
    Loop Parse, raw, "`n", "`r" {
        parts := StrSplit(A_LoopField, "|")
        if (parts.Length < 2)
            continue
        db[MapKey(parts[1])] := {name: Trim(parts[1]), rating: Trim(parts[2])}
    }

    ; Other spellings seen in strategy files or in game.
    for alias, real in Map("Black Spot", "Black Spot Exchange", "Forgotten Docks", "Forgetten Docks", "Lighthouse", "Lighthaos", "Wrecked Battlefield 2", "Wrecked Battlefield II", "Badlands 2", "Badlands II", "Polluted Wasteland 2", "Polluted Wasteland II") {
        if (db.Has(MapKey(real)) && !db.Has(MapKey(alias)))
            db[MapKey(alias)] := db[MapKey(real)]
    }
    return db
}

MapKey(name) {
    return StrLower(RegExReplace(name, "[^A-Za-z0-9]", ""))
}

GetMapInfo(name) {
    key := MapKey(name)
    if (key = "")
        return ""
    db := MapDB()
    if !db.Has(key)
        return ""
    info := db[key]
    return {name: info.name, rating: info.rating, color: MapRatingHex(info.rating)}
}

; Difficulty rating -> background colour
MapRatingHex(rating) {
    static colors := Map("Very Easy", "00FF00", "Easy", "32CD32", "Normal", "00FFFF", "Hard", "FF0000", "Insane", "800080")
    return colors.Has(rating) ? colors[rating] : "8A94A6"
}

; Game mode -> badge background colour (modes that are not listed get a neutral grey)
ModeColorHex(mode) {
    static colors := 0
    if (!colors) {
        colors := Map()
        colors.CaseSense := "Off"
        colors["Hardcore"] := "D19FE8"
        colors["Voidcore"] := "D19FE8"
        colors["Frost"] := "C6D8D8"
        colors["Fallen"] := "6C9ED9"
        colors["Easy"] := "7CE800"
        colors["Casual"] := "78C884"
        colors["Intermediate"] := "E88B7E"
        colors["Molten"] := "E59424"
        colors["Badlands II"] := "D08A4A"
        colors["Pizza Party"] := "E5533D"
        colors["Polluted Wasteland II"] := "7FB83A"
    }
    return colors.Has(mode) ? colors[mode] : "8A94A6"
}

; Dark text on light backgrounds, white text on dark ones.
ContrastTextHex(rgb) {
    r := Integer("0x" SubStr(rgb, 1, 2)), g := Integer("0x" SubStr(rgb, 3, 2)), b := Integer("0x" SubStr(rgb, 5, 2))
    return (0.299 * r + 0.587 * g + 0.114 * b) > 125 ? "141414" : "FFFFFF"
}

; "RRGGBB" -> "0xFFRRGGBB" scaled by factor (1 = unchanged, <1 = darker)
ShadeHex(rgb, factor := 1) {
    r := Min(255, Round(Integer("0x" SubStr(rgb, 1, 2)) * factor))
    g := Min(255, Round(Integer("0x" SubStr(rgb, 3, 2)) * factor))
    b := Min(255, Round(Integer("0x" SubStr(rgb, 5, 2)) * factor))
    return Format("0xFF{:02X}{:02X}{:02X}", r, g, b)
}

; Badge text is always white, so very light colours (lime, cyan, frost) are first darkened until white reads well on
; them. The badge then gets the same light-to-dark vertical gradient as the Load / Info / Remove buttons: a slightly
; lifted top and a bottom at about 58% brightness. Returns [gradient top, gradient bottom] as 0xFFRRGGBB.
BadgeColors(rgb, maxLum := 130) {
    r := Integer("0x" SubStr(rgb, 1, 2)), g := Integer("0x" SubStr(rgb, 3, 2)), b := Integer("0x" SubStr(rgb, 5, 2))
    lum := 0.299 * r + 0.587 * g + 0.114 * b
    f := lum > maxLum ? maxLum / lum : 1
    return [ShadeHex(rgb, f * 1.12), ShadeHex(rgb, f * 0.58)]
}

; ----------------------------------------------------------------------------------------------------------------------
; Map icons for the strategy library
;
;   Icons live in Resources\Images\MapIcons\<Map Name>.png (see the README.txt in that folder for the full list).
;   A map without an icon file is shown as a plate with its initials, so nothing breaks while icons are missing.
; ----------------------------------------------------------------------------------------------------------------------

; Special modes own their map: it exists only in that mode, so the mode name and the map name are the same.
; Accepts the usual spellings ("Badlands 2" = "Badlands II"). Returns the proper name, or "" for any other mode.
SpecialModeName(mode) {
    info := GetMapInfo(mode)
    if (info && InStr("|Badlands II|Pizza Party|Polluted Wasteland II|", "|" info.name "|"))
        return info.name
    return ""
}

; Path of a map's icon, or "" when the file has not been added yet.
MapIconPath(name) {
    if (Trim(name) = "")
        return ""
    path := "Resources/Images/MapIcons/" RegExReplace(Trim(name), '[\\/:*?"<>|]', "") ".png"
    return FileExist(path) ? path : ""
}

; "Wrecked Battlefield II" -> "WBI", "U-Turn" -> "UT", "Happy Home of Robloxia" -> "HHR" (at most 3 letters)
MapInitials(name) {
    out := "", pos := 1
    while (pos := RegExMatch(name, "[A-Za-z0-9]+", &m, pos)) {
        pos += StrLen(m[0])
        if (StrLower(m[0]) = "of" || StrLower(m[0]) = "the")
            continue
        out .= StrUpper(SubStr(m[0], 1, 1))
        if (StrLen(out) >= 3)
            break
    }
    return out != "" ? out : "?"
}

; Lightens a colour that is too dark to read as text on the dark card (for example the purple of "Insane").
LiftHex(rgb, minLum := 110) {
    r := Integer("0x" SubStr(rgb, 1, 2)), g := Integer("0x" SubStr(rgb, 3, 2)), b := Integer("0x" SubStr(rgb, 5, 2))
    lum := 0.299 * r + 0.587 * g + 0.114 * b
    if (lum >= minLum)
        return rgb
    t := (minLum - lum) / (255 - lum)
    return Format("{:02X}{:02X}{:02X}", r + Round((255 - r) * t), g + Round((255 - g) * t), b + Round((255 - b) * t))
}
