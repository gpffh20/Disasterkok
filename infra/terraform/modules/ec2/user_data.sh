#!/bin/bash
set -euo pipefail

LOG=/var/log/user_data.log
exec > >(tee -a "$LOG") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] user_data 시작"

# ── 시스템 업데이트 ────────────────────────────────────────────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 패키지 업데이트"
dnf update -y

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

# ── kubeconfig 권한 설정 ──────────────────────────────────────
chmod 644 /etc/rancher/k3s/k3s.yaml

echo "[$(date '+%Y-%m-%d %H:%M:%S')] user_data 완료"