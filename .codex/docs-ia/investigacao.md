# Investigação Técnica — Padrões para Estudos e Análises no Ecossistema EMED

# Objetivo

Este documento estabelece o padrão para condução de investigações técnicas no ecossistema EMED.

O objetivo é garantir que toda investigação produza conhecimento reutilizável, reduza riscos de implementação e permita tomada de decisão baseada em evidências.

Uma investigação **não tem como objetivo implementar uma solução**.

Seu objetivo é compreender completamente um problema antes que qualquer alteração seja iniciada.

---

# Princípios Fundamentais

Uma investigação deve responder:

- O problema realmente existe?
- Qual é sua causa?
- Quais componentes são impactados?
- Qual é o comportamento atual?
- Qual é o comportamento esperado?
- Quais alternativas existem?
- Quais riscos cada alternativa possui?
- Existe solução já implementada em outro componente?
- Existe configuração que resolve o problema?
- Existe documentação que trata do assunto?

Somente após responder essas perguntas uma implementação deve ser planejada.

---

# O que é uma investigação

Uma investigação é um processo estruturado de obtenção de conhecimento.

Ela pode envolver:

- leitura de código;
- análise arquitetural;
- análise de banco de dados;
- análise de integrações;
- análise de documentação;
- reuniões técnicas;
- levantamento com usuários;
- provas de conceito;
- comparação entre versões;
- análise de logs;
- análise de performance.

O resultado esperado é um documento técnico, e não código.

---

# Quando abrir uma investigação

Abrir uma investigação quando:

- o comportamento atual é desconhecido;
- existem múltiplas alternativas técnicas;
- há risco elevado;
- existe dependência externa;
- há mudança legislativa;
- o problema não é reproduzível;
- existem dúvidas arquiteturais;
- há necessidade de estimativa futura;
- envolve diversos repositórios;
- envolve impacto financeiro ou clínico.

---

# Quando NÃO abrir uma investigação

Não criar investigação quando:

- a implementação já está totalmente definida;
- existe especificação completa;
- trata-se apenas de codificação;
- a alteração é trivial;
- a solução já foi validada anteriormente.

---

# Estrutura recomendada

Toda investigação deve possuir:

## Título

Objetivo e curto.

Exemplos

```text
Investigar adequação à NT 009 da NFSe Nacional

Investigar impacto da Zona Interna no Prontuário React

Investigar unificação de bancos de clientes
```

---

# Objetivo

Explicar claramente:

- o que será investigado;
- por que será investigado;
- qual decisão dependerá dessa investigação.

---

# Contexto

Registrar:

- origem;
- chamado;
- legislação;
- cliente;
- melhoria;
- reunião;
- backlog relacionado.

---

# Perguntas da investigação

Listar explicitamente todas as perguntas que deverão ser respondidas.

Exemplo

```text
Como funciona atualmente?

Existe configuração?

Existe implementação equivalente?

Quais módulos utilizam?

Existe impacto em integrações?

Existe risco de regressão?
```

---

# Escopo

Definir exatamente o que será investigado.

Exemplo

```text
COM+

ASP Classic

API

React

Banco

Integração PagBank
```

---

# Fora do Escopo

Registrar claramente.

Exemplo

```text
Não contempla implementação.

Não contempla publicação.

Não contempla testes.

Não contempla alteração de banco.
```

---

# Levantamento Inicial

Antes de qualquer análise:

Pesquisar:

- backlog;
- documentação;
- AGENTS;
- projetos equivalentes;
- implementações semelhantes;
- tarefas anteriores.

Evitar investigar algo já documentado.

---

# Etapa 1 — Entendimento do Problema

Responder:

- Qual é o problema?
- Quem percebeu?
- Quem é impactado?
- Quando ocorre?
- Desde quando?
- É reproduzível?
- Existe evidência?

---

# Etapa 2 — Reprodução

Sempre que possível:

Reproduzir o problema.

Registrar:

- ambiente;
- versão;
- cliente;
- parâmetros;
- logs;
- imagens;
- mensagens.

Sem reprodução, registrar claramente.

---

# Etapa 3 — Mapeamento Arquitetural

Identificar:

```text
Tela

↓

API

↓

COM+

↓

Business Service

↓

Data Service

↓

Stored Procedure

↓

Banco
```

Ou qualquer fluxo equivalente.

Nunca assumir arquitetura.

---

# Etapa 4 — Pesquisa no Código

Localizar:

- métodos;
- classes;
- procedures;
- páginas;
- endpoints;
- configurações;
- XML;
- XSL.

Pesquisar implementações equivalentes.

---

# Etapa 5 — Banco de Dados

Verificar:

- tabelas;
- views;
- procedures;
- índices;
- triggers;
- constraints;
- configurações;
- dados existentes.

Não alterar banco durante investigação.

---

# Etapa 6 — Configurações

Pesquisar:

- Banco Global;
- Banco Individual;
- parâmetros;
- flags;
- cookies;
- arquivos de configuração.

Muitos comportamentos do EMED são controlados por configuração.

---

# Etapa 7 — Integrações

Quando existir integração:

Identificar:

- APIs;
- WebServices;
- XML;
- JSON;
- certificados;
- autenticação;
- timeout;
- protocolos.

Registrar dependências externas.

---

# Etapa 8 — Alternativas

Toda investigação deve apresentar alternativas.

Para cada alternativa registrar:

- descrição;
- vantagens;
- desvantagens;
- riscos;
- impacto;
- esforço estimado.

Nunca apresentar apenas uma possibilidade sem justificativa.

---

# Etapa 9 — Impactos

Levantar impacto em:

- COM+;
- ASP;
- ASP.NET;
- API;
- React;
- SQL;
- XSL;
- XML;
- Banco Global;
- Banco Individual;
- Integrações;
- Publicação.

---

# Etapa 10 — Riscos

Registrar riscos técnicos.

Exemplos

- regressão;
- quebra de contrato;
- publicação;
- dependência externa;
- legislação;
- concorrência;
- performance;
- compatibilidade.

---

# Etapa 11 — Estimativa

Somente após compreender o problema.

Nunca estimar antes da investigação.

---

# Resultado Esperado

Toda investigação deve produzir:

- entendimento completo;
- documentação;
- fluxograma;
- alternativas;
- recomendação;
- impactos;
- riscos.

---

# Recomendação

A recomendação deve ser objetiva.

Exemplo

```text
Recomenda-se reutilizar a implementação existente
no componente ORMEMED por apresentar menor risco
e manter compatibilidade com os consumidores atuais.
```

Sempre justificar.

---

# O que NÃO deve ocorrer

Durante investigação não deve existir:

- alteração de código;
- alteração de banco;
- publicação;
- refatoração;
- correção incidental.

A investigação termina antes da implementação.

---

# Artefatos Esperados

Uma investigação pode produzir:

- documento técnico;
- fluxograma;
- diagrama;
- matriz de impacto;
- comparação;
- prova de conceito;
- protótipo;
- estimativa;
- backlog.

---

# Critérios de Conclusão

Uma investigação está concluída quando:

- todas as perguntas foram respondidas;
- os impactos foram identificados;
- as alternativas foram avaliadas;
- existe recomendação técnica;
- os riscos foram documentados;
- existe informação suficiente para estimativa.

---

# Antipadrões

Não utilizar investigação para:

```text
programar;

corrigir bug;

alterar procedure;

criar endpoint;

fazer testes;

publicar.
```

---

# Checklist

Antes de concluir verificar:

- [ ] O problema foi entendido?
- [ ] Foi reproduzido?
- [ ] A arquitetura foi mapeada?
- [ ] Foram pesquisadas implementações semelhantes?
- [ ] Foram identificados todos os componentes?
- [ ] Existem alternativas?
- [ ] Existe recomendação?
- [ ] Existem riscos?
- [ ] Existe estimativa preliminar?
- [ ] A documentação está completa?

---

# Ordem de Precedência

Durante uma investigação considerar:

1. Código existente.
2. Implementações equivalentes.
3. Documentação do projeto.
4. Documentação arquitetural.
5. Legislação.
6. Especificações externas.
7. Boas práticas.

Nunca partir diretamente para uma solução sem compreender a implementação atual.

---

# Boas Práticas para o Ecossistema EMED

- Sempre localizar implementações equivalentes antes de propor uma solução.
- Sempre analisar todos os repositórios envolvidos (COM+, ASP, ORMEMED, API, React, SQL e integrações).
- Sempre produzir um documento técnico como resultado da investigação.
- Sempre identificar dependências de publicação e compatibilidade.
- Sempre separar claramente **investigação**, **especificação** e **implementação**.
- Sempre registrar hipóteses e evidências encontradas durante a análise.
- Sempre justificar tecnicamente a recomendação final.
- Sempre preservar a arquitetura existente, propondo reutilização antes da criação de novos componentes.
- Uma boa investigação reduz significativamente o risco da implementação e melhora a qualidade das estimativas.