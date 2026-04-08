#!/bin/bash

INSTANCE_ID="i-00993bdcb31a91056"
REGION="ap-southeast-2"
LOG_FILE="/home/shinobu_sato/ec2-automation/logs/ec2_test.log"
WEBHOOK_URL="https://hooks.slack.com/services/xxxxxxxxxxx/xxxxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxx"

exec >> $LOG_FILE 2>&1

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2"
}

log INFO "Cron job started"
log INFO "=== START PROCESS ==="

# ① 起動
log INFO "Starting EC2: $INSTANCE_ID"

aws ec2 start-instances \
  --instance-ids $INSTANCE_ID \
  --region $REGION

if [ $? -ne 0 ]; then
  log ERROR "Failed to start EC2"
  exit 1
fi

# ② 起動待ち
log INFO "Waiting for EC2 to be running"

aws ec2 wait instance-running \
  --instance-ids $INSTANCE_ID \
  --region $REGION

# ③ IP取得
#IP=$(aws ec2 describe-instances \
#  --instance-ids $INSTANCE_ID \
#  --region $REGION \
#  --query "Reservations[].Instances[].PublicIpAddress" \
#  --output text)
IP="uforiasatosgear.jp" # NATでPrivateIPへ通信するのでPublicIPは存在しない

log INFO "Public IP: $IP"

# ④ Web確認（リトライ付き）
MAX_RETRIES=5
COUNT=0

while [ $COUNT -lt $MAX_RETRIES ]; do
  curl -s http://$IP > /dev/null

  if [ $? -eq 0 ]; then
    log INFO "Web is reachable"
    break
  fi

  COUNT=$((COUNT+1))
  log WARN "Retry $COUNT..."
  sleep 5
done

# ⑤ 判定
if [ $COUNT -eq $MAX_RETRIES ]; then
  log ERROR "Web check failed"
　# Slack通知
  curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"cron ec2_test.sh : Web check failed.\"}" \
    $WEBHOOK_URL
else
  log INFO "Web check success"
fi

# ⑥ 停止
log INFO "Stopping EC2"

aws ec2 stop-instances \
  --instance-ids $INSTANCE_ID \
  --region $REGION

aws ec2 wait instance-stopped \
  --instance-ids $INSTANCE_ID \
  --region $REGION

log INFO "EC2 stopped"

log INFO "=== END PROCESS ==="
