# Script Bien Dich Design Tokens Chuan W3C DTCG (compile_tokens.ps1)
# Boc tach 02_YEU_CAU_CUA_TOI/tokens.json va bien dich ra:
# 1. tokens.css (Route A Web Zero-Install, CSS custom properties)
# 2. Color.kt, Type.kt, Shape.kt (Route B Android Jetpack Compose)
# 3. colors.xml, dimens.xml (Route B Android Native XML)
# 4. Tu dong dong bo va cap nhat khoi ma xem truoc trong 02_YEU_CAU_CUA_TOI/design.md.

param(
    [string]$TokensFile,
    [string]$OutputDir,
    [string]$DesignDoc
)

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Tree-climbing tim repoRoot
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$current = $scriptDir
$repoRoot = $null
while ($current) {
    if (Test-Path (Join-Path $current "docs/WORKFLOW_LIFECYCLE.md")) {
        $repoRoot = $current
        break
    }
    $parent = Split-Path $current -Parent
    if ($parent -eq $current -or [string]::IsNullOrEmpty($parent)) { break }
    $current = $parent
}
if (-not $repoRoot) {
    $repoRoot = (Get-Location).Path
}

if (-not $TokensFile) {
    $TokensFile = Join-Path $repoRoot "02_YEU_CAU_CUA_TOI/tokens.json"
} elseif (-not [System.IO.Path]::IsPathRooted($TokensFile)) {
    $TokensFile = Join-Path $repoRoot $TokensFile
}

if (-not $OutputDir) {
    $OutputDir = Join-Path $repoRoot "02_YEU_CAU_CUA_TOI"
} elseif (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir = Join-Path $repoRoot $OutputDir
}

if (-not $DesignDoc) {
    $DesignDoc = Join-Path $repoRoot "02_YEU_CAU_CUA_TOI/design.md"
} elseif (-not [System.IO.Path]::IsPathRooted($DesignDoc)) {
    $DesignDoc = Join-Path $repoRoot $DesignDoc
}

if (-not (Test-Path -LiteralPath $TokensFile)) {
    Write-Host "[FAIL] Khong tim thay file token tai: $TokensFile" -ForegroundColor Red
    exit 1
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "   BIEN DICH DESIGN TOKENS CHUAN W3C DTCG 3 TANG (.agents/scripts/compile_tokens.ps1)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " * Tep nguon tokens.json : $TokensFile" -ForegroundColor White
Write-Host " * Thu muc xuat ban      : $OutputDir" -ForegroundColor White

$rawJson = Get-Content -LiteralPath $TokensFile -Raw -Encoding UTF8
$tokens = $rawJson | ConvertFrom-Json

# Helper: Duyet lay gia tri token de quy voi ho tro alias {group.path.key}
function Resolve-TokenRef {
    param(
        [string]$RefStr,
        [object]$RootTokens
    )

    $currentStr = $RefStr
    $maxHops = 10
    $hop = 0
    while ($currentStr -match '^\{([^}]+)\}$' -and $hop -lt $maxHops) {
        $hop++
        $pathParts = $matches[1].Split('.')
        $curr = $RootTokens
        foreach ($part in $pathParts) {
            if ($curr -and $curr.PSObject.Properties[$part]) {
                $curr = $curr.$part
            } else {
                $curr = $null
                break
            }
        }
        if ($curr -and $curr.PSObject.Properties['$value']) {
            $currentStr = [string]$curr.'$value'
        } else {
            break
        }
    }
    return $currentStr
}

# Helper: Chuan hoa hex sang format Compose Color(0xFF...)
function To-ComposeColorHex {
    param([string]$Hex)
    $clean = $Hex.Trim().TrimStart('#')
    if ($clean.Length -eq 6) {
        return "0xFF" + $clean.ToUpper()
    } elseif ($clean.Length -eq 8) {
        return "0x" + $clean.ToUpper()
    } elseif ($clean.Length -eq 3) {
        $r = $clean[0]; $g = $clean[1]; $b = $clean[2]
        return "0xFF" + ("$r$r$g$g$b$b").ToUpper()
    }
    return "0xFF000000"
}

# Helper: Chuan hoa hex sang format XML (#AARRGGBB hoac #RRGGBB)
function To-XmlColorHex {
    param([string]$Hex)
    $clean = $Hex.Trim().TrimStart('#')
    if ($clean.Length -eq 6) {
        return "#" + $clean.ToUpper()
    } elseif ($clean.Length -eq 8) {
        return "#" + $clean.ToUpper()
    } elseif ($clean.Length -eq 3) {
        $r = $clean[0]; $g = $clean[1]; $b = $clean[2]
        return "#" + ("$r$r$g$g$b$b").ToUpper()
    }
    return "#000000"
}

# Helper: Chuan hoa dimension sang dp
function To-AndroidDp {
    param([string]$Dim)
    $clean = $Dim.Trim().ToLower() -replace 'px', 'dp'
    if ($clean -notmatch 'dp$') { $clean += "dp" }
    return $clean
}

# Trich xuat Semantic Colors
$semColors = @{}
if ($tokens.semantic -and $tokens.semantic.color) {
    foreach ($prop in $tokens.semantic.color.PSObject.Properties) {
        $resolved = Resolve-TokenRef -RefStr ([string]$prop.Value.'$value') -RootTokens $tokens
        $semColors[$prop.Name] = $resolved
    }
}

# Trich xuat Global Colors neu thieu semantic
if ($tokens.global -and $tokens.global.color) {
    foreach ($prop in $tokens.global.color.PSObject.Properties) {
        $resolved = Resolve-TokenRef -RefStr ([string]$prop.Value.'$value') -RootTokens $tokens
        if (-not $semColors.ContainsKey($prop.Name)) {
            $semColors[$prop.Name] = $resolved
        }
    }
}

# Cac token mac dinh bat buoc
$defaultColors = [ordered]@{
    "primary"        = if ($semColors["primary"]) { $semColors["primary"] } else { "#2563eb" }
    "primary-hover"  = if ($semColors["primary-hover"]) { $semColors["primary-hover"] } else { "#1d4ed8" }
    "background"     = if ($semColors["background"]) { $semColors["background"] } else { "#f8fafc" }
    "surface"        = if ($semColors["surface"]) { $semColors["surface"] } else { "#ffffff" }
    "border"         = if ($semColors["border"]) { $semColors["border"] } else { "#e2e8f0" }
    "text-main"      = if ($semColors["text-main"]) { $semColors["text-main"] } else { "#0f172a" }
    "text-muted"     = if ($semColors["text-muted"]) { $semColors["text-muted"] } else { "#64748b" }
    "accent"         = if ($semColors["accent"]) { $semColors["accent"] } else { "#10b981" }
    "danger"         = if ($semColors["danger"]) { $semColors["danger"] } else { "#ef4444" }
    "warning"        = if ($semColors["warning"]) { $semColors["warning"] } else { "#f59e0b" }
    "info"           = if ($semColors["info"]) { $semColors["info"] } else { "#0284c7" }
}

# Dimensions & Radius
$radiusSm = if ($tokens.global.dimension.'radius-sm') { Resolve-TokenRef $tokens.global.dimension.'radius-sm'.'$value' $tokens } else { "6px" }
$radiusMd = if ($tokens.global.dimension.'radius-md') { Resolve-TokenRef $tokens.global.dimension.'radius-md'.'$value' $tokens } else { "12px" }
$radiusLg = if ($tokens.global.dimension.'radius-lg') { Resolve-TokenRef $tokens.global.dimension.'radius-lg'.'$value' $tokens } else { "20px" }
$targetMin = if ($tokens.global.dimension.'target-min') { Resolve-TokenRef $tokens.global.dimension.'target-min'.'$value' $tokens } else { "48px" }

if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# -----------------------------------------------------------------------------
# 1. Sinh tokens.css (Route A Web Zero-Install)
# -----------------------------------------------------------------------------
$cssSb = [System.Text.StringBuilder]::new()
[void]$cssSb.AppendLine("/**")
[void]$cssSb.AppendLine(" * REA W3C DTCG Compiled Design Tokens (Route A Web Zero-Install)")
[void]$cssSb.AppendLine(" * DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json")
[void]$cssSb.AppendLine(" * Auto-generated by .agents/scripts/compile_tokens.ps1")
[void]$cssSb.AppendLine(" */")
[void]$cssSb.AppendLine(":root {")
[void]$cssSb.AppendLine("  /* Brand & Semantic Colors */")
foreach ($k in $defaultColors.Keys) {
    [void]$cssSb.AppendLine(('  --color-{0}: {1};' -f $k, $defaultColors[$k]))
}
[void]$cssSb.AppendLine("")
[void]$cssSb.AppendLine("  /* Corner Radius & Touch Targets */")
[void]$cssSb.AppendLine(('  --radius-sm: {0};' -f $radiusSm))
[void]$cssSb.AppendLine(('  --radius-md: {0};' -f $radiusMd))
[void]$cssSb.AppendLine(('  --radius-lg: {0};' -f $radiusLg))
[void]$cssSb.AppendLine(('  --touch-target-min: {0};' -f $targetMin))
[void]$cssSb.AppendLine("")
[void]$cssSb.AppendLine("  /* Typography */")
[void]$cssSb.AppendLine('  --font-main: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;')
[void]$cssSb.AppendLine("  --font-size-sm: 14px;")
[void]$cssSb.AppendLine("  --font-size-base: 16px;")
[void]$cssSb.AppendLine("  --font-size-lg: 20px;")
[void]$cssSb.AppendLine("  --font-size-xl: 24px;")
[void]$cssSb.AppendLine("  --line-height-base: 1.5;")
[void]$cssSb.AppendLine("")
[void]$cssSb.AppendLine("  /* Motion Tokens */")
[void]$cssSb.AppendLine("  --motion-duration-fast: 150ms;")
[void]$cssSb.AppendLine("  --motion-duration-base: 250ms;")
[void]$cssSb.AppendLine("  --motion-duration-slow: 400ms;")
[void]$cssSb.AppendLine("  --motion-easing-standard: cubic-bezier(0.2, 0, 0, 1);")
[void]$cssSb.AppendLine("  --motion-easing-emphasized: cubic-bezier(0.05, 0.7, 0.1, 1);")
[void]$cssSb.AppendLine("  --motion-easing-accelerate: cubic-bezier(0.3, 0, 0.8, 0.15);")
[void]$cssSb.AppendLine("")
[void]$cssSb.AppendLine("  /* Elevation & Shadows */")
[void]$cssSb.AppendLine("  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);")
[void]$cssSb.AppendLine("  --shadow-card: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);")
[void]$cssSb.AppendLine("  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);")
[void]$cssSb.AppendLine("}")
[void]$cssSb.AppendLine("")
[void]$cssSb.AppendLine("/* Ho tro Reduced Motion */")
[void]$cssSb.AppendLine("@media (prefers-reduced-motion: reduce) {")
[void]$cssSb.AppendLine("  :root {")
[void]$cssSb.AppendLine("    --motion-duration-fast: 0.01ms;")
[void]$cssSb.AppendLine("    --motion-duration-base: 0.01ms;")
[void]$cssSb.AppendLine("    --motion-duration-slow: 0.01ms;")
[void]$cssSb.AppendLine("  }")
[void]$cssSb.AppendLine("}")

$cssOut = Join-Path $OutputDir "tokens.css"
[System.IO.File]::WriteAllText($cssOut, $cssSb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host " [OK] Da bien dich CSS Tokens     : $cssOut" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 2. Sinh Color.kt (Jetpack Compose)
# -----------------------------------------------------------------------------
$colorKtSb = [System.Text.StringBuilder]::new()
[void]$colorKtSb.AppendLine("package ui.theme")
[void]$colorKtSb.AppendLine("")
[void]$colorKtSb.AppendLine("import androidx.compose.ui.graphics.Color")
[void]$colorKtSb.AppendLine("")
[void]$colorKtSb.AppendLine("/**")
[void]$colorKtSb.AppendLine(" * REA W3C DTCG Compiled Color Tokens (Route B Android Native)")
[void]$colorKtSb.AppendLine(" * DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json")
[void]$colorKtSb.AppendLine(" * Auto-generated by .agents/scripts/compile_tokens.ps1")
[void]$colorKtSb.AppendLine(" */")
[void]$colorKtSb.AppendLine(('val Primary = Color({0})' -f (To-ComposeColorHex $defaultColors['primary'])))
[void]$colorKtSb.AppendLine(('val PrimaryHover = Color({0})' -f (To-ComposeColorHex $defaultColors['primary-hover'])))
[void]$colorKtSb.AppendLine(('val Background = Color({0})' -f (To-ComposeColorHex $defaultColors['background'])))
[void]$colorKtSb.AppendLine(('val Surface = Color({0})' -f (To-ComposeColorHex $defaultColors['surface'])))
[void]$colorKtSb.AppendLine(('val Border = Color({0})' -f (To-ComposeColorHex $defaultColors['border'])))
[void]$colorKtSb.AppendLine(('val TextMain = Color({0})' -f (To-ComposeColorHex $defaultColors['text-main'])))
[void]$colorKtSb.AppendLine(('val TextMuted = Color({0})' -f (To-ComposeColorHex $defaultColors['text-muted'])))
[void]$colorKtSb.AppendLine(('val Accent = Color({0})' -f (To-ComposeColorHex $defaultColors['accent'])))
[void]$colorKtSb.AppendLine(('val Danger = Color({0})' -f (To-ComposeColorHex $defaultColors['danger'])))
[void]$colorKtSb.AppendLine(('val Warning = Color({0})' -f (To-ComposeColorHex $defaultColors['warning'])))
[void]$colorKtSb.AppendLine(('val Info = Color({0})' -f (To-ComposeColorHex $defaultColors['info'])))

$colorKtOut = Join-Path $OutputDir "Color.kt"
[System.IO.File]::WriteAllText($colorKtOut, $colorKtSb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host " [OK] Da bien dich Compose Color  : $colorKtOut" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 3. Sinh Type.kt (Jetpack Compose Typography)
# -----------------------------------------------------------------------------
$typeKtSb = [System.Text.StringBuilder]::new()
[void]$typeKtSb.AppendLine("package ui.theme")
[void]$typeKtSb.AppendLine("")
[void]$typeKtSb.AppendLine("import androidx.compose.material3.Typography")
[void]$typeKtSb.AppendLine("import androidx.compose.ui.text.TextStyle")
[void]$typeKtSb.AppendLine("import androidx.compose.ui.text.font.FontFamily")
[void]$typeKtSb.AppendLine("import androidx.compose.ui.text.font.FontWeight")
[void]$typeKtSb.AppendLine("import androidx.compose.ui.unit.sp")
[void]$typeKtSb.AppendLine("")
[void]$typeKtSb.AppendLine("/**")
[void]$typeKtSb.AppendLine(" * REA W3C DTCG Compiled Typography Tokens (Route B Android Native)")
[void]$typeKtSb.AppendLine(" * DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json")
[void]$typeKtSb.AppendLine(" * Auto-generated by .agents/scripts/compile_tokens.ps1")
[void]$typeKtSb.AppendLine(" */")
[void]$typeKtSb.AppendLine("val Typography = Typography(")
[void]$typeKtSb.AppendLine("    bodySmall = TextStyle(")
[void]$typeKtSb.AppendLine("        fontFamily = FontFamily.Default,")
[void]$typeKtSb.AppendLine("        fontSize = 14.sp,")
[void]$typeKtSb.AppendLine("        lineHeight = 20.sp")
[void]$typeKtSb.AppendLine("    ),")
[void]$typeKtSb.AppendLine("    bodyLarge = TextStyle(")
[void]$typeKtSb.AppendLine("        fontFamily = FontFamily.Default,")
[void]$typeKtSb.AppendLine("        fontSize = 16.sp,")
[void]$typeKtSb.AppendLine("        lineHeight = 24.sp")
[void]$typeKtSb.AppendLine("    ),")
[void]$typeKtSb.AppendLine("    titleLarge = TextStyle(")
[void]$typeKtSb.AppendLine("        fontFamily = FontFamily.Default,")
[void]$typeKtSb.AppendLine("        fontSize = 20.sp,")
[void]$typeKtSb.AppendLine("        fontWeight = FontWeight.Bold,")
[void]$typeKtSb.AppendLine("        lineHeight = 28.sp")
[void]$typeKtSb.AppendLine("    ),")
[void]$typeKtSb.AppendLine("    headlineMedium = TextStyle(")
[void]$typeKtSb.AppendLine("        fontFamily = FontFamily.Default,")
[void]$typeKtSb.AppendLine("        fontSize = 24.sp,")
[void]$typeKtSb.AppendLine("        fontWeight = FontWeight.Bold,")
[void]$typeKtSb.AppendLine("        lineHeight = 32.sp")
[void]$typeKtSb.AppendLine("    )")
[void]$typeKtSb.AppendLine(")")

$typeKtOut = Join-Path $OutputDir "Type.kt"
[System.IO.File]::WriteAllText($typeKtOut, $typeKtSb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host " [OK] Da bien dich Compose Type   : $typeKtOut" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 4. Sinh Shape.kt (Jetpack Compose Shapes)
# -----------------------------------------------------------------------------
$shapeKtSb = [System.Text.StringBuilder]::new()
[void]$shapeKtSb.AppendLine("package ui.theme")
[void]$shapeKtSb.AppendLine("")
[void]$shapeKtSb.AppendLine("import androidx.compose.foundation.shape.RoundedCornerShape")
[void]$shapeKtSb.AppendLine("import androidx.compose.material3.Shapes")
[void]$shapeKtSb.AppendLine("import androidx.compose.ui.unit.dp")
[void]$shapeKtSb.AppendLine("")
[void]$shapeKtSb.AppendLine("/**")
[void]$shapeKtSb.AppendLine(" * REA W3C DTCG Compiled Shape Tokens (Route B Android Native)")
[void]$shapeKtSb.AppendLine(" * DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json")
[void]$shapeKtSb.AppendLine(" * Auto-generated by .agents/scripts/compile_tokens.ps1")
[void]$shapeKtSb.AppendLine(" */")
[void]$shapeKtSb.AppendLine("val Shapes = Shapes(")
[void]$shapeKtSb.AppendLine(('    small = RoundedCornerShape({0}),' -f (To-AndroidDp $radiusSm)))
[void]$shapeKtSb.AppendLine(('    medium = RoundedCornerShape({0}),' -f (To-AndroidDp $radiusMd)))
[void]$shapeKtSb.AppendLine(('    large = RoundedCornerShape({0})' -f (To-AndroidDp $radiusLg)))
[void]$shapeKtSb.AppendLine(")")

$shapeKtOut = Join-Path $OutputDir "Shape.kt"
[System.IO.File]::WriteAllText($shapeKtOut, $shapeKtSb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host " [OK] Da bien dich Compose Shape  : $shapeKtOut" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 5. Sinh colors.xml (Android Native XML)
# -----------------------------------------------------------------------------
$colorsXmlSb = [System.Text.StringBuilder]::new()
[void]$colorsXmlSb.AppendLine('<?xml version="1.0" encoding="utf-8"?>')
[void]$colorsXmlSb.AppendLine('<!-- REA W3C DTCG Compiled XML Colors (Route B Android Native) -->')
[void]$colorsXmlSb.AppendLine('<!-- DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json -->')
[void]$colorsXmlSb.AppendLine('<!-- Auto-generated by .agents/scripts/compile_tokens.ps1 -->')
[void]$colorsXmlSb.AppendLine('<resources>')
foreach ($k in $defaultColors.Keys) {
    $xmlName = "color_" + ($k -replace '-', '_')
    $hex = To-XmlColorHex $defaultColors[$k]
    [void]$colorsXmlSb.AppendLine(('    <color name="{0}">{1}</color>' -f $xmlName, $hex))
}
[void]$colorsXmlSb.AppendLine('</resources>')

$colorsXmlOut = Join-Path $OutputDir "colors.xml"
[System.IO.File]::WriteAllText($colorsXmlOut, $colorsXmlSb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host " [OK] Da bien dich XML Colors     : $colorsXmlOut" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 6. Sinh dimens.xml (Android Native XML)
# -----------------------------------------------------------------------------
$dimensXmlSb = [System.Text.StringBuilder]::new()
[void]$dimensXmlSb.AppendLine('<?xml version="1.0" encoding="utf-8"?>')
[void]$dimensXmlSb.AppendLine('<!-- REA W3C DTCG Compiled XML Dimens (Route B Android Native) -->')
[void]$dimensXmlSb.AppendLine('<!-- DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json -->')
[void]$dimensXmlSb.AppendLine('<!-- Auto-generated by .agents/scripts/compile_tokens.ps1 -->')
[void]$dimensXmlSb.AppendLine('<resources>')
[void]$dimensXmlSb.AppendLine(('    <dimen name="radius_sm">{0}</dimen>' -f (To-AndroidDp $radiusSm)))
[void]$dimensXmlSb.AppendLine(('    <dimen name="radius_md">{0}</dimen>' -f (To-AndroidDp $radiusMd)))
[void]$dimensXmlSb.AppendLine(('    <dimen name="radius_lg">{0}</dimen>' -f (To-AndroidDp $radiusLg)))
[void]$dimensXmlSb.AppendLine(('    <dimen name="touch_target_min">{0}</dimen>' -f (To-AndroidDp $targetMin)))
[void]$dimensXmlSb.AppendLine('</resources>')

$dimensXmlOut = Join-Path $OutputDir "dimens.xml"
[System.IO.File]::WriteAllText($dimensXmlOut, $dimensXmlSb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host " [OK] Da bien dich XML Dimens     : $dimensXmlOut" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 7. Dong bo sang 05_MA_NGUON_PHAT_TRIEN (Neu thu muc dich ton tai)
# -----------------------------------------------------------------------------
$srcRoot = Join-Path $repoRoot "05_MA_NGUON_PHAT_TRIEN"
if (Test-Path -LiteralPath $srcRoot) {
    # Web target
    $webCssDir = Join-Path $srcRoot "css"
    if (Test-Path -LiteralPath $webCssDir) {
        Copy-Item -LiteralPath $cssOut -Destination (Join-Path $webCssDir "tokens.css") -Force
        Write-Host " [SYNC] Da dong bo tokens.css -> $webCssDir/tokens.css" -ForegroundColor Cyan
    }

    # Android Compose target
    $androidThemeDirs = Get-ChildItem -Path $srcRoot -Recurse -Directory -Filter "theme" -ErrorAction SilentlyContinue
    foreach ($td in $androidThemeDirs) {
        Copy-Item -LiteralPath $colorKtOut -Destination (Join-Path $td.FullName "Color.kt") -Force
        Copy-Item -LiteralPath $typeKtOut -Destination (Join-Path $td.FullName "Type.kt") -Force
        Copy-Item -LiteralPath $shapeKtOut -Destination (Join-Path $td.FullName "Shape.kt") -Force
        Write-Host " [SYNC] Da dong bo Compose tokens -> $($td.FullName)" -ForegroundColor Cyan
    }

    # Android Res Values target
    $androidValDirs = Get-ChildItem -Path $srcRoot -Recurse -Directory -Filter "values" -ErrorAction SilentlyContinue
    foreach ($vd in $androidValDirs) {
        Copy-Item -LiteralPath $colorsXmlOut -Destination (Join-Path $vd.FullName "colors.xml") -Force
        Copy-Item -LiteralPath $dimensXmlOut -Destination (Join-Path $vd.FullName "dimens.xml") -Force
        Write-Host " [SYNC] Da dong bo XML tokens -> $($vd.FullName)" -ForegroundColor Cyan
    }
}

# -----------------------------------------------------------------------------
# 8. Cap nhat khoi xem truoc (Preview) trong 02_YEU_CAU_CUA_TOI/design.md
# -----------------------------------------------------------------------------
if (Test-Path -LiteralPath $DesignDoc) {
    $designContent = [System.IO.File]::ReadAllText($DesignDoc, [System.Text.Encoding]::UTF8)
    $fences = '```'

    # 8.1 Cap nhat khoi CSS
    $cssLines = @(
        "$fences" + "css",
        ":root {",
        "  /* Mau thuong hieu & Nut chinh */",
        ("  --color-primary: {0};         /* Xanh duong hien dai */" -f $defaultColors['primary']),
        ("  --color-primary-hover: {0};   /* Mau di chuot vao nut */" -f $defaultColors['primary-hover']),
        "  ",
        "  /* Nen trang & Be mat khung */",
        ("  --color-background: {0};      /* Nen xam nhat diu mat */" -f $defaultColors['background']),
        ("  --color-surface: {0};         /* Nen trang cho the va bang */" -f $defaultColors['surface']),
        ("  --color-border: {0};          /* Duong vien ngan cach */" -f $defaultColors['border']),
        "  ",
        "  /* Mau chu */",
        ("  --color-text-main: {0};       /* Chu den dam de doc */" -f $defaultColors['text-main']),
        ("  --color-text-muted: {0};      /* Chu phu xam mo */" -f $defaultColors['text-muted']),
        "  ",
        "  /* Mau trang thai */",
        ("  --color-accent: {0};          /* Xanh la: Thanh cong */" -f $defaultColors['accent']),
        ("  --color-danger: {0};          /* Do: Xoa, Loi */" -f $defaultColors['danger']),
        ("  --color-warning: {0};         /* Vang: Canh bao */" -f $defaultColors['warning']),
        ("  --color-info: {0};            /* Xanh duong nhat: Chi dan */" -f $defaultColors['info']),
        "  ",
        "  /* Kich thuoc & Bo goc */",
        ("  --radius-sm: {0};" -f $radiusSm),
        ("  --radius-md: {0};" -f $radiusMd),
        ("  --radius-lg: {0};" -f $radiusLg),
        ("  --touch-target-min: {0};" -f $targetMin),
        "  ",
        "  /* Do bong & Nang be mat (Elevation) */",
        "  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);",
        "  --shadow-card: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);",
        "  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);",
        "}",
        "$fences"
    )
    $cssBlock = $cssLines -join "`n"

    if ($designContent -match '#### a\) Web CSS Tokens \(Route A\)[\s\S]*?```css[\s\S]*?```') {
        $designContent = [regex]::Replace($designContent, '#### a\) Web CSS Tokens \(Route A\)[\s\S]*?```css[\s\S]*?```', "#### a) Web CSS Tokens (Route A)`n$cssBlock")
    }

    # 8.2 Cap nhat khoi Compose Color
    $composeLines = @(
        "$fences" + "kotlin",
        "// Jetpack Compose Color Tokens (ui/theme/Color.kt)",
        ("val PrimaryColor = Color({0})" -f (To-ComposeColorHex $defaultColors['primary'])),
        ("val PrimaryHoverColor = Color({0})" -f (To-ComposeColorHex $defaultColors['primary-hover'])),
        ("val BackgroundColor = Color({0})" -f (To-ComposeColorHex $defaultColors['background'])),
        ("val SurfaceColor = Color({0})" -f (To-ComposeColorHex $defaultColors['surface'])),
        ("val BorderColor = Color({0})" -f (To-ComposeColorHex $defaultColors['border'])),
        ("val TextMainColor = Color({0})" -f (To-ComposeColorHex $defaultColors['text-main'])),
        ("val TextMutedColor = Color({0})" -f (To-ComposeColorHex $defaultColors['text-muted'])),
        ("val AccentColor = Color({0})" -f (To-ComposeColorHex $defaultColors['accent'])),
        ("val DangerColor = Color({0})" -f (To-ComposeColorHex $defaultColors['danger'])),
        ("val WarningColor = Color({0})" -f (To-ComposeColorHex $defaultColors['warning'])),
        ("val InfoColor = Color({0})" -f (To-ComposeColorHex $defaultColors['info'])),
        "$fences"
    )
    $composeBlock = $composeLines -join "`n"

    if ($designContent -match '```kotlin\s*// Jetpack Compose Color Tokens[\s\S]*?```') {
        $designContent = [regex]::Replace($designContent, '```kotlin\s*// Jetpack Compose Color Tokens[\s\S]*?```', $composeBlock)
    }

    # 8.3 Cap nhat khoi XML Colors
    $xmlColorLines = [System.Collections.Generic.List[string]]::new()
    $xmlColorLines.Add("$fences" + "xml")
    $xmlColorLines.Add("<!-- Android XML Color Tokens (res/values/colors.xml) -->")
    $xmlColorLines.Add("<resources>")
    foreach ($k in $defaultColors.Keys) {
        $xmlName = "color_" + ($k -replace '-', '_')
        $hex = To-XmlColorHex $defaultColors[$k]
        $xmlColorLines.Add(('    <color name="{0}">{1}</color>' -f $xmlName, $hex))
    }
    $xmlColorLines.Add("</resources>")
    $xmlColorLines.Add("$fences")
    $xmlColorsBlock = $xmlColorLines -join "`n"

    if ($designContent -match '```xml\s*<!-- Android XML Color Tokens[\s\S]*?```') {
        $designContent = [regex]::Replace($designContent, '```xml\s*<!-- Android XML Color Tokens[\s\S]*?```', $xmlColorsBlock)
    }

    # 8.4 Cap nhat khoi Compose Shapes
    $composeShapeLines = @(
        "$fences" + "kotlin",
        "// Jetpack Compose Shapes (ui/theme/Shape.kt)",
        "val Shapes = Shapes(",
        ("    small = RoundedCornerShape({0})," -f (To-AndroidDp $radiusSm)),
        ("    medium = RoundedCornerShape({0})," -f (To-AndroidDp $radiusMd)),
        ("    large = RoundedCornerShape({0})" -f (To-AndroidDp $radiusLg)),
        ")",
        "$fences"
    )
    $composeShapeBlock = $composeShapeLines -join "`n"

    if ($designContent -match '```kotlin\s*// Jetpack Compose Shapes[\s\S]*?```') {
        $designContent = [regex]::Replace($designContent, '```kotlin\s*// Jetpack Compose Shapes[\s\S]*?```', $composeShapeBlock)
    }

    # 8.5 Cap nhat khoi XML Dimens
    $xmlDimensLines = @(
        "$fences" + "xml",
        "<!-- Android XML Dimens (res/values/dimens.xml) -->",
        "<resources>",
        ("    <dimen name=""radius_sm"">{0}</dimen>" -f (To-AndroidDp $radiusSm)),
        ("    <dimen name=""radius_md"">{0}</dimen>" -f (To-AndroidDp $radiusMd)),
        ("    <dimen name=""radius_lg"">{0}</dimen>" -f (To-AndroidDp $radiusLg)),
        ("    <dimen name=""touch_target_min"">{0}</dimen>" -f (To-AndroidDp $targetMin)),
        "</resources>",
        "$fences"
    )
    $xmlDimensBlock = $xmlDimensLines -join "`n"

    if ($designContent -match '```xml\s*<!-- Android XML Dimens[\s\S]*?```') {
        $designContent = [regex]::Replace($designContent, '```xml\s*<!-- Android XML Dimens[\s\S]*?```', $xmlDimensBlock)
    }

    [System.IO.File]::WriteAllText($DesignDoc, $designContent, [System.Text.Encoding]::UTF8)
    Write-Host " [OK] Da cap nhat xem truoc trong : $DesignDoc" -ForegroundColor Green
}

Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "[OK] BIEN DICH DESIGN TOKENS HOAN TAT 100%!" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Cyan
exit 0
