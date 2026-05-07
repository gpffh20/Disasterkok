#!/bin/bash
set -e

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=disasterkok-dev-node" "Name=instance-state-name,Values=stopped" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text \
  --region ap-northeast-2)

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
  echo "중지된 인스턴스를 찾을 수 없습니다"
  exit 1
fi

echo "인스턴스 시작 중: $INSTANCE_ID"
aws ec2 start-instances --instance-ids "$INSTANCE_ID" --region ap-northeast-2

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region ap-northeast-2

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text \
  --region ap-northeast-2)

echo "시작 완료"
echo "새 퍼블릭 IP: $PUBLIC_IP"
echo ""
echo "접속 명령:"
echo "  ssh -i <키파일>.pem ec2-user@$PUBLIC_IP"
