import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { findRepoRoot, getWorkspacePaths } from "./workspace.js";
import {
  withFileLock,
  writeUtf8NoBomAtomic,
  appendEventAtomic,
} from "./state-lock.js";

export class ConcurrencyConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ConcurrencyConflictError";
  }
}

export const GATE_ORDER = [
  "gate_01_baseline_verified",
  "gate_02_audit_passed",
  "gate_03_spec_frozen",
  "gate_04_build_qa_passed",
  "gate_05_hard_verify_passed",
  "gate_06_handoff_signed",
] as const;

export type GateName = (typeof GATE_ORDER)[number];

export const VALID_GATE_STATES = [
  "NOT_STARTED",
  "IN_PROGRESS",
  "PASS",
  "PASS_WITH_LIMITATIONS",
  "SKIPPED",
  "NOT_APPLICABLE",
  "WAIVED",
  "BLOCKED",
  "FAILED",
  "INVALIDATED",
  "REUSED_VALIDATED",
] as const;

export type GateState = (typeof VALID_GATE_STATES)[number];

export const CLEARED_STATES = new Set<string>([
  "PASS",
  "PASS_WITH_LIMITATIONS",
  "SKIPPED",
  "NOT_APPLICABLE",
  "WAIVED",
  "REUSED_VALIDATED",
]);

export const CASCADE_MAP: Record<
  string,
  { revoke_gates: string[]; revert_phase: string; revert_step: string }
> = {
  gate_01_baseline_verified: {
    revoke_gates: [
      "gate_01_baseline_verified",
      "gate_02_audit_passed",
      "gate_03_spec_frozen",
      "gate_04_build_qa_passed",
      "gate_05_hard_verify_passed",
      "gate_06_handoff_signed",
    ],
    revert_phase: "STAGE_01_DISCOVERY",
    revert_step: "01_APP_INTAKE",
  },
  gate_02_audit_passed: {
    revoke_gates: [
      "gate_02_audit_passed",
      "gate_03_spec_frozen",
      "gate_04_build_qa_passed",
      "gate_05_hard_verify_passed",
      "gate_06_handoff_signed",
    ],
    revert_phase: "STAGE_02_REVERSE_ENGINEERING",
    revert_step: "03_REA_SCAN",
  },
  gate_03_spec_frozen: {
    revoke_gates: [
      "gate_03_spec_frozen",
      "gate_04_build_qa_passed",
      "gate_05_hard_verify_passed",
      "gate_06_handoff_signed",
    ],
    revert_phase: "STAGE_03_PRODUCT_DEFINITION",
    revert_step: "06_REA_INTERVIEW",
  },
  gate_04_build_qa_passed: {
    revoke_gates: [
      "gate_04_build_qa_passed",
      "gate_05_hard_verify_passed",
      "gate_06_handoff_signed",
    ],
    revert_phase: "STAGE_04_IMPLEMENTATION",
    revert_step: "09_REA_BUILD",
  },
  gate_05_hard_verify_passed: {
    revoke_gates: [
      "gate_04_build_qa_passed",
      "gate_05_hard_verify_passed",
      "gate_06_handoff_signed",
    ],
    revert_phase: "STAGE_04_IMPLEMENTATION",
    revert_step: "09_REA_BUILD",
  },
  gate_06_handoff_signed: {
    revoke_gates: ["gate_06_handoff_signed"],
    revert_phase: "STAGE_05_VALIDATION",
    revert_step: "12_HARD_VERIFY",
  },
};

export interface GateRecord {
  state: string;
  baseline_type?: string | null;
  evidence: string[];
  evidence_sha256: string | null;
  evidence_hashes?: Record<string, string>;
  approved_by: string | null;
  approved_at: string | null;
  revoked_reason: string | null;
  waived_reason: string | null;
  skip_reason: string | null;
}

export interface ActiveCaseState {
  schema_version: number;
  case_id: string;
  target_name: string | null;
  target_class: string;
  development_strategy?: string | null;
  delivery_platform?: string | null;
  build_strategy?: string | null;
  build_route?: string | null;
  current_phase: string;
  current_step: string;
  current_gate_status: string;
  next_prompt_guide?: string;
  revision: number;
  last_updated?: string;
  backup_verified?: boolean;
  workflow: {
    mode?: string;
    parent_case_id?: string | null;
    change_request_id?: string | null;
    run_id?: string;
    target_fingerprint?: string | null;
    execution_plan?: Record<string, any>;
    step_records?: Record<string, any>;
    skip_records?: any[];
    invalidation_history?: any[];
    reused_artifacts?: any[];
    [key: string]: any;
  };
  gates: Record<string, GateRecord | any>;
  metrics: {
    risk_level: string;
    review_convergence_rounds?: number;
    max_convergence_rounds?: number;
    [key: string]: any;
  };
  [key: string]: any;
}

export interface TargetAppInfo {
  name: string;
  path: string;
  relativePath: string;
  sha256: string;
  type: "FILE" | "DIRECTORY";
  length: number;
}

export interface ImmutabilityCheckResult {
  isClean: boolean;
  violations: string[];
}

export interface GateActionOptions {
  repoRoot?: string;
  action:
    | "status"
    | "validate"
    | "open"
    | "waive"
    | "skip"
    | "reject"
    | "event"
    | "archive-case"
    | "check-app";
  gate?: string;
  evidence?: string;
  approvedBy?: string;
  reason?: string;
  details?: string;
  mode?: "PASS" | "PASS_WITH_LIMITATIONS" | "SKIPPED" | "NOT_APPLICABLE";
  expectedRevision?: number;
  force?: boolean;
}

/**
 * Normalizes gate name or shorthand aliases.
 */
export function resolveGateName(input?: string): string | null {
  if (!input || !input.trim()) return null;
  const g = input.trim().toLowerCase();
  if (/^(1|01|gate_?01|baseline)$/i.test(g)) return "gate_01_baseline_verified";
  if (/^(2|02|gate_?02|audit)$/i.test(g)) return "gate_02_audit_passed";
  if (/^(3|03|gate_?03|spec)$/i.test(g)) return "gate_03_spec_frozen";
  if (/^(4|04|gate_?04|qa|build)$/i.test(g)) return "gate_04_build_qa_passed";
  if (/^(5|05|gate_?05|hard)$/i.test(g)) return "gate_05_hard_verify_passed";
  if (/^(6|06|gate_?06|handoff|release)$/i.test(g)) return "gate_06_handoff_signed";
  if (/^gate_05_release_ready$/i.test(g)) return "gate_06_handoff_signed";
  if (/^gate_00_ready$/i.test(g)) return "gate_01_baseline_verified";
  return input.trim();
}

/**
 * Computes normalized SHA-256 hash for a file.
 * Normalizes CRLF -> LF for text files, strips leading BOM.
 */
export async function getNormalizedFileHash(filePath: string): Promise<string> {
  const ext = path.extname(filePath).toLowerCase();
  const textExts = new Set([
    ".md",
    ".json",
    ".txt",
    ".xml",
    ".html",
    ".js",
    ".ts",
    ".tsx",
    ".kt",
    ".kts",
    ".java",
    ".py",
    ".ps1",
    ".sh",
    ".gradle",
    ".css",
    ".yaml",
    ".yml",
    ".csv",
  ]);

  if (textExts.has(ext)) {
    let raw = await fs.readFile(filePath, "utf8");
    if (raw.charCodeAt(0) === 0xfeff) {
      raw = raw.slice(1);
    }
    const normalized = raw.replace(/\r\n/g, "\n");
    return crypto
      .createHash("sha256")
      .update(Buffer.from(normalized, "utf8"))
      .digest("hex")
      .toUpperCase();
  } else {
    const buffer = await fs.readFile(filePath);
    return crypto.createHash("sha256").update(buffer).digest("hex").toUpperCase();
  }
}

/**
 * Loads current active_case.json state from workspace.
 */
export async function loadCaseState(repoRoot?: string): Promise<ActiveCaseState> {
  const root = repoRoot ? path.resolve(repoRoot) : findRepoRoot();
  const stateFile = path.join(root, ".agents", "state", "active_case.json");
  if (!fsSync.existsSync(stateFile)) {
    throw new Error(`active_case.json not found at: ${stateFile}`);
  }
  const raw = await fs.readFile(stateFile, "utf8");
  return JSON.parse(raw);
}

/**
 * Atomically saves active_case.json state inside withFileLock, verifies optimistic concurrency,
 * increments revision, and stores lineage snapshots (cases/<case_id>/manifest.json and runs/<run_id>.json).
 */
export async function saveCaseStateAtomic(
  repoRoot: string,
  state: ActiveCaseState,
  expectedRevision: number = -1,
  force: boolean = false
): Promise<ActiveCaseState> {
  const root = path.resolve(repoRoot);
  const stateFile = path.join(root, ".agents", "state", "active_case.json");
  const casesDir = path.join(root, ".agents", "state", "cases");

  return await withFileLock(stateFile, async () => {
    let diskState: any = null;
    if (fsSync.existsSync(stateFile)) {
      try {
        const diskRaw = await fs.readFile(stateFile, "utf8");
        diskState = JSON.parse(diskRaw);
        if (!force && expectedRevision > 0) {
          if (diskState.revision && Number(diskState.revision) !== expectedRevision) {
            throw new ConcurrencyConflictError(
              `[ConcurrencyConflictException] active_case.json was modified by another process (Disk Rev: ${diskState.revision}, Expected Rev: ${expectedRevision}). Operation aborted to prevent data loss!`
            );
          }
        }
      } catch (err) {
        if (err instanceof ConcurrencyConflictError) throw err;
      }
    }

    state.last_updated = new Date().toISOString();
    const currentRev = typeof state.revision === "number" ? state.revision : 1;
    state.revision = Math.max(Number(diskState?.revision || 0), currentRev) + 1;

    const json = JSON.stringify(state, null, 2);

    // Save active_case.json atomically
    await writeUtf8NoBomAtomic(stateFile, json);

    // Lineage snapshot
    const caseId = state.case_id || "CASE-UNKNOWN";
    const caseFolder = path.join(casesDir, caseId);
    const runsFolder = path.join(caseFolder, "runs");
    await fs.mkdir(runsFolder, { recursive: true });

    const caseManifest = path.join(caseFolder, "manifest.json");
    await writeUtf8NoBomAtomic(caseManifest, json);

    const runId = state.workflow?.run_id || `RUN-${state.revision}`;
    const runSnapshot = path.join(runsFolder, `${runId}.json`);
    await writeUtf8NoBomAtomic(runSnapshot, json);

    return state;
  });
}

/**
 * Checks immutability of 01_THA_APP_VAO_DAY directory.
 */
export async function testInputDirectoryImmutability(
  repoRoot: string
): Promise<ImmutabilityCheckResult> {
  const inputDir = path.join(repoRoot, "01_THA_APP_VAO_DAY");
  if (!fsSync.existsSync(inputDir)) {
    return { isClean: true, violations: [] };
  }

  const forbiddenExts = new Set([
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
  ]);
  const forbiddenDirNames = new Set([
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
  ]);

  const violations: string[] = [];

  async function traverse(currentDir: string): Promise<void> {
    const entries = await fs.readdir(currentDir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);
      const ext = path.extname(entry.name).toLowerCase();

      if (forbiddenExts.has(ext)) {
        violations.push(
          `Forbidden temporary/auto-generated file in 01_THA_APP_VAO_DAY: ${fullPath}`
        );
      }
      if (entry.isDirectory()) {
        if (forbiddenDirNames.has(entry.name.toLowerCase())) {
          violations.push(
            `Forbidden build/temporary directory in 01_THA_APP_VAO_DAY: ${fullPath}`
          );
        }
        await traverse(fullPath);
      }
    }
  }

  await traverse(inputDir);
  return { isClean: violations.length === 0, violations };
}

/**
 * Inspects 01_THA_APP_VAO_DAY to detect target application file or directory and compute its SHA-256 fingerprint.
 */
export async function getTargetAppInfo(
  repoRoot: string
): Promise<TargetAppInfo | null> {
  const inputDir = path.join(repoRoot, "01_THA_APP_VAO_DAY");
  if (!fsSync.existsSync(inputDir)) {
    return null;
  }

  const ignored = new Set([
    "readme.md",
    ".gitkeep",
    ".gitignore",
    ".ds_store",
    "thumbs.db",
  ]);
  const entries = await fs.readdir(inputDir, { withFileTypes: true });

  const files = entries.filter(
    (e) => e.isFile() && !ignored.has(e.name.toLowerCase())
  );
  if (files.length > 0) {
    const targetFile = files[0];
    const fullPath = path.join(inputDir, targetFile.name);
    const stat = await fs.stat(fullPath);
    const sha = await getNormalizedFileHash(fullPath);
    return {
      name: targetFile.name,
      path: fullPath,
      relativePath: `01_THA_APP_VAO_DAY/${targetFile.name}`,
      sha256: sha.toUpperCase(),
      type: "FILE",
      length: stat.size,
    };
  }

  const subDirs = entries.filter(
    (e) => e.isDirectory() && !e.name.startsWith(".")
  );
  if (subDirs.length > 0) {
    const firstDir = subDirs[0];
    const fullDirPath = path.join(inputDir, firstDir.name);

    // Recursively collect all files { relPath, sha256 }
    const subFiles: Array<{ relPath: string; sha256: string }> = [];
    async function collect(dir: string): Promise<void> {
      const items = await fs.readdir(dir, { withFileTypes: true });
      for (const item of items) {
        if (item.name.startsWith(".")) continue;
        const itemPath = path.join(dir, item.name);
        if (item.isDirectory()) {
          await collect(itemPath);
        } else if (item.isFile()) {
          if (item.name.toLowerCase() === "thumbs.db") continue;
          const relPath = path.relative(fullDirPath, itemPath).replace(/\\/g, "/");
          const sha = await getNormalizedFileHash(itemPath);
          subFiles.push({ relPath, sha256: sha });
        }
      }
    }
    await collect(fullDirPath);

    subFiles.sort((a, b) => a.relPath.localeCompare(b.relPath));
    const combined = subFiles.map((f) => `${f.relPath}:${f.sha256}`).join("\n");
    const hash = crypto
      .createHash("sha256")
      .update(Buffer.from(combined, "utf8"))
      .digest("hex")
      .toUpperCase();

    return {
      name: firstDir.name,
      path: fullDirPath,
      relativePath: `01_THA_APP_VAO_DAY/${firstDir.name}`,
      sha256: hash,
      type: "DIRECTORY",
      length: subFiles.length,
    };
  }

  return null;
}

/**
 * Archives current case and initializes a clean case.
 */
export async function archiveCurrentCaseAndReset(
  repoRoot: string,
  state: ActiveCaseState,
  targetApp: TargetAppInfo,
  reason: string = "New target app detected with different fingerprint"
): Promise<ActiveCaseState> {
  const root = path.resolve(repoRoot);
  const casesDir = path.join(root, ".agents", "state", "cases");
  const oldCaseId = state.case_id || "CASE-LEGACY";
  const oldFingerprint = state.workflow?.target_fingerprint || "NONE";
  const newFingerprint = targetApp.sha256;

  const caseFolder = path.join(casesDir, oldCaseId);
  await fs.mkdir(caseFolder, { recursive: true });

  const json = JSON.stringify(state, null, 2);
  const caseManifest = path.join(caseFolder, "manifest.json");
  await writeUtf8NoBomAtomic(caseManifest, json);

  // Initialize new case ID
  const pad = (n: number) => String(n).padStart(2, "0");
  const d = new Date();
  const tsStr = `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
  const hexSuffix = crypto.randomBytes(2).toString("hex");
  const newCaseId = `CASE-${tsStr}-${hexSuffix}`;

  const interviewStatePath = path.join(
    root,
    ".agents",
    "state",
    "interview_state.json"
  );

  // Wrap the copy and reset of interview_state.json with withFileLock(interviewStatePath)
  await withFileLock(interviewStatePath, async () => {
    if (fsSync.existsSync(interviewStatePath)) {
      const destInterview = path.join(caseFolder, "interview_state.json");
      await fs.copyFile(interviewStatePath, destInterview);
    }

    const nowIso = new Date().toISOString();
    const cleanInterviewState = {
      schema_version: 1,
      case_id: newCaseId,
      session: {
        session_id: `INT-SESSION-${newCaseId}`,
        status: "NOT_STARTED",
        current_goal: null,
        current_stage: "STAGE_03_PRODUCT_DEFINITION",
        active_domain: null,
        design_mode: null,
        max_clarification_per_goal: 2,
        max_total_questions: 15,
        created_at: nowIso,
        updated_at: nowIso,
      },
      goals: [],
      questions: [],
      answers: [],
      decisions: [],
      assumptions: [],
      conflicts: [],
      unknowns: [],
      scope_changes: [],
      sufficiency_evaluation: {
        verdict: "NEEDS_INPUT",
        evaluated_at: nowIso,
        goal_evaluations: [],
        blocking_reasons: [
          "No goals have been recorded in the interview state.",
        ],
        deferred_decisions: [],
        assumptions_summary: {
          total: 0,
          benign: 0,
          critical: 0,
          pending_approval: 0,
        },
        summary:
          "Chưa có mục tiêu nào được ghi nhận. Hãy bắt đầu bằng cách nạp hồ sơ và phân tích mục tiêu.",
      },
      last_updated: nowIso,
    };
    await writeUtf8NoBomAtomic(
      interviewStatePath,
      JSON.stringify(cleanInterviewState, null, 2)
    );
  });

  const archiveInfo = {
    archived_at: new Date().toISOString(),
    archived_case_id: oldCaseId,
    archived_reason: reason,
    previous_target_fingerprint: oldFingerprint,
    new_target_name: targetApp.name,
    new_target_fingerprint: newFingerprint,
  };
  await writeUtf8NoBomAtomic(
    path.join(caseFolder, "archive_info.json"),
    JSON.stringify(archiveInfo, null, 2)
  );

  await appendEventAtomic(root, {
    action: "CASE_ARCHIVED",
    actor: "coordinator",
    phase: state.current_phase,
    step: state.current_step,
    details: `Archived case ${oldCaseId} to cases/${oldCaseId}/. Reason: ${reason}`,
    evidence_sha256: newFingerprint,
  });

  state.case_id = newCaseId;
  state.target_name = targetApp.name;
  state.current_phase = "STAGE_01_DISCOVERY";
  state.current_step = "01_APP_INTAKE";
  state.current_gate_status = "GATE_00_READY";
  state.revision = 1;
  state.last_updated = new Date().toISOString();

  if (!state.workflow) {
    state.workflow = {};
  }
  state.workflow.mode = "NEW_CASE";
  state.workflow.parent_case_id = oldCaseId;
  state.workflow.run_id = "RUN-001";
  state.workflow.target_fingerprint = newFingerprint;

  for (const g of GATE_ORDER) {
    state.gates[g] = {
      state: "NOT_STARTED",
      evidence: [],
      evidence_sha256: null,
      approved_by: null,
      approved_at: null,
      revoked_reason: null,
      waived_reason: null,
      skip_reason: null,
    };
  }

  if (state.metrics) {
    state.metrics.review_convergence_rounds = 0;
  }

  await saveCaseStateAtomic(root, state, -1, true);

  await appendEventAtomic(root, {
    action: "CASE_INITIALIZED",
    actor: "coordinator",
    phase: "STAGE_01_DISCOVERY",
    step: "01_APP_INTAKE",
    details: `Initialized new case ${newCaseId} for target ${targetApp.name} (${newFingerprint})`,
    evidence_sha256: newFingerprint,
  });

  return state;
}

/**
 * Invalidates subsequent gates according to CASCADE_MAP.
 * Only gates that are COMPLETED (or in CLEARED_STATES) or IN_PROGRESS are invalidated.
 * Gates that are NOT_STARTED are left untouched.
 */
export function invalidateSubsequentGates(
  state: ActiveCaseState,
  fromGate: string,
  reason: string = "Cascade Invalidation",
  approver: string = "coordinator"
): string[] {
  const resolvedGate = resolveGateName(fromGate) || fromGate;
  const rule = CASCADE_MAP[resolvedGate];
  if (!rule) {
    throw new Error(
      `No cascade invalidation rule found for gate: ${resolvedGate}`
    );
  }

  const now = new Date().toISOString();
  const invalidatedGates: string[] = [];

  for (const rg of rule.revoke_gates) {
    const currentGateObj = state.gates[rg];
    const currentState =
      typeof currentGateObj?.state === "string"
        ? currentGateObj.state
        : currentGateObj === true
          ? "PASS"
          : "NOT_STARTED";

    // Only invalidate gates that are COMPLETED (or in CLEARED_STATES) or IN_PROGRESS
    const isCompletedOrInProgress =
      currentState === "IN_PROGRESS" ||
      currentState === "COMPLETED" ||
      CLEARED_STATES.has(currentState);

    // The gate being rejected itself is always invalidated, while subsequent gates
    // are only invalidated if they are COMPLETED or IN_PROGRESS.
    if (rg === resolvedGate || (isCompletedOrInProgress && currentState !== "NOT_STARTED")) {
      state.gates[rg] = {
        state: "INVALIDATED",
        evidence: [],
        evidence_sha256: null,
        approved_by: approver,
        approved_at: now,
        revoked_reason: `Cascade Invalidation from rejecting gate ${resolvedGate}: ${reason}`,
        waived_reason: null,
        skip_reason: null,
      };
      invalidatedGates.push(rg);
    }
  }

  if (state.workflow) {
    if (!Array.isArray(state.workflow.invalidation_history)) {
      state.workflow.invalidation_history = [];
    }
    state.workflow.invalidation_history.push({
      timestamp: now,
      triggered_by_gate: resolvedGate,
      reason,
      approver,
      invalidated_gates: invalidatedGates,
    });
  }

  return invalidatedGates;
}

/**
 * Main Gate Engine Action Handler.
 */
export async function runGateAction(
  options: GateActionOptions
): Promise<Record<string, any>> {
  const repoRoot = options.repoRoot
    ? path.resolve(options.repoRoot)
    : findRepoRoot();
  const state = await loadCaseState(repoRoot);
  const expectedRev =
    typeof options.expectedRevision === "number"
      ? options.expectedRevision
      : state.revision;

  switch (options.action) {
    case "status": {
      const summary: Record<string, any> = {
        case_id: state.case_id,
        revision: state.revision,
        current_phase: state.current_phase,
        current_step: state.current_step,
        current_gate_status: state.current_gate_status,
        mode: state.workflow?.mode || "STANDARD",
        risk_level: state.metrics?.risk_level || "UNASSESSED",
        gates: {},
      };

      for (const g of GATE_ORDER) {
        const gateObj = state.gates[g] || {};
        const gState = gateObj.state || "NOT_STARTED";
        summary.gates[g] = {
          state: gState,
          approved_by: gateObj.approved_by || null,
          approved_at: gateObj.approved_at || null,
          evidence: gateObj.evidence || [],
          evidence_sha256: gateObj.evidence_sha256 || null,
          note:
            gateObj.revoked_reason ||
            gateObj.waived_reason ||
            gateObj.skip_reason ||
            null,
        };
      }
      return summary;
    }

    case "validate": {
      const errors: string[] = [];
      const warnings: string[] = [];

      // 1. Required fields
      const requiredFields = [
        "schema_version",
        "case_id",
        "target_class",
        "current_phase",
        "current_step",
        "gates",
        "metrics",
        "workflow",
      ];
      for (const rf of requiredFields) {
        if (!state[rf]) {
          errors.push(`Missing required field in active_case.json: ${rf}`);
        }
      }

      // 2. Risk level
      const validRisks = new Set(["UNASSESSED", "LOW", "MEDIUM", "HIGH"]);
      if (!validRisks.has(state.metrics?.risk_level)) {
        errors.push(
          `Invalid metrics.risk_level: '${state.metrics?.risk_level}' (must be UNASSESSED, LOW, MEDIUM, or HIGH)`
        );
      }

      // 3. 6 gates check
      for (const g of GATE_ORDER) {
        const gateObj = state.gates[g];
        if (!gateObj) {
          errors.push(`Missing gate configuration: ${g}`);
          continue;
        }

        const gState =
          typeof gateObj.state === "string"
            ? gateObj.state
            : gateObj === true
              ? "PASS"
              : "NOT_STARTED";

        if (
          !VALID_GATE_STATES.includes(gState as any) &&
          gState !== "NOT_RUN" &&
          gState !== "REVOKED"
        ) {
          errors.push(`Gate ${g} has invalid state: '${gState}'`);
          continue;
        }

        if (
          gState === "PASS" ||
          gState === "PASS_WITH_LIMITATIONS" ||
          gState === "REUSED_VALIDATED"
        ) {
          if (!gateObj.evidence || gateObj.evidence.length === 0) {
            errors.push(
              `Gate ${g} is ${gState} but evidence array is empty!`
            );
          } else {
            for (const ev of gateObj.evidence) {
              const evPath = path.isAbsolute(ev)
                ? ev
                : path.join(repoRoot, ev);
              if (!fsSync.existsSync(evPath)) {
                errors.push(
                  `Gate ${g} is ${gState} but evidence file does not exist: ${ev}`
                );
              }
            }
          }

          if (!gateObj.evidence_sha256) {
            errors.push(`Gate ${g} is ${gState} but missing evidence_sha256!`);
          } else {
            const primaryEv = gateObj.evidence?.[0];
            if (primaryEv) {
              const primaryEvPath = path.isAbsolute(primaryEv)
                ? primaryEv
                : path.join(repoRoot, primaryEv);
              if (fsSync.existsSync(primaryEvPath)) {
                const actualHash = await getNormalizedFileHash(primaryEvPath);
                if (actualHash !== gateObj.evidence_sha256) {
                  errors.push(
                    `Gate ${g} SHA-256 mismatch! Expected: ${gateObj.evidence_sha256}, Actual: ${actualHash}`
                  );
                }
              }
            }
          }

          if (gateObj.evidence_hashes && typeof gateObj.evidence_hashes === "object") {
            for (const [evRel, expectedHash] of Object.entries(gateObj.evidence_hashes)) {
              const normEvRel = evRel.replace(/\\/g, "/");
              const evFilePath = path.isAbsolute(normEvRel) ? normEvRel : path.join(repoRoot, normEvRel);
              if (fsSync.existsSync(evFilePath)) {
                const actualHash = await getNormalizedFileHash(evFilePath);
                if (actualHash !== expectedHash) {
                  errors.push(
                    `Gate ${g} evidence SHA-256 mismatch for ${normEvRel}! Expected: ${expectedHash}, Actual: ${actualHash}`
                  );
                }
              } else {
                errors.push(
                  `Gate ${g} evidence file not found for hash verification: ${normEvRel}`
                );
              }
            }
          }

          // Special check for gate_02: APP_FLOW_SPEC.md & Evidence Anchors
          if (g === "gate_02_audit_passed") {
            let appFlowRel = "03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md";
            if (gateObj.evidence && Array.isArray(gateObj.evidence) && gateObj.evidence.length > 0) {
              const customRel =
                gateObj.evidence.find(
                  (ev: string) =>
                    ev.toLowerCase().includes("flow") ||
                    ev.toLowerCase().includes("spec")
                ) ||
                (fsSync.existsSync(path.join(repoRoot, "03_KET_QUA_KIEM_TRA", "APP_FLOW_SPEC.md"))
                  ? "03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md"
                  : gateObj.evidence[0]);
              if (customRel) {
                appFlowRel = customRel.replace(/\\/g, "/");
              }
            } else if (typeof gateObj.flow_spec === "string" && gateObj.flow_spec) {
              appFlowRel = gateObj.flow_spec.replace(/\\/g, "/");
            } else if (typeof gateObj.evidence_path === "string" && gateObj.evidence_path) {
              appFlowRel = gateObj.evidence_path.replace(/\\/g, "/");
            }

            const appFlowPath = path.isAbsolute(appFlowRel)
              ? appFlowRel
              : path.join(repoRoot, appFlowRel);
            if (!fsSync.existsSync(appFlowPath)) {
              errors.push(
                `Gate gate_02_audit_passed: Missing flow spec file: ${appFlowRel}`
              );
            } else {
              const appFlowText = await fs.readFile(appFlowPath, "utf8");
              const evMatches = appFlowText.match(/\[EV:\s*[^\]]+\]/g);
              if (!evMatches || evMatches.length === 0) {
                errors.push(
                  `Gate gate_02_audit_passed: ${appFlowRel} lacks Evidence Anchors [EV: ...]`
                );
              }
            }
          }
        } else if (gState === "WAIVED") {
          if (!gateObj.waived_reason) {
            errors.push(`Gate ${g} is WAIVED but missing waived_reason!`);
          }
        } else if (gState === "SKIPPED" || gState === "NOT_APPLICABLE") {
          if (gState === "SKIPPED" && !gateObj.skip_reason) {
            errors.push(`Gate ${g} is SKIPPED but missing skip_reason!`);
          }
        } else if (gState === "FAILED" || gState === "BLOCKED") {
          errors.push(`Gate ${g} is in failed/blocked state: ${gState}`);
        }
      }

      // 4. Immutability check
      const immCheck = await testInputDirectoryImmutability(repoRoot);
      if (!immCheck.isClean) {
        errors.push(...immCheck.violations);
      }

      // 5. Target app fingerprint check
      const targetApp = await getTargetAppInfo(repoRoot);
      if (targetApp) {
        const currentFp = state.workflow?.target_fingerprint;
        if (currentFp && currentFp !== targetApp.sha256) {
          warnings.push(
            `Target app fingerprint mismatch (${targetApp.name}): Disk ${targetApp.sha256} vs Active ${currentFp}`
          );
        }
      }

      return {
        valid: errors.length === 0,
        errors,
        warnings,
      };
    }

    case "open": {
      const resolvedGate = resolveGateName(options.gate);
      if (!resolvedGate) {
        throw new Error("Missing or invalid gate to open");
      }

      const gateIdx = GATE_ORDER.indexOf(resolvedGate as GateName);
      if (gateIdx < 0) {
        throw new Error(`Invalid gate name: ${resolvedGate}`);
      }

      // 1. DAG Ancestor clearance check
      for (let i = 0; i < gateIdx; i++) {
        const ancestorGate = GATE_ORDER[i];
        const ancestorObj = state.gates[ancestorGate];
        const ancestorState =
          typeof ancestorObj?.state === "string"
            ? ancestorObj.state
            : ancestorObj === true
              ? "PASS"
              : "NOT_STARTED";
        if (!CLEARED_STATES.has(ancestorState)) {
          throw new Error(
            `Cannot open ${resolvedGate} because ancestor gate ${ancestorGate} has not cleared (currently: ${ancestorState})!`
          );
        }
      }

      // 2. Evidence validation
      if (!options.evidence) {
        throw new Error(
          `Open action requires evidence parameter (-Evidence <path>)!`
        );
      }
      const evPath = path.isAbsolute(options.evidence)
        ? options.evidence
        : path.join(repoRoot, options.evidence);

      if (!fsSync.existsSync(evPath)) {
        throw new Error(`Evidence file not found on disk: ${options.evidence}`);
      }

      const sha = await getNormalizedFileHash(evPath);
      const relPath = path.relative(repoRoot, evPath).replace(/\\/g, "/");
      const evList = [relPath];

      // Immutability check: only gate_01 can use 01_THA_APP_VAO_DAY as evidence
      if (resolvedGate !== "gate_01_baseline_verified") {
        const normRel = relPath.replace(/^(\.\/|\/)/, "");
        if (normRel.startsWith("01_THA_APP_VAO_DAY/")) {
          throw new Error(
            `Immutability Violation! 01_THA_APP_VAO_DAY/ is strictly immutable and cannot be used as generated evidence for ${resolvedGate}!`
          );
        }
      }

      // Special check for gate_02_audit_passed
      if (resolvedGate === "gate_02_audit_passed") {
        let appFlowPath = path.join(
          repoRoot,
          "03_KET_QUA_KIEM_TRA",
          "APP_FLOW_SPEC.md"
        );
        const appFlowRel = "03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md";

        if (!fsSync.existsSync(appFlowPath)) {
          if (
            options.evidence.endsWith("APP_FLOW_SPEC.md") &&
            fsSync.existsSync(evPath)
          ) {
            appFlowPath = evPath;
          } else {
            throw new Error(
              `Cannot open gate_02_audit_passed: missing app flow spec file at ${appFlowRel}`
            );
          }
        }

        const appFlowText = await fs.readFile(appFlowPath, "utf8");
        const evMatches = appFlowText.match(/\[EV:\s*[^\]]+\]/g);
        if (!evMatches || evMatches.length === 0) {
          throw new Error(
            `Cannot open gate_02_audit_passed: ${appFlowRel} does not contain valid Evidence Anchors ([EV: ...])!`
          );
        }

        if (!evList.includes(appFlowRel)) {
          evList.push(appFlowRel);
        }
      }

      const approver = options.approvedBy || "coordinator";
      const now = new Date().toISOString();
      const finalState =
        options.mode === "PASS_WITH_LIMITATIONS"
          ? "PASS_WITH_LIMITATIONS"
          : "PASS";

      const evidenceHashes: Record<string, string> = {};
      for (const item of evList) {
        const itemNorm = item.replace(/\\/g, "/");
        const itemPath = path.isAbsolute(item) ? item : path.join(repoRoot, item);
        if (fsSync.existsSync(itemPath)) {
          evidenceHashes[itemNorm] = await getNormalizedFileHash(itemPath);
        }
      }

      state.gates[resolvedGate] = {
        state: finalState,
        evidence: evList,
        evidence_sha256: sha,
        evidence_hashes: evidenceHashes,
        approved_by: approver,
        approved_at: now,
        revoked_reason: null,
        waived_reason: null,
        skip_reason: null,
      };
      state.current_gate_status = `${resolvedGate}_${finalState}`.toUpperCase();

      await saveCaseStateAtomic(repoRoot, state, expectedRev, options.force);

      await appendEventAtomic(repoRoot, {
        action: "GATE_OPEN",
        actor: approver,
        phase: state.current_phase,
        step: state.current_step,
        details: `Successfully opened ${resolvedGate} (${finalState})`,
        evidence_sha256: sha,
      });

      return {
        status: finalState,
        gate: resolvedGate,
        approved_by: approver,
        approved_at: now,
        evidence: evList,
        evidence_sha256: sha,
      };
    }

    case "waive": {
      const resolvedGate = resolveGateName(options.gate);
      if (!resolvedGate) {
        throw new Error("Missing or invalid gate to waive");
      }
      if (!options.reason) {
        throw new Error("Waiving a gate requires a reason (-Reason)!");
      }

      const gateIdx = GATE_ORDER.indexOf(resolvedGate as GateName);
      if (gateIdx < 0) {
        throw new Error(`Invalid gate name: ${resolvedGate}`);
      }

      // DAG clearance check
      for (let i = 0; i < gateIdx; i++) {
        const ancestorGate = GATE_ORDER[i];
        const ancestorObj = state.gates[ancestorGate];
        const ancestorState =
          typeof ancestorObj?.state === "string"
            ? ancestorObj.state
            : ancestorObj === true
              ? "PASS"
              : "NOT_STARTED";
        if (!CLEARED_STATES.has(ancestorState)) {
          throw new Error(
            `Cannot waive ${resolvedGate} because ancestor gate ${ancestorGate} has not cleared!`
          );
        }
      }

      const approver = options.approvedBy || "human_owner";
      const now = new Date().toISOString();

      state.gates[resolvedGate] = {
        state: "WAIVED",
        evidence: [],
        evidence_sha256: null,
        approved_by: approver,
        approved_at: now,
        revoked_reason: null,
        waived_reason: options.reason,
        skip_reason: null,
      };
      state.current_gate_status = `${resolvedGate}_WAIVED`.toUpperCase();

      await saveCaseStateAtomic(repoRoot, state, expectedRev, options.force);

      await appendEventAtomic(repoRoot, {
        action: "GATE_WAIVED",
        actor: approver,
        phase: state.current_phase,
        step: state.current_step,
        details: `Waived ${resolvedGate}. Reason: ${options.reason}`,
        evidence_sha256: null,
      });

      return {
        status: "WAIVED",
        gate: resolvedGate,
        approved_by: approver,
        waived_reason: options.reason,
      };
    }

    case "skip": {
      const resolvedGate = resolveGateName(options.gate);
      if (!resolvedGate) {
        throw new Error("Missing or invalid gate to skip");
      }
      if (!options.reason) {
        throw new Error("Skipping a gate requires a reason (-Reason)!");
      }

      const gateIdx = GATE_ORDER.indexOf(resolvedGate as GateName);
      if (gateIdx < 0) {
        throw new Error(`Invalid gate name: ${resolvedGate}`);
      }

      // DAG clearance check
      for (let i = 0; i < gateIdx; i++) {
        const ancestorGate = GATE_ORDER[i];
        const ancestorObj = state.gates[ancestorGate];
        const ancestorState =
          typeof ancestorObj?.state === "string"
            ? ancestorObj.state
            : ancestorObj === true
              ? "PASS"
              : "NOT_STARTED";
        if (!CLEARED_STATES.has(ancestorState)) {
          throw new Error(
            `Cannot skip ${resolvedGate} because ancestor gate ${ancestorGate} has not cleared!`
          );
        }
      }

      const approver = options.approvedBy || "coordinator";
      const now = new Date().toISOString();
      const targetState =
        options.mode === "NOT_APPLICABLE" ? "NOT_APPLICABLE" : "SKIPPED";

      state.gates[resolvedGate] = {
        state: targetState,
        evidence: [],
        evidence_sha256: null,
        approved_by: approver,
        approved_at: now,
        revoked_reason: null,
        waived_reason: null,
        skip_reason: options.reason,
      };
      state.current_gate_status = `${resolvedGate}_${targetState}`.toUpperCase();

      await saveCaseStateAtomic(repoRoot, state, expectedRev, options.force);

      await appendEventAtomic(repoRoot, {
        action: "GATE_SKIPPED",
        actor: approver,
        phase: state.current_phase,
        step: state.current_step,
        details: `Skipped ${resolvedGate} (${targetState}). Reason: ${options.reason}`,
        evidence_sha256: null,
      });

      return {
        status: targetState,
        gate: resolvedGate,
        approved_by: approver,
        skip_reason: options.reason,
      };
    }

    case "reject": {
      const resolvedGate = resolveGateName(options.gate);
      if (!resolvedGate) {
        throw new Error("Missing or invalid gate to reject");
      }

      const rejectReason =
        options.reason || "Rejected by user or independent audit.";
      const approver = options.approvedBy || "coordinator";

      if (!state.metrics) {
        state.metrics = { risk_level: "UNASSESSED" };
      }

      let currentRounds = state.metrics.review_convergence_rounds || 0;
      const maxRounds = state.metrics.max_convergence_rounds || 2;
      currentRounds++;
      state.metrics.review_convergence_rounds = currentRounds;

      if (currentRounds > maxRounds) {
        state.gates[resolvedGate] = {
          ...(state.gates[resolvedGate] || {}),
          state: "BLOCKED",
          revoked_reason: `Exceeded maximum reject convergence rounds (${maxRounds}): ${rejectReason}`,
        };
        state.current_gate_status = `${resolvedGate}_BLOCKED`.toUpperCase();

        await saveCaseStateAtomic(repoRoot, state, expectedRev, options.force);

        await appendEventAtomic(repoRoot, {
          action: "GATE_BLOCKED",
          actor: approver,
          phase: state.current_phase,
          step: state.current_step,
          details: `Gate ${resolvedGate} BLOCKED after exceeding ${maxRounds} reject rounds. Reason: ${rejectReason}`,
          evidence_sha256: null,
        });

        return {
          status: "BLOCKED",
          gate: resolvedGate,
          convergence_rounds: currentRounds,
          max_rounds: maxRounds,
          reason: rejectReason,
        };
      }

      const rule = CASCADE_MAP[resolvedGate];
      if (!rule) {
        throw new Error(
          `No cascade invalidation rule found for gate: ${resolvedGate}`
        );
      }

      const revokedGates = invalidateSubsequentGates(
        state,
        resolvedGate,
        rejectReason,
        approver
      );

      state.current_phase = rule.revert_phase;
      state.current_step = rule.revert_step;
      state.current_gate_status = `${resolvedGate}_INVALIDATED`.toUpperCase();

      await saveCaseStateAtomic(repoRoot, state, expectedRev, options.force);

      await appendEventAtomic(repoRoot, {
        action: "GATE_CASCADE_REJECT",
        actor: approver,
        phase: rule.revert_phase,
        step: rule.revert_step,
        details: `Rejected ${resolvedGate} (Round ${currentRounds}/${maxRounds}). Revoked: ${revokedGates.join(", ")}. Reason: ${rejectReason}`,
        evidence_sha256: null,
      });

      return {
        status: "INVALIDATED",
        gate: resolvedGate,
        revoked_gates: rule.revoke_gates,
        revert_phase: rule.revert_phase,
        revert_step: rule.revert_step,
        convergence_rounds: currentRounds,
        max_rounds: maxRounds,
      };
    }

    case "event": {
      if (!options.details) {
        throw new Error("Event action requires details parameter (-Details)!");
      }
      const actor = options.approvedBy || "coordinator";
      await appendEventAtomic(repoRoot, {
        action: "CUSTOM_LOG",
        actor,
        phase: state.current_phase,
        step: state.current_step,
        details: options.details,
        evidence_sha256: null,
      });
      return { logged: true, details: options.details, actor };
    }

    case "archive-case": {
      let targetApp = await getTargetAppInfo(repoRoot);
      if (!targetApp) {
        targetApp = {
          name: state.target_name || "UNKNOWN_APP",
          path: "",
          relativePath: "",
          sha256: `MANUAL_ARCHIVE_${Date.now()}`,
          type: "FILE",
          length: 0,
        };
      }
      const archiveReason =
        options.reason || "Manual case archive requested via archive-case action";
      const newState = await archiveCurrentCaseAndReset(
        repoRoot,
        state,
        targetApp,
        archiveReason
      );
      return {
        archived: true,
        new_case_id: newState.case_id,
        target_name: newState.target_name,
      };
    }

    case "check-app": {
      const targetApp = await getTargetAppInfo(repoRoot);
      if (!targetApp) {
        return { found: false, message: "No app detected in 01_THA_APP_VAO_DAY" };
      }

      const currentFp = state.workflow?.target_fingerprint;
      if (!currentFp) {
        if (!state.workflow) state.workflow = {};
        state.workflow.target_fingerprint = targetApp.sha256;
        state.target_name = targetApp.name;
        await saveCaseStateAtomic(repoRoot, state, expectedRev, options.force);

        await appendEventAtomic(repoRoot, {
          action: "APP_FINGERPRINT_SET",
          actor: "coordinator",
          phase: state.current_phase,
          step: state.current_step,
          details: `Set app fingerprint for ${targetApp.name} (${targetApp.sha256})`,
          evidence_sha256: targetApp.sha256,
        });

        return {
          found: true,
          action: "FINGERPRINT_ATTACHED",
          app: targetApp,
        };
      } else if (currentFp !== targetApp.sha256) {
        const archiveReason =
          options.reason ||
          `Detected new app (${targetApp.name}) with SHA-256 (${targetApp.sha256}) different from current case (${currentFp}).`;
        const newState = await archiveCurrentCaseAndReset(
          repoRoot,
          state,
          targetApp,
          archiveReason
        );
        return {
          found: true,
          action: "CASE_ARCHIVED_AND_RESET",
          new_case_id: newState.case_id,
          app: targetApp,
        };
      } else {
        return {
          found: true,
          action: "FINGERPRINT_MATCH",
          app: targetApp,
        };
      }
    }

    default:
      throw new Error(`Unknown gate action: ${(options as any).action}`);
  }
}

/**
 * Validates gate states and evidence immutability.
 */
export async function validateGate(
  options: { repoRoot?: string; gate?: string } = {}
): Promise<{ valid: boolean; errors: string[]; warnings: string[] }> {
  return (await runGateAction({ action: "validate", ...options })) as any;
}
