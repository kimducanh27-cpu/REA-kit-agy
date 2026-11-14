import fs from "node:fs/promises";
import path from "node:path";
import { findRepoRoot } from "./workspace.js";
import { writeUtf8NoBomAtomic } from "./state-lock.js";

export interface AdrRecord {
  id: string;
  file: string;
  fullName: string;
  title: string;
  status: string;
  date: string;
}

/**
 * Locates the docs/adrs directory by climbing up from repoRoot or cwd.
 */
export function findAdrDir(repoRoot?: string): string {
  let current = repoRoot ? path.resolve(repoRoot) : findRepoRoot();
  while (current) {
    const candidate = path.join(current, "docs", "adrs");
    try {
      // Synchronous or quick check if needed; path.resolve is safe
      return candidate;
    } catch {
      // break
    }
    const parent = path.dirname(current);
    if (parent === current) break;
    current = parent;
  }
  return path.join(repoRoot ? path.resolve(repoRoot) : findRepoRoot(), "docs", "adrs");
}

/**
 * Scans docs/adrs/ for all Markdown ADR files and parses header metadata.
 */
export async function getAdrList(targetAdrDir?: string): Promise<AdrRecord[]> {
  const adrDir = targetAdrDir || findAdrDir();
  let fileNames: string[] = [];
  try {
    fileNames = await fs.readdir(adrDir);
  } catch {
    return [];
  }

  const mdFiles = fileNames.filter((f) => f.endsWith(".md")).sort();
  const adrs: AdrRecord[] = [];

  for (const fileName of mdFiles) {
    const fullPath = path.join(adrDir, fileName);
    let content = "";
    try {
      const raw = await fs.readFile(fullPath, "utf8");
      content = raw.charCodeAt(0) === 0xfeff ? raw.slice(1) : raw;
    } catch {
      continue;
    }

    let title = "Không có tiêu đề";
    let status = "unknown";
    let date = "unknown";

    const lines = content.split(/\r?\n/);
    for (const line of lines) {
      const titleMatch = line.match(/^#\s+(.+)$/);
      if (titleMatch && title === "Không có tiêu đề") {
        title = titleMatch[1].trim();
      }
      const statusMatch = line.match(/^-\s*Status:\s*(.+)$/i);
      if (statusMatch) {
        status = statusMatch[1].trim();
      }
      const dateMatch = line.match(/^-\s*Date:\s*(.+)$/i);
      if (dateMatch) {
        date = dateMatch[1].trim();
      }
    }

    let id = path.parse(fileName).name;
    const numMatch = id.match(/^(\d+)/);
    if (numMatch) {
      id = numMatch[1];
    }

    adrs.push({
      id,
      file: fileName,
      fullName: fullPath,
      title,
      status,
      date,
    });
  }

  return adrs;
}

/**
 * Returns formatted text list of all ADRs.
 */
export async function listAdrs(targetAdrDir?: string): Promise<{
  records: AdrRecord[];
  text: string;
}> {
  const adrDir = targetAdrDir || findAdrDir();
  const records = await getAdrList(adrDir);

  let text = `================================================================================
   DANH SÁCH ARCHITECTURE DECISION RECORDS (ADR) — REA-KIT-AGY
   Thư mục: docs/adrs | Chuẩn: MADR
================================================================================
${"ID".padEnd(6)} | ${"TRẠNG THÁI".padEnd(10)} | ${"NGÀY".padEnd(12)} | TIÊU ĐỀ
${"-".repeat(80)}\n`;

  if (records.length === 0) {
    text += `Chưa có bản ghi ADR nào trong ${adrDir}`;
    return { records, text };
  }

  for (const adr of records) {
    text += `${adr.id.padEnd(6)} | ${adr.status.toUpperCase().padEnd(10)} | ${adr.date.padEnd(12)} | ${adr.title}\n`;
  }
  text += `${"-".repeat(80)}\nTổng cộng: ${records.length} bản ghi ADR.\nGợi ý: Chạy 'rea-kit adr show <id>' để xem chi tiết bản ghi.`;

  return { records, text };
}

/**
 * Shows the full content of an ADR by ID or file prefix.
 */
export async function showAdr(
  id: string,
  targetAdrDir?: string
): Promise<{ record: AdrRecord; content: string; text: string }> {
  if (!id) {
    throw new Error("[!] Vui lòng cung cấp ID của ADR. Ví dụ: rea-kit adr show 0001");
  }
  const adrDir = targetAdrDir || findAdrDir();
  const paddedId = /^\d+$/.test(id) ? String(parseInt(id, 10)).padStart(4, "0") : id;

  const files = await fs.readdir(adrDir);
  const mdFiles = files.filter((f) => f.endsWith(".md")).sort();

  const idPattern = new RegExp(`^(${paddedId}|${id})(-.*)?\\.md$`, "i");
  const targetFile = mdFiles.find((f) => idPattern.test(f));

  if (!targetFile) {
    throw new Error(`[!] Không tìm thấy ADR nào khớp với ID hoặc tên: '${id}'`);
  }

  const fullPath = path.join(adrDir, targetFile);
  const raw = await fs.readFile(fullPath, "utf8");
  const content = raw.charCodeAt(0) === 0xfeff ? raw.slice(1) : raw;

  const adrs = await getAdrList(adrDir);
  const record = adrs.find((a) => a.file === targetFile) || {
    id: paddedId,
    file: targetFile,
    fullName: fullPath,
    title: "",
    status: "",
    date: "",
  };

  const text = `================================================================================
   CHI TIẾT ADR: ${targetFile}
================================================================================
${content}`;

  return { record, content, text };
}

/**
 * Validates MADR standard compliance across all ADR files.
 * Checks: title, status, date, context, decision drivers, considered options, decision outcome, consequences, links.
 */
export async function validateAdrs(targetAdrDir?: string): Promise<{
  valid: boolean;
  score: number;
  total: number;
  errors: Record<string, string[]>;
  text: string;
}> {
  const adrDir = targetAdrDir || findAdrDir();
  let files: string[] = [];
  try {
    files = (await fs.readdir(adrDir)).filter((f) => f.endsWith(".md")).sort();
  } catch {
    return {
      valid: false,
      score: 0,
      total: 0,
      errors: { global: [`Không tìm thấy thư mục ADR tại: ${adrDir}`] },
      text: `[FAIL] Không tìm thấy thư mục ADR tại: ${adrDir}`,
    };
  }

  const adrs = await getAdrList(adrDir);
  if (adrs.length === 0) {
    return {
      valid: false,
      score: 0,
      total: 0,
      errors: { global: [`Không tìm thấy bản ghi ADR nào trong ${adrDir} (thư mục rỗng)!`] },
      text: `[FAIL] Không tìm thấy bản ghi ADR nào trong ${adrDir} (thư mục rỗng)!`,
    };
  }

  let allValid = true;
  const errors: Record<string, string[]> = {};

  // Check duplicate IDs
  const idCounts = new Map<string, string[]>();
  for (const adr of adrs) {
    const list = idCounts.get(adr.id) || [];
    list.push(adr.file);
    idCounts.set(adr.id, list);
  }

  for (const [id, grpFiles] of idCounts.entries()) {
    if (grpFiles.length > 1) {
      allValid = false;
      const msg = `Phát hiện trùng lặp mã ID ADR '${id}': ${grpFiles.join(", ")}`;
      errors[id] = errors[id] || [];
      errors[id].push(msg);
    }
  }

  const validStatuses = ["PROPOSED", "ACCEPTED", "REJECTED", "DEPRECATED", "SUPERSEDED"];
  const requiredSections = [
    { name: "Context and Problem Statement", regex: /(## Context and Problem Statement|## Context)/i },
    { name: "Decision Drivers", regex: /## Decision Drivers/i },
    { name: "Considered Options", regex: /## Considered Options/i },
    { name: "Decision Outcome", regex: /(## Decision Outcome|## Decision)/i },
    { name: "Consequences / Pros and Cons", regex: /(### Positive Consequences|## Consequences|### Consequences|## Pros and Cons of the Options)/i },
    { name: "Links", regex: /## Links/i },
  ];

  let score = 0;
  let text = `================================================================================
   KIỂM ĐỊNH TÍNH CHUẨN MỰC MADR CÁC BẢN GHI ADR
================================================================================\n`;

  for (const adr of adrs) {
    const raw = await fs.readFile(adr.fullName, "utf8");
    const content = raw.charCodeAt(0) === 0xfeff ? raw.slice(1) : raw;
    const missing: string[] = [];

    // Title
    if (!/(^|\n)#\s+.+/.test(content)) {
      missing.push("Tiêu đề chính (# Title)");
    }

    // Status
    const statusMatch = content.match(/(^|\n)-\s*Status:\s*(.+)/i);
    if (!statusMatch) {
      missing.push("Trường '- Status:'");
    } else {
      const st = statusMatch[2].trim().toUpperCase();
      if (!validStatuses.includes(st)) {
        missing.push(
          `Trường '- Status:' không hợp lệ: '${statusMatch[2].trim()}' (phải là PROPOSED, ACCEPTED, REJECTED, DEPRECATED, hoặc SUPERSEDED)`
        );
      }
    }

    // Date
    if (!/(^|\n)-\s*Date:\s*.+/.test(content)) {
      missing.push("Trường '- Date:'");
    }

    // Required sections
    for (const sec of requiredSections) {
      if (!sec.regex.test(content)) {
        missing.push(`Mục '${sec.name}'`);
      }
    }

    if (missing.length === 0) {
      text += `[OK] ADR ${adr.id}: ${adr.file} (Chuẩn MADR hợp lệ)\n`;
      score++;
    } else {
      text += `[FAIL] ADR ${adr.id}: ${adr.file}\n`;
      for (const m of missing) {
        text += `       - Thiếu: ${m}\n`;
      }
      errors[adr.id] = (errors[adr.id] || []).concat(missing);
      allValid = false;
    }
  }

  text += `${"-".repeat(80)}\n`;
  if (allValid) {
    text += `HOÀN HẢO! Toàn bộ ${score}/${adrs.length} bản ghi ADR đạt chuẩn cấu trúc MADR.`;
  } else {
    text += `CẢNH BÁO: Phát hiện bản ghi ADR chưa đạt chuẩn MADR. (${score}/${adrs.length} hợp lệ)`;
  }

  return { valid: allValid, score, total: adrs.length, errors, text };
}

/**
 * Returns summary counts by status.
 */
export async function getAdrStatus(targetAdrDir?: string): Promise<{
  total: number;
  counts: Record<string, number>;
  text: string;
}> {
  const adrDir = targetAdrDir || findAdrDir();
  const adrs = await getAdrList(adrDir);
  const counts: Record<string, number> = {};

  for (const adr of adrs) {
    const st = adr.status.toLowerCase();
    counts[st] = (counts[st] || 0) + 1;
  }

  let text = `================================================================================
   THỐNG KÊ TRẠNG THÁI ARCHITECTURE DECISION RECORDS
================================================================================
Tổng số ADR đã lập: ${adrs.length}\n`;
  for (const [key, count] of Object.entries(counts)) {
    text += `  - ${key.toUpperCase().padEnd(12)}: ${count}\n`;
  }

  return { total: adrs.length, counts, text };
}

/**
 * Generates a new ADR file adhering to the MADR standard.
 */
export async function newAdr(
  titleOrId?: string,
  titleParam?: string,
  targetAdrDir?: string
): Promise<{ id: string; fileName: string; filePath: string; title: string; text: string }> {
  const adrDir = targetAdrDir || findAdrDir();
  await fs.mkdir(adrDir, { recursive: true });
  const adrs = await getAdrList(adrDir);

  let maxNum = 0;
  for (const adr of adrs) {
    if (/^\d+$/.test(adr.id)) {
      const n = parseInt(adr.id, 10);
      if (n > maxNum) maxNum = n;
    }
  }

  let newNum = maxNum + 1;
  let titleText = "New Architectural Decision";

  if (titleParam) {
    titleText = titleParam;
    if (titleOrId && /^\d+$/.test(titleOrId)) {
      newNum = parseInt(titleOrId, 10);
    }
  } else if (titleOrId) {
    if (/^\d+$/.test(titleOrId)) {
      newNum = parseInt(titleOrId, 10);
    } else {
      titleText = titleOrId;
    }
  }

  const formattedId = String(newNum).padStart(4, "0");
  const normalized = titleText
    .replace(/[đĐ]/g, "d")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
  let slug = normalized
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  if (!slug) slug = "new-record";

  const fileName = `${formattedId}-${slug}.md`;
  const filePath = path.join(adrDir, fileName);

  try {
    await fs.access(filePath);
    throw new Error(`[!] File ADR đã tồn tại: ${filePath}`);
  } catch (err: any) {
    if (err.code !== "ENOENT") throw err;
  }

  const currentDate = new Date().toISOString().slice(0, 10);
  const template = `# ${titleText}

- Status: proposed
- Deciders: REA Agent Swarm & Human Architect
- Date: ${currentDate}

## Context and Problem Statement

[Mô tả bối cảnh và vấn đề kiến trúc cần đưa ra quyết định...]

## Decision Drivers

* [Động lực 1: ví dụ yêu cầu hiệu năng, độ tin cậy]
* [Động lực 2: ví dụ chi phí bảo trì, tính tương thích]

## Considered Options

* Option 1: [Lựa chọn 1]
* Option 2: [Lựa chọn 2]

## Decision Outcome

Chosen option: "[Lựa chọn được chọn]", because [lý do lựa chọn].

### Positive Consequences

* [Hệ quả tích cực 1]
* [Hệ quả tích cực 2]

### Negative Consequences

* [Hệ quả tiêu cực hoặc thỏa hiệp 1]

## Pros and Cons of the Options

### Option 1

* Good, because [lợi ích]
* Bad, because [nhược điểm]

### Option 2

* Good, because [lợi ích]
* Bad, because [nhược điểm]

## Links

* [Link tham khảo hoặc task liên quan]
`;

  await writeUtf8NoBomAtomic(filePath, template);

  const text = `================================================================================
   ĐÃ TẠO MỚI ARCHITECTURE DECISION RECORD (ADR)
================================================================================
 ID       : ${formattedId}
 File     : ${fileName}
 Đường dẫn: ${filePath}
 Tiêu đề  : ${titleText}
 Chuẩn    : MADR (Markdown Any Architectural Decision Records)
================================================================================`;

  return { id: formattedId, fileName, filePath, title: titleText, text };
}

export function getAdrHelp(): string {
  return `SỬ DỤNG: rea-kit adr [action] [id/title] [title]
  list                  : Liệt kê toàn bộ các bản ghi ADR và trạng thái (mặc định).
  show <id>             : Xem nội dung đầy đủ của một bản ghi ADR theo mã số hoặc tên.
  validate              : Kiểm tra tính tuân thủ cấu trúc chuẩn MADR cho tất cả ADR.
  status                : Thống kê số lượng ADR theo trạng thái (accepted, proposed,...).
  new [title]           : Tạo bản ghi ADR mới tiếp theo theo mẫu chuẩn MADR.
  help                  : Hiển thị hướng dẫn này.`;
}

/**
 * Universal dispatcher for ADR CLI actions.
 */
export async function runAdrAction(
  action: string = "list",
  args: { id?: string; title?: string; repoRoot?: string } = {}
): Promise<any> {
  const targetDir = args.repoRoot ? path.join(path.resolve(args.repoRoot), "docs", "adrs") : findAdrDir();
  switch ((action || "list").toLowerCase()) {
    case "list":
      return await listAdrs(targetDir);
    case "show":
      return await showAdr(args.id || "", targetDir);
    case "validate":
      return await validateAdrs(targetDir);
    case "status":
      return await getAdrStatus(targetDir);
    case "new":
      return await newAdr(args.id, args.title, targetDir);
    case "help":
      return { text: getAdrHelp() };
    default:
      throw new Error(`Unknown ADR action: '${action}'. Valid actions: list, show, validate, status, new, help.`);
  }
}
