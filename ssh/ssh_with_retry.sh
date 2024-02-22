#!/bin/bash

source ~/.shoppal/env.sh

# ANSI颜色代码
RED='\033[0;31m'
NO_COLOR='\033[0m'

# 日志函数，输出到stderr并带有红色文本
log() {
    echo -e "${RED}$1${NO_COLOR}" >&2
}

# 参数检查
if [ "$#" -lt 4 ]; then
    log "Usage: $0 <instance-name> <ssh-port> <project-id> <zone>"
    exit 1
fi

# SSH连接信息
INSTANCE_NAME="$1"
PORT="$2"
PROJECT_ID="$3"
ZONE="$4"
USER="${SHOPPAL_USER:-$(id -un)}"

# 获取公网IP
IP=$(~/.shoppal/ssh/gcp_ssh_proxy.sh "$INSTANCE_NAME" "$PROJECT_ID" "$ZONE")

# 最大重试次数
MAX_RETRIES=10
# 初始重试次数
RETRY_COUNT=0

# SSH连接函数
ssh_connect() {
    ssh -o 'StrictHostKeyChecking no' -o 'ConnectTimeout=5' "$USER"@"$IP" nc $INSTANCE_NAME $PORT
}

# 尝试连接
until ssh_connect; do
    ((RETRY_COUNT++))
    log "SSH connection failed. Attempting retry $RETRY_COUNT of $MAX_RETRIES..."
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        log "SSH connection failed after $MAX_RETRIES attempts."
        exit 1
    fi
    sleep 5
done

