<#
    GitBucket - Auditoria de Pull Requests para Branch Base - v2
    ------------------------------------------------------------

    Objetivo:
      - Listar PRs abertos com destino na branch configurada (ex: develop)
      - Opcionalmente identificar se a branch do PR está desatualizada (behind)
        usando exclusivamente a API do GitBucket

    Principais recursos:
      - Paginação segura (evita loop infinito)
      - Deduplicação de repositórios
      - Filtro de repositórios (nome, arquivado)
      - Validação opcional da existência da branch base
      - Comparação opcional de branches (ahead/behind)
      - Exportação em CSV, JSON e HTML
      - Resumo por autor

    Requisitos:
      - PowerShell 5+ ou PowerShell 7+
      - Token válido do GitBucket

    Observações:
      - O endpoint /compare pode não ser suportado em todas as versões do GitBucket
      - O script continua funcionando mesmo sem compare
      - A API do GitBucket pode retornar objeto único, array ou array aninhado; por isso
        o script normaliza os retornos antes de processar
#>

# =========================================================
# ENCODING
# =========================================================

# Força saída UTF-8 no console para evitar caracteres quebrados em logs
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# =========================================================
# CONFIGURAÇÕES
# =========================================================

# Configuração central do script
$CONFIG = @{
    GitBucketUrl = "http://gitemed.emedrs.local:8080"
    Token = "3faf06e7e86563134f14178b2341d2fc8232786a"

    # Escopo de busca dos repositórios:
    # "org"  = repositórios da organização
    # "user" = repositórios de um usuário
    # "mine" = repositórios acessíveis ao usuário autenticado
    RepoScope = "org"
    OwnerName = "Desenvolvedores"

    BaseBranch = "main"
    PullRequestState = "open"

    EnableCompareCheck = $true
    IncludeUpToDateWhenCompareEnabled = $false

    IgnoreArchivedRepositories = $true
    ValidateBaseBranchExists = $true

    IncludeRepoNamePatterns = @()
    ExcludeRepoNamePatterns = @("^rel-")

    ExportCsv  = $true
    ExportJson = $false
    ExportHtml = $true

    OutputDir = "$PSScriptRoot\out"

    TimeoutSec = 60
    MaxRepoPages = 200
    VerboseMode = $true
}

# =========================================================
# LOG
# =========================================================

# Função: Write-Log
# Objetivo: Padronizar saída de log com níveis (INFO, DEBUG, etc)
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR","DEBUG")]
        [string]$Level = "INFO"
    )

    if ($Level -eq "DEBUG" -and -not $CONFIG.VerboseMode) { return }

    $prefix = "[{0}] {1}" -f $Level, (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Write-Host "$prefix - $Message"
}

# =========================================================
# INFRA / HTTP
# =========================================================

# Função: Initialize-OutputDir
# Objetivo: Garantir existência da pasta de saída
function Initialize-OutputDir {
    if (-not (Test-Path $CONFIG.OutputDir)) {
        New-Item -ItemType Directory -Path $CONFIG.OutputDir -Force | Out-Null
    }
}

# Função: Get-AuthHeaders
# Objetivo: Retornar headers padrão para autenticação na API
function Get-AuthHeaders {
    return @{
        Authorization = "token $($CONFIG.Token)"
        Accept        = "application/json"
    }
}

# Função: ConvertTo-FlatArray
# Objetivo: Normalizar retorno da API, evitando System.Object[] em owner/repo
function ConvertTo-FlatArray {
    param(
        [AllowNull()]
        $InputObject
    )

    $items = New-Object System.Collections.ArrayList

    function Add-FlatItem {
        param([AllowNull()]$Value)

        if ($null -eq $Value) {
            return
        }

        if ($Value -is [System.Array]) {
            foreach ($subItem in $Value) {
                Add-FlatItem -Value $subItem
            }
        }
        else {
            [void]$items.Add($Value)
        }
    }

    Add-FlatItem -Value $InputObject

    return $items.ToArray()
}

# Função: Invoke-GitBucketGet
# Objetivo: Centralizar chamadas GET para API do GitBucket
function Invoke-GitBucketGet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    Write-Log "GET $Url" "DEBUG"

    return Invoke-RestMethod `
        -Uri $Url `
        -Method Get `
        -Headers (Get-AuthHeaders) `
        -TimeoutSec $CONFIG.TimeoutSec
}

# Função: Get-UrlEncodedValue
# Objetivo: Codificar valores usados em path de URL, como branch feature/xpto
function Get-UrlEncodedValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return [System.Uri]::EscapeDataString($Value)
}

# =========================================================
# REPOSITÓRIOS
# =========================================================

# Função: Test-RepoNameIncluded
# Objetivo: Aplicar filtros de inclusão/exclusão por nome de repositório
function Test-RepoNameIncluded {
    param([string]$RepoName)

    if ([string]::IsNullOrWhiteSpace($RepoName)) {
        return $false
    }

    if ($CONFIG.IncludeRepoNamePatterns.Count -gt 0) {
        $match = $false

        foreach ($p in $CONFIG.IncludeRepoNamePatterns) {
            if ($RepoName -match $p) {
                $match = $true
                break
            }
        }

        if (-not $match) {
            return $false
        }
    }

    foreach ($p in $CONFIG.ExcludeRepoNamePatterns) {
        if ($RepoName -match $p) {
            return $false
        }
    }

    return $true
}

# Função: Test-RepoIsArchived
# Objetivo: Identificar se repositório está arquivado, quando o campo existir
function Test-RepoIsArchived {
    param($Repo)

    if ($null -eq $Repo) {
        return $false
    }

    if ($Repo.PSObject.Properties.Name -contains "archived") {
        return [bool]$Repo.archived
    }

    return $false
}

# Função: Get-RepoOwner
# Objetivo: Extrair owner/login do repositório de forma segura
function Get-RepoOwner {
    param($Repo)

    if ($null -eq $Repo) {
        return $null
    }

    if (
        ($Repo.PSObject.Properties.Name -contains "owner") -and
        ($null -ne $Repo.owner) -and
        ($Repo.owner.PSObject.Properties.Name -contains "login")
    ) {
        return [string]$Repo.owner.login
    }

    if ($Repo.PSObject.Properties.Name -contains "full_name") {
        $parts = ([string]$Repo.full_name).Split("/")
        if ($parts.Count -ge 2) {
            return [string]$parts[0]
        }
    }

    return $null
}

# Função: Get-RepoName
# Objetivo: Extrair nome do repositório de forma segura
function Get-RepoName {
    param($Repo)

    if ($null -eq $Repo) {
        return $null
    }

    if ($Repo.PSObject.Properties.Name -contains "name") {
        return [string]$Repo.name
    }

    if ($Repo.PSObject.Properties.Name -contains "full_name") {
        $parts = ([string]$Repo.full_name).Split("/")
        if ($parts.Count -ge 2) {
            return [string]$parts[1]
        }
    }

    return $null
}

# Função: Get-RepoKey
# Objetivo: Obter chave única do repositório para deduplicação
function Get-RepoKey {
    param($Repo)

    if ($null -eq $Repo) {
        return $null
    }

    if (
        ($Repo.PSObject.Properties.Name -contains "full_name") -and
        (-not [string]::IsNullOrWhiteSpace([string]$Repo.full_name))
    ) {
        return [string]$Repo.full_name
    }

    $owner = Get-RepoOwner -Repo $Repo
    $name  = Get-RepoName -Repo $Repo

    if ([string]::IsNullOrWhiteSpace($owner) -or [string]::IsNullOrWhiteSpace($name)) {
        return $null
    }

    return "$owner/$name"
}

# Função: Get-Repositories
# Objetivo: Buscar repositórios via API com proteção contra paginação inválida
function Get-Repositories {

    $repos = New-Object System.Collections.Generic.List[object]
    $seen = @{}
    $page = 1

    while ($true) {

        if ($page -gt $CONFIG.MaxRepoPages) {
            Write-Log "Limite de páginas atingido." "WARN"
            break
        }

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
            Write-Log "Erro ao buscar repositórios na página $page. $($_.Exception.Message)" "ERROR"
            break
        }

        $batch = ConvertTo-FlatArray -InputObject $result

        if ($batch.Count -eq 0) {
            Write-Log "Página vazia. Encerrando." "DEBUG"
            break
        }

        $newCount = 0

        foreach ($repo in $batch) {

            $repoName = Get-RepoName -Repo $repo
            $repoKey  = Get-RepoKey -Repo $repo

            if ([string]::IsNullOrWhiteSpace($repoName) -or [string]::IsNullOrWhiteSpace($repoKey)) {
                Write-Log "Item ignorado por não possuir nome/owner válido." "DEBUG"
                continue
            }

            if (-not (Test-RepoNameIncluded -RepoName $repoName)) {
                continue
            }

            if ($CONFIG.IgnoreArchivedRepositories -and (Test-RepoIsArchived -Repo $repo)) {
                continue
            }

            if (-not $seen.ContainsKey($repoKey)) {
                $seen[$repoKey] = $true
                $repos.Add($repo)
                $newCount++
            }
        }

        if ($newCount -eq 0) {
            Write-Log "Sem novos repositórios. Paginação repetida ou encerrada." "WARN"
            break
        }

        Write-Log "Página $page - recebidos: $($batch.Count), novos: $newCount, acumulado: $($repos.Count)" "DEBUG"
        $page++
    }

    return $repos.ToArray()
}

# Função: Test-BranchExists
# Objetivo: Validar se branch base existe no repositório
function Test-BranchExists {
    param(
        [string]$Owner,
        [string]$RepoName,
        [string]$Branch
    )

    if (
        [string]::IsNullOrWhiteSpace($Owner) -or
        [string]::IsNullOrWhiteSpace($RepoName) -or
        [string]::IsNullOrWhiteSpace($Branch)
    ) {
        return $false
    }

    $encodedBranch = Get-UrlEncodedValue -Value $Branch

    $url = "{0}/api/v3/repos/{1}/{2}/branches/{3}" -f `
        $CONFIG.GitBucketUrl, $Owner, $RepoName, $encodedBranch

    try {
        return ($null -ne (Invoke-GitBucketGet -Url $url))
    }
    catch {
        Write-Log "Branch '$Branch' não encontrada ou endpoint indisponível em $Owner/$RepoName." "DEBUG"
        return $false
    }
}

# =========================================================
# PULL REQUESTS
# =========================================================

# Função: Get-OpenPullRequestsForRepo
# Objetivo: Buscar PRs abertos de um repositório
function Get-OpenPullRequestsForRepo {
    param(
        [string]$Owner,
        [string]$RepoName
    )

    if ([string]::IsNullOrWhiteSpace($Owner) -or [string]::IsNullOrWhiteSpace($RepoName)) {
        return @()
    }

    $url = "{0}/api/v3/repos/{1}/{2}/pulls?state={3}" -f `
        $CONFIG.GitBucketUrl, $Owner, $RepoName, $CONFIG.PullRequestState

    try {
        $result = Invoke-GitBucketGet -Url $url
        return @(ConvertTo-FlatArray -InputObject $result)
    }
    catch {
        Write-Log "Falha ao buscar PRs de $Owner/$RepoName. $($_.Exception.Message)" "WARN"
        return @()
    }
}

# Função: Get-PullRequestAuthor
# Objetivo: Extrair autor do PR de forma segura
function Get-PullRequestAuthor {
    param($PullRequest)

    if (
        ($PullRequest.PSObject.Properties.Name -contains "user") -and
        ($null -ne $PullRequest.user) -and
        ($PullRequest.user.PSObject.Properties.Name -contains "login")
    ) {
        return [string]$PullRequest.user.login
    }

    return $null
}

# Função: Get-PullRequestBaseBranch
# Objetivo: Extrair branch base do PR de forma segura
function Get-PullRequestBaseBranch {
    param($PullRequest)

    if (
        ($PullRequest.PSObject.Properties.Name -contains "base") -and
        ($null -ne $PullRequest.base) -and
        ($PullRequest.base.PSObject.Properties.Name -contains "ref")
    ) {
        return [string]$PullRequest.base.ref
    }

    return $null
}

# Função: Get-PullRequestHeadBranch
# Objetivo: Extrair branch origem do PR de forma segura
function Get-PullRequestHeadBranch {
    param($PullRequest)

    if (
        ($PullRequest.PSObject.Properties.Name -contains "head") -and
        ($null -ne $PullRequest.head) -and
        ($PullRequest.head.PSObject.Properties.Name -contains "ref")
    ) {
        return [string]$PullRequest.head.ref
    }

    return $null
}

# Função: Get-CompareInfo
# Objetivo: Obter ahead/behind via endpoint compare, se disponível
function Get-CompareInfo {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$Base,
        [string]$Head
    )

    if (
        [string]::IsNullOrWhiteSpace($Owner) -or
        [string]::IsNullOrWhiteSpace($Repo) -or
        [string]::IsNullOrWhiteSpace($Base) -or
        [string]::IsNullOrWhiteSpace($Head)
    ) {
        return [pscustomobject]@{
            CompareSupported = $false
            CompareResult    = "invalid_parameters"
            CompareStatus    = $null
            AheadBy          = $null
            BehindBy         = $null
            ErrorMessage     = "Parâmetros inválidos para comparação."
        }
    }

    $encodedBase = Get-UrlEncodedValue -Value $Base
    $encodedHead = Get-UrlEncodedValue -Value $Head

    $url = "{0}/api/v3/repos/{1}/{2}/compare/{3}...{4}" -f `
        $CONFIG.GitBucketUrl, $Owner, $Repo, $encodedBase, $encodedHead

    try {
        $c = Invoke-GitBucketGet -Url $url

        $aheadBy  = $null
        $behindBy = $null
        $status   = $null

        if ($c.PSObject.Properties.Name -contains "ahead_by") {
            $aheadBy = $c.ahead_by
        }

        if ($c.PSObject.Properties.Name -contains "behind_by") {
            $behindBy = $c.behind_by
        }

        if ($c.PSObject.Properties.Name -contains "status") {
            $status = $c.status
        }

        return [pscustomobject]@{
            CompareSupported = $true
            CompareResult    = "ok"
            CompareStatus    = $status
            AheadBy          = $aheadBy
            BehindBy         = $behindBy
            ErrorMessage     = $null
        }
    }
    catch {
        return [pscustomobject]@{
            CompareSupported = $false
            CompareResult    = "not_supported_or_failed"
            CompareStatus    = $null
            AheadBy          = $null
            BehindBy         = $null
            ErrorMessage     = $_.Exception.Message
        }
    }
}

# Função: Test-ShouldIncludeResult
# Objetivo: Aplicar regra final de inclusão no resultado
function Test-ShouldIncludeResult {
    param($Item)

    if (-not $CONFIG.EnableCompareCheck) { return $true }

    if ($CONFIG.IncludeUpToDateWhenCompareEnabled) { return $true }

    if (-not $Item.CompareSupported) { return $true }

    if ($null -eq $Item.BehindBy) { return $true }

    return ([int]$Item.BehindBy -gt 0)
}

# =========================================================
# HTML
# =========================================================

# Função: ConvertTo-HtmlSafeText
# Objetivo: Escapar textos para evitar quebra no relatório HTML
function ConvertTo-HtmlSafeText {
    param($Value)

    if ($null -eq $Value) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

# Função: New-HtmlReport
# Objetivo: Gerar relatório HTML simples para visualização/Teams
function New-HtmlReport {
    param(
        $Items,
        $Path
    )

    $generatedAt = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

    # Monta linhas da tabela
    $rows = $Items | ForEach-Object {
        $repo   = ConvertTo-HtmlSafeText $_.Repository
        $pr     = ConvertTo-HtmlSafeText $_.PullRequestNo
        $author = ConvertTo-HtmlSafeText $_.Author
        $title  = ConvertTo-HtmlSafeText $_.PullRequestTitle
        $head   = ConvertTo-HtmlSafeText $_.HeadBranch
        $base   = ConvertTo-HtmlSafeText $_.BaseBranch
        $behind = ConvertTo-HtmlSafeText $_.BehindBy
        $ahead  = ConvertTo-HtmlSafeText $_.AheadBy
        $url    = ConvertTo-HtmlSafeText $_.HtmlUrl

        "<tr><td>$repo</td><td>$pr</td><td>$author</td><td>$title</td><td>$head</td><td>$base</td><td>$behind</td><td>$ahead</td><td><a href='$url'>Abrir</a></td></tr>"
    }

    # HTML (IMPORTANTE: delimitadores sem indentação)
$html = @"
<html>
<head>
<meta charset="UTF-8">
<title>GitBucket PR Audit</title>
<style>
body {
    font-family: Segoe UI, Arial, sans-serif;
    margin: 24px;
}
table {
    border-collapse: collapse;
    width: 100%;
}
th, td {
    border: 1px solid #cccccc;
    padding: 6px;
    font-size: 13px;
}
th {
    background: #eeeeee;
}
</style>
</head>
<body>
<h2>GitBucket PR Audit</h2>
<p>Gerado em: $generatedAt</p>
<p>Branch base: $($CONFIG.BaseBranch)</p>

<table>
<tr>
    <th>Repo</th>
    <th>PR</th>
    <th>Autor</th>
    <th>Título</th>
    <th>Branch Origem</th>
    <th>Branch Base</th>
    <th>Behind</th>
    <th>Ahead</th>
    <th>Link</th>
</tr>
$($rows -join "`n")
</table>
</body>
</html>
"@

    # Grava arquivo
    Set-Content -Path $Path -Value $html -Encoding UTF8
}

# =========================================================
# VALIDAÇÕES INICIAIS
# =========================================================

if ([string]::IsNullOrWhiteSpace($CONFIG.Token) -or $CONFIG.Token -eq "SEU_TOKEN_AQUI") {
    throw "Configure o token em `$CONFIG.Token antes de executar."
}

Initialize-OutputDir

Write-Log "Iniciando auditoria de PRs no GitBucket"
Write-Log "RepoScope: $($CONFIG.RepoScope)"
Write-Log "OwnerName: $($CONFIG.OwnerName)"
Write-Log "BaseBranch: $($CONFIG.BaseBranch)"
Write-Log "EnableCompareCheck: $($CONFIG.EnableCompareCheck)"
Write-Log "ValidateBaseBranchExists: $($CONFIG.ValidateBaseBranchExists)"
Write-Log "MaxRepoPages: $($CONFIG.MaxRepoPages)"

# =========================================================
# EXECUÇÃO - REPOSITÓRIOS
# =========================================================

$repos = Get-Repositories

Write-Log "Total de repositórios únicos encontrados: $($repos.Count)"

if (-not $repos -or $repos.Count -eq 0) {
    Write-Log "Nenhum repositório encontrado. Encerrando." "WARN"
    return
}

# =========================================================
# EXECUÇÃO - PULL REQUESTS
# =========================================================

$results = New-Object System.Collections.Generic.List[object]

foreach ($r in $repos) {

    $owner = Get-RepoOwner -Repo $r
    $repo  = Get-RepoName -Repo $r

    if ([string]::IsNullOrWhiteSpace($owner) -or [string]::IsNullOrWhiteSpace($repo)) {
        Write-Log "Repositório ignorado por owner/name inválido." "DEBUG"
        continue
    }

    Write-Log "Analisando repositório $owner/$repo" "DEBUG"

    if ($CONFIG.ValidateBaseBranchExists -and -not (Test-BranchExists -Owner $owner -RepoName $repo -Branch $CONFIG.BaseBranch)) {
        Write-Log "Ignorando $owner/$repo porque a branch '$($CONFIG.BaseBranch)' não foi encontrada." "DEBUG"
        continue
    }

    $prs = Get-OpenPullRequestsForRepo -Owner $owner -RepoName $repo

    foreach ($pr in $prs) {

        $baseBranch = Get-PullRequestBaseBranch -PullRequest $pr
        $headBranch = Get-PullRequestHeadBranch -PullRequest $pr

        if ($baseBranch -ne $CONFIG.BaseBranch) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($headBranch)) {
            Write-Log "PR ignorado em $owner/$repo por branch origem inválida." "DEBUG"
            continue
        }

        if ($CONFIG.EnableCompareCheck) {
            $compare = Get-CompareInfo `
                -Owner $owner `
                -Repo $repo `
                -Base $CONFIG.BaseBranch `
                -Head $headBranch
        }
        else {
            $compare = [pscustomobject]@{
                CompareSupported = $false
                CompareResult    = "disabled_by_config"
                CompareStatus    = $null
                AheadBy          = $null
                BehindBy         = $null
                ErrorMessage     = $null
            }
        }

        $item = [pscustomobject]@{
            Repository       = "$owner/$repo"
            PullRequestNo    = $(if ($pr.PSObject.Properties.Name -contains "number") { $pr.number } else { $null })
            PullRequestTitle = $(if ($pr.PSObject.Properties.Name -contains "title") { $pr.title } else { $null })
            PullRequestState = $(if ($pr.PSObject.Properties.Name -contains "state") { $pr.state } else { $null })
            Author           = Get-PullRequestAuthor -PullRequest $pr
            HeadBranch       = $headBranch
            BaseBranch       = $CONFIG.BaseBranch
            CreatedAt        = $(if ($pr.PSObject.Properties.Name -contains "created_at") { $pr.created_at } else { $null })
            UpdatedAt        = $(if ($pr.PSObject.Properties.Name -contains "updated_at") { $pr.updated_at } else { $null })
            HtmlUrl          = $(if ($pr.PSObject.Properties.Name -contains "html_url") { $pr.html_url } else { $null })

            CompareEnabled   = $CONFIG.EnableCompareCheck
            CompareSupported = $compare.CompareSupported
            CompareResult    = $compare.CompareResult
            CompareStatus    = $compare.CompareStatus
            AheadBy          = $compare.AheadBy
            BehindBy         = $compare.BehindBy
            CompareError     = $compare.ErrorMessage
        }

        if (Test-ShouldIncludeResult -Item $item) {
            $results.Add($item)
        }
    }
}

# =========================================================
# SAÍDA
# =========================================================

if ($results.Count -eq 0) {
    Write-Log "Nenhum PR encontrado com os filtros atuais." "WARN"
}
else {
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

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    if ($CONFIG.ExportCsv) {
        $csvPath = Join-Path $CONFIG.OutputDir "gitbucket_prs_$($CONFIG.BaseBranch)_$timestamp.csv"
        $ordered | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "CSV gerado em: $csvPath"
    }

    if ($CONFIG.ExportJson) {
        $jsonPath = Join-Path $CONFIG.OutputDir "gitbucket_prs_$($CONFIG.BaseBranch)_$timestamp.json"
        $ordered | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8
        Write-Log "JSON gerado em: $jsonPath"
    }

    if ($CONFIG.ExportHtml) {
        $htmlPath = Join-Path $CONFIG.OutputDir "gitbucket_prs_$($CONFIG.BaseBranch)_$timestamp.html"
        New-HtmlReport -Items $ordered -Path $htmlPath
        Write-Log "HTML gerado em: $htmlPath"
    }

    $totalPRs              = ($ordered | Measure-Object).Count
    $compareSupportedCount = ($ordered | Where-Object { $_.CompareSupported -eq $true } | Measure-Object).Count
    $compareNotSupported   = ($ordered | Where-Object { $_.CompareSupported -eq $false } | Measure-Object).Count
    $behindCount           = ($ordered | Where-Object { $_.BehindBy -gt 0 } | Measure-Object).Count
    $alignedCount          = ($ordered | Where-Object { $_.CompareSupported -eq $true -and $_.BehindBy -eq 0 } | Measure-Object).Count

    Write-Host ""
    Write-Host "================ RESUMO ================"
    Write-Host "Repositórios únicos encontrados : $($repos.Count)"
    Write-Host "PRs considerados                : $totalPRs"
    Write-Host "Compare suportado               : $compareSupportedCount"
    Write-Host "Compare indisponível            : $compareNotSupported"
    Write-Host "Behind > 0                      : $behindCount"
    Write-Host "Behind = 0                      : $alignedCount"
    Write-Host "========================================"

    Write-Host ""
    Write-Host "================ RESUMO POR AUTOR ================"
    $ordered |
        Group-Object Author |
        Sort-Object Count -Descending |
        Select-Object Name, Count |
        Format-Table -AutoSize
}