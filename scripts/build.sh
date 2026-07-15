#!/usr/bin/env bash
# empty placeholder
# 实际编译命令(defconfig + make), 本地和 CI 都能调用同一份
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

export PATH="${ROOT_DIR}/${TOOLCHAIN_DIR}/bin:${PATH}"
export ARCH="${KERNEL_ARCH}"
export SUBARCH="${KERNEL_ARCH}"
export CC="${CC}"
export CLANG_TRIPLE="${CLANG_TRIPLE}"
export CROSS_COMPILE="${CROSS_COMPILE}"
export CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}"

cd kernel_source

echo "=== 生成 defconfig: ${KERNEL_DEFCONFIG} ${KERNEL_DEFCONFIG_FRAGMENTS} ==="
make O=out ARCH="${ARCH}" ${KERNEL_DEFCONFIG} ${KERNEL_DEFCONFIG_FRAGMENTS}

echo "=== 开始编译 Image ==="
make O=out ARCH="${ARCH}" CC="${CC}" CLANG_TRIPLE="${CLANG_TRIPLE}" \
  CROSS_COMPILE="${CROSS_COMPILE}" CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}" \
  -j"$(nproc --all)" Image 2>&1 | tee ../build.log

echo "=== 编译完成,产物: kernel_source/out/arch/${ARCH}/boot/Image ==="