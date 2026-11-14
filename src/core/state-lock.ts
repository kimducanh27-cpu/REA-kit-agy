import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";

export const STALE_LOCK_TIMEOUT_MS = 10_000;
export const MAX_LOCK_RETRIES = 50;

/**
 * Executes an async function while holding an exclusive file lock.
 * Employs retry backoff (50 retries, 100-200ms) and automatically clears stale locks (>10s).
 */
export async function withFileLock<T>(
  filePath: string,
  fn: () => Promise<T>
): Promise<T> {
  const lockPath = `${filePath}.lock`;
  const pid = process.pid.toString();
  const lockToken = crypto.randomUUID();
  let acquired = false;

  for (let attempt = 0; attempt <= MAX_LOCK_RETRIES; attempt++) {
    try {
      // 'wx' flag ensures atomic creation; fails if file already exists
      const handle = await fs.open(lockPath, "wx");
      await handle.writeFile(`${lockToken}\n${pid}\n${Date.now()}\n`, "utf8");
      await handle.close();
      acquired = true;
      break;
    } catch (err: unknown) {
      const code = (err as NodeJS.ErrnoException).code;
      const isLocked = code === "EEXIST" || code === "EPERM" || code === "EBUSY";
      if (!isLocked) {
        throw err;
      }

      // Check for stale lock
      try {
        const stat = await fs.stat(lockPath);
        const age = Date.now() - stat.mtimeMs;

        let isPidAlive = true;
        let lockPid: number | null = null;
        try {
          const content = await fs.readFile(lockPath, "utf8");
          const lines = content.trim().split("\n");
          // Support lockToken\npid\ntimestamp or pid\ntimestamp
          const pidStr = lines.length >= 3 ? lines[1] : lines[0];
          const parsedPid = parseInt(pidStr?.trim(), 10);
          if (!isNaN(parsedPid) && parsedPid > 0) {
            lockPid = parsedPid;
            try {
              process.kill(parsedPid, 0);
            } catch (kErr: any) {
              if (kErr.code === "ESRCH") {
                isPidAlive = false;
              }
            }
          }
        } catch {
          // If reading fails, ignore
        }

        // Check PID liveness before clearing stale lock
        const isStale = !isPidAlive || age > STALE_LOCK_TIMEOUT_MS;
        if (isStale) {
          try {
            await fs.unlink(lockPath);
          } catch {
            // Unlink may race with another process; ignore error
          }
        }
      } catch {
        // Stat could fail if lock was just released; ignore
      }

      if (attempt === MAX_LOCK_RETRIES) {
        throw new Error(
          `Failed to acquire file lock on ${lockPath} after ${MAX_LOCK_RETRIES} retries`
        );
      }

      // Backoff jitter between 100ms and 200ms
      const delay = Math.floor(100 + Math.random() * 100);
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  if (!acquired) {
    throw new Error(`Failed to acquire file lock on ${lockPath}`);
  }

  try {
    return await fn();
  } finally {
    try {
      // Compare-and-delete: only unlink if token matches lockToken
      const content = await fs.readFile(lockPath, "utf8");
      const lines = content.trim().split("\n");
      const currentToken = lines[0]?.trim();
      if (currentToken === lockToken) {
        await fs.unlink(lockPath);
      }
    } catch {
      // Best-effort cleanup
    }
  }
}

/**
 * Writes content to targetPath atomically via a temporary file without UTF-8 BOM.
 * Includes 5 retries with 30ms backoff on EBUSY / EPERM for Windows indexer resilience.
 */
export async function writeUtf8NoBomAtomic(
  targetPath: string,
  content: string
): Promise<void> {
  const cleanContent = content.charCodeAt(0) === 0xfeff ? content.slice(1) : content;
  const targetDir = path.dirname(targetPath);
  await fs.mkdir(targetDir, { recursive: true });

  const tempFileName = `.${path.basename(targetPath)}.tmp.${crypto.randomUUID()}`;
  const tempPath = path.join(targetDir, tempFileName);

  try {
    // Write buffer without BOM explicitly
    await fs.writeFile(tempPath, Buffer.from(cleanContent, "utf8"));

    const MAX_RENAME_RETRIES = 5;
    for (let attempt = 0; attempt <= MAX_RENAME_RETRIES; attempt++) {
      try {
        await fs.rename(tempPath, targetPath);
        break;
      } catch (rErr: any) {
        const isLockError = rErr.code === "EBUSY" || rErr.code === "EPERM";
        if (isLockError && attempt < MAX_RENAME_RETRIES) {
          await new Promise((resolve) => setTimeout(resolve, 30));
        } else {
          throw rErr;
        }
      }
    }
  } catch (err) {
    try {
      await fs.unlink(tempPath);
    } catch {
      // Ignore cleanup error
    }
    throw err;
  }
}

/**
 * Atomically appends an event line to .agents/state/events.jsonl inside a file lock.
 */
export async function appendEventAtomic(
  repoRoot: string,
  event: Record<string, unknown>
): Promise<void> {
  const stateDir = path.join(repoRoot, ".agents", "state");
  await fs.mkdir(stateDir, { recursive: true });

  const eventsFile = path.join(stateDir, "events.jsonl");

  await withFileLock(eventsFile, async () => {
    const payload = {
      timestamp: event.timestamp || new Date().toISOString(),
      ...event,
    };
    const line = JSON.stringify(payload) + "\n";
    await fs.appendFile(eventsFile, Buffer.from(line, "utf8"));
  });
}
