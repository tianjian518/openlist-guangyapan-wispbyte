#!/bin/bash
# ============================================================
#  OpenList-GuangYaPan 启动脚本 — 适配 Wispbyte 免费服务器
#  用法：在面板 Startup 命令里填 bash start.sh
#  二进制从 GitHub Release 下载（避免 512M 内存编译 OOM / git 大文件限制）
#  完整输出（含报错）写入 startup.log 并同时打印到控制台
#  自动读取 Wispbyte/Pterodactyl 注入的端口变量，传给 OpenList
#  崩溃恢复：设环境变量 WIPE_DATA=1 可清空坏数据重初始化
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

# ---- 2. 端口处理：优先用 Wispbyte/Pterodactyl 注入的端口变量 ----
if [ -n "$OPENLIST_PORT" ]; then
    echo "🔌 使用 OPENLIST_PORT=$OPENLIST_PORT"
elif [ -n "$SERVER_PORT" ]; then
    export OPENLIST_PORT="$SERVER_PORT"
    echo "🔌 使用 SERVER_PORT=$SERVER_PORT"
elif [ -n "$PORT" ]; then
    export OPENLIST_PORT="$PORT"
    echo "🔌 使用 PORT=$PORT"
else
    export OPENLIST_PORT="5244"
    echo "⚠️  未检测到外部端口变量，暂用默认 5244（若外部访问不通，请在面板设置环境变量 OPENLIST_PORT=你的端口）"
fi

# ---- 2.5 清空坏数据（崩溃恢复用，平时别开）----
if [ "${WIPE_DATA}" = "1" ]; then
    echo "🧹 WIPE_DATA=1：清空 ./data 后重新初始化..."
    rm -rf ./data
fi

# ---- 3. 数据目录 ----
mkdir -p "${DATA_DIR}"

# ---- 4. 启动（完整输出捕获）----
echo "🚀 启动 OpenList-GuangYaPan（监听端口 ${OPENLIST_PORT}）..."
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
