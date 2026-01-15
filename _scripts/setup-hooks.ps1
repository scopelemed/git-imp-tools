\
# EMED - Setup de hooks versionados (PowerShell)
# Execute no diretório raiz do repositório.

git config core.hooksPath .githooks

Write-Host "✅ Hooks habilitados via core.hooksPath = .githooks" -ForegroundColor Green
Write-Host "Dica: para desabilitar, rode: git config --unset core.hooksPath" -ForegroundColor Yellow
