# ?? GitBucket PR Audit – Auditoria de Pull Requests para Develop

## ?? Objetivo

Este script tem como objetivo fornecer uma visão centralizada e confiável dos **Pull Requests (PRs) abertos** com destino à branch `develop` em todos os repositórios de um determinado escopo no GitBucket.

Opcionalmente, o script também pode identificar se as branches dos PRs estão **desatualizadas em relação à `develop`**, utilizando exclusivamente a API do GitBucket.

---

## ?? Descrição

O script realiza as seguintes etapas:

1. Consulta a API do GitBucket para listar repositórios:
   - de um usuário
   - de uma organização
   - ou do usuário autenticado

2. Para cada repositório:
   - busca todos os Pull Requests com estado `open`

3. Filtra apenas os PRs cujo destino (`base`) é a branch `develop`

4. (Opcional) Tenta verificar se a branch do PR está:
   - **ahead** (commits próprios)
   - **behind** (desatualizada em relação à `develop`)

5. Gera saída estruturada contendo:
   - repositório
   - número do PR
   - título
   - autor
   - branch origem
   - branch destino
   - datas
   - status de comparação (quando disponível)

6. Exporta os resultados em:
   - CSV (opcional)
   - JSON (opcional)

---

## ?? Requisitos para Execução

### ??? Ambiente

- PowerShell 5.1+ ou PowerShell 7+
- Acesso de rede ao servidor GitBucket

### ?? Autenticação

- Token de acesso válido no GitBucket

### ?? API do GitBucket

O script utiliza endpoints compatíveis com a API do GitHub, como:

- `/api/v3/repos/.../pulls`
- `/api/v3/repos/.../compare/...`

> ?? Importante: o endpoint de **compare** pode não estar disponível ou funcional dependendo da versão/configuração do GitBucket.

---

## ?? Como Executar

1. Abra o script `.ps1`
2. Configure a seção `$CONFIG` no início:

```powershell
$CONFIG = @{
    GitBucketUrl = "http://seu-gitbucket:8080"
    Token = "SEU_TOKEN_AQUI"
    RepoScope = "org"
    OwnerName = "Desenvolvedores"
    BaseBranch = "develop"
    EnableCompareCheck = $true
}