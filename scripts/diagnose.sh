#!/usr/bin/env bash
# 诊断: 找出链接报错里那些 oplus/qcom 私有符号到底定义在哪、被哪一层 Makefile/Kconfig 挡住了
# 用法: ./scripts/diagnose.sh (在 setup.sh 之后, build.sh 之前运行)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"
source configs/kernel_source.env
source configs/toolchain.env

cd kernel_source
export PATH="${PATH}:${ROOT_DIR}/${TOOLCHAIN_DIR}/bin"

echo "===================================================="
echo "=== 先生成一次 .config,方便后面查 CONFIG 开关状态 ==="
make O=out ARCH="${KERNEL_ARCH}" CC="${CC}" CLANG_TRIPLE="${CLANG_TRIPLE}" \
  CROSS_COMPILE="${CROSS_COMPILE}" CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}" \
  ${KERNEL_DEFCONFIG} ${KERNEL_DEFCONFIG_FRAGMENTS} > /dev/null 2>&1 || echo "(defconfig 生成失败,忽略,继续诊断)"

# 关键几个符号所在的目录,顺着往上查每一层 Makefile 是怎么把这个目录/文件包含进来的
declare -A SYMBOL_DIR=(
  ["get_boot_mode"]="drivers/power/oplus/charger_ic"
  ["oplus_gauge_init"]="drivers/power/oplus"
  ["switch_to_otg_mode"]="drivers/power/oplus"
  ["msm_drm_notifier_call_chain"]="techpack/display/oplus"
)

for sym in "${!SYMBOL_DIR[@]}"; do
  dir="${SYMBOL_DIR[$sym]}"
  echo "===================================================="
  echo "=== 符号 ${sym} 所在目录: ${dir} ==="
  cur="${dir}"
  # 从该目录开始,一路往上查每一级的 Makefile 里跟这个子目录名相关的行
  while [ "${cur}" != "." ] && [ -n "${cur}" ]; do
    parent="$(dirname "${cur}")"
    childname="$(basename "${cur}")"
    if [ -f "${parent}/Makefile" ]; then
      echo "--- ${parent}/Makefile 里跟 '${childname}' 相关的行 ---"
      grep -n "${childname}" "${parent}/Makefile" 2>/dev/null || echo "  (没找到,可能是通过 Kconfig 目录里的其它机制引入的)"
    fi
    if [ -f "${parent}/Kconfig" ]; then
      echo "--- ${parent}/Kconfig 里跟 '${childname}' 相关的行 ---"
      grep -n -i "${childname}" "${parent}/Kconfig" 2>/dev/null || true
    fi
    cur="${parent}"
  done
done

echo "===================================================="
echo "=== 当前 .config 里 OPLUS/OPPO 相关开关状态 ==="
if [ -f out/.config ]; then
  grep -i "config_oplus\|config_oppo" out/.config | head -60
else
  echo "(out/.config 不存在,defconfig 生成可能失败了,往上翻看报错)"
fi