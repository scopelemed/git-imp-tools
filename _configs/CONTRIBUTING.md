# Contribuindo com o EMED

Este repositório adota um padrão simples e consistente de commits, baseado em **Conventional Commits**,
para melhorar rastreabilidade, automação de changelog e governança de releases.

## 1) Regras rápidas de commit

Formato:

```
<prefixo>(escopo opcional): <descrição objetiva>
```

Exemplos:

- `feat(financeiro): criar sp de baixa automática por tipo de pagamento`
- `fix(sql): corrigir filtro de data na sp de agenda`
- `chore(repo): remover arquivos temporários e padronizar .gitignore`

### Boas práticas

- Prefixos em **minúsculo** (`feat`, `fix`, etc.)
- Descrição curta (ideal 50–72 caracteres), **sem ponto final**
- Use verbo no **infinitivo**: adicionar, corrigir, ajustar, remover, criar
- Use **escopo** quando fizer sentido (ex.: `sql`, `agendamento`, `financeiro`, `release`)

## 2) Prefixos oficiais

- `feat`: nova funcionalidade/regra de negócio
- `fix`: correção de bug
- `refactor`: reorganização sem mudar comportamento
- `perf`: melhoria de desempenho
- `docs`: documentação (CHANGELOG/README/políticas)
- `test`: testes e massa de validação
- `chore`: tarefa técnica/housekeeping (sem impacto direto na regra)
- `build`: dependências/build
- `ci`: pipelines/automação

> Quebra de compatibilidade: use `BREAKING CHANGE:` no corpo do commit quando necessário.

## 3) Escopos recomendados (use quando útil)

**scripts-banco-dados**
- `sql`, `sp`, `schema`, `migration`, `dados`, `indice`

**módulos**
- `agendamento`, `financeiro`, `faturamento`, `cadastro`, `integracao`, `relatorio`

**governança**
- `release`, `changelog`, `repo`, `infra`

## 4) Política de validação (hook)

Este repo pode conter um hook de validação do padrão de commit.
Para habilitar, siga **Setup** abaixo.

## 5) Setup (habilitar hooks do repositório)

### Windows (PowerShell)

No diretório do repositório:

```powershell
# aponta o Git para usar hooks versionados no repo
git config core.hooksPath .githooks
```

### Linux/macOS (bash)

```bash
git config core.hooksPath .githooks
chmod +x .githooks/commit-msg
```

> Observação: `core.hooksPath` é por-repositório (não global), então não afeta outros projetos.

## 6) Links

- Guia completo: `docs/commit-message-guidelines.md`
