import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { findRepoRoot } from "./workspace.js";
import { writeUtf8NoBomAtomic } from "./state-lock.js";

export interface TokenEstimation {
  length: number;
  tokens: number;
  isVietnamese: boolean;
}

export interface PlanOptions {
  repoRoot?: string;
  task: string;
  stage?: string;
  profile?: string;
}

export interface InspectOptions {
  repoRoot?: string;
  planId: string;
}

export interface PackOptions {
  repoRoot?: string;
  planId: string;
}

export interface VerifyOptions {
  repoRoot?: string;
  packId: string;
}

export interface ContextManifestDoc {
  id: string;
  path: string;
  layer: string;
  load_policy: "ALWAYS" | "CONDITIONAL" | "DEPRECATED";
  load_mode: "FULL" | "SUMMARY" | "SECTION_RETRIEVAL" | "REFERENCE_ONLY";
  estimated_tokens: number;
  description?: string;
  tags?: string[];
  condition?: {
    stages?: string[];
    profiles?: string[];
  };
  sections?: string[];
}

export interface ContextManifest {
  schema_version: number;
  manifest_id: string;
  default_budget: {
    model_capacity: number;
    reserved_output: number;
    reserved_tools: number;
    reserved_safety: number;
    usable_budget: number;
  };
  documents: ContextManifestDoc[];
}

export interface ProfileData {
  profile_id: string;
  name: string;
  context_budget_target?: number;
  included_documents?: Array<{
    id: string;
    mode?: "FULL" | "SUMMARY" | "SECTION_RETRIEVAL" | "REFERENCE_ONLY";
    sections?: string[];
  }>;
  forbidden_contexts?: string[];
  [key: string]: any;
}

/**
 * Estimates token count based on character count and language density.
 * Uses 2.0 divisor for Vietnamese text (>2% VN characters), 3.2 for English/code.
 */
export function estimateTokens(text: string): number {
  if (!text || text.length === 0) return 0;
  const vnRegex =
    /[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđĐ]/gi;
  const matches = text.match(vnRegex);
  const vnCount = matches ? matches.length : 0;
  const vnRatio = vnCount / text.length;
  const divisor = vnRatio > 0.02 ? 2.0 : 3.2;
  return Math.ceil(text.length / divisor);
}

/**
 * Classifies task text and stage into one of 6 context profiles.
 */
export function resolveProfileName(
  taskText?: string,
  stageName?: string,
  requestedProfile?: string
): string {
  if (requestedProfile && requestedProfile.trim()) {
    return requestedProfile.trim().toLowerCase();
  }

  const t = (taskText || "").toLowerCase();

  // 1. Compound UI phrases take precedence to prevent "tối ưu" from routing UI to optimization
  if (
    /(tối ưu giao diện|tối ưu layout|tối ưu ui|tối ưu ux|tối ưu animation|tối ưu icon)/i.test(
      t
    ) ||
    /\boptim\w*\s+(ui|ux|layout|animation|icon)\b/i.test(t)
  ) {
    return "design";
  }

  // 2. Security intents
  if (
    /\b(secur|audit|vulnerab|cve|secret|hardcod|permiss)\b/i.test(t) ||
    /(bảo mật|lỗ hổng|mã hóa|quyền truy cập|an toàn)/i.test(t)
  ) {
    return "security";
  }

  // 3. Optimization intents
  if (
    /\b(perf\w*|speed|memory|battery|leak\w*|profil\w*|fps)\b/i.test(t) ||
    /(tối ưu hiệu năng|tối ưu ram|tối ưu pin|tối ưu tốc độ|tối ưu fps|hiệu năng|tiêu thụ ram|ngốn ram|hao pin|tiết kiệm pin|tốc độ|mượt|lag|giật|fps)/i.test(
      t
    ) ||
    (/\b(optim\w*|tối ưu)\b/i.test(t) &&
      !/\b(design|ui|ux|token|layout|copy|anti-slop|giao diện|thiết kế|thẩm mỹ|đổi màu|bố cục|responsive|tỷ lệ màn hình|trực quan)\b/i.test(
        t
      ))
  ) {
    return "optimization";
  }

  // 4. Design intents
  if (
    /\b(re?design\w*|ui|ux|token|layout|copy|anti-slop|palette|typography|theme)\b/i.test(
      t
    ) ||
    /(giao diện|thiết kế|thẩm mỹ|đổi màu|bố cục|responsive|tỷ lệ màn hình|trực quan)/i.test(
      t
    )
  ) {
    return "design";
  }

  // 5. Validation intents
  if (
    /\b(validat|smoke|hard-verify|matrix|handoff|release)\b/i.test(t) ||
    /(nghiệm thu|kiểm thử|xác minh|kiểm định|bàn giao|phát hành)/i.test(t)
  ) {
    return "validation";
  }

  // 6. Feature addition intents
  if (
    /\b(feature|rebuild|implement|build|code|add|screen)\b/i.test(t) ||
    /(thêm tính năng|chức năng mới|viết lại|phát triển|xây dựng|màn hình mới)/i.test(
      t
    )
  ) {
    return "feature-addition";
  }

  // 7. Discovery intents
  if (
    /\b(discover|intake|scan|explore|baseline|investigat)\b/i.test(t) ||
    /(khám phá|quét|chẩn đoán|điều tra|bóc tách|tìm hiểu|sửa lỗi|fix bug|crash|bị lỗi|văng ứng dụng|treo máy)/i.test(
      t
    )
  ) {
    return "discovery";
  }

  switch (stageName) {
    case "STAGE_00_BOOTSTRAP":
    case "STAGE_01_DISCOVERY":
    case "STAGE_02_REVERSE_ENGINEERING":
      return "discovery";
    case "STAGE_03_PRODUCT_DEFINITION":
      return "design";
    case "STAGE_04_IMPLEMENTATION":
      return "feature-addition";
    case "STAGE_05_VALIDATION":
      return "validation";
    default:
      return "discovery";
  }
}

/**
 * Extracts sections from a Markdown file based on header matching.
 */
export function extractMarkdownSections(
  content: string,
  sections?: string[]
): string {
  if (!sections || sections.length === 0) {
    return content;
  }

  const lines = content.split(/\r?\n/);
  const headings: Array<{ index: number; level: number; title: string }> = [];

  for (let i = 0; i < lines.length; i++) {
    const match = lines[i].match(/^(#{1,6})\s+(.*)$/);
    if (match) {
      headings.push({
        index: i,
        level: match[1].length,
        title: match[2].trim(),
      });
    }
  }

  const extractedBlocks: string[] = [];

  for (const sec of sections) {
    const secClean = sec.trim();
    if (!secClean) continue;

    const words = secClean
      .replace(/[_·\-]+/g, " ")
      .split(/\s+/)
      .filter(Boolean)
      .map((w) => w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
    const secRegex = new RegExp(words.join(".*"), "i");

    let foundHeadingIndex = -1;
    for (let h = 0; h < headings.length; h++) {
      const hTitle = headings[h].title;
      if (secRegex.test(hTitle) || hTitle.toLowerCase().includes(secClean.toLowerCase())) {
        foundHeadingIndex = h;
        break;
      }
    }

    if (foundHeadingIndex !== -1) {
      const matchedH = headings[foundHeadingIndex];
      const startLine = matchedH.index;
      let endLine = lines.length - 1;

      for (let k = foundHeadingIndex + 1; k < headings.length; k++) {
        if (headings[k].level <= matchedH.level) {
          endLine = headings[k].index - 1;
          break;
        }
      }

      const blockLines = lines.slice(startLine, endLine + 1);
      extractedBlocks.push(blockLines.join("\n"));
    } else {
      let matchingLineIdx = -1;
      for (let i = 0; i < lines.length; i++) {
        if (secRegex.test(lines[i])) {
          matchingLineIdx = i;
          break;
        }
      }

      if (matchingLineIdx !== -1) {
        const wStart = Math.max(0, matchingLineIdx - 2);
        const wEnd = Math.min(lines.length - 1, matchingLineIdx + 10);
        extractedBlocks.push(lines.slice(wStart, wEnd + 1).join("\n"));
      }
    }
  }

  if (extractedBlocks.length > 0) {
    return extractedBlocks.join("\n\n---\n\n");
  }

  if (content.length > 8000) {
    return content.slice(0, 8000) + "\n... [Truncated: requested sections not found]";
  }

  return content;
}

function escapeXml(unsafe: string): string {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

/**
 * Resolves current stage from active_case.json.
 */
async function resolveStageFromState(repoRoot: string): Promise<string> {
  const stateFile = path.join(repoRoot, ".agents", "state", "active_case.json");
  if (fsSync.existsSync(stateFile)) {
    try {
      const raw = await fs.readFile(stateFile, "utf8");
      const st = JSON.parse(raw);
      if (st.current_phase) return st.current_phase;
    } catch {
      // Fallback
    }
  }
  return "STAGE_01_DISCOVERY";
}

/**
 * Plans context document selection and budget allocation based on task intent and manifest.
 */
export async function planContext(options: PlanOptions): Promise<Record<string, any>> {
  const repoRoot = options.repoRoot ? path.resolve(options.repoRoot) : findRepoRoot();
  const contextDir = path.join(repoRoot, ".agents", "context");
  const manifestFile = path.join(contextDir, "context-manifest.json");
  const profilesDir = path.join(contextDir, "profiles");
  const plansDir = path.join(contextDir, "plans");

  await fs.mkdir(plansDir, { recursive: true });

  const resolvedStage = options.stage || (await resolveStageFromState(repoRoot));
  let resolvedProfile = resolveProfileName(
    options.task,
    resolvedStage,
    options.profile
  );

  let profileFile = path.join(profilesDir, `${resolvedProfile}.json`);
  if (!fsSync.existsSync(profileFile)) {
    resolvedProfile = "discovery";
    profileFile = path.join(profilesDir, "discovery.json");
  }

  if (!fsSync.existsSync(manifestFile)) {
    throw new Error(`context-manifest.json not found at ${manifestFile}`);
  }

  const manifestRaw = await fs.readFile(manifestFile, "utf8");
  const manifest: ContextManifest = JSON.parse(manifestRaw);

  let profileData: ProfileData = { profile_id: resolvedProfile, name: resolvedProfile };
  if (fsSync.existsSync(profileFile)) {
    const profRaw = await fs.readFile(profileFile, "utf8");
    profileData = JSON.parse(profRaw);
  }

  const bModel = manifest.default_budget.model_capacity;
  const bOutput = manifest.default_budget.reserved_output;
  const bTools = manifest.default_budget.reserved_tools;
  const bSafety = manifest.default_budget.reserved_safety;
  let bUsable = bModel - bOutput - bTools - bSafety;

  if (profileData.context_budget_target && profileData.context_budget_target > 0) {
    bUsable = profileData.context_budget_target;
  }

  const selectedDocs: any[] = [];
  let totalTokens = 0;

  for (const doc of manifest.documents) {
    let shouldInclude = false;
    let loadMode = doc.load_mode;
    let docSections: string[] | undefined = undefined;

    if (doc.load_policy === "ALWAYS") {
      shouldInclude = true;
    } else if (doc.load_policy === "CONDITIONAL") {
      if (doc.condition) {
        const condStage = doc.condition.stages;
        const condProfiles = doc.condition.profiles;
        if (condStage && condStage.includes(resolvedStage)) shouldInclude = true;
        if (condProfiles && condProfiles.includes(resolvedProfile)) shouldInclude = true;
      }
    }

    if (profileData.included_documents) {
      for (const inc of profileData.included_documents) {
        if (inc.id === doc.id) {
          shouldInclude = true;
          if (inc.mode) loadMode = inc.mode;
          if (inc.sections) docSections = inc.sections;
        }
      }
    }

    if (!docSections && doc.sections) {
      docSections = doc.sections;
    }

    if (profileData.forbidden_contexts) {
      for (const forbid of profileData.forbidden_contexts) {
        if (doc.path.startsWith(forbid) || doc.id === forbid) {
          shouldInclude = false;
        }
      }
    }

    if (shouldInclude && doc.load_policy !== "DEPRECATED") {
      const estTok = Number(doc.estimated_tokens) || 0;
      const isUntrusted = doc.layer === "L5" || doc.tags?.includes("untrusted");
      const docObj: any = {
        id: doc.id,
        path: doc.path,
        layer: doc.layer,
        load_mode: loadMode,
        estimated_tokens: estTok,
        untrusted: Boolean(isUntrusted),
      };
      if (docSections) {
        docObj.sections = docSections;
      }
      selectedDocs.push(docObj);
      totalTokens += estTok;
    }
  }

  const pad = (n: number) => String(n).padStart(2, "0");
  const d = new Date();
  const planTimestamp = `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
  const randSuffix = crypto.randomBytes(2).toString("hex");
  const planId = `PLAN-${planTimestamp}-${randSuffix}`;

  const planObject = {
    schema_version: 1,
    plan_id: planId,
    task: options.task,
    stage: resolvedStage,
    profile: resolvedProfile,
    created_at: new Date().toISOString(),
    budget: {
      model_capacity: bModel,
      reserved_output: bOutput,
      reserved_tools: bTools,
      reserved_safety: bSafety,
      usable_budget: bUsable,
      allocated_tokens: totalTokens,
      utilization_pct: Number(((totalTokens / bUsable) * 100).toFixed(2)),
    },
    selected_documents: selectedDocs,
  };

  const planFilePath = path.join(plansDir, `${planId}.json`);
  await writeUtf8NoBomAtomic(planFilePath, JSON.stringify(planObject, null, 2));

  return planObject;
}

/**
 * Inspects a generated context plan.
 */
export async function inspectPlan(
  options: InspectOptions
): Promise<Record<string, any>> {
  const repoRoot = options.repoRoot ? path.resolve(options.repoRoot) : findRepoRoot();
  const plansDir = path.join(repoRoot, ".agents", "context", "plans");
  const targetFile = options.planId.endsWith(".json")
    ? path.join(plansDir, options.planId)
    : path.join(plansDir, `${options.planId}.json`);

  if (!fsSync.existsSync(targetFile)) {
    throw new Error(`Plan not found at: ${targetFile}`);
  }

  const raw = await fs.readFile(targetFile, "utf8");
  const plan = JSON.parse(raw);

  const layerOrder = ["L0", "L3", "L2", "L1", "L4", "L5"];
  const layerBreakdown: Record<string, any[]> = {};

  for (const ly of layerOrder) {
    layerBreakdown[ly] = (plan.selected_documents || []).filter(
      (d: any) => d.layer === ly
    );
  }

  return {
    plan_id: plan.plan_id,
    task: plan.task,
    stage: plan.stage,
    profile: plan.profile,
    budget: plan.budget,
    layers: layerBreakdown,
  };
}

/**
 * Assembles and packs context items into L0-L5 layers with prefix cache optimization.
 */
export async function packContext(options: PackOptions): Promise<Record<string, any>> {
  const repoRoot = options.repoRoot ? path.resolve(options.repoRoot) : findRepoRoot();
  const contextDir = path.join(repoRoot, ".agents", "context");
  const plansDir = path.join(contextDir, "plans");
  const packetsDir = path.join(contextDir, "packets");

  await fs.mkdir(packetsDir, { recursive: true });

  const planFile = options.planId.endsWith(".json")
    ? path.join(plansDir, options.planId)
    : path.join(plansDir, `${options.planId}.json`);

  if (!fsSync.existsSync(planFile)) {
    throw new Error(`Plan not found at: ${planFile}`);
  }

  const planRaw = await fs.readFile(planFile, "utf8");
  const plan = JSON.parse(planRaw);

  const layerNames: Record<string, string> = {
    L0: "Operating Contract & Safety Invariants",
    L1: "Active Case State & Gate Controller",
    L2: "Domain Knowledge & Execution Profiles",
    L3: "Project Architecture & Durable Wiki",
    L4: "Task Packet & Working Memory",
    L5: "Evidence & Ephemeral Tool I/O",
  };

  const orderedLayers = ["L0", "L3", "L2", "L1", "L4", "L5"];
  const packedLayers: any[] = [];
  let totalActualTokens = 0;

  for (const ly of orderedLayers) {
    const docsInLayer = (plan.selected_documents || []).filter(
      (d: any) => d.layer === ly
    );
    const layerItems: any[] = [];

    for (const doc of docsInLayer) {
      const filePath = path.join(repoRoot, doc.path);
      let content: string | null = null;
      let tok = Number(doc.estimated_tokens) || 0;

      if (fsSync.existsSync(filePath)) {
        try {
          if (doc.load_mode === "FULL") {
            content = await fs.readFile(filePath, "utf8");
          } else if (doc.load_mode === "SUMMARY") {
            const rawContent = await fs.readFile(filePath, "utf8");
            const lines = rawContent.split(/\r?\n/);
            if (doc.id === "STATE-MEMORY" || filePath.includes("MEMORY.md")) {
              const tableLines: string[] = [];
              let inTable = false;
              for (const line of lines) {
                if (
                  /^##\s+1\.\s+Bảng\s+Chỉ\s+Mục/i.test(line) ||
                  /^\|\s*ID\s*\|/i.test(line)
                ) {
                  inTable = true;
                }
                if (inTable) {
                  if (/^---/.test(line) && tableLines.length > 2) {
                    break;
                  }
                  tableLines.push(line);
                }
              }
              if (tableLines.length > 0) {
                content =
                  "# [SUMMARY: Memory Notes Index]\n" + tableLines.join("\n");
              } else {
                content =
                  lines.slice(0, 60).join("\n") + "\n... [Condensed memory summary]";
              }
            } else {
              content =
                lines.slice(0, 60).join("\n") + "\n... [Summary digest]";
            }
          } else if (doc.load_mode === "SECTION_RETRIEVAL") {
            const rawContent = await fs.readFile(filePath, "utf8");
            const sections = doc.sections || [];
            if (sections.length > 0) {
              content = extractMarkdownSections(rawContent, sections);
            } else {
              const rawTok = estimateTokens(rawContent);
              if (rawTok > 2500) {
                content =
                  rawContent.slice(0, 8000) + "\n... [Section slice]";
              } else {
                content = rawContent;
              }
            }
          } else {
            // REFERENCE_ONLY
            content = null;
            tok = 50;
          }
        } catch {
          content = `[Warning: Error reading file ${doc.path}]`;
        }
      } else {
        content = `[Notice: File not yet created: ${doc.path}]`;
        tok = 20;
      }

      let itemNonce: string | null = null;
      if (doc.untrusted) {
        itemNonce = crypto.randomBytes(16).toString("hex");
        const escaped = content ? escapeXml(content) : "";
        content = `<untrusted_binary_evidence nonce="${itemNonce}" path="${doc.path}">\n${escaped}\n</untrusted_binary_evidence>`;
      }

      if (content !== null) {
        tok = estimateTokens(content);
      }

      totalActualTokens += tok;
      const itemObj: any = {
        id: doc.id,
        path: doc.path,
        load_mode: doc.load_mode,
        estimated_tokens: tok,
        content,
        untrusted: Boolean(doc.untrusted),
      };
      if (doc.untrusted) {
        itemObj.nonce = itemNonce;
      }
      if (doc.sections) {
        itemObj.sections = doc.sections;
      }
      layerItems.push(itemObj);
    }

    packedLayers.push({
      layer_id: ly,
      layer_name: layerNames[ly],
      items: layerItems,
    });
  }

  const pad = (n: number) => String(n).padStart(2, "0");
  const d = new Date();
  const packTimestamp = `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
  const randSuffix = crypto.randomBytes(2).toString("hex");
  const packId = `PACK-${packTimestamp}-${randSuffix}`;

  const usable = Number(plan.budget.usable_budget);
  const status = totalActualTokens <= usable ? "READY" : "OVERBUDGET";

  const metadataTail = {
    packet_id: packId,
    plan_id: plan.plan_id,
    created_at: new Date().toISOString(),
    generator: "context.ts pack v2.0.1",
    layer_order: "L0->L3->L2->L1->L4->L5",
  };

  const packetObject = {
    schema_version: 1,
    layers: packedLayers,
    stage: plan.stage,
    profile: plan.profile,
    task: plan.task,
    budget: {
      model_capacity: plan.budget.model_capacity,
      reserved_output: plan.budget.reserved_output,
      reserved_tools: plan.budget.reserved_tools,
      reserved_safety: plan.budget.reserved_safety,
      usable_budget: usable,
      allocated_tokens: totalActualTokens,
      utilization_pct: Number(((totalActualTokens / usable) * 100).toFixed(2)),
    },
    cache_alignment: {
      prefix_stable: true,
      dynamic_suffix_only: true,
      timestamp_in_prefix: false,
    },
    status,
    _metadata_tail: metadataTail,
  };

  const packFilePath = path.join(packetsDir, `${packId}.json`);
  await writeUtf8NoBomAtomic(packFilePath, JSON.stringify(packetObject, null, 2));

  return packetObject;
}

/**
 * Verifies compliance of a packed context packet and issues a receipt.
 */
export async function verifyPacket(
  options: VerifyOptions
): Promise<Record<string, any>> {
  const repoRoot = options.repoRoot ? path.resolve(options.repoRoot) : findRepoRoot();
  const contextDir = path.join(repoRoot, ".agents", "context");
  const packetsDir = path.join(contextDir, "packets");
  const receiptsDir = path.join(contextDir, "receipts");

  await fs.mkdir(receiptsDir, { recursive: true });

  const packFile = options.packId.endsWith(".json")
    ? path.join(packetsDir, options.packId)
    : path.join(packetsDir, `${options.packId}.json`);

  if (!fsSync.existsSync(packFile)) {
    throw new Error(`Packet not found at: ${packFile}`);
  }

  const packetRaw = await fs.readFile(packFile, "utf8");
  const packet = JSON.parse(packetRaw);

  const packetId = packet._metadata_tail?.packet_id || packet.packet_id;
  const pad = (n: number) => String(n).padStart(2, "0");
  const d = new Date();
  const receiptTimestamp = `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
  const randSuffix = crypto.randomBytes(2).toString("hex");
  const receiptId = `RCPT-${receiptTimestamp}-${randSuffix}`;

  let totalDocs = 0;
  let totalChars = 0;
  const layerTokens: Record<string, number> = {
    L0: 0,
    L3: 0,
    L2: 0,
    L1: 0,
    L4: 0,
    L5: 0,
  };

  let noRawBinaryBloat = true;
  let untrustedSandboxed = true;

  for (const layer of packet.layers || []) {
    const lyId = layer.layer_id;
    let layerTok = 0;

    for (const it of layer.items || []) {
      totalDocs++;
      layerTok += Number(it.estimated_tokens) || 0;

      if (it.content) {
        totalChars += it.content.length;

        // Check raw binary bloat (>30k characters in 01_ or 04_)
        if (
          it.content.length > 30000 &&
          (it.path?.startsWith("01_THA_APP_VAO_DAY") ||
            it.path?.startsWith("04_SAO_LUU_AN_TOAN"))
        ) {
          noRawBinaryBloat = false;
        }

        // Check untrusted sandboxing
        if (it.untrusted) {
          const trimmed = it.content.trim();
          const noncePattern =
            /^<untrusted_binary_evidence\s+nonce="([a-f0-9]+)"\s+path="[^"]*">([\s\S]*?)<\/untrusted_binary_evidence>$/;
          const match = trimmed.match(noncePattern);
          if (match) {
            const extractedNonce = match[1];
            if (!extractedNonce || (it.nonce && it.nonce !== extractedNonce)) {
              untrustedSandboxed = false;
            }
            if (!trimmed.endsWith("</untrusted_binary_evidence>")) {
              untrustedSandboxed = false;
            }
          } else {
            untrustedSandboxed = false;
          }
        }
      }
    }
    layerTokens[lyId] = layerTok;
  }

  const totalTokens = Number(packet.budget.allocated_tokens) || 0;
  const usableBudget = Number(packet.budget.usable_budget) || 0;
  const budgetWithinLimit = totalTokens <= usableBudget;

  let verdict = "PASS";
  if (!budgetWithinLimit) {
    verdict = "WARN";
  }
  if (!noRawBinaryBloat || !packet.schema_version || !untrustedSandboxed) {
    verdict = "FAIL";
  }

  const layerOrderIds = (packet.layers || []).map((l: any) => l.layer_id);
  const stablePrefixFirst =
    layerOrderIds.length === 6 &&
    layerOrderIds[0] === "L0" &&
    layerOrderIds[1] === "L3" &&
    layerOrderIds[2] === "L2";

  const dynamicSuffixLast =
    layerOrderIds.length === 6 &&
    layerOrderIds[3] === "L1" &&
    layerOrderIds[4] === "L4" &&
    layerOrderIds[5] === "L5" &&
    Boolean(packet._metadata_tail);

  const receipt = {
    schema_version: 1,
    receipt_id: receiptId,
    packet_id: packetId,
    stage: packet.stage,
    verified_at: new Date().toISOString(),
    verdict,
    metrics: {
      total_documents: totalDocs,
      total_characters: totalChars,
      total_tokens: totalTokens,
      budget_limit: usableBudget,
      budget_utilization_pct: Number(
        ((totalTokens / usableBudget) * 100).toFixed(2)
      ),
      layer_tokens: layerTokens,
    },
    compliance: {
      stable_prefix_first: stablePrefixFirst,
      dynamic_suffix_last: dynamicSuffixLast,
      untrusted_data_sandboxed: untrustedSandboxed,
      budget_within_limit: budgetWithinLimit,
      no_raw_binary_bloat: noRawBinaryBloat,
    },
    compaction_applied: false,
    evicted_items: [],
    notes:
      "Context Packet verified against REA-kit-agy Context Engineering specifications.",
  };

  const receiptFilePath = path.join(receiptsDir, `${receiptId}.json`);
  await writeUtf8NoBomAtomic(receiptFilePath, JSON.stringify(receipt, null, 2));

  return receipt;
}
