#!/usr/bin/env bash
# Script Kiểm Tra Sức Khỏe Toàn Diện REA-kit-agy (Linux / macOS)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Thiết lập thư mục tạm độc lập (TMPDIR/TEMP/TMP) cho môi trường Unix
export TMPDIR="${TMPDIR:-/tmp}"
export TEMP="$TMPDIR"
export TMP="$TMPDIR"

echo "=========================================================="
echo "  KIỂM TRA SỨC KHỎE HỆ THỐNG REA-KIT-AGY (HEALTH CHECK)"
echo "=========================================================="

if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -File "$SCRIPT_DIR/.agents/scripts/health_check.ps1"
    exit $?
else
    echo "[!] Không tìm thấy 'pwsh' (PowerShell Core). Chạy kiểm tra tĩnh cơ bản..."
    PASSED=0
    TOTAL=6

    # 1. Cấu trúc 5 thư mục số
    if [ -d "01_THA_APP_VAO_DAY" ] && [ -d "02_YEU_CAU_CUA_TOI" ] && [ -d "03_KET_QUA_KIEM_TRA" ] && [ -d "04_SAO_LUU_AN_TOAN" ] && [ -d "05_MA_NGUON_PHAT_TRIEN" ]; then
        echo "[OK] 1/6: Cấu trúc 5 thư mục số đạt chuẩn."
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] 1/6: Thiếu các thư mục số tiêu chuẩn."
    fi

    # 2. Máy trạng thái active_case.json
    if [ -f ".agents/state/active_case.json" ]; then
        echo "[OK] 2/6: Máy trạng thái active_case.json tồn tại."
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] 2/6: Thiếu .agents/state/active_case.json."
    fi

    # 3. Upstream REA
    if [ -f "UPSTREAMS.md" ]; then
        echo "[OK] 3/6: Upstream REA registry UPSTREAMS.md tồn tại."
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] 3/6: Thiếu UPSTREAMS.md."
    fi

    # 4. Bộ tài liệu quản trị
    if [ -f "AGENTS.md" ] && [ -f "REVIEW.md" ] && [ -f "HUONG_DAN_SU_DUNG.md" ]; then
        echo "[OK] 4/6: Bộ tài liệu AGENTS.md, REVIEW.md, HUONG_DAN_SU_DUNG.md đầy đủ."
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] 4/6: Thiếu tài liệu quản trị cốt lõi."
    fi

    # 5. Bộ Prompts và Templates
    if [ -d "prompts" ] && [ -d "templates" ]; then
        echo "[OK] 5/6: Thư mục prompts và templates sẵn sàng."
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] 5/6: Thiếu prompts hoặc templates."
    fi

    # 6. Scripts tự động hóa
    if [ -f ".agents/scripts/gate.ps1" ] && [ -f ".agents/scripts/rollback.ps1" ]; then
        echo "[OK] 6/6: Bộ scripts .agents/scripts/ đầy đủ."
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] 6/6: Thiếu scripts trong .agents/scripts/."
    fi

    echo "----------------------------------------------------------"
    echo "Kết quả kiểm tra cơ bản: $PASSED/$TOTAL tiêu chí hợp lệ."
    if [ "$PASSED" -eq "$TOTAL" ]; then
        echo "[OK] Khuyến nghị cài đặt 'pwsh' để chạy kiểm tra toàn diện và máy trạng thái Gate."
        exit 0
    else
        echo "[FAIL] Vui lòng bổ sung các tệp còn thiếu."
        exit 1
    fi
fi
