# Commit Message Guidelines (EMED)

Este guia padroniza mensagens de commit para facilitar revisão, auditoria e automação (changelog/release).

## 1) Formato

```
<prefixo>(escopo opcional): <descrição>
```

- `prefixo` **obrigatório**
- `escopo` **opcional**, mas recomendado quando ajuda entendimento
- `descrição` **obrigatória**

Ex.: `fix(sql): corrigir filtro de data na sp de agenda`

## 2) Prefixos aceitos

- feat
- fix
- refactor
- perf
- docs
- test
- chore
- build
- ci
- revert

## 3) Escopo (opcional)

Entre parênteses, sem espaços:

- `sql`, `sp`, `schema`, `migration`, `indice`, `dados`
- `agendamento`, `financeiro`, `faturamento`, `cadastro`, `integracao`, `relatorio`
- `release`, `changelog`, `repo`, `infra`

Ex.: `feat(financeiro): ...`

## 4) Descrição

- verbo no infinitivo: adicionar, corrigir, ajustar, remover, criar, atualizar, padronizar, otimizar
- curta, objetiva, sem ponto final

✅ Bom:
- `perf(sql): otimizar consulta de movimentação financeira com índice composto`

❌ Ruim:
- `Ajustes`
- `teste`
- `corrigi bug.`

## 5) Quebra de compatibilidade

Quando o commit altera contrato público (assinatura de SP/API, parâmetros, retorno etc.), inclua no corpo:

```
BREAKING CHANGE: <explicação>
```

Exemplo:

```
feat(sql): alterar assinatura da sp de agendamento

BREAKING CHANGE: removido parâmetro @cd_convenio; usar @id_convenio
```

## 6) Referência de ticket (opcional)

Você pode adicionar no fim do subject ou no corpo:

- `Ref: 4345256920`
- `Refs: 123, 456`

## 7) Padrão validado pelo hook

O hook `commit-msg` valida:
- subject no formato `type(scope opcional): descrição`
- `type` em minúsculo e dentro da lista aceita
- sem caracteres inválidos no escopo
- descrição não vazia

Se precisar fazer bypass pontual (não recomendado):
- `git commit --no-verify`
