; ======================================================================================================================
; Tower (unit) database for the strategy library and the Strategy Info window
;
;   GetTowerInfo(name)    -> {name, category} for a tower, or "" if it is not in the database
;   TowerDisplayName(name)-> the proper name ("dj" -> "DJ Booth", "G Minigunner" -> "Golden Minigunner");
;                            a name that is not in the database is returned as written
;   TowerColorHex(name)   -> RRGGBB rarity colour for a tower (the square's background); "" if the tower is not in the database
;   TowerIconPath(name)   -> Resources/Images/TowerIcons/<Tower Name>.png, or "" when the file has not been added yet
;   TowerInitials(name)   -> "Crook Boss" -> "CB", "Scout" -> "SC" (shown on a square that has no icon)
;
; Icons live in Resources\Images\TowerIcons\<Tower Name>.png (see the README.txt in that folder for the full list).
; Names are matched ignoring case, spaces and punctuation, and a few short names are accepted as aliases
; (see TowerAliases below), so strat files can say "DJ", "Crook" or "G Minigunner".
; To add a tower, add a "Name|Category" line to the list below.
; ======================================================================================================================

TowerDB() {
    static db := 0
    if (db)
        return db
    db := Map()
    raw := "
(
Scout|Starter
Sniper|Starter
Paintballer|Starter
Demoman|Starter
Boomerang|Starter
Slime Trooper|Starter
Soldier|Starter
Freezer|Intermediate
Assassin|Intermediate
Militant|Intermediate
Shotgunner|Intermediate
Hunter|Intermediate
Pyromancer|Intermediate
Ace Pilot|Intermediate
Medic|Intermediate
Farm|Intermediate
Electroshocker|Intermediate
Rocketeer|Intermediate
Trapper|Intermediate
Pulse Trooper|Intermediate
Military Base|Intermediate
Crook Boss|Intermediate
Commander|Advanced
Warden|Advanced
Cowboy|Advanced
DJ Booth|Advanced
Tesla|Advanced
Saboteur|Advanced
Minigunner|Advanced
Ranger|Advanced
Pursuit|Advanced
Gatling Gun|Advanced
Turret|Advanced
Mortar|Advanced
Mercenary Base|Advanced
Brawler|Hardcore
Necromancer|Hardcore
Accelerator|Hardcore
Engineer|Hardcore
Hacker|Hardcore
Operator|Evolved
Enforcer|Evolved
Kingpin|Evolved
Juggernaut|Evolved
Mecha Base|Evolved
Golden Minigunner|Golden Perk
Golden Pyromancer|Golden Perk
Golden Crook Boss|Golden Perk
Golden Scout|Golden Perk
Golden Cowboy|Golden Perk
Golden Soldier|Golden Perk
Golden Demoman|Golden Perk
Golden Snowballer|Golden Perk
Gladiator|Exclusive
Commando|Exclusive
Slasher|Exclusive
Frost Blaster|Exclusive
Archer|Exclusive
Swarmer|Exclusive
Toxic Gunner|Exclusive
Sledger|Exclusive
Executioner|Exclusive
Elf Camp|Exclusive
Jester|Exclusive
Cryomancer|Exclusive
Hallow Punk|Exclusive
Harvester|Exclusive
Snowballer|Exclusive
Elementalist|Exclusive
Firework Technician|Exclusive
Biologist|Exclusive
Warlock|Exclusive
Spotlight Tech|Exclusive
War Machine|Exclusive
)"
    for line in StrSplit(raw, "`n", "`r") {
        parts := StrSplit(Trim(line), "|")
        if (parts.Length < 2)
            continue
        db[TowerKey(parts[1])] := {name: Trim(parts[1]), category: Trim(parts[2])}
    }
    return db
}

; Short or alternative names strat files may use -> the proper name. Keys are already in TowerKey form.
TowerAliases() {
    static a := Map(
        "dj", "DJ Booth",
        "crook", "Crook Boss",
        "gatling", "Gatling Gun",
        "mecha", "Mecha Base",
        "mercbase", "Mercenary Base",
        "mercenary", "Mercenary Base",
        "fireworktech", "Firework Technician",
        "spotlight", "Spotlight Tech",
        "gminigunner", "Golden Minigunner",
        "gpyromancer", "Golden Pyromancer",
        "gcrookboss", "Golden Crook Boss",
        "gcrook", "Golden Crook Boss",
        "gscout", "Golden Scout",
        "gcowboy", "Golden Cowboy",
        "gsoldier", "Golden Soldier",
        "gdemoman", "Golden Demoman",
        "gsnowballer", "Golden Snowballer"
    )
    return a
}

TowerKey(name) {
    return StrLower(RegExReplace(name, "[^A-Za-z0-9]", ""))
}

GetTowerInfo(name) {
    key := TowerKey(name)
    if (key = "")
        return ""
    db := TowerDB()
    if db.Has(key)
        return db[key]
    aliases := TowerAliases()
    if (aliases.Has(key)) {
        akey := TowerKey(aliases[key])
        if db.Has(akey)
            return db[akey]
    }
    return ""
}

TowerDisplayName(name) {
    info := GetTowerInfo(name)
    return info ? info.name : Trim(name)
}

; Rarity (category) -> background colour of the tower's square
TowerColorHex(name) {
    static colors := Map("Starter", "DCDCDC", "Intermediate", "00FF00", "Advanced", "42C6FF", "Hardcore", "C38CE8",
                         "Evolved", "42C6FF", "Golden Perk", "FFF200", "Exclusive", "FF4B6E")
    info := GetTowerInfo(name)
    return (info && colors.Has(info.category)) ? colors[info.category] : ""
}

; Path of a tower's icon, or "" when the file has not been added yet.
TowerIconPath(name) {
    proper := TowerDisplayName(name)
    if (proper = "")
        return ""
    path := "Resources/Images/TowerIcons/" RegExReplace(proper, '[\\/:*?"<>|]', "") ".png"
    return FileExist(path) ? path : ""
}

; "Crook Boss" -> "CB", "Firework Technician" -> "FT", "Scout" -> "SC" (at most 3 letters)
TowerInitials(name) {
    out := "", pos := 1
    while (pos := RegExMatch(name, "[A-Za-z0-9]+", &m, pos)) {
        pos += StrLen(m[0])
        out .= StrUpper(SubStr(m[0], 1, 1))
        if (StrLen(out) >= 3)
            break
    }
    if (StrLen(out) = 1) {
        if RegExMatch(name, "[A-Za-z0-9]{2}", &m2)
            out := StrUpper(SubStr(m2[0], 1, 1)) StrLower(SubStr(m2[0], 2, 1))
    }
    return out != "" ? out : "?"
}
