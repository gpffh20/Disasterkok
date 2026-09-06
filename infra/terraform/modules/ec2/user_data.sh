#!/bin/bash
set -euo pipefail

LOG=/var/log/user_data.log
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] user_data 시작"

# ── 시스템 업데이트 + git 설치 ────────────────────────────────────────────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 패키지 업데이트, git 설치"
dnf update -y
dnf install -y git

# ── k3s 설치 ──────────────────────────────────────────────────
K3S_VERSION="${k3s_version}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] k3s $K3S_VERSION 설치 시작"

curl -sfL https://get.k3s.io | \
INSTALL_K3S_VERSION="$K3S_VERSION" \
INSTALL_K3S_EXEC="server --disable traefik" \
sh -

# ── k3s 서비스 활성화 확인 ────────────────────────────────────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] k3s 서비스 상태 확인"
systemctl enable k3s
systemctl is-active k3s || { echo "[ERROR] k3s 서비스 시작 실패"; exit 1; }

# ── kubeconfig 전역 설정 ──────────────────────────────────────
chmod 644 /etc/rancher/k3s/k3s.yaml
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' > /etc/profile.d/k3s.sh

# ── ECR 토큰 자동 갱신 스크립트 ──────────────────────────────
cat > /usr/local/bin/refresh-ecr-token.sh << 'REFRESH_SCRIPT'
#!/bin/bash
set -euo pipefail
ECR_REGISTRY="${ecr_registry}"
AWS_REGION="${aws_region}"

TOKEN=$(aws ecr get-login-password --region "$AWS_REGION")

cat > /etc/rancher/k3s/registries.yaml << EOF
mirrors:
  "$ECR_REGISTRY":
    endpoint:
      - "https://$ECR_REGISTRY"
configs:
  "$ECR_REGISTRY":
    auth:
      username: AWS
      password: "$TOKEN"
EOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ECR 토큰 갱신 완료"
REFRESH_SCRIPT

chmod +x /usr/local/bin/refresh-ecr-token.sh
/usr/local/bin/refresh-ecr-token.sh

# ── systemd timer: 6시간마다 자동 갱신 ───────────────────────
cat > /etc/systemd/system/ecr-token-refresh.service << 'EOF'
[Unit]
Description=Refresh ECR authentication token

[Service]
Type=oneshot
ExecStart=/usr/local/bin/refresh-ecr-token.sh
EOF

cat > /etc/systemd/system/ecr-token-refresh.timer << 'EOF'
[Unit]
Description=ECR 토큰 6시간마다 자동 갱신

[Timer]
OnBootSec=5min
OnUnitActiveSec=6h

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now ecr-token-refresh.timer

echo "[$(date '+%Y-%m-%d %H:%M:%S')] user_data 완료"
