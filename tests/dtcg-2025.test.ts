import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import {
  compileTokens,
  extractDtcgValue,
  resolveTokenRef,
  resolveAlias,
  toComposeColorHex,
  toXmlColorHex,
  toAndroidDp,
  toAndroidSp,
} from "../src/core/compile-tokens.js";
import {
  hasEsmSyntax,
  verifyCode,
  convertHexToRgb,
  getRelativeLuminance,
  getWcagContrastRatio,
} from "../src/core/verify-code.js";
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

    it("should verify templates/16-TOKENS-TEMPLATE.json line-height-base is numeric", async () => {
      const templatePath = path.resolve(__dirname, "..", "templates", "16-TOKENS-TEMPLATE.json");
      const content = await fs.readFile(templatePath, "utf8");
      const tokens = JSON.parse(content);

      expect(typeof tokens.global.font["line-height-base"].$value).toBe("number");
      expect(tokens.global.font["line-height-base"].$value).toBe(1.5);
    });
  });

  describe("Android Hex Color Ordering (AARRGGBB Alpha-First)", () => {
    it("should reorder 8-character hex from #RRGGBBAA to Compose 0xAARRGGBB and XML #AARRGGBB", () => {
      // Input: #RRGGBBAA where RR=25, GG=63, BB=eb, AA=80
      const hex8 = "#2563eb80";
      expect(toComposeColorHex(hex8)).toBe("0x802563EB");
      expect(toXmlColorHex(hex8)).toBe("#802563EB");

      // Fully opaque 8-char hex
      const hex8Opaque = "#112233FF";
      expect(toComposeColorHex(hex8Opaque)).toBe("0xFF112233");
      expect(toXmlColorHex(hex8Opaque)).toBe("#FF112233");

      // 6-char hex should retain 0xFF prefix in Compose and #RRGGBB in XML
      const hex6 = "#2563eb";
      expect(toComposeColorHex(hex6)).toBe("0xFF2563EB");
      expect(toXmlColorHex(hex6)).toBe("#2563EB");

      // 3-char hex shorthand expansion
      const hex3 = "#123";
      expect(toComposeColorHex(hex3)).toBe("0xFF112233");
      expect(toXmlColorHex(hex3)).toBe("#112233");

      // 4-char hex shorthand (#RGBA) expansion to #AARRGGBB
      const hex4 = "#1238";
      expect(toComposeColorHex(hex4)).toBe("0x88112233");
      expect(toXmlColorHex(hex4)).toBe("#88112233");
    });

    it("should safely handle invalid, malformed, or non-hex inputs", () => {
      expect(toComposeColorHex("")).toBe("0xFF000000");
      expect(toComposeColorHex("not-a-color")).toBe("0xFF000000");
      expect(toComposeColorHex("#XYZ")).toBe("0xFF000000");
      expect(toComposeColorHex("#12")).toBe("0xFF000000");
      expect(toComposeColorHex("#12345")).toBe("0xFF000000");
      expect(toComposeColorHex(undefined as any)).toBe("0xFF000000");
      expect(toComposeColorHex(null as any)).toBe("0xFF000000");

      expect(toXmlColorHex("")).toBe("#000000");
      expect(toXmlColorHex("not-a-color")).toBe("#000000");
      expect(toXmlColorHex("#XYZ")).toBe("#000000");
      expect(toXmlColorHex("#12")).toBe("#000000");
      expect(toXmlColorHex("#12345")).toBe("#000000");
      expect(toXmlColorHex(undefined as any)).toBe("#000000");
      expect(toXmlColorHex(null as any)).toBe("#000000");
    });
  });

  describe("W3C DTCG 2025.10 Color Objects with components array", () => {
    it("should convert 0..1 sRGB components array to hex string", () => {
      // 3 components [r, g, b]
      const color3 = {
        colorSpace: "srgb",
        components: [0.2, 0.4, 0.6],
      };
      // 0.2*255=51 (0x33), 0.4*255=102 (0x66), 0.6*255=153 (0x99)
      expect(extractDtcgValue(color3)).toBe("#336699");

      // 4 components [r, g, b, a]
      const color4 = {
        colorSpace: "srgb",
        components: [0.2, 0.4, 0.6, 0.8],
      };
      // 0.8*255=204 (0xcc)
      expect(extractDtcgValue(color4)).toBe("#336699cc");

      // Extremes: pure black and pure white
      expect(extractDtcgValue({ colorSpace: "srgb", components: [0, 0, 0] })).toBe("#000000");
      expect(extractDtcgValue({ colorSpace: "srgb", components: [1, 1, 1] })).toBe("#ffffff");

      // Components with separate alpha property
      const colorWithAlphaProp = {
        colorSpace: "srgb",
        components: [1, 0, 0],
        alpha: 0.5,
      };
      // 0.5*255=128 (0x80)
      expect(extractDtcgValue(colorWithAlphaProp)).toBe("#ff000080");

      // Boundary clamping (< 0 clamped to 0, > 1 clamped to 255) and NaN safety
      expect(
        extractDtcgValue({
          colorSpace: "srgb",
          components: [-0.5, 1.5, NaN, 2.0],
        })
      ).toBe("#00ff00ff");
    });

    it("should resolve token references that point to DTCG components object", () => {
      const rootTokens = {
        global: {
          color: {
            brand: {
              $value: { colorSpace: "srgb", components: [0.2, 0.4, 0.6] },
              $type: "color",
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

      expect(resolveTokenRef("{semantic.color.primary}", rootTokens)).toBe("#336699");
    });
  });

  describe("Dimensions & Typography Rem Conversions", () => {
    it("should convert rem to dp (1rem = 16dp) in toAndroidDp", () => {
      expect(toAndroidDp("1.5rem")).toBe("24dp");
      expect(toAndroidDp("1rem")).toBe("16dp");
      expect(toAndroidDp("2rem")).toBe("32dp");
      expect(toAndroidDp("0.5rem")).toBe("8dp");
      expect(toAndroidDp("16px")).toBe("16dp");
      expect(toAndroidDp("16 px")).toBe("16dp");
      expect(toAndroidDp("24dp")).toBe("24dp");
      expect(toAndroidDp("24 dp")).toBe("24dp");
      expect(toAndroidDp("12")).toBe("12dp");
      expect(toAndroidDp("12.3456px")).toBe("12.35dp");
      expect(toAndroidDp("")).toBe("0dp");
      expect(toAndroidDp(undefined as any)).toBe("0dp");
    });

    it("should convert rem to sp (1rem = 16sp) in toAndroidSp", () => {
      expect(toAndroidSp("1.5rem")).toBe("24");
      expect(toAndroidSp("1rem")).toBe("16");
      expect(toAndroidSp("0.875rem")).toBe("14");
      expect(toAndroidSp("16px")).toBe("16");
      expect(toAndroidSp("16 px")).toBe("16dp" ? "16" : "16");
      expect(toAndroidSp("18sp")).toBe("18");
      expect(toAndroidSp("20")).toBe("20");
      expect(toAndroidSp("14.567px")).toBe("14.57");
      expect(toAndroidSp("", "14")).toBe("14");
      expect(toAndroidSp(undefined as any, "14")).toBe("14");
    });

    it("should compile tokens with rem dimensions and typography properly into Android outputs", async () => {
      const customTokens = {
        $schema: "https://design-tokens.github.io/community-group/format/",
        name: "Rem Test Tokens",
        version: "1.0.0",
        global: {
          color: {
            brand: { $value: "#2563eb", $type: "color" },
          },
          dimension: {
            "radius-sm": { $value: "0.5rem", $type: "dimension" },
            "radius-md": { $value: "1rem", $type: "dimension" },
            "radius-lg": { $value: "1.5rem", $type: "dimension" },
            "target-min": { $value: "3rem", $type: "dimension" },
          },
          font: {
            "family-main": { $value: "sans-serif", $type: "fontFamily" },
            "size-sm": { $value: "0.875rem", $type: "dimension" },
            "size-base": { $value: "1rem", $type: "dimension" },
            "size-lg": { $value: "1.25rem", $type: "dimension" },
            "size-xl": { $value: "1.5rem", $type: "dimension" },
            "line-height-base": { $value: 1.5, $type: "number" },
          },
        },
      };

      const tokensFile = path.join(tmpDir, "rem-tokens.json");
      const outputDir = path.join(tmpDir, "rem-compiled");
      await fs.writeFile(tokensFile, JSON.stringify(customTokens, null, 2), "utf8");

      const res = await compileTokens({
        tokensFile,
        outputDir,
        repoRoot: tmpDir,
      });

      expect(res.success).toBe(true);

      // Verify Shape.kt uses converted dp
      const shapeKtContent = await fs.readFile(path.join(outputDir, "Shape.kt"), "utf8");
      expect(shapeKtContent).toContain("small = RoundedCornerShape(8dp)");
      expect(shapeKtContent).toContain("medium = RoundedCornerShape(16dp)");
      expect(shapeKtContent).toContain("large = RoundedCornerShape(24dp)");

      // Verify dimens.xml uses converted dp
      const dimensXmlContent = await fs.readFile(path.join(outputDir, "dimens.xml"), "utf8");
      expect(dimensXmlContent).toContain('<dimen name="radius_sm">8dp</dimen>');
      expect(dimensXmlContent).toContain('<dimen name="radius_md">16dp</dimen>');
      expect(dimensXmlContent).toContain('<dimen name="radius_lg">24dp</dimen>');
      expect(dimensXmlContent).toContain('<dimen name="touch_target_min">48dp</dimen>');

      // Verify Type.kt uses converted sp (1rem = 16sp, 1.5rem = 24sp, 0.875rem = 14sp, 1.25rem = 20sp)
      const typeKtContent = await fs.readFile(path.join(outputDir, "Type.kt"), "utf8");
      expect(typeKtContent).toContain("fontSize = 14.sp");
      expect(typeKtContent).toContain("fontSize = 16.sp");
      expect(typeKtContent).toContain("fontSize = 20.sp");
      expect(typeKtContent).toContain("fontSize = 24.sp");
    });
  });

  describe("Circular Token Dependency Detection", () => {
    it("should throw an error on direct self-referencing tokens", () => {
      const rootTokens = {
        global: {
          color: {
            self: { $value: "{global.color.self}" },
          },
        },
      };

      expect(() => resolveTokenRef("{global.color.self}", rootTokens)).toThrow(
        /Circular token dependency detected/
      );
    });

    it("should throw an error on indirect 2-hop circular dependency", () => {
      const rootTokens = {
        global: {
          color: {
            alpha: { $value: "{global.color.beta}" },
            beta: { $value: "{global.color.alpha}" },
          },
        },
      };

      expect(() => resolveTokenRef("{global.color.alpha}", rootTokens)).toThrow(
        /Circular token dependency detected/
      );
      expect(() => resolveAlias("{global.color.beta}", rootTokens)).toThrow(
        /Circular token dependency detected/
      );
    });

    it("should throw an error on 3-hop circular dependency cycle", () => {
      const rootTokens = {
        global: {
          color: {
            a: { $value: "{global.color.b}" },
            b: { $value: "{global.color.c}" },
            c: { $value: "{global.color.a}" },
          },
        },
      };

      expect(() => resolveTokenRef("{global.color.a}", rootTokens)).toThrow(
        /Circular token dependency detected:.*a.*b.*c/
      );
    });

    it("should resolve valid non-circular multi-hop alias chains", () => {
      const rootTokens = {
        global: {
          color: {
            a: { $value: "{global.color.b}" },
            b: { $value: "{global.color.c}" },
            c: { $value: "#4f46e5" },
          },
        },
      };

      expect(resolveTokenRef("{global.color.a}", rootTokens)).toBe("#4f46e5");
    });

    it("should not false-alarm on diamond dependencies (A -> B, A -> C, B -> D, C -> D)", () => {
      const rootTokens = {
        global: {
          color: {
            d: { $value: "#10b981" },
            b: { $value: "{global.color.d}" },
            c: { $value: "{global.color.d}" },
            a1: { $value: "{global.color.b}" },
            a2: { $value: "{global.color.c}" },
          },
        },
      };

      expect(resolveTokenRef("{global.color.a1}", rootTokens)).toBe("#10b981");
      expect(resolveTokenRef("{global.color.a2}", rootTokens)).toBe("#10b981");
      expect(resolveAlias("{global.color.b}", rootTokens)).toBe("#10b981");
      expect(resolveAlias("{global.color.c}", rootTokens)).toBe("#10b981");
    });
  });

  describe("Code Verifier: ESM Syntax Detection", () => {
    it("should detect static imports, exports, and top-level await in hasEsmSyntax", () => {
      expect(hasEsmSyntax("import foo from './bar.js';")).toBe(true);
      expect(hasEsmSyntax("import { a, b } from './mod.js';")).toBe(true);
      expect(hasEsmSyntax("import * as all from './all.js';")).toBe(true);
      expect(hasEsmSyntax("import './side-effect.css';")).toBe(true);
      expect(hasEsmSyntax("export default function() {}")).toBe(true);
      expect(hasEsmSyntax("export const foo = 42;")).toBe(true);
      expect(hasEsmSyntax("export { bar } from './bar.js';")).toBe(true);
    });

    it("should not falsely match ESM keywords inside strings or comments", () => {
      expect(hasEsmSyntax("const str = 'import foo from \"./bar.js\"';")).toBe(false);
      expect(hasEsmSyntax("// import foo from './bar.js';")).toBe(false);
      expect(hasEsmSyntax("/* export default function() {} */")).toBe(false);
      expect(hasEsmSyntax("// const x = await fetch();")).toBe(false);
      expect(hasEsmSyntax("console.log('export default 123');")).toBe(false);
    });
    it("should detect top-level await in hasEsmSyntax", () => {
      expect(hasEsmSyntax("const res = await fetch('/api/data');")).toBe(true);
      expect(hasEsmSyntax("let config = await loadConfig();")).toBe(true);
      expect(hasEsmSyntax("var item = await getItem();")).toBe(true);
    });

    it("should detect import.meta in hasEsmSyntax", () => {
      expect(hasEsmSyntax("const currentDir = import.meta.url;")).toBe(true);
      expect(hasEsmSyntax("if (import.meta.env) { console.log('env'); }")).toBe(true);
    });

    it("should detect dynamic import() in hasEsmSyntax", () => {
      expect(hasEsmSyntax("const module = await import('./module.js');")).toBe(true);
      expect(hasEsmSyntax("import('./utils.js').then(u => u.run());")).toBe(true);
    });

    it("should return false for standard non-ESM CommonJS", () => {
      expect(hasEsmSyntax("const fs = require('fs'); module.exports = { fs };")).toBe(false);
    });
  });

  describe("Code Verifier: Secret Scanning Hardening", () => {
    it("should strip Data URIs and sourcemaps without false positive leaks", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });

      // HTML with Data URI font and inline sourceMappingURL comment
      const smComment = "//" + "# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbXX0=";
      const htmlWithDataUri = `<!DOCTYPE html>
<html>
<head>
  <title>Data URI Test</title>
  <style>
    @font-face {
      font-family: 'TestFont';
      src: url(data:font/woff2;base64,d09GMgABAAAAAA...d09GMgABAAAAAA==) format('woff2');
    }
  </style>
</head>
<body>
  <h1>Safe App</h1>
  <script>
    console.log("Clean code");
    ${smComment}
  </script>
</body>
</html>`;

      await fs.writeFile(path.join(srcDir, "index.html"), htmlWithDataUri, "utf8");

      const res = await verifyCode({ repoRoot: tmpDir, targetDir: "05_MA_NGUON_PHAT_TRIEN" });
      const secretErrors = res.errors.filter((e) => e.includes("Secret leak"));
      expect(secretErrors).toEqual([]);
    });
  });

  describe("Code Verifier: Route A Offline Check", () => {
    it("should block fonts.gstatic.com in Route A offline check", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });

      const htmlWithGstatic = `<!DOCTYPE html>
<html>
<head>
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
</head>
<body><p>Offline violation</p></body>
</html>`;
      await fs.writeFile(path.join(srcDir, "index.html"), htmlWithGstatic, "utf8");

      const res = await verifyCode({ repoRoot: tmpDir, targetDir: "05_MA_NGUON_PHAT_TRIEN" });
      expect(res.success).toBe(false);
      expect(res.errors.some((e) => e.includes("Route A offline violation"))).toBe(true);
    });

    it("should block CSS @import url('https://...') in Route A offline check", async () => {
      const srcDir = path.join(tmpDir, "05_MA_NGUON_PHAT_TRIEN");
      await fs.mkdir(srcDir, { recursive: true });

      await fs.writeFile(
        path.join(srcDir, "index.html"),
        `<!DOCTYPE html><html><head><link rel="stylesheet" href="style.css"></head><body><h1>Hi</h1></body></html>`,
        "utf8"
      );

      const cssWithImport = `@import url("https://fonts.googleapis.com/css2?family=Roboto");\nbody { font-family: Roboto; }`;
      await fs.writeFile(path.join(srcDir, "style.css"), cssWithImport, "utf8");

      const res = await verifyCode({ repoRoot: tmpDir, targetDir: "05_MA_NGUON_PHAT_TRIEN" });
      expect(res.success).toBe(false);
      expect(res.errors.some((e) => e.includes("Route A offline violation"))).toBe(true);
    });
  });

  describe("Code Verifier: Relative Luminance & Contrast Calculation", () => {
    it("should calculate relative luminance using IEC 61966-2-1 0.04045 threshold", () => {
      // Near black rgb
      const darkRgb = { r: 5, g: 5, b: 5 };
      const lum = getRelativeLuminance(darkRgb);
      expect(lum).toBeGreaterThan(0);
      expect(Number.isNaN(lum)).toBe(false);

      // Pure white
      const whiteRgb = { r: 255, g: 255, b: 255 };
      expect(getRelativeLuminance(whiteRgb)).toBeCloseTo(1.0, 4);

      // Pure black
      const blackRgb = { r: 0, g: 0, b: 0 };
      expect(getRelativeLuminance(blackRgb)).toBe(0);
    });

    it("should validate hex input to prevent NaN in convertHexToRgb and getWcagContrastRatio", () => {
      expect(convertHexToRgb("invalid")).toBeNull();
      expect(convertHexToRgb("#XYZ123")).toBeNull();
      expect(convertHexToRgb("#12")).toBeNull();
      expect(convertHexToRgb("")).toBeNull();
      expect(convertHexToRgb("#1238")).toEqual({ r: 17, g: 34, b: 51 });

      expect(getWcagContrastRatio("invalid", "#ffffff")).toBe(0.0);
      expect(getWcagContrastRatio("#000000", "not-a-color")).toBe(0.0);
      expect(Number.isNaN(getWcagContrastRatio("xyz", "abc"))).toBe(false);
    });
  });
});
