<#
====================================================================================================
SCRIPT: configurar-ignore-projetos.ps1
AUTOR : Heitor
LOCAL : E:\Projetos\git-imp\_scripts

OBJETIVO
----------------------------------------------------------------------------------------------------
Percorre todos os diretórios e subdiretórios dentro de:

    E:\Projetos\git-imp

identificando automaticamente repositórios Git contendo:

    - Projetos VB6  (.vbp)
    - Projetos .NET (.csproj)

Para cada arquivo encontrado, o script executa comandos Git responsáveis por:

    1) Ignorar alterações locais do arquivo
       OU
    2) Voltar a monitorar alterações normalmente.

MODOS DISPONÍVEIS
----------------------------------------------------------------------------------------------------
-Modo NaoConsiderar

    Executa:

        git update-index --assume-unchanged
        git update-index --skip-worktree

    Resultado:
        O Git deixa de monitorar alterações locais nos arquivos .vbp e .csproj.

----------------------------------------------------------------------------------------------------
-Modo Considerar

    Executa:

        git update-index --no-assume-unchanged
        git update-index --no-skip-worktree

    Resultado:
        O Git volta a monitorar normalmente alterações locais nos arquivos .vbp e .csproj.

EXEMPLOS DE EXECUÇÃO
----------------------------------------------------------------------------------------------------
Executar ignorando alterações locais:

    cd E:\Projetos\git-imp\_scripts
    .\configurar-ignore-projetos.ps1 -Modo NaoConsiderar

Voltar a monitorar alterações:

    .\configurar-ignore-projetos.ps1 -Modo Considerar

OBSERVAÇÕES IMPORTANTES
----------------------------------------------------------------------------------------------------
1) O script deve ser executado preferencialmente dentro de:

    E:\Projetos\git-imp\_scripts

2) Os comandos afetam apenas o repositório local do desenvolvedor.

3) Nenhuma alteração é enviada ao remoto.

4) O script ignora automaticamente:
   - .git
   - node_modules
   - bin
   - obj
   - Debug
   - Release
   - .vs
   - .vscode
   - diretórios auxiliares vb-vbp-xxxxxxxxxxxxx

5) O script só aplica git update-index em arquivos rastreados pelo Git.
====================================================================================================
#>

param(
    [ValidateSet("Considerar", "NaoConsiderar")]
    [string]$Modo = "NaoConsiderar",

    [string]$RootPath = "E:\Projetos\git-imp"
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "Raiz analisada: $RootPath"
Write-Host "Modo: $Modo"
Write-Host ""

function Test-IsGitRepo {
    param(
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    return Test-Path (Join-Path $Path ".git")
}

function Test-IsIgnoredPath {
    param(
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $true
    }

    return (
        $Path -match "\\\.git(\\" + "|$)" -or
        $Path -match "\\node_modules(\\" + "|$)" -or
        $Path -match "\\bin(\\" + "|$)" -or
        $Path -match "\\obj(\\" + "|$)" -or
        $Path -match "\\Debug(\\" + "|$)" -or
        $Path -match "\\Release(\\" + "|$)" -or
        $Path -match "\\\.vs(\\" + "|$)" -or
        $Path -match "\\\.vscode(\\" + "|$)" -or
        $Path -match "\\vb-vbp-xxxxxxxxxxxxx(\\" + "|$)"
    )
}

function Get-GitRelativePath {
    param(
        [string]$RepoPath,
        [string]$FilePath
    )

    if ([string]::IsNullOrWhiteSpace($RepoPath)) {
        return $null
    }

    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        return $null
    }

    if (!(Test-Path $FilePath)) {
        return $null
    }

    $repoFullPath = (Resolve-Path $RepoPath).Path.TrimEnd("\")
    $fileFullPath = (Resolve-Path $FilePath).Path

    if (!$fileFullPath.StartsWith($repoFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }

    $relativePath = $fileFullPath.Substring($repoFullPath.Length).TrimStart("\")
    $relativePath = $relativePath -replace "\\", "/"

    return $relativePath
}

function Test-IsTrackedByGit {
    param(
        [string]$RepoPath,
        [string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return $false
    }

    Push-Location $RepoPath

    try {
        git ls-files --error-unmatch -- "$RelativePath" 2>$null | Out-Null

        return ($LASTEXITCODE -eq 0)
    }
    finally {
        Pop-Location
    }
}

function Invoke-GitUpdateIndex {
    param(
        [string]$RepoPath,
        [string]$FilePath,
        [string]$Modo
    )

    if ([string]::IsNullOrWhiteSpace($RepoPath) -or [string]::IsNullOrWhiteSpace($FilePath)) {
        return
    }

    if (!(Test-Path $FilePath)) {
        return
    }

    if (Test-IsIgnoredPath -Path $FilePath) {
        return
    }

    $relativePathGit = Get-GitRelativePath -RepoPath $RepoPath -FilePath $FilePath

    if ([string]::IsNullOrWhiteSpace($relativePathGit)) {
        Write-Host "  Caminho inválido ignorado: $FilePath" -ForegroundColor DarkYellow
        return
    }

    if (!(Test-IsTrackedByGit -RepoPath $RepoPath -RelativePath $relativePathGit)) {
        Write-Host "  Arquivo não rastreado pelo Git: $relativePathGit" -ForegroundColor DarkYellow
        return
    }

    Push-Location $RepoPath

    try {
        if ($Modo -eq "NaoConsiderar") {
            Write-Host "  Ignorando alterações locais: $relativePathGit" -ForegroundColor Yellow

            git update-index --assume-unchanged -- "$relativePathGit"
            git update-index --skip-worktree -- "$relativePathGit"
        }
        else {
            Write-Host "  Voltando a considerar alterações: $relativePathGit" -ForegroundColor Green

            git update-index --no-assume-unchanged -- "$relativePathGit"
            git update-index --no-skip-worktree -- "$relativePathGit"
        }
    }
    catch {
        Write-Host "  Erro ao processar arquivo: $relativePathGit" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

function Get-GitRepositories {
    param(
        [string]$RootPath
    )

    if (!(Test-Path $RootPath)) {
        Write-Host "RootPath não encontrado: $RootPath" -ForegroundColor Red
        return @()
    }

    $repos = Get-ChildItem -Path $RootPath -Directory -Recurse -Force |
        Where-Object {
            !(Test-IsIgnoredPath -Path $_.FullName) -and
            (Test-IsGitRepo -Path $_.FullName)
        }

    return @($repos)
}

$gitRepos = Get-GitRepositories -RootPath $RootPath

if ($gitRepos.Count -eq 0) {
    Write-Host "Nenhum repositório Git encontrado." -ForegroundColor DarkYellow
    exit
}

foreach ($repo in $gitRepos) {
    Write-Host ""
    Write-Host "Repositório encontrado: $($repo.FullName)" -ForegroundColor Cyan

    $vbpFiles = Get-ChildItem -Path $repo.FullName -Filter "*.vbp" -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object {
            !(Test-IsIgnoredPath -Path $_.FullName)
        }

    $csprojFiles = Get-ChildItem -Path $repo.FullName -Filter "*.csproj" -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object {
            !(Test-IsIgnoredPath -Path $_.FullName)
        }

    $projectFiles = @($vbpFiles) + @($csprojFiles)

    if ($projectFiles.Count -eq 0) {
        Write-Host "  Nenhum .vbp ou .csproj encontrado." -ForegroundColor DarkGray
        continue
    }

    foreach ($file in $projectFiles) {
        if ($null -eq $file) {
            continue
        }

        Invoke-GitUpdateIndex `
            -RepoPath $repo.FullName `
            -FilePath $file.FullName `
            -Modo $Modo
    }
}

Write-Host ""
Write-Host "Processo finalizado." -ForegroundColor Green

