# Política Git Extremamente Conservadora — Ecossistema EMED

## Objetivo

Esta política define regras restritivas para qualquer atuação sobre repositórios Git do ecossistema EMED.

Seu objetivo é minimizar ao máximo os riscos de:

- perda de código;
- alteração de histórico;
- inclusão indevida de arquivos;
- mistura de tarefas;
- quebra de rastreabilidade;
- publicação incorreta;
- alteração de encoding;
- conflitos entre branches;
- sobrescrita de trabalho de terceiros;
- execução acidental de comandos destrutivos.

Esta política deve ser aplicada por desenvolvedores, revisores e agentes de IA.

Na dúvida, nenhuma ação Git deve ser executada.

A atuação padrão deve ser somente leitura.

---

# Princípio fundamental

Nenhuma alteração Git deve ser realizada automaticamente.

O agente pode:

- consultar;
- analisar;
- comparar;
- listar;
- sugerir;
- preparar alterações em arquivos de trabalho.

O agente não pode, por iniciativa própria:

- criar branch;
- trocar branch;
- adicionar arquivos ao stage;
- remover arquivos do stage;
- criar commit;
- alterar commit;
- fazer push;
- fazer pull;
- fazer merge;
- fazer rebase;
- fazer cherry-pick;
- fazer revert;
- criar tag;
- excluir tag;
- excluir branch;
- alterar remoto;
- limpar arquivos;
- restaurar arquivos;
- resetar o repositório;
- reescrever histórico.

Qualquer uma dessas ações exige solicitação explícita, direta e inequívoca do usuário.

---

# Regra de atuação padrão

A atuação padrão deve obedecer a esta ordem:

```text
1. Inspecionar
2. Informar
3. Propor
4. Aguardar autorização
5. Executar somente a ação autorizada
6. Informar exatamente o que foi feito