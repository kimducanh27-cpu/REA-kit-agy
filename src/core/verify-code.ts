import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";
import vm from "node:vm";
import { findRepoRoot } from "./workspace.js";

export interface VerifyCodeOptions {
  repoRoot?: string;
  targetDir?: string;
  reportDir?: string;
  allowHighRisk?: boolean;
}

export interface VerifyCodeResult {
  success: boolean;
  riskLevel: "LOW" | "MEDIUM" | "HIGH";
  errors: string[];
  warnings: string[];
  summary: string;
  details: {
    entryFiles: string[];
    isAndroidProject: boolean;
    scannedFiles: number;
    pairsChecked: number;
    highRiskIndicators: string[];
    mediumRiskIndicators: string[];
  };
}

export function removeCommentsAndStrings(code: string): string {
  if (!code) return "";
  const pattern =
    /(\/\*[\s\S]*?\*\/)|(\/\/[^\r\n]*)|("""[\s\S]*?""")|("(?:\\.|[^"\\\r\n])*")|('(?:\\.|[^'\\\r\n])*')|(`(?:\\.|[^`\\])*`)/g;
  return code.replace(pattern, (_match, cBlock, cLine) => {
    if (cBlock || cLine) return "";
    return '""';
  });
}

export function removeCommentsOnly(code: string): string {
  if (!code) return "";
  const pattern =
    /(\/\*[\s\S]*?\*\/)|(\/\/[^\r\n]*)|(<!--[\s\S]*?-->)|("""[\s\S]*?""")|("(?:\\.|[^"\\\r\n])*")|('(?:\\.|[^'\\\r\n])*')|(`(?:\\.|[^`\\])*`)/g;
  return code.replace(pattern, (match, cBlock, cLine, cHtml) => {
    if (cBlock || cLine || cHtml) return "";
    return match;
  });
}

export function hasEsmSyntax(code: string): boolean {
  if (!code) return false;
  const clean = removeCommentsAndStrings(code);
  if (/(?:^|[;\n])\s*import\s+(?:(?:[\w*\s{},]+)\s+from\s+)?['"][^'"]*['"]/m.test(clean)) {
    return true;
  }
  if (/(?:^|[;\n])\s*export\s+(?:default\b|\*|\{|\b(?:const|let|var|function|class|async)\b)/m.test(clean)) {
    return true;
  }
  // Top-level await
  if (
    /(?:^|\n)\s*(?:const|let|var)\s+[\w$]+\s*=\s*await\s+/.test(clean) ||
    /(?:^|[;\n])\s*await\s+[\w$([{]/m.test(clean)
  ) {
    return true;
  }
  // import.meta
  if (/\bimport\.meta\b/.test(clean)) {
    return true;
  }
  // Dynamic import()
  if (/\bimport\s*\(/.test(clean)) {
    return true;
  }
  return false;
}

export function getShannonEntropy(str: string): number {
  if (!str) return 0.0;
  const freq = new Map<string, number>();
  for (const ch of str) {
    freq.set(ch, (freq.get(ch) || 0) + 1);
  }
  let entropy = 0.0;
  const len = str.length;
  for (const count of freq.values()) {
    const p = count / len;
    entropy -= p * Math.log2(p);
  }
  return entropy;
}

export function convertHexToRgb(
  hex: string
): { r: number; g: number; b: number } | null {
  if (!hex || typeof hex !== "string") return null;
  const clean = hex.trim().replace(/^#/, "");
  // Validate hex characters and valid lengths (3, 4, 6, 8)
  if (!/^[0-9a-fA-F]{3,4}$|^[0-9a-fA-F]{6}$|^[0-9a-fA-F]{8}$/.test(clean)) {
    return null;
  }
  if (clean.length === 3 || clean.length === 4) {
    const r = parseInt(clean[0] + clean[0], 16);
    const g = parseInt(clean[1] + clean[1], 16);
    const b = parseInt(clean[2] + clean[2], 16);
    if (isNaN(r) || isNaN(g) || isNaN(b)) return null;
    return { r, g, b };
  } else if (clean.length >= 6) {
    const r = parseInt(clean.substring(0, 2), 16);
    const g = parseInt(clean.substring(2, 4), 16);
    const b = parseInt(clean.substring(4, 6), 16);
    if (isNaN(r) || isNaN(g) || isNaN(b)) return null;
    return { r, g, b };
  }
  return null;
}

export function getRelativeLuminance(rgb: {
  r: number;
  g: number;
  b: number;
}): number {
  if (!rgb || isNaN(rgb.r) || isNaN(rgb.g) || isNaN(rgb.b)) {
    return 0;
  }
  const channels = [rgb.r, rgb.g, rgb.b];
  const linear = channels.map((c) => {
    const s = Math.max(0, Math.min(255, c)) / 255.0;
    // IEC 61966-2-1 / WCAG 2.1 Errata threshold update: 0.04045
    return s <= 0.04045 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
  });
  const lum = 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2];
  return isNaN(lum) ? 0 : lum;
}

export function getWcagContrastRatio(hex1: string, hex2: string): number {
  const rgb1 = convertHexToRgb(hex1);
  const rgb2 = convertHexToRgb(hex2);
  if (!rgb1 || !rgb2) return 0.0;
  const l1 = getRelativeLuminance(rgb1);
  const l2 = getRelativeLuminance(rgb2);
  if (isNaN(l1) || isNaN(l2)) return 0.0;
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  const ratio = Math.round(((lighter + 0.05) / (darker + 0.05)) * 100) / 100;
  return isNaN(ratio) ? 0.0 : ratio;
}

async function getAllFiles(
  dir: string,
  filter?: (filePath: string) => boolean
): Promise<string[]> {
  const results: string[] = [];
  try {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        const sub = await getAllFiles(fullPath, filter);
        results.push(...sub);
      } else if (entry.isFile()) {
        if (!filter || filter(fullPath)) {
          results.push(fullPath);
        }
      }
    }
  } catch {
    // Ignore missing dirs
  }
  return results;
}

const BACKUP_PATH_REGEX = /[\\/]\.backup[\\/]/i;

function isExcludedFile(filePath: string): boolean {
  if (BACKUP_PATH_REGEX.test(filePath)) return true;
  if (path.basename(filePath) === ".gitkeep") return true;
  return false;
}

function isTokenFileName(name: string): boolean {
  const lower = name.toLowerCase();
  const tokenNames = [
    "tokens.css",
    "tokens.json",
    "color.kt",
    "colors.xml",
    "dimens.xml",
    "type.kt",
    "shape.kt",
    "design.md",
  ];
  return tokenNames.includes(lower) || lower.includes("token");
}

export async function verifyCode(
  options: VerifyCodeOptions = {}
): Promise<VerifyCodeResult> {
  const repoRoot = options.repoRoot || findRepoRoot();
  const targetDir = options.targetDir
    ? path.resolve(repoRoot, options.targetDir)
    : path.join(repoRoot, "05_MA_NGUON_PHAT_TRIEN");
  const reportDir = options.reportDir
    ? path.resolve(repoRoot, options.reportDir)
    : path.join(repoRoot, "03_KET_QUA_KIEM_TRA");
  const allowHighRisk = options.allowHighRisk ?? false;

  const errors: string[] = [];
  const warnings: string[] = [];

  // 0. Verify TargetDir exists and not empty
  let allTargetFiles: string[] = [];
  try {
    const stat = await fs.stat(targetDir);
    if (!stat.isDirectory()) {
      errors.push(`Target directory is not a directory: ${targetDir}`);
    } else {
      allTargetFiles = await getAllFiles(targetDir, (f) => !isExcludedFile(f));
    }
  } catch {
    errors.push(`Target directory does not exist: ${targetDir}`);
  }

  if (errors.length > 0) {
    return {
      success: false,
      riskLevel: "LOW",
      errors,
      warnings,
      summary: errors.join("; "),
      details: {
        entryFiles: [],
        isAndroidProject: false,
        scannedFiles: 0,
        pairsChecked: 0,
        highRiskIndicators: [],
        mediumRiskIndicators: [],
      },
    };
  }

  if (allTargetFiles.length === 0) {
    warnings.push(`Target directory is empty or only has .gitkeep: ${targetDir}`);
    return {
      success: true,
      riskLevel: "LOW",
      errors: [],
      warnings,
      summary: "Target directory is empty (clean workspace, no code to verify)",
      details: {
        entryFiles: [],
        isAndroidProject: false,
        scannedFiles: 0,
        pairsChecked: 0,
        highRiskIndicators: [],
        mediumRiskIndicators: [],
      },
    };
  }

  // 1. Check entry files & architecture
  const htmlFiles = allTargetFiles.filter((f) => f.toLowerCase().endsWith(".html"));
  const androidManifests = allTargetFiles.filter(
    (f) => path.basename(f).toLowerCase() === "androidmanifest.xml"
  );
  const gradleFiles = allTargetFiles.filter((f) =>
    path.basename(f).toLowerCase().includes("build.gradle")
  );
  const isAndroidProject = androidManifests.length > 0 || gradleFiles.length > 0;

  if (htmlFiles.length === 0 && !isAndroidProject) {
    warnings.push("No .html or Android project files found for direct execution.");
  }

  // 2. HTML syntax & basic tag pairs
  for (const htmlPath of htmlFiles) {
    const content = await fs.readFile(htmlPath, "utf8");
    const basicTags = ["html", "head", "body"];
    for (const tag of basicTags) {
      const openRegex = new RegExp(`<${tag}\\b`, "i");
      const closeRegex = new RegExp(`</${tag}\\s*>`, "i");
      if (openRegex.test(content) && !closeRegex.test(content)) {
        errors.push(`HTML file ${path.basename(htmlPath)} is missing closing tag </${tag}>`);
      }
    }
  }

  // 3. JavaScript syntax (external .js and inline <script>)
  const jsFiles = allTargetFiles.filter((f) => f.toLowerCase().endsWith(".js"));
  function validateJsCode(code: string, sourceLabel: string, isModule = false): void {
    if (!code || !code.trim()) return;
    if (isModule || hasEsmSyntax(code)) {
      // ESM syntax (import/export/top-level await) or <script type="module"> is not supported by vm.Script.
      // Skip passing to vm.Script to prevent false-positive syntax errors.
      return;
    }
    try {
      new vm.Script(code, { filename: sourceLabel });
    } catch (err: any) {
      errors.push(`JavaScript syntax error in ${sourceLabel}: ${err.message}`);
    }
  }

  for (const jsPath of jsFiles) {
    const content = await fs.readFile(jsPath, "utf8");
    validateJsCode(content, path.basename(jsPath));
  }

  for (const htmlPath of htmlFiles) {
    const content = await fs.readFile(htmlPath, "utf8");
    const scriptRegex = /<script\b([^>]*)>([\s\S]*?)<\/script>/gi;
    let match: RegExpExecArray | null;
    let blockIdx = 0;
    while ((match = scriptRegex.exec(content)) !== null) {
      const attrs = match[1] || "";
      const inlineJs = match[2];
      if (/\bsrc\s*=/i.test(attrs)) continue;
      if (
        /\btype\s*=\s*["'](?:application\/json|application\/ld\+json|importmap|text\/template)["']/i.test(
          attrs
        )
      ) {
        continue;
      }
      blockIdx++;
      const isModule = /\btype\s*=\s*["']module["']/i.test(attrs);
      if (inlineJs && inlineJs.trim()) {
        validateJsCode(
          inlineJs,
          `${path.basename(htmlPath)} [inline <script #${blockIdx}>]`,
          isModule
        );
      }
    }
  }

  // 4. Secret & API key leaks scanner
  const leakPatterns = [
    /sk-[a-zA-Z0-9_-]{20,}/,
    /sk-ant-[a-zA-Z0-9_-]{20,}/,
    /(?:ghp|gho|ghu|ghs|ghr|github_pat)_[0-9a-zA-Z_]{36,}/,
    /AIza[0-9A-Za-z\-_]{35}/,
    /AKIA[0-9A-Z]{16}/,
    /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/,
    /eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/,
    /(?:password|passwd|pwd|api[_-]?key|secret[_-]?key|access[_-]?token|auth[_-]?token|storePassword|keyPassword)\s*[:=]\s*["'](?!\[REDACTED\]|YOUR_|REPLACE_|TODO|EXAMPLE|<|\$\{)[^"'\r\n]{6,}["']/i,
  ];

  const checkExts = [
    ".html",
    ".js",
    ".ts",
    ".json",
    ".py",
    ".env",
    ".kt",
    ".kts",
    ".java",
    ".xml",
    ".gradle",
    ".properties",
    ".toml",
    ".yaml",
    ".yml",
    ".smali",
    ".md",
  ];

  const filesToScanSecrets = [...allTargetFiles].filter((f) => {
    const ext = path.extname(f).toLowerCase();
    const base = path.basename(f).toLowerCase();
    if (base.endsWith(".min.js")) return false;
    return checkExts.includes(ext) || base.includes(".gradle") || base.startsWith(".env");
  });

  const reportFiles = await getAllFiles(reportDir, (f) => {
    const ext = path.extname(f).toLowerCase();
    const base = path.basename(f).toLowerCase();
    if (base.endsWith(".min.js")) return false;
    return !isExcludedFile(f) && checkExts.includes(ext);
  });
  filesToScanSecrets.push(...reportFiles);

  for (const filePath of filesToScanSecrets) {
    if (path.basename(filePath).toLowerCase().endsWith(".min.js")) continue;
    let text = "";
    try {
      text = await fs.readFile(filePath, "utf8");
    } catch {
      continue;
    }
    if (!text) continue;

    // Strip all Data URIs and sourceMappingURL comments before scanning to eliminate sourcemap false positives
    text = text.replace(/data:[a-zA-Z0-9+.-]+\/[a-zA-Z0-9+.-]+;base64,[A-Za-z0-9+/=]+/gi, "");
    text = text.replace(/\/\/#\s*sourceMappingURL=[^\r\n]+/g, "");
    if (!text.trim()) continue;

    // 4.1 Raw regex pattern matches
    for (const pat of leakPatterns) {
      if (pat.test(text)) {
        errors.push(
          `Secret leak detected in ${path.basename(filePath)} (pattern: ${pat})`
        );
      }
    }

    // 4.2 Base64-encoded secrets (limit candidate length to 24..512 chars)
    const base64Candidates = text.match(/\b[A-Za-z0-9+/]{24,512}={0,2}\b/g) || [];
    for (const cand of base64Candidates) {
      if (cand.length < 24 || cand.length > 512) continue;
      try {
        const decoded = Buffer.from(cand, "base64").toString("utf8");
        if (decoded && decoded.length >= 16) {
          for (const pat of leakPatterns) {
            if (pat.test(decoded)) {
              const candSha = crypto.createHash("sha256").update(cand).digest("hex");
              errors.push(
                `Base64 secret leak in ${path.basename(filePath)} ([REDACTED_SECRET_CANDIDATE: sha256=${candSha}])`
              );
              break;
            }
          }
        }
      } catch {
        // Ignore invalid base64
      }
    }

    // 4.3 High-entropy string assigned to secret keys
    const assignedSecretRegex =
      /(?:password|passwd|pwd|api[_-]?key|secret[_-]?key|access[_-]?token|auth[_-]?token)\s*[:=]\s*["']([^"'\r\n]{16,})["']/gi;
    let asmMatch: RegExpExecArray | null;
    while ((asmMatch = assignedSecretRegex.exec(text)) !== null) {
      const val = asmMatch[1];
      if (
        !/\[REDACTED\]|YOUR_|REPLACE_|TODO|EXAMPLE|<|\${|null|false|true|\*\*\*/i.test(
          val
        )
      ) {
        const entropy = getShannonEntropy(val);
        if (entropy >= 4.5) {
          errors.push(
            `High-entropy secret (${entropy.toFixed(2)}) in ${path.basename(filePath)}`
          );
        }
      }
    }

    // 4.4 Secret hex byte array
    if (
      /(?:key|secret|token|aes|cipher)\w*\s*[:=]\s*(?:new\s+byte\[\]\s*)?\{\s*(?:0x[0-9a-f]{1,2}\s*,\s*){15,}0x[0-9a-f]{1,2}\s*\}/i.test(
        text
      )
    ) {
      errors.push(
        `Secret hex byte array detected in ${path.basename(filePath)}`
      );
    }
  }

  // 5. Automated risk classifier
  let riskLevel: "LOW" | "MEDIUM" | "HIGH" = "LOW";
  const highRiskIndicators: string[] = [];
  const mediumRiskIndicators: string[] = [];

  const codeFilesToCheck = allTargetFiles.filter(
    (f) => path.extname(f).toLowerCase() !== ".md"
  );

  for (const f of codeFilesToCheck) {
    let rawCode = "";
    try {
      rawCode = await fs.readFile(f, "utf8");
    } catch {
      continue;
    }
    if (!rawCode) continue;

    const codeNoComments = removeCommentsOnly(rawCode);
    const fname = path.basename(f);

    if (/\bfetch\s*\(/.test(codeNoComments)) highRiskIndicators.push(`${fname}: fetch() call`);
    if (/\bXMLHttpRequest\b/.test(codeNoComments))
      highRiskIndicators.push(`${fname}: XMLHttpRequest call`);
    if (/\bWebSocket\b/.test(codeNoComments))
      highRiskIndicators.push(`${fname}: WebSocket connection`);
    if (
      /\beval\s*\(/.test(codeNoComments) ||
      /\bnew\s+Function\s*\(/.test(codeNoComments) ||
      /\bwindow\.Function\s*\(/.test(codeNoComments)
    ) {
      highRiskIndicators.push(`${fname}: Dynamic code execution eval()/Function()`);
    }
    if (/\b(?:OkHttpClient|Retrofit|HttpURLConnection)\b/.test(codeNoComments)) {
      highRiskIndicators.push(`${fname}: Android network call`);
    }
    if (
      /\b(?:Runtime\.getRuntime\(\)\.exec|ProcessBuilder|DexClassLoader)\b/.test(
        codeNoComments
      )
    ) {
      highRiskIndicators.push(`${fname}: Process execution / dynamic class loading`);
    }
    if (
      /http:\/\/(?!www\.w3\.org\/|schemas\.android\.com\/|schemas\.openxmlformats\.org\/|localhost|127\.0\.0\.1)/.test(
        codeNoComments
      )
    ) {
      highRiskIndicators.push(`${fname}: Insecure cleartext HTTP`);
    }

    if (/\blocalStorage\b/.test(codeNoComments))
      mediumRiskIndicators.push(`${fname}: localStorage access`);
    if (/\bsessionStorage\b/.test(codeNoComments))
      mediumRiskIndicators.push(`${fname}: sessionStorage access`);
    if (/\bindexedDB\b/.test(codeNoComments))
      mediumRiskIndicators.push(`${fname}: indexedDB access`);
    if (
      /\b(?:SharedPreferences|Room\.databaseBuilder|SQLiteOpenHelper)\b/.test(
        codeNoComments
      )
    ) {
      mediumRiskIndicators.push(`${fname}: Android local storage`);
    }
    if (/addEventListener\s*\(\s*['"]submit['"]/.test(codeNoComments)) {
      mediumRiskIndicators.push(`${fname}: Form submit handler`);
    }
  }

  if (highRiskIndicators.length > 0) {
    riskLevel = "HIGH";
    if (!allowHighRisk) {
      errors.push(
        `High risk indicators detected without --allow-high-risk: ${highRiskIndicators.join(", ")}`
      );
    } else {
      warnings.push(`High risk indicators allowed by flag: ${highRiskIndicators.join(", ")}`);
    }
  } else if (mediumRiskIndicators.length > 0) {
    riskLevel = "MEDIUM";
  }

  // 6. Android Project structure check
  if (isAndroidProject) {
    for (const manifestPath of androidManifests) {
      const content = await fs.readFile(manifestPath, "utf8");
      if (!/<manifest\b/i.test(content)) {
        errors.push(`AndroidManifest.xml (${path.basename(manifestPath)}) is missing root <manifest> tag`);
      }
    }

    for (const gradlePath of gradleFiles) {
      const content = await fs.readFile(gradlePath, "utf8");
      const clean = removeCommentsAndStrings(content);
      const openCount = (clean.match(/\{/g) || []).length;
      const closeCount = (clean.match(/\}/g) || []).length;
      if (openCount !== closeCount) {
        errors.push(
          `Gradle file ${path.basename(gradlePath)} has unbalanced braces: {${openCount} open, ${closeCount} close}`
        );
      }
    }
  }

  // 7. Token drift & Route A offline
  const uiFiles = allTargetFiles.filter((f) => {
    const ext = path.extname(f).toLowerCase();
    return [".html", ".css", ".js", ".ts", ".kt", ".java", ".xml"].includes(ext);
  });

  for (const f of uiFiles) {
    const content = await fs.readFile(f, "utf8");
    if (!content.trim()) continue;
    const clean = removeCommentsOnly(content);
    const fname = path.basename(f);
    const ext = path.extname(f).toLowerCase();

    // 7.1 Check Route A external CDNs
    if (htmlFiles.length > 0 && [".html", ".css", ".js"].includes(ext)) {
      const cdnPatterns = [
        /https?:\/\/(?:cdn\.|cdnjs\.|unpkg\.|cdn\.jsdelivr\.net|maxcdn\.|stackpath\.|fonts\.googleapis\.com|fonts\.gstatic\.com|cdn\.tailwindcss\.com)/i,
        /<(?:script|link)\b[^>]*(?:src|href)\s*=\s*["']https?:\/\//i,
        /@import\s+(?:url\s*\(\s*["']?https?:\/\/|["']https?:\/\/)/i,
      ];
      for (const cp of cdnPatterns) {
        if (cp.test(clean)) {
          errors.push(`Route A offline violation: External CDN detected in ${fname}`);
        }
      }
    }

    // 7.2 Hardcoded colors check (Token Drift)
    if (!isTokenFileName(fname)) {
      if ([".css", ".html", ".js", ".ts"].includes(ext)) {
        const hexMatch = clean.match(
          /(?:color|background|border|fill|stroke)\s*:\s*(#[0-9a-fA-F]{3,8})\b/i
        );
        if (hexMatch) {
          errors.push(
            `Token Drift in ${fname}: Hardcoded hex color '${hexMatch[1]}'`
          );
        }
        const rgbMatch = clean.match(
          /(?:color|background|border|fill|stroke)\s*:\s*(rgba?\s*\([^)]+\))/i
        );
        if (rgbMatch) {
          errors.push(
            `Token Drift in ${fname}: Hardcoded rgb color '${rgbMatch[1]}'`
          );
        }
      } else if ([".kt", ".java"].includes(ext)) {
        const nativeColorMatch = clean.match(
          /\b(?:Color\s*\(\s*0x[0-9a-fA-F]{6,8}\b|Color\s*\.\s*(?:parseColor|rgb|argb)\s*\()/i
        );
        if (nativeColorMatch) {
          errors.push(
            `Token Drift in ${fname}: Hardcoded native color '${nativeColorMatch[0]}'`
          );
        }
      } else if (ext === ".xml" && fname !== "colors.xml") {
        const xmlColorMatch = clean.match(
          /(?:android:(?:textColor|background|tint|color)|app:(?:tint|backgroundTint))\s*=\s*["'](#[0-9a-fA-F]{3,8})["']/i
        );
        if (xmlColorMatch) {
          errors.push(
            `Token Drift in ${fname}: Hardcoded XML color '${xmlColorMatch[1]}'`
          );
        }
      }
    }
  }

  // 8. WCAG AA Semantic Contrast check (>= 4.5:1)
  const colorMap: Record<string, string> = {};
  const tokenCandidateFiles = allTargetFiles.filter((f) => isTokenFileName(path.basename(f)));
  const specDir = path.join(repoRoot, "02_YEU_CAU_CUA_TOI");
  try {
    const specEntries = await fs.readdir(specDir);
    for (const entry of specEntries) {
      if (entry.toLowerCase().includes("token") || entry.toLowerCase() === "design.md") {
        tokenCandidateFiles.push(path.join(specDir, entry));
      }
    }
  } catch {
    // Ignore missing spec dir
  }

  function extractDtcgTokens(obj: any, currentPath = ""): Record<string, string> {
    const out: Record<string, string> = {};
    if (!obj || typeof obj !== "object") return out;

    let val: any = null;
    let hasVal = false;
    if ("$value" in obj) {
      val = obj.$value;
      hasVal = true;
    } else if ("value" in obj) {
      val = obj.value;
      hasVal = true;
    }

    if (hasVal) {
      if (typeof val === "string") {
        out[currentPath] = val;
        return out;
      } else if (val && typeof val === "object") {
        if (typeof val.hex === "string") {
          out[currentPath] = val.hex;
          return out;
        }
        if (Array.isArray(val.components) && val.components.length >= 3) {
          const toHex = (n: number) => {
            const num = Number(n);
            const val = Number.isNaN(num) ? 0 : num;
            const clamped = Math.max(0, Math.min(255, Math.round(val * 255)));
            return clamped.toString(16).padStart(2, "0");
          };
          const r = toHex(val.components[0]);
          const g = toHex(val.components[1]);
          const b = toHex(val.components[2]);
          if (val.components.length >= 4 && val.components[3] !== undefined) {
            out[currentPath] = `#${r}${g}${b}${toHex(val.components[3])}`;
          } else if (val.alpha !== undefined && val.alpha !== null) {
            out[currentPath] = `#${r}${g}${b}${toHex(val.alpha)}`;
          } else {
            out[currentPath] = `#${r}${g}${b}`;
          }
          return out;
        }
      }
    }

    for (const [k, v] of Object.entries(obj)) {
      if (k.startsWith("$")) continue;
      const childPath = currentPath ? `${currentPath}.${k}` : k;
      if (v && typeof v === "object") {
        Object.assign(out, extractDtcgTokens(v, childPath));
      }
    }
    return out;
  }

  for (const tf of tokenCandidateFiles) {
    let tText = "";
    try {
      tText = await fs.readFile(tf, "utf8");
    } catch {
      continue;
    }
    if (!tText.trim()) continue;

    if (tf.toLowerCase().endsWith(".json")) {
      try {
        const jsonObj = JSON.parse(tText);
        const dtcg = extractDtcgTokens(jsonObj);

        // Resolve aliases up to 10 passes
        for (let pass = 0; pass < 10; pass++) {
          let hasUnresolved = false;
          for (const [k, v] of Object.entries(dtcg)) {
            const m = v.match(/^\{([^}]+)\}$/);
            if (m) {
              const ref = m[1].trim();
              if (dtcg[ref] && !dtcg[ref].startsWith("{")) {
                dtcg[k] = dtcg[ref];
              } else {
                hasUnresolved = true;
              }
            }
          }
          if (!hasUnresolved) break;
        }

        for (const [k, v] of Object.entries(dtcg)) {
          if (/^#[0-9a-fA-F]{3,8}$/.test(v)) {
            const kLower = k.toLowerCase();
            colorMap[kLower] = v;

            // Fix Leaf-Key Collision (P0): In DTCG token extraction, ONLY map leaf/short keys
            // from semantic.color.* or global.color.*. NEVER allow component.* (e.g.
            // component.button.primary.background, component.card.background) to overwrite short-key colorMap["background"].
            if (!kLower.startsWith("component.")) {
              const semMatch = k.match(/^semantic\.color\.(.+)$/i);
              if (semMatch) {
                const subKey = semMatch[1].toLowerCase();
                colorMap[subKey] = v;
                if (subKey.includes(".")) {
                  colorMap[subKey.replace(/\./g, "-")] = v;
                  const leaf = subKey.substring(subKey.lastIndexOf(".") + 1);
                  colorMap[leaf] = v;
                }
              }

              const globMatch = k.match(/^global\.color\.(.+)$/i);
              if (globMatch) {
                const subKey = globMatch[1].toLowerCase();
                colorMap[subKey] = v;
                if (subKey.includes(".")) {
                  colorMap[subKey.replace(/\./g, "-")] = v;
                  const leaf = subKey.substring(subKey.lastIndexOf(".") + 1);
                  colorMap[leaf] = v;
                }
              }

              if (!k.includes(".")) {
                colorMap[kLower] = v;
              }
            }
          }
        }
      } catch {
        // Ignore json parse error
      }
    }

    const cssMatches = tText.matchAll(/--([a-zA-Z0-9_-]+)\s*:\s*(#[0-9a-fA-F]{3,8})/g);
    for (const m of cssMatches) {
      colorMap[m[1].toLowerCase()] = m[2];
    }

    const xmlMatches = tText.matchAll(/<color\s+name=["']([^"']+)["']>(#[0-9a-fA-F]{3,8})<\/color>/gi);
    for (const m of xmlMatches) {
      colorMap[m[1].toLowerCase()] = m[2];
    }
  }

  const semanticPairs: Array<{ text: string; bg: string }> = [
    { text: "text-main", bg: "background" },
    { text: "text-main", bg: "surface" },
    { text: "text-muted", bg: "background" },
    { text: "text-muted", bg: "surface" },
    { text: "foreground", bg: "background" },
    { text: "foreground", bg: "surface" },
    { text: "on-background", bg: "background" },
    { text: "on-surface", bg: "surface" },
    { text: "on-primary", bg: "primary" },
    { text: "on-danger", bg: "danger" },
    { text: "on-success", bg: "accent" },
    { text: "on-info", bg: "info" },
    { text: "component.button.primary.color", bg: "component.button.primary.background" },
  ];

  let pairsChecked = 0;
  for (const pair of semanticPairs) {
    const tKey = pair.text.toLowerCase();
    const bKey = pair.bg.toLowerCase();
    if (colorMap[tKey] && colorMap[bKey]) {
      const textColor = colorMap[tKey];
      const bgColor = colorMap[bKey];
      if (textColor && bgColor && textColor.toLowerCase() !== bgColor.toLowerCase()) {
        const ratio = getWcagContrastRatio(textColor, bgColor);
        if (ratio > 0) {
          pairsChecked++;
          if (ratio < 4.5) {
            errors.push(
              `WCAG AA contrast failure for semantic pair [${tKey} (${textColor}) / ${bKey} (${bgColor})]: ${ratio}:1 (< 4.5:1)`
            );
          }
        }
      }
    }
  }

  // Also check inline CSS rules in target CSS files
  const cssFiles = allTargetFiles.filter((f) => f.toLowerCase().endsWith(".css"));
  for (const cf of cssFiles) {
    let cssRaw = "";
    try {
      cssRaw = await fs.readFile(cf, "utf8");
    } catch {
      continue;
    }
    const ruleRegex = /([^{}]+)\{([^}]+)\}/g;
    let rm: RegExpExecArray | null;
    while ((rm = ruleRegex.exec(cssRaw)) !== null) {
      const body = rm[2];
      const fgM = body.match(/(?<![a-zA-Z-])color\s*:\s*(#[0-9a-fA-F]{3,8})/i);
      const bgM = body.match(/background(?:-color)?\s*:\s*(#[0-9a-fA-F]{3,8})/i);
      if (fgM && bgM) {
        const fgVal = fgM[1];
        const bgVal = bgM[1];
        const ratio = getWcagContrastRatio(fgVal, bgVal);
        if (ratio > 0) {
          pairsChecked++;
          if (ratio < 4.5) {
            errors.push(
              `WCAG AA contrast failure in ${path.basename(cf)} [${rm[1].trim()}]: ${fgVal} on ${bgVal} is ${ratio}:1 (< 4.5:1)`
            );
          }
        }
      }
    }
  }

  // 9. Asset Provenance Check
  const assetExtensions = [
    ".png",
    ".jpg",
    ".jpeg",
    ".svg",
    ".webp",
    ".gif",
    ".ico",
    ".bmp",
    ".ttf",
    ".otf",
    ".woff",
    ".woff2",
  ];
  const assetsInTarget = allTargetFiles.filter((f) =>
    assetExtensions.includes(path.extname(f).toLowerCase())
  );

  if (assetsInTarget.length > 0) {
    const provenanceDirs = [
      path.join(repoRoot, "01_THA_APP_VAO_DAY"),
      path.join(repoRoot, "04_SAO_LUU_AN_TOAN"),
    ];
    const knownAssetNames = new Set<string>();
    const knownAssetHashes = new Set<string>();

    for (const pDir of provenanceDirs) {
      const pFiles = await getAllFiles(pDir, (f) =>
        assetExtensions.includes(path.extname(f).toLowerCase())
      );
      for (const pf of pFiles) {
        knownAssetNames.add(path.basename(pf).toLowerCase());
        try {
          const buf = await fs.readFile(pf);
          const hash = crypto.createHash("sha256").update(buf).digest("hex").toUpperCase();
          knownAssetHashes.add(hash);
        } catch {
          // Ignore
        }
      }
    }

    const allowlistLocations = [
      path.join(repoRoot, "ASSET_ALLOWLIST.md"),
      path.join(repoRoot, "02_YEU_CAU_CUA_TOI", "ASSET_ALLOWLIST.md"),
      path.join(repoRoot, "03_KET_QUA_KIEM_TRA", "ASSET_ALLOWLIST.md"),
      path.join(repoRoot, "05_MA_NGUON_PHAT_TRIEN", "ASSET_ALLOWLIST.md"),
      path.join(repoRoot, "docs", "ASSET_ALLOWLIST.md"),
    ];

    let allowlistContent = "";
    for (const alLoc of allowlistLocations) {
      try {
        const alText = await fs.readFile(alLoc, "utf8");
        allowlistContent += `\n${alText}`;
      } catch {
        // Ignore missing allowlist file
      }
    }

    for (const af of assetsInTarget) {
      const afName = path.basename(af);
      let isOriginalAsset = false;
      let afHash: string | null = null;

      try {
        const buf = await fs.readFile(af);
        afHash = crypto.createHash("sha256").update(buf).digest("hex").toUpperCase();
        if (knownAssetHashes.has(afHash)) {
          isOriginalAsset = true;
        }
      } catch {
        // Ignore
      }

      if (!isOriginalAsset && knownAssetNames.has(afName.toLowerCase())) {
        isOriginalAsset = true;
      }

      if (isOriginalAsset) {
        let isPermitted = false;
        if (allowlistContent.trim()) {
          if (
            allowlistContent.includes(afName) ||
            (afHash && allowlistContent.includes(afHash))
          ) {
            isPermitted = true;
          }
        }

        if (!isPermitted) {
          errors.push(
            `Asset Provenance Violation: Asset ${afName} matches original app asset but is not permitted in ASSET_ALLOWLIST.md`
          );
        }
      }
    }
  }

  const success = errors.length === 0;
  const summary = success
    ? `Deterministic Verification PASSED (Risk: ${riskLevel})`
    : `Deterministic Verification FAILED with ${errors.length} error(s)`;

  return {
    success,
    riskLevel,
    errors,
    warnings,
    summary,
    details: {
      entryFiles: [...htmlFiles, ...androidManifests],
      isAndroidProject,
      scannedFiles: allTargetFiles.length,
      pairsChecked,
      highRiskIndicators,
      mediumRiskIndicators,
    },
  };
}
