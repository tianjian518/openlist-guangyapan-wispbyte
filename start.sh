#!/bin/bash
# ============================================================
#  OpenList-GuangYaPan 启动脚本 — 适配 Wispbyte 免费服务器
#  用法：在面板 Startup 命令里填 bash start.sh
#  二进制从 GitHub Release 下载（避免 512M 内存编译 OOM / git 大文件限制）
#  完整输出（含报错）写入 startup.log 并同时打印到控制台
# ============================================================

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

# ---- 1. 下载预编译二进制（如果未解压，或指定强制重下）----
if [ ! -f "${BINARY_NAME}" ] || [ "${FORCE_REDOWNLOAD}" = "1" ]; then
    if [ "${FORCE_REDOWNLOAD}" = "1" ] && [ -f "${BINARY_GZ}" ]; then rm -f "${BINARY_GZ}"; fi
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

# ---- 2. 数据目录 ----
mkdir -p "${DATA_DIR}"

# ---- 3. 启动（完整输出捕获）----
echo "🚀 启动 OpenList-GuangYaPan ..."
echo "    日志同时写入 startup.log"
echo "    获取密码命令: ./${BINARY_NAME} admin"
echo "------------------------------------------"

./${BINARY_NAME} server --data "${DATA_DIR}" 2>&1 | tee startup.log
EXIT_CODE=${PIPESTATUS[0]}
echo ""
echo "=== OpenList 已退出，退出码: ${EXIT_CODE} ==="
if [ "${EXIT_CODE}" != "0" ]; then
    echo "=== 最后 30 行日志（真正的报错通常在这里）==="
    tail -n 30 startup.log
fi
