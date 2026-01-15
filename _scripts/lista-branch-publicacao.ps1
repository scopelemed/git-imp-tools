Clear-Host

# Lista de branches a procurar
$BranchesToFind = @(
    #"develop",
    #"feature/1522818443",
    "feature/1522818442"
)

# Repositórios com caminho fixo
$repoRoots = @(
    "E:\Projetos\git-imp\emed-aspnet",
    "E:\Projetos\git-imp\emed-web",
    "E:\Projetos\git-imp\emed-scripts\objetos-bd",
    "E:\Projetos\git-imp\emed-scripts\scripts-banco-dados"
)

# Repositórios em E:\Projetos\git-imp\emed-com\[subdiretórios]
$emedCOMSubRepos =
    Get-ChildItem "E:\Projetos\git-imp\emed-com" -Directory |
    ForEach-Object {
        $_.FullName
    } | Where-Object {
        Test-Path (Join-Path $_ ".git")
    }
# Repositórios em E:\Projetos\git-imp\emed-dotnet\[subdiretórios]
$emedDotnetSubRepos =
    Get-ChildItem "E:\Projetos\git-imp\emed-dotnet" -Directory |
    ForEach-Object {
        $_.FullName
    } | Where-Object {
        Test-Path (Join-Path $_ ".git")
    }

$allRepos = $repoRoots + $emedCOMSubRepos + $emedDotnetSubRepos

Write-Host "`nTotal de repositórios encontrados: $($allRepos.Count)`n"

# Hashtable: branch -> lista de nomes de repositórios
$results = @{}

foreach ($repoPath in $allRepos) {

    Write-Host ">>> Repositório: $repoPath"

    if (-not (Test-Path (Join-Path $repoPath ".git"))) {
        Write-Host "    Não é repositório Git. Pulando.`n"
        continue
    }

    $repoName = Split-Path $repoPath -Leaf

    try {
        Push-Location -Path $repoPath -ErrorAction Stop

        foreach ($branch in $BranchesToFind) {
            git show-ref --verify --quiet "refs/heads/$branch"
            $exists = $LASTEXITCODE -eq 0

            if ($exists) {
                Write-Host "    # Branch encontrada: $branch"

                if (-not $results.ContainsKey($branch)) {
                    $results[$branch] = New-Object System.Collections.Generic.List[string]
                }

                # evita duplicado
                if (-not $results[$branch].Contains($repoName)) {
                    $results[$branch].Add($repoName) | Out-Null
                }
            } else {
                Write-Host "    Branch não encontrada: $branch"
            }
        }
    }
    catch {
        Write-Host "    Erro ao acessar o repositório: $($_.Exception.Message)"
    }
    finally {
        Pop-Location | Out-Null
    }

    Write-Host ""
}

Write-Host "Processo concluído.`n"

# Montar texto no formato:
# branch
#     repo1
#     repo2
# (linha em branco entre grupos)
if ($results.Count -gt 0) {
    $lines = New-Object System.Collections.Generic.List[string]

    foreach ($branch in $BranchesToFind) {
        if (-not $results.ContainsKey($branch)) { continue }

        $lines.Add($branch) | Out-Null

        foreach ($repoName in $results[$branch]) {
            $lines.Add("    $repoName") | Out-Null
        }

        $lines.Add("") | Out-Null  # linha em branco entre grupos
    }

    $clipboardText = $lines -join "`r`n"
    $clipboardText | Set-Clipboard

    Write-Host "=== Saída (também copiada para a área de transferência) ===`n"
    Write-Host $clipboardText
} else {
    Write-Host "Nenhuma das branches informadas foi encontrada em nenhum repositório."
}
