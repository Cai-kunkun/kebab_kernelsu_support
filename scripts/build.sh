#!/usr/bin/env bash

set -e

echo "== Building kernel =="

cd "$GITHUB_WORKSPACE/kernel"


make \
 O=out \
 ARCH=arm64 \
 LLVM=1 \
 LLVM_IAS=1 \
 Image.gz \
 -j$(nproc)


echo "Build finished"

ls -lh out/arch/arm64/boot/