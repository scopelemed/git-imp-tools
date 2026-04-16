<# 
    GitBucket - Auditoria de PRs abertos para develop
    -------------------------------------------------
    Objetivo:
      - Listar PRs abertos com destino na branch develop
      - Opcionalmente tentar verificar se a branch do PR está desatualizada
        em relação à develop usando SOMENTE a API do GitBucket

    Requisitos:
      - PowerShell 5+ ou PowerShell 7+
      - Token de acesso à API do GitBucket

    Observações:
      - A comparação ahead/behind depende do suporte da instância GitBucket
        ao endpoint de compare.
      - Se a comparação estiver desabilitada ou não for suportada, o script
        continua funcionando e entrega os PRs pendentes.
#>

# =========================================================
# CONFIGURAÇÕES
# =========================================================

$CONFIG = @{
    # URL base do GitBucket
    GitBucketUrl = "http://seu-gitbucket:8080"

    # Token de acesso
    Token = "SEU_TOKEN_AQUI"

    # Modo de busca de repositórios:
    # "user" = busca repositórios de um usuário
    # "org"  = busca repositórios de uma organização
    # "mine" = busca repositórios acessíveis ao usuário autenticado
    RepoScope = "org"

    # Nome do owner quando RepoScope = user ou org
    OwnerName = "Desenvolvedores"

    # Branch base a considerar como alvo
    BaseBranch = "develop"

    # Estado do PR
    PullRequestState = "open"

    # Habilita tentativa de comparar branch do PR com a develop via API
    # true  = tenta usar endpoint compare
    # false = apenas lista PRs pendentes
    EnableCompareCheck = $true

    # Quando a comparação estiver habilitada:
    # true  = mostra também PRs alinhados com develop
    # false = mostra apenas os que estão behind ou com comparação indisponível
    IncludeUpToDateWhenCompareEnabled = $false

    # Exportações
    ExportCsv  = $true
    ExportJson = $false

    # Pasta de saída
    OutputDir = "$PSScriptRoot\out"

    # Timeout HTTP em segundos
    TimeoutSec = 60

    # Verbose técnico
    VerboseMode = $true
}

# =========================================================
# FUNÇÕES AUXILIARES
# =========================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR","DEBUG")]
        [string]$Level = "INFO"
    )

    if ($Level -eq "DEBUG" -and -not $CONFIG.VerboseMode) {
        return
    }

    $prefix = "[{0}] {1}" -f $Level, (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Write-Host "$prefix - $Message"
}

function Ensure-OutputDir {
    if (-not (Test-Path $CONFIG.OutputDir)) {
        New-Item -ItemType Directory -Path $CONFIG.OutputDir -Force | Out-Null
    }
}

function Get-AuthHeaders {
    return @{
        Authorization = "token $($CONFIG.Token)"
        Accept        = "application/json"
    }
}

function Invoke-GitBucketGet {
    param(
        [Parameter(Mandatory = $true)][string]$Url
    )

    Write-Log "GET $Url" "DEBUG"

    try {
        return Invoke-RestMethod `
            -Uri $Url `
            -Method Get `
            -Headers (Get-AuthHeaders) `
            -TimeoutSec $CONFIG.TimeoutSec
    }
    catch {
        throw $_
    }
}

function Get-Repositories {
    $repos = @()
    $page  = 1

    while ($true) {
        switch ($CONFIG.RepoScope) {
            "org" {
                $url = "{0}/api/v3/orgs/{1}/repos?page={2}&per_page=100" -f `
                    $CONFIG.GitBucketUrl, $CONFIG.OwnerName, $page
            }
            "user" {
                $url = "{0}/api/v3/users/{1}/repos?page={2}&per_page=100" -f `
                    $CONFIG.GitBucketUrl, $CONFIG.OwnerName, $page
            }
            "mine" {
                $url = "{0}/api/v3/user/repos?page={1}&per_page=100" -f `
                    $CONFIG.GitBucketUrl, $page
            }
            default {
                throw "RepoScope inválido: $($CONFIG.RepoScope)"
            }
        }

        try {
            $result = Invoke-GitBucketGet -Url $url
        }
        catch {
            throw "Erro ao buscar repositórios na página $page. $($_.Exception.Message)"
        }

        if ($null -eq $result) { break }

        $batch = @($result)
        if ($batch.Count -eq 0) { break }

        $repos += $batch
        $page++
    }

    return $repos
}

function Get-OpenPullRequestsForRepo {
    param(
        [Parameter(Mandatory = $true)][string]$Owner,
        [Parameter(Mandatory = $true)][string]$RepoName
    )

    $url = "{0}/api/v3/repos/{1}/{2}/pulls?state={3}" -f `
        $CONFIG.GitBucketUrl, $Owner, $RepoName, $CONFIG.PullRequestState

    try {
        $result = Invoke-GitBucketGet -Url $url
        if ($null -eq $result) { return @() }
        return @($result)
    }
    catch {
        Write-Log "Falha ao buscar PRs de $Owner/$RepoName. $($_.Exception.Message)" "WARN"
        return @()
    }
}

function Get-CompareInfo {
    param(
        [Parameter(Mandatory = $true)][string]$Owner,
        [Parameter(Mandatory = $true)][string]$RepoName,
        [Parameter(Mandatory = $true)][string]$BaseBranch,
        [Parameter(Mandatory = $true)][string]$HeadBranch
    )

    # Padrão estilo GitHub/GitBucket:
    # /api/v3/repos/{owner}/{repo}/compare/{base}...{head}
    $url = "{0}/api/v3/repos/{1}/{2}/compare/{3}...{4}" -f `
        $CONFIG.GitBucketUrl, $Owner, $RepoName, $BaseBranch, $HeadBranch

    try {
        $compare = Invoke-GitBucketGet -Url $url

        # Tentativa de leitura em formato compatível com GitHub-like compare response
        $aheadBy  = $null
        $behindBy = $null
        $status   = $null

        if ($compare.PSObject.Properties.Name -contains "ahead_by") {
            $aheadBy = $compare.ahead_by
        }

        if ($compare.PSObject.Properties.Name -contains "behind_by") {
            $behindBy = $compare.behind_by
        }

        if ($compare.PSObject.Properties.Name -contains "status") {
            $status = $compare.status
        }

        return [pscustomobject]@{
            CompareSupported = $true
            CompareStatus    = "ok"
            AheadBy          = $aheadBy
            BehindBy         = $behindBy
            Status           = $status
            RawResponse      = $compare
        }
    }
    catch {
        return [pscustomobject]@{
            CompareSupported = $false
            CompareStatus    = "not_supported_or_failed"
            AheadBy          = $null
            BehindBy         = $null
            Status           = $null
            RawResponse      = $null
            ErrorMessage     = $_.Exception.Message
        }
    }
}

function Should-IncludeResult {
    param(
        [Parameter(Mandatory = $true)]$Item
    )

    if (-not $CONFIG.EnableCompareCheck) {
        return $true
    }

    if ($CONFIG.IncludeUpToDateWhenCompareEnabled) {
        return $true
    }

    # Quando comparação está habilitada, mas a instância não suporta
    # ainda vale mostrar, para não ocultar PR pendente
    if (-not $Item.CompareSupported) {
        return $true
    }

    # Se temos behind_by e é maior que zero, está desatualizada
    if ($null -ne $Item.BehindBy -and [int]$Item.BehindBy -gt 0) {
        return $true
    }

    return $false
}

# =========================================================
# EXECUÇÃO
# =========================================================

if ([string]::IsNullOrWhiteSpace($CONFIG.Token) -or $CONFIG.Token -eq "SEU_TOKEN_AQUI") {
    throw "Configure o token em `$CONFIG.Token antes de executar."
}

Ensure-OutputDir

Write-Log "Iniciando auditoria de PRs no GitBucket"
Write-Log "RepoScope: $($CONFIG.RepoScope)"
Write-Log "OwnerName: $($CONFIG.OwnerName)"
Write-Log "BaseBranch: $($CONFIG.BaseBranch)"
Write-Log "EnableCompareCheck: $($CONFIG.EnableCompareCheck)"

$repos = Get-Repositories
Write-Log "Total de repositórios encontrados: $($repos.Count)"

$results = New-Object System.Collections.Generic.List[object]

foreach ($repo in $repos) {
    $repoName = $repo.name
    $owner    = $repo.owner.login

    Write-Log "Analisando repositório $owner/$repoName"

    $prs = Get-OpenPullRequestsForRepo -Owner $owner -RepoName $repoName
    if (-not $prs -or $prs.Count -eq 0) {
        continue
    }

    $targetPrs = $prs | Where-Object { $_.base.ref -eq $CONFIG.BaseBranch }

    foreach ($pr in $targetPrs) {
        $compareInfo = $null

        if ($CONFIG.EnableCompareCheck) {
            $compareInfo = Get-CompareInfo `
                -Owner $owner `
                -RepoName $repoName `
                -BaseBranch $CONFIG.BaseBranch `
                -HeadBranch $pr.head.ref
        }
        else {
            $compareInfo = [pscustomobject]@{
                CompareSupported = $false
                CompareStatus    = "disabled_by_config"
                AheadBy          = $null
                BehindBy         = $null
                Status           = $null
            }
        }

        $item = [pscustomobject]@{
            Repository       = "$owner/$repoName"
            RepoOwner        = $owner
            RepoName         = $repoName
            PullRequestId    = $pr.id
            PullRequestNo    = $pr.number
            PullRequestTitle = $pr.title
            PullRequestState = $pr.state
            Author           = $pr.user.login
            BaseBranch       = $pr.base.ref
            HeadBranch       = $pr.head.ref
            CreatedAt        = $pr.created_at
            UpdatedAt        = $pr.updated_at
            HtmlUrl          = $pr.html_url
            CompareEnabled   = $CONFIG.EnableCompareCheck
            CompareSupported = $compareInfo.CompareSupported
            CompareResult    = $compareInfo.CompareStatus
            CompareStatus    = $compareInfo.Status
            AheadBy          = $compareInfo.AheadBy
            BehindBy         = $compareInfo.BehindBy
        }

        if (Should-IncludeResult -Item $item) {
            $results.Add($item)
        }
    }
}

# =========================================================
# SAÍDA
# =========================================================

if ($results.Count -eq 0) {
    Write-Log "Nenhum PR encontrado com os filtros atuais." "WARN"
    return
}

$ordered = $results | Sort-Object Repository, PullRequestNo

Write-Host ""
Write-Host "================ RESULTADO ================"
$ordered | Format-Table `
    Repository,
    PullRequestNo,
    Author,
    HeadBranch,
    BaseBranch,
    BehindBy,
    AheadBy,
    CompareSupported,
    CompareResult,
    UpdatedAt -AutoSize

Write-Host ""

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if ($CONFIG.ExportCsv) {
    $csvPath = Join-Path $CONFIG.OutputDir "gitbucket_prs_develop_$timestamp.csv"
    $ordered | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Log "CSV gerado em: $csvPath"
}

if ($CONFIG.ExportJson) {
    $jsonPath = Join-Path $CONFIG.OutputDir "gitbucket_prs_develop_$timestamp.json"
    $ordered | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8
    Write-Log "JSON gerado em: $jsonPath"
}

# =========================================================
# RESUMO
# =========================================================

$totalRepos = ($repos | Measure-Object).Count
$totalPRs   = ($ordered | Measure-Object).Count

$compareSupportedCount = ($ordered | Where-Object { $_.CompareSupported -eq $true } | Measure-Object).Count
$behindCount = ($ordered | Where-Object { $_.BehindBy -gt 0 } | Measure-Object).Count

Write-Host ""
Write-Host "================ RESUMO ================"
Write-Host "Repositórios analisados : $totalRepos"
Write-Host "PRs considerados        : $totalPRs"
Write-Host "Compare suportado       : $compareSupportedCount"
Write-Host "Behind > 0              : $behindCount"
Write-Host "========================================"