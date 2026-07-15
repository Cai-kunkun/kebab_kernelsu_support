#!/usr/bin/env bash
set -e

export ARCH=arm64

KERNEL_DIR="$GITHUB_WORKSPACE/kernel"
OUT_DIR="$KERNEL_DIR/out"

echo "== Setting up build environment =="

cd "$KERNEL_DIR"

echo "Cleaning previous build"

make mrproper

rm -rf "$OUT_DIR"

mkdir -p "$OUT_DIR"

echo "Using defconfig: vendor/kona_defconfig"

make \
    O="$OUT_DIR" \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    vendor/kona_defconfig

echo "Running olddefconfig"

make \
    O="$OUT_DIR" \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    olddefconfig

echo "Config generated successfully"