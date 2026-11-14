import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { initWorkspace, STANDARD_DIRS } from "../src/core/init.js";
import { runInterviewAction } from "../src/core/interview.js";

describe("Phase 4: Workspace Init, MCP Tools & Governance Tests", () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "rea-phase4-test-"));
  });

  afterEach(async () => {
    try {
      await fs.rm(tmpDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup error
    }
  });

  describe("Workspace Initialization (initWorkspace)", () => {
    it("should create 5 standard directories with .gitkeep inside each", async () => {
      const res = await initWorkspace({ dir: tmpDir });
      expect(res.root).toBe(path.resolve(tmpDir));

      for (const d of STANDARD_DIRS) {
        const fullPath = path.join(tmpDir, d);
        const stat = await fs.stat(fullPath);
        expect(stat.isDirectory()).toBe(true);

        const gitkeepPath = path.join(fullPath, ".gitkeep");
        const keepStat = await fs.stat(gitkeepPath);
        expect(keepStat.isFile()).toBe(true);
      }

      // Check cases directory
      const casesPath = path.join(tmpDir, ".agents", "state", "cases");
      const casesStat = await fs.stat(casesPath);
      expect(casesStat.isDirectory()).toBe(true);
      const casesGitkeep = path.join(casesPath, ".gitkeep");
      const casesKeepStat = await fs.stat(casesGitkeep);
      expect(casesKeepStat.isFile()).toBe(true);
    });

    it("should initialize active_case.json with valid schema and CASE-INITIAL", async () => {
      await initWorkspace({ dir: tmpDir });
      const activeCasePath = path.join(tmpDir, ".agents", "state", "active_case.json");
      const raw = await fs.readFile(activeCasePath, "utf8");

      // Verify NO BOM
      const buf = await fs.readFile(activeCasePath);
      expect(buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf).toBe(false);

      const parsed = JSON.parse(raw);
      expect(parsed.schema_version).toBe(2);
      expect(parsed.case_id).toBe("CASE-INITIAL");
      expect(parsed.current_phase).toBe("STAGE_00_BOOTSTRAP");
      expect(parsed.current_gate_status).toBe("GATE_00_READY");
      expect(parsed.gates.gate_01_baseline_verified.state).toBe("NOT_STARTED");
      expect(parsed.metrics.risk_level).toBe("UNASSESSED");
    });

    it("should initialize interview_state.json with NOT_STARTED status and empty arrays", async () => {
      await initWorkspace({ dir: tmpDir });
      const interviewPath = path.join(tmpDir, ".agents", "state", "interview_state.json");
      const raw = await fs.readFile(interviewPath, "utf8");

      // Verify NO BOM
      const buf = await fs.readFile(interviewPath);
      expect(buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf).toBe(false);

      const parsed = JSON.parse(raw);
      expect(parsed.schema_version).toBe(1);
      expect(parsed.case_id).toBe("CASE-INITIAL");
      expect(parsed.session.status).toBe("NOT_STARTED");
      expect(parsed.session.session_id).toBe("INT-SESSION-INITIAL");
      expect(parsed.goals).toEqual([]);
      expect(parsed.questions).toEqual([]);
      expect(parsed.answers).toEqual([]);
      expect(parsed.decisions).toEqual([]);
      expect(parsed.assumptions).toEqual([]);
      expect(parsed.conflicts).toEqual([]);
      expect(parsed.unknowns).toEqual([]);
      expect(parsed.scope_changes).toEqual([]);
      expect(parsed.sufficiency_evaluation.verdict).toBe("NEEDS_INPUT");
    });

    it("should initialize events.jsonl with exactly 1 line (EVT-0000, WORKSPACE_INIT)", async () => {
      await initWorkspace({ dir: tmpDir });
      const eventsPath = path.join(tmpDir, ".agents", "state", "events.jsonl");
      const raw = await fs.readFile(eventsPath, "utf8");

      // Verify NO BOM
      const buf = await fs.readFile(eventsPath);
      expect(buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf).toBe(false);

      const lines = raw.trim().split("\n");
      expect(lines.length).toBe(1);

      const evt = JSON.parse(lines[0]);
      expect(evt.event_id).toBe("EVT-0000");
      expect(evt.action).toBe("WORKSPACE_INIT");
      expect(evt.case_id).toBe("CASE-INITIAL");
      expect(evt.phase).toBe("STAGE_00_BOOTSTRAP");
    });

    it("should reject re-initialization if state files exist and force is not set", async () => {
      await initWorkspace({ dir: tmpDir });

      await expect(initWorkspace({ dir: tmpDir, force: false })).rejects.toThrow(
        /\[STATE_EXISTS\]/
      );
    });

    it("should allow overwriting state files when force: true is passed", async () => {
      await initWorkspace({ dir: tmpDir });

      // Mutate active_case.json
      const activeCasePath = path.join(tmpDir, ".agents", "state", "active_case.json");
      await fs.writeFile(activeCasePath, JSON.stringify({ mutated: true }));

      // Re-init with force
      const res = await initWorkspace({ dir: tmpDir, force: true });
      expect(res.root).toBe(path.resolve(tmpDir));

      const raw = await fs.readFile(activeCasePath, "utf8");
      const parsed = JSON.parse(raw);
      expect(parsed.case_id).toBe("CASE-INITIAL");
      expect(parsed.mutated).toBeUndefined();
    });
  });

  describe("runInterviewAction Gateway", () => {
    it("should initialize and record goals via runInterviewAction", async () => {
      await initWorkspace({ dir: tmpDir });

      const initRes = await runInterviewAction({
        action: "init",
        caseId: "CASE-INITIAL",
        force: true,
        repoRoot: tmpDir,
      });
      expect(initRes.session.status).toBe("IN_PROGRESS");

      const goalRes = await runInterviewAction({
        action: "record-goal",
        goalId: "GOAL-001",
        description: "Reconstruct APK with Jetpack Compose",
        priority: "P0_CRITICAL",
        repoRoot: tmpDir,
      });
      expect(goalRes.goal_id).toBe("GOAL-001");

      const statusRes = await runInterviewAction({
        action: "status",
        repoRoot: tmpDir,
      });
      expect(statusRes.summary.goalsTotal).toBe(1);
    });

    it("should reject invalid arguments gracefully", async () => {
      await initWorkspace({ dir: tmpDir });

      await expect(
        runInterviewAction({
          action: "record-goal",
          repoRoot: tmpDir,
        })
      ).rejects.toThrow(/\[INVALID_ARGUMENT\]/);
    });
  });

  describe("MCP Config & Wrapper Scripts Integrity", () => {
    it("should ensure .agents/mcp_config.json contains both rea and rea-kit servers", async () => {
      const configPath = path.resolve(__dirname, "..", ".agents", "mcp_config.json");
      const raw = await fs.readFile(configPath, "utf8");
      const config = JSON.parse(raw);

      expect(config.mcpServers.rea).toBeDefined();
      expect(config.mcpServers["rea-kit"]).toBeDefined();
      expect(config.mcpServers["rea-kit"].command).toBe("node");
      expect(config.mcpServers["rea-kit"].args).toEqual(["dist/mcp.js", "--workspace", "${workspaceFolder}"]);
    });

    it("should verify wrapper scripts contain node dist/cli.js priority", async () => {
      const repoRoot = path.resolve(__dirname, "..");
      const kiemTraBat = await fs.readFile(path.join(repoRoot, "KIEM_TRA.bat"), "utf8");
      const kiemTraSh = await fs.readFile(path.join(repoRoot, "kiem_tra.sh"), "utf8");
      const hoanTacBat = await fs.readFile(path.join(repoRoot, "HOAN_TAC.bat"), "utf8");
      const hoanTacSh = await fs.readFile(path.join(repoRoot, "hoan_tac.sh"), "utf8");

      expect(kiemTraBat).toContain("node");
      expect(kiemTraBat).toContain("verify");
      expect(kiemTraSh).toContain("dist/cli.js");
      expect(kiemTraSh).toContain("verify");

      expect(hoanTacBat).toContain("node");
      expect(hoanTacBat).toContain("rollback");
      expect(hoanTacSh).toContain("dist/cli.js");
      expect(hoanTacSh).toContain("rollback");
    });
  });
});
