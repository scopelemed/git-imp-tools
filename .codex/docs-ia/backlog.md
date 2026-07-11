# Backlog — Padrões para Especificação de Itens no Ecossistema EMED

# Objetivo

Este documento define os padrões utilizados para criação, refinamento e manutenção dos itens de backlog do ecossistema EMED.

Seu objetivo é garantir que todas as demandas possuam:

- rastreabilidade;
- objetivo claro;
- escopo bem definido;
- baixo risco de interpretação;
- aderência à arquitetura existente;
- facilidade de estimativa;
- facilidade de planejamento;
- facilidade de code review;
- facilidade de publicação.

O backlog deve representar **o problema de negócio**, e não a solução técnica.

Os detalhes técnicos pertencem às tarefas de desenvolvimento.

---

# Princípios Fundamentais

Um bom backlog responde:

- O que deve ser resolvido?
- Por que deve ser resolvido?
- Qual benefício será obtido?
- Quem será impactado?

Não deve responder:

- Como será implementado.
- Quais classes serão alteradas.
- Quais Stored Procedures serão modificadas.
- Quais arquivos serão alterados.

Esses detalhes pertencem às tarefas.

---

# Hierarquia

A organização recomendada é:

```text
Projeto

    Backlog Item

        Desenvolvimento

        Banco

        Frontend

        API

        Testes

        Publicação
```

ou

```text
Projeto

    Epic

        Backlog

            Tarefas
```

conforme a ferramenta utilizada.

---

# Granularidade

## Projeto

Representa um objetivo estratégico.

Exemplos

- Reforma Tributária
- Novo Fluxo Financeiro
- Integração PagBank
- Certificados Digitais A1
- Middleware NFSe

---

## Item de Backlog

Representa uma entrega funcional.

Exemplos

```text
Permitir geração de PDF da NFSe Nacional

Implementar autenticação por certificado digital

Implantar controle de favorecido financeiro
```

---

## Tarefa

Representa uma implementação técnica.

Exemplo

```text
Alterar Stored Procedures

Adequar Business Services

Atualizar página ASP

Implementar endpoint

Realizar testes
```

---

# Estrutura recomendada

Todo item de backlog deve conter:

## Título

Curto.

Objetivo.

Sem detalhes técnicos.

Bom:

```text
Implementar geração do PDF da NFSe Nacional
```

Ruim

```text
Criar classe USGeraPDFByNFSe usando iTextSharp
```

---

## Objetivo

Descrever:

- necessidade;
- benefício;
- resultado esperado.

Exemplo

```text
Permitir que a NFSe Nacional possua geração de PDF
padronizada conforme a Nota Técnica vigente.
```

---

## Contexto

Explicar:

- origem da necessidade;
- legislação;
- chamado;
- cliente;
- melhoria;
- problema operacional.

Sem detalhar implementação.

---

## Escopo

Descrever somente o comportamento esperado.

Exemplo

```text
Permitir geração do PDF.

Disponibilizar QRCode.

Exibir marca d'água.

Manter compatibilidade com notas antigas.
```

---

## Fora do escopo

Sempre registrar.

Exemplo

```text
Não contempla:

Emissão da NF.

Cancelamento.

Assinatura digital.

Mudanças no XML.
```

---

# Não colocar no backlog

Não descrever:

```text
alterar classe

criar procedure

alterar xsl

usar DataTable

usar COM+

usar XML
```

Essas informações pertencem às tarefas.

---

# Linguagem

Sempre utilizar linguagem funcional.

Correto

```text
Permitir...

Impedir...

Disponibilizar...

Controlar...

Validar...
```

Evitar

```text
Criar classe...

Alterar método...

Modificar SQL...
```

---

# Critérios de Aceite

Todo backlog deve possuir critérios objetivos.

Exemplo

```text
O usuário consegue gerar o PDF.

O QRCode é exibido.

Notas antigas permanecem funcionando.

Não ocorre regressão.
```

Evitar critérios vagos.

Exemplo ruim

```text
Funcionar corretamente.
```

---

# Dependências

Registrar quando houver.

Exemplo

```text
Depende:

Middleware NFSe

API EMED

COM+

Portal Nacional
```

---

# Impactos

Registrar os módulos afetados.

Exemplo

```text
Financeiro

Pedidos

NFSe

API

Portal do Cliente
```

---

# Riscos

Registrar riscos relevantes.

Exemplo

```text
Mudança legislativa.

Dependência externa.

Mudança de leiaute.

Dependência de publicação conjunta.
```

---

# Estimativa

A estimativa deve considerar:

- desenvolvimento;
- testes;
- revisão;
- publicação.

Não considerar apenas codificação.

---

# Divisão em tarefas

Após aprovado o backlog:

Criar tarefas específicas.

Exemplo

```text
Alteração Stored Procedures

Alteração COM+

Alteração ASP

Alteração API

Testes

Publicação
```

---

# Tarefas Técnicas

As tarefas devem conter:

Objetivo técnico.

Artefatos envolvidos.

Dependências.

Critérios de conclusão.

---

# Padrão para tarefas

Cada tarefa deve responder:

```text
O que será alterado?

Por quê?

Quando estará concluída?
```

---

# Nome das tarefas

Preferir:

```text
Adequação das Stored Procedures

Adequação dos Business Services

Implementação da API

Testes Integrados

Publicação
```

Evitar

```text
Programação

Codificação

Alterações diversas

Ajustes
```

---

# Itens de investigação

Quando não houver definição suficiente.

Utilizar:

```text
Investigar...

Avaliar...

Estudar...

Levantar impactos...

Realizar prova de conceito...
```

O resultado esperado é conhecimento.

Não implementação.

---

# Itens de estudo

Devem produzir artefatos.

Exemplo

```text
Documento técnico.

Protótipo.

Fluxograma.

Análise de impacto.

Comparativo.

Plano de implementação.
```

---

# Tarefas de testes

Devem possuir objetivo próprio.

Exemplo

```text
Executar testes integrados.

Validar cenários regressivos.

Validar publicação.

Executar testes de homologação.
```

---

# Publicação

Sempre prever uma tarefa específica.

Ela deve contemplar:

- publicação;
- validação;
- rollback;
- documentação.

---

# Critérios de conclusão

Um backlog está concluído quando:

- todas as tarefas terminaram;
- critérios de aceite foram atendidos;
- testes executados;
- publicação concluída;
- documentação atualizada.

---

# Antipadrões

Não criar backlog para:

```text
Alterar classe X

Criar Stored Procedure

Modificar método

Atualizar DataTable
```

Esses são detalhes técnicos.

---

# Checklist

Antes de criar um backlog verificar:

- [ ] O problema está claro?
- [ ] Existe objetivo?
- [ ] Existe benefício?
- [ ] O escopo está funcional?
- [ ] O fora do escopo foi registrado?
- [ ] Existem critérios de aceite?
- [ ] Existem riscos?
- [ ] Existem dependências?
- [ ] As tarefas técnicas ficaram separadas?
- [ ] A implementação não foi antecipada?

---

# Ordem de precedência

Na elaboração de backlog considerar:

1. Necessidade de negócio.
2. Legislação ou requisito externo.
3. Processo operacional.
4. Arquitetura existente.
5. Implementação técnica.

Nunca inverter essa ordem.

---

# Boas práticas para o Ecossistema EMED

- Um backlog representa **uma entrega funcional**, não uma alteração de código.
- Tarefas representam **implementações técnicas**.
- O backlog deve permanecer compreensível por usuários de negócio.
- As tarefas devem ser compreensíveis pelos desenvolvedores.
- Sempre separar claramente **o que será entregue** de **como será implementado**.
- Sempre registrar dependências entre repositórios (COM+, ASP, API, React, SQL) nas tarefas, nunca no backlog.
- Sempre prever tarefas específicas para **testes**, **publicação** e **ajustes finais**.
- Itens de investigação devem resultar em documentação técnica antes da implementação.
- Mudanças legislativas (TISS, NFSe, Reforma Tributária, etc.) devem possuir um backlog próprio, independente das tarefas de desenvolvimento.
- O backlog deve permanecer estável durante a execução; alterações de implementação devem ocorrer nas tarefas, preservando a rastreabilidade do planejamento.