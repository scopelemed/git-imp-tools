# Banco Global - Arquitetura do Ecossistema EMED

# Objetivo

Este documento descreve o papel do Banco Global dentro da arquitetura do ecossistema EMED.

Seu objetivo é orientar implementações e investigações técnicas para que o agente compreenda corretamente quando uma informação pertence ao Banco Global e quando pertence ao Banco Individual do cliente.

A arquitetura do EMED utiliza isolamento completo entre clientes.

Essa separação é um princípio fundamental do sistema.

Nunca deve ser ignorada.

---

# Visão Geral

O ecossistema EMED trabalha com dois contextos distintos de banco de dados.

```
                 Banco Global
                       │
         identifica o cliente
         identifica serviços
         identifica configurações
                       │
                       ▼
              Banco Individual
```

Todo acesso ao sistema inicia pelo Banco Global.

Após identificar o cliente, todas as operações passam a utilizar exclusivamente o Banco Individual correspondente.

---

# Banco Global

O Banco Global é compartilhado por todos os clientes do ecossistema EMED.

Ele não armazena os dados operacionais dos clientes.

Seu objetivo é centralizar informações comuns ao ambiente.

---

# Responsabilidades do Banco Global

O Banco Global normalmente contém informações como:

- cadastro de clientes;

- identificação das contas EMED;

- configuração dos serviços contratados;

- habilitação de módulos;

- licenciamento;

- parâmetros globais;

- informações compartilhadas;

- tabelas nacionais de referência;

- CEP;

- CBO;

- CNAE;

- Municípios;

- Estados;

- Países;

- operadoras;

- tabelas de domínio compartilhadas.

O Banco Global não deve armazenar dados operacionais do cliente.

---

# Banco Individual

Cada cliente possui seu próprio banco de dados.

Todos possuem exatamente a mesma estrutura.

Os bancos são completamente independentes.

Cada banco contém apenas informações daquele cliente.

---

# Dados pertencentes ao Banco Individual

Exemplos:

Paciente

Agenda

Atendimento

Pedido

Movimentação Financeira

Estoque

Prontuário

Repasse Médico

Faturamento

Contas a Receber

Contas a Pagar

Documentos

Arquivos

Configurações específicas do cliente

---

# Fluxo de Acesso

Todo acesso segue a sequência abaixo.

```
Usuário

↓

Banco Global

↓

Identifica Conta EMED

↓

Localiza Banco Individual

↓

Abre conexão

↓

Todas as operações passam a utilizar
o Banco Individual
```

---

# Identificação do Cliente

A identificação do banco correto ocorre através do identificador da conta EMED.

Nos componentes COM+ normalmente esse identificador é representado por:

```
global_cd_empresa_conta_emed
```

Esse campo acompanha praticamente toda a cadeia da chamada.

Nunca deve ser descartado.

---

# Contexto da Conexão

Os componentes COM+ não conhecem diretamente qual banco utilizar.

Eles recebem o identificador da conta.

A conexão é obtida através do componente administrativo.

Exemplo conceitual.

```
Business Service

↓

Data Service

↓

BSConexao

↓

Banco Individual
```

---

# Nunca Utilizar Banco Fixo

É proibido assumir:

```
EMEDCliente01

EMEDCliente02

EMEDTeste

EMEDProducao
```

Nenhum componente deve conhecer previamente qual banco utilizar.

Toda conexão deve ser obtida através do mecanismo existente.

---

# Isolamento dos Clientes

O isolamento entre clientes é absoluto.

Uma operação realizada por um cliente nunca pode:

- consultar dados de outro cliente;

- alterar dados de outro cliente;

- compartilhar registros;

- reutilizar conexões.

---

# Compartilhamento de Dados

Os únicos dados compartilhados entre clientes são aqueles existentes no Banco Global.

Jamais copiar dados operacionais entre bancos durante uma operação normal.

---

# Configurações

Existem dois tipos de configuração.

## Configuração Global

Controla:

- habilitação de módulos;

- licenciamento;

- funcionalidades;

- parâmetros corporativos;

- integrações.

São mantidas no Banco Global.

---

## Configuração do Cliente

Controla:

- comportamento da clínica;

- parâmetros específicos;

- preferências;

- usuários;

- perfis;

- agendas;

- financeiro;

- estoque.

São mantidas exclusivamente no Banco Individual.

---

# Consulta de Configurações

Durante uma operação é comum ocorrer:

```
Consulta Banco Global

↓

Obtém configuração

↓

Continua utilizando Banco Individual
```

Isso não significa troca permanente de contexto.

---

# Troca de Contexto

Toda troca entre Banco Global e Banco Individual deve ser explícita.

Nunca assumir que uma conexão pode ser reutilizada para ambos.

---

# Segurança

O Banco Global possui informações críticas.

Exemplos.

Cadastro de clientes.

Licenciamento.

Configurações.

Credenciais.

Nunca:

alterar registros diretamente;

executar scripts sem análise;

utilizar dados reais em testes.

---

# Investigação de Problemas

Sempre determinar primeiro.

O problema pertence ao:

Banco Global?

ou

Banco Individual?

Exemplos.

## Problema de Login

Provavelmente envolve Banco Global.

---

## Paciente não encontrado

Banco Individual.

---

## Agenda

Banco Individual.

---

## Estoque

Banco Individual.

---

## Configuração de Licença

Banco Global.

---

## Configuração Financeira da Clínica

Banco Individual.

---

## Habilitação de Módulo

Banco Global.

---

## Cadastro de Usuário

Normalmente Banco Individual.

---

# Desenvolvimento

Antes de criar qualquer tabela, Stored Procedure ou regra de negócio perguntar.

Esta informação pertence:

ao cliente?

ou

ao ecossistema?

Se pertence ao cliente:

Banco Individual.

Se pertence ao ecossistema:

Banco Global.

---

# Alterações

Nunca mover informações entre Banco Global e Banco Individual sem análise arquitetural.

Essa decisão impacta:

segurança

performance

isolamento

licenciamento

replicação

backup

restauração

migração

integrações

---

# Erros Comuns

Não utilizar Banco Global para armazenar:

pacientes

agendamentos

pedidos

financeiro

estoque

prontuário

documentos

histórico

movimentações

Esses dados pertencem ao Banco Individual.

---

# Boas Práticas

Sempre preservar o isolamento entre clientes.

Sempre utilizar o mecanismo existente para localizar o banco correto.

Sempre propagar o identificador da conta EMED.

Nunca assumir conexões fixas.

Nunca compartilhar dados operacionais entre clientes.

Nunca utilizar dados de um cliente em outro banco.

---

# Checklist

Antes de implementar verificar.

☐ O dado pertence ao Banco Global?

☐ O dado pertence ao Banco Individual?

☐ O identificador da conta EMED está sendo propagado?

☐ A conexão está sendo obtida pelo mecanismo padrão?

☐ Existe risco de acesso ao banco incorreto?

☐ Existe risco de mistura de dados entre clientes?

☐ A alteração preserva o isolamento arquitetural?

---

# Princípio Fundamental

O Banco Global identifica o cliente.

O Banco Individual contém a operação do cliente.

Esses dois contextos nunca devem ser confundidos.

Toda implementação deve preservar esse isolamento.