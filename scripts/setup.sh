#!/usr/bin/env bash
# 准备内核源码 + 工具链
# 用法: ./scripts/setup.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source configs/kernel_source.env
source configs/toolchain.env

echo "=== [1/2] 克隆内核源码 (${KERNEL_BRANCH}) ==="
if [ -d "kernel_source" ]; then
  echo "kernel_source 已存在,跳过克隆(如需重新拉取请先手动删除该目录)"
else
  git clone --depth=1 -b "${KERNEL_BRANCH}" "${KERNEL_REPO}" kernel_source
fi

echo "=== [2/2] 克隆工具链 ==="
if [ -d "${TOOLCHAIN_DIR}" ]; then
  echo "${TOOLCHAIN_DIR} 已存在,跳过克隆"
else
  mkdir -p "$(dirname "${TOOLCHAIN_DIR}")"
  git clone --depth=1 "${TOOLCHAIN_REPO}" "${TOOLCHAIN_DIR}"
fi

echo "=== setup 完成 ==="