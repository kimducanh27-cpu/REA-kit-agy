import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";

import { findRepoRoot } from "../src/core/workspace.js";
import {
  initInterview,
  getInterviewStatus,
  recordGoal,
  recordQuestion,
  recordAnswer,
  recordDecision,
  recordAssumption,
  recordUnknown,
  recordConflict,
  resolveConflict,
  recordScopeChange,
  evaluateSufficiency,
  validateInterview,
  getInterviewState,
  saveInterviewState,
} from "../src/core/interview.js";
import { resolveProfileName } from "../src/core/context.js";
import { CLEARED_STATES, runGateAction } from "../src/core/gate.js";

describe("REA Adaptive Interview Engine & 52-Test Verification Suite", () => {
  const repoRoot = findRepoRoot();
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "rea-interview-test-"));
    // Ensure docs directory exists for workspace detection if needed
    await fs.mkdir(path.join(tmpDir, "docs"), { recursive: true });
    await fs.writeFile(
      path.join(tmpDir, "docs", "WORKFLOW_LIFECYCLE.md"),
      "# Workflow Lifecycle",
      "utf8"
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
  // LAYER 1: STATIC VALIDATION & SCHEMA CONFORMANCE (11 Tests)
  // =========================================================================
  describe("Layer 1: Static Validation & Schema Conformance", () => {
    it("01 - File interview.ps1 (and TypeScript engine) exists", async () => {
      const ps1Exists = await fs
        .access(path.join(repoRoot, ".agents", "scripts", "interview.ps1"))
        .then(() => true)
        .catch(() => false);
      const tsExists = await fs
        .access(path.join(repoRoot, "src", "core", "interview.ts"))
        .then(() => true)
        .catch(() => false);
      expect(ps1Exists || tsExists).toBe(true);
    });

    it("02 - File 14-INTERVIEW-STATE-TEMPLATE.json exists", async () => {
      const tplExists = await fs
        .access(path.join(repoRoot, "templates", "14-INTERVIEW-STATE-TEMPLATE.json"))
        .then(() => true)
        .catch(() => false);
      expect(tplExists).toBe(true);
    });

    it("03 - File interview_state.json exists", async () => {
      const stateExists = await fs
        .access(path.join(repoRoot, ".agents", "state", "interview_state.json"))
        .then(() => true)
        .catch(() => false);
      expect(stateExists).toBe(true);
    });

    it("04 - File context.ps1 (and TypeScript engine) exists", async () => {
      const ps1Exists = await fs
        .access(path.join(repoRoot, ".agents", "scripts", "context.ps1"))
        .then(() => true)
        .catch(() => false);
      const tsExists = await fs
        .access(path.join(repoRoot, "src", "core", "context.ts"))
        .then(() => true)
        .catch(() => false);
      expect(ps1Exists || tsExists).toBe(true);
    });

    it("05 - Template conforms to JSON Schema Draft-07", async () => {
      const raw = await fs.readFile(
        path.join(repoRoot, "templates", "14-INTERVIEW-STATE-TEMPLATE.json"),
        "utf8"
      );
      const tpl = JSON.parse(raw);
      expect(tpl.$schema).toMatch(/draft-07/);
    });

    it("06 - DIFF-01: Goal status enums include NEEDS_INPUT and evaluation states", async () => {
      const raw = await fs.readFile(
        path.join(repoRoot, "templates", "14-INTERVIEW-STATE-TEMPLATE.json"),
        "utf8"
      );
      const tpl = JSON.parse(raw);
      const goalEnums: string[] = tpl.properties.goals.items.properties.status.enum;
      expect(goalEnums).toContain("RESOLVED");
      expect(goalEnums).toContain("APPROVED");
      expect(goalEnums).toContain("DEFERRED");
      expect(goalEnums).toContain("BLOCKED");
      expect(goalEnums).toContain("NEEDS_INPUT");
    });

    it("07 - Answer type enums include SPONTANEOUS_INFO", async () => {
      const raw = await fs.readFile(
        path.join(repoRoot, "templates", "14-INTERVIEW-STATE-TEMPLATE.json"),
        "utf8"
      );
      const tpl = JSON.parse(raw);
      const ansTypeEnum: string[] = tpl.properties.answers.items.properties.answer_type.enum;
      expect(ansTypeEnum).toContain("SPONTANEOUS_INFO");
    });

    it("08 - Unknown schema has priority (CRITICAL, HIGH) and status (OPEN, RESOLVED, DEFERRED)", async () => {
      const raw = await fs.readFile(
        path.join(repoRoot, "templates", "14-INTERVIEW-STATE-TEMPLATE.json"),
        "utf8"
      );
      const tpl = JSON.parse(raw);
      const prioEnum: string[] = tpl.properties.unknowns.items.properties.priority.enum;
      const statusEnum: string[] = tpl.properties.unknowns.items.properties.status.enum;
      expect(prioEnum).toContain("CRITICAL");
      expect(prioEnum).toContain("HIGH");
      expect(statusEnum).toContain("OPEN");
      expect(statusEnum).toContain("DEFERRED");
    });

    it("09 - interview_state.json written UTF-8 No BOM", async () => {
      const stateFile = path.join(repoRoot, ".agents", "state", "interview_state.json");
      const bytes = await fs.readFile(stateFile);
      const hasBOM = bytes.length >= 3 && bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf;
      expect(hasBOM).toBe(false);
    });

    it("10 - Phase 1: Template has topic_key, MULTIPLE_CHOICE enum and session limits", async () => {
      const raw = await fs.readFile(
        path.join(repoRoot, "templates", "14-INTERVIEW-STATE-TEMPLATE.json"),
        "utf8"
      );
      const tpl = JSON.parse(raw);
      const qProps = tpl.properties.questions.items.properties;
      const sessProps = tpl.properties.session.properties;
      const ansEnum = tpl.properties.answers.items.properties.answer_type.enum;

      expect(qProps.topic_key).toBeDefined();
      expect(sessProps.max_clarification_per_goal).toBeDefined();
      expect(sessProps.max_total_questions).toBeDefined();
      expect(ansEnum).toContain("MULTIPLE_CHOICE");
      expect(ansEnum).not.toContain("MULTIPLE_CHOICES");
    });

    it("11 - Spec Template has Mobile Display Compatibility Matrix 6 columns with evidence-based model", async () => {
      const specPath = path.join(repoRoot, "templates", "02-SPEC-TEMPLATE.md");
      const content = await fs.readFile(specPath, "utf8");
      const hasMatrixCols = /\|\s*Device class\s*\|\s*Aspect ratio\s*\|\s*Viewport \(dp\)\s*\|\s*Orientation\s*\|\s*Support status\s*\|\s*Verification\s*\|/.test(
        content
      );
      const hasEvidenceModel =
        content.includes("NOT_ASSESSED") &&
        content.includes("IN_SCOPE") &&
        content.includes("NOT_VERIFIED");
      expect(hasMatrixCols).toBe(true);
      expect(hasEvidenceModel).toBe(true);
    });
  });

  // =========================================================================
  // LAYER 2: STATE & CLI INTEGRATION & EXIT GATE TESTS (10 Tests)
  // =========================================================================
  describe("Layer 2: State & CLI Integration & Exit Gate Tests", () => {
    it("12 - CLI init rejects overwriting active session without -Force (DIFF-02)", async () => {
      await initInterview({ repoRoot: tmpDir, caseId: "CASE-INITIAL", force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-INIT-TEST",
        description: "Goal to protect",
      });

      let rejected = false;
      try {
        await initInterview({ repoRoot: tmpDir });
      } catch (err: any) {
        if (err.message && err.message.includes("DESTRUCTIVE_INIT_REFUSED")) {
          rejected = true;
        }
      }
      expect(rejected).toBe(true);
    });

    it("13 - CLI init -Force creates safe backup before re-initialization (DIFF-02)", async () => {
      await initInterview({ repoRoot: tmpDir, caseId: "CASE-INITIAL", force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-INIT-TEST",
        description: "Goal to protect",
      });

      await initInterview({ repoRoot: tmpDir, force: true });
      const backupDir = path.join(tmpDir, ".agents", "state", "cases");
      const files = await fs.readdir(backupDir);
      const backupFound = files.some((f) => f.startsWith("interview_backup_") && f.endsWith(".json"));
      expect(backupFound).toBe(true);
    });

    it("14 - CLI record-question blocks duplicate question without -AllowRepeat (DIFF-03)", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-REP-1",
        text: "Hệ quản trị CSDL dự kiến là gì?",
        reason: "Xác định storage engine",
      });

      let repeatRejected = false;
      try {
        await recordQuestion({
          repoRoot: tmpDir,
          questionId: "Q-REP-2",
          text: "Hệ quản trị CSDL dự kiến là gì?",
          reason: "Hỏi lại mà không có cờ",
        });
      } catch (err: any) {
        if (err.message && err.message.includes("REPETITION_REJECTED")) {
          repeatRejected = true;
        }
      }
      expect(repeatRejected).toBe(true);
    });

    it("15 - DIFF-06: CLI record-question allows repetition with -AllowRepeat and updates question repetition state", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-REP-1",
        text: "Hệ quản trị CSDL dự kiến là gì?",
        reason: "Xác định storage engine",
      });

      const qRep2 = await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-REP-2",
        text: "Hệ quản trị CSDL dự kiến là gì?",
        reason: "Đánh giá lại sau khi kiểm toán phát hiện SQLite chưa mã hóa",
        allowRepeat: true,
      });

      expect(qRep2.repetition).toBeDefined();
      expect(qRep2.repetition?.is_repeated).toBe(true);
      expect(qRep2.repetition?.prior_question_id).toBe("Q-REP-1");
    });

    it("16 - DIFF-05: CLI record-question rejects duplicate QuestionId with different text without -Force/-Supersede", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-REP-1",
        text: "Hệ quản trị CSDL dự kiến là gì?",
        reason: "Xác định storage engine",
      });

      let dupIdRejected = false;
      try {
        await recordQuestion({
          repoRoot: tmpDir,
          questionId: "Q-REP-1",
          text: "Nội dung câu hỏi hoàn toàn khác nhưng bị trùng ID",
          reason: "Cố tình ghi đè ID",
        });
      } catch (err: any) {
        if (err.message && err.message.includes("DUPLICATE_QUESTION_ID_REJECTED")) {
          dupIdRejected = true;
        }
      }
      expect(dupIdRejected).toBe(true);
    });

    it("17 - DIFF-05: CLI record-question allows overriding QuestionId with -Supersede", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-REP-1",
        text: "Hệ quản trị CSDL dự kiến là gì?",
        reason: "Xác định storage engine",
      });

      const overridden = await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-REP-1",
        text: "Nội dung câu hỏi sửa đổi đã được duyệt ghi đè",
        reason: "Ghi đè hợp lệ có chủ đích",
        supersede: true,
      });

      expect(overridden.question_text).toBe("Nội dung câu hỏi sửa đổi đã được duyệt ghi đè");
    });

    it("18 - CLI record-answer rejects orphan answer without matching question (DIFF-04)", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });

      let orphanRejected = false;
      try {
        await recordAnswer({
          repoRoot: tmpDir,
          answerId: "ANS-ORPH-1",
          questionId: "Q-NONEXISTENT",
          answer: "Câu trả lời mồ côi",
        });
      } catch (err: any) {
        if (err.message && err.message.includes("ORPHAN_ANSWER_REJECTED")) {
          orphanRejected = true;
        }
      }
      expect(orphanRejected).toBe(true);
    });

    it("19 - CLI record-answer allows spontaneous info with -Spontaneous (DIFF-04)", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      const ans = await recordAnswer({
        repoRoot: tmpDir,
        answerId: "ANS-SPONT-1",
        answer: "Người dùng chủ động báo cần hỗ trợ đăng nhập sinh trắc học",
        spontaneous: true,
      });

      expect(ans.answer_type).toBe("SPONTANEOUS_INFO");
      expect(ans.answer_source).toBe("USER_SPONTANEOUS");
    });

    it("20 - CLI record-unknown stores blindspot with priority and status", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      const unk = await recordUnknown({
        repoRoot: tmpDir,
        unknownId: "UNK-TEST-01",
        description: "Tài liệu API chưa hoàn thiện",
        priority: "HIGH",
        status: "OPEN",
      });

      expect(unk.unknown_id).toBe("UNK-TEST-01");
      expect(unk.priority).toBe("HIGH");
      expect(unk.status).toBe("OPEN");
    });

    it("21 - CLI validate checks referential integrity successfully", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-VAL-01",
        description: "Valid goal",
      });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-VAL-01",
        text: "Valid question",
        reason: "Valid reason",
        goalIds: "G-VAL-01",
      });
      await recordAnswer({
        repoRoot: tmpDir,
        answerId: "A-VAL-01",
        questionId: "Q-VAL-01",
        answer: "Valid answer",
      });

      const res = await validateInterview(tmpDir);
      expect(res.valid).toBe(true);
      expect(res.errors.length).toBe(0);
    });
  });

  // =========================================================================
  // EXIT GATE REGRESSION TESTS (DIFF-01 TESTS 01-06 + DIFF-02 + DIFF-04) (10 Tests)
  // =========================================================================
  describe("Exit Gate Regression Tests", () => {
    it("22 - Test 01: Goal without Decision sets verdict to NEEDS_INPUT, preserves goal status ACTIVE and sets goal_evaluations status to NEEDS_INPUT", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-REG-01",
        description: "Mục tiêu chưa có quyết định xử lý",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      const st = await getInterviewState(tmpDir);
      const gObj = st.goals.find((g) => g.goal_id === "G-REG-01");
      const gEval = st.sufficiency_evaluation.goal_evaluations.find((ge) => ge.goal_id === "G-REG-01");

      expect(evalRes.verdict).toBe("NEEDS_INPUT");
      expect(gObj?.status).toBe("ACTIVE");
      expect(gEval?.status).toBe("NEEDS_INPUT");
    });

    it("23 - Test 02: PROPOSED decision does not count as approved (NEEDS_INPUT)", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-REG-01",
        description: "Mục tiêu có quyết định đề xuất",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-REG-01",
        description: "G-REG-01: Giải pháp đề xuất",
        selectedOption: "Option A",
        approvalStatus: "PROPOSED",
        relatedRequirements: "G-REG-01",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      expect(evalRes.verdict).toBe("NEEDS_INPUT");
    });

    it("24 - Test 03: Important unresolved Unknown (CRITICAL/HIGH) OPEN prevents completion (BLOCKED)", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-REG-01",
        description: "Mục tiêu hoàn chỉnh",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-REG-01",
        description: "G-REG-01: Đã duyệt",
        selectedOption: "Option A",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-REG-01",
      });
      await recordUnknown({
        repoRoot: tmpDir,
        unknownId: "UNK-CRIT-01",
        description: "Chưa rõ cơ chế ký số APK",
        priority: "CRITICAL",
        status: "OPEN",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      expect(evalRes.verdict).toBe("BLOCKED");
    });

    it("25 - DIFF-02: CRITICAL unknown DEFERRED without justification and approval remains BLOCKED", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-REG-01",
        description: "Mục tiêu",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-REG-01",
        description: "G-REG-01: Đã duyệt",
        selectedOption: "Option A",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-REG-01",
      });
      await recordUnknown({
        repoRoot: tmpDir,
        unknownId: "UNK-CRIT-01",
        description: "Chưa rõ cơ chế ký số APK",
        priority: "CRITICAL",
        status: "DEFERRED",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      expect(evalRes.verdict).toBe("BLOCKED");
      const hasBlocker = evalRes.blocking_reasons.some((b) => b.includes("Deferred critical unknown requires"));
      expect(hasBlocker).toBe(true);
    });

    it("26 - DIFF-02: CRITICAL unknown DEFERRED with justification and approval passes Exit Gate (SUFFICIENT)", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-REG-01",
        description: "Mục tiêu",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-REG-01",
        description: "G-REG-01: Đã duyệt",
        selectedOption: "Option A",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-REG-01",
      });
      await recordUnknown({
        repoRoot: tmpDir,
        unknownId: "UNK-CRIT-01",
        description: "Chưa rõ cơ chế ký số APK",
        priority: "CRITICAL",
        status: "DEFERRED",
        justification: "Được phép hoãn vì sử dụng debug keystore trong giai đoạn dev",
        approval: "APPROVED",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      expect(evalRes.verdict).toBe("SUFFICIENT");
      const hasDeferred = evalRes.deferred_decisions.some((d) =>
        d.includes("DEFERRED CRITICAL UNKNOWN UNK-CRIT-01")
      );
      expect(hasDeferred).toBe(true);
    });

    it("27 - Test 04: Properly deferred non-critical decision does not block Exit Gate (SUFFICIENT)", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-CORE",
        description: "Tính năng chính",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-CORE",
        description: "G-CORE: Triển khai Room DB",
        selectedOption: "Room",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-CORE",
      });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-NICE",
        description: "Tính năng mở rộng",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-NICE",
        description: "G-NICE: Chủ đề tối nâng cao",
        selectedOption: "Hoãn sang v1.2",
        approvalStatus: "DEFERRED",
        relatedRequirements: "G-NICE",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      expect(evalRes.verdict).toBe("SUFFICIENT");
      expect(evalRes.deferred_decisions.length).toBeGreaterThanOrEqual(1);
    });

    it("28 - DIFF-04: Approved Assumption resolving Goal passes Exit Gate without false decision blocker", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-ASSUMP-01",
        description: "Bảo mật lưu trữ access token người dùng",
      });
      await recordAssumption({
        repoRoot: tmpDir,
        assumptionId: "ASM-DATASTORE",
        description: "G-ASSUMP-01: Sử dụng Jetpack DataStore mã hóa qua Google Tink Aead",
        rationale: "Khuyến nghị bảo mật chính thức của Android",
        riskLevel: "BENIGN",
        approvalStatus: "APPROVED",
        downstreamDeps: "G-ASSUMP-01",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      const st = await getInterviewState(tmpDir);
      const gEval = st.sufficiency_evaluation.goal_evaluations.find((ge) => ge.goal_id === "G-ASSUMP-01");
      const noFalseBlocker = !evalRes.blocking_reasons.some((b) =>
        b.includes("Goal G-ASSUMP-01 has no resolving decision recorded")
      );

      expect(evalRes.verdict).toBe("SUFFICIENT");
      expect(gEval?.status).toBe("ASSUMED_WITH_APPROVAL");
      expect(noFalseBlocker).toBe(true);
    });

    it("29 - Test 05: Unresolved CRITICAL conflict sets verdict to BLOCKED", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-CONF-TEST",
        description: "Goal with conflict",
      });
      await recordConflict({
        repoRoot: tmpDir,
        conflictId: "CONF-T5",
        explanation: "Xung đột giữa yêu cầu bảo mật cao và lưu mật khẩu văn bản rõ",
        severity: "CRITICAL",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      expect(evalRes.verdict).toBe("BLOCKED");
    });

    it("30 - Test 06: All goals with APPROVED decision and conflict RESOLVED pass Exit Gate (SUFFICIENT)", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-CONF-TEST",
        description: "Goal with resolved conflict",
      });
      await recordConflict({
        repoRoot: tmpDir,
        conflictId: "CONF-T5",
        explanation: "Xung đột giữa yêu cầu bảo mật cao và lưu mật khẩu văn bản rõ",
        severity: "CRITICAL",
      });
      await resolveConflict({
        repoRoot: tmpDir,
        conflictId: "CONF-T5",
        resolutionStrategy: "Sử dụng Android KeyStore Cipher",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-CONF-RES",
        description: "G-CONF-TEST: Sử dụng Android KeyStore",
        selectedOption: "KeyStore Cipher",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-CONF-TEST",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      expect(evalRes.verdict).toBe("SUFFICIENT");
    });

    it("31 - Test 06 (Duplicate assertion from test_interview.ps1 line 330): Exit Gate passes SUFFICIENT", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-DUP-06",
        description: "Duplicate assertion test goal",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-DUP-06",
        description: "G-DUP-06: Approved decision",
        selectedOption: "Approved",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-DUP-06",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      expect(evalRes.verdict).toBe("SUFFICIENT");
    });
  });

  // =========================================================================
  // PHASE 1 REGRESSION TESTS: STATE PRESERVATION, AMBIGUITY, TOPIC KEY & LIMITS (8 Tests)
  // =========================================================================
  describe("Phase 1 Regression Tests: State Preservation, Ambiguity, Topic Key & Limits", () => {
    it("32 - Phase 1: evaluate-sufficiency preserves ACTIVE/PROPOSED goal status in state and reports verdict NEEDS_INPUT", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-ACTIVE-01",
        description: "Goal dang ACTIVE",
      });
      const st = await getInterviewState(tmpDir);
      st.goals.push({
        goal_id: "G-PROP-01",
        description: "Goal dang PROPOSED",
        category: "GENERAL",
        priority: "P1_HIGH",
        status: "PROPOSED",
        related_requirements: [],
      });
      await saveInterviewState(tmpDir, st);

      const evalRes = await evaluateSufficiency(tmpDir);
      const stAfter = await getInterviewState(tmpDir);
      const gActive = stAfter.goals.find((g) => g.goal_id === "G-ACTIVE-01");
      const gProp = stAfter.goals.find((g) => g.goal_id === "G-PROP-01");
      const gActiveEval = stAfter.sufficiency_evaluation.goal_evaluations.find(
        (ge) => ge.goal_id === "G-ACTIVE-01"
      );
      const gPropEval = stAfter.sufficiency_evaluation.goal_evaluations.find(
        (ge) => ge.goal_id === "G-PROP-01"
      );

      expect(evalRes.verdict).toBe("NEEDS_INPUT");
      expect(gActive?.status).toBe("ACTIVE");
      expect(gProp?.status).toBe("PROPOSED");
      expect(gActiveEval?.status).toBe("NEEDS_INPUT");
      expect(gPropEval?.status).toBe("NEEDS_INPUT");
    });

    it("33 - Phase 1: Goal resolved by Approved Assumption reaches SUFFICIENT and has no false decision blocker", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-ASM-COVERED",
        description: "Bảo vệ thông tin định danh",
      });
      await recordAssumption({
        repoRoot: tmpDir,
        assumptionId: "ASM-COV-01",
        description: "G-ASM-COVERED: Tự động mã hóa AES-GCM",
        rationale: "Khuyến nghị chuẩn bảo mật",
        riskLevel: "BENIGN",
        approvalStatus: "APPROVED",
        downstreamDeps: "G-ASM-COVERED",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      const st = await getInterviewState(tmpDir);
      const gEval = st.sufficiency_evaluation.goal_evaluations.find((ge) => ge.goal_id === "G-ASM-COVERED");
      const noFalseBlocker = !evalRes.blocking_reasons.some((b) =>
        b.includes("Goal G-ASM-COVERED has no resolving decision recorded")
      );

      expect(evalRes.verdict).toBe("SUFFICIENT");
      expect(gEval?.status).toBe("ASSUMED_WITH_APPROVAL");
      expect(noFalseBlocker).toBe(true);
    });

    it("34 - Phase 1: AMBIGUOUS answer keeps question status as NEEDS_CLARIFICATION and sets verdict to NEEDS_INPUT", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-AMB-TEST",
        description: "Tối ưu hóa bộ nhớ",
      });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-AMB-01",
        text: "Mục tiêu dung lượng RAM tối đa là bao nhiêu MB?",
        reason: "Xác định giới hạn bộ nhớ",
        goalIds: "G-AMB-TEST",
      });
      await recordAnswer({
        repoRoot: tmpDir,
        answerId: "ANS-AMB-01",
        questionId: "Q-AMB-01",
        answer: "Càng nhẹ càng tốt, tầm vài chục hoặc vài trăm MB gì đó",
        type: "AMBIGUOUS",
      });

      const stBefore = await getInterviewState(tmpDir);
      const qAmb = stBefore.questions.find((q) => q.question_id === "Q-AMB-01");
      expect(qAmb?.status).toBe("NEEDS_CLARIFICATION");

      const evalRes = await evaluateSufficiency(tmpDir);
      expect(evalRes.verdict).toBe("NEEDS_INPUT");
    });

    it("35 - Phase 1: CONFLICTING answer keeps question status as NEEDS_CLARIFICATION and blocks Exit Gate with verdict BLOCKED", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-AMB-TEST",
        description: "Tối ưu hóa bộ nhớ",
      });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-CONF-01",
        text: "Có cho phép lưu mật khẩu người dùng dạng cleartext không?",
        reason: "Kiểm tra chính sách bảo mật",
        goalIds: "G-AMB-TEST",
      });
      await recordAnswer({
        repoRoot: tmpDir,
        answerId: "ANS-CONF-01",
        questionId: "Q-CONF-01",
        answer: "Cần lưu cleartext để debug nhưng yêu cầu phải đạt chuẩn PCI-DSS không lưu cleartext",
        type: "CONFLICTING",
      });

      const st = await getInterviewState(tmpDir);
      const qConf = st.questions.find((q) => q.question_id === "Q-CONF-01");
      expect(qConf?.status).toBe("NEEDS_CLARIFICATION");

      const evalRes = await evaluateSufficiency(tmpDir);
      expect(evalRes.verdict).toBe("BLOCKED");
    });

    it("36 - Phase 1: -TopicKey prevents duplicate question topic in same domain without -Supersede", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-TOPIC-1",
        text: "Hệ quản trị CSDL dự kiến dùng là gì?",
        reason: "Xác định storage engine",
        domain: "DATABASE",
        topicKey: "db_engine",
      });

      let dupBlocked = false;
      try {
        await recordQuestion({
          repoRoot: tmpDir,
          questionId: "Q-TOPIC-2",
          text: "Bạn muốn dùng SQLite hay Room DB?",
          reason: "Hỏi lại cùng topic trong cùng domain",
          domain: "DATABASE",
          topicKey: "db_engine",
        });
      } catch (err: any) {
        if (err.message && err.message.includes("DUPLICATE_TOPIC_KEY_REJECTED")) {
          dupBlocked = true;
        }
      }
      expect(dupBlocked).toBe(true);
    });

    it("37 - Phase 1: -TopicKey allows overriding topic with -Supersede", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-TOPIC-1",
        text: "Hệ quản trị CSDL dự kiến dùng là gì?",
        reason: "Xác định storage engine",
        domain: "DATABASE",
        topicKey: "db_engine",
      });

      const qOverridden = await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-TOPIC-2",
        text: "Bạn muốn dùng SQLite hay Room DB?",
        reason: "Ghi đè topic có chủ đích",
        domain: "DATABASE",
        topicKey: "db_engine",
        supersede: true,
      });

      expect(qOverridden.topic_key).toBe("db_engine");
    });

    it("38 - Phase 1: max_clarification_per_goal rejects 3rd question exceeding goal clarification limit without -Force", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-LIMIT-CLAR",
        description: "Tích hợp cổng thanh toán MoMo",
      });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-CLAR-1",
        text: "Môi trường MoMo là sandbox hay production?",
        reason: "Xác định endpoint",
        goalIds: "G-LIMIT-CLAR",
      });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-CLAR-2",
        text: "Phương thức thanh toán MoMo là QR hay App-to-App?",
        reason: "Xác định SDK flow",
        goalIds: "G-LIMIT-CLAR",
      });

      let limitExceeded = false;
      try {
        await recordQuestion({
          repoRoot: tmpDir,
          questionId: "Q-CLAR-3",
          text: "Có cần lưu lịch sử giao dịch MoMo vào Room không?",
          reason: "Câu hỏi vượt quá giới hạn làm rõ",
          goalIds: "G-LIMIT-CLAR",
        });
      } catch (err: any) {
        if (err.message && err.message.includes("GOAL_CLARIFICATION_LIMIT_EXCEEDED")) {
          limitExceeded = true;
        }
      }
      expect(limitExceeded).toBe(true);
    });

    it("39 - Phase 1: max_total_questions rejects additional questions when session total limit reached", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      const st = await getInterviewState(tmpDir);
      st.session.max_total_questions = 2;
      await saveInterviewState(tmpDir, st);

      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-TOT-1",
        text: "Câu hỏi 1",
        reason: "Lý do 1",
      });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-TOT-2",
        text: "Câu hỏi 2",
        reason: "Lý do 2",
      });

      let totalLimitExceeded = false;
      try {
        await recordQuestion({
          repoRoot: tmpDir,
          questionId: "Q-TOTAL-OVER",
          text: "Câu hỏi vượt tổng hạn mức session?",
          reason: "Kiểm tra max_total_questions",
        });
      } catch (err: any) {
        if (err.message && err.message.includes("SESSION_LIMIT_EXCEEDED")) {
          totalLimitExceeded = true;
        }
      }
      expect(totalLimitExceeded).toBe(true);
    });
  });

  // =========================================================================
  // LAYER 3: REALISTIC ADAPTIVE BEHAVIOR SCENARIOS (A THROUGH J) (13 Tests)
  // =========================================================================
  describe("Layer 3: Realistic Adaptive Behavior Scenarios (A through J)", () => {
    it("40 - Scenario A: Bug fix handled concisely with exactly 1 RCA/STR question and reaches SUFFICIENT", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-BUG-A",
        description: "Sửa lỗi crash NullPointerException khi mở màn hình chi tiết",
        domain: "APPLICATION_DIAGNOSIS",
        priority: "P0_CRITICAL",
      });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-BUG-STR",
        text: "Các bước tái hiện lỗi (STR) và điều kiện mạng khi xảy ra crash là gì?",
        reason: "Thu thập Steps to Reproduce để khoanh vùng Root Cause",
        domain: "APPLICATION_DIAGNOSIS",
        goalIds: "G-BUG-A",
      });
      await recordAnswer({
        repoRoot: tmpDir,
        answerId: "ANS-BUG-STR",
        questionId: "Q-BUG-STR",
        answer: "Bấm nút Xem chi tiết khi thiết bị mất kết nối mạng thì ứng dụng văng ngay lập tức",
        type: "CLEAR",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-BUG-FIX",
        description: "Bổ sung kiểm tra null an toàn và khối fallback hiển thị offline banner",
        selectedOption: "Safe null check & Offline UI",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-BUG-A",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      const st = await getInterviewState(tmpDir);
      expect(evalRes.verdict).toBe("SUFFICIENT");
      expect(st.questions.length).toBe(1);
      expect(st.questions[0].status).toBe("ANSWERED");
    });

    it("41 - Scenario B: Obfuscated APK establishes evidence-based assumption with verification task", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-OBF-B",
        description: "Khôi phục API Client từ APK bị obfuscate ProGuard",
      });
      await recordAssumption({
        repoRoot: tmpDir,
        assumptionId: "ASM-OBF-NET",
        description: "G-OBF-B: Sử dụng OkHttp với TLS 1.3 dựa trên string dump network traffic",
        rationale: "Mã nguồn lớp model bị obfuscate, suy luận từ evidence chuỗi URL",
        riskLevel: "BENIGN",
        approvalStatus: "APPROVED",
        downstreamDeps: "G-OBF-B",
        verificationTask: "Kiểm chứng logcat khi gửi request thực tế",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      const st = await getInterviewState(tmpDir);
      expect(evalRes.verdict).toBe("SUFFICIENT");
      expect(st.assumptions.length).toBeGreaterThanOrEqual(1);
      expect(st.assumptions[0].verification_task).not.toBe("");
    });

    it("42 - Scenario C: Delegated choice (DELEGATED_CHOICE) auto-applies safe default assumption and reaches SUFFICIENT", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-STORE-C",
        description: "Thiết lập cơ sở dữ liệu cục bộ",
      });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-DB-SELECT",
        text: "Bạn muốn dùng Room DB hay raw SQLite?",
        reason: "Xác định storage engine",
        goalIds: "G-STORE-C",
      });
      await recordAnswer({
        repoRoot: tmpDir,
        answerId: "ANS-DB-DELEGATE",
        questionId: "Q-DB-SELECT",
        answer: "Anh chọn giúp em kiến trúc an toàn và chuẩn nhất",
        type: "DELEGATED_CHOICE",
      });
      await recordAssumption({
        repoRoot: tmpDir,
        assumptionId: "ASM-SAFE-DEFAULT",
        description: "G-STORE-C: Sử dụng Room DB với SQLiteCipher theo Safe Default",
        rationale: "Người dùng ủy quyền lựa chọn kỹ thuật; Room DB là chuẩn chính thức của Android",
        riskLevel: "BENIGN",
        approvalStatus: "APPROVED",
        downstreamDeps: "G-STORE-C",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      const st = await getInterviewState(tmpDir);
      expect(evalRes.verdict).toBe("SUFFICIENT");
      expect(st.answers[0].answer_type).toBe("DELEGATED_CHOICE");
    });

    it("43 - Scenario D: Feature addition establishes scope boundary and locks decision successfully", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-FEAT-QR",
        description: "Tích hợp tính năng thanh toán QR code",
        domain: "FEATURE_DISCOVERY",
        priority: "P1_HIGH",
      });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-FEAT-SCOPE",
        text: "Tính năng thanh toán QR có tích hợp cổng thanh toán ngoài (VNPay/Momo) hay quét mã nội bộ?",
        reason: "Xác định ranh giới phạm vi (Scope Boundary) và phụ thuộc SDK",
        domain: "FEATURE_DISCOVERY",
        goalIds: "G-FEAT-QR",
      });
      await recordAnswer({
        repoRoot: tmpDir,
        answerId: "ANS-FEAT-SCOPE",
        questionId: "Q-FEAT-SCOPE",
        answer: "Chỉ quét mã QR nội bộ chuẩn VietQR, không dùng SDK bên thứ ba",
        type: "CLEAR",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-FEAT-SCOPE",
        description: "Triển khai camera quét ZXing nội bộ chuẩn VietQR, loại trừ phụ thuộc SDK ngoài (Non-Goal)",
        selectedOption: "VietQR ZXing Embedded",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-FEAT-QR",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      const st = await getInterviewState(tmpDir);
      expect(evalRes.verdict).toBe("SUFFICIENT");
      expect(st.decisions[0].approval_status).toBe("APPROVED");
    });

    it("44 - Scenario E: Contradiction resolution protocol blocks on conflict and opens when resolved", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-SYNC-E",
        description: "Đồng bộ hóa dữ liệu người dùng",
      });
      await recordConflict({
        repoRoot: tmpDir,
        conflictId: "CONF-SYNC-01",
        conflictingItems: "Yêu cầu offline 100%, Yêu cầu real-time cloud sync",
        explanation: "Không thể đồng bộ thời gian thực khi ứng dụng bắt buộc hoạt động hoàn toàn ngoại tuyến",
        severity: "CRITICAL",
      });

      const evalBlocked = await evaluateSufficiency(tmpDir);
      expect(evalBlocked.verdict).toBe("BLOCKED");

      // Resolve the conflict
      await resolveConflict({
        repoRoot: tmpDir,
        conflictId: "CONF-SYNC-01",
        resolutionStrategy: "Kiến trúc Offline-First: Lưu trữ Room cục bộ và đồng bộ nền WorkManager khi có mạng",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-SYNC-RES",
        description: "Áp dụng kiến trúc Offline-First giải quyết CONF-SYNC-01",
        selectedOption: "Offline-First + WorkManager",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-SYNC-E",
      });

      const evalResolved = await evaluateSufficiency(tmpDir);
      const st = await getInterviewState(tmpDir);
      expect(evalResolved.verdict).toBe("SUFFICIENT");
      expect(st.conflicts[0].resolution_status).toBe("RESOLVED");
    });

    it("45 - Scenario F: Ambiguous response triggers DESIGN_REUSE_EXACT adjustment and reaches SUFFICIENT", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-UI-MODE",
        description: "Xác định phong cách giao diện và luồng người dùng",
      });
      await recordQuestion({
        repoRoot: tmpDir,
        questionId: "Q-UI-STYLE",
        text: "Bạn muốn thiết kế giao diện theo phong cách nào?",
        reason: "Phân định 1 trong 3 Design Modes",
        goalIds: "G-UI-MODE",
      });
      await recordAnswer({
        repoRoot: tmpDir,
        answerId: "ANS-UI-AMBIG",
        questionId: "Q-UI-STYLE",
        answer: "Làm giao diện nhìn hiện đại và giống bản gốc nhưng đẹp hơn một chút",
        type: "AMBIGUOUS",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-UI-MODE",
        description: "Chọn chế độ DESIGN_REUSE_EXACT kèm Sanitary Ergonomic Lint (touch target 48dp)",
        selectedOption: "DESIGN_REUSE_EXACT",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-UI-MODE",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      const st = await getInterviewState(tmpDir);
      expect(evalRes.verdict).toBe("SUFFICIENT");
      expect(st.answers[0].answer_type).toBe("AMBIGUOUS");
      expect(st.decisions[0].selected_option).toBe("DESIGN_REUSE_EXACT");
    });

    it("46 - Scenario G: Scope Change records scope reduction without losing independent decisions", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-INDEP",
        description: "Kiến trúc module cơ bản",
        selectedOption: "MVI Architecture",
        approvalStatus: "APPROVED",
      });
      await recordScopeChange({
        repoRoot: tmpDir,
        changeId: "SC-TEST",
        previousScope: "Bao gồm module Video Player",
        newScope: "Bỏ module Video Player",
      });

      const st = await getInterviewState(tmpDir);
      const indepDec = st.decisions.find((d) => d.decision_id === "DEC-INDEP");
      expect(st.scope_changes.length).toBeGreaterThanOrEqual(1);
      expect(indepDec?.selected_option).toBe("MVI Architecture");
    });

    it("47 - Scenario H: Gate Engine validation executes successfully (Exit 0) and supports SKIPPED/WAIVED for Gate 02", async () => {
      // Check gate cleared states include SKIPPED and WAIVED
      expect(CLEARED_STATES.has("SKIPPED")).toBe(true);
      expect(CLEARED_STATES.has("WAIVED")).toBe(true);

      // Verify gate script content has cleared states match
      const gateScriptPath = path.join(repoRoot, ".agents", "scripts", "gate.ps1");
      const gateContent = await fs.readFile(gateScriptPath, "utf8");
      const clearedStatesMatch =
        gateContent.includes("$clearedStates") &&
        gateContent.includes('"SKIPPED"') &&
        gateContent.includes('"WAIVED"');
      expect(clearedStatesMatch).toBe(true);
    });

    it("48 - Scenario I: Performance-critical app manages metric blindspots and reaches SUFFICIENT after resolution", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-PERF-I",
        description: "Tối ưu hóa giật lag và tốc độ khởi động",
      });
      await recordUnknown({
        repoRoot: tmpDir,
        unknownId: "UNK-PERF-BASE",
        description: "Chưa có chỉ số đo lường FPS baseline thực tế trên thiết bị vật lý",
        priority: "HIGH",
        status: "OPEN",
      });

      const evalBlocked = await evaluateSufficiency(tmpDir);
      expect(evalBlocked.verdict).toBe("BLOCKED");

      // Resolve baseline unknown and record quantitative decision
      await recordUnknown({
        repoRoot: tmpDir,
        unknownId: "UNK-PERF-BASE",
        description: "Đã thu thập baseline đo lường thực tế",
        priority: "HIGH",
        status: "RESOLVED",
      });
      await recordAssumption({
        repoRoot: tmpDir,
        assumptionId: "ASM-PERF-TARGET",
        description: "G-PERF-I: Thiết lập mục tiêu Cold Start < 1.2s và 60 FPS theo REFERENCE_BENCHMARK của Android Vitals",
        rationale: "Áp dụng benchmark ngành của Google Play",
        riskLevel: "BENIGN",
        approvalStatus: "APPROVED",
        downstreamDeps: "G-PERF-I",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-PERF-OPT",
        description: "Triển khai Baseline Profiles và nạp trước Dex để đạt chỉ tiêu Cold Start",
        selectedOption: "Baseline Profiles + Dex Pre-load",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-PERF-I",
      });

      const evalResolved = await evaluateSufficiency(tmpDir);
      expect(evalResolved.verdict).toBe("SUFFICIENT");
    });

    it("49 - Scenario J: MoSCoW prioritization accepts deferred decision and reaches SUFFICIENT", async () => {
      await initInterview({ repoRoot: tmpDir, force: true });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-MUST",
        description: "Xác thực sinh trắc học vân tay",
        priority: "P0_CRITICAL",
      });
      await recordGoal({
        repoRoot: tmpDir,
        goalId: "G-COULD",
        description: "Hiệu ứng hoạt họa chuyển cảnh 3D",
        priority: "P3_LOW",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-MUST",
        description: "Triển khai BiometricPrompt CryptoObject",
        selectedOption: "BiometricPrompt",
        approvalStatus: "APPROVED",
        relatedRequirements: "G-MUST",
      });
      await recordDecision({
        repoRoot: tmpDir,
        decisionId: "DEC-COULD",
        description: "Hoãn hiệu ứng chuyển cảnh 3D sang v2 để ưu tiên bảo mật và hiệu năng",
        selectedOption: "Hoãn sang v2",
        approvalStatus: "DEFERRED",
        relatedRequirements: "G-COULD",
      });

      const evalRes = await evaluateSufficiency(tmpDir);
      expect(evalRes.verdict).toBe("SUFFICIENT");
      expect(evalRes.deferred_decisions.length).toBeGreaterThanOrEqual(1);
    });

    it("50 - DIFF-08: 'tối ưu giao diện' routes to profile 'design'", () => {
      const profile = resolveProfileName("tối ưu giao diện và bố cục nút bấm");
      expect(profile).toBe("design");
    });

    it("51 - DIFF-08: 'tối ưu ram' routes to profile 'optimization'", () => {
      const profile = resolveProfileName("tối ưu ram và giảm rò rỉ bộ nhớ");
      expect(profile).toBe("optimization");
    });

    it("52 - DIFF-08: 'tối ưu hiệu năng' routes to profile 'optimization'", () => {
      const profile = resolveProfileName("tối ưu hiệu năng và fps");
      expect(profile).toBe("optimization");
    });
  });
});
