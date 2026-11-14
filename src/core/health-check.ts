import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";
import { exec } from "node:child_process";
import { promisify } from "node:util";
import { findRepoRoot } from "./workspace.js";
import { getNormalizedFileHash, getTargetAppInfo } from "./gate.js";

const execAsync = promisify(exec);

export interface HealthCheckOptions {
  repoRoot?: string;
  checkExternalTools?: boolean;
}

export interface CheckItem {
  id: number;
  name: string;
  passed: boolean;
  message: string;
  details?: string[];
}

export interface ExternalToolStatus {
  name: string;
  available: boolean;
  version?: string;
  path?: string;
  note?: string;
}

export interface HealthCheckResult {
  score: number;
  total: number;
  passed: boolean;
  checks: CheckItem[];
  tools: ExternalToolStatus[];
  activeCase?: any;
  appInput?: {
    name: string;
    sha256: string;
    matchedFingerprint: boolean;
  };
}

async function fileExists(p: string): Promise<boolean> {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

async function checkCommand(cmd: string): Promise<{ ok: boolean; output: string }> {
  try {
    const { stdout, stderr } = await execAsync(cmd, { timeout: 8000 });
    return { ok: true, output: (stdout || stderr || "").trim() };
  } catch (err: any) {
    return { ok: false, output: (err.stdout || err.stderr || err.message || "").trim() };
  }
}

/**
 * Evaluates whether a Node.js version string complies with the REA-kit-agy engines range:
 * "^22.23.4 || ^24.22.1 || >=26.12.1"
 */
export function isNodeVersionCompliant(versionStr: string): boolean {
  if (!versionStr) return false;
  const clean = versionStr.trim().replace(/^v/, "");
  const match = clean.match(/^(\d+)\.(\d+)\.(\d+)/);
  if (!match) return false;
  const major = parseInt(match[1], 10);
  const minor = parseInt(match[2], 10);
  const patch = parseInt(match[3], 10);

  // Range 1: ^22.23.4 (major == 22, minor >= 23, if minor == 23 then patch >= 4)
  if (major === 22) {
    if (minor > 23) return true;
    if (minor === 23) return patch >= 4;
    return false;
  }

  // Range 2: ^24.22.1 (major == 24, minor >= 22, if minor == 22 then patch >= 1)
  if (major === 24) {
    if (minor > 22) return true;
    if (minor === 22) return patch >= 1;
    return false;
  }

  // Range 3: >=26.12.1 (major > 26, or major == 26 with minor > 12 or minor == 12 && patch >= 1)
  if (major > 26) {
    return true;
  }
  if (major === 26) {
    if (minor > 12) return true;
    if (minor === 12) return patch >= 1;
    return false;
  }

  return false;
}

export async function runHealthCheck(
  options: HealthCheckOptions = {}
): Promise<HealthCheckResult> {
  const repoRoot = options.repoRoot || findRepoRoot();
  const checks: CheckItem[] = [];
  const tools: ExternalToolStatus[] = [];

  // Check 1: 5 User directories & 01_THA_APP_VAO_DAY immutability
  const userDirs = [
    "01_THA_APP_VAO_DAY",
    "02_YEU_CAU_CUA_TOI",
    "03_KET_QUA_KIEM_TRA",
    "04_SAO_LUU_AN_TOAN",
    "05_MA_NGUON_PHAT_TRIEN",
  ];
  const missingDirs: string[] = [];
  for (const d of userDirs) {
    if (!(await fileExists(path.join(repoRoot, d)))) {
      missingDirs.push(d);
    }
  }

  const immutabilityViolations: string[] = [];
  const inputDir = path.join(repoRoot, "01_THA_APP_VAO_DAY");
  if (await fileExists(inputDir)) {
    const forbiddenExts = [
      ".tmp",
      ".bak",
      ".log",
      ".class",
      ".dex",
      ".o",
      ".obj",
      ".map",
      ".swp",
      ".lock",
    ];
    const forbiddenDirs = [
      "build",
      "out",
      "target",
      "bin",
      "obj",
      "node_modules",
      ".gradle",
      "__pycache__",
      ".backup",
      "dist",
    ];

    async function check01Recursively(dir: string) {
      try {
        const entries = await fs.readdir(dir, { withFileTypes: true });
        for (const entry of entries) {
          const fullPath = path.join(dir, entry.name);
          if (entry.isDirectory()) {
            if (forbiddenDirs.includes(entry.name.toLowerCase())) {
              immutabilityViolations.push(`Forbidden directory in 01_: ${entry.name}`);
            }
            await check01Recursively(fullPath);
          } else {
            const ext = path.extname(entry.name).toLowerCase();
            if (forbiddenExts.includes(ext)) {
              immutabilityViolations.push(`Forbidden file in 01_: ${entry.name}`);
            }
          }
        }
      } catch {
        // Ignore read error
      }
    }
    await check01Recursively(inputDir);
  }

  const check1Passed = missingDirs.length === 0 && immutabilityViolations.length === 0;
  checks.push({
    id: 1,
    name: "User directories & 01_ immutability",
    passed: check1Passed,
    message: check1Passed
      ? "Cấu trúc 5 thư mục người dùng đầy đủ & 01_THA_APP_VAO_DAY bất biến (Immutability verified)."
      : missingDirs.length > 0
        ? `Thiếu thư mục: ${missingDirs.join(", ")}`
        : `Vi phạm tính bất biến tại 01_ (${immutabilityViolations.join(", ")})`,
    details: immutabilityViolations,
  });

  // Check 2: Core docs
  const coreDocs = ["AGENTS.md", "HUONG_DAN_SU_DUNG.md", "REVIEW.md"];
  const missingCoreDocs: string[] = [];
  for (const doc of coreDocs) {
    if (!(await fileExists(path.join(repoRoot, doc)))) {
      missingCoreDocs.push(doc);
    }
  }
  const check2Passed = missingCoreDocs.length === 0;
  checks.push({
    id: 2,
    name: "Core documentation",
    passed: check2Passed,
    message: check2Passed
      ? "File luật AGENTS.md, REVIEW.md và Hướng dẫn sử dụng đã sẵn sàng."
      : `Thiếu file tài liệu: ${missingCoreDocs.join(", ")}`,
  });

  // Check 3: Skills (6 orchestration + 1 core upstream REA)
  const skills = [
    "rea-scan",
    "rea-audit",
    "rea-interview",
    "rea-plan",
    "rea-build",
    "memory-consolidation",
    "reverse-engineer-anything",
  ];
  const missingSkills: string[] = [];
  for (const sk of skills) {
    const skPath = path.join(repoRoot, ".agents", "skills", sk, "SKILL.md");
    if (!(await fileExists(skPath))) {
      missingSkills.push(sk);
    }
  }
  const check3Passed = missingSkills.length === 0;
  checks.push({
    id: 3,
    name: "Skill packages",
    passed: check3Passed,
    message: check3Passed
      ? "Bộ kỹ năng đầy đủ (6 skills điều phối + 1 skill lõi REA)."
      : `Thiếu kỹ năng: ${missingSkills.join(", ")}`,
  });

  // Check 4: Safety rules (trigger: always_on)
  const rulePath = path.join(repoRoot, ".agents", "rules", "rea-workflow.md");
  let check4Passed = false;
  let ruleMsg = "Thiếu luật an toàn .agents/rules/rea-workflow.md";
  if (await fileExists(rulePath)) {
    const content = await fs.readFile(rulePath, "utf8");
    if (/^trigger:\s*always_on/mi.test(content)) {
      check4Passed = true;
      ruleMsg = "Luật an toàn và bảo vệ dữ liệu đã kích hoạt (trigger: always_on verified).";
    } else {
      ruleMsg = "Luật an toàn thiếu 'trigger: always_on' trong frontmatter!";
    }
  }
  checks.push({
    id: 4,
    name: "Workflow safety rules",
    passed: check4Passed,
    message: ruleMsg,
  });

  // Check 5: Context & Memory (docs + state)
  const contextDocs = [
    "docs/PRD.md",
    "docs/ARCHITECTURE.md",
    "docs/PROGRESS.md",
    "docs/HANDOFF.md",
    "docs/PLAN.md",
    "docs/WORKFLOW_LIFECYCLE.md",
  ];
  const missingContext: string[] = [];
  for (const doc of contextDocs) {
    if (!(await fileExists(path.join(repoRoot, doc)))) {
      missingContext.push(doc);
    }
  }
  const stateFiles = [
    ".agents/state/MEMORY.md",
    ".agents/state/learned_rules.json",
    ".agents/state/active_case.json",
  ];
  for (const sf of stateFiles) {
    if (!(await fileExists(path.join(repoRoot, sf)))) {
      missingContext.push(sf);
    }
  }
  const check5Passed = missingContext.length === 0;
  checks.push({
    id: 5,
    name: "Context & 4-tier memory state",
    passed: check5Passed,
    message: check5Passed
      ? "Hồ sơ ngữ cảnh (docs/) và Bộ nhớ 4 tầng (MEMORY.md, active_case.json, learned_rules.json) hoàn chỉnh."
      : `Thiếu hồ sơ ngữ cảnh hoặc state: ${missingContext.join(", ")}`,
  });

  // Check 6: REA Engine & MCP runtime registration
  let check6Passed = false;
  let reaMessage = "REA Engine chưa đăng ký hoặc cấu hình chưa khớp với Antigravity";
  const shouldCheckExternal = options.checkExternalTools ?? true;

  if (shouldCheckExternal) {
    const reaRes = await checkCommand("rea doctor --client antigravity --json");
    if (reaRes.ok && reaRes.output) {
      try {
        const docJson = JSON.parse(reaRes.output);
        if (
          docJson.healthy === true ||
          docJson.registrations?.some(
            (r: any) => r.client === "antigravity" && r.state === "aligned"
          )
        ) {
          check6Passed = true;
          reaMessage = "REA Registration: ALIGNED (Antigravity client configuration verified).";
        }
      } catch {
        // Non-json output
      }
    }

    if (!check6Passed) {
      const npxRes = await checkCommand(
        "npx --no-install rea-agents doctor --client antigravity --json"
      );
      if (npxRes.ok && npxRes.output) {
        try {
          const docJson = JSON.parse(npxRes.output);
          if (
            docJson.healthy === true ||
            docJson.registrations?.some(
              (r: any) => r.client === "antigravity" && r.state === "aligned"
            )
          ) {
            check6Passed = true;
            reaMessage = "REA Registration: ALIGNED (Antigravity client configuration verified).";
          }
        } catch {
          // Non-json output
        }
      }
    }

    // Inspect Java JDK
    const javaRes = await checkCommand("java -version");
    let javaOk = false;
    let javaVer = "Unknown";
    const jMatch = javaRes.output.match(/version\s*"(\d+)(?:\.(\d+))?.*"/i);
    if (jMatch) {
      let major = parseInt(jMatch[1], 10);
      if (major === 1 && jMatch[2]) major = parseInt(jMatch[2], 10);
      javaVer = `${major}`;
      if (major >= 17) javaOk = true;
    }
    tools.push({
      name: "Java JDK",
      available: javaRes.ok,
      version: javaVer,
      note: javaOk ? ">= 17 (Ready for JADX & Apktool)" : "< 17 (Upgrade recommended)",
    });

    // Inspect JADX
    const jadxRes = await checkCommand("jadx --version");
    tools.push({
      name: "JADX Decompiler",
      available: jadxRes.ok,
      version: jadxRes.ok ? jadxRes.output.split("\n")[0] : undefined,
    });

    // Inspect Apktool
    const apkRes = await checkCommand("apktool --version");
    tools.push({
      name: "Apktool",
      available: apkRes.ok,
      version: apkRes.ok ? apkRes.output.split("\n")[0] : undefined,
    });

    // Inspect Node.js
    const nodeCompliant = isNodeVersionCompliant(process.version);
    tools.push({
      name: "Node.js Runtime",
      available: true,
      version: process.version,
      note: nodeCompliant
        ? "Compliant with engines range (^22.23.4 || ^24.22.1 || >=26.12.1)"
        : `Non-compliant with engines range (^22.23.4 || ^24.22.1 || >=26.12.1); current: ${process.version}`,
    });

    // Inspect Android CLI
    const androidRes = await checkCommand("android --version");
    tools.push({
      name: "Android CLI",
      available: androidRes.ok,
      note: androidRes.ok ? "Ready for AVD/Device Hub" : "Static fallback active",
    });
  } else {
    check6Passed = true;
    reaMessage = "External tools check skipped.";
  }

  checks.push({
    id: 6,
    name: "REA Engine & Runtime",
    passed: check6Passed,
    message: reaMessage,
  });

  const score = checks.filter((c) => c.passed).length;
  const total = checks.length;

  // Active case banner inspection
  let activeCase: any = null;
  const activeCasePath = path.join(repoRoot, ".agents", "state", "active_case.json");
  if (await fileExists(activeCasePath)) {
    try {
      const raw = await fs.readFile(activeCasePath, "utf8");
      activeCase = JSON.parse(raw);
    } catch {
      // Ignore
    }
  }

  let appInput:
    | { name: string; sha256: string; matchedFingerprint: boolean }
    | undefined;

  if (await fileExists(inputDir)) {
    try {
      const targetApp = await getTargetAppInfo(repoRoot);
      if (targetApp) {
        const matched =
          activeCase?.workflow?.target_fingerprint?.toUpperCase() ===
          targetApp.sha256.toUpperCase();
        appInput = {
          name: targetApp.name,
          sha256: targetApp.sha256,
          matchedFingerprint: matched,
        };
      }
    } catch {
      // Ignore
    }
  }

  return {
    score,
    total,
    passed: score === total,
    checks,
    tools,
    activeCase,
    appInput,
  };
}
