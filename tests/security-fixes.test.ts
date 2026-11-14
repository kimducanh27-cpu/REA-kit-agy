import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";
import { verifyCode, hasEsmSyntax } from "../src/core/verify-code.js";
import {
  archiveCurrentCaseAndReset,
  getNormalizedFileHash,
  runGateAction,
  validateGate,
  loadCaseState,
  saveCaseStateAtomic,
  TargetAppInfo,
  ActiveCaseState,
} from "../src/core/gate.js";
import {
  createSnapshot,
  restoreSnapshot,
  computeFileSha256,
  safeMove,
  isPathTraversal,
  rotateSnapshots,
} from "../src/core/rollback.js";
import {
  withFileLock,
  writeUtf8NoBomAtomic,
  MAX_LOCK_RETRIES,
  STALE_LOCK_TIMEOUT_MS,
} from "../src/core/state-lock.js";
import { initWorkspace } from "../src/core/init.js";
import { runHealthCheck } from "../src/core/health-check.js";

describe("Work Stream 2: Security Boundaries, WCAG Leaf Collision, Gate & Rollback Hardening", () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "rea-sec-test-"));
  });

  afterEach(async () => {
    try {
      await fs.rm(tmpDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup error
    }
  });

  describe("Task 1: Code Verification & WCAG Leaf Collision Hardening", () => {
    it("should prevent component token keys from overwriting semantic leaf keys (WCAG AA leaf collision fix)", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });

      // DTCG tokens where semantic background is white (#FFFFFF), text-main is near-black (#111111)
      // Component button background is black (#000000).
      // If leaf collision occurred, colorMap["background"] would become #000000, causing contrast failure with #111111.
      const tokens = {
        semantic: {
          color: {
            background: { $value: "#FFFFFF" },
            "text-main": { $value: "#111111" },
          },
        },
        component: {
          button: {
            primary: {
              background: { $value: "#000000" },
              color: { $value: "#FFFFFF" },
            },
          },
          card: {
            background: { $value: "#1A1A1A" },
          },
        },
      };

      await fs.writeFile(
        path.join(srcDir, "tokens.json"),
        JSON.stringify(tokens, null, 2),
        "utf8"
      );

      // Clean HTML entry file
      const htmlContent = `<!DOCTYPE html>
<html>
<head>
  <title>WCAG AA Test</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <h1>Hello World</h1>
</body>
</html>`;
      await fs.writeFile(path.join(srcDir, "index.html"), htmlContent, "utf8");

      const res = await verifyCode({ repoRoot: tmpDir, targetDir: "05_MA_NGUON_PHAT_TRIEN" });

      expect(res.success).toBe(true);
      expect(res.errors).toEqual([]);
      expect(res.details.pairsChecked).toBeGreaterThan(0);
    });

    it("should support DTCG 2025.10 Color objects with .hex in colorMap", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });

      const dtcg2025Tokens = {
        semantic: {
          color: {
            background: {
              $type: "color",
              $value: { colorSpace: "srgb", hex: "#FFFFFF" },
            },
            "text-main": {
              $type: "color",
              $value: { colorSpace: "srgb", hex: "#111111" },
            },
          },
        },
      };

      await fs.writeFile(
        path.join(srcDir, "tokens.json"),
        JSON.stringify(dtcg2025Tokens, null, 2),
        "utf8"
      );

      const htmlContent = `<!DOCTYPE html><html><head><title>DTCG 2025</title></head><body><p>Test</p></body></html>`;
      await fs.writeFile(path.join(srcDir, "index.html"), htmlContent, "utf8");

      const res = await verifyCode({ repoRoot: tmpDir, targetDir: "05_MA_NGUON_PHAT_TRIEN" });
      expect(res.success).toBe(true);
      expect(res.details.pairsChecked).toBeGreaterThan(0);
    });

    it("should support ESM syntax and <script type='module'> without vm.Script false-positives", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });

      // ESM JavaScript file
      const esmJs = `import { useState } from './preact.js';\nexport function App() { return 1; }`;
      await fs.writeFile(path.join(srcDir, "app.js"), esmJs, "utf8");

      // HTML with <script type="module">
      const htmlWithModule = `<!DOCTYPE html>
<html>
<head><title>ESM Test</title></head>
<body>
  <script type="module">
    import { App } from './app.js';
    console.log(App);
  </script>
</body>
</html>`;
      await fs.writeFile(path.join(srcDir, "index.html"), htmlWithModule, "utf8");

      expect(hasEsmSyntax(esmJs)).toBe(true);
      expect(hasEsmSyntax("const a = 1; module.exports = a;")).toBe(false);

      const res = await verifyCode({ repoRoot: tmpDir, targetDir: "05_MA_NGUON_PHAT_TRIEN" });
      expect(res.errors.filter((e) => e.includes("JavaScript syntax error"))).toEqual([]);
    });

    it("should harden Base64 secret scanner (skip images, skip .min.js, mask candidate sha256)", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });

      // 1. data:image/png should be skipped without false positive
      const htmlWithDataUri = `<!DOCTYPE html>
<html><head><title>Data URI</title></head>
<body>
  <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==">
</body>
</html>`;
      await fs.writeFile(path.join(srcDir, "index.html"), htmlWithDataUri, "utf8");

      // 2. .min.js should be skipped from secret scanning
      const minJs = `var a="sk-123456789012345678901234567890";`;
      await fs.writeFile(path.join(srcDir, "bundle.min.js"), minJs, "utf8");

      // 3. Real base64 secret in normal file should be detected with masked report
      const secretStr = "sk-ant-api03-abcdefghijklmnopqrstuvwxyz123456789";
      const b64Secret = Buffer.from(secretStr, "utf8").toString("base64");
      const configJs = `const token = "${b64Secret}";`;
      await fs.writeFile(path.join(srcDir, "config.js"), configJs, "utf8");

      const res = await verifyCode({ repoRoot: tmpDir, targetDir: "05_MA_NGUON_PHAT_TRIEN" });

      expect(res.success).toBe(false);

      // Verify no data:image leak error
      const imageErrors = res.errors.filter((e) => e.includes("index.html"));
      expect(imageErrors).toEqual([]);

      // Verify bundle.min.js was skipped
      const minErrors = res.errors.filter((e) => e.includes("bundle.min.js"));
      expect(minErrors).toEqual([]);

      // Verify masked report for config.js
      const configErrors = res.errors.filter((e) => e.includes("config.js"));
      expect(configErrors.length).toBeGreaterThan(0);
      expect(configErrors[0]).toContain("[REDACTED_SECRET_CANDIDATE: sha256=");
      // Ensure raw base64 string is NOT printed
      expect(configErrors[0]).not.toContain(b64Secret);
    });
  });

  describe("Task 2: Gate Hardening & Clean Case Reset", () => {
    it("should normalize line endings and BOM for code files in getNormalizedFileHash", async () => {
      const tsFile = path.join(tmpDir, "test.ts");
      const ktFile = path.join(tmpDir, "test.kt");

      // CRLF with UTF-8 BOM
      const content = "fun main() {\r\n    println(\"Hello\")\r\n}\r\n";
      const bomBuffer = Buffer.concat([Buffer.from([0xef, 0xbb, 0xbf]), Buffer.from(content, "utf8")]);
      await fs.writeFile(ktFile, bomBuffer);

      // LF without BOM
      const cleanContent = "fun main() {\n    println(\"Hello\")\n}\n";
      await fs.writeFile(tsFile, Buffer.from(cleanContent, "utf8"));

      const hashKt = await getNormalizedFileHash(ktFile);
      const hashTs = await getNormalizedFileHash(tsFile);

      // Should be identical hashes due to normalization
      expect(hashKt).toBe(hashTs);
    });

    it("should reset clean interview_state.json and append random suffix in case_id on archiveCurrentCaseAndReset", async () => {
      await initWorkspace({ dir: tmpDir });

      // Pollute interview_state.json with dummy active data
      const interviewPath = path.join(tmpDir, ".agents", "state", "interview_state.json");
      const dirtyState = {
        schema_version: 1,
        case_id: "CASE-INITIAL",
        session: {
          session_id: "INT-DIRTY",
          status: "IN_PROGRESS",
          current_stage: "STAGE_03_PRODUCT_DEFINITION",
        },
        goals: [{ goal_id: "GOAL-001", description: "Old goal" }],
        questions: [{ question_id: "Q-001", text: "Old question" }],
        answers: [{ question_id: "Q-001", answer: "Old answer" }],
        decisions: [{ decision_id: "D-001", decision: "Old decision" }],
      };
      await fs.writeFile(interviewPath, JSON.stringify(dirtyState, null, 2), "utf8");

      const activeCase = await loadCaseState(tmpDir);
      const targetApp: TargetAppInfo = {
        name: "new_app.apk",
        path: path.join(tmpDir, "01_THA_APP_VAO_DAY", "new_app.apk"),
        relativePath: "01_THA_APP_VAO_DAY/new_app.apk",
        sha256: "ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890",
        type: "FILE",
        length: 1024,
      };

      const newState = await archiveCurrentCaseAndReset(tmpDir, activeCase, targetApp, "New APK loaded");

      // Check random suffix in case_id: CASE-yyyyMMdd-HHmmss-xxxx (4 hex chars)
      expect(newState.case_id).toMatch(/^CASE-\d{8}-\d{6}-[0-9a-f]{4}$/);

      // Check archived case folder exists and preserved old interview_state.json
      const archivedInterview = path.join(
        tmpDir,
        ".agents",
        "state",
        "cases",
        "CASE-INITIAL",
        "interview_state.json"
      );
      expect(fsSync.existsSync(archivedInterview)).toBe(true);
      const archivedContent = JSON.parse(await fs.readFile(archivedInterview, "utf8"));
      expect(archivedContent.goals.length).toBe(1);

      // Check active interview_state.json was completely reset clean
      const freshInterviewRaw = await fs.readFile(interviewPath, "utf8");
      const freshInterview = JSON.parse(freshInterviewRaw);
      expect(freshInterview.case_id).toBe(newState.case_id);
      expect(freshInterview.session.status).toBe("NOT_STARTED");
      expect(freshInterview.goals).toEqual([]);
      expect(freshInterview.questions).toEqual([]);
      expect(freshInterview.answers).toEqual([]);
      expect(freshInterview.decisions).toEqual([]);
      expect(freshInterview.assumptions).toEqual([]);
    });

    it("should compute and verify all evidence hashes for Gate 02 (including APP_FLOW_SPEC.md)", async () => {
      await initWorkspace({ dir: tmpDir });

      // Clear Gate 01
      const appPath = path.join(tmpDir, "01_THA_APP_VAO_DAY", "sample.txt");
      await fs.writeFile(appPath, "sample baseline content", "utf8");
      await runGateAction({
        repoRoot: tmpDir,
        action: "open",
        gate: "gate_01_baseline_verified",
        evidence: "01_THA_APP_VAO_DAY/sample.txt",
        force: true,
      });

      // Prepare Gate 02 evidence
      const auditRel = "03_KET_QUA_KIEM_TRA/AUDIT_REPORT.md";
      const appFlowRel = "03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md";
      await fs.writeFile(path.join(tmpDir, auditRel), "# Audit Report\nPassed.", "utf8");
      await fs.writeFile(
        path.join(tmpDir, appFlowRel),
        "# App Flow Spec\nFlow anchor [EV: ANCHOR_01]\nDetails here.",
        "utf8"
      );

      // Open Gate 02
      await runGateAction({
        repoRoot: tmpDir,
        action: "open",
        gate: "gate_02_audit_passed",
        evidence: auditRel,
        force: true,
      });

      const caseState = await loadCaseState(tmpDir);
      const gate02 = caseState.gates.gate_02_audit_passed;
      expect(gate02.state).toBe("PASS");
      expect(gate02.evidence_hashes).toBeDefined();
      expect(gate02.evidence_hashes[auditRel]).toBeDefined();
      expect(gate02.evidence_hashes[appFlowRel]).toBeDefined();

      // Validate gate passes initially
      const val1 = await validateGate({ repoRoot: tmpDir });
      expect(val1.valid).toBe(true);

      // Tamper with APP_FLOW_SPEC.md
      await fs.writeFile(
        path.join(tmpDir, appFlowRel),
        "# App Flow Spec\nTampered without permission [EV: ANCHOR_01]",
        "utf8"
      );

      // Validate gate should detect evidence hash tampering!
      const val2 = await validateGate({ repoRoot: tmpDir });
      expect(val2.valid).toBe(false);
      expect(val2.errors.some((e) => e.includes(appFlowRel) && e.includes("SHA-256 mismatch"))).toBe(true);
    });
  });

  describe("Task 3: Rollback Hardening", () => {
    it("should strictly require manifest.json and reject restore if missing", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      const backupDir = path.join(tmpDir, "04_SAO_LUU_AN_TOAN");
      await fs.mkdir(srcDir, { recursive: true });
      await fs.mkdir(backupDir, { recursive: true });

      const snapDir = path.join(backupDir, "20261114_010000_000");
      await fs.mkdir(snapDir, { recursive: true });
      await fs.writeFile(path.join(snapDir, "file.txt"), "content", "utf8");

      // No manifest.json created in snapDir
      await expect(
        restoreSnapshot({ repoRoot: tmpDir, backupDir, buildDir: srcDir })
      ).rejects.toThrow(/Missing manifest\.json/);
    });

    it("should enforce two-way matching between staging files and manifest.files", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });
      await fs.writeFile(path.join(srcDir, "file1.txt"), "hello", "utf8");

      const snapRes = await createSnapshot({ repoRoot: tmpDir });
      expect(snapRes.created).toBe(true);

      // Plant an unmanifested extra file into the snapshot directory
      const extraFile = path.join(snapRes.snapshotDir!, "untracked.txt");
      await fs.writeFile(extraFile, "sneaky unauthorized file", "utf8");

      // Restore must fail due to two-way verification (extraneous file in staging)
      await expect(restoreSnapshot({ repoRoot: tmpDir })).rejects.toThrow(
        /Extraneous file in staging not listed in manifest\.json/
      );
    });

    it("should sort candidate snapshots globally across primary and fallback directories", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      const primaryBackup = path.join(tmpDir, "04_SAO_LUU_AN_TOAN");
      const fallbackBackup = path.join(srcDir, ".backup");

      await fs.mkdir(srcDir, { recursive: true });
      await fs.mkdir(primaryBackup, { recursive: true });
      await fs.mkdir(fallbackBackup, { recursive: true });

      // Older snapshot in primary backup
      const olderSnapId = "20261114_010000_000";
      const olderDir = path.join(primaryBackup, olderSnapId);
      await fs.mkdir(olderDir, { recursive: true });
      await fs.writeFile(path.join(olderDir, "app.js"), "// older v1", "utf8");
      const olderHash = await computeFileSha256(path.join(olderDir, "app.js"));
      await fs.writeFile(
        path.join(olderDir, "manifest.json"),
        JSON.stringify({
          timestamp: new Date().toISOString(),
          snapshot_id: olderSnapId,
          files: [{ path: "app.js", sha256: olderHash, bytes: 11 }],
        }),
        "utf8"
      );

      // Newer snapshot in fallback backup
      const newerSnapId = "20261114_090000_000";
      const newerDir = path.join(fallbackBackup, newerSnapId);
      await fs.mkdir(newerDir, { recursive: true });
      await fs.writeFile(path.join(newerDir, "app.js"), "// newer v2", "utf8");
      const newerHash = await computeFileSha256(path.join(newerDir, "app.js"));
      await fs.writeFile(
        path.join(newerDir, "manifest.json"),
        JSON.stringify({
          timestamp: new Date().toISOString(),
          snapshot_id: newerSnapId,
          files: [{ path: "app.js", sha256: newerHash, bytes: 11 }],
        }),
        "utf8"
      );

      // Restore without specifying snapshotId -> must pick the newest snapshot globally (newerSnapId)
      const res = await restoreSnapshot({
        repoRoot: tmpDir,
        backupDir: primaryBackup,
        buildDir: srcDir,
      });

      expect(res.restored).toBe(true);
      expect(res.snapshotId).toBe(newerSnapId);

      const restoredContent = await fs.readFile(path.join(srcDir, "app.js"), "utf8");
      expect(restoredContent).toBe("// newer v2");
    });

    it("should clamp maxSnapshots to at least 1 to prevent wiping all snapshots", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });
      await fs.writeFile(path.join(srcDir, "test.txt"), "sample", "utf8");

      // Call createSnapshot with maxSnapshots: 0
      const res = await createSnapshot({ repoRoot: tmpDir, maxSnapshots: 0 });
      expect(res.created).toBe(true);

      const backupDir = path.join(tmpDir, "04_SAO_LUU_AN_TOAN");
      const entries = await fs.readdir(backupDir);
      const dirs = entries.filter((e) => !e.startsWith("."));
      expect(dirs.length).toBe(1);
    });

    it("should prevent path traversal in manifest entries (reject .., /, C:\\)", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      const backupDir = path.join(tmpDir, "04_SAO_LUU_AN_TOAN");
      await fs.mkdir(srcDir, { recursive: true });
      await fs.mkdir(backupDir, { recursive: true });

      const snapId = "20261114_120000_000";
      const snapDir = path.join(backupDir, snapId);
      await fs.mkdir(snapDir, { recursive: true });
      await fs.writeFile(path.join(snapDir, "legit.txt"), "hello", "utf8");

      expect(isPathTraversal("../secret.txt")).toBe(true);
      expect(isPathTraversal("/etc/passwd")).toBe(true);
      expect(isPathTraversal("C:\\Windows\\System32")).toBe(true);
      expect(isPathTraversal("sub/../../traversal.txt")).toBe(true);
      expect(isPathTraversal("normal/file.txt")).toBe(false);

      // Write malicious manifest containing path traversal
      await fs.writeFile(
        path.join(snapDir, "manifest.json"),
        JSON.stringify({
          timestamp: new Date().toISOString(),
          snapshot_id: snapId,
          files: [{ path: "../escape.txt", sha256: "DUMMY", bytes: 10 }],
        }),
        "utf8"
      );

      await expect(
        restoreSnapshot({ repoRoot: tmpDir, backupDir, buildDir: srcDir })
      ).rejects.toThrow(/path traversal/i);
    });

    it("should strictly filter snapshots by regex and require manifest.json during rotation", async () => {
      const backupDir = path.join(tmpDir, "04_SAO_LUU_AN_TOAN");
      await fs.mkdir(backupDir, { recursive: true });

      // Non-matching directory name (e.g. custom-folder, temp_backup)
      const invalidDir = path.join(backupDir, "custom_backup_dir");
      await fs.mkdir(invalidDir, { recursive: true });
      await fs.writeFile(path.join(invalidDir, "manifest.json"), "{}", "utf8");

      // Matching timestamp name but missing manifest.json
      const noManifestDir = path.join(backupDir, "20261114_010000_001");
      await fs.mkdir(noManifestDir, { recursive: true });
      await fs.writeFile(path.join(noManifestDir, "app.js"), "code", "utf8");

      // Valid snapshots with matching timestamp and manifest.json
      for (const id of ["20261114_010000_002", "20261114_010000_003"]) {
        const d = path.join(backupDir, id);
        await fs.mkdir(d, { recursive: true });
        await fs.writeFile(path.join(d, "manifest.json"), "{}", "utf8");
      }

      // Rotate with maxSnapshots = 1 -> should keep newest valid (003), remove older valid (002),
      // and NOT touch invalidDir or noManifestDir
      await rotateSnapshots(backupDir, 1);

      expect(fsSync.existsSync(invalidDir)).toBe(true);
      expect(fsSync.existsSync(noManifestDir)).toBe(true);
      expect(fsSync.existsSync(path.join(backupDir, "20261114_010000_003"))).toBe(true);
      expect(fsSync.existsSync(path.join(backupDir, "20261114_010000_002"))).toBe(false);
    });

    it("should safely move files even when destination directory or file already exists (safeMove Windows EPERM resilience)", async () => {
      const srcFolder = path.join(tmpDir, "src_folder");
      const destFolder = path.join(tmpDir, "dest_folder");

      await fs.mkdir(srcFolder, { recursive: true });
      await fs.writeFile(path.join(srcFolder, "file.txt"), "from src", "utf8");

      await fs.mkdir(destFolder, { recursive: true });
      await fs.writeFile(path.join(destFolder, "old.txt"), "old content", "utf8");

      // Move directory over existing directory
      await safeMove(srcFolder, destFolder);

      expect(fsSync.existsSync(path.join(destFolder, "file.txt"))).toBe(true);
      expect(fsSync.existsSync(path.join(destFolder, "old.txt"))).toBe(false);
      expect(fsSync.existsSync(srcFolder)).toBe(false);
    });

    it("should handle safeMove when src and dest are identical without deleting target", async () => {
      const filePath = path.join(tmpDir, "same-file.txt");
      await fs.writeFile(filePath, "identical path content", "utf8");

      await safeMove(filePath, filePath);

      expect(fsSync.existsSync(filePath)).toBe(true);
      expect(await fs.readFile(filePath, "utf8")).toBe("identical path content");
    });
  });

  describe("Task 4: State Lock Compare-and-Delete & PID Liveness", () => {
    it("should write unique lockToken and perform compare-and-delete on release", async () => {
      const targetFile = path.join(tmpDir, "test-resource.json");
      const lockFile = `${targetFile}.lock`;

      let capturedToken = "";

      await withFileLock(targetFile, async () => {
        expect(fsSync.existsSync(lockFile)).toBe(true);
        const lockContent = await fs.readFile(lockFile, "utf8");
        const lines = lockContent.trim().split("\n");
        expect(lines.length).toBeGreaterThanOrEqual(3);

        capturedToken = lines[0].trim();
        // lockToken should be a valid UUID
        expect(capturedToken).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);

        // PID should be current process PID
        expect(lines[1].trim()).toBe(process.pid.toString());
      });

      // After normal execution, lock should be cleaned up
      expect(fsSync.existsSync(lockFile)).toBe(false);
    });

    it("should NOT delete lockfile if lockToken does not match (compare-and-delete protection)", async () => {
      const targetFile = path.join(tmpDir, "protected-resource.json");
      const lockFile = `${targetFile}.lock`;

      let foreignToken = "FOREIGN-TOKEN-12345";

      await withFileLock(targetFile, async () => {
        // Tamper with lock file to simulate another process acquiring lock with a different token
        await fs.writeFile(lockFile, `${foreignToken}\n${process.pid}\n${Date.now()}\n`, "utf8");
      });

      // Because token did not match, the lockfile must NOT have been unlinked!
      expect(fsSync.existsSync(lockFile)).toBe(true);
      const remainingContent = await fs.readFile(lockFile, "utf8");
      expect(remainingContent).toContain(foreignToken);

      // Clean up manually
      await fs.unlink(lockFile);
    });

    it("should clear stale lock when process PID is dead", async () => {
      const targetFile = path.join(tmpDir, "stale-resource.json");
      const lockFile = `${targetFile}.lock`;

      // Plant a stale lock with a non-existent dead PID (e.g. 9999999) and old timestamp
      const deadPid = 9999999;
      const oldTimestamp = Date.now() - 30_000;
      await fs.writeFile(
        lockFile,
        `DEAD-TOKEN\n${deadPid}\n${oldTimestamp}\n`,
        "utf8"
      );

      // withFileLock should detect that deadPid is not alive and clear the stale lock
      let executed = false;
      await withFileLock(targetFile, async () => {
        executed = true;
      });

      expect(executed).toBe(true);
      expect(fsSync.existsSync(lockFile)).toBe(false);
    });

    it("should clear stale lock when age > STALE_LOCK_TIMEOUT_MS even if process PID is alive (deadlock fix)", async () => {
      const targetFile = path.join(tmpDir, "stale-livepid-resource.json");
      const lockFile = `${targetFile}.lock`;

      // Plant a stale lock with the CURRENT process PID (alive!) but older than STALE_LOCK_TIMEOUT_MS
      const livePid = process.pid;
      const oldTimestamp = Date.now() - (STALE_LOCK_TIMEOUT_MS + 5_000);
      await fs.writeFile(
        lockFile,
        `OLD-TOKEN\n${livePid}\n${oldTimestamp}\n`,
        "utf8"
      );

      // Set old mtime on lockfile so stat.mtimeMs also registers as stale (>10s)
      const oldDate = new Date(Date.now() - (STALE_LOCK_TIMEOUT_MS + 5_000));
      await fs.utimes(lockFile, oldDate, oldDate);

      let executed = false;
      await withFileLock(targetFile, async () => {
        executed = true;
      });

      expect(executed).toBe(true);
      expect(fsSync.existsSync(lockFile)).toBe(false);
    });

    it("should configure 50 lock retries and 10s timeout budget", () => {
      expect(MAX_LOCK_RETRIES).toBe(50);
      expect(STALE_LOCK_TIMEOUT_MS).toBe(10_000);
    });

    it("should write files atomically without BOM using writeUtf8NoBomAtomic", async () => {
      const targetFile = path.join(tmpDir, "atomic-test.txt");
      await writeUtf8NoBomAtomic(targetFile, "Hello Windows World!");

      const buffer = await fs.readFile(targetFile);
      expect(buffer[0] !== 0xef || buffer[1] !== 0xbb || buffer[2] !== 0xbf).toBe(true);
      expect(buffer.toString("utf8")).toBe("Hello Windows World!");
    });

    it("should not confuse a numeric-prefix token with a dead PID when lockfile has 2 lines", async () => {
      const targetFile = path.join(tmpDir, "token-numeric-prefix.json");
      const lockFile = `${targetFile}.lock`;

      // Plant a 2-line lockfile where line 0 is a token starting with digits (e.g. 1234abcd-...)
      // and line 1 is our live PID. The lock is fresh (<10s).
      const tokenWithNumericPrefix = "1234abcd-fake-uuid";
      await fs.writeFile(
        lockFile,
        `${tokenWithNumericPrefix}\n${process.pid}\n`,
        "utf8"
      );

      // Release lock after 350ms
      setTimeout(async () => {
        try {
          await fs.unlink(lockFile);
        } catch {}
      }, 350);

      let acquired = false;
      await withFileLock(targetFile, async () => {
        acquired = true;
      });

      expect(acquired).toBe(true);
    });
  });

  describe("Task 5: Health Check & Workspace Init Hardening", () => {
    it("should match fingerprint with normalized CRLF hashing in runHealthCheck", async () => {
      await initWorkspace({ dir: tmpDir });

      const inputDir = path.join(tmpDir, "01_THA_APP_VAO_DAY");
      const targetFile = path.join(inputDir, "app-flow.md");

      // Write CRLF content
      const crlfContent = "# Flow\r\nStep 1\r\nStep 2\r\n";
      await fs.writeFile(targetFile, crlfContent, "utf8");

      // Compute normalized hash (LF normalized)
      const expectedSha = await getNormalizedFileHash(targetFile);

      // Update active_case.json with expectedSha
      const activeCasePath = path.join(tmpDir, ".agents", "state", "active_case.json");
      const activeCase = JSON.parse(await fs.readFile(activeCasePath, "utf8"));
      activeCase.workflow.target_fingerprint = expectedSha;
      await fs.writeFile(activeCasePath, JSON.stringify(activeCase, null, 2), "utf8");

      const res = await runHealthCheck({ repoRoot: tmpDir, checkExternalTools: false });
      expect(res.appInput).toBeDefined();
      expect(res.appInput?.matchedFingerprint).toBe(true);
      expect(res.appInput?.sha256).toBe(expectedSha);
    });

    it("should generate dynamic ISO timestamp in events.jsonl on initWorkspace", async () => {
      const beforeTime = Date.now() - 2000;
      await initWorkspace({ dir: tmpDir });
      const afterTime = Date.now() + 2000;

      const eventsPath = path.join(tmpDir, ".agents", "state", "events.jsonl");
      const content = await fs.readFile(eventsPath, "utf8");
      const firstLine = JSON.parse(content.trim().split("\n")[0]);

      expect(firstLine.timestamp).not.toBe("2026-11-14T08:00:00+07:00");
      const parsedTime = new Date(firstLine.timestamp).getTime();
      expect(parsedTime).toBeGreaterThanOrEqual(beforeTime);
      expect(parsedTime).toBeLessThanOrEqual(afterTime);
    });

    it("should compute appInput for target directory in 01_THA_APP_VAO_DAY without EISDIR in runHealthCheck", async () => {
      await initWorkspace({ dir: tmpDir });

      const inputDir = path.join(tmpDir, "01_THA_APP_VAO_DAY");
      const targetDir = path.join(inputDir, "sample-unpacked-app");
      await fs.mkdir(targetDir, { recursive: true });
      await fs.writeFile(path.join(targetDir, "index.html"), "<h1>App</h1>", "utf8");

      const res = await runHealthCheck({ repoRoot: tmpDir, checkExternalTools: false });
      expect(res.appInput).toBeDefined();
      expect(res.appInput?.name).toBe("sample-unpacked-app");
      expect(typeof res.appInput?.sha256).toBe("string");
      expect(res.appInput?.sha256.length).toBe(64);
    });
  });
});
