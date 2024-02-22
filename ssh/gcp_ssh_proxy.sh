#!/bin/bash

# ANSI颜色代码
RED='\033[0;31m'
NO_COLOR='\033[0m'

# 日志函数，输出到stderr并带有红色文本
log() {
    echo -e "${RED}$1${NO_COLOR}" >&2
}

# 参数检查
if [ "$#" -ne 3 ]; then
    log "Usage: $0 <instance-name> <project-id> <zone>"
    exit 1
fi

# 从传入的Host名称中去除前缀"gcp-"
#INSTANCE_NAME=${1#gcp-}
INSTANCE_NAME=$1
PROJECT_ID=$2
ZONE=$3

log "Starting SSH connection process for instance $INSTANCE_NAME..."

# 检查gcloud是否已经认证
if ! gcloud auth print-access-token &> /dev/null; then
    log "No active gcloud session found. Attempting to login..."
    if gcloud auth login; then
        log "Successfully authenticated with gcloud."
    else
        log "gcloud authentication failed."
        exit 1
    fi
else
    log "Already authenticated with gcloud."
fi

# 获取公网IP
log "Retrieving the public IP for instance $INSTANCE_NAME..."
IP=$(gcloud compute instances describe $INSTANCE_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# 如果IP为空，尝试启动实例
if [ -z "$IP" ]; then
    log "Instance $INSTANCE_NAME does not have an external IP. Starting instance..."
    if gcloud compute instances start $INSTANCE_NAME --project=$PROJECT_ID --zone=$ZONE; then
        log "Instance $INSTANCE_NAME is starting..."
    else
        log "Failed to start instance $INSTANCE_NAME."
        exit 1
    fi

    # 等待实例启动并获取IP
    while [ -z "$IP" ]; do
        log "Waiting for instance $INSTANCE_NAME to start and acquire an external IP..."
        sleep 10
        IP=$(gcloud compute instances describe $INSTANCE_NAME \
            --project=$PROJECT_ID \
            --zone=$ZONE \
            --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    done
    log "Instance $INSTANCE_NAME started with IP: $IP"
else
    log "External IP for instance $INSTANCE_NAME is $IP"
fi

# 输出IP地址以供SSH使用
echo $IP

