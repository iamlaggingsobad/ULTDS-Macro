; ======================================================================================================================
; Vision: Looking at the game: image search and reading text on screen (OCR).
;
; Functions only. Nothing runs from this file; it is included by Main.ahk (see the #Include lines there).
; ======================================================================================================================

AdvancedImageSearch(templ, x, y, w, h, minScale := 0.0, maxScale := 0.0, scaleStep := 0.05) {
    if (LegacyMode) {
        nx := 0
        ny := 0

        score := ImageSearch(&nx, &ny, x, y, x+w, y+h, "*80 " templ)

        status := "failed"

        if score == 1
            status := "success"

        return {score: score, x: nx, y: ny, message: " ", status: status}
    } else {
        return AdvImageSearch(templ, x, y, w, h, minScale, maxScale, scaleStep)
    }
}

CheckOcrLanguage() {
    try {
        rawLangs := OCR.GetAvailableLanguages()
        hasEnglish := false
        
        availableLangs := StrSplit(rawLangs, ["`n", "`r", ",", " "])
        
        for lang in availableLangs {
            if (lang = "")
                continue
                
            if InStr(lang, "en") {
                hasEnglish := true
                break
            }
        }
        
        if (!hasEnglish) {
            msgText := "English language pack for OCR (text detection) is not installed on your system!`n`n"
                    . "Without it, the script cannot read text from the screen properly.`n`n"
                    . "Would you like to open Windows Settings to download the Language?"
            
            result := MsgBox(msgText, "Missing OCR Language", 48 + 4)
            
            if (result = "Yes") {
                Run("ms-settings:regionlanguage")
            }
            
            ExitApp()
        }
    }
}

; reads tds message (e.g., "You cannot place here")
; returns 1 if the given text is found, 0 if not
; ReadMessage(["already", "current", "rotation"]), for example
; works only with red color
ReadMessage(includeStr := "", includeRx := "", excludeStr := "", excludeRx := "") {
    langCode := "en-US"
    for availableLang in StrSplit(OCR.GetAvailableLanguages(), "`n", "`r") {
        if (availableLang != "" && SubStr(availableLang, 1, 2) = "en") {
            langCode := availableLang
            break
        }
    }

    getRobloxPos(,,&w,&h)
    x := Round(w * 0.2), y := Round(h * 0.18)
    width := Round(w * 0.7) - x, height := Round(h * 0.35) - y

    if (width <= 0 || height <= 0)
        return false

    pBitmap := Gdip_BitmapFromScreen(x "|" y "|" width "|" height)
    pGraphics := Gdip_GraphicsFromImage(pBitmap)
    Matrix := "
    (
    5.0|0.0|0.0|0.0|0.0|
    0.0|-5.0|0.0|0.0|0.0|
    0.0|0.0|-5.0|0.0|0.0|
    0.0|0.0|0.0|1.0|0.0|
    -2.5|1.0|1.0|0.0|1.0
    )"
    pBitmapFiltered := Gdip_CreateBitmap(width, height)
    pGraphicsFiltered := Gdip_GraphicsFromImage(pBitmapFiltered)
    Gdip_DrawImage(pGraphicsFiltered, pBitmap, 0, 0, width, height, 0, 0, width, height, Matrix)
    hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmapFiltered)

    ocrResult := OCR.FromBitmap(hBitmap, {lang: langCode, scale: 3, grayscale: 1})

    DeleteObject(hBitmap)
    Gdip_DisposeImage(pBitmapFiltered), Gdip_DeleteGraphics(pGraphicsFiltered)
    Gdip_DeleteGraphics(pGraphics), Gdip_DisposeImage(pBitmap)

    ocrText := ocrResult.Text

    for s in (HasMethod(excludeStr, "__Enum") ? excludeStr : [excludeStr]) {
        if (s != "" && RegExMatch(ocrText, "i)\b" . s . "\b"))
            return false
    }
    for rx in (HasMethod(excludeRx, "__Enum") ? excludeRx : [excludeRx]) {
        if (rx != "" && RegExMatch(ocrText, "i)" . rx))
            return false
    }

    matchStr := (includeStr == "")
    for s in (HasMethod(includeStr, "__Enum") ? includeStr : [includeStr]) {
        if (s != "" && RegExMatch(ocrText, "i)\b" . s . "\b")) {
            matchStr := true
            break
        }
    }

    matchRx := (includeRx == "")
    for rx in (HasMethod(includeRx, "__Enum") ? includeRx : [includeRx]) {
        if (rx != "" && RegExMatch(ocrText, "i)" . rx)) {
            matchRx := true
            break
        }
    }

    return matchStr && matchRx
}
