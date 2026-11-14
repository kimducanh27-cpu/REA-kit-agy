import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";

import {
  createSnapshot,
  restoreSnapshot,
  computeFileSha256,
  generateSnapshotTimestamp,
} from "../src/core/rollback.js";
import {
  runGateAction,
  loadCaseState,
  saveCaseStateAtomic,
  resolveGateName,
  getNormalizedFileHash,
  testInputDirectoryImmutability,
  getTargetAppInfo,
  ConcurrencyConflictError,
  GATE_ORDER,
} from "../src/core/gate.js";
import {
  estimateTokens,
  resolveProfileName,
  extractMarkdownSections,
  planContext,
  inspectPlan,
  packContext,
  verifyPacket,
} from "../src/core/context.js";
import { writeUtf8NoBomAtomic } from "../src/core/state-lock.js";

describe("Phase 2 Core Infrastructure Tests", () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "rea-phase2-test-"));

    // Set up standard workspace structure
    await fs.mkdir(path.join(tmpDir, "docs"), { recursive: true });
    await fs.writeFile(
      path.join(tmpDir, "docs", "WORKFLOW_LIFECYCLE.md"),
      "# REA Lifecycle\nDeterministic workflow anchor."
    );

    await fs.mkdir(path.join(tmpDir, "01_THA_APP_VAO_DAY"), { recursive: true });
    await fs.writeFile(
      path.join(tmpDir, "01_THA_APP_VAO_DAY", "README.md"),
      "# Input Dropzone"
    );

    await fs.mkdir(path.join(tmpDir, "02_YEU_CAU_CUA_TOI"), { recursive: true });
    await fs.mkdir(path.join(tmpDir, "03_KET_QUA_KIEM_TRA"), { recursive: true });
    await fs.mkdir(path.join(tmpDir, "04_SAO_LUU_AN_TOAN"), { recursive: true });
    await fs.mkdir(path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN"), { recursive: true });

    // Seed active_case.json
    const stateDir = path.join(tmpDir, ".agents", "state");
    await fs.mkdir(stateDir, { recursive: true });

    const initialCase = {
      schema_version: 2,
      case_id: "CASE-TEST-001",
      target_name: "test_target",
      target_class: "ANDROID_APK",
      current_phase: "STAGE_01_DISCOVERY",
      current_step: "01_APP_INTAKE",
      current_gate_status: "GATE_00_READY",
      revision: 1,
      last_updated: new Date().toISOString(),
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

    // Seed context manifest and profiles
    const contextDir = path.join(tmpDir, ".agents", "context");
    await fs.mkdir(path.join(contextDir, "profiles"), { recursive: true });

    const contextManifest = {
      schema_version: 1,
      manifest_id: "MANIFEST-TEST",
      default_budget: {
        model_capacity: 100000,
        reserved_output: 5000,
        reserved_tools: 5000,
        reserved_safety: 10000,
        usable_budget: 80000,
      },
      documents: [
        {
          id: "DOC-CONTRACT",
          path: "docs/WORKFLOW_LIFECYCLE.md",
          layer: "L0",
          load_policy: "ALWAYS",
          load_mode: "FULL",
          estimated_tokens: 500,
        },
        {
          id: "DOC-STATE",
          path: ".agents/state/active_case.json",
          layer: "L1",
          load_policy: "ALWAYS",
          load_mode: "FULL",
          estimated_tokens: 800,
        },
        {
          id: "DOC-SPEC",
          path: "03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md",
          layer: "L3",
          load_policy: "CONDITIONAL",
          load_mode: "SECTION_RETRIEVAL",
          sections: ["Flow", "Screens"],
          estimated_tokens: 1200,
          condition: {
            stages: ["STAGE_02_REVERSE_ENGINEERING", "STAGE_03_PRODUCT_DEFINITION"],
            profiles: ["discovery", "design"],
          },
        },
        {
          id: "EVIDENCE-RAW",
          path: "03_KET_QUA_KIEM_TRA/dump.bin",
          layer: "L5",
          load_policy: "ALWAYS",
          load_mode: "FULL",
          estimated_tokens: 300,
          tags: ["untrusted"],
        },
      ],
    };

    await writeUtf8NoBomAtomic(
      path.join(contextDir, "context-manifest.json"),
      JSON.stringify(contextManifest, null, 2)
    );

    const discoveryProfile = {
      profile_id: "discovery",
      name: "Discovery Profile",
      context_budget_target: 60000,
      included_documents: [{ id: "DOC-CONTRACT", mode: "FULL" }],
      forbidden_contexts: ["01_THA_APP_VAO_DAY/"],
    };
    await writeUtf8NoBomAtomic(
      path.join(contextDir, "profiles", "discovery.json"),
      JSON.stringify(discoveryProfile, null, 2)
    );
  });

  afterEach(async () => {
    try {
      await fs.rm(tmpDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup error
    }
  });

  // =========================================================================
  // 1. Rollback & Snapshot Engine Tests
  // =========================================================================
  describe("Rollback & Snapshot Engine (src/core/rollback.ts)", () => {
    it("should skip snapshot creation when build directory is empty or contains only .gitkeep", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.writeFile(path.join(srcDir, ".gitkeep"), "");

      const res = await createSnapshot({ repoRoot: tmpDir });
      expect(res.created).toBe(false);
      expect(res.reason).toContain("No real source files");
    });

    it("should create atomic snapshot with SHA-256 manifest.json and exclude ignored files", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.writeFile(path.join(srcDir, "MainActivity.kt"), "class MainActivity : ComponentActivity()");
      await fs.mkdir(path.join(srcDir, "sub"), { recursive: true });
      await fs.writeFile(path.join(srcDir, "sub", "Utils.kt"), "object Utils {}");

      // Ignored items
      await fs.writeFile(path.join(srcDir, ".gitkeep"), "");
      await fs.mkdir(path.join(srcDir, "node_modules"), { recursive: true });
      await fs.writeFile(path.join(srcDir, "node_modules", "package.json"), "{}");
      await fs.mkdir(path.join(srcDir, "build"), { recursive: true });
      await fs.writeFile(path.join(srcDir, "build", "output.apk"), "fake apk");

      const res = await createSnapshot({ repoRoot: tmpDir });
      expect(res.created).toBe(true);
      expect(res.fileCount).toBe(2);
      expect(res.snapshotDir).toBeDefined();

      const manifestPath = path.join(res.snapshotDir!, "manifest.json");
      expect(fsSync.existsSync(manifestPath)).toBe(true);

      const manifest = JSON.parse(await fs.readFile(manifestPath, "utf8"));
      expect(manifest.file_count).toBe(2);
      expect(manifest.files.some((f: any) => f.path === "MainActivity.kt")).toBe(true);
      expect(manifest.files.some((f: any) => f.path === "sub/Utils.kt")).toBe(true);
      expect(manifest.files.some((f: any) => f.path.includes("node_modules"))).toBe(false);

      // Verify SHA-256 matches actual copied file
      const copiedMain = path.join(res.snapshotDir!, "MainActivity.kt");
      const hash = await computeFileSha256(copiedMain);
      const manifestEntry = manifest.files.find((f: any) => f.path === "MainActivity.kt");
      expect(manifestEntry.sha256).toBe(hash);
    });

    it("should enforce maxSnapshots rotation to prevent disk bloat", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.writeFile(path.join(srcDir, "app.js"), "console.log('v1')");

      const backupDir = path.join(tmpDir, "04_SAO_LUU_AN_TOAN");

      // Pre-create 5 snapshot directories
      for (let i = 1; i <= 5; i++) {
        const snapDir = path.join(backupDir, `20261114_10000${i}_000`);
        await fs.mkdir(snapDir, { recursive: true });
        await fs.writeFile(path.join(snapDir, "app.js"), `v${i}`);
        await fs.writeFile(path.join(snapDir, "manifest.json"), JSON.stringify({ files: [] }));
      }

      // Create snapshot with maxSnapshots = 3
      const res = await createSnapshot({ repoRoot: tmpDir, maxSnapshots: 3 });
      expect(res.created).toBe(true);

      const entries = await fs.readdir(backupDir);
      const dirs = entries.filter((e) => !e.startsWith("."));
      expect(dirs.length).toBe(3);
    });

    it("should restore latest snapshot with 2-phase atomic swap and 100% SHA-256 verification", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.writeFile(path.join(srcDir, "fileA.txt"), "Original Content A");
      await fs.writeFile(path.join(srcDir, "fileB.txt"), "Original Content B");

      // 1. Snapshot original state
      const snapRes = await createSnapshot({ repoRoot: tmpDir });
      expect(snapRes.created).toBe(true);

      // 2. Corrupt/modify source directory
      await fs.writeFile(path.join(srcDir, "fileA.txt"), "Corrupted Content");
      await fs.unlink(path.join(srcDir, "fileB.txt"));
      await fs.writeFile(path.join(srcDir, "junk.txt"), "Junk file");

      // 3. Restore snapshot
      const restoreRes = await restoreSnapshot({ repoRoot: tmpDir });
      expect(restoreRes.restored).toBe(true);
      expect(restoreRes.snapshotId).toBe(snapRes.snapshotId);

      // Verify files restored completely
      expect(await fs.readFile(path.join(srcDir, "fileA.txt"), "utf8")).toBe("Original Content A");
      expect(await fs.readFile(path.join(srcDir, "fileB.txt"), "utf8")).toBe("Original Content B");
      expect(fsSync.existsSync(path.join(srcDir, "junk.txt"))).toBe(false);
    });

    it("should abort restore and roll back safely if snapshot manifest SHA-256 is tampered", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.writeFile(path.join(srcDir, "secure.txt"), "Legitimate Code");

      const snapRes = await createSnapshot({ repoRoot: tmpDir });
      expect(snapRes.created).toBe(true);

      // Tamper with the snapshot file without updating manifest
      const snapshotFile = path.join(snapRes.snapshotDir!, "secure.txt");
      await fs.writeFile(snapshotFile, "Tampered Malicious Code");

      // Modify source directory
      await fs.writeFile(path.join(srcDir, "current.txt"), "Keep me safe");

      // Attempt restore -> should throw SHA mismatch error
      await expect(restoreSnapshot({ repoRoot: tmpDir })).rejects.toThrow(/SHA-256 hash mismatch/);

      // Verify build directory was rolled back safely and not destroyed
      expect(fsSync.existsSync(path.join(srcDir, "current.txt"))).toBe(true);
    });
  });

  // =========================================================================
  // 2. Gate Controller & State Machine Tests
  // =========================================================================
  describe("Gate Controller & State Machine (src/core/gate.ts)", () => {
    it("should report gate status correctly", async () => {
      const status = await runGateAction({ repoRoot: tmpDir, action: "status" });
      expect(status.case_id).toBe("CASE-TEST-001");
      expect(status.current_gate_status).toBe("GATE_00_READY");
      expect(status.gates.gate_01_baseline_verified.state).toBe("NOT_STARTED");
    });

    it("should resolve gate aliases accurately", () => {
      expect(resolveGateName("1")).toBe("gate_01_baseline_verified");
      expect(resolveGateName("01")).toBe("gate_01_baseline_verified");
      expect(resolveGateName("baseline")).toBe("gate_01_baseline_verified");
      expect(resolveGateName("gate_02")).toBe("gate_02_audit_passed");
      expect(resolveGateName("spec")).toBe("gate_03_spec_frozen");
      expect(resolveGateName("qa")).toBe("gate_04_build_qa_passed");
      expect(resolveGateName("hard")).toBe("gate_05_hard_verify_passed");
      expect(resolveGateName("handoff")).toBe("gate_06_handoff_signed");
    });

    it("should enforce DAG predecessor checks when opening gates", async () => {
      // Create evidence for gate 2
      const evFile = path.join(tmpDir, "03_KET_QUA_KIEM_TRA", "audit.md");
      await fs.writeFile(evFile, "Audit passed");

      // Cannot open gate 2 because gate 1 is NOT_STARTED
      await expect(
        runGateAction({
          repoRoot: tmpDir,
          action: "open",
          gate: "gate_02_audit_passed",
          evidence: "03_KET_QUA_KIEM_TRA/audit.md",
        })
      ).rejects.toThrow(/ancestor gate gate_01_baseline_verified has not cleared/);
    });

    it("should enforce 01_THA_APP_VAO_DAY immutability check on evidence", async () => {
      // 1. Open gate 1 (gate 1 is allowed to reference 01_THA_APP_VAO_DAY)
      const ev1 = path.join(tmpDir, "01_THA_APP_VAO_DAY", "README.md");
      const res1 = await runGateAction({
        repoRoot: tmpDir,
        action: "open",
        gate: "gate_01_baseline_verified",
        evidence: "01_THA_APP_VAO_DAY/README.md",
      });
      expect(res1.status).toBe("PASS");

      // 2. Try to open gate 2 with evidence pointing to 01_THA_APP_VAO_DAY
      await expect(
        runGateAction({
          repoRoot: tmpDir,
          action: "open",
          gate: "gate_02_audit_passed",
          evidence: "01_THA_APP_VAO_DAY/README.md",
        })
      ).rejects.toThrow(/Immutability Violation/);
    });

    it("should enforce APP_FLOW_SPEC.md and Evidence Anchors [EV: ...] for gate 2", async () => {
      // Open gate 1 first
      const ev1 = path.join(tmpDir, "02_YEU_CAU_CUA_TOI", "baseline.md");
      await fs.writeFile(ev1, "Baseline data");
      await runGateAction({
        repoRoot: tmpDir,
        action: "open",
        gate: "gate_01_baseline_verified",
        evidence: "02_YEU_CAU_CUA_TOI/baseline.md",
      });

      // Try opening gate 2 when APP_FLOW_SPEC.md is missing
      const ev2 = path.join(tmpDir, "03_KET_QUA_KIEM_TRA", "audit.md");
      await fs.writeFile(ev2, "Audit result");
      await expect(
        runGateAction({
          repoRoot: tmpDir,
          action: "open",
          gate: "gate_02_audit_passed",
          evidence: "03_KET_QUA_KIEM_TRA/audit.md",
        })
      ).rejects.toThrow(/missing app flow spec/);

      // Create APP_FLOW_SPEC.md without [EV: ...]
      const appFlowFile = path.join(tmpDir, "03_KET_QUA_KIEM_TRA", "APP_FLOW_SPEC.md");
      await fs.writeFile(appFlowFile, "# Flow Spec without anchors");

      await expect(
        runGateAction({
          repoRoot: tmpDir,
          action: "open",
          gate: "gate_02_audit_passed",
          evidence: "03_KET_QUA_KIEM_TRA/audit.md",
        })
      ).rejects.toThrow(/does not contain valid Evidence Anchors/);

      // Add valid [EV: ...] anchor and retry
      await fs.writeFile(
        appFlowFile,
        "# Flow Spec\nScreen A [EV: MainActivity.java#onCreate]\nScreen B [EV: LoginActivity.java#login]"
      );

      const res2 = await runGateAction({
        repoRoot: tmpDir,
        action: "open",
        gate: "gate_02_audit_passed",
        evidence: "03_KET_QUA_KIEM_TRA/audit.md",
      });
      expect(res2.status).toBe("PASS");

      // Verify event logged in events.jsonl
      const eventsFile = path.join(tmpDir, ".agents", "state", "events.jsonl");
      const eventContent = await fs.readFile(eventsFile, "utf8");
      expect(eventContent).toContain("GATE_OPEN");
    });

    it("should support waive and skip actions with reason and audit logging", async () => {
      // Open gate 1
      const ev1 = path.join(tmpDir, "02_YEU_CAU_CUA_TOI", "baseline.md");
      await fs.writeFile(ev1, "Baseline data");
      await runGateAction({
        repoRoot: tmpDir,
        action: "open",
        gate: "1",
        evidence: "02_YEU_CAU_CUA_TOI/baseline.md",
      });

      // Waive gate 2
      const waiveRes = await runGateAction({
        repoRoot: tmpDir,
        action: "waive",
        gate: "2",
        reason: "Static analysis only requested",
      });
      expect(waiveRes.status).toBe("WAIVED");

      // Skip gate 3 with mode NOT_APPLICABLE
      const skipRes = await runGateAction({
        repoRoot: tmpDir,
        action: "skip",
        gate: "3",
        mode: "NOT_APPLICABLE",
        reason: "No UI redesign needed",
      });
      expect(skipRes.status).toBe("NOT_APPLICABLE");

      const state = await loadCaseState(tmpDir);
      expect(state.gates.gate_02_audit_passed.state).toBe("WAIVED");
      expect(state.gates.gate_03_spec_frozen.state).toBe("NOT_APPLICABLE");
    });

    it("should execute cascade invalidation when rejecting a gate", async () => {
      // Setup: Open gate 1, 2, 3
      const ev1 = path.join(tmpDir, "02_YEU_CAU_CUA_TOI", "ev1.md");
      await fs.writeFile(ev1, "ev1");
      await runGateAction({ repoRoot: tmpDir, action: "open", gate: "1", evidence: "02_YEU_CAU_CUA_TOI/ev1.md" });

      const appFlow = path.join(tmpDir, "03_KET_QUA_KIEM_TRA", "APP_FLOW_SPEC.md");
      await fs.writeFile(appFlow, "Anchor [EV: Main#onCreate]");
      await runGateAction({ repoRoot: tmpDir, action: "open", gate: "2", evidence: "03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md" });

      const ev3 = path.join(tmpDir, "02_YEU_CAU_CUA_TOI", "spec.md");
      await fs.writeFile(ev3, "spec frozen");
      await runGateAction({ repoRoot: tmpDir, action: "open", gate: "3", evidence: "02_YEU_CAU_CUA_TOI/spec.md" });

      // Reject gate 2
      const rejRes = await runGateAction({
        repoRoot: tmpDir,
        action: "reject",
        gate: "gate_02_audit_passed",
        reason: "Audit incomplete",
      });

      expect(rejRes.status).toBe("INVALIDATED");
      expect(rejRes.revert_phase).toBe("STAGE_02_REVERSE_ENGINEERING");
      expect(rejRes.revert_step).toBe("03_REA_SCAN");

      const state = await loadCaseState(tmpDir);
      expect(state.gates.gate_01_baseline_verified.state).toBe("PASS"); // Not revoked
      expect(state.gates.gate_02_audit_passed.state).toBe("INVALIDATED");
      expect(state.gates.gate_03_spec_frozen.state).toBe("INVALIDATED"); // Downstream revoked
      expect(state.current_phase).toBe("STAGE_02_REVERSE_ENGINEERING");
    });

    it("should block gate transition when exceeding review convergence limit", async () => {
      const state = await loadCaseState(tmpDir);
      state.metrics.review_convergence_rounds = 2;
      state.metrics.max_convergence_rounds = 2;
      await saveCaseStateAtomic(tmpDir, state, -1, true);

      const rejRes = await runGateAction({
        repoRoot: tmpDir,
        action: "reject",
        gate: "gate_01_baseline_verified",
        reason: "Third rejection loop",
      });

      expect(rejRes.status).toBe("BLOCKED");
      const updatedState = await loadCaseState(tmpDir);
      expect(updatedState.gates.gate_01_baseline_verified.state).toBe("BLOCKED");
    });

    it("should enforce optimistic concurrency control via revision checks", async () => {
      const state = await loadCaseState(tmpDir);
      const staleRev = state.revision;

      // Update state in background
      await saveCaseStateAtomic(tmpDir, { ...state }, -1, true);

      // Attempting to save with stale revision must throw ConcurrencyConflictError
      await expect(
        saveCaseStateAtomic(tmpDir, { ...state }, staleRev, false)
      ).rejects.toThrow(ConcurrencyConflictError);
    });

    it("should validate active case state and contract invariants", async () => {
      const val = await runGateAction({ repoRoot: tmpDir, action: "validate" });
      expect(val.valid).toBe(true);

      // Violate immutability by creating .tmp file in 01_THA_APP_VAO_DAY
      const tmpViolation = path.join(tmpDir, "01_THA_APP_VAO_DAY", "leak.tmp");
      await fs.writeFile(tmpViolation, "temp data");

      const valInvalid = await runGateAction({ repoRoot: tmpDir, action: "validate" });
      expect(valInvalid.valid).toBe(false);
      expect(valInvalid.errors.some((e: string) => e.includes("Forbidden temporary"))).toBe(true);
    });
  });

  // =========================================================================
  // 3. Context Engineering Engine Tests
  // =========================================================================
  describe("Context Engineering Engine (src/core/context.ts)", () => {
    it("should estimate tokens accurately using Vietnamese (2.0) and English/code (3.2) divisors", () => {
      expect(estimateTokens("")).toBe(0);

      // English string (40 chars) -> 40 / 3.2 = 12.5 -> ceil = 13
      const eng = "This is a clean English prompt for test.";
      expect(estimateTokens(eng)).toBe(Math.ceil(eng.length / 3.2));

      // Vietnamese string with >2% diacritics -> length / 2.0
      const vn = "Đây là văn bản tiếng Việt có dấu để đo lường token chính xác.";
      expect(estimateTokens(vn)).toBe(Math.ceil(vn.length / 2.0));
    });

    it("should classify task description intent into one of 6 profiles", () => {
      // Compound UI phrases prioritize design over optimization
      expect(resolveProfileName("tối ưu giao diện và bố cục navigation")).toBe("design");
      expect(resolveProfileName("optimize ui layout and animation")).toBe("design");

      // Security
      expect(resolveProfileName("kiểm tra lỗ hổng bảo mật và cve trong apk")).toBe("security");
      expect(resolveProfileName("audit permissions and hardcoded secrets")).toBe("security");

      // Performance optimization
      expect(resolveProfileName("tối ưu ram và giảm hao pin khi chạy background")).toBe("optimization");
      expect(resolveProfileName("profile memory leaks and fps drop")).toBe("optimization");

      // Design
      expect(resolveProfileName("chỉnh sửa thiết kế màu sắc theo W3C tokens")).toBe("design");
      expect(resolveProfileName("redesign color palette and theme typography")).toBe("design");

      // Validation
      expect(resolveProfileName("thực hiện nghiệm thu và smoke test")).toBe("validation");
      expect(resolveProfileName("run hard-verify matrix and prepare release")).toBe("validation");

      // Feature addition
      expect(resolveProfileName("thêm tính năng đăng nhập bằng Google")).toBe("feature-addition");
      expect(resolveProfileName("rebuild dashboard screen and add new cards")).toBe("feature-addition");

      // Discovery
      expect(resolveProfileName("khám phá bóc tách file APK đầu vào")).toBe("discovery");
      expect(resolveProfileName("intake target app and scan manifest")).toBe("discovery");

      // Stage fallback
      expect(resolveProfileName("", "STAGE_03_PRODUCT_DEFINITION")).toBe("design");
      expect(resolveProfileName("", "STAGE_04_IMPLEMENTATION")).toBe("feature-addition");
      expect(resolveProfileName("", "STAGE_05_VALIDATION")).toBe("validation");
    });

    it("should extract targeted markdown sections by title", () => {
      const md = `# Overview\nThis is overview.\n\n## Architecture\nArch details.\n\n### Database\nDB tables.\n\n## Deployment\nDeploy steps.`;
      const extracted = extractMarkdownSections(md, ["Architecture"]);
      expect(extracted).toContain("Arch details");
      expect(extracted).toContain("DB tables");
      expect(extracted).not.toContain("This is overview");
      expect(extracted).not.toContain("Deploy steps");
    });

    it("should generate context plan and pack L0-L5 layers with untrusted sandboxing and verification", async () => {
      // 1. Generate plan
      const plan = await planContext({
        repoRoot: tmpDir,
        task: "Khám phá và phân tích tĩnh APK đầu vào",
        stage: "STAGE_01_DISCOVERY",
      });

      expect(plan.plan_id).toBeDefined();
      expect(plan.profile).toBe("discovery");
      expect(plan.budget.usable_budget).toBeGreaterThan(0);
      expect(plan.selected_documents.length).toBeGreaterThan(0);

      // 2. Inspect plan
      const inspection = await inspectPlan({ repoRoot: tmpDir, planId: plan.plan_id });
      expect(inspection.plan_id).toBe(plan.plan_id);
      expect(inspection.layers.L0).toBeDefined();

      // 3. Create raw untrusted evidence file
      const rawEvidenceFile = path.join(tmpDir, "03_KET_QUA_KIEM_TRA", "dump.bin");
      await fs.writeFile(rawEvidenceFile, "BINARY_DATA_DUMP");

      // 4. Pack context
      const packet = await packContext({ repoRoot: tmpDir, planId: plan.plan_id });
      expect(packet.status).toBe("READY");
      expect(packet.layers.length).toBe(6);
      expect(packet._metadata_tail.packet_id).toBeDefined();

      // Verify untrusted evidence is sandboxed with cryptographic nonce
      const l5Layer = packet.layers.find((l: any) => l.layer_id === "L5");
      const untrustedItem = l5Layer.items.find((it: any) => it.id === "EVIDENCE-RAW");
      expect(untrustedItem).toBeDefined();
      expect(untrustedItem.content).toContain("<untrusted_binary_evidence nonce=");
      expect(untrustedItem.nonce).toBeDefined();

      // 5. Verify packet and issue receipt
      const receipt = await verifyPacket({
        repoRoot: tmpDir,
        packId: packet._metadata_tail.packet_id,
      });

      expect(receipt.receipt_id).toBeDefined();
      expect(receipt.verdict).toBe("PASS");
      expect(receipt.compliance.stable_prefix_first).toBe(true);
      expect(receipt.compliance.dynamic_suffix_last).toBe(true);
      expect(receipt.compliance.untrusted_data_sandboxed).toBe(true);
      expect(receipt.compliance.budget_within_limit).toBe(true);
      expect(receipt.compliance.no_raw_binary_bloat).toBe(true);
    });
  });
});
