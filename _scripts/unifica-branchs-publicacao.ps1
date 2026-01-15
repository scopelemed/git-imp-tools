Clear-Host

# ================== CONFIGURAÇÃO INICIAL ==================

# Branches possíveis de origem (o script usa a primeira que existir em cada repo)
$BranchesToFind = @(
    # "develop",
    # "outra-branch",
    "feature/1522818442"
)

# Nome da nova branch que será criada em todos os repositórios
$NewBranchName = "feature/automatizacao_whatsaap_publicacao"

# Controla se deve compactar o conteúdo da branch base antes de criar a nova
$EnableCompression = $false   # $true para habilitar, $false para desabilitar

# Controla se deve mexer no remoto (origin) da nova branch
$UpdateRemote = $false        # $true para push/pull, $false para manter tudo local

# Caminho do executável do WinRAR
$WinRARPath = "C:\Program Files\WinRAR\WinRAR.exe"

# Repositórios com caminho fixo
$repoRoots = @(
    "E:\Projetos\git-imp\emed-aspnet",
    "E:\Projetos\git-imp\emed-com",
    "E:\Projetos\git-imp\emed-web",
    "E:\Projetos\git-imp\emed-scripts\objetos-bd",
    "E:\Projetos\git-imp\emed-scripts\scripts-banco-dados"
)

# Repositórios em E:\Projetos\git-imp\emed-dotnet\[subdiretórios]
$emedDotnetSubRepos =
    Get-ChildItem "E:\Projetos\git-imp\emed-dotnet" -Directory |
    ForEach-Object {
        $_.FullName
    } | Where-Object {
        Test-Path (Join-Path $_ ".git")
    }

$allRepos = $repoRoots + $emedDotnetSubRepos

Write-Host "`nTotal de repositórios encontrados: $($allRepos.Count)`n"

# ================== PROCESSAMENTO ==================

foreach ($repoPath in $allRepos) {

    Write-Host ">>> Repositório: $repoPath"

    if (-not (Test-Path $repoPath)) {
        Write-Host "    ? Caminho não existe. Pulando.`n"
        continue
    }

    if (-not (Test-Path (Join-Path $repoPath ".git"))) {
        Write-Host "    ? Não é repositório Git (sem .git). Pulando.`n"
        continue
    }

    try {
        Push-Location -Path $repoPath -ErrorAction Stop

        # 1) Localizar a primeira branch de origem que existir
        $baseBranch = $null

        foreach ($branch in $BranchesToFind) {
            git show-ref --verify --quiet "refs/heads/$branch"
            if ($LASTEXITCODE -eq 0) {
                $baseBranch = $branch
                break
            }
        }

        if (-not $baseBranch) {
            Write-Host "    ? Nenhuma das branches de origem foi encontrada. Pulando este repositório.`n"
            continue
        }

        Write-Host "    ? Branch base encontrada: $baseBranch"

        # 2) Checkout na branch localizada
        git checkout $baseBranch
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    ?? Falha ao fazer checkout em $baseBranch. Pulando.`n"
            continue
        }

        # 3) Compactação opcional usando WinRAR
        if ($EnableCompression) {
            if (Test-Path $WinRARPath) {
                $archiveName = "$($baseBranch).rar"           # mesmo nome da branch
                $archivePath = Join-Path $repoPath $archiveName

                Write-Host "    ?? Compactando conteúdo da branch '$baseBranch' em:"
                Write-Host "       $archivePath"

                # Compacta tudo da working tree, excluindo a pasta .git
                & $WinRARPath a -r -idq "$archivePath" * -x.git\* | Out-Null

                if ($LASTEXITCODE -eq 0) {
                    Write-Host "    ? Compactação concluída."
                } else {
                    Write-Host "    ?? Erro ao compactar com WinRAR (código $LASTEXITCODE)."
                }
            } else
                {
                Write-Host "    ?? WinRAR não encontrado em '$WinRARPath'. Compactação ignorada."
            }
        } else {
            Write-Host "    ?? Compactação desabilitada (`$EnableCompression = `$false)."
        }

        # 4) Criar / posicionar na nova branch
        git show-ref --verify --quiet "refs/heads/$NewBranchName"
        $localNewExists = $LASTEXITCODE -eq 0

        if ($localNewExists) {
            Write-Host "    ?? Nova branch '$NewBranchName' já existe localmente. Fazendo checkout..."
            git checkout $NewBranchName
        } else {
            Write-Host "    ?? Criando nova branch '$NewBranchName' a partir de '$baseBranch'..."
            git checkout -b $NewBranchName
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Host "    ?? Falha ao posicionar na nova branch '$NewBranchName'. Pulando atualização.`n"
            continue
        }

        # 5) Atualizar nova branch (remoto) – opcional
        if ($UpdateRemote) {
            Write-Host "    ?? Atualizando nova branch com remoto..."

            # Verifica se a branch já existe no remoto
            git ls-remote --heads origin $NewBranchName | Out-Null
            $remoteExists = $LASTEXITCODE -eq 0

            if ($remoteExists) {
                Write-Host "    ?? Branch '$NewBranchName' já existe em 'origin'. Configurando upstream e dando pull..."
                git branch --set-upstream-to=("origin/$NewBranchName") $NewBranchName 2>$null
                git pull
            } else {
                Write-Host "    ?? Branch '$NewBranchName' não existe em 'origin'. Fazendo push inicial..."
                git push -u origin $NewBranchName
            }
        } else {
            Write-Host "    ?? Update remoto desabilitado (`$UpdateRemote = `$false). Nenhuma alteração no servidor."
        }

        Write-Host "    ? Processo concluído para este repositório.`n"
    }
    catch {
        Write-Host "    ?? Erro ao acessar o repositório: $($_.Exception.Message)`n"
    }
    finally {
        Pop-Location | Out-Null
    }
}
Write-Host "?? Processo geral concluído."

