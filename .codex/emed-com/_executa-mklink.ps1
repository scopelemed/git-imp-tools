<#
.SYNOPSIS
    Cria links simbólicos para arquivos Markdown dentro da pasta .codex\docs.

.DESCRIPTION
    Todos os arquivos .md encontrados na pasta origem serão linkados
    para a pasta destino.

    O arquivo original permanece em seu local.
    Apenas um link simbólico é criado.

.PARAMETER Source
    Pasta onde estão os arquivos .md

.PARAMETER Destination
    Pasta onde serão criados os links

.PARAMETER Force
    Remove links existentes antes de recriá-los

.EXAMPLE
    .\Exportar-Arquivos-Docs-Codex.ps1

.EXAMPLE
    .\Exportar-Arquivos-Docs-Codex.ps1 -Force
#>

param(
    [string]$Source = "E:\Projetos\git-imp\emed-com\docs-ia",
    [string]$Destination = "E:\Projetos\git-imp\.codex\emed-com",
    [switch]$Force
)

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host " Exportando documentação para o Codex"
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

if (!(Test-Path $Source))
{
    Write-Host "Pasta origem não encontrada." -ForegroundColor Red
    exit 1
}

if (!(Test-Path $Destination))
{
    New-Item `
        -ItemType Directory `
        -Path $Destination `
        -Force | Out-Null
}

$Arquivos = Get-ChildItem `
                -Path $Source `
                -Filter *.md `
                -File

foreach ($Arquivo in $Arquivos)
{
    $Destino = Join-Path $Destination $Arquivo.Name

    if (Test-Path $Destino)
    {
        if ($Force)
        {
            Remove-Item $Destino -Force
        }
        else
        {
            Write-Host "[IGNORADO] $($Arquivo.Name)" -ForegroundColor Yellow
            continue
        }
    }

    New-Item `
        -ItemType SymbolicLink `
        -Path $Destino `
        -Target $Arquivo.FullName | Out-Null

    Write-Host "[OK] $($Arquivo.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Concluído." -ForegroundColor Cyan