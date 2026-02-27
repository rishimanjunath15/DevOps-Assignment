#!/usr/bin/env bash
# push-to-ecr.sh — Build images locally and push to ECR
# Usage: ./push-to-ecr.sh [dev|staging|prod]

set -euo pipefail

ENV=${1:-dev}
REGION="ap-south-1"
ACCOUNT_ID="655024857157"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

FRONTEND_REPO="${REGISTRY}/${ENV}-frontend"
BACKEND_REPO="${REGISTRY}/${ENV}-backend"

# Image tag — use git short SHA if available, else 'latest'
TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")

echo "============================================"
echo "  Environment : ${ENV}"
echo "  Registry    : ${REGISTRY}"
echo "  Tag         : ${TAG}"
echo "============================================"

# ─── Authenticate Docker to ECR ──────────────────────────────────────────────
echo "[1/5] Authenticating Docker to ECR..."
aws ecr get-login-password --region "${REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

# ─── Build Backend ───────────────────────────────────────────────────────────
echo "[2/5] Building backend..."
docker build -t backend:${TAG} ./backend

# ─── Build Frontend ──────────────────────────────────────────────────────────
echo "[3/5] Building frontend..."
docker build \
  --build-arg NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-http://localhost:8000}" \
  -t frontend:${TAG} ./frontend

# ─── Tag ─────────────────────────────────────────────────────────────────────
echo "[4/5] Tagging images..."
docker tag backend:${TAG}  "${BACKEND_REPO}:${TAG}"
docker tag backend:${TAG}  "${BACKEND_REPO}:latest"
docker tag frontend:${TAG} "${FRONTEND_REPO}:${TAG}"
docker tag frontend:${TAG} "${FRONTEND_REPO}:latest"

# ─── Push ────────────────────────────────────────────────────────────────────
echo "[5/5] Pushing to ECR..."
docker push "${BACKEND_REPO}:${TAG}"
docker push "${BACKEND_REPO}:latest"
docker push "${FRONTEND_REPO}:${TAG}"
docker push "${FRONTEND_REPO}:latest"

echo ""
echo "Done! Images pushed:"
echo "  ${BACKEND_REPO}:${TAG}"
echo "  ${FRONTEND_REPO}:${TAG}"
