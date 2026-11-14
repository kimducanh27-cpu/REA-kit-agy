import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import os from "node:os";
import {
  getTargetAppInfo,
  saveCaseStateAtomic,
  loadCaseState,
  archiveCurrentCaseAndReset,
  invalidateSubsequentGates,
  runGateAction,
  validateGate,
  GATE_ORDER,
  type ActiveCaseState,
} from "../src/core/gate.js";
import { writeUtf8NoBomAtomic } from "../src/core/state-lock.js";

describe("Stream 2: Gate Engine, Directory Fingerprinting & Concurrency Tests", () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "rea-stream2-test-"));

    // Standard workspace directories
    await fs.mkdir(path.join(tmpDir, "01_THA_APP_VAO_DAY"), { recursive: true });
    await fs.mkdir(path.join(tmpDir, "02_YEU_CAU_CUA_TOI"), { recursive: true });
    await fs.mkdir(path.join(tmpDir, "03_KET_QUA_KIEM_TRA"), { recursive: true });
    await fs.mkdir(path.join(tmpDir, "04_SAO_LUU_AN_TOAN"), { recursive: true });
    await fs.mkdir(path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN"), { recursive: true });

    // Seed active_case.json
    const stateDir = path.join(tmpDir, ".agents", "state");
    await fs.mkdir(stateDir, { recursive: true });

    const initialCase: ActiveCaseState = {
      schema_version: 2,
      case_id: "CASE-STREAM2-001",
      target_name: null,
      target_class: "ANDROID_APP",
      current_phase: "STAGE_01_DISCOVERY",
      current_step: "01_APP_INTAKE",
      current_gate_status: "GATE_00_READY",
      revision: 1,
      workflow: {
        mode: "NEW_CASE",
        parent_case_id: null,
        run_id: "RUN-001",
        target_fingerprint: null,
      },
      gates: {
        gate_01_baseline_verified: {
          state: "NOT_STARTED",
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
        risk_level: "LOW",
        review_convergence_rounds: 0,
        max_convergence_rounds: 2,
      },
    };

    await writeUtf8NoBomAtomic(
      path.join(stateDir, "active_case.json"),
      JSON.stringify(initialCase, null, 2)
    );
  });

  afterEach(async () => {
    try {
      await fs.rm(tmpDir, { recursive: true, force: true });
    } catch {
      // Ignore
    }
  });

  describe("Directory App Fingerprinting", () => {
    it("should compute deterministic SHA-256 over sorted relPath:sha256 composite string", async () => {
      const appDir = path.join(tmpDir, "01_THA_APP_VAO_DAY", "my_app_folder");
      await fs.mkdir(path.join(appDir, "src", "sub"), { recursive: true });

      // Create files in unsorted order
      await fs.writeFile(path.join(appDir, "src", "index.ts"), "console.log('index')");
      await fs.writeFile(path.join(appDir, "src", "sub", "util.ts"), "export const x = 1;");
      await fs.writeFile(path.join(appDir, "package.json"), JSON.stringify({ name: "my-app" }));

      const info1 = await getTargetAppInfo(tmpDir);
      expect(info1).not.toBeNull();
      expect(info1!.type).toBe("DIRECTORY");
      expect(info1!.name).toBe("my_app_folder");
      expect(info1!.sha256).toMatch(/^[A-F0-9]{64}$/);
      expect(info1!.length).toBe(3);

      // Re-read should be identical
      const info2 = await getTargetAppInfo(tmpDir);
      expect(info2!.sha256).toBe(info1!.sha256);

      // Modify content of an internal file without changing size
      // 'console.log('index')' -> 'console.log('hello')' (same character count!)
      await fs.writeFile(path.join(appDir, "src", "index.ts"), "console.log('hello')");

      const info3 = await getTargetAppInfo(tmpDir);
      expect(info3!.sha256).not.toBe(info1!.sha256);
    });
  });

  describe("Optimistic Concurrency & Revision Calculation", () => {
    it("should calculate state.revision as Math.max(diskState.revision, currentRev) + 1 to prevent regression", async () => {
      const state = await loadCaseState(tmpDir);
      expect(state.revision).toBe(1);

      // Save normally
      const s1 = await saveCaseStateAtomic(tmpDir, state, 1);
      expect(s1.revision).toBe(2);

      // Stale object passing revision: 1 with force: true must still advance beyond disk (2 -> 3)
      const staleState: ActiveCaseState = { ...state, revision: 1 };
      const s2 = await saveCaseStateAtomic(tmpDir, staleState, -1, true);
      expect(s2.revision).toBe(3);

      // If state object had ahead revision 5, next is 6
      const aheadState: ActiveCaseState = { ...s2, revision: 5 };
      const s3 = await saveCaseStateAtomic(tmpDir, aheadState, -1, true);
      expect(s3.revision).toBe(6);
    });
  });

  describe("archiveCurrentCaseAndReset with interview_state.json file lock", () => {
    it("should safely archive and reset interview_state.json inside file lock", async () => {
      const interviewStatePath = path.join(tmpDir, ".agents", "state", "interview_state.json");
      const sampleInterview = {
        schema_version: 1,
        case_id: "CASE-STREAM2-001",
        session: { status: "IN_PROGRESS" },
        goals: [{ goal_id: "G-001", description: "Goal 1" }],
      };
      await fs.writeFile(interviewStatePath, JSON.stringify(sampleInterview, null, 2));

      const state = await loadCaseState(tmpDir);
      const targetApp = {
        name: "test_new.apk",
        path: path.join(tmpDir, "01_THA_APP_VAO_DAY", "test_new.apk"),
        relativePath: "01_THA_APP_VAO_DAY/test_new.apk",
        sha256: "FEEDFACE12345678",
        type: "FILE" as const,
        length: 100,
      };

      const newState = await archiveCurrentCaseAndReset(tmpDir, state, targetApp, "New APK loaded");
      expect(newState.case_id).toMatch(/^CASE-\d+-\d+-[a-f0-9]{4}$/);
      expect(newState.case_id).not.toBe("CASE-STREAM2-001");

      // Verify archived interview_state.json exists in old case folder
      const oldCaseFolder = path.join(tmpDir, ".agents", "state", "cases", "CASE-STREAM2-001");
      const archivedInterviewPath = path.join(oldCaseFolder, "interview_state.json");
      expect(fsSync.existsSync(archivedInterviewPath)).toBe(true);

      const archivedContent = JSON.parse(await fs.readFile(archivedInterviewPath, "utf8"));
      expect(archivedContent.case_id).toBe("CASE-STREAM2-001");
      expect(archivedContent.goals.length).toBe(1);

      // Verify active interview_state.json is reset to clean state
      const cleanInterview = JSON.parse(await fs.readFile(interviewStatePath, "utf8"));
      expect(cleanInterview.case_id).toBe(newState.case_id);
      expect(cleanInterview.session.status).toBe("NOT_STARTED");
      expect(cleanInterview.goals.length).toBe(0);
    });
  });

  describe("Gate 02 Custom Evidence Path & Windows Backslash Normalization", () => {
    it("should allow custom evidence path for Gate 02 and normalize backslashes in evidence_hashes", async () => {
      // 1. Open Gate 01 first
      const ev1 = path.join(tmpDir, "02_YEU_CAU_CUA_TOI", "baseline.md");
      await fs.writeFile(ev1, "Gate 1 baseline");
      await runGateAction({
        repoRoot: tmpDir,
        action: "open",
        gate: "gate_01_baseline_verified",
        evidence: "02_YEU_CAU_CUA_TOI/baseline.md",
      });

      // 2. Create custom evidence for Gate 02 (named CUSTOM_SPEC.md, with NO APP_FLOW_SPEC.md on disk)
      const customSpecPath = path.join(tmpDir, "03_KET_QUA_KIEM_TRA", "CUSTOM_SPEC.md");
      await fs.writeFile(
        customSpecPath,
        "# Custom Flow Spec\nScreen 1 [EV: MainActivity.kt#init]\nScreen 2 [EV: SettingsActivity.kt#load]"
      );

      // Verify APP_FLOW_SPEC.md does NOT exist
      expect(fsSync.existsSync(path.join(tmpDir, "03_KET_QUA_KIEM_TRA", "APP_FLOW_SPEC.md"))).toBe(false);

      // Update active_case.json with custom evidence path containing Windows backslashes
      const state = await loadCaseState(tmpDir);
      const customSpecRelWin = "03_KET_QUA_KIEM_TRA\\CUSTOM_SPEC.md";
      const customSpecRelNorm = "03_KET_QUA_KIEM_TRA/CUSTOM_SPEC.md";
      const { getNormalizedFileHash } = await import("../src/core/gate.js");
      const hash = await getNormalizedFileHash(customSpecPath);

      state.gates.gate_02_audit_passed = {
        state: "PASS",
        evidence: [customSpecRelWin],
        evidence_sha256: hash,
        evidence_hashes: {
          [customSpecRelWin]: hash, // Windows backslash in key!
        },
        approved_by: "coordinator",
        approved_at: new Date().toISOString(),
        revoked_reason: null,
        waived_reason: null,
        skip_reason: null,
      };
      await saveCaseStateAtomic(tmpDir, state, -1, true);

      // Validate gate should pass with custom evidence and normalize Windows backslash keys in evidence_hashes
      const val = await validateGate({ repoRoot: tmpDir });
      expect(val.valid).toBe(true);
      expect(val.errors).toEqual([]);
    });
  });

  describe("Selective Invalidation in invalidateSubsequentGates", () => {
    it("should only invalidate gates that are COMPLETED or IN_PROGRESS, leaving NOT_STARTED untouched", () => {
      const state: ActiveCaseState = {
        schema_version: 2,
        case_id: "CASE-INVALIDATE-TEST",
        target_name: "app",
        target_class: "ANDROID_APP",
        current_phase: "STAGE_03_PRODUCT_DEFINITION",
        current_step: "06_REA_INTERVIEW",
        current_gate_status: "GATE_03_PASS",
        revision: 4,
        workflow: {},
        gates: {
          gate_01_baseline_verified: { state: "PASS", evidence: ["ev1"], evidence_sha256: "H1" },
          gate_02_audit_passed: { state: "PASS", evidence: ["ev2"], evidence_sha256: "H2" },
          gate_03_spec_frozen: { state: "IN_PROGRESS", evidence: [], evidence_sha256: null },
          gate_04_build_qa_passed: { state: "NOT_STARTED", evidence: [], evidence_sha256: null },
          gate_05_hard_verify_passed: { state: "NOT_STARTED", evidence: [], evidence_sha256: null },
          gate_06_handoff_signed: { state: "NOT_STARTED", evidence: [], evidence_sha256: null },
        },
        metrics: { risk_level: "LOW" },
      };

      // Invalidate starting from gate 02
      const revoked = invalidateSubsequentGates(state, "gate_02_audit_passed", "Spec revision required");

      // gate_02 (PASS) and gate_03 (IN_PROGRESS) must be invalidated
      expect(revoked).toContain("gate_02_audit_passed");
      expect(revoked).toContain("gate_03_spec_frozen");
      expect(state.gates.gate_02_audit_passed.state).toBe("INVALIDATED");
      expect(state.gates.gate_03_spec_frozen.state).toBe("INVALIDATED");

      // gate_01 (upstream) must remain PASS
      expect(state.gates.gate_01_baseline_verified.state).toBe("PASS");

      // gate_04, gate_05, gate_06 were NOT_STARTED -> must REMAIN NOT_STARTED!
      expect(state.gates.gate_04_build_qa_passed.state).toBe("NOT_STARTED");
      expect(state.gates.gate_05_hard_verify_passed.state).toBe("NOT_STARTED");
      expect(state.gates.gate_06_handoff_signed.state).toBe("NOT_STARTED");
      expect(revoked).not.toContain("gate_04_build_qa_passed");
    });
  });

  describe("CLI Exit Codes", () => {
    it("should exit with code 1 on gate validate failure", async () => {
      const { spawnSync } = await import("node:child_process");
      const cliDistPath = path.resolve(__dirname, "../dist/cli.js");

      // In tmpDir with invalid active_case.json (e.g. create a forbidden file in 01_THA_APP_VAO_DAY)
      await fs.writeFile(path.join(tmpDir, "01_THA_APP_VAO_DAY", "leak.tmp"), "corrupt");

      const proc = spawnSync(
        process.execPath,
        [cliDistPath, "gate", "validate"],
        {
          cwd: tmpDir,
          encoding: "utf8",
        }
      );

      expect(proc.status).toBe(1);
      expect(proc.stdout).toContain('"valid": false');
    });
  });
});
