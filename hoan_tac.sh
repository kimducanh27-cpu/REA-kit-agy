#!/usr/bin/env bash
# Script Hoàn Tác Mã Nguồn 1-Click (1-Click Atomic Rollback cho Linux / macOS)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================================="
echo "  XÁC NHẬN HOÀN TÁC ỨNG DỤNG (1-CLICK ATOMIC ROLLBACK)"
echo "=========================================================="
echo "Bạn có chắc chắn muốn hoàn tác về bản snapshot gần nhất?"
read -r -p "Nhấn 'Y' để tiếp tục hoàn tác, hoặc 'N' để hủy [y/N]: " confirm

case "$confirm" in
    [yY][eE][sS]|[yY])
        echo "[*] Bắt đầu hoàn tác..."
        ;;
    *)
        echo "[*] Đã hủy thao tác hoàn tác."
        exit 0
        ;;
esac

if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -File "$SCRIPT_DIR/.agents/scripts/rollback.ps1" -Force
    exit $?
else
    echo "[!] Không tìm thấy 'pwsh' (PowerShell Core)."
    echo "    Vui lòng cài đặt 'pwsh' để thực thi rollback.ps1 có xác thực mã băm SHA-256 an toàn."
    latest_backup=$(find "$SCRIPT_DIR/04_SAO_LUU_AN_TOAN" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r | head -n 1 || true)
    if [ -n "$latest_backup" ] && [ -d "$latest_backup" ]; then
        echo "    GỢI Ý KHÔI PHỤC THỦ CÔNG:"
        echo "    Bản sao lưu mới nhất phát hiện tại: $latest_backup"
        echo "    Bạn có thể sao chép dữ liệu từ thư mục trên về 05_MA_NGUON_PHAT_TRIEN/."
    else
        echo "    Không tìm thấy thư mục snapshot nào trong 04_SAO_LUU_AN_TOAN/."
    fi
    exit 1
fi
