import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import {
  compileTokens,
  extractDtcgValue,
  resolveTokenRef,
  toComposeColorHex,
  toXmlColorHex,
  toAndroidDp,
} from "../src/core/compile-tokens.js";
import { isNodeVersionCompliant, runHealthCheck } from "../src/core/health-check.js";

describe("Work Stream 1: W3C DTCG 2025.10 & Package/MCP/Health Compliance", () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "rea-dtcg-test-"));
  });

  afterEach(async () => {
    try {
      await fs.rm(tmpDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup error
    }
  });

  describe("extractDtcgValue Helper", () => {
    it("should extract hex from Color objects with .hex property", () => {
      expect(extractDtcgValue({ hex: "#2563eb" })).toBe("#2563eb");
      expect(
        extractDtcgValue({
          colorSpace: "srgb",
          hex: "#1d4ed8",
          components: [0.114, 0.306, 0.847],
        })
      ).toBe("#1d4ed8");
    });

    it("should extract value and unit from Dimension / Duration objects", () => {
      expect(extractDtcgValue({ value: 12, unit: "px" })).toBe("12px");
      expect(extractDtcgValue({ value: 1.5, unit: "rem" })).toBe("1.5rem");
      expect(extractDtcgValue({ value: 250, unit: "ms" })).toBe("250ms");
    });

    it("should extract nested $value if present", () => {
      expect(extractDtcgValue({ $value: { hex: "#10b981" } })).toBe("#10b981");
      expect(extractDtcgValue({ $value: { value: 48, unit: "px" } })).toBe("48px");
    });

    it("should return strings and numbers formatted correctly", () => {
      expect(extractDtcgValue("#ffffff")).toBe("#ffffff");
      expect(extractDtcgValue("6px")).toBe("6px");
      expect(extractDtcgValue(1.5)).toBe("1.5");
      expect(extractDtcgValue(0)).toBe("0");
    });
  });

  describe("resolveTokenRef with DTCG 2025.10 objects", () => {
    it("should resolve direct and indirect object references", () => {
      const rootTokens = {
        global: {
          color: {
            brand: {
              $value: { hex: "#3b82f6", colorSpace: "srgb" },
              $type: "color",
            },
          },
          dimension: {
            spacing: {
              $value: { value: 16, unit: "px" },
              $type: "dimension",
            },
          },
        },
        semantic: {
          color: {
            primary: {
              $value: "{global.color.brand}",
              $type: "color",
            },
          },
        },
      };

      expect(resolveTokenRef("{global.color.brand}", rootTokens)).toBe("#3b82f6");
      expect(resolveTokenRef("{semantic.color.primary}", rootTokens)).toBe("#3b82f6");
      expect(resolveTokenRef("{global.dimension.spacing}", rootTokens)).toBe("16px");
    });
  });

  describe("Dynamic Tokens Compilation (W3C DTCG 2025.10)", () => {
    it("should compile DTCG 2025.10 object colors/dimensions and dynamic font/duration", async () => {
      const customTokens = {
        $schema: "https://design-tokens.github.io/community-group/format/",
        name: "Test DTCG 2025.10 Tokens",
        version: "2.0.0",
        global: {
          color: {
            brand: {
              $value: { hex: "#3b82f6", colorSpace: "srgb" },
              $type: "color",
            },
            "brand-hover": {
              $value: { hex: "#1d4ed8" },
              $type: "color",
            },
          },
          dimension: {
            "radius-sm": {
              $value: { value: 8, unit: "px" },
              $type: "dimension",
            },
            "radius-md": {
              $value: { value: 16, unit: "px" },
              $type: "dimension",
            },
            "radius-lg": {
              $value: "24px",
              $type: "dimension",
            },
            "target-min": {
              $value: { value: 48, unit: "px" },
              $type: "dimension",
            },
          },
          font: {
            "family-main": {
              $value: "Inter, Roboto, sans-serif",
              $type: "fontFamily",
            },
            "size-sm": {
              $value: { value: 13, unit: "px" },
              $type: "dimension",
            },
            "size-base": {
              $value: { value: 18, unit: "px" },
              $type: "dimension",
            },
            "size-lg": {
              $value: "22px",
              $type: "dimension",
            },
            "size-xl": {
              $value: "28px",
              $type: "dimension",
            },
            "line-height-base": {
              $value: 1.6,
              $type: "number",
            },
          },
          duration: {
            fast: {
              $value: { value: 120, unit: "ms" },
              $type: "duration",
            },
            base: {
              $value: "220ms",
              $type: "duration",
            },
            slow: {
              $value: { value: 380, unit: "ms" },
              $type: "duration",
            },
          },
        },
        semantic: {
          color: {
            primary: {
              $value: "{global.color.brand}",
              $type: "color",
            },
            "primary-hover": {
              $value: "{global.color.brand-hover}",
              $type: "color",
            },
          },
        },
      };

      const tokensFile = path.join(tmpDir, "tokens.json");
      const outputDir = path.join(tmpDir, "compiled");
      await fs.writeFile(tokensFile, JSON.stringify(customTokens, null, 2), "utf8");

      const res = await compileTokens({
        tokensFile,
        outputDir,
        repoRoot: tmpDir,
      });

      expect(res.success).toBe(true);
      expect(res.colors.primary).toBe("#3b82f6");
      expect(res.dimensions.radiusSm).toBe("8px");
      expect(res.dimensions.radiusMd).toBe("16px");

      // Verify Web CSS Tokens
      const cssContent = await fs.readFile(path.join(outputDir, "tokens.css"), "utf8");
      expect(cssContent).toContain("--color-primary: #3b82f6;");
      expect(cssContent).toContain("--color-primary-hover: #1d4ed8;");
      expect(cssContent).toContain("--radius-sm: 8px;");
      expect(cssContent).toContain("--radius-md: 16px;");
      expect(cssContent).toContain("--font-main: Inter, Roboto, sans-serif;");
      expect(cssContent).toContain("--font-size-base: 18px;");
      expect(cssContent).toContain("--line-height-base: 1.6;");
      expect(cssContent).toContain("--motion-duration-fast: 120ms;");
      expect(cssContent).toContain("--motion-duration-base: 220ms;");
      expect(cssContent).toContain("--motion-duration-slow: 380ms;");

      // Verify Jetpack Compose Color.kt
      const colorKtContent = await fs.readFile(path.join(outputDir, "Color.kt"), "utf8");
      expect(colorKtContent).toContain("val Primary = Color(0xFF3B82F6)");
      expect(colorKtContent).toContain("val PrimaryHover = Color(0xFF1D4ED8)");

      // Verify Jetpack Compose Type.kt
      const typeKtContent = await fs.readFile(path.join(outputDir, "Type.kt"), "utf8");
      expect(typeKtContent).toContain("fontSize = 13.sp");
      expect(typeKtContent).toContain("fontSize = 18.sp");
      expect(typeKtContent).toContain("fontSize = 22.sp");
      expect(typeKtContent).toContain("fontSize = 28.sp");

      // Verify Jetpack Compose Shape.kt
      const shapeKtContent = await fs.readFile(path.join(outputDir, "Shape.kt"), "utf8");
      expect(shapeKtContent).toContain("small = RoundedCornerShape(8dp)");
      expect(shapeKtContent).toContain("medium = RoundedCornerShape(16dp)");
      expect(shapeKtContent).toContain("large = RoundedCornerShape(24dp)");

      // Verify Android XML colors.xml & dimens.xml
      const colorsXmlContent = await fs.readFile(path.join(outputDir, "colors.xml"), "utf8");
      expect(colorsXmlContent).toContain('<color name="color_primary">#3B82F6</color>');
      expect(colorsXmlContent).toContain('<color name="color_primary_hover">#1D4ED8</color>');

      const dimensXmlContent = await fs.readFile(path.join(outputDir, "dimens.xml"), "utf8");
      expect(dimensXmlContent).toContain('<dimen name="radius_sm">8dp</dimen>');
      expect(dimensXmlContent).toContain('<dimen name="radius_md">16dp</dimen>');
      expect(dimensXmlContent).toContain('<dimen name="radius_lg">24dp</dimen>');
      expect(dimensXmlContent).toContain('<dimen name="touch_target_min">48dp</dimen>');
    });
  });

  describe("Node.js Version Semver Range Compliance", () => {
    it("should accurately validate Node.js versions against ^22.23.4 || ^24.22.1 || >=26.12.1", () => {
      // Major 22 tests (^22.23.4)
      expect(isNodeVersionCompliant("v22.23.4")).toBe(true);
      expect(isNodeVersionCompliant("22.23.4")).toBe(true);
      expect(isNodeVersionCompliant("v22.23.5")).toBe(true);
      expect(isNodeVersionCompliant("v22.24.0")).toBe(true);
      expect(isNodeVersionCompliant("v22.23.3")).toBe(false);
      expect(isNodeVersionCompliant("v22.22.0")).toBe(false);
      expect(isNodeVersionCompliant("v22.13.0")).toBe(false);

      // Major 24 tests (^24.22.1)
      expect(isNodeVersionCompliant("v24.22.1")).toBe(true);
      expect(isNodeVersionCompliant("24.22.1")).toBe(true);
      expect(isNodeVersionCompliant("v24.22.3")).toBe(true);
      expect(isNodeVersionCompliant("v24.23.0")).toBe(true);
      expect(isNodeVersionCompliant("v24.22.0")).toBe(false);
      expect(isNodeVersionCompliant("v24.21.9")).toBe(false);

      // Major >= 26 tests (>=26.12.1)
      expect(isNodeVersionCompliant("v26.12.1")).toBe(true);
      expect(isNodeVersionCompliant("v26.12.2")).toBe(true);
      expect(isNodeVersionCompliant("v26.13.0")).toBe(true);
      expect(isNodeVersionCompliant("v27.0.0")).toBe(true);
      expect(isNodeVersionCompliant("v28.5.1")).toBe(true);
      expect(isNodeVersionCompliant("v26.12.0")).toBe(false);
      expect(isNodeVersionCompliant("v26.11.9")).toBe(false);

      // Non-matching majors
      expect(isNodeVersionCompliant("v20.18.0")).toBe(false);
      expect(isNodeVersionCompliant("v18.20.0")).toBe(false);
      expect(isNodeVersionCompliant("v21.0.0")).toBe(false);
      expect(isNodeVersionCompliant("v23.0.0")).toBe(false);
      expect(isNodeVersionCompliant("v25.0.0")).toBe(false);
      expect(isNodeVersionCompliant("")).toBe(false);
    });

    it("should report Node.js runtime compliance in runHealthCheck tools", async () => {
      const res = await runHealthCheck({
        repoRoot: tmpDir,
        checkExternalTools: true,
      });

      const nodeTool = res.tools.find((t) => t.name === "Node.js Runtime");
      expect(nodeTool).toBeDefined();
      expect(nodeTool?.available).toBe(true);
      expect(nodeTool?.version).toBe(process.version);

      const isCurrentNodeCompliant = isNodeVersionCompliant(process.version);
      if (isCurrentNodeCompliant) {
        expect(nodeTool?.note).toContain("Compliant with engines range");
      } else {
        expect(nodeTool?.note).toContain("Non-compliant with engines range");
      }
    });
  });

  describe("Workspace File Integrity Verification", () => {
    it("should verify 02_YEU_CAU_CUA_TOI/tokens.json line-height-base is numeric", async () => {
      const tokensPath = path.resolve(__dirname, "..", "02_YEU_CAU_CUA_TOI", "tokens.json");
      const content = await fs.readFile(tokensPath, "utf8");
      const tokens = JSON.parse(content);

      expect(typeof tokens.global.font["line-height-base"].$value).toBe("number");
      expect(tokens.global.font["line-height-base"].$value).toBe(1.5);
    });

    it("should verify package.json has updated sdk, engines, prepare script, and bin alias", async () => {
      const pkgPath = path.resolve(__dirname, "..", "package.json");
      const content = await fs.readFile(pkgPath, "utf8");
      const pkg = JSON.parse(content);

      expect(pkg.dependencies["@modelcontextprotocol/sdk"]).toBe("^1.32.2");
      expect(pkg.engines.node).toBe("^22.23.4 || ^24.22.1 || >=26.12.1");
      expect(pkg.scripts.prepare).toBe("npm run build");
      expect(pkg.bin["rea-kit-mcp"]).toBe("./dist/mcp.js");
      expect(pkg.bin["rea-kit"]).toBe("./dist/cli.js");
    });

    it("should verify .agents/mcp_config.json configuration matches spec", async () => {
      const configPath = path.resolve(__dirname, "..", ".agents", "mcp_config.json");
      const content = await fs.readFile(configPath, "utf8");
      const config = JSON.parse(content);

      // Server 'rea'
      expect(config.mcpServers.rea).toBeDefined();
      expect(config.mcpServers.rea.env).toEqual({
        REA_MCP_INPUT_SCHEMA_PROFILE: "full",
      });
      expect(config.mcpServers.rea.description).toBeUndefined();

      // Server 'rea-kit'
      expect(config.mcpServers["rea-kit"]).toBeDefined();
      expect(config.mcpServers["rea-kit"].cwd).toBe("${workspaceFolder}");
      expect(config.mcpServers["rea-kit"].args[0]).toBe("${workspaceFolder}/dist/mcp.js");
      expect(config.mcpServers["rea-kit"].description).toBeUndefined();
    });
  });
});
