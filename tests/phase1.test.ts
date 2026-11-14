import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";

import {
  findRepoRoot,
  getWorkspacePaths,
} from "../src/core/workspace.js";
import {
  withFileLock,
  writeUtf8NoBomAtomic,
  appendEventAtomic,
} from "../src/core/state-lock.js";
import {
  compileTokens,
  resolveTokenRef,
  toComposeColorHex,
  toXmlColorHex,
  toAndroidDp,
} from "../src/core/compile-tokens.js";
import {
  verifyCode,
  getShannonEntropy,
  getWcagContrastRatio,
  removeCommentsAndStrings,
  removeCommentsOnly,
} from "../src/core/verify-code.js";
import { runHealthCheck } from "../src/core/health-check.js";

describe("Phase 1 Core Infrastructure Tests", () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "rea-phase1-test-"));
  });

  afterEach(async () => {
    try {
      await fs.rm(tmpDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup error
    }
  });

  // =========================================================================
  // 1. Workspace Tests
  // =========================================================================
  describe("workspace", () => {
    it("should find repo root using docs/WORKFLOW_LIFECYCLE.md", async () => {
      const subDir = path.join(tmpDir, "sub", "deep", "dir");
      await fs.mkdir(subDir, { recursive: true });
      await fs.mkdir(path.join(tmpDir, "docs"), { recursive: true });
      await fs.writeFile(
        path.join(tmpDir, "docs", "WORKFLOW_LIFECYCLE.md"),
        "# Lifecycle"
      );

      const found = findRepoRoot(subDir);
      expect(found).toBe(tmpDir);
    });

    it("should resolve standard workspace paths", () => {
      const paths = getWorkspacePaths(tmpDir);
      expect(paths.root).toBe(tmpDir);
      expect(paths.inbox).toBe(path.join(tmpDir, "01_THA_APP_VAO_DAY"));
      expect(paths.spec).toBe(path.join(tmpDir, "02_YEU_CAU_CUA_TOI"));
      expect(paths.report).toBe(path.join(tmpDir, "03_KET_QUA_KIEM_TRA"));
      expect(paths.backup).toBe(path.join(tmpDir, "04_SAO_LUU_AN_TOAN"));
      expect(paths.src).toBe(path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN"));
      expect(paths.state).toBe(path.join(tmpDir, ".agents", "state"));
    });
  });

  // =========================================================================
  // 2. State Lock Tests
  // =========================================================================
  describe("state-lock", () => {
    it("should write UTF-8 atomic files with no BOM", async () => {
      const targetFile = path.join(tmpDir, "test-file.txt");
      // Provide content with a BOM character
      const contentWithBom = "\uFEFFHello World UTF-8";
      await writeUtf8NoBomAtomic(targetFile, contentWithBom);

      const buffer = await fs.readFile(targetFile);
      // UTF-8 BOM is 0xEF, 0xBB, 0xBF
      const hasBom =
        buffer.length >= 3 &&
        buffer[0] === 0xef &&
        buffer[1] === 0xbb &&
        buffer[2] === 0xbf;
      expect(hasBom).toBe(false);
      expect(buffer.toString("utf8")).toBe("Hello World UTF-8");
    });

    it("should enforce mutual exclusion using withFileLock", async () => {
      const targetFile = path.join(tmpDir, "counter.txt");
      let counter = 0;

      // Launch 5 concurrent operations
      const tasks = Array.from({ length: 5 }, async () => {
        await withFileLock(targetFile, async () => {
          const current = counter;
          await new Promise((r) => setTimeout(r, 20));
          counter = current + 1;
        });
      });

      await Promise.all(tasks);
      expect(counter).toBe(5);
    });

    it("should recover and acquire lock when a stale lock (>10s) exists", async () => {
      const targetFile = path.join(tmpDir, "stale-test.txt");
      const lockPath = `${targetFile}.lock`;

      // Create a stale lock file with mtime 15 seconds ago
      await fs.writeFile(lockPath, "99999\n1000\n", "utf8");
      const past = new Date(Date.now() - 15000);
      await fs.utimes(lockPath, past, past);

      let executed = false;
      await withFileLock(targetFile, async () => {
        executed = true;
      });

      expect(executed).toBe(true);
    });

    it("should append event line to events.jsonl atomically", async () => {
      await appendEventAtomic(tmpDir, {
        event_type: "PHASE1_TEST",
        message: "Testing atomic append",
      });
      await appendEventAtomic(tmpDir, {
        event_type: "PHASE1_TEST_2",
        message: "Second event",
      });

      const eventsFile = path.join(tmpDir, ".agents", "state", "events.jsonl");
      const content = await fs.readFile(eventsFile, "utf8");
      const lines = content.trim().split("\n");
      expect(lines.length).toBe(2);

      const parsed1 = JSON.parse(lines[0]);
      expect(parsed1.event_type).toBe("PHASE1_TEST");
      expect(parsed1.timestamp).toBeDefined();

      const parsed2 = JSON.parse(lines[1]);
      expect(parsed2.event_type).toBe("PHASE1_TEST_2");
    });
  });

  // =========================================================================
  // 3. Compile Tokens Tests
  // =========================================================================
  describe("compile-tokens", () => {
    it("should resolve token aliases and helpers correctly", () => {
      const tokensObj = {
        global: {
          color: {
            blue: {
              "600": { $value: "#2563eb" },
            },
          },
        },
        semantic: {
          color: {
            primary: { $value: "{global.color.blue.600}" },
            brand: { $value: "{semantic.color.primary}" },
          },
        },
      };

      const resolved = resolveTokenRef("{semantic.color.brand}", tokensObj);
      expect(resolved).toBe("#2563eb");

      expect(toComposeColorHex("#2563eb")).toBe("0xFF2563EB");
      expect(toComposeColorHex("#FFF")).toBe("0xFFFFFFFF");
      expect(toXmlColorHex("#2563eb")).toBe("#2563EB");
      expect(toAndroidDp("16px")).toBe("16dp");
      expect(toAndroidDp("8")).toBe("8dp");
    });

    it("should compile tokens to css, kotlin, xml and update design.md", async () => {
      const specDir = path.join(tmpDir, "02_YEU_CAU_CUA_TOI");
      await fs.mkdir(specDir, { recursive: true });

      const tokensData = {
        global: {
          color: {
            brand: { $value: "#1d4ed8" },
          },
          dimension: {
            "radius-sm": { $value: "4px" },
            "radius-md": { $value: "8px" },
            "radius-lg": { $value: "16px" },
            "target-min": { $value: "48px" },
          },
        },
        semantic: {
          color: {
            primary: { $value: "{global.color.brand}" },
            background: { $value: "#ffffff" },
            "text-main": { $value: "#111827" },
          },
        },
      };

      const tokensFile = path.join(specDir, "tokens.json");
      await fs.writeFile(tokensFile, JSON.stringify(tokensData, null, 2), "utf8");

      const designDoc = path.join(specDir, "design.md");
      const designContent = [
        "# Design Specifications",
        "#### a) Web CSS Tokens (Route A)",
        "```css",
        ":root { old-css: true; }",
        "```",
        "```kotlin",
        "// Jetpack Compose Color Tokens",
        "val OldColor = Color(0)",
        "```",
        "```xml",
        "<!-- Android XML Color Tokens -->",
        "<resources></resources>",
        "```",
      ].join("\n");
      await fs.writeFile(designDoc, designContent, "utf8");

      // Setup sync target in 05_MA_NGUON_PHAT_TRIEN
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      const cssDir = path.join(srcDir, "css");
      const themeDir = path.join(srcDir, "app", "theme");
      await fs.mkdir(cssDir, { recursive: true });
      await fs.mkdir(themeDir, { recursive: true });

      const result = await compileTokens({
        repoRoot: tmpDir,
        tokensFile,
        outputDir: specDir,
        designDoc,
      });

      expect(result.success).toBe(true);
      expect(result.colors.primary).toBe("#1d4ed8");

      // Verify generated files
      const cssOut = path.join(specDir, "tokens.css");
      const colorKtOut = path.join(specDir, "Color.kt");
      const typeKtOut = path.join(specDir, "Type.kt");
      const shapeKtOut = path.join(specDir, "Shape.kt");
      const colorsXmlOut = path.join(specDir, "colors.xml");
      const dimensXmlOut = path.join(specDir, "dimens.xml");

      const cssContent = await fs.readFile(cssOut, "utf8");
      expect(cssContent).toContain("--color-primary: #1d4ed8;");
      expect(cssContent).toContain("--radius-sm: 4px;");

      const colorKtContent = await fs.readFile(colorKtOut, "utf8");
      expect(colorKtContent).toContain("val Primary = Color(0xFF1D4ED8)");

      const colorsXmlContent = await fs.readFile(colorsXmlOut, "utf8");
      expect(colorsXmlContent).toContain('<color name="color_primary">#1D4ED8</color>');

      // Verify synced files
      const syncedCss = path.join(cssDir, "tokens.css");
      const syncedColorKt = path.join(themeDir, "Color.kt");
      expect(await fs.readFile(syncedCss, "utf8")).toBe(cssContent);
      expect(await fs.readFile(syncedColorKt, "utf8")).toBe(colorKtContent);

      // Verify design.md update
      const updatedDesign = await fs.readFile(designDoc, "utf8");
      expect(updatedDesign).toContain("--color-primary: #1d4ed8;");
      expect(updatedDesign).toContain("val PrimaryColor = Color(0xFF1D4ED8)");
    });
  });

  // =========================================================================
  // 4. Verify Code Tests
  // =========================================================================
  describe("verify-code", () => {
    it("should compute Shannon entropy and WCAG contrast correctly", () => {
      // Repetitive text has low entropy
      const low = getShannonEntropy("AAAAAAAAAA");
      expect(low).toBe(0);

      // High randomness string has high entropy
      const high = getShannonEntropy("8f7aB1$zQ#p9mK2vX!");
      expect(high).toBeGreaterThan(3.5);

      // Black on White contrast is 21:1
      const blackWhite = getWcagContrastRatio("#000000", "#FFFFFF");
      expect(blackWhite).toBe(21);

      // Gray on White
      const grayWhite = getWcagContrastRatio("#888888", "#FFFFFF");
      expect(grayWhite).toBeLessThan(4.5);
    });

    it("should pass clean Route A Web application", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      const reportDir = path.join(tmpDir, "03_KET_QUA_KIEM_TRA");
      await fs.mkdir(srcDir, { recursive: true });
      await fs.mkdir(reportDir, { recursive: true });

      await fs.writeFile(
        path.join(srcDir, "index.html"),
        "<!DOCTYPE html><html><head><title>Test</title></head><body>Hello</body></html>",
        "utf8"
      );
      await fs.writeFile(
        path.join(srcDir, "app.js"),
        "console.log('App started successfully');",
        "utf8"
      );

      const result = await verifyCode({
        repoRoot: tmpDir,
        targetDir: srcDir,
        reportDir,
      });

      expect(result.success).toBe(true);
      expect(result.riskLevel).toBe("LOW");
      expect(result.errors.length).toBe(0);
    });

    it("should detect secrets and API keys", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });

      await fs.writeFile(
        path.join(srcDir, "index.html"),
        "<!DOCTYPE html><html><head></head><body></body></html>",
        "utf8"
      );
      await fs.writeFile(
        path.join(srcDir, "secret.js"),
        'const apiKey = "sk-ant-1234567890123456789012345";',
        "utf8"
      );

      const result = await verifyCode({
        repoRoot: tmpDir,
        targetDir: srcDir,
      });

      expect(result.success).toBe(false);
      expect(result.errors.some((e) => e.includes("Secret leak"))).toBe(true);
    });

    it("should classify high risk calls (fetch/eval) and fail unless allowHighRisk is true", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });

      await fs.writeFile(
        path.join(srcDir, "index.html"),
        "<!DOCTYPE html><html><head></head><body></body></html>",
        "utf8"
      );
      await fs.writeFile(
        path.join(srcDir, "network.js"),
        'fetch("https://api.example.com/data");',
        "utf8"
      );

      // Without allowHighRisk
      const res1 = await verifyCode({
        repoRoot: tmpDir,
        targetDir: srcDir,
        allowHighRisk: false,
      });
      expect(res1.success).toBe(false);
      expect(res1.riskLevel).toBe("HIGH");

      // With allowHighRisk
      const res2 = await verifyCode({
        repoRoot: tmpDir,
        targetDir: srcDir,
        allowHighRisk: true,
      });
      expect(res2.success).toBe(true);
      expect(res2.riskLevel).toBe("HIGH");
    });

    it("should detect token drift (hardcoded colors in CSS)", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });

      await fs.writeFile(
        path.join(srcDir, "index.html"),
        "<!DOCTYPE html><html><head></head><body></body></html>",
        "utf8"
      );
      await fs.writeFile(
        path.join(srcDir, "style.css"),
        ".card { color: #ff0000; }",
        "utf8"
      );

      const result = await verifyCode({
        repoRoot: tmpDir,
        targetDir: srcDir,
      });

      expect(result.success).toBe(false);
      expect(result.errors.some((e) => e.includes("Token Drift"))).toBe(true);
    });

    it("should enforce asset provenance and check allowlist", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      const inboxDir = path.join(tmpDir, "01_THA_APP_VAO_DAY");
      await fs.mkdir(srcDir, { recursive: true });
      await fs.mkdir(inboxDir, { recursive: true });

      await fs.writeFile(
        path.join(srcDir, "index.html"),
        "<!DOCTYPE html><html><head></head><body></body></html>",
        "utf8"
      );

      const fakeImageBytes = Buffer.from("FAKE_IMAGE_DATA_123");
      await fs.writeFile(path.join(inboxDir, "logo.png"), fakeImageBytes);
      await fs.writeFile(path.join(srcDir, "logo.png"), fakeImageBytes);

      // Without allowlist -> should fail
      const res1 = await verifyCode({
        repoRoot: tmpDir,
        targetDir: srcDir,
      });
      expect(res1.success).toBe(false);
      expect(
        res1.errors.some((e) => e.includes("Asset Provenance Violation"))
      ).toBe(true);

      // With allowlist -> should pass
      await fs.writeFile(
        path.join(tmpDir, "ASSET_ALLOWLIST.md"),
        "# Allowlist\n- logo.png\n",
        "utf8"
      );
      const res2 = await verifyCode({
        repoRoot: tmpDir,
        targetDir: srcDir,
      });
      expect(res2.success).toBe(true);
    });
  });

  // =========================================================================
  // 5. Health Check Tests
  // =========================================================================
  describe("health-check", () => {
    it("should flag missing directories and immutability violations in 01_", async () => {
      // Mock an incomplete repo
      const res = await runHealthCheck({
        repoRoot: tmpDir,
        checkExternalTools: false,
      });

      expect(res.passed).toBe(false);
      expect(res.checks[0].passed).toBe(false);

      // Now create all required folders and test 01_ immutability violation
      const userDirs = [
        "01_THA_APP_VAO_DAY",
        "02_YEU_CAU_CUA_TOI",
        "03_KET_QUA_KIEM_TRA",
        "04_SAO_LUU_AN_TOAN",
        "05_MA_NGUON_PHAT_TRIEN",
      ];
      for (const d of userDirs) {
        await fs.mkdir(path.join(tmpDir, d), { recursive: true });
      }

      // Add forbidden temporary file to 01_
      await fs.writeFile(
        path.join(tmpDir, "01_THA_APP_VAO_DAY", "temp.tmp"),
        "temp",
        "utf8"
      );

      const resWithTemp = await runHealthCheck({
        repoRoot: tmpDir,
        checkExternalTools: false,
      });
      expect(resWithTemp.checks[0].passed).toBe(false);
      expect(resWithTemp.checks[0].message).toContain("Vi phạm tính bất biến");
    });

    it("should pass health check when workspace structure is fully satisfied", async () => {
      // 1. Dirs
      const userDirs = [
        "01_THA_APP_VAO_DAY",
        "02_YEU_CAU_CUA_TOI",
        "03_KET_QUA_KIEM_TRA",
        "04_SAO_LUU_AN_TOAN",
        "05_MA_NGUON_PHAT_TRIEN",
      ];
      for (const d of userDirs) {
        await fs.mkdir(path.join(tmpDir, d), { recursive: true });
      }

      // 2. Core docs
      for (const doc of ["AGENTS.md", "HUONG_DAN_SU_DUNG.md", "REVIEW.md"]) {
        await fs.writeFile(path.join(tmpDir, doc), "# " + doc, "utf8");
      }

      // 3. Skills
      const skills = [
        "rea-scan",
        "rea-audit",
        "rea-interview",
        "rea-plan",
        "rea-build",
        "memory-consolidation",
        "reverse-engineer-anything",
      ];
      for (const sk of skills) {
        const skDir = path.join(tmpDir, ".agents", "skills", sk);
        await fs.mkdir(skDir, { recursive: true });
        await fs.writeFile(path.join(skDir, "SKILL.md"), "# " + sk, "utf8");
      }

      // 4. Safety rule
      const ruleDir = path.join(tmpDir, ".agents", "rules");
      await fs.mkdir(ruleDir, { recursive: true });
      await fs.writeFile(
        path.join(ruleDir, "rea-workflow.md"),
        "---\ntrigger: always_on\n---\nRules",
        "utf8"
      );

      // 5. Context & State
      const docsDir = path.join(tmpDir, "docs");
      await fs.mkdir(docsDir, { recursive: true });
      for (const d of [
        "PRD.md",
        "ARCHITECTURE.md",
        "PROGRESS.md",
        "HANDOFF.md",
        "PLAN.md",
        "WORKFLOW_LIFECYCLE.md",
      ]) {
        await fs.writeFile(path.join(docsDir, d), "# " + d, "utf8");
      }

      const stateDir = path.join(tmpDir, ".agents", "state");
      await fs.mkdir(stateDir, { recursive: true });
      for (const s of ["MEMORY.md", "learned_rules.json", "active_case.json"]) {
        await fs.writeFile(path.join(stateDir, s), s.endsWith(".json") ? "{}" : "# Memory", "utf8");
      }

      const res = await runHealthCheck({
        repoRoot: tmpDir,
        checkExternalTools: false,
      });

      expect(res.passed).toBe(true);
      expect(res.score).toBe(res.total);
    });
  });
});
