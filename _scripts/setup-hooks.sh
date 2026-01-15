#!/usr/bin/env bash
# EMED - Setup de hooks versionados (bash)
set -euo pipefail

git config core.hooksPath .githooks
chmod +x .githooks/commit-msg

echo "✅ Hooks habilitados via core.hooksPath = .githooks"
echo "Dica: para desabilitar: git config --unset core.hooksPath"
