import fs from "node:fs";
import path from "node:path";

export interface WorkspacePaths {
  root: string;
  inbox: string;
  spec: string;
  report: string;
  backup: string;
  src: string;
  state: string;
  context: string;
  templates: string;
  docs: string;
  rules: string;
  skills: string;
  scripts: string;
}

/**
 * Locates the workspace root directory by traversing upwards from startDir
 * until docs/WORKFLOW_LIFECYCLE.md or .git is found.
 */
export function findRepoRoot(startDir?: string): string {
  let current = path.resolve(startDir || process.cwd());

  while (current) {
    const lifecycleFile = path.join(current, "docs", "WORKFLOW_LIFECYCLE.md");
    const gitDir = path.join(current, ".git");

    if (fs.existsSync(lifecycleFile) || fs.existsSync(gitDir)) {
      return current;
    }

    const parent = path.dirname(current);
    if (parent === current || !parent) {
      break;
    }
    current = parent;
  }

  return path.resolve(startDir || process.cwd());
}

/**
 * Resolves standard workspace directories relative to the repository root.
 */
export function getWorkspacePaths(root: string): WorkspacePaths {
  const resolvedRoot = path.resolve(root);
  return {
    root: resolvedRoot,
    inbox: path.join(resolvedRoot, "01_THA_APP_VAO_DAY"),
    spec: path.join(resolvedRoot, "02_YEU_CAU_CUA_TOI"),
    report: path.join(resolvedRoot, "03_KET_QUA_KIEM_TRA"),
    backup: path.join(resolvedRoot, "04_SAO_LUU_AN_TOAN"),
    src: path.join(resolvedRoot, "05_MA_NGUON_PHAT_TRIEN"),
    state: path.join(resolvedRoot, ".agents", "state"),
    context: path.join(resolvedRoot, ".agents", "context"),
    templates: path.join(resolvedRoot, "templates"),
    docs: path.join(resolvedRoot, "docs"),
    rules: path.join(resolvedRoot, ".agents", "rules"),
    skills: path.join(resolvedRoot, ".agents", "skills"),
    scripts: path.join(resolvedRoot, ".agents", "scripts"),
  };
}
