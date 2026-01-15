<#
.SYNOPSIS
Procura uma branch Git em todos os repositórios abaixo da pasta atual.

.DESCRIPTION
Percorre recursivamente todos os diretórios, identifica repositórios Git
(inclusive aninhados) e verifica se a branch informada existe (local ou remota).
Opcionalmente, realiza checkout automático na branch.

Saida:
- Lista apenas repositórios onde a branch foi localizada
- Exibe totais ao final

Protecoes:
- Bloqueia checkout se houver alteracoes locais
- Ignora pastas configuradas
- Modo DryRun (simulacao)

.PARAMETER BranchName
Nome da branch a ser procurada.

.PARAMETER Checkout
Se informado, realiza checkout automatico.

.PARAMETER DryRun
Simula as acoes sem executar fetch/checkout.

.PARAMETER ExcludeDirs
Lista de diretorios a ignorar durante a varredura.

.EXAMPLE
.\achaRepoByBranch.ps1 "feature/4324232227"

.EXAMPLE
.\achaRepoByBranch.ps1 "feature/4324232227" -Checkout

.EXAMPLE
.\achaRepoByBranch.ps1 "feature/4324232227" -Checkout -DryRun

.EXAMPLE
.\achaRepoByBranch.ps1 "feature/4324232227" -ExcludeDirs @("node_modules","dist",".next","bin","obj")

#>

param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$BranchName,

    [switch]$Checkout,

    [switch]$DryRun,

    [string[]]$ExcludeDirs = @(
        "scripts-temp-bkp",
        "node_modules", "dist", "build", "out",
        ".next", ".nuxt", ".angular", ".cache",
        "bin", "obj", ".vs", ".vscode"
    )
)

function Test-ExcludedDir {
    param (
        [Parameter(Mandatory = $true)][string]$DirName,
        [Parameter(Mandatory = $true)][string[]]$ExcludeList
    )
    return $ExcludeList -contains $DirName
}

Write-Host "[INFO] Procurando branch '$BranchName' (recursivo)"
Write-Host "[INFO] Checkout: $Checkout | DryRun: $DryRun"
Write-Host ""

$totalGitRepos     = 0
$reposWithBranch   = 0
$foundAny          = $false

# Pilha manual para recursao controlada (permite repos aninhados)
$stack = New-Object System.Collections.Stack
$stack.Push((Get-Item -LiteralPath (Get-Location)))

while ($stack.Count -gt 0) {

    $current = $stack.Pop()
    $subDirs = Get-ChildItem -LiteralPath $current.FullName -Directory -ErrorAction SilentlyContinue

    foreach ($dir in $subDirs) {

        if (Test-ExcludedDir -DirName $dir.Name -ExcludeList $ExcludeDirs) {
            continue
        }

        $repoPath = $dir.FullName
        $gitPath  = Join-Path $repoPath ".git"

        if (Test-Path -LiteralPath $gitPath) {

            $totalGitRepos++

            # Atualiza referencias remotas (se nao for DryRun)
            if (-not $DryRun) {
                git -C $repoPath fetch --all --prune 2>$null | Out-Null
            }

            # Verifica branch local e remota
            $localBranch  = git -C $repoPath branch --list $BranchName 2>$null
            $remoteBranch = git -C $repoPath branch -r 2>$null |
                            Select-String -SimpleMatch "origin/$BranchName"

            if ($localBranch -or $remoteBranch) {

                Write-Host "[REPO] $repoPath"

                if ($DryRun) {
                    Write-Host "  [DRYRUN] git fetch --all --prune"
                }

                Write-Host "  [OK] Branch encontrada"

                $reposWithBranch++
                $foundAny = $true

                if ($Checkout) {

                    # Bloqueia checkout se houver alteracoes locais
                    $dirty = git -C $repoPath status --porcelain 2>$null
                    if ($dirty) {
                        Write-Host "  [BLOCKED] Alteracoes locais encontradas"
                    }
                    elseif ($DryRun) {
                        if ($localBranch) {
                            Write-Host "  [DRYRUN] git checkout $BranchName"
                        }
                        else {
                            Write-Host "  [DRYRUN] git checkout -b $BranchName origin/$BranchName"
                        }
                    }
                    else {
                        if ($localBranch) {
                            git -C $repoPath checkout $BranchName 2>$null | Out-Null
                        }
                        else {
                            git -C $repoPath checkout -b $BranchName "origin/$BranchName" 2>$null | Out-Null
                        }
                        Write-Host "  [CHECKOUT] Realizado"
                    }
                }

                Write-Host ""
            }
        }

        # Continua descendo sempre (repos aninhados sao suportados)
        $stack.Push($dir)
    }
}

Write-Host "Total de Repositorios GIT: $totalGitRepos"
Write-Host "Repositorios com esta branch: $reposWithBranch"

if (-not $foundAny) {
    Write-Host ""
    Write-Host "[WARN] Branch '$BranchName' nao encontrada em nenhum repositorio."
}
