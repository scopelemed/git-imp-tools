# Fluxo entre Camadas — Ecossistema EMED

## Objetivo

Este documento descreve como uma operação percorre as diferentes camadas do ecossistema EMED.

Seu objetivo é orientar:

- análise de impacto;
- investigação de problemas;
- criação de novas funcionalidades;
- manutenção de regras existentes;
- identificação de responsabilidades;
- rastreamento de contratos;
- definição do menor conjunto de arquivos a alterar.

O ecossistema EMED possui múltiplas gerações arquiteturais coexistindo.

Por isso, uma funcionalidade pode seguir fluxos diferentes conforme:

- tecnologia da interface;
- componente responsável;
- tipo de serviço;
- padrão de persistência;
- presença de proxy;
- uso de COM+;
- uso de ORMEMED;
- uso de API;
- existência de integração externa.

A tecnologia da tela não determina, por si só, toda a cadeia da operação.

Antes de alterar qualquer funcionalidade, o fluxo real deve ser identificado no código.

---

# Visão Geral

De forma conceitual, toda operação percorre esta sequência:

```text
Entrada
   │
   ▼
Apresentação
   │
   ▼
Adaptação ou integração
   │
   ▼
Regra de negócio
   │
   ▼
Persistência
   │
   ▼
Banco de dados ou serviço externo
```

O retorno percorre o caminho inverso:

```text
Banco de dados ou serviço externo
   │
   ▼
Persistência
   │
   ▼
Regra de negócio
   │
   ▼
Adaptação
   │
   ▼
Apresentação
   │
   ▼
Usuário ou consumidor
```

---

# Princípio de Responsabilidade

Cada camada possui uma responsabilidade principal.

```text
Apresentação
    interação e exibição

Adaptação
    conversão de contratos e formatos

Business Service
    regra de negócio e orquestração

Data Service
    persistência

Stored Procedure
    manipulação de dados

Banco
    armazenamento

Integração externa
    comunicação com terceiros
```

Uma alteração deve ser implementada na camada responsável.

Não resolver um problema em uma camada inadequada apenas porque ela é mais fácil de modificar.

---

# Fluxo 1 — ASP Classic com COM+

Este é o fluxo mais tradicional da arquitetura EMED.

```text
Usuário
   │
   ▼
Página ASP Classic
   │
   ▼
Business Service VB6
   │
   ▼
Data Service VB6
   │
   ▼
Stored Procedure COM+
   │
   ▼
SQL Server
```

O retorno geralmente segue:

```text
SQL Server
   │
   ▼
FOR XML AUTO, ELEMENTS
   │
   ▼
XSL
   │
   ▼
Data Service VB6
   │
   ▼
Business Service VB6
   │
   ▼
Página ASP Classic
```

---

# Responsabilidade da página ASP Classic

A página normalmente executa:

- leitura de parâmetros;
- leitura de `Request`;
- composição do critério XML;
- chamada ao Business Service;
- interpretação do retorno;
- montagem da interface;
- validações de usabilidade;
- controle de exibição;
- JavaScript;
- navegação;
- submissão de formulário.

A página não deve:

- executar SQL diretamente;
- chamar Stored Procedure;
- centralizar regra de negócio compartilhada;
- decidir regras que deveriam valer para outros consumidores;
- acessar Data Service diretamente sem padrão existente.

---

# Montagem do XML no ASP Classic

A página pode montar um XML de critério contendo:

```xml
<Criterio>
    <cd_paciente>123</cd_paciente>
    <cd_agendamento>456</cd_agendamento>
    <global_cd_empresa_conta_emed>10</global_cd_empresa_conta_emed>
</Criterio>
```

O nome dos elementos deve corresponder ao contrato esperado pelo Business Service.

Não alterar:

- caixa;
- ordem sem análise;
- nomes;
- hierarquia;
- identificação da conta.

---

# Chamada ao Business Service no ASP Classic

Fluxo conceitual:

```text
ASP
  │
  ├── instancia componente COM+
  ├── chama método público
  ├── envia XML
  └── recebe XML
```

A página deve preferencialmente chamar um Business Service.

Exemplo conceitual:

```text
LEMED.BSRequisicao.FechaRequisicao
```

e não diretamente:

```text
LEMED.DSRequisicao.UpdateRequisicao
```

---

# Responsabilidade do Business Service VB6

O Business Service concentra:

- validações funcionais;
- regras de negócio;
- decisões;
- orquestração;
- controle transacional;
- chamadas a um ou mais Data Services;
- chamadas a outros Business Services;
- composição do retorno.

Exemplo de fluxo:

```text
Recebe XML
   │
   ▼
Valida parâmetros funcionais
   │
   ▼
Consulta situação atual
   │
   ▼
Aplica regra
   │
   ▼
Executa persistência
   │
   ▼
Monta retorno
```

---

# Responsabilidade do Data Service VB6

O Data Service concentra:

- carregamento do XML;
- validação técnica dos parâmetros;
- obtenção da conexão;
- montagem do `ADODB.Command`;
- configuração da Stored Procedure;
- criação de parâmetros;
- execução;
- aplicação do XSL;
- retorno XML;
- tratamento técnico de erro.

O Data Service não deve:

- decidir regra funcional;
- validar permissão de negócio;
- realizar orquestração de domínio;
- duplicar regra do Business Service.

---

# Responsabilidade da Stored Procedure COM+

A Stored Procedure executa:

- consulta;
- inclusão;
- alteração;
- exclusão;
- filtros;
- joins;
- retorno de dados;
- retorno de código.

Consultas GET no padrão COM+ devem retornar:

```sql
FOR XML AUTO, ELEMENTS
```

Além do `RETURN` previsto pelo contrato.

---

# Papel do XSL no fluxo COM+

No padrão COM+, a Stored Procedure pode produzir um XML bruto.

O XSL transforma esse XML para o formato final esperado pelo Business Service ou consumidor.

```text
Stored Procedure
      │
      ▼
XML bruto
      │
      ▼
XSL
      │
      ▼
XML transformado
```

Por isso, uma alteração de campo no retorno pode exigir modificação em:

- `SELECT`;
- alias SQL;
- XSL;
- Data Service;
- Business Service;
- página.

---

# Fluxo 2 — ASP.NET WebForms com proxy COM+

Neste fluxo, a apresentação é .NET, mas a regra continua em VB6/COM+.

```text
Usuário
   │
   ▼
Página ASP.NET WebForms
   │
   ▼
Code-behind
   │
   ▼
Proxy C#
   │
   ▼
Interop COM+
   │
   ▼
Business Service VB6
   │
   ▼
Data Service VB6
   │
   ▼
Stored Procedure
```

---

# Responsabilidade do WebForms

A página e o code-behind podem executar:

- captura de controles;
- validações de interface;
- montagem de parâmetros;
- chamada ao proxy;
- binding de dados;
- renderização;
- tratamento de eventos;
- mensagens ao usuário.

Não devem duplicar regras existentes no Business Service.

---

# Responsabilidade do proxy C#

O proxy adapta chamadas tipadas para o contrato COM+.

Fluxo conceitual:

```text
Parâmetros C#
   │
   ▼
Monta XML padrão
   │
   ▼
Chama COM+
   │
   ▼
Recebe string XML
   │
   ▼
Carrega XmlDocument
   │
   ▼
Retorna ao consumidor
```

O proxy deve:

- preservar o contrato;
- utilizar o critério padrão;
- propagar o contexto do cliente;
- manter nomes equivalentes;
- não implementar regra de negócio.

---

# Fluxo 3 — ASP.NET WebForms com ORMEMED

Neste fluxo, as camadas de negócio e persistência são implementadas em C#.

```text
Usuário
   │
   ▼
ASP.NET WebForms
   │
   ▼
Business Service C#
   │
   ▼
Data Service C#
   │
   ▼
Stored Procedure ORMEMED
   │
   ▼
SQL Server
```

O retorno normalmente utiliza:

```text
DataTable
DataSet
objetos C#
```

---

# Responsabilidade do Business Service C#

O Business Service C# pode:

- validar regras;
- coordenar operações;
- controlar `TransactionScope`;
- chamar Data Services;
- consumir serviços externos;
- processar `DataTable`;
- devolver resultados tipados ou tabelas.

Não deve:

- montar SQL textual;
- acessar diretamente a interface;
- concentrar responsabilidades de controller;
- duplicar persistência.

---

# Responsabilidade do Data Service C#

O Data Service C# normalmente:

- instancia `SqlCommand`;
- define `CommandType.StoredProcedure`;
- cria `SqlParameter`;
- adiciona `@RETURN_VALUE`;
- chama `ExecuteDataTable`;
- chama `ExecuteScalar`;
- converte `DBNull`;
- retorna `DataTable`, `DataSet` ou código.

Exemplo conceitual:

```text
GS
   consultas

DS
   insert, update e delete
```

---

# Fluxo 4 — React com API EMED

Neste fluxo, a apresentação é desacoplada do backend.

```text
Usuário
   │
   ▼
Aplicação React
   │
   ▼
API EMED
   │
   ▼
Business Service C#
   │
   ├── Data Service C#
   │
   └── Proxy COM+
   │
   ▼
Stored Procedure ou componente COM+
```

---

# Responsabilidade do React

A aplicação React deve concentrar:

- interface;
- navegação;
- estado;
- validação de usabilidade;
- composição de requisições;
- consumo de API;
- feedback ao usuário;
- controle de componentes.

React não deve:

- acessar banco;
- conhecer Stored Procedures;
- chamar COM+;
- implementar regras que precisam ser compartilhadas;
- decidir permissões apenas no cliente.

---

# Responsabilidade do controller da API

O controller deve:

- receber a requisição;
- validar contrato básico;
- aplicar filtros de autenticação e autorização;
- identificar o contexto;
- chamar serviço ou Business Service;
- transformar o resultado em resposta HTTP;
- devolver DTO ou código adequado.

O controller deve permanecer enxuto.

Não deve:

- executar SQL;
- conter regra complexa;
- duplicar lógica existente em Business Service;
- criar conexão diretamente;
- ignorar o contexto do cliente.

---

# Responsabilidade dos DTOs

DTOs representam contratos de entrada e saída da API.

Eles devem:

- transportar dados;
- manter nomes e serialização esperados;
- refletir o contrato público;
- evitar exposição indevida de estruturas internas.

Alterar um DTO pode impactar:

- React;
- sistemas terceiros;
- testes;
- integrações;
- documentação;
- serialização.

---

# Fluxo 5 — API com reutilização de COM+

Nem toda API usa ORMEMED diretamente.

Um endpoint pode reutilizar Business Service VB6.

```text
Controller API
   │
   ▼
Serviço C#
   │
   ▼
Proxy COM+
   │
   ▼
Business Service VB6
   │
   ▼
Data Service VB6
   │
   ▼
Stored Procedure COM+
```

Nesse caso, a API é apenas uma nova entrada para uma regra existente.

Não duplicar a regra em C# sem necessidade.

---

# Fluxo 6 — Integração externa

Uma operação pode envolver sistema externo.

```text
Apresentação ou serviço
   │
   ▼
Business Service
   │
   ▼
Cliente de integração
   │
   ▼
API, WebService ou arquivo externo
   │
   ▼
Retorno
   │
   ▼
Persistência local
```

Exemplos de integrações:

- operadoras de pagamento;
- serviços de teleconsulta;
- emissão de NFSe;
- certificados digitais;
- WebServices TISS;
- envio de SMS;
- e-mail;
- serviços auxiliares.

---

# Ordem recomendada em integrações

Um fluxo comum pode ser:

```text
Valida regra
   │
   ▼
Prepara requisição
   │
   ▼
Chama serviço externo
   │
   ▼
Valida resposta
   │
   ▼
Persiste protocolo ou resultado
   │
   ▼
Retorna ao consumidor
```

A ordem real deve ser confirmada no código.

Algumas operações podem precisar persistir antes da chamada externa para garantir rastreabilidade.

---

# Transações e serviços externos

Não assumir que uma chamada externa pode participar da mesma transação do banco.

Riscos:

- timeout;
- indisponibilidade;
- resposta tardia;
- duplicidade;
- gravação parcial;
- tentativa de rollback impossível no terceiro;
- repetição da chamada.

Antes de alterar esse fluxo, verificar:

- idempotência;
- protocolo externo;
- status local;
- política de retry;
- registro de requisição;
- registro de resposta;
- conciliação;
- tratamento de falha.

---

# Fluxo 7 — Banco Global e Banco Individual

Toda funcionalidade deve identificar corretamente o contexto de banco.

```text
Entrada
   │
   ▼
Identificação da conta
   │
   ▼
Banco Global
   │
   ├── localiza cliente
   ├── serviços
   └── configurações
   │
   ▼
Banco Individual
   │
   └── operação do cliente
```

---

# Propagação do contexto do cliente

No fluxo COM+, o identificador pode ser:

```text
global_cd_empresa_conta_emed
```

Esse valor deve percorrer:

```text
Tela
   │
   ▼
Business Service
   │
   ▼
Data Service
   │
   ▼
BSConexao
   │
   ▼
Banco Individual
```

Nunca remover esse elemento para simplificar a chamada.

---

# Fluxo de leitura

Um fluxo de consulta normalmente é:

```text
Consumidor
   │
   ▼
Monta critérios
   │
   ▼
Business Service ou serviço
   │
   ▼
Data Service
   │
   ▼
Stored Procedure GET
   │
   ▼
Resultado
   │
   ▼
Transformação
   │
   ▼
Consumidor
```

Antes de incluir um campo no retorno, verificar toda essa cadeia.

---

# Fluxo de inclusão

```text
Entrada de dados
   │
   ▼
Validação de interface
   │
   ▼
Validação de negócio
   │
   ▼
Data Service
   │
   ▼
Stored Procedure INSERT
   │
   ▼
RETURN_VALUE
   │
   ▼
Business Service
   │
   ▼
Consumidor
```

O `RETURN_VALUE` pode representar o identificador inserido.

Não presumir sua semântica.

---

# Fluxo de atualização

```text
Entrada
   │
   ▼
Valida existência
   │
   ▼
Valida regra
   │
   ▼
Consulta situação atual, quando necessário
   │
   ▼
Executa update
   │
   ▼
Valida linhas afetadas
   │
   ▼
Retorna resultado
```

A regra pode exigir leitura prévia para evitar alteração de um estado já consolidado.

---

# Fluxo de exclusão

```text
Solicitação
   │
   ▼
Valida permissão
   │
   ▼
Valida dependências
   │
   ▼
Decide exclusão lógica ou física
   │
   ▼
Executa persistência
   │
   ▼
Retorna resultado
```

Não implementar exclusão diretamente na tela.

---

# Fluxo transacional COM+

```text
Business Service
   │
   ▼
GetObjectContext
   │
   ▼
CreateInstance
   │
   ▼
Uma ou mais operações
   │
   ├── sucesso → SetComplete
   │
   └── erro    → SetAbort
```

Uma alteração em qualquer chamada intermediária pode afetar a transação completa.

---

# Fluxo transacional ORMEMED

```text
Business Service C#
   │
   ▼
TransactionScope
   │
   ▼
Um ou mais Data Services
   │
   ▼
Complete
```

Não criar `TransactionScope` adicional sem necessidade.

Não fragmentar uma operação transacional em chamadas independentes.

---

# Fluxo de autorização

```text
Usuário
   │
   ▼
Autenticação
   │
   ▼
Identificação da conta
   │
   ▼
Identificação do usuário
   │
   ▼
Permissão de grupo ou perfil
   │
   ▼
Validação específica
   │
   ▼
Operação
```

A autorização pode existir em:

- tela;
- filtro da API;
- Business Service;
- configuração;
- zona interna ou externa;
- regra por domínio.

Não depender exclusivamente da interface.

---

# Fluxo de configuração

Uma configuração pode ser consultada antes da regra.

```text
Entrada
   │
   ▼
Consulta configuração
   │
   ▼
Interpreta comportamento
   │
   ▼
Executa fluxo A ou B
```

A configuração pode estar:

- no Banco Global;
- no Banco Individual;
- em arquivo;
- em cookie;
- em cache;
- em componente de configuração.

Antes de criar uma nova flag, pesquisar o mecanismo existente.

---

# Fluxo de retorno no padrão COM+

```text
Stored Procedure
   │
   ▼
FOR XML AUTO, ELEMENTS
   │
   ▼
XML Root
   │
   ▼
XSL
   │
   ▼
ReturnValue
   │
   ▼
String XML
```

Pontos sensíveis:

- aliases;
- `XML Root`;
- nome do XSL;
- elementos esperados;
- `ReturnValue`;
- nós ausentes;
- encoding.

---

# Fluxo de retorno no padrão ORMEMED

```text
Stored Procedure
   │
   ▼
Result set
   │
   ▼
DataTable
   │
   ▼
Business Service
   │
   ▼
DTO, DataSet ou interface
```

Pontos sensíveis:

- ordem das colunas;
- nome das colunas;
- tipo;
- `DBNull`;
- `TableName`;
- código de retorno;
- conversão para DTO.

---

# Fluxo de retorno na API

```text
Business Service
   │
   ▼
Model ou DTO
   │
   ▼
Serialização JSON
   │
   ▼
Código HTTP
   │
   ▼
React ou terceiro
```

Pontos sensíveis:

- nome JSON;
- camelCase;
- campos opcionais;
- códigos HTTP;
- mensagens;
- dados sensíveis;
- compatibilidade com consumidores.

---

# Mapeamento de Impacto

Antes de alterar uma funcionalidade, montar o fluxo real.

Exemplo:

```text
pedido-particular.asp
   │
   ▼
LEFIN.BSMovFinanceira.AtualizaMovimento
   │
   ▼
LEFIN.DSMovFinanceira.UpdateMovimento
   │
   ▼
p_LEFIN_DSMovFinanceira_UpdateMovimento
   │
   ▼
LEFIN_MovFinanceira
```

Ou:

```text
Componente React
   │
   ▼
Controller Financeiro
   │
   ▼
BSFinanceiro C#
   │
   ▼
DSFinanceiro C#
   │
   ▼
p_LEFIN_DS_MovFinanceira_UpdateMovimento
```

A cadeia deve ser confirmada, não presumida.

---

# Investigação de um problema

## Sintoma na interface

Quando o erro aparece na tela, não concluir que a causa está na tela.

Investigar:

```text
Tela
   │
   ▼
Contrato enviado
   │
   ▼
Business Service
   │
   ▼
Data Service
   │
   ▼
Stored Procedure
   │
   ▼
Dados
```

## Erro 500

Verificar:

- erro de sintaxe na página;
- objeto não instanciado;
- parâmetro XML ausente;
- componente COM+ não registrado;
- método incorreto;
- XSL inexistente;
- Stored Procedure ausente;
- erro SQL;
- encoding;
- tratamento de erro;
- resposta inválida.

## Campo não aparece

Verificar:

- Stored Procedure retorna;
- alias correto;
- XSL transforma;
- DS devolve;
- BS preserva;
- proxy expõe;
- DTO possui;
- tela renderiza.

---

# Inclusão de novo campo

Fluxo típico COM+:

```text
Tabela
   │
   ▼
Stored Procedure INSERT/UPDATE/GET
   │
   ▼
Data Service VB6
   │
   ▼
XSL
   │
   ▼
Business Service VB6
   │
   ▼
Proxy ou tela
```

Fluxo típico ORMEMED:

```text
Tabela
   │
   ▼
Stored Procedure
   │
   ▼
Data Service C#
   │
   ▼
Business Service C#
   │
   ▼
DTO ou tela
```

Não incluir o campo em apenas uma camada.

---

# Inclusão de nova regra

Uma nova regra deve ser analisada desta forma:

```text
Quem deve obedecer à regra?
```

Se a resposta for:

```text
todos os consumidores
```

a regra deve ficar no Business Service ou serviço central.

Se a resposta for:

```text
somente exibição
```

pode ficar na apresentação.

Se a resposta for:

```text
integridade de dados
```

pode haver complemento na Stored Procedure ou constraint, sem substituir a regra central.

---

# Regra de validação em múltiplas camadas

Uma mesma condição pode aparecer em mais de uma camada por motivos diferentes.

Exemplo:

```text
Tela
    impede ação para melhor experiência

Business Service
    garante regra para todos os consumidores

Banco
    protege integridade mínima
```

Isso não significa necessariamente duplicação indevida.

Cada validação deve ter responsabilidade clara.

---

# Dependência entre repositórios

Uma tarefa pode exigir alterações em vários repositórios.

Exemplo:

```text
emed-web
   página

emed-com
   BS, DS, SP, XSL

emed-dotnet
   proxy

emed-react
   consumidor
```

Antes de alterar:

- identificar todos os repositórios;
- verificar branches;
- manter contratos compatíveis;
- definir ordem de publicação;
- registrar dependências.

---

# Ordem de publicação

Quando várias camadas são alteradas, a ordem de publicação deve evitar quebra temporária.

Um exemplo possível:

```text
1. Banco e Stored Procedures compatíveis com versão atual
2. Data Service
3. Business Service
4. Proxy ou API
5. Apresentação
```

Entretanto, a ordem deve ser definida por tarefa.

Uma boa estratégia é manter compatibilidade retroativa durante a transição.

---

# Compatibilidade durante publicação

Quando possível:

- adicionar campo sem remover antigo;
- aceitar parâmetro opcional;
- preservar contrato existente;
- publicar backend antes do consumidor;
- evitar alteração simultânea incompatível;
- prever rollback.

Não assumir publicação atômica entre vários repositórios e servidores.

---

# Fluxo de análise de impacto

Utilizar esta sequência:

```text
1. Localizar ponto de entrada
2. Identificar método chamado
3. Localizar contrato
4. Localizar regra
5. Localizar persistência
6. Localizar retorno
7. Pesquisar outros consumidores
8. Identificar banco
9. Identificar transação
10. Definir menor alteração
```

---

# Perguntas obrigatórias antes de implementar

- Qual é o ponto de entrada?
- Qual método público é chamado?
- O contrato é XML, DTO, `DataTable` ou JSON?
- Existe proxy?
- A regra está em VB6 ou C#?
- A persistência é COM+ ou ORMEMED?
- Existe XSL?
- Qual Stored Procedure é executada?
- O dado está no Banco Global ou Individual?
- Existem outros consumidores?
- Há transação?
- Há integração externa?
- Qual é a ordem de publicação?
- O contrato pode ser mantido compatível?
- Qual é o menor diff possível?

---

# Antipadrões de fluxo

Nunca:

- corrigir apenas a tela quando a regra deve ser central;
- chamar Data Service diretamente por conveniência;
- executar SQL na apresentação;
- duplicar regra da camada de negócio;
- alterar Stored Procedure sem revisar consumidor;
- alterar retorno COM+ sem revisar XSL;
- alterar DTO sem revisar React e terceiros;
- ignorar contexto do cliente;
- separar operação transacional sem análise;
- fixar conexão;
- misturar padrão COM+ e ORMEMED;
- assumir que a API não usa COM+;
- assumir que WebForms usa sempre ORMEMED;
- publicar consumidor antes do backend incompatível;
- declarar impacto apenas em um repositório sem pesquisar referências.

---

# Checklist — Fluxo COM+

- [ ] A página chama Business Service?
- [ ] O XML de entrada está correto?
- [ ] O identificador da conta está presente?
- [ ] O Business Service contém a regra?
- [ ] O Data Service executa apenas persistência?
- [ ] A Stored Procedure segue o padrão COM+?
- [ ] O GET retorna `FOR XML AUTO, ELEMENTS`?
- [ ] O XSL foi revisado?
- [ ] O `ReturnValue` foi preservado?
- [ ] A transação COM+ foi preservada?
- [ ] Outros consumidores foram pesquisados?

---

# Checklist — Fluxo ORMEMED

- [ ] O Business Service C# contém a regra?
- [ ] O Data Service usa `SqlCommand`?
- [ ] A procedure segue `GS_` ou `DS_` corretamente?
- [ ] O retorno é tabular?
- [ ] O `RETURN_VALUE` foi preservado?
- [ ] Os tipos SQL e C# são compatíveis?
- [ ] O `TransactionScope` foi analisado?
- [ ] DTOs e consumidores foram revisados?

---

# Checklist — Fluxo API

- [ ] A rota existente foi preservada?
- [ ] Os filtros de autenticação foram preservados?
- [ ] Os filtros de autorização foram preservados?
- [ ] O contexto do cliente está correto?
- [ ] O controller permanece enxuto?
- [ ] A regra foi delegada ao serviço?
- [ ] O DTO foi revisado?
- [ ] A serialização foi revisada?
- [ ] O código HTTP está coerente?
- [ ] React e terceiros foram considerados?

---

# Checklist — Integração externa

- [ ] A requisição está validada?
- [ ] O contrato externo foi confirmado?
- [ ] Credenciais não foram expostas?
- [ ] Existe idempotência?
- [ ] O timeout foi considerado?
- [ ] O retry foi considerado?
- [ ] O retorno é persistido?
- [ ] Erros são rastreáveis?
- [ ] Existe risco de duplicidade?
- [ ] A transação local foi analisada?
- [ ] Existe conciliação posterior?

---

# Ordem de precedência

Ao identificar o fluxo, utilizar esta ordem de confiança:

1. chamada real no ponto de entrada;
2. implementação do método chamado;
3. referências no mesmo repositório;
4. referências nos demais repositórios;
5. documentação específica da funcionalidade;
6. documentação da arquitetura;
7. convenções gerais.

Diagramas conceituais não substituem a inspeção do código real.

---

# Princípios fundamentais

1. Toda operação possui um fluxo real entre camadas.

2. A tecnologia da interface não define sozinha o backend utilizado.

3. Regra de negócio deve permanecer na camada de negócio.

4. Persistência deve permanecer no Data Service e Stored Procedure.

5. Contratos devem ser preservados durante todo o fluxo.

6. O contexto do cliente deve ser propagado entre as camadas.

7. COM+, ORMEMED, API e React podem participar da mesma operação.

8. Alterações devem ser analisadas nos dois sentidos:

   ```text
   consumidor → banco
   banco → consumidores
   ```

9. Transações devem ser avaliadas de ponta a ponta.

10. Integrações externas exigem análise de idempotência e falhas parciais.

11. Alterações em vários repositórios exigem ordem de publicação.

12. O menor conjunto de camadas e arquivos deve ser alterado.

13. O código existente é a principal fonte de verdade.

14. O agente deve compreender o fluxo antes de propor a solução.