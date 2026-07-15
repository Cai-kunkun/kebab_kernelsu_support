#!/usr/bin/env bash
# 编译内核 (stage1: 仅原生编译,不含 KernelSU/SUSFS)
# 用法: ./scripts/build.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source configs/kernel_source.env
source configs/toolchain.env


if [ ! -d "kernel_source" ]; then
  echo "错误: kernel_source 不存在,请先运行 ./scripts/setup.sh"
  exit 1
fi


# 注意: toolchain 放在 PATH 最后面,不要放最前面!
# proton-clang 自带未加前缀的老版本 ld/as/ar,
# 如果放在 PATH 最前面会覆盖系统 ld,
# 导致编译 host 工具失败。

export PATH="${PATH}:${ROOT_DIR}/${TOOLCHAIN_DIR}/bin"

export HOSTCC=gcc
export HOSTCXX=g++
export HOSTLD=ld

export ARCH="${KERNEL_ARCH}"
export SUBARCH="${KERNEL_ARCH}"

export CC="${CC}"
export CLANG_TRIPLE="${CLANG_TRIPLE}"
export CROSS_COMPILE="${CROSS_COMPILE}"
export CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}"


cd kernel_source


echo "=== 禁用不兼容的 schgm-flash 驱动 ==="

if [ -f drivers/power/supply/qcom/Makefile ]; then
  sed -i '/schgm-flash\.o/d' drivers/power/supply/qcom/Makefile
fi



echo "=== 合并 Stage1 fragment ==="

FRAGMENT_FILE="../configs/kebab_stage1.fragment"

if [ ! -f "${FRAGMENT_FILE}" ]; then
  echo "错误: ${FRAGMENT_FILE} 不存在"
  exit 1
fi


if [ ! -f scripts/kconfig/merge_config.sh ]; then
  echo "错误: scripts/kconfig/merge_config.sh 不存在"
  exit 1
fi


bash scripts/kconfig/merge_config.sh \
  -m \
  -O out \
  arch/arm64/configs/${KERNEL_DEFCONFIG} \
  "${FRAGMENT_FILE}"


echo "=== 更新最终配置 ==="

make \
  O=out \
  ARCH="${ARCH}" \
  CC="${CC}" \
  CLANG_TRIPLE="${CLANG_TRIPLE}" \
  CROSS_COMPILE="${CROSS_COMPILE}" \
  CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}" \
  olddefconfig



echo "=== 当前 Stage1 配置确认 ==="

grep -E \
  "CONFIG_OPLUS_SM8250_CHARGER|CONFIG_OPLUS_FINGERPRINT|CONFIG_TOUCHPANEL_OPLUS" \
  out/.config || true



echo "=== 开始编译 Image ==="


# Android 4.19 Oplus 驱动大量来自厂商源码,
# 部分函数栈超过 clang 默认检查阈值。
# 仅关闭该 warning 的 error 化,
# 不关闭其它 Werror 检查。

make \
  O=out \
  ARCH="${ARCH}" \
  CC="${CC}" \
  CLANG_TRIPLE="${CLANG_TRIPLE}" \
  CROSS_COMPILE="${CROSS_COMPILE}" \
  CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}" \
  KCFLAGS="-Wno-error=frame-larger-than" \
  -j"$(nproc --all)" \
  Image 2>&1 | tee ../build.log



echo "=== 编译完成 ==="

echo "产物:"
echo "kernel_source/out/arch/${ARCH}/boot/Image"
