#!/usr/bin/env node
import path from "node:path";
import { Command } from "commander";
import { initWorkspace } from "./core/init.js";
import { runHealthCheck } from "./core/health-check.js";
import { compileTokens } from "./core/compile-tokens.js";
import { verifyCode } from "./core/verify-code.js";
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
} from "./core/interview.js";
import { createSnapshot, restoreSnapshot } from "./core/rollback.js";
import { runGateAction } from "./core/gate.js";
import {
  planContext,
  inspectPlan,
  packContext,
  verifyPacket,
} from "./core/context.js";
import { runAdrAction } from "./core/adr.js";
import { startMcpServer } from "./mcp.js";

const program = new Command();

program
  .name("rea-kit")
  .description("REA-kit-agy v2.0.1 CLI - Reverse Engineering & App Reconstruction Toolkit")
  .version("2.0.1");

program
  .command("init")
  .description("Initialize workspace with 5 standard directories, state machines, and event log")
  .option("-d, --dir <path>", "Target workspace directory (default: current directory)")
  .option("-f, --force", "Force re-initialization and overwrite existing state", false)
  .action(async (options) => {
    try {
      console.log("==========================================================");
      console.log("   INITIALIZING REA-KIT WORKSPACE v2.0.1");
      console.log("==========================================================");

      const res = await initWorkspace({
        dir: options.dir,
        force: options.force,
      });

      console.log(`[OK] Workspace initialized at: ${res.root}`);
      for (const d of res.createdDirs) {
        console.log(` [DIR]  ${d}`);
      }
      for (const f of res.initializedFiles) {
        console.log(` [INIT] ${f}`);
      }
      console.log("==========================================================");
      process.exit(0);
    } catch (err: any) {
      console.error(`[ERROR] Initialization failed: ${err.message}`);
      process.exit(1);
    }
  });

program
  .command("health")
  .alias("check")
  .description("Run workspace and runtime health checks")

  .option("--no-external", "Skip external CLI tool checks")
  .action(async (options) => {
    try {
      console.log("==========================================================");
      console.log("   REA-KIT HEALTH CHECK v2.0.1");
      console.log("==========================================================");

      const result = await runHealthCheck({
        checkExternalTools: options.external !== false,
      });

      for (const check of result.checks) {
        const symbol = check.passed ? "[OK]" : "[FAIL]";
        console.log(`${symbol} (${check.id}/${result.total}) ${check.name}: ${check.message}`);
      }

      console.log("----------------------------------------------------------");
      console.log(`Score: ${result.score}/${result.total}`);

      if (result.activeCase) {
        console.log(`Active Case: ${result.activeCase.case_id} (${result.activeCase.current_phase || "INITIAL"})`);
      }
      if (result.appInput) {
        console.log(`App Input: ${result.appInput.name} (SHA: ${result.appInput.sha256.slice(0, 12)}...)`);
      }

      console.log("==========================================================");
      process.exit(result.passed ? 0 : 1);
    } catch (err: any) {
      console.error(`[ERROR] Health check failed: ${err.message}`);
      process.exit(1);
    }
  });

program
  .command("compile-tokens")
  .description("Compile W3C DTCG design tokens to CSS, Compose Kotlin, and Android XML")
  .option("-t, --tokens <path>", "Path to tokens.json")
  .option("-o, --output <path>", "Output directory for compiled tokens")
  .option("-d, --design-doc <path>", "Path to design.md to update code blocks")
  .action(async (options) => {
    try {
      console.log("==========================================================");
      console.log("   COMPILING DESIGN TOKENS (W3C DTCG 3-LAYER)");
      console.log("==========================================================");

      const result = await compileTokens({
        tokensFile: options.tokens,
        outputDir: options.output,
        designDoc: options.designDoc,
      });

      for (const f of result.generatedFiles) {
        console.log(` [OK] Generated: ${f}`);
      }
      for (const s of result.syncedFiles) {
        console.log(` [SYNC] Synced to: ${s}`);
      }
      if (result.updatedDesignDoc) {
        console.log(" [OK] Updated preview fences in design.md");
      }

      console.log("==========================================================");
      process.exit(0);
    } catch (err: any) {
      console.error(`[ERROR] Compile tokens failed: ${err.message}`);
      process.exit(1);
    }
  });

program
  .command("verify")
  .description("Deterministic code verification & risk classifier")
  .option("-t, --target <path>", "Target source directory (default: 05_MA_NGUON_PHAT_TRIEN)")
  .option("-r, --report <path>", "Report directory (default: 03_KET_QUA_KIEM_TRA)")
  .option("--allow-high-risk", "Allow high-risk indicators when approved by user spec")
  .action(async (options) => {
    try {
      console.log("==========================================================");
      console.log("   DETERMINISTIC VERIFICATION & RISK CLASSIFIER v2.0.1");
      console.log("==========================================================");

      const result = await verifyCode({
        targetDir: options.target,
        reportDir: options.report,
        allowHighRisk: !!options.allowHighRisk,
      });

      console.log(`Risk Level : [${result.riskLevel}]`);
      console.log(`Summary    : ${result.summary}`);

      if (result.warnings.length > 0) {
        console.log("\nWarnings:");
        for (const w of result.warnings) {
          console.log(` [WARN] ${w}`);
        }
      }

      if (result.errors.length > 0) {
        console.log("\nErrors:");
        for (const e of result.errors) {
          console.log(` [FAIL] ${e}`);
        }
      }

      console.log("==========================================================");
      process.exit(result.success ? 0 : 1);
    } catch (err: any) {
      console.error(`[ERROR] Verification execution failed: ${err.message}`);
      process.exit(1);
    }
  });

// Rollback Subcommand
const rollbackCmd = program.command("rollback").description("Atomic snapshot & rollback engine");

rollbackCmd
  .command("snapshot")
  .description("Create atomic snapshot of development source directory")
  .option("-m, --max-snapshots <number>", "Maximum retained snapshots", "10")
  .action(async (options) => {
    try {
      const res = await createSnapshot({
        maxSnapshots: parseInt(options.maxSnapshots, 10),
      });
      if (!res.created) {
        console.log(`[!] Skipped snapshot: ${res.reason}`);
      } else {
        console.log(`[OK] Created snapshot ${res.snapshotId} (${res.fileCount} files, ${res.totalBytes} bytes)`);
      }
      process.exit(0);
    } catch (err: any) {
      console.error(`[FAIL] Snapshot creation failed: ${err.message}`);
      process.exit(1);
    }
  });

rollbackCmd
  .command("restore", { isDefault: true })
  .description("Restore latest or specific snapshot using 2-phase atomic swap")
  .option("-s, --snapshot <id>", "Specific snapshot ID to restore")
  .option("-f, --force", "Force restore without confirmation", false)
  .action(async (options) => {
    try {
      const res = await restoreSnapshot({
        snapshotId: options.snapshot,
        force: options.force,
      });
      console.log(`[OK] Successfully restored snapshot ${res.snapshotId} (${res.fileCount} files)`);
      process.exit(0);
    } catch (err: any) {
      console.error(`[FAIL] Rollback failed: ${err.message}`);
      process.exit(1);
    }
  });

// Gate Subcommand
program
  .command("gate <action> [gate]")
  .description("Gate controller (status, validate, open, waive, skip, reject, event, archive-case, check-app)")
  .option("-e, --evidence <path>", "Evidence file path")
  .option("-a, --approved-by <name>", "Approver name", "coordinator")
  .option("-r, --reason <text>", "Reason for waive/skip/reject/archive")
  .option("-d, --details <text>", "Details for event logging")
  .option("-m, --mode <mode>", "Gate mode (PASS, PASS_WITH_LIMITATIONS, SKIPPED, NOT_APPLICABLE)", "PASS")
  .action(async (action, gate, options) => {
    try {
      const res = await runGateAction({
        action: action as any,
        gate,
        evidence: options.evidence,
        approvedBy: options.approvedBy,
        reason: options.reason,
        details: options.details,
        mode: options.mode,
      });
      console.log(JSON.stringify(res, null, 2));
      process.exit(0);
    } catch (err: any) {
      console.error(`[FAIL] Gate action '${action}' failed: ${err.message}`);
      process.exit(1);
    }
  });

// Context Subcommand
const contextCmd = program.command("context").description("Context engineering & packet assembly engine");

contextCmd
  .command("plan")
  .description("Plan context assembly based on task description")
  .requiredOption("-t, --task <text>", "Task description")
  .option("-s, --stage <stage>", "Lifecycle stage")
  .option("-p, --profile <profile>", "Target profile")
  .action(async (options) => {
    try {
      const plan = await planContext({
        task: options.task,
        stage: options.stage,
        profile: options.profile,
      });
      console.log(`[OK] Plan created: ${plan.plan_id} (${plan.budget.allocated_tokens} tokens)`);
      process.exit(0);
    } catch (err: any) {
      console.error(`[FAIL] Context plan failed: ${err.message}`);
      process.exit(1);
    }
  });

contextCmd
  .command("inspect")
  .description("Inspect a planned context")
  .requiredOption("-p, --plan-id <id>", "Plan ID")
  .action(async (options) => {
    try {
      const info = await inspectPlan({ planId: options.planId });
      console.log(JSON.stringify(info, null, 2));
      process.exit(0);
    } catch (err: any) {
      console.error(`[FAIL] Context inspect failed: ${err.message}`);
      process.exit(1);
    }
  });

contextCmd
  .command("pack")
  .description("Pack context into layers")
  .requiredOption("-p, --plan-id <id>", "Plan ID")
  .action(async (options) => {
    try {
      const packet = await packContext({ planId: options.planId });
      console.log(`[OK] Packet created: ${packet._metadata_tail.packet_id} (Status: ${packet.status})`);
      process.exit(0);
    } catch (err: any) {
      console.error(`[FAIL] Context pack failed: ${err.message}`);
      process.exit(1);
    }
  });

contextCmd
  .command("verify")
  .description("Verify a packed context packet")
  .requiredOption("-k, --pack-id <id>", "Packet ID")
  .action(async (options) => {
    try {
      const receipt = await verifyPacket({ packId: options.packId });
      console.log(`[OK] Receipt created: ${receipt.receipt_id} (Verdict: ${receipt.verdict})`);
      process.exit(receipt.verdict === "FAIL" ? 1 : 0);
    } catch (err: any) {
      console.error(`[FAIL] Context verify failed: ${err.message}`);
      process.exit(1);
    }
  });

// Interview Subcommand
program
  .command("interview <action>")
  .description("Adaptive Interview Engine (init, status, record-goal, record-question, record-answer, record-decision, record-assumption, record-unknown, record-conflict, resolve-conflict, record-scope-change, evaluate-sufficiency, validate)")
  .option("--case-id <id>", "Case ID")
  .option("-f, --force", "Force action override")
  .option("--supersede", "Allow superseding question / topic")
  .option("--allow-repeat", "Allow repeating identical question")
  .option("--spontaneous", "Record unsolicited spontaneous answer")
  .option("--goal-id <id>", "Goal ID")
  .option("--question-id <id>", "Question ID")
  .option("--answer-id <id>", "Answer ID")
  .option("--decision-id <id>", "Decision ID")
  .option("--assumption-id <id>", "Assumption ID")
  .option("--unknown-id <id>", "Unknown ID")
  .option("--conflict-id <id>", "Conflict ID")
  .option("--change-id <id>", "Change ID")
  .option("-d, --description <text>", "Description")
  .option("-t, --text <text>", "Text")
  .option("-r, --reason <text>", "Reason")
  .option("--justification <text>", "Justification")
  .option("--domain <domain>", "Domain")
  .option("--expected-info <info>", "Expected information")
  .option("--topic-key <key>", "Topic key")
  .option("--answer <text>", "Answer")
  .option("--interpreted <text>", "Interpreted answer")
  .option("--type <type>", "Answer type")
  .option("--source <source>", "Answer source")
  .option("--confidence <conf>", "Confidence")
  .option("--selected-option <opt>", "Selected option")
  .option("--options <list>", "Available options (comma separated)")
  .option("--owner <owner>", "Decision owner")
  .option("--approval-status <status>", "Approval status")
  .option("--approval <status>", "Approval")
  .option("--rationale <text>", "Rationale")
  .option("--impact <text>", "Impact")
  .option("--risk-level <risk>", "Risk level")
  .option("--verification-task <task>", "Verification task")
  .option("--conflicting-items <items>", "Conflicting items (comma separated)")
  .option("--explanation <text>", "Explanation")
  .option("--severity <sev>", "Severity")
  .option("--resolution-strategy <strat>", "Resolution strategy")
  .option("--previous-scope <scope>", "Previous scope")
  .option("--new-scope <scope>", "New scope")
  .option("--goal-ids <ids>", "Goal IDs (comma separated)")
  .option("--decision-ids <ids>", "Decision IDs (comma separated)")
  .option("--evidence-refs <refs>", "Evidence refs (comma separated)")
  .option("--related-requirements <reqs>", "Related requirements (comma separated)")
  .option("--downstream-deps <deps>", "Downstream deps (comma separated)")
  .option("--priority <prio>", "Priority")
  .option("--status <status>", "Status")
  .action(async (action, options) => {
    try {
      switch (action) {
        case "init": {
          const res = await initInterview({
            caseId: options.caseId,
            force: !!options.force,
          });
          console.log(`[OK] Interview state initialized: ${res.session.session_id} (Case: ${res.case_id})`);
          process.exit(0);
        }
        case "status": {
          const res = await getInterviewStatus();
          console.log(JSON.stringify(res.summary, null, 2));
          process.exit(0);
        }
        case "record-goal": {
          const res = await recordGoal({
            goalId: options.goalId,
            description: options.description,
            domain: options.domain,
            priority: options.priority,
            relatedRequirements: options.relatedRequirements,
          });
          console.log(`[OK] Recorded Goal: ${res.goal_id}`);
          process.exit(0);
        }
        case "record-question": {
          const res = await recordQuestion({
            questionId: options.questionId,
            text: options.text,
            reason: options.reason,
            domain: options.domain,
            topicKey: options.topicKey,
            goalIds: options.goalIds,
            decisionIds: options.decisionIds,
            expectedInfo: options.expectedInfo,
            priority: options.priority,
            force: !!options.force,
            supersede: !!options.supersede,
            allowRepeat: !!options.allowRepeat,
          });
          console.log(`[OK] Recorded Question: ${res.question_id}`);
          process.exit(0);
        }
        case "record-answer": {
          const res = await recordAnswer({
            answerId: options.answerId,
            questionId: options.questionId,
            answer: options.answer,
            interpreted: options.interpreted,
            type: options.type,
            source: options.source,
            confidence: options.confidence,
            conflictId: options.conflictId,
            spontaneous: !!options.spontaneous,
            domain: options.domain,
            topicKey: options.topicKey,
            goalIds: options.goalIds,
            decisionIds: options.decisionIds,
          });
          console.log(`[OK] Recorded Answer: ${res.answer_id}`);
          process.exit(0);
        }
        case "record-decision": {
          const res = await recordDecision({
            decisionId: options.decisionId,
            description: options.description,
            selectedOption: options.selectedOption,
            options: options.options,
            owner: options.owner,
            approvalStatus: options.approvalStatus,
            evidenceRefs: options.evidenceRefs,
            relatedRequirements: options.relatedRequirements,
          });
          console.log(`[OK] Recorded Decision: ${res.decision_id}`);
          process.exit(0);
        }
        case "record-assumption": {
          const res = await recordAssumption({
            assumptionId: options.assumptionId,
            description: options.description,
            rationale: options.rationale,
            impact: options.impact,
            riskLevel: options.riskLevel,
            approvalStatus: options.approvalStatus,
            verificationTask: options.verificationTask,
            downstreamDeps: options.downstreamDeps,
          });
          console.log(`[OK] Recorded Assumption: ${res.assumption_id}`);
          process.exit(0);
        }
        case "record-unknown": {
          const res = await recordUnknown({
            unknownId: options.unknownId,
            description: options.description,
            impact: options.impact,
            priority: options.priority,
            status: options.status,
            resolutionStrategy: options.resolutionStrategy,
            justification: options.justification,
            approval: options.approval,
            approvalStatus: options.approvalStatus,
          });
          console.log(`[OK] Recorded Unknown: ${res.unknown_id}`);
          process.exit(0);
        }
        case "record-conflict": {
          const res = await recordConflict({
            conflictId: options.conflictId,
            conflictingItems: options.conflictingItems,
            explanation: options.explanation,
            severity: options.severity,
            resolutionStrategy: options.resolutionStrategy,
          });
          console.log(`[OK] Recorded Conflict: ${res.conflict_id}`);
          process.exit(0);
        }
        case "resolve-conflict": {
          const res = await resolveConflict({
            conflictId: options.conflictId,
            resolutionStrategy: options.resolutionStrategy,
          });
          console.log(`[OK] Resolved Conflict: ${res.conflict_id}`);
          process.exit(0);
        }
        case "record-scope-change": {
          const res = await recordScopeChange({
            changeId: options.changeId,
            previousScope: options.previousScope,
            newScope: options.newScope,
            decisionIds: options.decisionIds,
            relatedRequirements: options.relatedRequirements,
          });
          console.log(`[OK] Recorded Scope Change: ${res.change_id}`);
          process.exit(0);
        }
        case "evaluate-sufficiency": {
          const res = await evaluateSufficiency();
          console.log(JSON.stringify(res, null, 2));
          if (res.verdict === "SUFFICIENT") process.exit(0);
          else if (res.verdict === "NEEDS_INPUT") process.exit(1);
          else process.exit(2);
        }
        case "validate": {
          const res = await validateInterview();
          if (res.valid) {
            console.log("[PASS] Interview state is structurally valid and referentially intact.");
            process.exit(0);
          } else {
            console.error(`[FAIL] Validation errors: ${res.errors.join("; ")}`);
            process.exit(1);
          }
        }
        default:
          console.error(`[ERROR] Unknown interview action: ${action}`);
          process.exit(1);
      }
    } catch (err: any) {
      console.error(`[ERROR] Interview action '${action}' failed: ${err.message}`);
      process.exit(1);
    }
  });

program
  .command("serve")
  .description("Start REA-kit-agy MCP Server (Stdio transport)")
  .option("-w, --workspace <path>", "Set target workspace directory")
  .action(async (options) => {
    try {
      if (options.workspace) {
        process.chdir(path.resolve(options.workspace));
      }
      await startMcpServer();
    } catch (err: any) {
      console.error(`[ERROR] MCP Server failed: ${err.message}`);
      process.exit(1);
    }
  });

program
  .command("adr")
  .description("Manage Architecture Decision Records (ADR) under MADR standard")
  .argument("[action]", "Action: list, show, validate, status, new, help", "list")
  .argument("[id]", "ADR ID or Title")
  .argument("[title]", "ADR Title (for 'new' action)")
  .option("-w, --workspace <path>", "Workspace directory containing docs/adrs")
  .action(async (action, id, title, options) => {
    try {
      const repoRoot = options.workspace ? path.resolve(options.workspace) : undefined;
      const res = await runAdrAction(action || "list", { id, title, repoRoot });
      if (res && res.text) {
        console.log(res.text);
      }
      if (action === "validate" && res && !res.valid) {
        process.exit(1);
      }
      process.exit(0);
    } catch (err: any) {
      console.error(`[ERROR] ADR action '${action}' failed: ${err.message}`);
      process.exit(1);
    }
  });

program.parse(process.argv);
