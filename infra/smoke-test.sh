#!/bin/bash
set -e

NAMESPACE="disasterkok"
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PORT=30080

echo "=== Pod 상태 확인 ==="
kubectl get pods -n $NAMESPACE

echo ""
echo "=== Running 아닌 Pod 체크 ==="
NOT_RUNNING=$(kubectl get pods -n $NAMESPACE --no-headers | grep -v "Running" | wc -l)
if [ "$NOT_RUNNING" -gt 0 ]; then
  echo "FAIL: Running 아닌 Pod 있음"
  exit 1
fi
echo "PASS: 전체 Pod Running"

echo ""
echo "=== HTTP 200 체크 ==="
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP:$PORT/)
if [ "$STATUS" != "200" ]; then
  echo "FAIL: HTTP $STATUS"
  exit 1
fi
echo "PASS: HTTP $STATUS — http://$EC2_IP:$PORT/"

echo ""
echo "=== smoke test 완료 ==="
