#!/bin/bash
set -e

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

NAMESPACE="disasterkok"
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
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/)
if [ "$STATUS" != "200" ]; then
  echo "FAIL: HTTP $STATUS"
  exit 1
fi
echo "PASS: HTTP $STATUS — http://localhost:$PORT/"

echo ""
echo "=== smoke test 완료 ==="
