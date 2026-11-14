#!/usr/bin/env bash
# Script Kiểm Tra Mã Nguồn & Định Danh Rủi Ro (Deterministic Verification & Automated Risk Classifier)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Thiết lập thư mục tạm độc lập (TMPDIR/TEMP/TMP) cho môi trường Unix
export TMPDIR="${TMPDIR:-/tmp}"
export TEMP="$TMPDIR"
export TMP="$TMPDIR"

echo "=========================================================="
echo "  KIỂM TRA MÃ NGUỒN & ĐỊNH DANH RỦI RO (REA-KIT VERIFY)"
echo "=========================================================="

# 1. Ưu tiên Node CLI (dist/cli.js verify)
if [ -f "$SCRIPT_DIR/dist/cli.js" ] && command -v node >/dev/null 2>&1; then
    node "$SCRIPT_DIR/dist/cli.js" verify "$@"
    exit $?
fi

# 2. Fallback về PowerShell Core (pwsh) hoặc PowerShell nếu có
if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -File "$SCRIPT_DIR/.agents/scripts/verify_code.ps1" "$@"
    exit $?
elif command -v powershell >/dev/null 2>&1; then
    powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/.agents/scripts/verify_code.ps1" "$@"
    exit $?
else
    echo "[!] Không tìm thấy node runtime hoặc PowerShell (pwsh/powershell)."
    echo "    Vui lòng cài đặt Node.js và biên dịch 'npm run build' hoặc cài pwsh để chạy kiểm tra."
    exit 1
fi
