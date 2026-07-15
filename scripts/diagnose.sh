#!/usr/bin/env bash
# 诊断: 找出链接报错里那些 oplus/qcom 私有符号到底定义在哪、被哪个 Kconfig 控制
# 用法: ./scripts/diagnose.sh (在 setup.sh 之后, build.sh 之前运行)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}/kernel_source"

SYMBOLS=(get_project get_boot_mode is_project get_PCB_Version msm_drm_notifier_call_chain oplus_gauge_init switch_to_otg_mode)

for sym in "${SYMBOLS[@]}"; do
  echo "===================================================="
  echo "=== 符号: ${sym} ==="
  echo "--- 定义位置(带函数体/EXPORT_SYMBOL的那处) ---"
  grep -rn "^\(int\|void\|bool\|static\).*\b${sym}\b(" --include=*.c . 2>/dev/null | grep -v "^\./scripts" | head -5 || echo "(没搜到定义,可能真的不在这份源码树里)"
  echo "--- 所在文件所属目录的 Kconfig/Makefile 情况 ---"
  DEF_FILE=$(grep -rl "^\(int\|void\|bool\|static\).*\b${sym}\b(" --include=*.c . 2>/dev/null | grep -v "^\./scripts" | head -1 || true)
  if [ -n "${DEF_FILE:-}" ]; then
    echo "定义所在文件: ${DEF_FILE}"
    DEF_DIR=$(dirname "${DEF_FILE}")
    echo "--- ${DEF_DIR}/Makefile 相关行 ---"
    grep -n "$(basename "${DEF_FILE}" .c)" "${DEF_DIR}/Makefile" 2>/dev/null || echo "(该目录 Makefile 里没找到这个文件名,可能被上一级目录的条件包含)"
  fi
done

echo "===================================================="
echo "=== 当前 .config 里 oplus/oppo 相关开关状态(节选) ==="
if [ -f out/.config ]; then
  grep -i "oplus\|oppo" out/.config | head -40
else
  echo "(out/.config 还不存在,请先跑一次 defconfig 生成)"
fi