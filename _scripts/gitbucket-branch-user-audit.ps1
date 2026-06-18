<#
    GitBucket - Auditoria de Branches por Usuário
    ---------------------------------------------

    Objetivo:
      - Buscar todos os repositórios de uma organização, usuário ou usuário autenticado
      - Listar todas as branches de cada repositório
      - Incluir uma branch de origem provável por heurística de nomenclatura
      - Identificar branches cujo último commit foi feito pelo usuário alvo
      - Gerar relatório com repositório, branch, autor, data e SHA do último commit

    Requisitos:
      - PowerShell 5+ ou PowerShell 7+
      - Token válido do GitBucket
      - Acesso à API do GitBucket
#>

# =========================================================
# ENCODING
# =========================================================

try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
    $OutputEncoding = New-Object System.Text.UTF8Encoding $false
}
catch {
    # Alguns hosts PowerShell/VS Code podem bloquear alteração do encoding.
}

# =========================================================
# CONFIGURAÇÕES
# =========================================================

$CONFIG = @{
    GitBucketUrl = "http://gitemed.emedrs.local:8080"
    Token = "3faf06e7e86563134f14178b2341d2fc8232786a"

    # "org"  = busca repositórios da organização
    # "user" = busca repositórios de um usuário técnico/login
    # "mine" = busca repositórios acessíveis ao token autenticado
    RepoScope = "org"

    # Quando RepoScope = org, use a organização
    RepoOwner = "Desenvolvedores"

    # Quando RepoScope = user, use o login técnico do usuário
    RepoUser = ""

    # Usuário alvo para identificar autoria do último commit
    TargetUser = "Daniel Nogueira"

    IncludeRepoNamePatterns = @()
    ExcludeRepoNamePatterns = @()

    IncludeBranchNamePatterns = @()
    ExcludeBranchNamePatterns = @(
        "^master$",
        "^main$",
        "^develop$"
    )

    OnlyBranchesTouchedByTargetUser = $true

    # Regras para inferir a branch de origem provável.
    # Observação: Git não armazena oficialmente "branch de origem"; este campo é inferido por padrão de nomenclatura.
    BranchOriginRules = @(
        @{ Pattern = "^feature/"; Origin = "develop" },
        @{ Pattern = "^bugfix/";  Origin = "develop" },
        @{ Pattern = "^hotfix/";  Origin = "main" },
        @{ Pattern = "^release/"; Origin = "main" }
    )

    # Valor usado quando nenhuma regra acima combinar com o nome da branch
    DefaultProbableBaseBranch = "develop"

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
# Objetivo: Padronizar saída de log com níveis
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

# Função: Ensure-OutputDir
# Objetivo: Garantir que o diretório de saída exista antes da geração de arquivos
function Ensure-OutputDir {
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
# Objetivo: Normalizar retorno da API, evitando arrays aninhados
function ConvertTo-FlatArray {
    param(
        [AllowNull()]
        $InputObject
    )

    $items = New-Object System.Collections.ArrayList

    function Add-FlatItem {
        param([AllowNull()]$Value)

        if ($null -eq $Value) { return }

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
# Objetivo: Codificar valores usados em URL
function Get-UrlEncodedValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return [System.Uri]::EscapeDataString($Value)
}

# =========================================================
# FILTROS
# =========================================================

# Função: Test-NameIncluded
# Objetivo: Aplicar filtros de inclusão/exclusão por regex
function Test-NameIncluded {
    param(
        [string]$Name,
        [array]$IncludePatterns,
        [array]$ExcludePatterns
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    if ($IncludePatterns.Count -gt 0) {
        $matched = $false

        foreach ($pattern in $IncludePatterns) {
            if ($Name -match $pattern) {
                $matched = $true
                break
            }
        }

        if (-not $matched) {
            return $false
        }
    }

    foreach ($pattern in $ExcludePatterns) {
        if ($Name -match $pattern) {
            return $false
        }
    }

    return $true
}

# =========================================================
# REPOSITÓRIOS
# =========================================================

# Função: Get-RepoOwner
# Objetivo: Extrair owner/login do repositório de forma segura
function Get-RepoOwner {
    param($Repo)

    if ($null -eq $Repo) { return $null }

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

    if ($null -eq $Repo) { return $null }

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

    if ($null -eq $Repo) { return $null }

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
# Objetivo: Buscar repositórios conforme escopo configurado, com paginação segura
function Get-Repositories {
    $repos = New-Object System.Collections.Generic.List[object]
    $seen = @{}
    $page = 1

    while ($true) {
        if ($page -gt $CONFIG.MaxRepoPages) {
            Write-Log "Limite de páginas atingido ao buscar repositórios." "WARN"
            break
        }

        switch ($CONFIG.RepoScope) {
            "org" {
                $encodedOwner = Get-UrlEncodedValue -Value $CONFIG.RepoOwner
                $url = "{0}/api/v3/orgs/{1}/repos?page={2}&per_page=100" -f `
                    $CONFIG.GitBucketUrl, $encodedOwner, $page
            }
            "user" {
                $encodedUser = Get-UrlEncodedValue -Value $CONFIG.RepoUser
                $url = "{0}/api/v3/users/{1}/repos?page={2}&per_page=100" -f `
                    $CONFIG.GitBucketUrl, $encodedUser, $page
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
            Write-Log "Página vazia. Encerrando busca de repositórios." "DEBUG"
            break
        }

        $newCount = 0

        foreach ($repo in $batch) {
            $repoName = Get-RepoName -Repo $repo
            $repoKey  = Get-RepoKey -Repo $repo

            if ([string]::IsNullOrWhiteSpace($repoName) -or [string]::IsNullOrWhiteSpace($repoKey)) {
                continue
            }

            if (-not (Test-NameIncluded `
                -Name $repoName `
                -IncludePatterns $CONFIG.IncludeRepoNamePatterns `
                -ExcludePatterns $CONFIG.ExcludeRepoNamePatterns)
            ) {
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

# =========================================================
# BRANCHES / COMMITS
# =========================================================

# Função: Get-BranchesForRepo
# Objetivo: Buscar todas as branches de um repositório
function Get-BranchesForRepo {
    param(
        [string]$Owner,
        [string]$RepoName
    )

    if ([string]::IsNullOrWhiteSpace($Owner) -or [string]::IsNullOrWhiteSpace($RepoName)) {
        return @()
    }

    $url = "{0}/api/v3/repos/{1}/{2}/branches" -f `
        $CONFIG.GitBucketUrl, $Owner, $RepoName

    try {
        $result = Invoke-GitBucketGet -Url $url
        return @(ConvertTo-FlatArray -InputObject $result)
    }
    catch {
        Write-Log "Falha ao buscar branches de $Owner/$RepoName. $($_.Exception.Message)" "WARN"
        return @()
    }
}

# Função: Get-BranchCommitSha
# Objetivo: Extrair SHA do último commit da branch
function Get-BranchCommitSha {
    param($Branch)

    if (
        ($null -ne $Branch) -and
        ($Branch.PSObject.Properties.Name -contains "commit") -and
        ($null -ne $Branch.commit) -and
        ($Branch.commit.PSObject.Properties.Name -contains "sha")
    ) {
        return [string]$Branch.commit.sha
    }

    return $null
}

# Função: Get-BranchName
# Objetivo: Extrair nome da branch
function Get-BranchName {
    param($Branch)

    if (
        ($null -ne $Branch) -and
        ($Branch.PSObject.Properties.Name -contains "name")
    ) {
        return [string]$Branch.name
    }

    return $null
}

# Função: Get-CommitDetails
# Objetivo: Buscar detalhes do commit pelo SHA
function Get-CommitDetails {
    param(
        [string]$Owner,
        [string]$RepoName,
        [string]$Sha
    )

    if (
        [string]::IsNullOrWhiteSpace($Owner) -or
        [string]::IsNullOrWhiteSpace($RepoName) -or
        [string]::IsNullOrWhiteSpace($Sha)
    ) {
        return $null
    }

    $url = "{0}/api/v3/repos/{1}/{2}/commits/{3}" -f `
        $CONFIG.GitBucketUrl, $Owner, $RepoName, $Sha

    try {
        return Invoke-GitBucketGet -Url $url
    }
    catch {
        Write-Log "Falha ao buscar commit $Sha de $Owner/$RepoName. $($_.Exception.Message)" "DEBUG"
        return $null
    }
}

# Função: Get-CommitAuthorName
# Objetivo: Extrair nome do autor do commit
function Get-CommitAuthorName {
    param($Commit)

    if (
        ($null -ne $Commit) -and
        ($Commit.PSObject.Properties.Name -contains "commit") -and
        ($null -ne $Commit.commit) -and
        ($Commit.commit.PSObject.Properties.Name -contains "author") -and
        ($null -ne $Commit.commit.author) -and
        ($Commit.commit.author.PSObject.Properties.Name -contains "name")
    ) {
        return [string]$Commit.commit.author.name
    }

    return $null
}

# Função: Get-CommitAuthorEmail
# Objetivo: Extrair e-mail do autor do commit
function Get-CommitAuthorEmail {
    param($Commit)

    if (
        ($null -ne $Commit) -and
        ($Commit.PSObject.Properties.Name -contains "commit") -and
        ($null -ne $Commit.commit) -and
        ($Commit.commit.PSObject.Properties.Name -contains "author") -and
        ($null -ne $Commit.commit.author) -and
        ($Commit.commit.author.PSObject.Properties.Name -contains "email")
    ) {
        return [string]$Commit.commit.author.email
    }

    return $null
}

# Função: Get-CommitCommitterName
# Objetivo: Extrair nome do committer do commit
function Get-CommitCommitterName {
    param($Commit)

    if (
        ($null -ne $Commit) -and
        ($Commit.PSObject.Properties.Name -contains "commit") -and
        ($null -ne $Commit.commit) -and
        ($Commit.commit.PSObject.Properties.Name -contains "committer") -and
        ($null -ne $Commit.commit.committer) -and
        ($Commit.commit.committer.PSObject.Properties.Name -contains "name")
    ) {
        return [string]$Commit.commit.committer.name
    }

    return $null
}

# Função: Get-CommitCommitterEmail
# Objetivo: Extrair e-mail do committer do commit
function Get-CommitCommitterEmail {
    param($Commit)

    if (
        ($null -ne $Commit) -and
        ($Commit.PSObject.Properties.Name -contains "commit") -and
        ($null -ne $Commit.commit) -and
        ($Commit.commit.PSObject.Properties.Name -contains "committer") -and
        ($null -ne $Commit.commit.committer) -and
        ($Commit.commit.committer.PSObject.Properties.Name -contains "email")
    ) {
        return [string]$Commit.commit.committer.email
    }

    return $null
}

# Função: Get-CommitDate
# Objetivo: Extrair data do commit
function Get-CommitDate {
    param($Commit)

    if (
        ($null -ne $Commit) -and
        ($Commit.PSObject.Properties.Name -contains "commit") -and
        ($null -ne $Commit.commit) -and
        ($Commit.commit.PSObject.Properties.Name -contains "committer") -and
        ($null -ne $Commit.commit.committer) -and
        ($Commit.commit.committer.PSObject.Properties.Name -contains "date")
    ) {
        return [datetime]$Commit.commit.committer.date
    }

    if (
        ($null -ne $Commit) -and
        ($Commit.PSObject.Properties.Name -contains "commit") -and
        ($null -ne $Commit.commit) -and
        ($Commit.commit.PSObject.Properties.Name -contains "author") -and
        ($null -ne $Commit.commit.author) -and
        ($Commit.commit.author.PSObject.Properties.Name -contains "date")
    ) {
        return [datetime]$Commit.commit.author.date
    }

    return $null
}

# Função: Get-CommitMessage
# Objetivo: Extrair mensagem do commit
function Get-CommitMessage {
    param($Commit)

    if (
        ($null -ne $Commit) -and
        ($Commit.PSObject.Properties.Name -contains "commit") -and
        ($null -ne $Commit.commit) -and
        ($Commit.commit.PSObject.Properties.Name -contains "message")
    ) {
        return [string]$Commit.commit.message
    }

    return $null
}

# Função: Test-CommitBelongsToTargetUser
# Objetivo: Verificar se o commit está associado ao usuário alvo
# Função: Test-CommitBelongsToTargetUser
# Objetivo: Verificar se o commit está associado ao usuário alvo
function Test-CommitBelongsToTargetUser {
    param(
        $Commit,
        [string]$TargetUser
    )

    if ([string]::IsNullOrWhiteSpace($TargetUser)) {
        return $false
    }

    $target = $TargetUser.Trim().ToLowerInvariant()

    $values = @(
        (Get-CommitAuthorName -Commit $Commit)
        (Get-CommitAuthorEmail -Commit $Commit)
        (Get-CommitCommitterName -Commit $Commit)
        (Get-CommitCommitterEmail -Commit $Commit)
    ) | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    }

    foreach ($value in $values) {

        $normalized = $value.Trim().ToLowerInvariant()

        if ($normalized -like "*$target*") {
            return $true
        }
    }

    return $false
}


# Função: Get-ProbableBaseBranch
# Objetivo: Inferir a branch de origem provável com base no padrão de nomenclatura da branch
function Get-ProbableBaseBranch {
    param(
        [string]$BranchName
    )

    if ([string]::IsNullOrWhiteSpace($BranchName)) {
        return $null
    }

    foreach ($rule in $CONFIG.BranchOriginRules) {
        if (
            ($rule.ContainsKey("Pattern")) -and
            ($rule.ContainsKey("Origin")) -and
            ($BranchName -match [string]$rule.Pattern)
        ) {
            return [string]$rule.Origin
        }
    }

    return [string]$CONFIG.DefaultProbableBaseBranch
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
# Objetivo: Gerar relatório HTML de branches por usuário
function New-HtmlReport {
    param(
        $Items,
        $Path
    )

    $generatedAt = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

    $rows = $Items | ForEach-Object {
        $repo = ConvertTo-HtmlSafeText $_.Repository
        $branch = ConvertTo-HtmlSafeText $_.Branch
        $origin = ConvertTo-HtmlSafeText $_.ProbableBaseBranch
        $author = ConvertTo-HtmlSafeText $_.AuthorName
        $email = ConvertTo-HtmlSafeText $_.AuthorEmail
        $committer = ConvertTo-HtmlSafeText $_.CommitterName
        $date = if ($null -ne $_.CommitDate) { ConvertTo-HtmlSafeText ([datetime]$_.CommitDate).ToString("dd/MM/yyyy HH:mm") } else { "" }
        $sha = ConvertTo-HtmlSafeText $_.CommitSha
        $msg = ConvertTo-HtmlSafeText $_.CommitMessage

        "<tr><td>$repo</td><td>$branch</td><td>$origin</td><td>$author</td><td>$email</td><td>$committer</td><td>$date</td><td>$sha</td><td>$msg</td></tr>"
    }

$html = @"
<html>
<head>
<meta charset="UTF-8">
<title>GitBucket Branch Audit</title>
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
    vertical-align: top;
}
th {
    background: #eeeeee;
}
</style>
</head>
<body>
<h2>GitBucket Branch Audit</h2>
<p>Gerado em: $generatedAt</p>
<p>Escopo de repositórios: $($CONFIG.RepoScope)</p>
<p>Owner/Organização: $($CONFIG.RepoOwner)</p>
<p>Usuário de repositórios: $($CONFIG.RepoUser)</p>
<p>Usuário alvo: $($CONFIG.TargetUser)</p>

<table>
<tr>
    <th>Repo</th>
    <th>Branch</th>
    <th>Branch Origem Provável</th>
    <th>Autor</th>
    <th>E-mail Autor</th>
    <th>Committer</th>
    <th>Data Commit</th>
    <th>SHA</th>
    <th>Mensagem</th>
</tr>
$($rows -join "`n")
</table>
</body>
</html>
"@

    Set-Content -Path $Path -Value $html -Encoding UTF8
}

# =========================================================
# VALIDAÇÕES INICIAIS
# =========================================================

if ([string]::IsNullOrWhiteSpace($CONFIG.Token) -or $CONFIG.Token -eq "SEU_TOKEN_AQUI") {
    throw "Configure o token em `$CONFIG.Token antes de executar."
}

Ensure-OutputDir

Write-Log "Iniciando auditoria de branches no GitBucket"
Write-Log "RepoScope: $($CONFIG.RepoScope)"
Write-Log "RepoOwner: $($CONFIG.RepoOwner)"
Write-Log "RepoUser: $($CONFIG.RepoUser)"
Write-Log "TargetUser: $($CONFIG.TargetUser)"
Write-Log "OnlyBranchesTouchedByTargetUser: $($CONFIG.OnlyBranchesTouchedByTargetUser)"

# =========================================================
# EXECUÇÃO
# =========================================================

$repos = Get-Repositories

Write-Log "Total de repositórios encontrados: $($repos.Count)"

$results = New-Object System.Collections.Generic.List[object]

foreach ($repoObj in $repos) {
    $owner = Get-RepoOwner -Repo $repoObj
    $repoName = Get-RepoName -Repo $repoObj

    if ([string]::IsNullOrWhiteSpace($owner) -or [string]::IsNullOrWhiteSpace($repoName)) {
        continue
    }

    Write-Log "Analisando repositório $owner/$repoName" "DEBUG"

    $branches = Get-BranchesForRepo -Owner $owner -RepoName $repoName

    foreach ($branch in $branches) {
        $branchName = Get-BranchName -Branch $branch

        if (-not (Test-NameIncluded `
            -Name $branchName `
            -IncludePatterns $CONFIG.IncludeBranchNamePatterns `
            -ExcludePatterns $CONFIG.ExcludeBranchNamePatterns)
        ) {
            continue
        }

        $sha = Get-BranchCommitSha -Branch $branch
        $commit = Get-CommitDetails -Owner $owner -RepoName $repoName -Sha $sha

        if ($CONFIG.OnlyBranchesTouchedByTargetUser -and -not (Test-CommitBelongsToTargetUser -Commit $commit -TargetUser $CONFIG.TargetUser)) {
            continue
        }

        $item = [pscustomobject]@{
            Repository         = "$owner/$repoName"
            Branch             = $branchName
            ProbableBaseBranch = Get-ProbableBaseBranch -BranchName $branchName
            CommitSha          = $sha
            CommitDate     = Get-CommitDate -Commit $commit
            AuthorName     = Get-CommitAuthorName -Commit $commit
            AuthorEmail    = Get-CommitAuthorEmail -Commit $commit
            CommitterName  = Get-CommitCommitterName -Commit $commit
            CommitterEmail = Get-CommitCommitterEmail -Commit $commit
            CommitMessage  = Get-CommitMessage -Commit $commit
        }

        $results.Add($item)
    }
}

# =========================================================
# SAÍDA
# =========================================================

if ($results.Count -eq 0) {
    Write-Log "Nenhuma branch encontrada com os filtros atuais." "WARN"
    return
}

$ordered = $results | Sort-Object Repository, ProbableBaseBranch, Branch

Write-Host ""
Write-Host "================ RESULTADO ================"
$ordered | Format-Table `
    Repository,
    Branch,
    ProbableBaseBranch,
    AuthorName,
    AuthorEmail,
    CommitterName,
    CommitDate,
    CommitSha -AutoSize

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if ($CONFIG.ExportCsv) {
    $safeTargetUser = ($CONFIG.TargetUser -replace "[^\w\-]", "_")
    $csvPath = Join-Path $CONFIG.OutputDir "gitbucket_branches_$safeTargetUser`_$timestamp.csv"
    $ordered | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Log "CSV gerado em: $csvPath"
}

if ($CONFIG.ExportJson) {
    $safeTargetUser = ($CONFIG.TargetUser -replace "[^\w\-]", "_")
    $jsonPath = Join-Path $CONFIG.OutputDir "gitbucket_branches_$safeTargetUser`_$timestamp.json"
    $ordered | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8
    Write-Log "JSON gerado em: $jsonPath"
}

if ($CONFIG.ExportHtml) {
    $safeTargetUser = ($CONFIG.TargetUser -replace "[^\w\-]", "_")
    $htmlPath = Join-Path $CONFIG.OutputDir "gitbucket_branches_$safeTargetUser`_$timestamp.html"
    New-HtmlReport -Items $ordered -Path $htmlPath
    Write-Log "HTML gerado em: $htmlPath"
}

Write-Host ""
Write-Host "================ RESUMO ================"
Write-Host "Repositórios analisados : $($repos.Count)"
Write-Host "Branches encontradas    : $($ordered.Count)"
Write-Host "Usuário alvo            : $($CONFIG.TargetUser)"
Write-Host "========================================"