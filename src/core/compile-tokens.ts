import fs from "node:fs/promises";
import path from "node:path";
import { findRepoRoot } from "./workspace.js";
import { writeUtf8NoBomAtomic } from "./state-lock.js";

export interface CompileTokensOptions {
  repoRoot?: string;
  tokensFile?: string;
  outputDir?: string;
  designDoc?: string;
}

export interface CompileTokensResult {
  success: boolean;
  tokensFile: string;
  outputDir: string;
  generatedFiles: string[];
  syncedFiles: string[];
  updatedDesignDoc: boolean;
  colors: Record<string, string>;
  dimensions: {
    radiusSm: string;
    radiusMd: string;
    radiusLg: string;
    targetMin: string;
  };
  typography?: {
    fontMain: string;
    fontSizeSm: string;
    fontSizeBase: string;
    fontSizeLg: string;
    fontSizeXl: string;
    lineHeightBase: string;
  };
  duration?: {
    fast: string;
    base: string;
    slow: string;
  };
}

/**
 * Extracts a normalized string value from W3C DTCG 2025.10 token value representations.
 * Handles:
 * - DTCG Color objects with .hex (e.g. { hex: "#2563eb", colorSpace: "srgb" })
 * - DTCG Dimension / Duration objects with .value and .unit (e.g. { value: 12, unit: "px" })
 * - Raw numbers (e.g. 1.5 -> "1.5")
 * - Raw strings (e.g. "#ffffff" -> "#ffffff", "6px" -> "6px")
 */
export function extractDtcgValue(raw: unknown): string {
  if (raw === null || raw === undefined) return "";
  if (typeof raw === "string") return raw;
  if (typeof raw === "number") return String(raw);
  if (typeof raw === "object") {
    const obj = raw as any;
    // If object with .hex, return .hex
    if (typeof obj.hex === "string") {
      return obj.hex;
    }
    // If object with .value and .unit, return `${raw.value}${raw.unit}`
    if (obj.value !== undefined && obj.unit !== undefined) {
      return `${obj.value}${obj.unit}`;
    }
    // If nested $value exists
    if (obj.$value !== undefined) {
      return extractDtcgValue(obj.$value);
    }
    // If object with just .value
    if (obj.value !== undefined && typeof obj.value !== "object") {
      return String(obj.value);
    }
  }
  return String(raw);
}

export function resolveTokenRef(
  refStr: unknown,
  rootTokens: any,
  maxHops = 10
): string {
  if (typeof refStr === "object" && refStr !== null) {
    const extracted = extractDtcgValue(refStr);
    if (!extracted.startsWith("{")) {
      return extracted;
    }
    refStr = extracted;
  }

  let currentStr = String(refStr ?? "");
  let hop = 0;

  while (hop < maxHops) {
    const match = currentStr.match(/^\{([^}]+)\}$/);
    if (!match) break;
    hop++;

    const pathParts = match[1].split(".");
    let curr: any = rootTokens;

    for (const part of pathParts) {
      if (curr && typeof curr === "object" && part in curr) {
        curr = curr[part];
      } else {
        curr = null;
        break;
      }
    }

    if (curr && typeof curr === "object") {
      if ("$value" in curr) {
        currentStr = extractDtcgValue(curr.$value);
      } else if ("value" in curr) {
        currentStr = extractDtcgValue(curr.value);
      } else {
        currentStr = extractDtcgValue(curr);
        break;
      }
    } else if (typeof curr === "string" || typeof curr === "number") {
      currentStr = String(curr);
    } else {
      break;
    }
  }

  return extractDtcgValue(currentStr);
}

export function toComposeColorHex(hex: string): string {
  const clean = hex.trim().replace(/^#/, "");
  if (clean.length === 6) {
    return `0xFF${clean.toUpperCase()}`;
  } else if (clean.length === 8) {
    return `0x${clean.toUpperCase()}`;
  } else if (clean.length === 3) {
    const [r, g, b] = clean;
    return `0xFF${(r + r + g + g + b + b).toUpperCase()}`;
  }
  return "0xFF000000";
}

export function toXmlColorHex(hex: string): string {
  const clean = hex.trim().replace(/^#/, "");
  if (clean.length === 6 || clean.length === 8) {
    return `#${clean.toUpperCase()}`;
  } else if (clean.length === 3) {
    const [r, g, b] = clean;
    return `#${r}${r}${g}${g}${b}${b}`.toUpperCase();
  }
  return "#000000";
}

export function toAndroidDp(dim: string): string {
  let clean = dim.trim().toLowerCase().replace(/px$/, "dp");
  if (!clean.endsWith("dp")) {
    clean += "dp";
  }
  return clean;
}

async function findDirsRecursively(
  dir: string,
  targetName: string
): Promise<string[]> {
  const results: string[] = [];
  try {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (entry.name.toLowerCase() === targetName.toLowerCase()) {
          results.push(fullPath);
        }
        const sub = await findDirsRecursively(fullPath, targetName);
        results.push(...sub);
      }
    }
  } catch {
    // Ignore unreadable dirs
  }
  return results;
}

export async function compileTokens(
  options: CompileTokensOptions = {}
): Promise<CompileTokensResult> {
  const repoRoot = options.repoRoot || findRepoRoot();
  const tokensFile = options.tokensFile
    ? path.resolve(repoRoot, options.tokensFile)
    : path.join(repoRoot, "02_YEU_CAU_CUA_TOI", "tokens.json");
  const outputDir = options.outputDir
    ? path.resolve(repoRoot, options.outputDir)
    : path.join(repoRoot, "02_YEU_CAU_CUA_TOI");
  const designDoc = options.designDoc
    ? path.resolve(repoRoot, options.designDoc)
    : path.join(repoRoot, "02_YEU_CAU_CUA_TOI", "design.md");

  const rawJson = await fs.readFile(tokensFile, "utf8");
  const tokens = JSON.parse(rawJson);

  // Extract semantic colors
  const semColors: Record<string, string> = {};
  if (tokens.semantic?.color && typeof tokens.semantic.color === "object") {
    for (const [key, val] of Object.entries(tokens.semantic.color)) {
      const rawVal =
        (val as any)?.$value !== undefined
          ? (val as any).$value
          : (val as any)?.value !== undefined
          ? (val as any).value
          : val;
      semColors[key] = resolveTokenRef(rawVal, tokens);
    }
  }

  // Fallback to global colors if semantic is missing
  if (tokens.global?.color && typeof tokens.global.color === "object") {
    for (const [key, val] of Object.entries(tokens.global.color)) {
      const rawVal =
        (val as any)?.$value !== undefined
          ? (val as any).$value
          : (val as any)?.value !== undefined
          ? (val as any).value
          : val;
      const resolved = resolveTokenRef(rawVal, tokens);
      if (!semColors[key]) {
        semColors[key] = resolved;
      }
    }
  }

  const defaultColors: Record<string, string> = {
    primary: semColors["primary"] || "#2563eb",
    "primary-hover": semColors["primary-hover"] || "#1d4ed8",
    background: semColors["background"] || "#f8fafc",
    surface: semColors["surface"] || "#ffffff",
    border: semColors["border"] || "#e2e8f0",
    "text-main": semColors["text-main"] || "#0f172a",
    "text-muted": semColors["text-muted"] || "#64748b",
    accent: semColors["accent"] || "#10b981",
    danger: semColors["danger"] || "#ef4444",
    warning: semColors["warning"] || "#f59e0b",
    info: semColors["info"] || "#0284c7",
  };

  // Dimensions from global.dimension
  const dim = tokens.global?.dimension;
  function getDimVal(key: string, fallback: string): string {
    if (!dim || !dim[key]) return fallback;
    const raw =
      dim[key].$value !== undefined
        ? dim[key].$value
        : dim[key].value !== undefined
        ? dim[key].value
        : dim[key];
    const resolved = resolveTokenRef(raw, tokens);
    return extractDtcgValue(resolved) || fallback;
  }

  const radiusSm = getDimVal("radius-sm", "6px");
  const radiusMd = getDimVal("radius-md", "12px");
  const radiusLg = getDimVal("radius-lg", "20px");
  const targetMin = getDimVal("target-min", "48px");

  // Typography dynamically from global.font
  const fontObj = tokens.global?.font || {};
  function getFontVal(key: string, fallback: string): string {
    const entry = fontObj[key];
    if (!entry) return fallback;
    const raw =
      entry.$value !== undefined
        ? entry.$value
        : entry.value !== undefined
        ? entry.value
        : entry;
    const resolved = resolveTokenRef(raw, tokens);
    return extractDtcgValue(resolved) || fallback;
  }

  const fontMain = getFontVal(
    "family-main",
    '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif'
  );
  const fontSizeSm = getFontVal("size-sm", "14px");
  const fontSizeBase = getFontVal("size-base", "16px");
  const fontSizeLg = getFontVal("size-lg", "20px");
  const fontSizeXl = getFontVal("size-xl", "24px");
  const lineHeightBase = getFontVal("line-height-base", "1.5");

  // Motion duration dynamically from global.duration
  const durationObj = tokens.global?.duration || {};
  function getDurationVal(key: string, fallback: string): string {
    const entry = durationObj[key];
    if (!entry) return fallback;
    const raw =
      entry.$value !== undefined
        ? entry.$value
        : entry.value !== undefined
        ? entry.value
        : entry;
    const resolved = resolveTokenRef(raw, tokens);
    return extractDtcgValue(resolved) || fallback;
  }

  const durationFast = getDurationVal("fast", "150ms");
  const durationBase = getDurationVal("base", "250ms");
  const durationSlow = getDurationVal("slow", "400ms");

  await fs.mkdir(outputDir, { recursive: true });
  const generatedFiles: string[] = [];

  // 1. Generate tokens.css (Route A Web Zero-Install)
  const cssLines: string[] = [
    "/**",
    " * REA W3C DTCG Compiled Design Tokens (Route A Web Zero-Install)",
    " * DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json",
    " * Auto-generated by .agents/scripts/compile_tokens.ps1 / rea-kit compile-tokens",
    " */",
    ":root {",
    "  /* Brand & Semantic Colors */",
  ];
  for (const [k, v] of Object.entries(defaultColors)) {
    cssLines.push(`  --color-${k}: ${v};`);
  }
  cssLines.push(
    "",
    "  /* Corner Radius & Touch Targets */",
    `  --radius-sm: ${radiusSm};`,
    `  --radius-md: ${radiusMd};`,
    `  --radius-lg: ${radiusLg};`,
    `  --touch-target-min: ${targetMin};`,
    "",
    "  /* Typography */",
    `  --font-main: ${fontMain};`,
    `  --font-size-sm: ${fontSizeSm};`,
    `  --font-size-base: ${fontSizeBase};`,
    `  --font-size-lg: ${fontSizeLg};`,
    `  --font-size-xl: ${fontSizeXl};`,
    `  --line-height-base: ${lineHeightBase};`,
    "",
    "  /* Motion Tokens */",
    `  --motion-duration-fast: ${durationFast};`,
    `  --motion-duration-base: ${durationBase};`,
    `  --motion-duration-slow: ${durationSlow};`,
    "  --motion-easing-standard: cubic-bezier(0.2, 0, 0, 1);",
    "  --motion-easing-emphasized: cubic-bezier(0.05, 0.7, 0.1, 1);",
    "  --motion-easing-accelerate: cubic-bezier(0.3, 0, 0.8, 0.15);",
    "",
    "  /* Elevation & Shadows */",
    "  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);",
    "  --shadow-card: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);",
    "  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);",
    "}",
    "",
    "/* Ho tro Reduced Motion */",
    "@media (prefers-reduced-motion: reduce) {",
    "  :root {",
    "    --motion-duration-fast: 0.01ms;",
    "    --motion-duration-base: 0.01ms;",
    "    --motion-duration-slow: 0.01ms;",
    "  }",
    "}",
    ""
  );

  const cssOut = path.join(outputDir, "tokens.css");
  await writeUtf8NoBomAtomic(cssOut, cssLines.join("\n"));
  generatedFiles.push(cssOut);

  // 2. Generate Color.kt (Jetpack Compose)
  const colorKtLines: string[] = [
    "package ui.theme",
    "",
    "import androidx.compose.ui.graphics.Color",
    "",
    "/**",
    " * REA W3C DTCG Compiled Color Tokens (Route B Android Native)",
    " * DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json",
    " * Auto-generated by .agents/scripts/compile_tokens.ps1 / rea-kit compile-tokens",
    " */",
    `val Primary = Color(${toComposeColorHex(defaultColors["primary"])})`,
    `val PrimaryHover = Color(${toComposeColorHex(defaultColors["primary-hover"])})`,
    `val Background = Color(${toComposeColorHex(defaultColors["background"])})`,
    `val Surface = Color(${toComposeColorHex(defaultColors["surface"])})`,
    `val Border = Color(${toComposeColorHex(defaultColors["border"])})`,
    `val TextMain = Color(${toComposeColorHex(defaultColors["text-main"])})`,
    `val TextMuted = Color(${toComposeColorHex(defaultColors["text-muted"])})`,
    `val Accent = Color(${toComposeColorHex(defaultColors["accent"])})`,
    `val Danger = Color(${toComposeColorHex(defaultColors["danger"])})`,
    `val Warning = Color(${toComposeColorHex(defaultColors["warning"])})`,
    `val Info = Color(${toComposeColorHex(defaultColors["info"])})`,
    "",
  ];
  const colorKtOut = path.join(outputDir, "Color.kt");
  await writeUtf8NoBomAtomic(colorKtOut, colorKtLines.join("\n"));
  generatedFiles.push(colorKtOut);

  // 3. Generate Type.kt (Jetpack Compose Typography)
  const parseNumOnly = (s: string) => s.replace(/[^0-9.]/g, "");
  const numSm = parseNumOnly(fontSizeSm) || "14";
  const numBase = parseNumOnly(fontSizeBase) || "16";
  const numLg = parseNumOnly(fontSizeLg) || "20";
  const numXl = parseNumOnly(fontSizeXl) || "24";

  const typeKtLines: string[] = [
    "package ui.theme",
    "",
    "import androidx.compose.material3.Typography",
    "import androidx.compose.ui.text.TextStyle",
    "import androidx.compose.ui.text.font.FontFamily",
    "import androidx.compose.ui.text.font.FontWeight",
    "import androidx.compose.ui.unit.sp",
    "",
    "/**",
    " * REA W3C DTCG Compiled Typography Tokens (Route B Android Native)",
    " * DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json",
    " * Auto-generated by .agents/scripts/compile_tokens.ps1 / rea-kit compile-tokens",
    " */",
    "val Typography = Typography(",
    "    bodySmall = TextStyle(",
    "        fontFamily = FontFamily.Default,",
    `        fontSize = ${numSm}.sp,`,
    "        lineHeight = 20.sp",
    "    ),",
    "    bodyLarge = TextStyle(",
    "        fontFamily = FontFamily.Default,",
    `        fontSize = ${numBase}.sp,`,
    "        lineHeight = 24.sp",
    "    ),",
    "    titleLarge = TextStyle(",
    "        fontFamily = FontFamily.Default,",
    `        fontSize = ${numLg}.sp,`,
    "        fontWeight = FontWeight.Bold,",
    "        lineHeight = 28.sp",
    "    ),",
    "    headlineMedium = TextStyle(",
    "        fontFamily = FontFamily.Default,",
    `        fontSize = ${numXl}.sp,`,
    "        fontWeight = FontWeight.Bold,",
    "        lineHeight = 32.sp",
    "    )",
    ")",
    "",
  ];
  const typeKtOut = path.join(outputDir, "Type.kt");
  await writeUtf8NoBomAtomic(typeKtOut, typeKtLines.join("\n"));
  generatedFiles.push(typeKtOut);

  // 4. Generate Shape.kt (Jetpack Compose Shapes)
  const shapeKtLines: string[] = [
    "package ui.theme",
    "",
    "import androidx.compose.foundation.shape.RoundedCornerShape",
    "import androidx.compose.material3.Shapes",
    "import androidx.compose.ui.unit.dp",
    "",
    "/**",
    " * REA W3C DTCG Compiled Shape Tokens (Route B Android Native)",
    " * DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json",
    " * Auto-generated by .agents/scripts/compile_tokens.ps1 / rea-kit compile-tokens",
    " */",
    "val Shapes = Shapes(",
    `    small = RoundedCornerShape(${toAndroidDp(radiusSm)}),`,
    `    medium = RoundedCornerShape(${toAndroidDp(radiusMd)}),`,
    `    large = RoundedCornerShape(${toAndroidDp(radiusLg)})`,
    ")",
    "",
  ];
  const shapeKtOut = path.join(outputDir, "Shape.kt");
  await writeUtf8NoBomAtomic(shapeKtOut, shapeKtLines.join("\n"));
  generatedFiles.push(shapeKtOut);

  // 5. Generate colors.xml (Android Native XML)
  const colorsXmlLines: string[] = [
    '<?xml version="1.0" encoding="utf-8"?>',
    "<!-- REA W3C DTCG Compiled XML Colors (Route B Android Native) -->",
    "<!-- DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json -->",
    "<!-- Auto-generated by .agents/scripts/compile_tokens.ps1 / rea-kit compile-tokens -->",
    "<resources>",
  ];
  for (const [k, v] of Object.entries(defaultColors)) {
    const xmlName = `color_${k.replace(/-/g, "_")}`;
    colorsXmlLines.push(`    <color name="${xmlName}">${toXmlColorHex(v)}</color>`);
  }
  colorsXmlLines.push("</resources>", "");
  const colorsXmlOut = path.join(outputDir, "colors.xml");
  await writeUtf8NoBomAtomic(colorsXmlOut, colorsXmlLines.join("\n"));
  generatedFiles.push(colorsXmlOut);

  // 6. Generate dimens.xml (Android Native XML)
  const dimensXmlLines: string[] = [
    '<?xml version="1.0" encoding="utf-8"?>',
    "<!-- REA W3C DTCG Compiled XML Dimens (Route B Android Native) -->",
    "<!-- DO NOT EDIT DIRECTLY. Source: 02_YEU_CAU_CUA_TOI/tokens.json -->",
    "<!-- Auto-generated by .agents/scripts/compile_tokens.ps1 / rea-kit compile-tokens -->",
    "<resources>",
    `    <dimen name="radius_sm">${toAndroidDp(radiusSm)}</dimen>`,
    `    <dimen name="radius_md">${toAndroidDp(radiusMd)}</dimen>`,
    `    <dimen name="radius_lg">${toAndroidDp(radiusLg)}</dimen>`,
    `    <dimen name="touch_target_min">${toAndroidDp(targetMin)}</dimen>`,
    "</resources>",
    "",
  ];
  const dimensXmlOut = path.join(outputDir, "dimens.xml");
  await writeUtf8NoBomAtomic(dimensXmlOut, dimensXmlLines.join("\n"));
  generatedFiles.push(dimensXmlOut);

  // 7. Sync to 05_MA_NGUON_PHAT_TRIEN (if directories exist)
  const syncedFiles: string[] = [];
  const srcRoot = path.join(repoRoot, "05_MA_NGUON_PHAT_TRIEN");
  try {
    const stat = await fs.stat(srcRoot);
    if (stat.isDirectory()) {
      // Web target
      const webCssDir = path.join(srcRoot, "css");
      try {
        const cssStat = await fs.stat(webCssDir);
        if (cssStat.isDirectory()) {
          const destCss = path.join(webCssDir, "tokens.css");
          await fs.copyFile(cssOut, destCss);
          syncedFiles.push(destCss);
        }
      } catch {
        // css dir does not exist
      }

      // Android Compose target
      const themeDirs = await findDirsRecursively(srcRoot, "theme");
      for (const td of themeDirs) {
        const d1 = path.join(td, "Color.kt");
        const d2 = path.join(td, "Type.kt");
        const d3 = path.join(td, "Shape.kt");
        await fs.copyFile(colorKtOut, d1);
        await fs.copyFile(typeKtOut, d2);
        await fs.copyFile(shapeKtOut, d3);
        syncedFiles.push(d1, d2, d3);
      }

      // Android Res Values target
      const valDirs = await findDirsRecursively(srcRoot, "values");
      for (const vd of valDirs) {
        const d1 = path.join(vd, "colors.xml");
        const d2 = path.join(vd, "dimens.xml");
        await fs.copyFile(colorsXmlOut, d1);
        await fs.copyFile(dimensXmlOut, d2);
        syncedFiles.push(d1, d2);
      }
    }
  } catch {
    // 05_MA_NGUON_PHAT_TRIEN does not exist
  }

  // 8. Update preview blocks in design.md
  let updatedDesignDoc = false;
  try {
    let designContent = await fs.readFile(designDoc, "utf8");
    const fences = "```";

    // 8.1 CSS block
    const previewCssBlock = [
      `${fences}css`,
      ":root {",
      "  /* Mau thuong hieu & Nut chinh */",
      `  --color-primary: ${defaultColors["primary"]};         /* Xanh duong hien dai */`,
      `  --color-primary-hover: ${defaultColors["primary-hover"]};   /* Mau di chuot vao nut */`,
      "  ",
      "  /* Nen trang & Be mat khung */",
      `  --color-background: ${defaultColors["background"]};      /* Nen xam nhat diu mat */`,
      `  --color-surface: ${defaultColors["surface"]};         /* Nen trang cho the va bang */`,
      `  --color-border: ${defaultColors["border"]};          /* Duong vien ngan cach */`,
      "  ",
      "  /* Mau chu */",
      `  --color-text-main: ${defaultColors["text-main"]};       /* Chu den dam de doc */`,
      `  --color-text-muted: ${defaultColors["text-muted"]};      /* Chu phu xam mo */`,
      "  ",
      "  /* Mau trang thai */",
      `  --color-accent: ${defaultColors["accent"]};          /* Xanh la: Thanh cong */`,
      `  --color-danger: ${defaultColors["danger"]};          /* Do: Xoa, Loi */`,
      `  --color-warning: ${defaultColors["warning"]};         /* Vang: Canh bao */`,
      `  --color-info: ${defaultColors["info"]};            /* Xanh duong nhat: Chi dan */`,
      "  ",
      "  /* Kich thuoc & Bo goc */",
      `  --radius-sm: ${radiusSm};`,
      `  --radius-md: ${radiusMd};`,
      `  --radius-lg: ${radiusLg};`,
      `  --touch-target-min: ${targetMin};`,
      "  ",
      "  /* Do bong & Nang be mat (Elevation) */",
      "  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);",
      "  --shadow-card: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);",
      "  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);",
      "}",
      fences,
    ].join("\n");

    if (/#### a\) Web CSS Tokens \(Route A\)[\s\S]*?```css[\s\S]*?```/.test(designContent)) {
      designContent = designContent.replace(
        /#### a\) Web CSS Tokens \(Route A\)[\s\S]*?```css[\s\S]*?```/,
        `#### a) Web CSS Tokens (Route A)\n${previewCssBlock}`
      );
    }

    // 8.2 Compose Color block
    const previewComposeBlock = [
      `${fences}kotlin`,
      "// Jetpack Compose Color Tokens (ui/theme/Color.kt)",
      `val PrimaryColor = Color(${toComposeColorHex(defaultColors["primary"])})`,
      `val PrimaryHoverColor = Color(${toComposeColorHex(defaultColors["primary-hover"])})`,
      `val BackgroundColor = Color(${toComposeColorHex(defaultColors["background"])})`,
      `val SurfaceColor = Color(${toComposeColorHex(defaultColors["surface"])})`,
      `val BorderColor = Color(${toComposeColorHex(defaultColors["border"])})`,
      `val TextMainColor = Color(${toComposeColorHex(defaultColors["text-main"])})`,
      `val TextMutedColor = Color(${toComposeColorHex(defaultColors["text-muted"])})`,
      `val AccentColor = Color(${toComposeColorHex(defaultColors["accent"])})`,
      `val DangerColor = Color(${toComposeColorHex(defaultColors["danger"])})`,
      `val WarningColor = Color(${toComposeColorHex(defaultColors["warning"])})`,
      `val InfoColor = Color(${toComposeColorHex(defaultColors["info"])})`,
      fences,
    ].join("\n");

    if (/```kotlin\s*\/\/\s*Jetpack Compose Color Tokens[\s\S]*?```/.test(designContent)) {
      designContent = designContent.replace(
        /```kotlin\s*\/\/\s*Jetpack Compose Color Tokens[\s\S]*?```/,
        previewComposeBlock
      );
    }

    // 8.3 XML Colors block
    const previewXmlColors = [
      `${fences}xml`,
      "<!-- Android XML Color Tokens (res/values/colors.xml) -->",
      "<resources>",
      ...Object.entries(defaultColors).map(
        ([k, v]) => `    <color name="color_${k.replace(/-/g, "_")}">${toXmlColorHex(v)}</color>`
      ),
      "</resources>",
      fences,
    ].join("\n");

    if (/```xml\s*<!-- Android XML Color Tokens[\s\S]*?```/.test(designContent)) {
      designContent = designContent.replace(
        /```xml\s*<!-- Android XML Color Tokens[\s\S]*?```/,
        previewXmlColors
      );
    }

    // 8.4 Compose Shapes block
    const previewShapeBlock = [
      `${fences}kotlin`,
      "// Jetpack Compose Shapes (ui/theme/Shape.kt)",
      "val Shapes = Shapes(",
      `    small = RoundedCornerShape(${toAndroidDp(radiusSm)}),`,
      `    medium = RoundedCornerShape(${toAndroidDp(radiusMd)}),`,
      `    large = RoundedCornerShape(${toAndroidDp(radiusLg)})`,
      ")",
      fences,
    ].join("\n");

    if (/```kotlin\s*\/\/\s*Jetpack Compose Shapes[\s\S]*?```/.test(designContent)) {
      designContent = designContent.replace(
        /```kotlin\s*\/\/\s*Jetpack Compose Shapes[\s\S]*?```/,
        previewShapeBlock
      );
    }

    // 8.5 XML Dimens block
    const previewDimensBlock = [
      `${fences}xml`,
      "<!-- Android XML Dimens (res/values/dimens.xml) -->",
      "<resources>",
      `    <dimen name="radius_sm">${toAndroidDp(radiusSm)}</dimen>`,
      `    <dimen name="radius_md">${toAndroidDp(radiusMd)}</dimen>`,
      `    <dimen name="radius_lg">${toAndroidDp(radiusLg)}</dimen>`,
      `    <dimen name="touch_target_min">${toAndroidDp(targetMin)}</dimen>`,
      "</resources>",
      fences,
    ].join("\n");

    if (/```xml\s*<!-- Android XML Dimens[\s\S]*?```/.test(designContent)) {
      designContent = designContent.replace(
        /```xml\s*<!-- Android XML Dimens[\s\S]*?```/,
        previewDimensBlock
      );
    }

    await writeUtf8NoBomAtomic(designDoc, designContent);
    updatedDesignDoc = true;
  } catch {
    // designDoc does not exist or cannot be read; optional step
  }

  return {
    success: true,
    tokensFile,
    outputDir,
    generatedFiles,
    syncedFiles,
    updatedDesignDoc,
    colors: defaultColors,
    dimensions: {
      radiusSm,
      radiusMd,
      radiusLg,
      targetMin,
    },
    typography: {
      fontMain,
      fontSizeSm,
      fontSizeBase,
      fontSizeLg,
      fontSizeXl,
      lineHeightBase,
    },
    duration: {
      fast: durationFast,
      base: durationBase,
      slow: durationSlow,
    },
  };
}
