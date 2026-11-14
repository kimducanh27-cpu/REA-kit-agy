import fs from "node:fs/promises";
import path from "node:path";
import { findRepoRoot } from "./workspace.js";
import { withFileLock, writeUtf8NoBomAtomic } from "./state-lock.js";

// ============================================================================
// Enums & Types
// ============================================================================

export type AnswerType =
  | "CLEAR"
  | "PARTIAL"
  | "AMBIGUOUS"
  | "UNKNOWN"
  | "CONDITIONAL"
  | "MULTIPLE_CHOICE"
  | "CONFLICTING"
  | "OUT_OF_SCOPE"
  | "NEW_REQUIREMENT"
  | "SCOPE_CHANGE"
  | "SPONTANEOUS_INFO"
  | "DELEGATED_CHOICE";

export type AnswerSource =
  | "USER_EXPLICIT"
  | "REPO_EVIDENCE"
  | "DERIVED"
  | "USER_SPONTANEOUS";

export type Confidence = "HIGH" | "MEDIUM" | "LOW";

export type Priority =
  | "P0_CRITICAL"
  | "P1_HIGH"
  | "P2_MEDIUM"
  | "P3_LOW"
  | "CRITICAL"
  | "HIGH"
  | "MEDIUM"
  | "LOW"
  | "BENIGN";

export type RiskLevel = "BENIGN" | "CRITICAL";

export type Severity = "CRITICAL" | "MAJOR" | "MINOR";

export type UnknownStatus = "OPEN" | "RESOLVED" | "DEFERRED";

export type DecisionStatus = "PROPOSED" | "APPROVED" | "REJECTED" | "DEFERRED";

export type GoalStatus =
  | "PROPOSED"
  | "ACTIVE"
  | "NEEDS_INPUT"
  | "RESOLVED"
  | "APPROVED"
  | "DEFERRED"
  | "ASSUMED_WITH_APPROVAL"
  | "BLOCKED"
  | "ACHIEVED"
  | "ABANDONED";

export type SessionStatus =
  | "NOT_STARTED"
  | "IN_PROGRESS"
  | "SUFFICIENT"
  | "BLOCKED"
  | "COMPLETED";

export type SufficiencyVerdict =
  | "PENDING"
  | "SUFFICIENT"
  | "BLOCKED"
  | "NEEDS_INPUT";

export interface Goal {
  goal_id: string;
  description: string;
  category?: string;
  priority: string;
  status: GoalStatus | string;
  related_requirements?: string[];
}

export interface QuestionRepetition {
  is_repeated: boolean;
  prior_question_id: string;
  justification: string;
}

export interface Question {
  question_id: string;
  question_text: string;
  question_reason: string;
  domain?: string;
  topic_key?: string | null;
  related_goal_ids?: string[];
  related_decision_ids?: string[];
  expected_information?: string;
  answer_format?: string;
  priority: string;
  status: "DRAFT" | "ASKED" | "ANSWERED" | "SKIPPED" | "DEFERRED" | "NEEDS_CLARIFICATION" | string;
  asked_at?: string | null;
  repetition?: QuestionRepetition | null;
}

export interface Answer {
  answer_id: string;
  question_id: string;
  original_answer: string;
  interpreted_answer: string;
  answer_type: AnswerType | string;
  answer_source: AnswerSource | string;
  confidence: Confidence | string;
  conflict_id?: string | null;
  recorded_at: string;
}

export interface Decision {
  decision_id: string;
  description: string;
  available_options: string[];
  selected_option: string;
  decision_owner: string;
  approval_status: DecisionStatus | string;
  evidence_refs?: string[];
  related_requirements?: string[];
}

export interface Assumption {
  assumption_id: string;
  description: string;
  rationale: string;
  impact: string;
  risk_level: RiskLevel | string;
  approval_status: "PENDING_APPROVAL" | "APPROVED" | "REJECTED" | string;
  verification_task: string;
  status: "ACTIVE" | "INVALIDATED" | "SUPERSEDED" | string;
  invalidated_at?: string | null;
  revocation_reason?: string | null;
  downstream_dependencies?: string[];
}

export interface Conflict {
  conflict_id: string;
  conflicting_items: string[];
  explanation: string;
  severity: Severity | string;
  resolution_status: "UNRESOLVED" | "INVESTIGATING" | "RESOLVED" | "DEFERRED" | string;
  resolution_strategy?: string | null;
  resolved_at?: string | null;
}

export interface Unknown {
  unknown_id: string;
  description: string;
  impact: string;
  priority: Priority | string;
  status: UnknownStatus | string;
  resolution_strategy: string;
  justification?: string | null;
  approval?: string | null;
  approval_status?: string | null;
}

export interface ScopeChange {
  change_id: string;
  previous_scope: string;
  new_scope: string;
  affected_decisions?: string[];
  affected_requirements?: string[];
  recorded_at: string;
}

export interface GoalEvaluation {
  goal_id: string;
  status: GoalStatus | string;
  decision_ids: string[];
  assumption_ids: string[];
  pending_questions: string[];
  blocking_reasons: string[];
}

export interface AssumptionsSummary {
  total: number;
  benign: number;
  critical: number;
  pending_approval: number;
}

export interface SufficiencyEvaluation {
  verdict: SufficiencyVerdict;
  evaluated_at: string | null;
  goal_evaluations: GoalEvaluation[];
  blocking_reasons: string[];
  deferred_decisions: string[];
  assumptions_summary: AssumptionsSummary;
  summary: string;
}

export interface Session {
  session_id: string;
  status: SessionStatus;
  current_goal?: string | null;
  current_stage: string;
  active_domain?: string | null;
  design_mode?: string | null;
  max_clarification_per_goal: number;
  max_total_questions: number;
  created_at: string;
  updated_at: string;
}

export interface InterviewState {
  schema_version: number;
  case_id: string;
  session: Session;
  goals: Goal[];
  questions: Question[];
  answers: Answer[];
  decisions: Decision[];
  assumptions: Assumption[];
  conflicts: Conflict[];
  unknowns: Unknown[];
  scope_changes: ScopeChange[];
  sufficiency_evaluation: SufficiencyEvaluation;
  last_updated: string;
}

// ============================================================================
// Utilities
// ============================================================================

export function cleanArray(input?: string | string[] | null): string[] {
  if (!input) return [];
  const rawList = Array.isArray(input) ? input : [input];
  const result: string[] = [];
  for (const item of rawList) {
    if (typeof item === "string") {
      for (const part of item.split(",")) {
        const trimmed = part.trim();
        if (trimmed.length > 0) {
          result.push(trimmed);
        }
      }
    }
  }
  return result;
}

export function formatTimestamp(d = new Date()): string {
  const pad = (n: number) => n.toString().padStart(2, "0");
  const yyyy = d.getFullYear();
  const MM = pad(d.getMonth() + 1);
  const dd = pad(d.getDate());
  const HH = pad(d.getHours());
  const mm = pad(d.getMinutes());
  const ss = pad(d.getSeconds());
  return `${yyyy}${MM}${dd}-${HH}${mm}${ss}`;
}

export function formatIsoLocal(d = new Date()): string {
  return d.toISOString();
}

export function escapeRegExp(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export function matchesGoalId(text: string | undefined | null, gId: string): boolean {
  if (!text) return false;
  const regex = new RegExp(`(?<![a-zA-Z0-9_-])${escapeRegExp(gId)}(?![a-zA-Z0-9_-])`);
  return regex.test(text);
}

export function normalizePriority(p?: string | null): string {
  if (!p) return "P1_HIGH";
  const up = p.trim().toUpperCase();
  switch (up) {
    case "CRITICAL":
    case "P0":
    case "P0_CRITICAL":
      return "P0_CRITICAL";
    case "HIGH":
    case "P1":
    case "P1_HIGH":
      return "P1_HIGH";
    case "MEDIUM":
    case "P2":
    case "P2_MEDIUM":
      return "P2_MEDIUM";
    case "LOW":
    case "P3":
    case "P3_LOW":
    case "BENIGN":
      return "P3_LOW";
    default:
      return up;
  }
}

export async function getInterviewState(repoRoot: string = findRepoRoot()): Promise<InterviewState> {
  const stateFile = path.join(repoRoot, ".agents", "state", "interview_state.json");
  try {
    const raw = await fs.readFile(stateFile, "utf8");
    const clean = raw.charCodeAt(0) === 0xfeff ? raw.slice(1) : raw;
    return JSON.parse(clean) as InterviewState;
  } catch {
    throw new Error(`Interview state file does not exist: ${stateFile}. Run 'interview init' first.`);
  }
}

export async function saveInterviewStateInternal(repoRoot: string, state: InterviewState): Promise<void> {
  const stateDir = path.join(repoRoot, ".agents", "state");
  await fs.mkdir(stateDir, { recursive: true });
  const stateFile = path.join(stateDir, "interview_state.json");
  const activeCaseFile = path.join(stateDir, "active_case.json");

  const now = formatIsoLocal();
  state.last_updated = now;
  if (state.session) {
    state.session.updated_at = now;
  }
  const json = JSON.stringify(state, null, 2);
  await writeUtf8NoBomAtomic(stateFile, json);

  // Synchronize active_case.json if active_case exists
  try {
    const caseRaw = await fs.readFile(activeCaseFile, "utf8");
    const cleanCase = caseRaw.charCodeAt(0) === 0xfeff ? caseRaw.slice(1) : caseRaw;
    const caseObj = JSON.parse(cleanCase);
    if (!caseObj.interview) {
      caseObj.interview = {};
    }
    caseObj.interview.state_file = ".agents/state/interview_state.json";
    caseObj.interview.status = state.session.status;
    caseObj.interview.session_id = state.session.session_id;
    caseObj.interview.active_goals_count = (state.goals || []).filter(
      (g) => g.status === "ACTIVE" || g.status === "PROPOSED" || g.status === "NEEDS_INPUT"
    ).length;
    caseObj.interview.decisions_count = (state.decisions || []).length;
    caseObj.interview.unresolved_conflicts_count = (state.conflicts || []).filter(
      (c) => c.resolution_status !== "RESOLVED"
    ).length;
    caseObj.interview.critical_assumptions_count = (state.assumptions || []).filter(
      (a) => a.risk_level === "CRITICAL" && a.status === "ACTIVE"
    ).length;
    caseObj.interview.sufficiency_verdict = state.sufficiency_evaluation.verdict;

    await writeUtf8NoBomAtomic(activeCaseFile, JSON.stringify(caseObj, null, 2));
  } catch {
    // Ignore if active_case.json does not exist
  }
}

export async function saveInterviewState(repoRoot: string, state: InterviewState): Promise<void> {
  const root = path.resolve(repoRoot);
  const stateFile = path.join(root, ".agents", "state", "interview_state.json");
  await withFileLock(stateFile, async () => {
    await saveInterviewStateInternal(root, state);
  });
}

// ============================================================================
// 13 Actions Implementation
// ============================================================================

export interface InitOptions {
  repoRoot?: string;
  caseId?: string;
  force?: boolean;
}

export async function initInterview(options: InitOptions = {}): Promise<InterviewState> {
  const repoRoot = path.resolve(options.repoRoot || findRepoRoot());
  const stateDir = path.join(repoRoot, ".agents", "state");
  await fs.mkdir(stateDir, { recursive: true });
  const stateFile = path.join(stateDir, "interview_state.json");
  const activeCaseFile = path.join(stateDir, "active_case.json");

  return await withFileLock(stateFile, async () => {
    let authoritativeCaseId = "CASE-INITIAL";
    try {
      const rawCase = await fs.readFile(activeCaseFile, "utf8");
      const cleanCase = rawCase.charCodeAt(0) === 0xfeff ? rawCase.slice(1) : rawCase;
      const caseObj = JSON.parse(cleanCase);
      if (caseObj.case_id) {
        authoritativeCaseId = caseObj.case_id;
      }
    } catch {
      // default
    }

    const cId = options.caseId || authoritativeCaseId;
    if (options.caseId && options.caseId !== authoritativeCaseId && !options.force) {
      throw new Error(
        `[CASE_MISMATCH] Requested CaseId '${options.caseId}' does not match active_case.json authoritative CaseId '${authoritativeCaseId}'. Pass -Force to override.`
      );
    }

    // Destructive check (DIFF-02)
    try {
      const raw = await fs.readFile(stateFile, "utf8");
      const clean = raw.charCodeAt(0) === 0xfeff ? raw.slice(1) : raw;
      const existing = JSON.parse(clean);
      if (existing && existing.session) {
        const hasContent =
          (existing.goals && existing.goals.length > 0) ||
          (existing.questions && existing.questions.length > 0) ||
          (existing.decisions && existing.decisions.length > 0);
        if (hasContent && !options.force) {
          throw new Error(
            `[DESTRUCTIVE_INIT_REFUSED] Active interview session exists with ID '${existing.session.session_id}' and existing goals/questions/decisions. Refusing destructive overwrite without -Force.`
          );
        }

        // Create backup
        const backupDir = path.join(repoRoot, ".agents", "state", "cases");
        await fs.mkdir(backupDir, { recursive: true });
        const ts = formatTimestamp(new Date()).replace("-", "_");
        const backupFile = path.join(backupDir, `interview_backup_${ts}.json`);
        await fs.copyFile(stateFile, backupFile);
      }
    } catch (err: any) {
      if (err.message && err.message.includes("[DESTRUCTIVE_INIT_REFUSED]")) {
        throw err;
      }
    }

    const now = formatIsoLocal();
    const sessionId = `INT-SESSION-${formatTimestamp(new Date())}`;

    const initState: InterviewState = {
      schema_version: 1,
      case_id: cId,
      session: {
        session_id: sessionId,
        status: "IN_PROGRESS",
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
        verdict: "PENDING",
        evaluated_at: null,
        goal_evaluations: [],
        blocking_reasons: [],
        deferred_decisions: [],
        assumptions_summary: {
          total: 0,
          benign: 0,
          critical: 0,
          pending_approval: 0,
        },
        summary: "Interview session initialized. Ready for context ingestion.",
      },
      last_updated: now,
    };

    await saveInterviewStateInternal(repoRoot, initState);
    return initState;
  });
}

export async function getInterviewStatus(repoRoot: string = findRepoRoot()): Promise<{
  state: InterviewState;
  summary: {
    sessionId: string;
    caseId: string;
    sessionStatus: string;
    sufficiencyVerdict: string;
    goalsTotal: number;
    questionsTotal: number;
    questionsAsked: number;
    questionsAnswered: number;
    decisionsTotal: number;
    decisionsApproved: number;
    assumptionsTotal: number;
    assumptionsCritical: number;
    conflictsTotal: number;
    conflictsUnresolved: number;
    unknownsTotal: number;
    unknownsOpen: number;
    scopeChangesTotal: number;
    blockingReasons: string[];
  };
}> {
  const state = await getInterviewState(repoRoot);
  const questionsAsked = state.questions.filter((q) => q.status === "ASKED").length;
  const questionsAnswered = state.questions.filter((q) => q.status === "ANSWERED").length;
  const decisionsApproved = state.decisions.filter((d) => d.approval_status === "APPROVED").length;
  const assumptionsCritical = state.assumptions.filter(
    (a) => a.risk_level === "CRITICAL" && a.status === "ACTIVE"
  ).length;
  const conflictsUnresolved = state.conflicts.filter((c) => c.resolution_status !== "RESOLVED").length;
  const unknownsOpen = state.unknowns.filter((u) => u.status === "OPEN" || !u.status).length;

  return {
    state,
    summary: {
      sessionId: state.session.session_id,
      caseId: state.case_id,
      sessionStatus: state.session.status,
      sufficiencyVerdict: state.sufficiency_evaluation.verdict,
      goalsTotal: state.goals.length,
      questionsTotal: state.questions.length,
      questionsAsked,
      questionsAnswered,
      decisionsTotal: state.decisions.length,
      decisionsApproved,
      assumptionsTotal: state.assumptions.length,
      assumptionsCritical,
      conflictsTotal: state.conflicts.length,
      conflictsUnresolved,
      unknownsTotal: state.unknowns.length,
      unknownsOpen,
      scopeChangesTotal: state.scope_changes.length,
      blockingReasons: state.sufficiency_evaluation.blocking_reasons,
    },
  };
}

export interface RecordGoalOptions {
  repoRoot?: string;
  goalId: string;
  description: string;
  category?: string;
  domain?: string;
  priority?: string;
  relatedRequirements?: string | string[];
}

export async function recordGoal(options: RecordGoalOptions): Promise<Goal> {
  if (!options.goalId || !options.description) {
    throw new Error("GoalId and Description are mandatory.");
  }
  const repoRoot = path.resolve(options.repoRoot || findRepoRoot());
  const stateFile = path.join(repoRoot, ".agents", "state", "interview_state.json");

  return await withFileLock(stateFile, async () => {
    const state = await getInterviewState(repoRoot);

    const existing = state.goals.find((g) => g.goal_id === options.goalId);
    let goal: Goal;
    if (existing) {
      existing.description = options.description;
      if (options.priority) existing.priority = normalizePriority(options.priority);
      if (options.relatedRequirements) {
        existing.related_requirements = cleanArray(options.relatedRequirements);
      }
      goal = existing;
    } else {
      goal = {
        goal_id: options.goalId,
        description: options.description,
        category: options.domain || options.category || "GENERAL",
        priority: normalizePriority(options.priority || "P1_HIGH"),
        status: "ACTIVE",
        related_requirements: cleanArray(options.relatedRequirements),
      };
      state.goals.push(goal);
    }

    state.session.current_goal = options.goalId;
    state.session.status = "IN_PROGRESS";
    await saveInterviewStateInternal(repoRoot, state);
    return goal;
  });
}

export interface RecordQuestionOptions {
  repoRoot?: string;
  questionId: string;
  text: string;
  reason: string;
  domain?: string;
  topicKey?: string;
  goalIds?: string | string[];
  decisionIds?: string | string[];
  expectedInfo?: string;
  priority?: string;
  force?: boolean;
  supersede?: boolean;
  allowRepeat?: boolean;
}

export async function recordQuestion(options: RecordQuestionOptions): Promise<Question> {
  if (!options.questionId || !options.text || !options.reason) {
    throw new Error("QuestionId, Text, and Reason are mandatory.");
  }
  const repoRoot = path.resolve(options.repoRoot || findRepoRoot());
  const stateFile = path.join(repoRoot, ".agents", "state", "interview_state.json");

  return await withFileLock(stateFile, async () => {
    const state = await getInterviewState(repoRoot);

    const cleanText = options.text.trim().toLowerCase().replace(/\s+/g, " ");
    const existingQ = state.questions.find((q) => q.question_id === options.questionId);

    // Duplicate QuestionId check (DIFF-05)
    if (existingQ) {
      const priorText = existingQ.question_text.trim().toLowerCase().replace(/\s+/g, " ");
      if (priorText !== cleanText) {
        if (!options.force && !options.supersede) {
          throw new Error(
            `[DUPLICATE_QUESTION_ID_REJECTED] QuestionId '${options.questionId}' already exists in interview state with different text ('${existingQ.question_text}'). Overwriting question history is rejected to prevent silent data loss. Pass -Force or -Supersede to override.`
          );
        }
      }
    }

    // TopicKey duplicate check on (domain, topic_key)
    const targetDomain = options.domain || "GENERAL";
    if (options.topicKey && options.topicKey.trim().length > 0) {
      const cleanTopicKey = options.topicKey.trim().toLowerCase();
      const matchingTopicQ = state.questions.find(
        (q) =>
          q.question_id !== options.questionId &&
          (q.domain || "GENERAL") === targetDomain &&
          q.topic_key &&
          q.topic_key.trim().toLowerCase() === cleanTopicKey
      );
      if (matchingTopicQ) {
        if (!options.force && !options.supersede) {
          throw new Error(
            `[DUPLICATE_TOPIC_KEY_REJECTED] Question with topic_key '${options.topicKey}' in domain '${targetDomain}' already exists in interview state (QuestionId: '${matchingTopicQ.question_id}'). Rejecting duplicate topic to avoid redundancy. Pass -Force or -Supersede to override.`
          );
        }
      }
    }

    // Session limits enforcement (exclude synthetic questions prefixed with SPONTANEOUS-)
    const maxTotalQ = state.session.max_total_questions ?? 15;
    const maxClarification = state.session.max_clarification_per_goal ?? 2;
    const isNewQuestion = !existingQ;

    const countedQuestions = state.questions.filter((q) => !q.question_id.startsWith("SPONTANEOUS-"));

    if (isNewQuestion && !options.questionId.startsWith("SPONTANEOUS-") && countedQuestions.length >= maxTotalQ) {
      if (!options.force) {
        throw new Error(
          `[SESSION_LIMIT_EXCEEDED] Maximum total questions limit (${maxTotalQ}) reached for this interview session. Further questions rejected; auto-delegate Two-Way Door decisions to Assumption Record or mark BLOCKED. Pass -Force to override.`
        );
      }
    }

    // Check clarification per goal limit
    const cleanGoalIds = cleanArray(options.goalIds);
    for (const gid of cleanGoalIds) {
      const priorGoalQ = countedQuestions.filter(
        (q) => q.question_id !== options.questionId && (q.related_goal_ids || []).includes(gid)
      );
      if (priorGoalQ.length >= maxClarification && isNewQuestion && !options.questionId.startsWith("SPONTANEOUS-")) {
        if (!options.force) {
          throw new Error(
            `[GOAL_CLARIFICATION_LIMIT_EXCEEDED] Goal '${gid}' has already reached the maximum clarification limit of ${maxClarification} questions (Asked: ${priorGoalQ.length}). Under R5/R7, Two-Way Door decisions must be auto-delegated to Assumption Record or marked BLOCKED. Pass -Force to override.`
          );
        }
      }
    }

    // Repetition check (DIFF-03)
    const matchingQ = state.questions.find(
      (q) =>
        q.question_id !== options.questionId &&
        q.question_text.trim().toLowerCase().replace(/\s+/g, " ") === cleanText
    );

    if (matchingQ) {
      if (!options.allowRepeat) {
        throw new Error(
          `[REPETITION_REJECTED] Question identical to '${matchingQ.question_id}' was already recorded (Status: ${matchingQ.status}). Repeating questions requires explicit justification under R7. Pass -AllowRepeat -Reason '<detailed reason>'.`
        );
      }
      if (!options.reason || options.reason.trim().length === 0) {
        throw new Error(
          `[REPETITION_REJECTED] -AllowRepeat requires a valid non-empty -Reason explaining why repetition is necessary under R7.`
        );
      }
    }

    const newQ: Question = {
      question_id: options.questionId,
      question_text: options.text,
      question_reason: options.reason,
      domain: targetDomain,
      topic_key: options.topicKey && options.topicKey.trim().length > 0 ? options.topicKey.trim() : null,
      related_goal_ids: cleanGoalIds,
      related_decision_ids: cleanArray(options.decisionIds),
      expected_information: options.expectedInfo || "",
      priority: options.priority || "MEDIUM",
      status: "ASKED",
      asked_at: formatIsoLocal(),
      repetition: matchingQ
        ? {
            is_repeated: true,
            prior_question_id: matchingQ.question_id,
            justification: options.reason,
          }
        : null,
    };

    state.questions = state.questions.filter((q) => q.question_id !== options.questionId);
    state.questions.push(newQ);
    await saveInterviewStateInternal(repoRoot, state);
    return newQ;
  });
}

export interface RecordAnswerOptions {
  repoRoot?: string;
  answerId: string;
  questionId?: string;
  answer: string;
  interpreted?: string;
  type?: AnswerType | string;
  source?: AnswerSource | string;
  confidence?: Confidence | string;
  conflictId?: string;
  spontaneous?: boolean;
  domain?: string;
  topicKey?: string;
  goalIds?: string | string[];
  decisionIds?: string | string[];
}

export async function recordAnswer(options: RecordAnswerOptions): Promise<Answer> {
  if (!options.answerId || !options.answer) {
    throw new Error("AnswerId and Answer are mandatory.");
  }
  const repoRoot = path.resolve(options.repoRoot || findRepoRoot());
  const stateFile = path.join(repoRoot, ".agents", "state", "interview_state.json");

  return await withFileLock(stateFile, async () => {
    const state = await getInterviewState(repoRoot);

    const q = options.questionId ? state.questions.find((x) => x.question_id === options.questionId) : undefined;

    let ansType = options.type || "CLEAR";
    let ansSource = options.source || "USER_EXPLICIT";
    let effQId = options.questionId;

    // Orphan Answer Prevention (DIFF-04)
    if (!q) {
      if (!options.spontaneous && options.type !== "SPONTANEOUS_INFO") {
        throw new Error(
          `[ORPHAN_ANSWER_REJECTED] QuestionId '${options.questionId}' does not exist in interview state. To record unsolicited user information, pass -Spontaneous.`
        );
      }
      ansType = "SPONTANEOUS_INFO";
      ansSource = "USER_SPONTANEOUS";
      effQId = options.questionId || `SPONTANEOUS-${options.answerId}`;

      // Create synthetic question to prevent referential breakage
      const synthQ: Question = {
        question_id: effQId,
        question_text: `[Spontaneous user contribution] ${options.answer}`,
        question_reason: "Unsolicited user input captured spontaneously",
        domain: options.domain || "GENERAL",
        topic_key: options.topicKey || null,
        related_goal_ids: cleanArray(options.goalIds),
        related_decision_ids: cleanArray(options.decisionIds),
        expected_information: "Unsolicited info",
        priority: "MEDIUM",
        status: "ANSWERED",
        asked_at: formatIsoLocal(),
      };
      state.questions = state.questions.filter((x) => x.question_id !== effQId);
      state.questions.push(synthQ);
    } else {
      effQId = options.questionId!;
      // State machine: conclusive types -> ANSWERED; ambiguous/partial/conflicting -> NEEDS_CLARIFICATION
      if (["CLEAR", "CONDITIONAL", "OUT_OF_SCOPE", "SPONTANEOUS_INFO", "DELEGATED_CHOICE"].includes(ansType)) {
        q.status = "ANSWERED";
      } else if (["AMBIGUOUS", "PARTIAL", "CONFLICTING"].includes(ansType)) {
        q.status = "NEEDS_CLARIFICATION";
      } else {
        q.status = "ANSWERED";
      }
    }

    const newA: Answer = {
      answer_id: options.answerId,
      question_id: effQId!,
      original_answer: options.answer,
      interpreted_answer: options.interpreted || options.answer,
      answer_type: ansType,
      answer_source: ansSource,
      confidence: options.confidence || "HIGH",
      conflict_id: options.conflictId || null,
      recorded_at: formatIsoLocal(),
    };

    state.answers = state.answers.filter((a) => a.answer_id !== options.answerId);
    state.answers.push(newA);
    await saveInterviewStateInternal(repoRoot, state);
    return newA;
  });
}

export interface RecordDecisionOptions {
  repoRoot?: string;
  decisionId: string;
  description: string;
  selectedOption: string;
  options?: string | string[];
  owner?: string;
  approvalStatus?: DecisionStatus | string;
  evidenceRefs?: string | string[];
  relatedRequirements?: string | string[];
}

export async function recordDecision(options: RecordDecisionOptions): Promise<Decision> {
  if (!options.decisionId || !options.description || !options.selectedOption) {
    throw new Error("DecisionId, Description, and SelectedOption are mandatory.");
  }
  const validStatuses = ["PROPOSED", "APPROVED", "REJECTED", "DEFERRED"];
  const appStatus = (options.approvalStatus || "PROPOSED").toUpperCase();
  if (!validStatuses.includes(appStatus)) {
    throw new Error(`Invalid decision ApprovalStatus '${options.approvalStatus}'. Valid: ${validStatuses.join(", ")}`);
  }

  const repoRoot = path.resolve(options.repoRoot || findRepoRoot());
  const stateFile = path.join(repoRoot, ".agents", "state", "interview_state.json");

  return await withFileLock(stateFile, async () => {
    const state = await getInterviewState(repoRoot);

    const newD: Decision = {
      decision_id: options.decisionId,
      description: options.description,
      available_options: options.options ? cleanArray(options.options) : [options.selectedOption],
      selected_option: options.selectedOption,
      decision_owner: options.owner || "USER_PO",
      approval_status: appStatus,
      evidence_refs: cleanArray(options.evidenceRefs),
      related_requirements: cleanArray(options.relatedRequirements),
    };

    state.decisions = state.decisions.filter((d) => d.decision_id !== options.decisionId);
    state.decisions.push(newD);
    await saveInterviewStateInternal(repoRoot, state);
    return newD;
  });
}

export interface RecordAssumptionOptions {
  repoRoot?: string;
  assumptionId: string;
  description: string;
  rationale: string;
  impact?: string;
  riskLevel?: RiskLevel | string;
  approvalStatus?: string;
  verificationTask?: string;
  downstreamDeps?: string | string[];
}

export async function recordAssumption(options: RecordAssumptionOptions): Promise<Assumption> {
  if (!options.assumptionId || !options.description || !options.rationale) {
    throw new Error("AssumptionId, Description, and Rationale are mandatory.");
  }
  const validStatuses = ["PENDING_APPROVAL", "APPROVED", "REJECTED"];
  let appStatus = (options.approvalStatus || "PENDING_APPROVAL").toUpperCase();
  if (appStatus === "PROPOSED") {
    appStatus = "PENDING_APPROVAL";
  }
  if (!validStatuses.includes(appStatus)) {
    throw new Error(`Invalid assumption ApprovalStatus '${options.approvalStatus}'. Valid: ${validStatuses.join(", ")}`);
  }

  const repoRoot = path.resolve(options.repoRoot || findRepoRoot());
  const stateFile = path.join(repoRoot, ".agents", "state", "interview_state.json");

  return await withFileLock(stateFile, async () => {
    const state = await getInterviewState(repoRoot);

    const newAs: Assumption = {
      assumption_id: options.assumptionId,
      description: options.description,
      rationale: options.rationale,
      impact: options.impact || "Low",
      risk_level: options.riskLevel || "BENIGN",
      approval_status: appStatus,
      verification_task: options.verificationTask || "Verify during Step 10 QA",
      status: "ACTIVE",
      invalidated_at: null,
      revocation_reason: null,
      downstream_dependencies: cleanArray(options.downstreamDeps),
    };

    state.assumptions = state.assumptions.filter((a) => a.assumption_id !== options.assumptionId);
    state.assumptions.push(newAs);
    await saveInterviewStateInternal(repoRoot, state);
    return newAs;
  });
}

export interface RecordUnknownOptions {
  repoRoot?: string;
  unknownId: string;
  description: string;
  impact?: string;
  priority?: Priority | string;
  status?: UnknownStatus | string;
  resolutionStrategy?: string;
  justification?: string;
  reason?: string;
  rationale?: string;
  approval?: string;
  approvalStatus?: string;
}

export async function recordUnknown(options: RecordUnknownOptions): Promise<Unknown> {
  if (!options.unknownId || !options.description) {
    throw new Error("UnknownId and Description are mandatory.");
  }
  const validPriorities = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "BENIGN"];
  const prio = (options.priority || "MEDIUM").toUpperCase();
  if (!validPriorities.includes(prio)) {
    throw new Error(`Invalid unknown Priority '${options.priority}'. Valid: ${validPriorities.join(", ")}`);
  }
  const validStatuses = ["OPEN", "RESOLVED", "DEFERRED"];
  const unkStatus = (options.status || "OPEN").toUpperCase();
  if (!validStatuses.includes(unkStatus)) {
    throw new Error(`Invalid unknown Status '${options.status}'. Valid: ${validStatuses.join(", ")}`);
  }

  const repoRoot = path.resolve(options.repoRoot || findRepoRoot());
  const stateFile = path.join(repoRoot, ".agents", "state", "interview_state.json");

  return await withFileLock(stateFile, async () => {
    const state = await getInterviewState(repoRoot);

    const existingUnk = state.unknowns.find((u) => u.unknown_id === options.unknownId);
    const just =
      options.justification ||
      options.reason ||
      options.rationale ||
      existingUnk?.justification ||
      null;
    const appr =
      options.approval ||
      options.approvalStatus ||
      existingUnk?.approval ||
      null;

    const newUnk: Unknown = {
      unknown_id: options.unknownId,
      description: options.description,
      impact: options.impact || "Unassessed",
      priority: prio,
      status: unkStatus,
      resolution_strategy: options.resolutionStrategy || "TBD",
      justification: just,
      approval: appr,
      approval_status: appr,
    };

    state.unknowns = state.unknowns.filter((u) => u.unknown_id !== options.unknownId);
    state.unknowns.push(newUnk);
    await saveInterviewStateInternal(repoRoot, state);
    return newUnk;
  });
}

export interface RecordConflictOptions {
  repoRoot?: string;
  conflictId: string;
  explanation: string;
  conflictingItems?: string | string[];
  severity?: Severity | string;
  resolutionStrategy?: string;
}

export async function recordConflict(options: RecordConflictOptions): Promise<Conflict> {
  if (!options.conflictId || !options.explanation) {
    throw new Error("ConflictId and Explanation are mandatory.");
  }
  const repoRoot = path.resolve(options.repoRoot || findRepoRoot());
  const stateFile = path.join(repoRoot, ".agents", "state", "interview_state.json");

  return await withFileLock(stateFile, async () => {
    const state = await getInterviewState(repoRoot);

    const newC: Conflict = {
      conflict_id: options.conflictId,
      conflicting_items: cleanArray(options.conflictingItems),
      explanation: options.explanation,
      severity: options.severity || "MAJOR",
      resolution_status: "UNRESOLVED",
      resolution_strategy: options.resolutionStrategy || null,
      resolved_at: null,
    };

    state.conflicts = state.conflicts.filter((c) => c.conflict_id !== options.conflictId);
    state.conflicts.push(newC);
    await saveInterviewStateInternal(repoRoot, state);
    return newC;
  });
}

export interface ResolveConflictOptions {
  repoRoot?: string;
  conflictId: string;
  resolutionStrategy: string;
}

export async function resolveConflict(options: ResolveConflictOptions): Promise<Conflict> {
  if (!options.conflictId || !options.resolutionStrategy) {
    throw new Error("ConflictId and ResolutionStrategy are mandatory.");
  }
  const repoRoot = path.resolve(options.repoRoot || findRepoRoot());
  const stateFile = path.join(repoRoot, ".agents", "state", "interview_state.json");

  return await withFileLock(stateFile, async () => {
    const state = await getInterviewState(repoRoot);

    const c = state.conflicts.find((x) => x.conflict_id === options.conflictId);
    if (!c) {
      throw new Error(`Conflict ${options.conflictId} not found.`);
    }

    c.resolution_status = "RESOLVED";
    c.resolution_strategy = options.resolutionStrategy;
    c.resolved_at = formatIsoLocal();

    await saveInterviewStateInternal(repoRoot, state);
    return c;
  });
}

export interface RecordScopeChangeOptions {
  repoRoot?: string;
  changeId: string;
  previousScope: string;
  newScope: string;
  decisionIds?: string | string[];
  relatedRequirements?: string | string[];
}

export async function recordScopeChange(options: RecordScopeChangeOptions): Promise<ScopeChange> {
  if (!options.changeId || !options.previousScope || !options.newScope) {
    throw new Error("ChangeId, PreviousScope, and NewScope are mandatory.");
  }
  const repoRoot = path.resolve(options.repoRoot || findRepoRoot());
  const stateFile = path.join(repoRoot, ".agents", "state", "interview_state.json");

  return await withFileLock(stateFile, async () => {
    const state = await getInterviewState(repoRoot);

    const newSC: ScopeChange = {
      change_id: options.changeId,
      previous_scope: options.previousScope,
      new_scope: options.newScope,
      affected_decisions: cleanArray(options.decisionIds),
      affected_requirements: cleanArray(options.relatedRequirements),
      recorded_at: formatIsoLocal(),
    };

    state.scope_changes = state.scope_changes.filter((sc) => sc.change_id !== options.changeId);
    state.scope_changes.push(newSC);
    await saveInterviewStateInternal(repoRoot, state);
    return newSC;
  });
}

export async function evaluateSufficiency(repoRoot: string = findRepoRoot()): Promise<SufficiencyEvaluation> {
  const root = path.resolve(repoRoot);
  const stateFile = path.join(root, ".agents", "state", "interview_state.json");

  return await withFileLock(stateFile, async () => {
    const state = await getInterviewState(root);

    const blocking: string[] = [];
    const deferred: string[] = [];
    const goalEvals: GoalEvaluation[] = [];

    // 1. Check Unresolved Conflicts
    const unresolvedConflicts = state.conflicts.filter(
      (c) => c.resolution_status !== "RESOLVED" && (c.severity === "CRITICAL" || c.severity === "MAJOR")
    );
    for (const c of unresolvedConflicts) {
      blocking.push(`Unresolved ${c.severity} Conflict: ${c.conflict_id} - ${c.explanation}`);
    }

    // 1.1 Check Unresolved Conflicting Answers without resolved conflict_id
    const resolvedConflictIds = state.conflicts
      .filter((c) => c.resolution_status === "RESOLVED")
      .map((c) => c.conflict_id);

    const unresolvedConflictingAnswers = state.answers.filter((a) => {
      if (a.answer_type !== "CONFLICTING") return false;
      if (a.conflict_id && resolvedConflictIds.includes(a.conflict_id)) {
        return false;
      }
      const matchingRes = state.conflicts.find(
        (c) =>
          c.resolution_status === "RESOLVED" &&
          (c.conflicting_items.includes(a.answer_id) ||
            c.conflicting_items.includes(a.question_id) ||
            (a.conflict_id && c.conflict_id === a.conflict_id))
      );
      return !matchingRes;
    });

    for (const a of unresolvedConflictingAnswers) {
      blocking.push(
        `Unresolved CONFLICTING answer without resolved conflict_id: ${a.answer_id} (Question: ${a.question_id})`
      );
    }

    // 2. Check Critical Assumptions Unapproved
    const criticalAssumptions = state.assumptions.filter(
      (a) => a.status === "ACTIVE" && a.risk_level === "CRITICAL" && a.approval_status !== "APPROVED"
    );
    for (const a of criticalAssumptions) {
      blocking.push(`Critical assumption requires user approval: ${a.assumption_id} - ${a.description}`);
    }

    // 3. Check Critical/High Unknowns Unresolved & Deferred Critical Unknowns
    const openImportantUnknowns = state.unknowns.filter(
      (u) => (u.status === "OPEN" || !u.status) && (u.priority === "CRITICAL" || u.priority === "HIGH")
    );
    for (const u of openImportantUnknowns) {
      blocking.push(`Important unresolved unknown (${u.priority}): ${u.unknown_id} - ${u.description}`);
    }

    const deferredCriticalUnknowns = state.unknowns.filter(
      (u) => u.priority === "CRITICAL" && u.status === "DEFERRED"
    );
    const unapprovedDeferredCritical: Unknown[] = [];

    for (const u of deferredCriticalUnknowns) {
      let hasJustification = false;
      let justVal = "";
      if (u.justification && u.justification.trim().length > 0) {
        hasJustification = true;
        justVal = u.justification.trim();
      } else if ((u as any).deferral_justification && (u as any).deferral_justification.trim().length > 0) {
        hasJustification = true;
        justVal = (u as any).deferral_justification.trim();
      }

      let hasApproval = false;
      let appVal = "";
      const rawApp = (u.approval || u.approval_status || "").trim();
      if (rawApp.length > 0) {
        const upper = rawApp.toUpperCase();
        if (!["REJECTED", "PENDING", "PENDING_APPROVAL", "NO", "FALSE", "UNAPPROVED"].includes(upper)) {
          hasApproval = true;
          appVal = rawApp;
        }
      } else if ((u as any).approved === true) {
        hasApproval = true;
        appVal = "APPROVED";
      }

      if (hasJustification && hasApproval) {
        deferred.push(
          `DEFERRED CRITICAL UNKNOWN ${u.unknown_id}: ${u.description} [Justification: ${justVal}, Approval: ${appVal}]`
        );
      } else {
        unapprovedDeferredCritical.push(u);
        if (!hasJustification && !hasApproval) {
          blocking.push(
            `Deferred critical unknown requires explicit justification and approval: ${u.unknown_id} - ${u.description}`
          );
        } else if (!hasJustification) {
          blocking.push(
            `Deferred critical unknown requires explicit justification: ${u.unknown_id} - ${u.description}`
          );
        } else {
          blocking.push(`Deferred critical unknown requires approval: ${u.unknown_id} - ${u.description}`);
        }
      }
    }

    const blockingUnknowns = [...openImportantUnknowns, ...unapprovedDeferredCritical];

    // 4. Check Goals Resolution
    const activeGoals = state.goals.filter((g) => g.status !== "ACHIEVED" && g.status !== "ABANDONED");

    if (activeGoals.length === 0) {
      blocking.push("No active goals recorded in interview state.");
    } else {
      for (const g of activeGoals) {
        const gId = g.goal_id;
        const gBlockers: string[] = [];

        if (!g.description || g.description.trim().length === 0) {
          gBlockers.push(`Goal ${gId} has empty description.`);
        }

        // Find matching decisions using word boundary check so G-1 never collides with G-10 or G-11
        const matchingDecisions = state.decisions.filter(
          (d) =>
            (d.related_requirements && d.related_requirements.includes(gId)) ||
            matchesGoalId(d.description, gId) ||
            (g.related_requirements && g.related_requirements.includes(d.decision_id))
        );

        // Find matching approved assumptions using word boundary check
        const matchingAssumptions = state.assumptions.filter(
          (a) =>
            (a.downstream_dependencies && a.downstream_dependencies.includes(gId)) ||
            matchesGoalId(a.description, gId) ||
            (g.related_requirements && g.related_requirements.includes(a.assumption_id))
        );
        let approvedAssumptions = matchingAssumptions.filter(
          (a) => a.approval_status === "APPROVED" && (a.status === "ACTIVE" || !a.status)
        );

        let gStatus: GoalStatus = "NEEDS_INPUT";
        const approvedDecs = matchingDecisions.filter((d) => d.approval_status === "APPROVED");
        const deferredDecs = matchingDecisions.filter((d) => d.approval_status === "DEFERRED");
        const proposedDecs = matchingDecisions.filter((d) => d.approval_status === "PROPOSED");
        const rejectedDecs = matchingDecisions.filter((d) => d.approval_status === "REJECTED");

        // Find pending questions
        const pendingQ = state.questions.filter(
          (q) =>
            (q.related_goal_ids || []).includes(gId) &&
            (q.status === "ASKED" ||
              (q.status === "NEEDS_CLARIFICATION" && approvedDecs.length === 0 && approvedAssumptions.length === 0))
        );

        for (const pq of pendingQ) {
          gBlockers.push(`Goal ${gId} has unanswered question: ${pq.question_id} ('${pq.question_text}')`);
        }

        const maxClarification = state.session.max_clarification_per_goal ?? 2;
        const goalQuestions = state.questions.filter(
          (q) => !q.question_id.startsWith("SPONTANEOUS-") && (q.related_goal_ids || []).includes(gId)
        );
        const clarificationLimitReached = goalQuestions.length >= maxClarification;
        const normalizedGoalPrio = normalizePriority(g.priority);
        const isOneWayDoor =
          normalizedGoalPrio === "P0_CRITICAL" || matchingAssumptions.some((a) => a.risk_level === "CRITICAL");

        const autoAsmId = `ASM-AUTODELEGATE-${gId}`;
        const existingAuto = state.assumptions.find((a) => a.assumption_id === autoAsmId);

        if (approvedDecs.length > 0) {
          gStatus = "RESOLVED";
        } else if (rejectedDecs.length > 0) {
          gBlockers.push(`Goal ${gId} is linked to REJECTED decision ${rejectedDecs[0].decision_id}.`);
          gStatus = "BLOCKED";
        } else if (existingAuto && (existingAuto.approval_status === "REJECTED" || existingAuto.status === "INVALIDATED")) {
          gBlockers.push(`Goal ${gId} auto-delegate assumption ${existingAuto.assumption_id} was rejected or invalidated.`);
          gStatus = "BLOCKED";
        } else if (approvedAssumptions.length > 0) {
          gStatus = "ASSUMED_WITH_APPROVAL";
        } else if (existingAuto) {
          if (existingAuto.approval_status === "APPROVED" && (existingAuto.status === "ACTIVE" || !existingAuto.status)) {
            approvedAssumptions = [existingAuto];
            gStatus = "ASSUMED_WITH_APPROVAL";
          } else {
            gBlockers.push(`Goal ${gId} auto-delegate assumption ${existingAuto.assumption_id} is pending approval.`);
            gStatus = "NEEDS_INPUT";
          }
        } else if (clarificationLimitReached && proposedDecs.length === 0 && deferredDecs.length === 0) {
          if (!isOneWayDoor) {
            const autoAsm: Assumption = {
              assumption_id: autoAsmId,
              description: `${gId}: Tự động ủy quyền lựa chọn kỹ thuật an toàn (Two-Way Door Safe Default)`,
              rationale: `Mục tiêu ${gId} đạt giới hạn làm rõ (${maxClarification} câu hỏi); tự động áp dụng Safe Default theo R5`,
              impact: "Low",
              risk_level: "BENIGN",
              approval_status: "APPROVED",
              verification_task: "Verify during Step 10 QA",
              status: "ACTIVE",
              invalidated_at: null,
              revocation_reason: null,
              downstream_dependencies: [gId],
            };
            state.assumptions.push(autoAsm);
            approvedAssumptions = [autoAsm];
            gStatus = "ASSUMED_WITH_APPROVAL";
          } else {
            gBlockers.push(
              `Goal ${gId} reached clarification limit (${maxClarification} questions) on a One-Way Door / Critical goal. Marked BLOCKED.`
            );
            gStatus = "BLOCKED";
          }
        } else if (proposedDecs.length > 0 && deferredDecs.length === 0) {
          gBlockers.push(`Goal ${gId} decision ${proposedDecs[0].decision_id} remains PROPOSED (requires user approval).`);
          gStatus = "NEEDS_INPUT";
        } else if (deferredDecs.length > 0) {
          if (isOneWayDoor) {
            gBlockers.push(
              `Goal ${gId} is P0_CRITICAL / One-Way Door and cannot be resolved with DEFERRED decision ${deferredDecs[0].decision_id} without explicit approval.`
            );
            gStatus = "BLOCKED";
          } else {
            gStatus = "DEFERRED";
          }
        } else {
          gBlockers.push(`Goal ${gId} has no resolving decision recorded.`);
          gStatus = "NEEDS_INPUT";
        }

        if (gBlockers.length > 0) {
          blocking.push(...gBlockers);
          if (gStatus === "RESOLVED" || gStatus === "ASSUMED_WITH_APPROVAL") {
            gStatus = "BLOCKED";
          }
        }

        // Preserve goal status enum in state:
        // When gStatus is NEEDS_INPUT, keep goal.status = ACTIVE (or PROPOSED)
        if (gStatus === "NEEDS_INPUT") {
          if (g.status !== "PROPOSED") {
            g.status = "ACTIVE";
          }
        } else {
          g.status = gStatus;
        }

        goalEvals.push({
          goal_id: gId,
          status: gStatus,
          decision_ids: matchingDecisions.map((d) => d.decision_id),
          assumption_ids: approvedAssumptions.map((a) => a.assumption_id),
          pending_questions: pendingQ.map((q) => q.question_id),
          blocking_reasons: gBlockers,
        });
      }
    }

    // 5. Check Decisions Approval Status
    const rejectedDecisions = state.decisions.filter((d) => d.approval_status === "REJECTED");
    for (const d of rejectedDecisions) {
      blocking.push(`Rejected decision requires resolution: ${d.decision_id}`);
    }

    // 6. Collect Deferred Decisions
    const deferredDecisions = state.decisions.filter((d) => d.approval_status === "DEFERRED");
    for (const dd of deferredDecisions) {
      deferred.push(`${dd.decision_id}: ${dd.description}`);
    }

    // Calculate Final Verdict
    let verdict: SufficiencyVerdict = "SUFFICIENT";
    let summary = "All active goals, decisions, and assumptions meet the Exit Gate criteria. Ready for Spec Freeze.";

    if (blocking.length > 0) {
      if (
        unresolvedConflicts.length > 0 ||
        unresolvedConflictingAnswers.length > 0 ||
        criticalAssumptions.length > 0 ||
        blockingUnknowns.length > 0 ||
        goalEvals.some((ge) => ge.status === "BLOCKED")
      ) {
        verdict = "BLOCKED";
        summary =
          "Interview is BLOCKED by unresolved conflicts, critical unknowns, unapproved critical assumptions, or blocked goals.";
      } else {
        verdict = "NEEDS_INPUT";
        summary = "Interview requires additional input, question responses, or decision approval before Gate 03.";
      }
    }

    const now = formatIsoLocal();
    const benignCount = state.assumptions.filter((a) => a.status === "ACTIVE" && a.risk_level === "BENIGN").length;
    const critCount = state.assumptions.filter((a) => a.status === "ACTIVE" && a.risk_level === "CRITICAL").length;
    const pendingAppr = state.assumptions.filter(
      (a) => a.status === "ACTIVE" && a.approval_status === "PENDING_APPROVAL"
    ).length;

    const evaluation: SufficiencyEvaluation = {
      verdict,
      evaluated_at: now,
      goal_evaluations: goalEvals,
      blocking_reasons: blocking,
      deferred_decisions: deferred,
      assumptions_summary: {
        total: state.assumptions.filter((a) => a.status === "ACTIVE").length,
        benign: benignCount,
        critical: critCount,
        pending_approval: pendingAppr,
      },
      summary,
    };

    state.sufficiency_evaluation = evaluation;
    if (verdict === "SUFFICIENT") {
      state.session.status = "SUFFICIENT";
    } else if (verdict === "BLOCKED") {
      state.session.status = "BLOCKED";
    } else {
      state.session.status = "IN_PROGRESS";
    }

    await saveInterviewStateInternal(root, state);
    return evaluation;
  });
}

export async function validateInterview(repoRoot: string = findRepoRoot()): Promise<{
  valid: boolean;
  errors: string[];
}> {
  const root = path.resolve(repoRoot);
  const state = await getInterviewState(root);
  const errors: string[] = [];

  if (!state.session || !state.session.session_id) {
    errors.push("Invalid interview state: missing session");
  }

  const gIds = state.goals.map((g) => g.goal_id);
  const qIds = state.questions.map((q) => q.question_id);
  const dIds = state.decisions.map((d) => d.decision_id);

  for (const q of state.questions) {
    if (q.related_goal_ids) {
      for (const gid of q.related_goal_ids) {
        if (gid && !gIds.includes(gid)) {
          errors.push(`Question '${q.question_id}' references non-existent goal '${gid}'.`);
        }
      }
    }
    if (q.related_decision_ids) {
      for (const did of q.related_decision_ids) {
        if (did && !dIds.includes(did)) {
          errors.push(`Question '${q.question_id}' references non-existent decision '${did}'.`);
        }
      }
    }
  }

  for (const a of state.answers) {
    if (a.question_id && !qIds.includes(a.question_id) && a.answer_type !== "SPONTANEOUS_INFO") {
      errors.push(`Answer '${a.answer_id}' references non-existent question '${a.question_id}'.`);
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

export interface InterviewActionOptions {
  action: string;
  caseId?: string;
  force?: boolean;
  supersede?: boolean;
  allowRepeat?: boolean;
  spontaneous?: boolean;
  goalId?: string;
  questionId?: string;
  answerId?: string;
  decisionId?: string;
  assumptionId?: string;
  unknownId?: string;
  conflictId?: string;
  changeId?: string;
  description?: string;
  text?: string;
  reason?: string;
  justification?: string;
  domain?: string;
  expectedInfo?: string;
  topicKey?: string;
  answer?: string;
  interpreted?: string;
  type?: string;
  source?: string;
  confidence?: string;
  selectedOption?: string;
  options?: string | string[];
  owner?: string;
  approvalStatus?: string;
  approval?: string;
  rationale?: string;
  impact?: string;
  riskLevel?: string;
  verificationTask?: string;
  conflictingItems?: string | string[];
  explanation?: string;
  severity?: string;
  resolutionStrategy?: string;
  previousScope?: string;
  newScope?: string;
  goalIds?: string | string[];
  decisionIds?: string | string[];
  evidenceRefs?: string | string[];
  relatedRequirements?: string | string[];
  downstreamDeps?: string | string[];
  priority?: string;
  status?: string;
  repoRoot?: string;
}

export async function runInterviewAction(
  options: InterviewActionOptions
): Promise<any> {
  const repoRoot = options.repoRoot
    ? path.resolve(options.repoRoot)
    : findRepoRoot();

  switch (options.action) {
    case "init":
      return await initInterview({
        caseId: options.caseId,
        force: options.force,
        repoRoot,
      });
    case "status":
      return await getInterviewStatus(repoRoot);
    case "record-goal": {
      if (!options.goalId || !options.description) {
        throw new Error("[INVALID_ARGUMENT] record-goal requires goalId and description");
      }
      return await recordGoal({
        goalId: options.goalId,
        description: options.description,
        domain: options.domain,
        priority: options.priority,
        relatedRequirements: options.relatedRequirements,
        repoRoot,
      });
    }
    case "record-question": {
      if (!options.questionId || !options.text || !options.reason) {
        throw new Error("[INVALID_ARGUMENT] record-question requires questionId, text, and reason");
      }
      return await recordQuestion({
        questionId: options.questionId,
        text: options.text,
        reason: options.reason,
        domain: options.domain,
        topicKey: options.topicKey,
        goalIds: options.goalIds,
        decisionIds: options.decisionIds,
        expectedInfo: options.expectedInfo,
        priority: options.priority,
        force: options.force,
        supersede: options.supersede,
        allowRepeat: options.allowRepeat,
        repoRoot,
      });
    }
    case "record-answer": {
      if (!options.answerId || !options.answer) {
        throw new Error("[INVALID_ARGUMENT] record-answer requires answerId and answer");
      }
      return await recordAnswer({
        answerId: options.answerId,
        questionId: options.questionId,
        answer: options.answer,
        interpreted: options.interpreted,
        type: options.type as any,
        source: options.source as any,
        confidence: options.confidence as any,
        conflictId: options.conflictId,
        spontaneous: options.spontaneous,
        domain: options.domain,
        topicKey: options.topicKey,
        goalIds: options.goalIds,
        decisionIds: options.decisionIds,
        repoRoot,
      });
    }
    case "record-decision": {
      if (!options.decisionId || !options.description || !options.selectedOption) {
        throw new Error("[INVALID_ARGUMENT] record-decision requires decisionId, description, and selectedOption");
      }
      return await recordDecision({
        decisionId: options.decisionId,
        description: options.description,
        selectedOption: options.selectedOption,
        options: options.options,
        owner: options.owner,
        approvalStatus: options.approvalStatus as any,
        evidenceRefs: options.evidenceRefs,
        relatedRequirements: options.relatedRequirements,
        repoRoot,
      });
    }
    case "record-assumption": {
      if (!options.assumptionId || !options.description || !options.rationale) {
        throw new Error("[INVALID_ARGUMENT] record-assumption requires assumptionId, description, and rationale");
      }
      return await recordAssumption({
        assumptionId: options.assumptionId,
        description: options.description,
        rationale: options.rationale,
        impact: options.impact,
        riskLevel: options.riskLevel as any,
        approvalStatus: options.approvalStatus,
        verificationTask: options.verificationTask,
        downstreamDeps: options.downstreamDeps,
        repoRoot,
      });
    }
    case "record-unknown": {
      if (!options.unknownId || !options.description) {
        throw new Error("[INVALID_ARGUMENT] record-unknown requires unknownId and description");
      }
      return await recordUnknown({
        unknownId: options.unknownId,
        description: options.description,
        impact: options.impact,
        priority: options.priority as any,
        status: options.status as any,
        resolutionStrategy: options.resolutionStrategy,
        justification: options.justification,
        approval: options.approval,
        approvalStatus: options.approvalStatus,
        repoRoot,
      });
    }
    case "record-conflict": {
      if (!options.conflictId || !options.explanation) {
        throw new Error("[INVALID_ARGUMENT] record-conflict requires conflictId and explanation");
      }
      return await recordConflict({
        conflictId: options.conflictId,
        conflictingItems: options.conflictingItems,
        explanation: options.explanation,
        severity: options.severity as any,
        resolutionStrategy: options.resolutionStrategy,
        repoRoot,
      });
    }
    case "resolve-conflict": {
      if (!options.conflictId || !options.resolutionStrategy) {
        throw new Error("[INVALID_ARGUMENT] resolve-conflict requires conflictId and resolutionStrategy");
      }
      return await resolveConflict({
        conflictId: options.conflictId,
        resolutionStrategy: options.resolutionStrategy,
        repoRoot,
      });
    }
    case "record-scope-change": {
      if (!options.changeId || !options.previousScope || !options.newScope) {
        throw new Error("[INVALID_ARGUMENT] record-scope-change requires changeId, previousScope, and newScope");
      }
      return await recordScopeChange({
        changeId: options.changeId,
        previousScope: options.previousScope,
        newScope: options.newScope,
        decisionIds: options.decisionIds,
        relatedRequirements: options.relatedRequirements,
        repoRoot,
      });
    }
    case "evaluate-sufficiency":
      return await evaluateSufficiency(repoRoot);
    case "validate":
      return await validateInterview(repoRoot);
    default:
      throw new Error(`Unknown interview action: ${options.action}`);
  }

}

