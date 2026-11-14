import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import {
  findAdrDir,
  getAdrList,
  listAdrs,
  showAdr,
  validateAdrs,
  getAdrStatus,
  newAdr,
  transitionAdr,
  getAdrHelp,
  runAdrAction,
} from "../src/core/adr.js";

describe("Work Stream 3: ADR Management Engine & MADR Compliance", () => {
  let testDir: string;
  let adrDir: string;

  beforeEach(async () => {
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "rea-adr-test-"));
    adrDir = path.join(testDir, "docs", "adrs");
    await fs.mkdir(adrDir, { recursive: true });
  });

  afterEach(async () => {
    try {
      await fs.rm(testDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup error
    }
  });

  it("01 - list: Empty ADR directory returns 0 records and informative text", async () => {
    const listRes = await listAdrs(adrDir);
    expect(listRes.records).toHaveLength(0);
    expect(listRes.text).toContain("Chưa có bản ghi ADR nào");
  });

  it("02 - new: Generates compliant MADR records with auto-incremented 4-digit ID and slug", async () => {
    // Create first ADR
    const adr1 = await newAdr("Decouple Storage Provider", undefined, adrDir);
    expect(adr1.id).toBe("0001");
    expect(adr1.fileName).toBe("0001-decouple-storage-provider.md");
    expect(adr1.filePath).toBe(path.join(adrDir, "0001-decouple-storage-provider.md"));

    const content1 = await fs.readFile(adr1.filePath, "utf8");
    expect(content1).toContain("# Decouple Storage Provider");
    expect(content1).toContain("- Status: proposed");
    expect(content1).toMatch(/- Date: \d{4}-\d{2}-\d{2}/);
    expect(content1).toContain("## Context and Problem Statement");
    expect(content1).toContain("## Decision Drivers");
    expect(content1).toContain("## Considered Options");
    expect(content1).toContain("## Decision Outcome");
    expect(content1).toContain("### Positive Consequences");
    expect(content1).toContain("### Negative Consequences");
    expect(content1).toContain("## Pros and Cons of the Options");
    expect(content1).toContain("## Links");

    // Create second ADR with Vietnamese diacritics
    const adr2 = await newAdr("Tối ưu hóa hiệu năng và bộ nhớ đệm", undefined, adrDir);
    expect(adr2.id).toBe("0002");
    expect(adr2.fileName).toBe("0002-toi-uu-hoa-hieu-nang-va-bo-nho-dem.md");

    // List should now return 2 records
    const listRes = await listAdrs(adrDir);
    expect(listRes.records).toHaveLength(2);
    expect(listRes.records[0].id).toBe("0001");
    expect(listRes.records[0].status).toBe("proposed");
    expect(listRes.records[1].id).toBe("0002");
    expect(listRes.records[1].title).toBe("Tối ưu hóa hiệu năng và bộ nhớ đệm");
  });

  it("03 - validate: Successfully validates valid MADR records and catches violations", async () => {
    // Generate valid records
    await newAdr("First Architecture Decision", undefined, adrDir);
    await newAdr("Second Architecture Decision", undefined, adrDir);

    const validRes = await validateAdrs(adrDir);
    expect(validRes.valid).toBe(true);
    expect(validRes.score).toBe(2);
    expect(validRes.total).toBe(2);
    expect(validRes.text).toContain("HOÀN HẢO! Toàn bộ 2/2 bản ghi ADR đạt chuẩn cấu trúc MADR.");

    // Create an invalid ADR missing Status
    const badFile1 = path.join(adrDir, "0003-invalid-missing-status.md");
    await fs.writeFile(
      badFile1,
      `# Invalid Decision 3

- Deciders: Architects
- Date: 2026-11-14

## Context and Problem Statement
Missing status field here.

## Decision Drivers
* Driver 1

## Considered Options
* Opt 1

## Decision Outcome
* Opt 1

## Pros and Cons of the Options
* Good

## Links
* none
`,
      "utf8"
    );

    const failRes1 = await validateAdrs(adrDir);
    expect(failRes1.valid).toBe(false);
    expect(failRes1.errors["0003"]).toBeDefined();
    expect(failRes1.errors["0003"].some((e) => e.includes("Trường '- Status:'"))).toBe(true);

    // Fix status to an invalid value
    await fs.writeFile(
      badFile1,
      `# Invalid Decision 3

- Status: UNKNOWN_STATUS
- Date: 2026-11-14

## Context and Problem Statement
Context...

## Decision Drivers
* Driver 1

## Considered Options
* Opt 1

## Decision Outcome
* Opt 1

## Pros and Cons of the Options
* Good

## Links
* none
`,
      "utf8"
    );

    const failRes2 = await validateAdrs(adrDir);
    expect(failRes2.valid).toBe(false);
    expect(failRes2.errors["0003"].some((e) => e.includes("không hợp lệ"))).toBe(true);

    // Test duplicate ID detection
    const dupFile = path.join(adrDir, "0001-duplicate-first.md");
    await fs.writeFile(dupFile, (await fs.readFile(badFile1, "utf8")).replace("UNKNOWN_STATUS", "proposed"), "utf8");

    const failRes3 = await validateAdrs(adrDir);
    expect(failRes3.valid).toBe(false);
    expect(failRes3.errors["0001"].some((e) => e.includes("trùng lặp mã ID ADR '0001'"))).toBe(true);
  });

  it("04 - show: Locates and outputs full content by integer or zero-padded ID", async () => {
    await newAdr("Modular Dependency Injection", undefined, adrDir);

    // Show using zero-padded "0001"
    const show1 = await showAdr("0001", adrDir);
    expect(show1.record.title).toBe("Modular Dependency Injection");
    expect(show1.content).toContain("# Modular Dependency Injection");
    expect(show1.text).toContain("CHI TIẾT ADR: 0001-modular-dependency-injection.md");

    // Show using single integer "1"
    const show2 = await showAdr("1", adrDir);
    expect(show2.record.id).toBe("0001");
    expect(show2.content).toBe(show1.content);

    // Show using 'ADR-0001' or 'adr-1' with prefix stripping
    const show3 = await showAdr("ADR-0001", adrDir);
    expect(show3.record.id).toBe("0001");
    expect(show3.content).toBe(show1.content);

    const show4 = await showAdr("adr-1", adrDir);
    expect(show4.record.id).toBe("0001");
    expect(show4.content).toBe(show1.content);

    // Non-existent ID throws error
    await expect(showAdr("9999", adrDir)).rejects.toThrow(/Không tìm thấy ADR/);
  });

  it("05 - status: Aggregates counts correctly by status", async () => {
    const adr1 = await newAdr("ADR 1", undefined, adrDir);
    const adr2 = await newAdr("ADR 2", undefined, adrDir);

    // Update status of ADR 1 to ACCEPTED
    const full1 = path.join(adrDir, adr1.fileName);
    const c1 = await fs.readFile(full1, "utf8");
    await fs.writeFile(full1, c1.replace("Status: proposed", "Status: accepted"), "utf8");

    const st = await getAdrStatus(adrDir);
    expect(st.total).toBe(2);
    expect(st.counts["accepted"]).toBe(1);
    expect(st.counts["proposed"]).toBe(1);
    expect(st.text).toContain("ACCEPTED    : 1");
    expect(st.text).toContain("PROPOSED    : 1");
  });

  it("06 - runAdrAction & help: Dispatcher works across all actions", async () => {
    const helpRes = await runAdrAction("help", { repoRoot: testDir });
    expect(helpRes.text).toContain("SỬ DỤNG: rea-kit adr");

    const newRes = await runAdrAction("new", { id: "Global Cache Layer", repoRoot: testDir });
    expect(newRes.id).toBe("0001");

    const listRes = await runAdrAction("list", { repoRoot: testDir });
    expect(listRes.records).toHaveLength(1);

    const valRes = await runAdrAction("validate", { repoRoot: testDir });
    expect(valRes.valid).toBe(true);

    const statusRes = await runAdrAction("status", { repoRoot: testDir });
    expect(statusRes.total).toBe(1);

    const transRes = await runAdrAction("transition", {
      id: "ADR-0001",
      status: "accepted",
      repoRoot: testDir,
    });
    expect(transRes.newStatus).toBe("accepted");

    await expect(runAdrAction("unknown-action", { repoRoot: testDir })).rejects.toThrow(/Unknown ADR action/);
  });

  it("07 - prefix stripping in newAdr: Strips ADR- prefix when explicit ID is passed", async () => {
    const customAdr = await newAdr("ADR-0010", "Custom Architecture Plan", adrDir);
    expect(customAdr.id).toBe("0010");
    expect(customAdr.fileName).toBe("0010-custom-architecture-plan.md");
  });

  it("08 - transitionAdr: Supports MADR status transitions and records superseding links", async () => {
    const adr1 = await newAdr("Initial Database Selection", undefined, adrDir);
    const adr2 = await newAdr("Migrate to Distributed Database", undefined, adrDir);

    expect(adr1.id).toBe("0001");
    expect(adr2.id).toBe("0002");

    // Transition 0001 from proposed to accepted
    const t1 = await transitionAdr("0001", "ACCEPTED", { targetAdrDir: adrDir });
    expect(t1.oldStatus.toLowerCase()).toBe("proposed");
    expect(t1.newStatus).toBe("accepted");

    const showAfterT1 = await showAdr("0001", adrDir);
    expect(showAfterT1.record.status.toLowerCase()).toBe("accepted");

    // Transition 0001 from accepted to superseded by 0002
    const t2 = await transitionAdr("ADR-0001", "SUPERSEDED", {
      supersededBy: "ADR-0002",
      reason: "Distributed database scaling requirements",
      targetAdrDir: adrDir,
    });
    expect(t2.oldStatus.toLowerCase()).toBe("accepted");
    expect(t2.newStatus).toBe("superseded");

    const showAfterT2 = await showAdr("0001", adrDir);
    expect(showAfterT2.record.status.toLowerCase()).toBe("superseded");
    expect(showAfterT2.content).toContain("* Superseded by [ADR-0002]");
    expect(showAfterT2.content).toContain("* Reason for transition: Distributed database scaling requirements");

    // Reciprocal bidirectional link verification: ADR-0002 should link back to ADR-0001
    const showAdr2 = await showAdr("ADR_0002", adrDir);
    expect(showAdr2.content).toContain("* Supersedes [ADR-0001]");

    // Both ADRs must remain compliant with MADR validation
    const valRes = await validateAdrs(adrDir);
    expect(valRes.valid).toBe(true);
    expect(valRes.score).toBe(2);
  });
});
