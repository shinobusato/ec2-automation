#!/bin/bash

# 設定
REGION="ap-southeast-2"
LOG_FILE="/home/shinobu_sato/ec2-automation/logs/start_ec2.log"
CONFIG_FILE="/home/shinobu_sato/ec2-automation/config/instance_list.txt"

# ログ出力先設定
exec >> $LOG_FILE 2>&1

# ログ関数
log() {
  LEVEL=$1
  MESSAGE=$2
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$LEVEL] $MESSAGE"
}

log INFO "=== START PROCESS MULTI EC2 ==="

while read ID  || [ -n "$ID" ]; do
  log INFO "Starting EC2: $ID"

  # 起動
  aws ec2 start-instances \
    --instance-ids $ID \
    --region $REGION

  if [ $? -ne 0 ]; then
    log ERROR "Failed to start: $ID"
    continue
  fi

  # 起動待ち
  aws ec2 wait instance-running \
    --instance-ids $ID \
    --region $REGION

  if [ $? -ne 0 ]; then
    log ERROR "EC2 Did not reach running: $ID"
    continue
  fi

  log INFO "Started successfully: $ID"
done < $CONFIG_FILE

log INFO "=== END ==="
