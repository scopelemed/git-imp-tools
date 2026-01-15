<#
check-branches.ps1 — Varredor de branches no GitBucket (pronto para rodar)

USO BÁSICO:
  1) Salve este arquivo como: E:\Projetos\git-imp\check-branches.ps1
  2) No PowerShell:
       cd "E:\Projetos\git-imp"
       .\check-branches.ps1 -Verbose

PARÂMETROS ÚTEIS:
  -Server       URL do GitBucket. Ex.: http://gitemed.emedrs.local:8080
  -Owner        Organização/Usuário. Ex.: Desenvolvedores
  -Branch       Nome da branch a procurar. Ex.: feature/1522818442
  -Token        Personal Access Token (opcional). Se vazio, usa Basic Auth (se habilitado)
  -UseBasicAuth Usa Basic Auth (login/senha) quando não há Token. Padrão: TRUE (se Token vazio)
  -User / -Pass Credenciais para Basic Auth
  -PerPage      Tamanho da página na API. Padrão: 100
  -MaxPages     Limite de páginas para evitar loop infinito. Padrão: 50
  -TimeoutSec   Timeout das chamadas HTTP em segundos. Padrão: 15
  -ExportCsv    Se presente, exporta CSV em -CsvPath
  -CsvPath      Caminho do CSV (padrão: .\repos-com-branch.csv)
  -OpenCsv      Abre o CSV após gerar (usar com -ExportCsv)
#>

[CmdletBinding()]
param(
  [string]$Server = 'http://gitemed.emedrs.local:8080',
  [string]$Owner  = 'Desenvolvedores',
  [string]$Branch = 'feature/1522818442',

  [string]$Token  = '',
  [switch]$UseBasicAuth,
  [string]$User   = 'xxxxxxxxx',
  [string]$Pass   = 'xxxxxxxxxx',

  [int]$PerPage   = 100,
  [int]$MaxPages  = 50,
  [int]$TimeoutSec = 15,

  [switch]$ExportCsv,
  [string]$CsvPath = '.\repos-com-branch.csv',
  [switch]$OpenCsv
)

# Se não houver Token e o usuário não informou -UseBasicAuth explicitamente, assume TRUE
if (-not $Token -and -not $PSBoundParameters.ContainsKey('UseBasicAuth')) {
  $UseBasicAuth = $true
}

# Preferências de execução
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'
$VerbosePreference  = if ($PSBoundParameters.ContainsKey('Verbose')) { 'Continue' } else { 'SilentlyContinue' }

function Get-AuthHeader {
  if ($Token -and -not [string]::IsNullOrWhiteSpace($Token)) {
    return @{ Authorization = "token $Token" }
  }
  elseif ($UseBasicAuth) {
    $pair = "{0}:{1}" -f $User,$Pass
    $b64  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
    return @{ Authorization = "Basic $b64" }
  }
  else {
    return @{}
  }
}

function Invoke-GitBucketApi {
  param(
    [Parameter(Mandatory)][string]$Path,
    [int]$Timeout = $TimeoutSec
  )
  $headers = Get-AuthHeader
  $url = "$Server/api/v3/$Path"
  Write-Verbose "GET $url"
  try {
    return Invoke-RestMethod -Method GET -Uri $url -Headers $headers -TimeoutSec $Timeout -ErrorAction Stop
  }
  catch {
    throw "Falha ao chamar API: $url - $($_.Exception.Message)"
  }
}

function Test-ApiReachable {
  try {
    $null = Invoke-GitBucketApi -Path 'rate_limit' -Timeout 10
    return $true
  }
  catch {
    Write-Warning $_
    return $false
  }
}

function Get-Repos {
  $all = New-Object System.Collections.Generic.List[object]
  $page = 1
  $lastPageIds = $null

  while ($page -le $MaxPages) {
    $percent = if ($MaxPages -gt 0) { [int](($page-1)/$MaxPages*100) } else { 0 }
    Write-Progress -Activity "Listando repositórios" -Status "Página $page" -PercentComplete $percent

    try {
      $batch = Invoke-GitBucketApi -Path ("orgs/{0}/repos?per_page={1}&page={2}" -f $Owner,$PerPage,$page)
    }
    catch {
      # se org falhar, tenta como usuário
      $batch = Invoke-GitBucketApi -Path ("users/{0}/repos?per_page={1}&page={2}" -f $Owner,$PerPage,$page)
    }

    if (-not $batch -or $batch.Count -eq 0) {
      Write-Verbose "Página $page vazia — fim da paginação."
      break
    }

    # Proteção contra repetição de página
    $currIds = ($batch | ForEach-Object { $_.id })
    if ($lastPageIds -ne $null) {
      if (($currIds -join ',') -eq ($lastPageIds -join ',')) {
        Write-Warning "A API parece estar repetindo a mesma página. Interrompendo para evitar loop infinito."
        break
      }
    }
    $lastPageIds = $currIds

    $batch | ForEach-Object { [void]$all.Add($_) }

    if ($batch.Count -lt $PerPage) { break } # provável última página
    $page++
  }

  Write-Progress -Activity "Listando repositórios" -Completed
  return $all.ToArray()
}

function Test-BranchExists {
  param(
    [Parameter(Mandatory)][string]$RepoName,
    [Parameter(Mandatory)][string]$BranchName
  )
  $encBranch = [uri]::EscapeDataString($BranchName)
  try {
    $null = Invoke-GitBucketApi -Path ("repos/{0}/{1}/branches/{2}" -f $Owner,$RepoName,$encBranch)
    Write-Verbose "Branch '$BranchName' existe em $RepoName"
    return $true
  }
  catch {
    if ($_.Exception.Message -match '404') {
      Write-Verbose "Branch '$BranchName' NÃO existe em $RepoName"
      return $false
    }
    throw $_
  }
}

# ========================
# Execução
# ========================
Write-Host "=== check-branches.ps1 ===" -ForegroundColor Cyan
Write-Host ("Server : {0}" -f $Server)
Write-Host ("Owner  : {0}" -f $Owner)
Write-Host ("Branch : {0}" -f $Branch)
Write-Host ("Auth   : {0}" -f (if ($Token) { 'Token' } elseif ($UseBasicAuth) { 'Basic' } else { 'Anonymous' }))
Write-Host ("Início : {0}" -f (Get-Date))

if (-not (Test-ApiReachable)) {
  Write-Error "Não foi possível alcançar a API ($Server). Verifique URL, rede ou credenciais."
  exit 1
}

$repos = Get-Repos
if (-not $repos -or $repos.Count -eq 0) {
  Write-Error ("Nenhum repositório encontrado para '{0}'. Verifique permissões/owner." -f $Owner)
  exit 2
}

$i = 0
$total = $repos.Count
$result = New-Object System.Collections.Generic.List[object]
foreach ($r in $repos) {
  $i++
  $name = $r.name
  $pct = if ($total -gt 0) { [int]($i/$total*100) } else { 0 }
  Write-Progress -Activity ("Verificando branch '{0}'" -f $Branch) -Status ("{0} de {1}: {2}" -f $i,$total,$name) -PercentComplete $pct
  if (Test-BranchExists -RepoName $name -BranchName $Branch) {
    $obj = [pscustomobject]@{
      Repo   = "$Owner/$name"
      Branch = $Branch
      Url    = "$Server/git/$Owner/$name.git"
    }
    [void]$result.Add($obj)
  }
}
Write-Progress -Activity ("Verificando branch '{0}'" -f $Branch) -Completed

if ($result.Count -gt 0) {
  $result | Sort-Object Repo | Format-Table -AutoSize
  if ($ExportCsv) {
    try {
      $result | Sort-Object Repo | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $CsvPath
      Write-Host ("CSV gerado em: {0}" -f (Resolve-Path $CsvPath)) -ForegroundColor Green
      if ($OpenCsv) { Invoke-Item -Path $CsvPath }
    }
    catch {
      Write-Warning ("Falha ao exportar CSV: {0}" -f $_)
    }
  }
  exit 0
}
else {
  Write-Host ("Nenhum repositório com a branch '{0}' em '{1}'." -f $Branch,$Owner) -ForegroundColor Yellow
  if ($ExportCsv) {
    try {
      # Exporta CSV vazio com cabeçalhos
      ,([pscustomobject]@{ Repo=''; Branch=$Branch; Url='' }) | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $CsvPath
      Write-Host ("CSV (vazio) gerado em: {0}" -f (Resolve-Path $CsvPath)) -ForegroundColor Yellow
    }
    catch {
      Write-Warning ("Falha ao exportar CSV (vazio): {0}" -f $_)
    }
  }
  exit 3
}
