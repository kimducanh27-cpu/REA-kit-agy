#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import path from "node:path";
import fs from "node:fs";
import { initWorkspace } from "./core/init.js";
import { runHealthCheck } from "./core/health-check.js";
import { compileTokens } from "./core/compile-tokens.js";
import { verifyCode } from "./core/verify-code.js";
import { createSnapshot, restoreSnapshot } from "./core/rollback.js";
import { runGateAction } from "./core/gate.js";
import {
  planContext,
  inspectPlan,
  packContext,
  verifyPacket,
} from "./core/context.js";
import { runInterviewAction } from "./core/interview.js";
import { runAdrAction } from "./core/adr.js";

function parseWorkspaceArg(): string | undefined {
  for (let i = 0; i < process.argv.length; i++) {
    const arg = process.argv[i];
    if (arg === "-w" || arg === "--workspace") {
      if (i + 1 < process.argv.length && !process.argv[i + 1].startsWith("-")) {
        return path.resolve(process.argv[i + 1]);
      }
    } else if (arg.startsWith("--workspace=")) {
      return path.resolve(arg.slice("--workspace=".length));
    } else if (arg.startsWith("-w=")) {
      return path.resolve(arg.slice("-w=".length));
    }
  }
  return undefined;
}

const defaultWorkspaceRoot = parseWorkspaceArg();

const server = new Server(
  {
    name: "rea-kit-agy",
    version: "2.0.2",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

const interviewInputSchema = {
  type: "object" as const,
  properties: {
    action: {
      type: "string",
      enum: [
        "init",
        "status",
        "record-goal",
        "record-question",
        "record-answer",
        "record-decision",
        "record-assumption",
        "record-unknown",
        "record-conflict",
        "resolve-conflict",
        "record-scope-change",
        "evaluate-sufficiency",
        "validate",
      ],
      description: "Interview action to execute",
    },
    caseId: { type: "string", description: "Case ID" },
    goalId: { type: "string", description: "Goal ID" },
    questionId: { type: "string", description: "Question ID" },
    answerId: { type: "string", description: "Answer ID" },
    decisionId: { type: "string", description: "Decision ID" },
    assumptionId: { type: "string", description: "Assumption ID" },
    unknownId: { type: "string", description: "Unknown ID" },
    conflictId: { type: "string", description: "Conflict ID" },
    changeId: { type: "string", description: "Change ID" },
    description: { type: "string", description: "Description text" },
    text: { type: "string", description: "Question or content text" },
    reason: { type: "string", description: "Reason or rationale" },
    justification: { type: "string", description: "Justification" },
    domain: { type: "string", description: "Domain classification" },
    expectedInfo: { type: "string", description: "Expected information" },
    topicKey: { type: "string", description: "Topic key for deduplication" },
    answer: { type: "string", description: "Raw answer text" },
    interpreted: { type: "string", description: "Interpreted answer" },
    type: { type: "string", description: "Answer type" },
    source: { type: "string", description: "Answer source" },
    confidence: { type: "string", description: "Confidence level" },
    selectedOption: { type: "string", description: "Selected option" },
    options: { type: "string", description: "Options (comma-separated or JSON array)" },
    owner: { type: "string", description: "Decision owner" },
    approvalStatus: { type: "string", description: "Approval status" },
    approval: { type: "string", description: "Approval" },
    rationale: { type: "string", description: "Rationale" },
    impact: { type: "string", description: "Impact assessment" },
    riskLevel: { type: "string", description: "Risk level" },
    verificationTask: { type: "string", description: "Verification task" },
    conflictingItems: { type: "string", description: "Conflicting item IDs" },
    explanation: { type: "string", description: "Conflict explanation" },
    severity: { type: "string", description: "Conflict severity" },
    resolutionStrategy: { type: "string", description: "Resolution strategy" },
    previousScope: { type: "string", description: "Previous scope description" },
    newScope: { type: "string", description: "New scope description" },
    goalIds: { type: "string", description: "Related goal IDs (comma-separated)" },
    decisionIds: { type: "string", description: "Related decision IDs (comma-separated)" },
    evidenceRefs: { type: "string", description: "Evidence references (comma-separated)" },
    relatedRequirements: { type: "string", description: "Related requirements (comma-separated)" },
    downstreamDeps: { type: "string", description: "Downstream dependencies (comma-separated)" },
    priority: { type: "string", description: "Priority level" },
    status: { type: "string", description: "Status value" },
    force: { type: "boolean", description: "Force overwrite or action override" },
    supersede: { type: "boolean", description: "Allow superseding question / topic" },
    allowRepeat: { type: "boolean", description: "Allow repeating identical question" },
    spontaneous: { type: "boolean", description: "Record unsolicited spontaneous answer" },
    repoRoot: { type: "string", description: "Repository root directory (optional)" },
  },
  required: ["action"],
};

const adrInputSchema = {
  type: "object" as const,
  properties: {
    action: {
      type: "string",
      enum: ["list", "show", "validate", "status", "new", "transition", "help"],
      description: "ADR action to execute",
    },
    id: { type: "string", description: "ADR ID or title parameter" },
    title: { type: "string", description: "ADR title (for new action)" },
    status: { type: "string", description: "Target status (for transition action)" },
    targetStatus: { type: "string", description: "Alias for status in transition action" },
    supersededBy: { type: "string", description: "Superseding ADR ID" },
    reason: { type: "string", description: "Transition reason" },
    repoRoot: { type: "string", description: "Repository root directory (optional)" },
  },
  required: ["action"],
};

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "kit_init",
        description: "Initialize workspace with 5 standard directories, state machines, and event log",
        inputSchema: {
          type: "object",
          properties: {
            dir: {
              type: "string",
              description: "Target workspace directory (default: workspace root)",
            },
            force: {
              type: "boolean",
              description: "Force re-initialization and overwrite existing state",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
        },
      },
      {
        name: "init_workspace",
        description: "Alias for kit_init - Initialize workspace with 5 standard directories, state machines, and event log",
        inputSchema: {
          type: "object",
          properties: {
            dir: {
              type: "string",
              description: "Target workspace directory (default: workspace root)",
            },
            force: {
              type: "boolean",
              description: "Force re-initialization and overwrite existing state",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
        },
      },
      {
        name: "kit_health_check",
        description: "Run comprehensive REA-kit-agy workspace & environment health check",
        inputSchema: {
          type: "object",
          properties: {
            checkExternalTools: {
              type: "boolean",
              description: "Whether to probe external CLI tools (java, jadx, apktool, etc.)",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
        },
      },
      {
        name: "kit_compile_tokens",
        description: "Compile W3C DTCG design tokens to Web CSS, Compose Kotlin, and Android XML",
        inputSchema: {
          type: "object",
          properties: {
            tokensFile: {
              type: "string",
              description: "Path to tokens.json (relative to workspace root)",
            },
            outputDir: {
              type: "string",
              description: "Output directory for compiled tokens",
            },
            designDoc: {
              type: "string",
              description: "Path to design.md to update preview code fences",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
        },
      },
      {
        name: "kit_verify_code",
        description: "Run deterministic verification & automated risk classifier on source code",
        inputSchema: {
          type: "object",
          properties: {
            targetDir: {
              type: "string",
              description: "Directory containing source code (default: 05_MA_NGUON_PHAT_TRIEN)",
            },
            reportDir: {
              type: "string",
              description: "Directory for reports (default: 03_KET_QUA_KIEM_TRA)",
            },
            allowHighRisk: {
              type: "boolean",
              description: "Allow approved high-risk indicators without failing gate",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
        },
      },
      {
        name: "kit_rollback",
        description: "Atomic snapshot & rollback engine (create snapshot or restore)",
        inputSchema: {
          type: "object",
          properties: {
            action: {
              type: "string",
              enum: ["restore", "snapshot"],
              description: "Rollback action: restore or snapshot (default: restore)",
            },
            maxSnapshots: {
              type: "number",
              description: "Maximum number of snapshots to retain (for snapshot)",
            },
            snapshotId: {
              type: "string",
              description: "Specific snapshot ID to restore (for restore)",
            },
            force: {
              type: "boolean",
              description: "Force restore without prompt",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
        },
      },
      {
        name: "kit_gate",
        description: "Control quality gates and workflow state transitions",
        inputSchema: {
          type: "object",
          properties: {
            action: {
              type: "string",
              enum: [
                "status",
                "validate",
                "open",
                "waive",
                "skip",
                "reject",
                "event",
                "archive-case",
                "check-app",
              ],
              description: "Gate action to execute",
            },
            gate: {
              type: "string",
              description: "Gate name or alias (e.g. gate_01_baseline_verified, 1)",
            },
            evidence: {
              type: "string",
              description: "Path to evidence file",
            },
            approvedBy: {
              type: "string",
              description: "Name of approver",
            },
            reason: {
              type: "string",
              description: "Reason for waive, skip, reject, or archive",
            },
            details: {
              type: "string",
              description: "Details for custom event logging",
            },
            mode: {
              type: "string",
              enum: ["PASS", "PASS_WITH_LIMITATIONS", "SKIPPED", "NOT_APPLICABLE"],
              description: "Gate completion mode",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
          required: ["action"],
        },
      },
      {
        name: "kit_context_plan",
        description: "Plan context documents and budget for an agent task",
        inputSchema: {
          type: "object",
          properties: {
            task: {
              type: "string",
              description: "Task description",
            },
            stage: {
              type: "string",
              description: "Optional workflow stage",
            },
            profile: {
              type: "string",
              description: "Optional target profile",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
          required: ["task"],
        },
      },
      {
        name: "kit_context_inspect",
        description: "Inspect a generated context plan and breakdown layers",
        inputSchema: {
          type: "object",
          properties: {
            planId: {
              type: "string",
              description: "Plan ID to inspect",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
          required: ["planId"],
        },
      },
      {
        name: "kit_context_pack",
        description: "Pack context into L0-L5 layers with prefix cache alignment",
        inputSchema: {
          type: "object",
          properties: {
            planId: {
              type: "string",
              description: "Plan ID to pack",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
          required: ["planId"],
        },
      },
      {
        name: "kit_context_verify",
        description: "Verify context packet compliance and issue receipt",
        inputSchema: {
          type: "object",
          properties: {
            packId: {
              type: "string",
              description: "Packet ID to verify",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
          required: ["packId"],
        },
      },
      {
        name: "kit_interview",
        description: "Adaptive Interview Engine for Requirements Elicitation & Domain Intelligence",
        inputSchema: interviewInputSchema,
      },
      {
        name: "kit_adr",
        description: "Architecture Decision Record (ADR) manager complying with MADR standard",
        inputSchema: adrInputSchema,
      },
      // Backwards compatibility tools
      {
        name: "health_check",
        description: "Alias for kit_health_check",
        inputSchema: {
          type: "object",
          properties: {
            checkExternalTools: {
              type: "boolean",
              description: "Whether to probe external CLI tools",
            },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
        },
      },
      {
        name: "compile_tokens",
        description: "Alias for kit_compile_tokens",
        inputSchema: {
          type: "object",
          properties: {
            tokensFile: { type: "string" },
            outputDir: { type: "string" },
            designDoc: { type: "string" },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
        },
      },
      {
        name: "verify_code",
        description: "Alias for kit_verify_code",
        inputSchema: {
          type: "object",
          properties: {
            targetDir: { type: "string" },
            reportDir: { type: "string" },
            allowHighRisk: { type: "boolean" },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
        },
      },
      {
        name: "rollback_snapshot",
        description: "Create an atomic snapshot of the development source directory",
        inputSchema: {
          type: "object",
          properties: {
            maxSnapshots: { type: "number" },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
        },
      },
      {
        name: "rollback_restore",
        description: "Restore from latest or specific snapshot using 2-phase atomic swap",
        inputSchema: {
          type: "object",
          properties: {
            snapshotId: { type: "string" },
            force: { type: "boolean" },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
        },
      },
      {
        name: "gate_action",
        description: "Alias for kit_gate",
        inputSchema: {
          type: "object",
          properties: {
            action: { type: "string" },
            gate: { type: "string" },
            evidence: { type: "string" },
            approvedBy: { type: "string" },
            reason: { type: "string" },
            details: { type: "string" },
            mode: { type: "string" },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
          required: ["action"],
        },
      },
      {
        name: "context_plan",
        description: "Alias for kit_context_plan",
        inputSchema: {
          type: "object",
          properties: {
            task: { type: "string" },
            stage: { type: "string" },
            profile: { type: "string" },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
          required: ["task"],
        },
      },
      {
        name: "context_inspect",
        description: "Alias for kit_context_inspect - Inspect a generated context plan",
        inputSchema: {
          type: "object",
          properties: {
            planId: { type: "string" },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
          required: ["planId"],
        },
      },
      {
        name: "context_pack",
        description: "Pack context into L0-L5 layers with prefix cache alignment",
        inputSchema: {
          type: "object",
          properties: {
            planId: { type: "string" },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
          required: ["planId"],
        },
      },
      {
        name: "context_verify",
        description: "Verify context packet compliance and issue receipt",
        inputSchema: {
          type: "object",
          properties: {
            packId: { type: "string" },
            repoRoot: {
              type: "string",
              description: "Repository root directory (optional)",
            },
          },
          required: ["packId"],
        },
      },
      {
        name: "interview_action",
        description: "Alias for kit_interview",
        inputSchema: interviewInputSchema,
      },
      {
        name: "adr_action",
        description: "Alias for kit_adr - Architecture Decision Record (ADR) manager",
        inputSchema: adrInputSchema,
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "kit_init":
      case "init_workspace": {
        const result = await initWorkspace({
          dir: (args as any)?.dir || (args as any)?.repoRoot || defaultWorkspaceRoot,
          force: (args as any)?.force,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "kit_health_check":
      case "health_check": {
        const result = await runHealthCheck({
          checkExternalTools: (args as any)?.checkExternalTools ?? true,
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "kit_compile_tokens":
      case "compile_tokens": {
        const result = await compileTokens({
          tokensFile: (args as any)?.tokensFile,
          outputDir: (args as any)?.outputDir,
          designDoc: (args as any)?.designDoc,
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "kit_verify_code":
      case "verify_code": {
        const result = await verifyCode({
          targetDir: (args as any)?.targetDir,
          reportDir: (args as any)?.reportDir,
          allowHighRisk: (args as any)?.allowHighRisk,
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "kit_rollback": {
        const action = (args as any)?.action || "restore";
        if (action === "snapshot") {
          const result = await createSnapshot({
            maxSnapshots: (args as any)?.maxSnapshots,
            repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
          });
          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(result, null, 2),
              },
            ],
          };
        } else {
          const result = await restoreSnapshot({
            snapshotId: (args as any)?.snapshotId,
            force: (args as any)?.force,
            repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
          });
          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(result, null, 2),
              },
            ],
          };
        }
      }

      case "rollback_snapshot": {
        const result = await createSnapshot({
          maxSnapshots: (args as any)?.maxSnapshots,
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "rollback_restore": {
        const result = await restoreSnapshot({
          snapshotId: (args as any)?.snapshotId,
          force: (args as any)?.force,
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "kit_gate":
      case "gate_action": {
        const result = await runGateAction({
          ...(args as any),
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "kit_context_plan":
      case "context_plan": {
        const result = await planContext({
          ...(args as any),
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "kit_context_inspect":
      case "context_inspect": {
        const result = await inspectPlan({
          ...(args as any),
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "kit_context_pack":
      case "context_pack": {
        const result = await packContext({
          ...(args as any),
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "kit_context_verify":
      case "context_verify": {
        const result = await verifyPacket({
          ...(args as any),
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "kit_interview":
      case "interview_action": {
        const result = await runInterviewAction({
          ...(args as any),
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "kit_adr":
      case "adr_action": {
        const action = (args as any)?.action || "list";
        const result = await runAdrAction(action, {
          ...(args as any),
          repoRoot: (args as any)?.repoRoot || defaultWorkspaceRoot,
        });
        return {
          content: [
            {
              type: "text",
              text: typeof result === "string" ? result : JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool name: ${name}`);
    }
  } catch (err: any) {
    return {
      isError: true,
      content: [
        {
          type: "text",
          text: `Error executing ${name}: ${err.message}`,
        },
      ],
    };
  }
});

export async function startMcpServer() {
  console.log = (...args: any[]) => console.error(...args);
  console.info = (...args: any[]) => console.error(...args);
  console.debug = (...args: any[]) => console.error(...args);

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

function isEntrypoint(): boolean {
  if (!process.argv[1]) return false;
  try {
    const realScript = fs.realpathSync(process.argv[1]);
    const normalized = path.normalize(realScript).toLowerCase();
    const base = path.basename(normalized);
    return base === "mcp.js" || base === "mcp.ts" || base === "rea-kit-mcp" || base.startsWith("mcp.");
  } catch {
    const normalized = path.normalize(process.argv[1]).toLowerCase();
    const base = path.basename(normalized);
    return base === "mcp.js" || base === "mcp.ts" || base === "rea-kit-mcp" || base.startsWith("mcp.");
  }
}

if (isEntrypoint()) {
  startMcpServer().catch((err) => {
    console.error("Failed to start MCP server:", err);
    process.exit(1);
  });
}
