# Exportar-Ecossistema-EMED.ps1

$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURAÇÕES
# ============================================================

$RaizProjetos = "E:\Projetos\git-imp"
$PastaTemporaria = "E:\Projetos\_exportacao_emed_tmp"
$ArquivoZip = "E:\Projetos\EMED_Fornecedor.zip"

# Pastas analisadas com FILTRO de arquivos
# Mantém somente DLL, XSL e SQL
$PastasFiltradas = @(
    "emed-com",
    "emed-aspnet",
    "emed-dotnet"
)

# Pastas copiadas INTEGRALMENTE
# Não aplica filtro de extensão nem ignora DLL, SQL, XSL etc.
$PastasIntegrais = @(
    "emed-dotnet\.net-emedapi",
    "emed-dotnet\.net-emedclin",
    "emed-dotnet\.net-emedservices",
    "emed-dotnet\.net-emedservicescom",
    "emed-web"
)

# Extensões copiadas nas pastas filtradas
$ExtensoesIncluidas = @(
    ".dll",
    ".xsl",
    ".sql"
)

# Pastas ignoradas no modo FILTRADO
# IMPORTANTE:
# bin NÃO foi incluída aqui, pois DLLs de bin podem ser referência de outros projetos.
$PastasIgnoradasFiltro = @(
    ".git",
    ".vs",
    ".vscode",
    "obj",
    "Debug",
    "Release",
    "node_modules",
    "dist",
    "build",
    ".next",
    ".turbo",
    "backup",
    "bkp",
    "temp",
    "tmp"
)

# Arquivos ignorados no modo FILTRADO
$ArquivosIgnoradosFiltro = @(
    "*.pdb",
    "*.cache",
    "*.log",
    "*.tmp",
    "*.bak",
    "*.zip",
    "*.rar",
    "*.7z"
)

# Pastas ignoradas no modo INTEGRAL
# Mesmo integral, normalmente não faz sentido levar .git, obj, node_modules etc.
# Se quiser copiar absolutamente tudo, deixe este array vazio.
$PastasIgnoradasIntegral = @(
    ".git",
    ".vs",
    ".vscode",
    "obj",
    "node_modules",
    ".next",
    ".turbo"
)

# ============================================================
# FUNÇÕES
# ============================================================

function Escrever-Linha {
    param([string]$Texto = "")
    Write-Host $Texto
}

function Parar-ComErro {
    param([string]$Mensagem)

    Escrever-Linha ""
    Escrever-Linha "[ERRO] $Mensagem"
    Escrever-Linha ""
    throw $Mensagem
}

function Obter-CaminhoRelativo {
    param(
        [string]$Base,
        [string]$CaminhoCompleto
    )

    $BaseNormalizada = $Base.TrimEnd('\') + '\'
    return $CaminhoCompleto.Substring($BaseNormalizada.Length)
}

function Testar-PastaIgnorada {
    param(
        [string]$Caminho,
        [string[]]$PastasIgnoradas
    )

    $Partes = $Caminho -split '[\\/]'

    foreach ($Parte in $Partes) {
        foreach ($Ignorada in $PastasIgnoradas) {
            if ($Parte -ieq $Ignorada) {
                return $true
            }
        }
    }

    return $false
}

function Testar-ArquivoIgnorado {
    param(
        [string]$NomeArquivo,
        [string[]]$ArquivosIgnorados
    )

    foreach ($Padrao in $ArquivosIgnorados) {
        if ($NomeArquivo -like $Padrao) {
            return $true
        }
    }

    return $false
}

function Copiar-ArquivoMantendoEstrutura {
    param(
        [string]$ArquivoOrigem
    )

    $Relativo = Obter-CaminhoRelativo -Base $RaizProjetos -CaminhoCompleto $ArquivoOrigem
    $Destino = Join-Path $PastaTemporaria $Relativo
    $PastaDestino = Split-Path $Destino -Parent

    if (!(Test-Path $PastaDestino)) {
        New-Item -ItemType Directory -Path $PastaDestino -Force | Out-Null
    }

    Copy-Item -Path $ArquivoOrigem -Destination $Destino -Force

    return $Relativo
}

# ============================================================
# INÍCIO
# ============================================================

Escrever-Linha ""
Escrever-Linha "========================================="
Escrever-Linha "EXPORTACAO ECOSSISTEMA EMED"
Escrever-Linha "========================================="
Escrever-Linha ""

if (!(Test-Path $RaizProjetos)) {
    Parar-ComErro "Pasta raiz nao encontrada: $RaizProjetos"
}

if (Test-Path $PastaTemporaria) {
    Escrever-Linha "[REMOVENDO TEMPORARIA] $PastaTemporaria"
    Remove-Item $PastaTemporaria -Recurse -Force
}

if (Test-Path $ArquivoZip) {
    Escrever-Linha "[REMOVENDO ZIP EXISTENTE] $ArquivoZip"
    Remove-Item $ArquivoZip -Force
}

New-Item -ItemType Directory -Path $PastaTemporaria | Out-Null

$ArquivosCopiados = 0
$PastasIntegraisCopiadas = 0

# ============================================================
# 1) CÓPIA FILTRADA
# ============================================================

Escrever-Linha ""
Escrever-Linha "========================================="
Escrever-Linha "COPIA FILTRADA"
Escrever-Linha "========================================="

foreach ($Pasta in $PastasFiltradas) {

    $CaminhoPasta = Join-Path $RaizProjetos $Pasta

    if (!(Test-Path $CaminhoPasta)) {
        Escrever-Linha "[IGNORADA] Pasta nao encontrada: $CaminhoPasta"
        continue
    }

    Escrever-Linha ""
    Escrever-Linha "[ANALISANDO] $CaminhoPasta"

    $Arquivos = Get-ChildItem -Path $CaminhoPasta -Recurse -File -Force | Where-Object {
        ($ExtensoesIncluidas -contains $_.Extension.ToLower()) -and
        !(Testar-PastaIgnorada -Caminho $_.DirectoryName -PastasIgnoradas $PastasIgnoradasFiltro) -and
        !(Testar-ArquivoIgnorado -NomeArquivo $_.Name -ArquivosIgnorados $ArquivosIgnoradosFiltro)
    }

    foreach ($Arquivo in $Arquivos) {
        $RelativoCopiado = Copiar-ArquivoMantendoEstrutura -ArquivoOrigem $Arquivo.FullName
        $ArquivosCopiados++
        Escrever-Linha "[COPIADO FILTRADO] $RelativoCopiado"
    }
}

# ============================================================
# 2) CÓPIA INTEGRAL
# ============================================================

Escrever-Linha ""
Escrever-Linha "========================================="
Escrever-Linha "COPIA INTEGRAL"
Escrever-Linha "========================================="

foreach ($Pasta in $PastasIntegrais) {

    $OrigemIntegral = Join-Path $RaizProjetos $Pasta

    if (!(Test-Path $OrigemIntegral)) {
        Escrever-Linha "[IGNORADA] Pasta integral nao encontrada: $OrigemIntegral"
        continue
    }

    Escrever-Linha ""
    Escrever-Linha "[COPIANDO INTEGRAL] $OrigemIntegral"

    $ArquivosIntegrais = Get-ChildItem -Path $OrigemIntegral -Recurse -File -Force | Where-Object {
        !(Testar-PastaIgnorada -Caminho $_.DirectoryName -PastasIgnoradas $PastasIgnoradasIntegral)
    }

    foreach ($Arquivo in $ArquivosIntegrais) {
        $RelativoCopiado = Copiar-ArquivoMantendoEstrutura -ArquivoOrigem $Arquivo.FullName
        $ArquivosCopiados++
        Escrever-Linha "[COPIADO INTEGRAL] $RelativoCopiado"
    }

    $PastasIntegraisCopiadas++
}

# ============================================================
# VALIDAÇÃO
# ============================================================

$ItensExportados = @(Get-ChildItem -Path $PastaTemporaria -Recurse -File -Force)

if ($ItensExportados.Count -eq 0) {
    Remove-Item $PastaTemporaria -Recurse -Force
    Parar-ComErro "Nenhum arquivo foi encontrado para exportacao."
}

# ============================================================
# ZIP
# ============================================================

Escrever-Linha ""
Escrever-Linha "Compactando arquivos..."
Escrever-Linha ""

Compress-Archive `
    -Path (Join-Path $PastaTemporaria "*") `
    -DestinationPath $ArquivoZip `
    -Force

if (!(Test-Path $ArquivoZip)) {
    Parar-ComErro "Falha ao gerar o arquivo ZIP."
}

Escrever-Linha ""
Escrever-Linha "Removendo pasta temporaria..."
Remove-Item $PastaTemporaria -Recurse -Force

Escrever-Linha ""
Escrever-Linha "========================================="
Escrever-Linha "EXPORTACAO CONCLUIDA COM SUCESSO"
Escrever-Linha "========================================="
Escrever-Linha ""
Escrever-Linha "Raiz analisada           : $RaizProjetos"
Escrever-Linha "Arquivo ZIP gerado       : $ArquivoZip"
Escrever-Linha "Arquivos copiados        : $ArquivosCopiados"
Escrever-Linha "Pastas integrais copiadas: $PastasIntegraisCopiadas"
Escrever-Linha ""
Escrever-Linha "A estrutura original das pastas foi preservada no ZIP."
Escrever-Linha ""