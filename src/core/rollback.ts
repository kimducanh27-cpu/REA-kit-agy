import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { findRepoRoot, getWorkspacePaths } from "./workspace.js";

export interface SnapshotOptions {
  repoRoot?: string;
  buildDir?: string;
  backupDir?: string;
  maxSnapshots?: number;
}

export interface SnapshotManifestFile {
  path: string;
  sha256: string;
  bytes: number;
}

export interface SnapshotManifest {
  timestamp: string;
  snapshot_id: string;
  file_count: number;
  total_bytes: number;
  files: SnapshotManifestFile[];
}

export interface SnapshotResult {
  created: boolean;
  reason?: string;
  snapshotId?: string;
  snapshotDir?: string;
  fileCount?: number;
  totalBytes?: number;
  manifestPath?: string;
}

export interface RestoreOptions {
  repoRoot?: string;
  buildDir?: string;
  backupDir?: string;
  snapshotId?: string;
  force?: boolean;
}

export interface RestoreResult {
  restored: boolean;
  snapshotId: string;
  snapshotDir: string;
  fileCount: number;
}

const DEFAULT_EXCLUDED_NAMES = new Set([
  ".backup",
  ".gitkeep",
  ".gradle",
  "node_modules",
  "build",
]);

/**
 * Computes uppercase SHA-256 hash of a file on disk.
 */
export async function computeFileSha256(filePath: string): Promise<string> {
  const buffer = await fs.readFile(filePath);
  return crypto.createHash("sha256").update(buffer).digest("hex").toUpperCase();
}

/**
 * Safely removes a file or directory, handling symbolic links / reparse points
 * without deleting the target outside of the workspace.
 */
export async function removeSafeItem(itemPath: string): Promise<void> {
  try {
    const lstat = await fs.lstat(itemPath);
    if (lstat.isSymbolicLink()) {
      await fs.unlink(itemPath);
    } else if (lstat.isDirectory()) {
      await fs.rm(itemPath, { recursive: true, force: true });
    } else {
      await fs.unlink(itemPath);
    }
  } catch (err: any) {
    if (err.code !== "ENOENT") {
      throw err;
    }
  }
}

/**
 * Recursively copies items from srcDir to destDir, skipping excluded names and symlinks.
 */
async function copyDirClean(
  srcDir: string,
  destDir: string,
  excludedNames: Set<string>
): Promise<void> {
  await fs.mkdir(destDir, { recursive: true });
  const entries = await fs.readdir(srcDir, { withFileTypes: true });

  for (const entry of entries) {
    if (excludedNames.has(entry.name)) {
      continue;
    }
    if (entry.isSymbolicLink()) {
      continue;
    }

    const srcPath = path.join(srcDir, entry.name);
    const destPath = path.join(destDir, entry.name);

    if (entry.isDirectory()) {
      await copyDirClean(srcPath, destPath, excludedNames);
    } else if (entry.isFile()) {
      await fs.copyFile(srcPath, destPath);
    }
  }
}

/**
 * Recursively collects all regular files in a directory.
 */
async function getAllFiles(
  dir: string,
  baseDir: string = dir
): Promise<Array<{ fullPath: string; relPath: string; size: number }>> {
  const result: Array<{ fullPath: string; relPath: string; size: number }> = [];
  if (!fsSync.existsSync(dir)) return result;

  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isSymbolicLink()) continue;

    if (entry.isDirectory()) {
      const subFiles = await getAllFiles(fullPath, baseDir);
      result.push(...subFiles);
    } else if (entry.isFile()) {
      const stat = await fs.stat(fullPath);
      const relPath = path.relative(baseDir, fullPath).replace(/\\/g, "/");
      result.push({ fullPath, relPath, size: stat.size });
    }
  }
  return result;
}

/**
 * Generates timestamp string in yyyyMMdd_HHmmss_fff format.
 */
export function generateSnapshotTimestamp(date: Date = new Date()): string {
  const pad = (n: number, len = 2) => String(n).padStart(len, "0");
  const y = date.getFullYear();
  const m = pad(date.getMonth() + 1);
  const d = pad(date.getDate());
  const hh = pad(date.getHours());
  const mm = pad(date.getMinutes());
  const ss = pad(date.getSeconds());
  const fff = pad(date.getMilliseconds(), 3);
  return `${y}${m}${d}_${hh}${mm}${ss}_${fff}`;
}

/**
 * Creates an atomic snapshot of the development source directory (05_MA_NGUON_PHAT_TRIEN),
 * computes SHA-256 manifest.json, copies to backup directory (04_SAO_LUU_AN_TOAN/<timestamp>),
 * and enforces rotation of maxSnapshots.
 */
export async function createSnapshot(
  options?: SnapshotOptions
): Promise<SnapshotResult> {
  const repoRoot = options?.repoRoot
    ? path.resolve(options.repoRoot)
    : findRepoRoot();
  const paths = getWorkspacePaths(repoRoot);
  const buildDir = options?.buildDir ? path.resolve(options.buildDir) : paths.src;
  const backupDir = options?.backupDir
    ? path.resolve(options.backupDir)
    : paths.backup;
  const maxSnapshots = Math.max(1, options?.maxSnapshots ?? 10);

  if (!fsSync.existsSync(buildDir)) {
    await fs.mkdir(buildDir, { recursive: true });
  }

  // Scan items in buildDir to check if there are any real files
  const existingFiles = await getAllFiles(buildDir);
  const realFiles = existingFiles.filter(
    (f) => !DEFAULT_EXCLUDED_NAMES.has(path.basename(f.fullPath))
  );

  if (realFiles.length === 0) {
    return {
      created: false,
      reason: "No real source files in buildDir to backup (empty or only .gitkeep)",
    };
  }

  await fs.mkdir(backupDir, { recursive: true });

  const snapshotId = generateSnapshotTimestamp();
  const snapshotDir = path.join(backupDir, snapshotId);
  await fs.mkdir(snapshotDir, { recursive: true });

  // Copy non-excluded items to snapshotDir
  await copyDirClean(buildDir, snapshotDir, DEFAULT_EXCLUDED_NAMES);

  // Compute SHA-256 for all copied files (excluding manifest.json)
  const copiedFiles = await getAllFiles(snapshotDir);
  const manifestFiles: SnapshotManifestFile[] = [];
  let totalBytes = 0;

  for (const file of copiedFiles) {
    if (path.basename(file.fullPath) === "manifest.json") continue;
    const sha256 = await computeFileSha256(file.fullPath);
    manifestFiles.push({
      path: file.relPath,
      sha256,
      bytes: file.size,
    });
    totalBytes += file.size;
  }

  const manifest: SnapshotManifest = {
    timestamp: new Date().toISOString(),
    snapshot_id: snapshotId,
    file_count: manifestFiles.length,
    total_bytes: totalBytes,
    files: manifestFiles,
  };

  const manifestPath = path.join(snapshotDir, "manifest.json");
  await fs.writeFile(manifestPath, JSON.stringify(manifest, null, 2), "utf8");

  // Enforce rotation of maxSnapshots
  await rotateSnapshots(backupDir, maxSnapshots);

  return {
    created: true,
    snapshotId,
    snapshotDir,
    fileCount: manifestFiles.length,
    totalBytes,
    manifestPath,
  };
}

/**
 * Safely moves a file or directory, handling cross-device / EXDEV errors
 * by falling back to copyDirClean / copyFile + removeSafeItem.
 */
async function safeMove(src: string, dest: string): Promise<void> {
  try {
    await fs.rename(src, dest);
  } catch (err: any) {
    if (err.code === "EXDEV") {
      const stat = await fs.lstat(src);
      if (stat.isDirectory()) {
        await copyDirClean(src, dest, new Set());
        await removeSafeItem(src);
      } else {
        await fs.mkdir(path.dirname(dest), { recursive: true });
        await fs.copyFile(src, dest);
        await removeSafeItem(src);
      }
    } else {
      throw err;
    }
  }
}

/**
 * Enforces maximum snapshot retention limit by pruning older snapshots.
 */
async function rotateSnapshots(backupDir: string, maxSnapshots: number): Promise<void> {
  if (!fsSync.existsSync(backupDir)) return;

  const limit = Math.max(1, maxSnapshots);
  const entries = await fs.readdir(backupDir, { withFileTypes: true });
  const snapshotDirs = entries
    .filter((e) => e.isDirectory() && !e.name.startsWith("."))
    .map((e) => e.name)
    .sort()
    .reverse(); // Newest first

  if (snapshotDirs.length > limit) {
    const toRemove = snapshotDirs.slice(limit);
    for (const dirName of toRemove) {
      const dirPath = path.join(backupDir, dirName);
      await removeSafeItem(dirPath);
    }
  }
}

/**
 * Restores a snapshot into buildDir using a 2-phase atomic swap (.staging -> .safety -> buildDir)
 * after 100% SHA-256 two-way manifest verification.
 */
export async function restoreSnapshot(
  options?: RestoreOptions
): Promise<RestoreResult> {
  const repoRoot = options?.repoRoot
    ? path.resolve(options.repoRoot)
    : findRepoRoot();
  const paths = getWorkspacePaths(repoRoot);
  const buildDir = options?.buildDir ? path.resolve(options.buildDir) : paths.src;
  const primaryBackupDir = options?.backupDir
    ? path.resolve(options.backupDir)
    : paths.backup;
  const fallbackBackupDir = path.join(buildDir, ".backup");

  // Find candidate snapshot directories
  const candidateDirs: string[] = [];
  if (fsSync.existsSync(primaryBackupDir)) {
    candidateDirs.push(primaryBackupDir);
  }
  if (fsSync.existsSync(fallbackBackupDir) && fallbackBackupDir !== primaryBackupDir) {
    candidateDirs.push(fallbackBackupDir);
  }

  if (candidateDirs.length === 0) {
    throw new Error(`Backup directory not found at: ${primaryBackupDir}`);
  }

  // Collect valid snapshots across candidates
  interface SnapshotCandidate {
    snapshotId: string;
    dirPath: string;
    files: Array<{ fullPath: string; relPath: string; size: number }>;
  }

  const validSnapshots: SnapshotCandidate[] = [];

  for (const bDir of candidateDirs) {
    const entries = await fs.readdir(bDir, { withFileTypes: true });
    const dirNames = entries
      .filter((e) => e.isDirectory() && !e.name.startsWith("."))
      .map((e) => e.name)
      .sort()
      .reverse();

    for (const name of dirNames) {
      if (options?.snapshotId && name !== options.snapshotId) {
        continue;
      }
      const dirPath = path.join(bDir, name);
      const files = await getAllFiles(dirPath);
      const realFiles = files.filter(
        (f) =>
          path.basename(f.fullPath) !== ".gitkeep" &&
          path.basename(f.fullPath) !== "manifest.json"
      );
      if (realFiles.length > 0) {
        validSnapshots.push({ snapshotId: name, dirPath, files: realFiles });
      }
    }
  }

  if (validSnapshots.length === 0) {
    throw new Error(
      "No valid snapshots containing source files found (cannot restore empty snapshot)!"
    );
  }

  // Global snapshot sorting: Sort validSnapshots globally across all candidate directories descending
  validSnapshots.sort((a, b) => b.snapshotId.localeCompare(a.snapshotId));

  const targetSnapshot = validSnapshots[0];
  const snapshotDir = targetSnapshot.dirPath;
  const snapshotId = targetSnapshot.snapshotId;
  const activeBackupRoot = path.dirname(snapshotDir);

  // Strictly require valid manifest.json; reject restore if manifest is missing or invalid
  const manifestPath = path.join(snapshotDir, "manifest.json");
  if (!fsSync.existsSync(manifestPath)) {
    throw new Error(`Missing manifest.json in snapshot ${snapshotId}: restore rejected`);
  }

  let manifest: SnapshotManifest;
  try {
    const raw = await fs.readFile(manifestPath, "utf8");
    manifest = JSON.parse(raw);
    if (!manifest || !Array.isArray(manifest.files)) {
      throw new Error("manifest.json has invalid structure (missing files array)");
    }
  } catch (err: any) {
    throw new Error(`Invalid manifest.json in snapshot ${snapshotId}: ${err.message}`);
  }

  // PHASE 1: Prepare staging directory
  const stagingUid = crypto.randomUUID().replace(/-/g, "");
  const stagingDir = path.join(activeBackupRoot, `.staging_${stagingUid}`);
  await fs.mkdir(stagingDir, { recursive: true });

  const safetyUid = crypto.randomUUID().replace(/-/g, "");
  const safetyDir = path.join(activeBackupRoot, `.safety_${safetyUid}`);

  try {
    // Copy snapshot contents to staging directory (excluding manifest.json)
    await copyDirClean(
      snapshotDir,
      stagingDir,
      new Set(["manifest.json"])
    );

    // Verify 100% two-way matching between staging files and manifest.files
    const stagedFiles = await getAllFiles(stagingDir);
    const stagedFileMap = new Map<string, string>(); // relPath -> fullPath
    for (const sf of stagedFiles) {
      stagedFileMap.set(sf.relPath.replace(/\\/g, "/"), sf.fullPath);
    }

    const manifestPathSet = new Set<string>();

    for (const mf of manifest.files) {
      const normPath = mf.path.replace(/\\/g, "/");
      manifestPathSet.add(normPath);
      const stagedFilePath = stagedFileMap.get(normPath);
      if (!stagedFilePath || !fsSync.existsSync(stagedFilePath)) {
        throw new Error(`Missing file during staging verification: ${mf.path}`);
      }
      const stagedHash = await computeFileSha256(stagedFilePath);
      if (stagedHash.toUpperCase() !== mf.sha256.toUpperCase()) {
        throw new Error(
          `SHA-256 hash mismatch at file: ${mf.path} (Expected: ${mf.sha256}, Actual: ${stagedHash})`
        );
      }
    }

    // Two-way match: ensure no extraneous files exist in staging that are not in manifest
    for (const stagedRelPath of stagedFileMap.keys()) {
      if (!manifestPathSet.has(stagedRelPath)) {
        throw new Error(
          `Extraneous file in staging not listed in manifest.json: ${stagedRelPath}`
        );
      }
    }

    // PHASE 2: 2-Phase Atomic Swap
    await fs.mkdir(safetyDir, { recursive: true });

    // Move current items in buildDir to safetyDir (except excluded)
    if (fsSync.existsSync(buildDir)) {
      const currentEntries = await fs.readdir(buildDir, { withFileTypes: true });
      for (const entry of currentEntries) {
        if (DEFAULT_EXCLUDED_NAMES.has(entry.name)) continue;

        const currentPath = path.join(buildDir, entry.name);
        const safetyPath = path.join(safetyDir, entry.name);

        if (entry.isSymbolicLink()) {
          await fs.unlink(currentPath);
        } else {
          await safeMove(currentPath, safetyPath);
        }
      }
    } else {
      await fs.mkdir(buildDir, { recursive: true });
    }

    // Move staged items into buildDir
    const stagedEntries = await fs.readdir(stagingDir, { withFileTypes: true });
    for (const entry of stagedEntries) {
      const srcPath = path.join(stagingDir, entry.name);
      const destPath = path.join(buildDir, entry.name);
      await safeMove(srcPath, destPath);
    }

    // Clean up temporary safety and staging directories
    await removeSafeItem(safetyDir);
    await removeSafeItem(stagingDir);

    const restoredFiles = await getAllFiles(buildDir);
    const count = restoredFiles.filter(
      (f) => !DEFAULT_EXCLUDED_NAMES.has(path.basename(f.fullPath))
    ).length;

    return {
      restored: true,
      snapshotId,
      snapshotDir,
      fileCount: count,
    };
  } catch (err: any) {
    // Rollback atomic swap if safetyDir exists
    if (fsSync.existsSync(safetyDir)) {
      try {
        const savedEntries = await fs.readdir(safetyDir, { withFileTypes: true });
        for (const s of savedEntries) {
          const savedPath = path.join(safetyDir, s.name);
          const restorePath = path.join(buildDir, s.name);
          try {
            await safeMove(savedPath, restorePath);
          } catch {
            // Ignore error during recovery move
          }
        }
        await removeSafeItem(safetyDir);
      } catch {
        // Best-effort cleanup
      }
    }

    if (fsSync.existsSync(stagingDir)) {
      await removeSafeItem(stagingDir);
    }

    throw err;
  }
}
