#!/usr/bin/env bash
set -e

export ARCH=arm64

KERNEL_DIR="$GITHUB_WORKSPACE/kernel"
OUT_DIR="$KERNEL_DIR/out"

echo "== Building kernel =="

cd "$KERNEL_DIR"

make \
    O="$OUT_DIR" \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    -j$(nproc)

echo "== Build finished =="

ls -lh "$OUT_DIR/arch/arm64/boot/"