#!/bin/bash

# 設定
INSTANCE_ID="i-00993bdcb31a91056"
BASTION_IP="13.237.209.132"
REGION="ap-southeast-2"
KEY="/home/shinobu_sato/.ssh/ubuntu-study-key.pem"
LOG_DIR="/home/shinobu_sato/ec2-automation/logs"
DATE=$(date +%Y%m%d)

mkdir -p $LOG_DIR

# ログ出力関数
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2"
}

# 起動
log INFO "Starting EC2"

aws ec2 start-instances --instance-ids $INSTANCE_ID --region $REGION
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# EC2のPrivateIPアドレス取得
EC2IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --query "Reservations[].Instances[].PrivateIpAddress" \
  --output text)

log INFO "EC2IP: $EC2IP"

# エージェントを起動して鍵を登録
eval `ssh-agent`
ssh-add $KEY

# 少し待つ（SSH安定）
sleep 10

# ログ取得
log INFO "Downloading logs"

scp -o ProxyJump=ubuntu@$BASTION_IP ubuntu@$EC2IP:/var/log/nginx/access.log $LOG_DIR/access.log
scp -o ProxyJump=ubuntu@$BASTION_IP ubuntu@$EC2IP:/var/log/nginx/access.log.1 $LOG_DIR/access_$DATE.log
scp -o ProxyJump=ubuntu@$BASTION_IP ubuntu@$EC2IP:/var/log/nginx/error.log $LOG_DIR/error.log
scp -o ProxyJump=ubuntu@$BASTION_IP ubuntu@$EC2IP:/var/log/nginx/error.log.1 $LOG_DIR/error_$DATE.log

# 停止
log INFO "Stopping EC2"

aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $REGION
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID --region $REGION

log INFO "Done"
