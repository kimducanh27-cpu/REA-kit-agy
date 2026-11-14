import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import { findRepoRoot } from "./workspace.js";
import { writeUtf8NoBomAtomic } from "./state-lock.js";

export interface InitWorkspaceOptions {
  dir?: string;
  force?: boolean;
  repoRoot?: string;
}

export interface InitWorkspaceResult {
  root: string;
  createdDirs: string[];
  initializedFiles: string[];
}

export const STANDARD_DIRS = [
  "01_THA_APP_VAO_DAY",
  "02_YEU_CAU_CUA_TOI",
  "03_KET_QUA_KIEM_TRA",
  "04_SAO_LUU_AN_TOAN",
  "05_MA_NGUON_PHAT_TRIEN",
];

/**
 * Initializes a new REA-kit workspace with the standard 5 directories,
 * initial active_case.json, interview_state.json, and events.jsonl.
 */
export async function initWorkspace(options: InitWorkspaceOptions = {}): Promise<InitWorkspaceResult> {
  const targetRoot = path.resolve(options.dir || options.repoRoot || process.cwd());
  const stateDir = path.join(targetRoot, ".agents", "state");
  const activeCasePath = path.join(stateDir, "active_case.json");
  const interviewStatePath = path.join(stateDir, "interview_state.json");
  const eventsPath = path.join(stateDir, "events.jsonl");

  // Rejection check if state already exists and force is not set
  if (!options.force) {
    const activeCaseExists = fsSync.existsSync(activeCasePath);
    const interviewStateExists = fsSync.existsSync(interviewStatePath);
    const eventsExists = fsSync.existsSync(eventsPath);

    if (activeCaseExists || interviewStateExists || eventsExists) {
      throw new Error(
        `[STATE_EXISTS] Workspace state already exists in '${stateDir}'. Pass --force to overwrite.`
      );
    }
  }

  // Ensure 5 standard directories and .gitkeep
  const createdDirs: string[] = [];
  for (const dirName of STANDARD_DIRS) {
    const fullDirPath = path.join(targetRoot, dirName);
    await fs.mkdir(fullDirPath, { recursive: true });
    createdDirs.push(fullDirPath);

    const gitkeepPath = path.join(fullDirPath, ".gitkeep");
    if (!fsSync.existsSync(gitkeepPath)) {
      await fs.writeFile(gitkeepPath, "", "utf8");
    }
  }

  // Ensure .agents/state and cases directory
  await fs.mkdir(stateDir, { recursive: true });
  createdDirs.push(stateDir);
  const casesDir = path.join(stateDir, "cases");
  await fs.mkdir(casesDir, { recursive: true });
  createdDirs.push(casesDir);
  const casesGitkeep = path.join(casesDir, ".gitkeep");
  if (!fsSync.existsSync(casesGitkeep)) {
    await fs.writeFile(casesGitkeep, "", "utf8");
  }

  // 1. Initialize active_case.json from template or clean state
  let activeCaseContent: string;
  const templatePath = path.join(targetRoot, "templates", "11-ACTIVE-CASE-TEMPLATE.json");
  let fallbackTemplatePath = "";
  try {
    fallbackTemplatePath = path.join(findRepoRoot(), "templates", "11-ACTIVE-CASE-TEMPLATE.json");
  } catch {
    // ignore
  }

  if (fsSync.existsSync(templatePath)) {
    activeCaseContent = await fs.readFile(templatePath, "utf8");
  } else if (fallbackTemplatePath && fsSync.existsSync(fallbackTemplatePath)) {
    activeCaseContent = await fs.readFile(fallbackTemplatePath, "utf8");
  } else {
    activeCaseContent = JSON.stringify(
      {
        schema_version: 2,
        case_id: "CASE-INITIAL",
        target_name: null,
        target_class: "ANDROID_APK",
        development_strategy: null,
        delivery_platform: null,
        build_strategy: null,
        build_route: null,
        current_phase: "STAGE_00_BOOTSTRAP",
        current_step: "00_PROJECT_BOOTSTRAP",
        current_gate_status: "GATE_00_READY",
        next_prompt_guide:
          "Dán 'prompts/00-WORKFLOW-ROUTER.md' để phân loại luồng yêu cầu (Router) hoặc 'prompts/01-TAB-DISCOVERY.md' để bắt đầu tiếp nhận app.",
        revision: 1,
        backup_verified: false,
        workflow: {
          mode: "NEW_CASE",
          parent_case_id: null,
          change_request_id: null,
          run_id: "RUN-001",
          target_fingerprint: null,
          execution_plan: {
            path: "HAPPY_PATH_FULL",
            steps_mandatory: [
              "01_APP_INTAKE",
              "02_BASELINE_MEASUREMENT",
              "05_REA_AUDIT",
              "08_IMPLEMENTATION_PLAN",
              "09_REA_BUILD",
              "10_BUILD_QA",
              "11_SMOKE_TEST",
              "13_RELEASE_AND_HANDOFF",
            ],
            steps_conditional: [
              "03_REA_SCAN",
              "04_DEEP_INVESTIGATION",
              "06_REA_INTERVIEW",
              "07_UI_SPEC",
              "12_HARD_VERIFY",
            ],
            steps_skipped: [],
            steps_waived: [],
          },
          step_records: {},
          skip_records: [],
          invalidation_history: [],
          reused_artifacts: [],
        },
        gates: {
          gate_01_baseline_verified: {
            state: "NOT_STARTED",
            baseline_type: null,
            evidence: [],
            evidence_sha256: null,
            approved_by: null,
            approved_at: null,
            revoked_reason: null,
            waived_reason: null,
            skip_reason: null,
          },
          gate_02_audit_passed: {
            state: "NOT_STARTED",
            evidence: [],
            evidence_sha256: null,
            approved_by: null,
            approved_at: null,
            revoked_reason: null,
            waived_reason: null,
            skip_reason: null,
          },
          gate_03_spec_frozen: {
            state: "NOT_STARTED",
            evidence: [],
            evidence_sha256: null,
            approved_by: null,
            approved_at: null,
            revoked_reason: null,
            waived_reason: null,
            skip_reason: null,
          },
          gate_04_build_qa_passed: {
            state: "NOT_STARTED",
            evidence: [],
            evidence_sha256: null,
            approved_by: null,
            approved_at: null,
            revoked_reason: null,
            waived_reason: null,
            skip_reason: null,
          },
          gate_05_hard_verify_passed: {
            state: "NOT_STARTED",
            evidence: [],
            evidence_sha256: null,
            approved_by: null,
            approved_at: null,
            revoked_reason: null,
            waived_reason: null,
            skip_reason: null,
          },
          gate_06_handoff_signed: {
            state: "NOT_STARTED",
            evidence: [],
            evidence_sha256: null,
            approved_by: null,
            approved_at: null,
            revoked_reason: null,
            waived_reason: null,
            skip_reason: null,
          },
        },
        metrics: {
          risk_level: "UNASSESSED",
          review_convergence_rounds: 0,
          max_convergence_rounds: 2,
        },
      },
      null,
      2
    );
  }

  // Ensure JSON formatting and NO BOM
  try {
    const clean = activeCaseContent.charCodeAt(0) === 0xfeff ? activeCaseContent.slice(1) : activeCaseContent;
    const parsed = JSON.parse(clean);
    activeCaseContent = JSON.stringify(parsed, null, 2);
  } catch {
    // Keep as is
  }
  await writeUtf8NoBomAtomic(activeCasePath, activeCaseContent);

  // 2. Initialize interview_state.json with status NOT_STARTED and empty arrays
  const now = new Date().toISOString();
  const cleanInterviewState = {
    schema_version: 1,
    case_id: "CASE-INITIAL",
    session: {
      session_id: "INT-SESSION-INITIAL",
      status: "NOT_STARTED",
      current_goal: null,
      current_stage: "STAGE_03_PRODUCT_DEFINITION",
      active_domain: null,
      design_mode: null,
      max_clarification_per_goal: 2,
      max_total_questions: 15,
      created_at: now,
      updated_at: now,
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
      evaluated_at: now,
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
    last_updated: now,
  };
  await writeUtf8NoBomAtomic(interviewStatePath, JSON.stringify(cleanInterviewState, null, 2));

  // 3. Initialize events.jsonl with exactly 1 line (EVT-0000, WORKSPACE_INIT)
  const initialEvent = {
    event_id: "EVT-0000",
    timestamp: "2026-11-14T08:00:00+07:00",
    case_id: "CASE-INITIAL",
    actor: "system",
    action: "WORKSPACE_INIT",
    phase: "STAGE_00_BOOTSTRAP",
    step: "00_PROJECT_BOOTSTRAP",
    details:
      "Khởi tạo workspace REA-kit-agy v2.0 với kiến trúc điều phối DAG (RWO v2), 4 tầng bộ nhớ Anthropic và 6 cổng kiểm soát chất lượng.",
    evidence_sha256: null,
  };
  const eventLine = JSON.stringify(initialEvent) + "\n";
  await writeUtf8NoBomAtomic(eventsPath, eventLine);

  return {
    root: targetRoot,
    createdDirs,
    initializedFiles: [activeCasePath, interviewStatePath, eventsPath],
  };
}
