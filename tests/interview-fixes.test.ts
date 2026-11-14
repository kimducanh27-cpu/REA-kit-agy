import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import {
  initInterview,
  getInterviewState,
  saveInterviewState,
  recordGoal,
  recordQuestion,
  recordAnswer,
  recordDecision,
  recordAssumption,
  evaluateSufficiency,
  matchesGoalId,
  escapeRegExp,
} from "../src/core/interview.js";

describe("Work Stream 3: Interview Engine Hardening Fixes", () => {
  let testDir: string;

  beforeEach(async () => {
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "rea-interview-fixes-"));
    const stateDir = path.join(testDir, ".agents", "state");
    await fs.mkdir(stateDir, { recursive: true });

    // Mock active_case.json
    await fs.writeFile(
      path.join(stateDir, "active_case.json"),
      JSON.stringify(
        {
          schema_version: 1,
          case_id: "CASE-20261114-120000",
          current_phase: "PHASE_01_INGESTION",
          status: "OPEN",
        },
        null,
        2
      ),
      "utf8"
    );
  });

  afterEach(async () => {
    try {
      await fs.rm(testDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup error
    }
  });

  it("01 - Exact Goal ID matching: G-1 does not resolve or collide from G-10 / G-11 decisions", async () => {
    await initInterview({ repoRoot: testDir, force: true });

    // Goal ID matching regex unit check
    expect(matchesGoalId("Resolves G-10 requirement", "G-1")).toBe(false);
    expect(matchesGoalId("Resolves G-11 requirement", "G-1")).toBe(false);
    expect(matchesGoalId("Resolves G-100 requirement", "G-1")).toBe(false);
    expect(matchesGoalId("Resolves G-1 and G-2", "G-1")).toBe(true);
    expect(matchesGoalId("G-1: Implement login", "G-1")).toBe(true);
    expect(matchesGoalId("PrefixAG-1", "G-1")).toBe(false);

    // Record two goals: G-1 and G-10
    await recordGoal({
      repoRoot: testDir,
      goalId: "G-1",
      description: "Setup basic navigation layout",
      priority: "P1_HIGH",
    });

    await recordGoal({
      repoRoot: testDir,
      goalId: "G-10",
      description: "Setup push notification engine",
      priority: "P1_HIGH",
    });

    // Record decision only for G-10 (description contains G-10, relatedRequirements: ["G-10"])
    await recordDecision({
      repoRoot: testDir,
      decisionId: "DEC-10",
      description: "Implement Firebase Cloud Messaging for G-10",
      selectedOption: "Firebase FCM",
      approvalStatus: "APPROVED",
      relatedRequirements: ["G-10"],
    });

    // Evaluate sufficiency
    const evalResult = await evaluateSufficiency(testDir);

    const evalG1 = evalResult.goal_evaluations.find((g) => g.goal_id === "G-1");
    const evalG10 = evalResult.goal_evaluations.find((g) => g.goal_id === "G-10");

    expect(evalG1).toBeDefined();
    expect(evalG10).toBeDefined();

    // G-10 must be RESOLVED because DEC-10 is approved for G-10
    expect(evalG10?.status).toBe("RESOLVED");
    expect(evalG10?.decision_ids).toContain("DEC-10");

    // G-1 MUST NOT resolve from DEC-10 or G-10. It must remain NEEDS_INPUT!
    expect(evalG1?.status).toBe("NEEDS_INPUT");
    expect(evalG1?.decision_ids).not.toContain("DEC-10");
    expect(evalG1?.blocking_reasons).toContain("Goal G-1 has no resolving decision recorded.");

    // Now record decision for G-1
    await recordDecision({
      repoRoot: testDir,
      decisionId: "DEC-01",
      description: "Implement Jetpack Navigation BottomBar for G-1",
      selectedOption: "BottomBar",
      approvalStatus: "APPROVED",
      relatedRequirements: ["G-1"],
    });

    const evalResult2 = await evaluateSufficiency(testDir);
    const evalG1Updated = evalResult2.goal_evaluations.find((g) => g.goal_id === "G-1");
    expect(evalG1Updated?.status).toBe("RESOLVED");
    expect(evalG1Updated?.decision_ids).toContain("DEC-01");
  });

  it("02 - ASM-AUTODELEGATE Status Check: Rejected auto-delegate assumption sets goal to BLOCKED", async () => {
    await initInterview({ repoRoot: testDir, force: true });

    // Record a Two-Way Door goal
    await recordGoal({
      repoRoot: testDir,
      goalId: "G-1",
      description: "Safe caching default mechanism",
      priority: "P2_MEDIUM",
    });

    // Ask 2 questions to reach the max clarification limit (default: 2)
    await recordQuestion({
      repoRoot: testDir,
      questionId: "Q-1",
      text: "Do you need Room or Datastore for caching?",
      reason: "Clarify cache database",
      goalIds: ["G-1"],
    });
    await recordAnswer({
      repoRoot: testDir,
      answerId: "ANS-1",
      questionId: "Q-1",
      answer: "Choose what is best",
      type: "CLEAR",
    });

    await recordQuestion({
      repoRoot: testDir,
      questionId: "Q-2",
      text: "What cache TTL duration is required?",
      reason: "Clarify cache TTL",
      goalIds: ["G-1"],
    });
    await recordAnswer({
      repoRoot: testDir,
      answerId: "ANS-2",
      questionId: "Q-2",
      answer: "Standard default is fine",
      type: "CLEAR",
    });

    // First evaluation: Reaches clarification limit on Two-Way Door goal -> auto-delegates
    const eval1 = await evaluateSufficiency(testDir);
    const evalG1 = eval1.goal_evaluations.find((g) => g.goal_id === "G-1");
    expect(evalG1?.status).toBe("ASSUMED_WITH_APPROVAL");
    expect(evalG1?.assumption_id || evalG1?.assumption_ids).toContain("ASM-AUTODELEGATE-G-1");

    const state1 = await getInterviewState(testDir);
    const autoAsm = state1.assumptions.find((a) => a.assumption_id === "ASM-AUTODELEGATE-G-1");
    expect(autoAsm).toBeDefined();
    expect(autoAsm?.approval_status).toBe("APPROVED");
    expect(autoAsm?.status).toBe("ACTIVE");

    // User or Reviewer rejects the auto-delegate assumption
    await recordAssumption({
      repoRoot: testDir,
      assumptionId: "ASM-AUTODELEGATE-G-1",
      description: "G-1: Tự động ủy quyền lựa chọn kỹ thuật an toàn (Two-Way Door Safe Default)",
      rationale: "User rejected the safe default; explicit architecture input is required",
      approvalStatus: "REJECTED",
      downstreamDeps: ["G-1"],
    });

    // Re-evaluate sufficiency
    const eval2 = await evaluateSufficiency(testDir);
    const evalG1Blocked = eval2.goal_evaluations.find((g) => g.goal_id === "G-1");

    expect(evalG1Blocked?.status).toBe("BLOCKED");
    expect(eval2.verdict).toBe("BLOCKED");
    expect(eval2.blocking_reasons.some((r) => r.includes("ASM-AUTODELEGATE-G-1") && r.includes("rejected"))).toBe(
      true
    );

    // Also verify INVALIDATED status blocks goal
    const state2 = await getInterviewState(testDir);
    const autoAsm2 = state2.assumptions.find((a) => a.assumption_id === "ASM-AUTODELEGATE-G-1")!;
    autoAsm2.approval_status = "APPROVED";
    autoAsm2.status = "INVALIDATED";
    await saveInterviewState(testDir, state2);

    const eval3 = await evaluateSufficiency(testDir);
    const evalG1Invalidated = eval3.goal_evaluations.find((g) => g.goal_id === "G-1");
    expect(evalG1Invalidated?.status).toBe("BLOCKED");
    expect(eval3.verdict).toBe("BLOCKED");
  });

  it("03 - Question Limits: Spontaneous user info does not consume question budget", async () => {
    await initInterview({ repoRoot: testDir, force: true });

    // Set tight limits in session: max 2 total questions, max 1 clarification per goal
    const state = await getInterviewState(testDir);
    state.session.max_total_questions = 2;
    state.session.max_clarification_per_goal = 1;
    await saveInterviewState(testDir, state);

    await recordGoal({
      repoRoot: testDir,
      goalId: "G-1",
      description: "User Profile Management",
      priority: "P1_HIGH",
    });

    await recordGoal({
      repoRoot: testDir,
      goalId: "G-2",
      description: "Application Settings",
      priority: "P1_HIGH",
    });

    // Record spontaneous user inputs (creates synthetic SPONTANEOUS-* questions)
    const ans1 = await recordAnswer({
      repoRoot: testDir,
      answerId: "ANS-SPONT-1",
      answer: "User profile needs an avatar upload feature supporting PNG/JPEG",
      spontaneous: true,
      goalIds: ["G-1"],
    });
    expect(ans1.question_id).toMatch(/^SPONTANEOUS-/);

    const ans2 = await recordAnswer({
      repoRoot: testDir,
      answerId: "ANS-SPONT-2",
      answer: "User profile should show account creation date",
      spontaneous: true,
      goalIds: ["G-1"],
    });
    expect(ans2.question_id).toMatch(/^SPONTANEOUS-/);

    // Verify synthetic questions exist in state
    const stateAfterSpont = await getInterviewState(testDir);
    const spontQuestions = stateAfterSpont.questions.filter((q) => q.question_id.startsWith("SPONTANEOUS-"));
    expect(spontQuestions.length).toBe(2);

    // Now record real Question Q-1 for G-1:
    // Even though there are 2 spontaneous questions (and both associated with G-1),
    // Q-1 must NOT be rejected by max_total_questions (2) or max_clarification_per_goal (1)!
    const q1 = await recordQuestion({
      repoRoot: testDir,
      questionId: "Q-1",
      text: "What maximum file size should be allowed for avatar uploads?",
      reason: "Establish upload constraints",
      goalIds: ["G-1"],
    });
    expect(q1.question_id).toBe("Q-1");

    // Second real question Q-2 for G-2:
    // This reaches the max_total_questions limit (2 real questions).
    const q2 = await recordQuestion({
      repoRoot: testDir,
      questionId: "Q-2",
      text: "Should dark mode be toggled automatically or manually?",
      reason: "Clarify theme preferences",
      goalIds: ["G-2"],
    });
    expect(q2.question_id).toBe("Q-2");

    // Attempting a 3rd real question Q-3 must fail with SESSION_LIMIT_EXCEEDED
    await expect(
      recordQuestion({
        repoRoot: testDir,
        questionId: "Q-3",
        text: "Should notifications be enabled by default?",
        reason: "Clarify notification policy",
        goalIds: ["G-2"],
      })
    ).rejects.toThrow(/SESSION_LIMIT_EXCEEDED/);

    // Attempting a 2nd real question for G-1 must fail with GOAL_CLARIFICATION_LIMIT_EXCEEDED (with force=false)
    // Note: session limit would also trigger, but if force is used on session or goal limit:
    const stateRelaxed = await getInterviewState(testDir);
    stateRelaxed.session.max_total_questions = 10;
    await saveInterviewState(testDir, stateRelaxed);

    await expect(
      recordQuestion({
        repoRoot: testDir,
        questionId: "Q-1B",
        text: "Should avatar be cropped square or circular?",
        reason: "Clarify avatar crop",
        goalIds: ["G-1"],
      })
    ).rejects.toThrow(/GOAL_CLARIFICATION_LIMIT_EXCEEDED/);
  });

  it("04 - Atomicity: Concurrent read-modify-write operations do not lose state", async () => {
    await initInterview({ repoRoot: testDir, force: true });

    // Run 5 concurrent recordGoal calls
    await Promise.all([
      recordGoal({ repoRoot: testDir, goalId: "G-A", description: "Goal A" }),
      recordGoal({ repoRoot: testDir, goalId: "G-B", description: "Goal B" }),
      recordGoal({ repoRoot: testDir, goalId: "G-C", description: "Goal C" }),
      recordGoal({ repoRoot: testDir, goalId: "G-D", description: "Goal D" }),
      recordGoal({ repoRoot: testDir, goalId: "G-E", description: "Goal E" }),
    ]);

    const state = await getInterviewState(testDir);
    const goalIds = state.goals.map((g) => g.goal_id).sort();
    expect(goalIds).toEqual(["G-A", "G-B", "G-C", "G-D", "G-E"]);
  });
});
