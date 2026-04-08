#!/bin/bash

# 設定
REGION="ap-southeast-2"
LOG_FILE="/home/shinobu_sato/ec2-automation/logs/stop_ec2.log"
CONFIG_FILE="/home/shinobu_sato/ec2-automation/config/instance_list.txt"

# ログ出力先設定
exec >> $LOG_FILE 2>&1

# ログ関数
log() {
  LEVEL=$1
  MESSAGE=$2
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$LEVEL] $MESSAGE"
}

# 停止実行
log INFO "=== STOP PROCESS MULTI EC2 ==="

while read ID || [ -n "$ID" ]; do
  log INFO "Stopping EC2: $ID"

  # 停止実行
  aws ec2 stop-instances \
    --instance-ids $ID \
    --region $REGION

  if [ $? -ne 0 ]; then
    log ERROR "Failed to stop: $ID"
    continue
  fi

  # 停止待ち
  aws ec2 wait instance-stopped \
    --instance-ids $ID \
    --region $REGION

  if [ $? -ne 0 ]; then
    log ERROR "Did not reach stopped: $ID"
    continue
  fi

  log INFO "Stopped: $ID"
done < $CONFIG_FILE

log INFO "=== END ==="
