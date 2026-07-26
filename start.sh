#!/bin/bash
# ============================================================
#  OpenList-GuangYaPan 启动脚本 — 适配 Wispbyte 免费服务器
#  用法：在面板 Startup 命令里填 bash start.sh
#  二进制从 GitHub Release 下载（避免 512M 内存编译 OOM / git 大文件限制）
# ============================================================

set -e

REPO_OWNER="tianjian518"
REPO_NAME="openlist-guangyapan-wispbyte"
RELEASE_TAG="v1.0.0"
BINARY_GZ="openlist-guangyapan.gz"
BINARY_NAME="openlist-guangyapan"
DATA_DIR="./data"

echo "=========================================="
echo "  OpenList-GuangYaPan 启动脚本"
echo "  ${REPO_OWNER}/${REPO_NAME} @ ${RELEASE_TAG}"
echo "=========================================="

# ---- 1. 下载预编译二进制（如果未解压）----
if [ ! -f "${BINARY_NAME}" ]; then
    if [ ! -f "${BINARY_GZ}" ]; then
        DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${RELEASE_TAG}/${BINARY_GZ}"
        echo "⬇️  下载预编译二进制: ${DOWNLOAD_URL}"
        if command -v wget &>/dev/null; then
            wget -q --show-progress -O "${BINARY_GZ}" "${DOWNLOAD_URL}" || curl -sL -o "${BINARY_GZ}" "${DOWNLOAD_URL}"
        else
            curl -sL -o "${BINARY_GZ}" "${DOWNLOAD_URL}"
        fi
    fi
    echo "📦 解压本地二进制..."
    gzip -d "${BINARY_GZ}" || { echo "❌ 解压失败，请确认 Release 包含 ${BINARY_GZ}"; exit 1; }
    chmod +x "${BINARY_NAME}"
    echo "✅ 二进制就绪: ${BINARY_NAME}"
else
    echo "✅ 二进制已存在，跳过下载"
fi

# ---- 2. 创建数据目录 ----
mkdir -p "${DATA_DIR}"

# ---- 3. 显示版本 ----
echo ""
echo "=========================================="
./${BINARY_NAME} version 2>/dev/null || true
echo "=========================================="
echo ""

# ---- 4. 启动 ----
echo "🚀 启动 OpenList-GuangYaPan ..."
echo "    默认端口: 5244"
echo "    首次启动会生成随机管理员密码，请查看下方日志"
echo "    获取密码: ./${BINARY_NAME} admin"
echo ""
echo "------------------------------------------"

exec ./${BINARY_NAME} server --data "${DATA_DIR}"
