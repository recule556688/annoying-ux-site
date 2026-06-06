#!/usr/bin/env bash
# One-time server setup. Run on your VPS after cloning the repo.
set -euo pipefail

DEPLOY_PATH="${1:-$HOME/annoying-ux-site}"
REPO_URL="${2:-}"

if [[ -z "$REPO_URL" ]]; then
  echo "Usage: $0 [deploy-path] <git-repo-url>"
  echo "Example: $0 /opt/annoying-ux-site git@github.com:you/annoying-ux-site.git"
  exit 1
fi

mkdir -p "$(dirname "$DEPLOY_PATH")"
if [[ ! -d "$DEPLOY_PATH/.git" ]]; then
  git clone "$REPO_URL" "$DEPLOY_PATH"
fi

cd "$DEPLOY_PATH"
git pull --ff-only

echo "Bootstrap complete. Next:"
echo "  1. Add GitHub Actions secrets (SSH_HOST, SSH_USER, SSH_PRIVATE_KEY, DEPLOY_PATH, SSH_PORT)"
echo "  2. Make the GHCR package public, or run: echo TOKEN | docker login ghcr.io -u USER --password-stdin"
echo "  3. Push to main to trigger deploy"
