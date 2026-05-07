#!/bin/bash
set -e

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=disasterkok-dev-node" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text \
  --region ap-northeast-2)

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
  echo "실행 중인 인스턴스를 찾을 수 없습니다"
  exit 1
fi

echo "인스턴스 중지 중: $INSTANCE_ID"
aws ec2 stop-instances --instance-ids "$INSTANCE_ID" --region ap-northeast-2

aws ec2 wait instance-stopped --instance-ids "$INSTANCE_ID" --region ap-northeast-2
echo "중지 완료: $INSTANCE_ID"