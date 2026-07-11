# Code Review — Ecossistema EMED

## Objetivo

Este documento define os critérios de revisão de código aplicáveis aos projetos do ecossistema EMED.

Seu objetivo é orientar revisões técnicas de alterações em:

- VB6 e COM+;
- ASP Classic;
- ASP.NET WebForms;
- C# e ORMEMED;
- APIs;
- React;
- Stored Procedures;
- XSL;
- XML;
- integrações externas;
- scripts de banco;
- configurações;
- artefatos de publicação.

A revisão deve priorizar:

- aderência ao padrão existente;
- preservação de compatibilidade;
- prevenção de regressões;
- segurança;
- integridade dos dados;
- isolamento entre clientes;
- menor diff possível;
- clareza do impacto;
- viabilidade de publicação e rollback.

O objetivo do code review não é reescrever o código segundo preferências pessoais.

O objetivo é verificar se a alteração atende à tarefa com o menor risco possível.

---

# Princípio fundamental

A pergunta principal de uma revisão não deve ser:

```text
Eu escreveria dessa forma?
```

A pergunta correta é:

```text
Esta alteração atende ao objetivo,
respeita o padrão do componente
e preserva os contratos existentes?
```

---

# Escopo da revisão

Toda revisão deve começar pela compreensão do escopo.

Antes de analisar o diff, confirmar:

- qual problema está sendo resolvido;
- qual comportamento esperado;
- quais camadas deveriam ser alteradas;
- quais arquivos foram modificados;
- qual arquitetura está envolvida;
- quais riscos existem;
- quais validações foram realizadas.

Não revisar apenas a sintaxe.

A revisão deve considerar comportamento, contratos e impacto arquitetural.

---

# Ordem recomendada de revisão

Utilizar esta sequência:

```text
1. Entender a tarefa
2. Identificar a arquitetura
3. Revisar o diff geral
4. Verificar escopo
5. Analisar contratos
6. Analisar regra de negócio
7. Analisar persistência
8. Analisar segurança
9. Analisar compatibilidade
10. Analisar publicação
11. Analisar testes
12. Registrar achados
```

---

# Classificação dos achados

Os comentários devem ser classificados por severidade.

## Bloqueador

Problema que impede aprovação.

Exemplos:

- perda de dados;
- acesso ao banco de cliente incorreto;
- quebra de contrato público;
- falha de autorização;
- SQL incompatível com SQL Server 2000;
- alteração que não compila;
- transação inconsistente;
- Stored Procedure sem permissão;
- exposição de credencial;
- regressão funcional evidente;
- publicação inviável.

Formato sugerido:

```text
[BLOQUEADOR]
```

---

## Alto risco

Problema com grande probabilidade de regressão ou incidente.

Exemplos:

- regra aplicada apenas na interface;
- alteração de XML sem ajuste no XSL;
- parâmetro incluído apenas em parte da cadeia;
- alteração de retorno sem revisar consumidores;
- atualização sem filtro seguro;
- mudança de semântica do RETURN_VALUE;
- quebra provável de compatibilidade COM+.

Formato sugerido:

```text
[ALTO]
```

---

## Médio risco

Problema relevante, mas que pode não impedir a funcionalidade principal.

Exemplos:

- falta de tratamento para valor nulo;
- mensagem de erro incorreta;
- recurso não liberado;
- ausência de validação de entrada;
- possível consulta repetitiva;
- regra duplicada;
- risco de publicação parcial.

Formato sugerido:

```text
[MÉDIO]
```

---

## Baixo risco

Ajuste de manutenção ou consistência com impacto reduzido.

Exemplos:

- comentário incorreto;
- nome de variável copiado;
- trecho pouco claro;
- inconsistência local de estilo;
- validação adicional recomendada.

Formato sugerido:

```text
[BAIXO]
```

---

## Sugestão

Melhoria opcional que não deve bloquear aprovação.

Exemplos:

- comentário mais claro;
- teste adicional;
- documentação complementar;
- pequena simplificação coerente com o padrão.

Formato sugerido:

```text
[SUGESTÃO]
```

Não tratar preferência pessoal como defeito.

---

# Revisão do escopo

## Verificar

- Todos os arquivos alterados são necessários?
- Existem arquivos fora do escopo?
- Houve alteração de formatação global?
- Houve alteração de encoding?
- O diff é proporcional à tarefa?
- Existe refatoração não solicitada?
- O autor corrigiu problemas não relacionados?
- Arquivos gerados foram incluídos indevidamente?
- Existem binários, logs ou temporários no commit?

## Sinais de alerta

```text
Tarefa pequena
+
muitos arquivos alterados
=
revisar escopo com atenção
```

Uma correção pontual não deve produzir reestruturação ampla sem justificativa.

---

# Revisão do diff

Antes de entrar nos detalhes, observar:

- quantidade de linhas adicionadas e removidas;
- arquivos inteiros aparentemente modificados;
- alteração de finais de linha;
- espaços e indentação;
- mudanças em comentários;
- renomeações;
- exclusões inesperadas;
- arquivos duplicados;
- mudanças em dependências.

## Perguntas

- O diff mostra apenas a mudança funcional?
- O arquivo foi regravado em outro encoding?
- Há ruído que dificulta a revisão?
- É possível reduzir o diff?
- Alguma mudança foi introduzida por ferramenta automática?

---

# Revisão arquitetural

Determinar qual fluxo está envolvido.

Exemplos:

```text
ASP Classic
→ BS VB6
→ DS VB6
→ SP
→ XSL
```

```text
WebForms
→ Proxy C#
→ COM+
```

```text
React
→ API
→ BS C#
→ DS C#
→ SP
```

```text
API
→ Proxy COM+
→ BS VB6
→ DS VB6
→ SP
```

## Verificar

- A regra foi colocada na camada correta?
- A apresentação está executando regra de negócio?
- O Data Service recebeu lógica funcional?
- O controller está excessivamente complexo?
- O proxy duplicou regra?
- Houve acesso direto ao banco?
- A alteração respeita a arquitetura do componente?
- COM+ e ORMEMED foram misturados?

---

# Revisão de regra de negócio

## Verificar

- A regra implementada corresponde à descrição da tarefa?
- Todas as condições foram consideradas?
- Existem estados intermediários?
- A regra vale para todos os consumidores?
- Foi aplicada apenas na tela?
- O comportamento antigo foi preservado nos demais cenários?
- Existem casos de inclusão, alteração e exclusão?
- Há comportamento para valores nulos ou vazios?
- Há dependência de configuração?
- Existe impacto financeiro, clínico ou fiscal?

## Perguntas essenciais

```text
O que acontece quando o dado já existe?
O que acontece quando não existe?
O que acontece quando está vazio?
O que acontece quando o usuário não tem permissão?
O que acontece quando a operação externa falha?
O que acontece se a operação for executada duas vezes?
```

---

# Revisão de VB6 e COM+

## Assinaturas públicas

Verificar se foram preservados:

- nome do método;
- visibilidade;
- quantidade de parâmetros;
- ordem dos parâmetros;
- tipos;
- `ByVal`;
- `ByRef`;
- `Optional`;
- retorno.

Alterações em métodos públicos podem quebrar consumidores externos.

---

## ObjectContext

Verificar:

- uso de `GetObjectContext`;
- instanciação por `CreateInstance`;
- `SetComplete`;
- `SetAbort`;
- posição do controle transacional;
- comportamento em erro.

Não aprovar remoção de contexto transacional sem justificativa.

---

## Tratamento de erro

Verificar:

- label correto;
- nome correto da classe;
- nome correto do método;
- uso de `EMED_ADM.errorHandler`;
- preservação do XML no diagnóstico;
- liberação de objetos;
- propagação do erro.

Erros comuns de cópia:

- método antigo no `errorHandler`;
- classe errada;
- label incorreto;
- retorno atribuído a outra Function.

---

## Objetos COM

Verificar:

- instanciação correta;
- liberação com `Set ... = Nothing`, conforme padrão;
- objeto não liberado antes do uso;
- versão correta do MSXML;
- early binding ou late binding coerente;
- referência existente no projeto.

---

## XML no VB6

Verificar:

- `loadXML` validado;
- nós obrigatórios validados;
- nomes preservados;
- caixa preservada;
- uso de helpers existentes;
- propagação de `global_cd_empresa_conta_emed`;
- `StringXMLCriterioPadrao`;
- `StringXMLRetornoPadrao`;
- `fGetNode`;
- `NullIfEmpty`.

---

## Data Services VB6

Verificar:

- apenas persistência;
- uso de `ADODB.Command`;
- `adCmdStoredProc`;
- Stored Procedure correta;
- parâmetros corretos;
- tipos ADO corretos;
- `@RETURN_VALUE`;
- `XML Root`;
- XSL;
- `Output Stream`;
- `adExecuteStream`.

---

## Business Services VB6

Verificar:

- regra no BS;
- orquestração;
- validações funcionais;
- transação;
- chamadas a DS;
- chamadas a outros BS;
- retorno padrão;
- ausência de SQL.

---

# Revisão de Stored Procedures COM+

## Nomenclatura

Verificar:

```text
p_PREFIXO_DSTabela_Operacao
```

Não aceitar:

```text
p_PREFIXO_GS_Tabela_Operacao
```

em persistência COM+.

---

## Retorno

GET deve possuir:

```sql
FOR XML AUTO, ELEMENTS
```

Além do `RETURN` esperado.

Verificar:

- aliases;
- estrutura XML;
- XSL consumidor;
- semântica do retorno;
- ordem dos campos;
- nome dos elementos.

---

## Permissão

Toda procedure deve terminar com:

```sql
GRANT ALL ON p_NOME_DA_PROCEDURE TO GrpLEMED
GO
```

Confirmar que o nome do `GRANT` corresponde à procedure criada.

---

# Revisão de ORMEMED

## Classes C#

Verificar:

- classe-base correta;
- construtores preservados;
- uso de `SqlCommand`;
- `CommandType.StoredProcedure`;
- `SqlParameter`;
- `@RETURN_VALUE`;
- `ExecuteDataTable`;
- `ExecuteScalar`;
- `TransactionScope`;
- tratamento de `DBNull`;
- exceções conforme padrão.

---

## Separação GS e DS

Consultas:

```text
GS
```

Escritas:

```text
DS
```

Stored Procedures:

```text
p_PREFIXO_GS_Tabela_Operacao
p_PREFIXO_DS_Tabela_Operacao
```

Verificar se o padrão foi respeitado.

---

## Retorno tabular

GET ORMEMED deve retornar tabela.

Não aceitar:

```sql
FOR XML AUTO, ELEMENTS
```

quando o consumidor utiliza `ExecuteDataTable`.

---

# Revisão de SQL Server 2000

## Compatibilidade

Rejeitar recursos incompatíveis, como:

- CTE;
- `MERGE`;
- `TRY/CATCH`;
- `THROW`;
- funções de janela;
- `VARCHAR(MAX)`;
- `NVARCHAR(MAX)`;
- `DATE`;
- `DATETIME2`;
- `CREATE OR ALTER`;
- `DROP IF EXISTS`;
- `CONCAT`;
- `IIF`;
- `STRING_SPLIT`;
- `OFFSET/FETCH`.

---

## Parâmetros

Verificar:

- nomes;
- ordem;
- tipo;
- tamanho;
- precisão;
- escala;
- nulabilidade;
- compatibilidade com ADO ou C#;
- tratamento de vazio e `NULL`.

---

## SELECT

Verificar:

- ausência de `SELECT *` em novos contratos;
- ordem de colunas;
- aliases;
- filtros;
- joins;
- `ORDER BY`;
- risco de retorno excessivo;
- risco de dados de outro contexto.

---

## INSERT

Verificar:

- lista explícita de colunas;
- correspondência com valores;
- campos obrigatórios;
- valores nulos;
- identificador retornado;
- duplicidade;
- fallback;
- idempotência, quando necessário.

---

## UPDATE

Verificar principalmente:

- `WHERE`;
- chave correta;
- quantidade de linhas;
- alteração de registros indevidos;
- semântica de `@@ROWCOUNT`;
- concorrência;
- regra prévia.

Um `UPDATE` sem filtro deve ser tratado como bloqueador, salvo justificativa explícita.

---

## DELETE

Verificar:

- `WHERE`;
- exclusão física ou lógica;
- dependências;
- integridade;
- histórico;
- auditoria;
- comportamento em reexecução.

---

## RETURN

Verificar:

- semântica preservada;
- captura imediata de `@@ROWCOUNT`;
- identificador correto;
- compatibilidade com consumidor;
- códigos negativos ou funcionais.

---

## Transação SQL

Verificar se foi adicionado:

```sql
BEGIN TRAN
COMMIT
ROLLBACK
```

Analisar interação com:

- COM+;
- `ObjectContext`;
- `TransactionScope`;
- chamadas externas;
- operações encadeadas.

---

# Revisão de XSL

## Verificar

- arquivo correto;
- nome correto;
- caminho correto;
- template correto;
- nomes dos elementos;
- aliases da procedure;
- nós opcionais;
- estrutura final;
- namespaces;
- compatibilidade com XSLT utilizada;
- encoding.

## Perguntas

- O novo campo é transformado?
- O campo removido ainda é referenciado?
- O XSL espera um alias que mudou?
- A hierarquia produzida continua igual?
- Consumidores dependem da ordem?
- O arquivo foi salvo em outro encoding?

---

# Revisão de XML

## Verificar

- XML válido;
- nomes exatos;
- caixa;
- hierarquia;
- elementos obrigatórios;
- elementos opcionais;
- caracteres especiais;
- escape;
- contexto do cliente;
- contrato de retorno.

## Sinais de risco

- concatenação manual de texto livre;
- mudança de nome de nó;
- mudança de raiz;
- introdução de namespace;
- remoção de `ReturnValue`;
- mudança de snake_case para camelCase.

---

# Revisão de ASP Classic

## Verificar

- sintaxe VBScript;
- fechamento de blocos;
- includes;
- variáveis;
- objetos;
- `Request`;
- `Session`;
- cookies;
- tratamento de erro;
- JavaScript;
- renderização;
- submissão;
- encoding Windows-1252;
- strings com acentos;
- diff mínimo.

## Regra de negócio

Confirmar se a página apenas controla a experiência ou se está tentando substituir regra central.

## Segurança

Verificar:

- parâmetros confiáveis;
- autorização;
- exposição de dados;
- injeção;
- saída sem encoding;
- manipulação de URL;
- acesso indevido por alteração de query string.

---

# Revisão de ASP.NET WebForms

## Verificar

- ciclo de vida da página;
- `IsPostBack`;
- ViewState;
- eventos;
- binding;
- validação;
- code-behind;
- proxies;
- contratos XML;
- autorização;
- tratamento de exceção;
- compatibilidade com .NET Framework.

Não aceitar migração incidental para padrões modernos fora do escopo.

---

# Revisão de APIs

## Controller

Verificar:

- rota;
- verbo HTTP;
- filtros;
- autenticação;
- autorização;
- contexto do cliente;
- controller enxuto;
- delegação para serviço;
- validação de entrada;
- resposta;
- tratamento de erro.

---

## DTO

Verificar:

- contrato público;
- nomes JSON;
- obrigatoriedade;
- nulabilidade;
- compatibilidade retroativa;
- dados sensíveis;
- propriedades removidas;
- novos campos opcionais ou obrigatórios.

---

## Respostas HTTP

Verificar se os códigos são coerentes:

- sucesso;
- validação;
- não autorizado;
- proibido;
- não encontrado;
- conflito;
- erro interno.

Não expor stack trace ou detalhes internos.

---

# Revisão de React

## Verificar

- chamada à API;
- tratamento de loading;
- tratamento de erro;
- estado;
- validação de interface;
- permissões;
- renderização condicional;
- duplicidade de chamadas;
- contrato do DTO;
- comportamento após sucesso;
- acessibilidade;
- consistência com componentes existentes.

## Regra

Validação no React não substitui regra no backend.

---

# Revisão de banco global e banco individual

## Verificar

- o dado pertence ao contexto correto;
- o identificador da conta é propagado;
- não existe banco fixo;
- não há mistura de dados entre clientes;
- a conexão é obtida pelo mecanismo padrão;
- o script será aplicado no conjunto correto de bases;
- não há uso indevido do Banco Global para dados operacionais.

Qualquer risco de acesso cruzado entre clientes deve ser tratado como bloqueador.

---

# Revisão de segurança

## Verificar

- autenticação;
- autorização;
- perfil;
- grupo;
- zona interna ou externa;
- contexto do cliente;
- dados sensíveis;
- logs;
- mensagens;
- tokens;
- certificados;
- connection strings;
- query strings;
- uploads;
- integrações.

## Nunca aprovar

- credencial no código;
- token em comentário;
- connection string fixa;
- log com dados clínicos;
- remoção de filtro de autorização;
- acesso por identificador sem validação de contexto;
- retorno de informação interna desnecessária.

---

# Revisão de privacidade e LGPD

Verificar se a alteração:

- expõe dados pessoais;
- registra dados excessivos;
- amplia acesso;
- transfere dados a terceiro;
- adiciona informações em logs;
- utiliza dados reais em teste;
- altera anonimização;
- permite acesso entre clientes.

Em funcionalidades clínicas, financeiras ou de integração, aplicar atenção especial.

---

# Revisão de integrações externas

## Verificar

- contrato atual do terceiro;
- autenticação;
- timeout;
- retry;
- idempotência;
- duplicidade;
- persistência do protocolo;
- resposta parcial;
- erro externo;
- conciliação;
- log seguro;
- máscara de credenciais;
- fallback;
- indisponibilidade.

## Pergunta crítica

```text
O que acontece se o terceiro executar a operação,
mas o EMED não receber a resposta?
```

A alteração deve considerar inconsistência entre estado local e externo.

---

# Revisão de transações

## COM+

Verificar:

- `SetComplete`;
- `SetAbort`;
- objetos criados no contexto;
- chamadas múltiplas;
- erro intermediário;
- gravação parcial.

## ORMEMED

Verificar:

- `TransactionScope`;
- escopo;
- `Complete`;
- timeout;
- chamadas externas dentro da transação;
- conexões múltiplas;
- promoção para transação distribuída.

## Regra

Não aprovar fragmentação de uma operação atômica sem justificativa.

---

# Revisão de concorrência

Verificar quando aplicável:

- leitura seguida de atualização;
- dois usuários alterando o mesmo registro;
- validação baseada em estado anterior;
- geração de identificador;
- duplicidade;
- conciliação;
- atualização de status;
- processamento repetido;
- uso de `NOLOCK`;
- bloqueios.

Pergunta:

```text
O que acontece se duas execuções ocorrerem ao mesmo tempo?
```

---

# Revisão de performance

Não transformar o review em otimização prematura.

Avaliar performance quando a alteração:

- adiciona consulta dentro de loop;
- amplia retorno;
- remove filtro;
- inclui join pesado;
- usa função em coluna indexada;
- cria tabela temporária;
- adiciona chamada externa;
- repete Data Service;
- processa grande volume;
- afeta todos os clientes.

## Sinais de alerta

- N+1;
- `SELECT *`;
- consulta sem filtro;
- loop com chamada ao banco;
- carregamento completo para filtrar em memória;
- transação longa;
- chamada externa dentro da transação;
- `NOLOCK` adicionado sem análise.

---

# Revisão de compatibilidade

## Verificar compatibilidade com

- SQL Server 2000;
- VB6;
- COM+;
- MSXML;
- ADODB;
- ASP Classic;
- Windows-1252;
- ASP.NET WebForms;
- .NET Framework;
- `packages.config`;
- ORMEMED;
- WebServices SOAP;
- API existente;
- React existente;
- sistemas terceiros.

Não aprovar recurso que dependa de atualização tecnológica não prevista.

---

# Revisão de encoding

## Verificar

- Windows-1252 preservado;
- UTF-8 não introduzido indevidamente;
- BOM;
- CRLF;
- caracteres acentuados;
- strings;
- comentários;
- XSL;
- ASP;
- VB6;
- SQL.

## Sinal comum

Quando quase todas as linhas aparecem alteradas, verificar encoding e finais de linha antes de revisar conteúdo.

---

# Revisão de publicação

## Verificar

- ordem de publicação;
- dependências entre repositórios;
- compatibilidade temporária;
- scripts necessários;
- XSL incluído;
- registro COM+;
- proxy atualizado;
- API publicada;
- frontend publicado;
- configuração criada;
- permissões;
- rollback.

## Perguntas

- O backend deve ser publicado antes?
- A nova procedure é compatível com a versão atual do código?
- O novo código funciona com a procedure antiga?
- Existe janela de incompatibilidade?
- O componente COM+ precisa ser recompilado e registrado?
- O XSL será incluído no pacote?

---

# Revisão de rollback

Verificar se existe estratégia para desfazer:

- script estrutural;
- carga de dados;
- configuração;
- publicação COM+;
- API;
- frontend;
- integração.

Nem toda alteração possui rollback simples.

Quando não houver, o risco deve estar explícito.

---

# Revisão de testes

## Verificar se foram testados

- cenário principal;
- cenários alternativos;
- valores vazios;
- valores nulos;
- registro existente;
- registro inexistente;
- usuário sem permissão;
- cliente diferente;
- falha de integração;
- reexecução;
- concorrência, quando relevante;
- retorno antigo e novo;
- rollback.

## Qualidade da evidência

Aceitar evidências como:

- compilação;
- execução local;
- teste em ambiente;
- comparação de XML;
- execução de procedure;
- print de tela;
- log controlado;
- teste automatizado;
- revisão estática.

Não exigir teste impossível sem considerar limitações do ambiente, mas registrar o que não foi validado.

---

# Revisão de comentários

Comentários devem explicar:

- motivo;
- regra;
- exceção;
- dependência;
- decisão.

Evitar comentários que apenas repetem o código.

Não bloquear por estilo de comentário salvo quando:

- está incorreto;
- contradiz o comportamento;
- expõe dado sensível;
- induz manutenção errada.

---

# Revisão de documentação

Quando a alteração impacta arquitetura, contrato ou operação, verificar necessidade de atualizar:

- AGENTS;
- documentação técnica;
- fluxo;
- tarefa;
- publicação;
- configuração;
- contrato da API;
- manual;
- instrução de suporte.

Não exigir documentação extensa para correção trivial.

---

# Como escrever comentários de review

Um bom comentário deve conter:

1. problema;
2. impacto;
3. evidência;
4. correção esperada.

Exemplo:

```text
[ALTO] O novo campo foi incluído no SELECT da procedure,
mas não foi adicionado ao XSL consumido por
LNUC.DSFeriado.GetListaFeriado.

Nesse fluxo, o XML bruto é transformado antes de chegar ao BS,
portanto o campo não será disponibilizado ao consumidor.

Inclua o elemento no template correspondente ou confirme
que a chamada utiliza outro XSL.
```

---

# Comentário ruim

```text
Não gostei.
```

```text
Faria diferente.
```

```text
Melhor refatorar tudo.
```

```text
Use padrão moderno.
```

Comentários devem ser objetivos e verificáveis.

---

# Evitar excesso de comentários

Não comentar cada linha.

Agrupar achados relacionados.

Priorizar:

- defeitos;
- riscos;
- contratos;
- segurança;
- regressões;
- publicação.

Não transformar o review em aula de estilo.

---

# Preferências pessoais

Não bloquear por:

- nome de variável aceitável no padrão local;
- quantidade de linhas;
- uso histórico de `Variant`;
- uso de `IIf` seguro;
- formato legado;
- ausência de padrão moderno;
- tecnologia antiga.

O review deve respeitar o contexto.

---

# Aprovação com ressalvas

Quando não houver bloqueadores, mas existirem riscos menores, pode-se registrar:

```text
Aprovado com ressalva:
- validar cenário X;
- confirmar publicação do XSL;
- acompanhar comportamento em homologação.
```

A ressalva não deve ocultar problema que deveria bloquear.

---

# Revisão por tipo de alteração

## Correção pontual

Priorizar:

- causa raiz;
- menor diff;
- regressão;
- encoding;
- cenário exato;
- ausência de refatoração.

## Nova funcionalidade

Priorizar:

- fluxo completo;
- contratos;
- segurança;
- persistência;
- testes;
- publicação;
- compatibilidade.

## Refatoração

Priorizar:

- comportamento preservado;
- testes;
- escopo;
- consumidores;
- risco de incompatibilidade;
- ganho real.

## Alteração de banco

Priorizar:

- SQL Server 2000;
- todos os clientes;
- dados existentes;
- reexecução;
- rollback;
- tempo de execução;
- bloqueios.

## Integração externa

Priorizar:

- contrato;
- idempotência;
- segurança;
- falha parcial;
- conciliação;
- rastreabilidade.

---

# Checklist geral de code review

## Escopo

- [ ] A alteração atende à tarefa?
- [ ] O diff é mínimo?
- [ ] Não há arquivos fora do escopo?
- [ ] Não há refatoração incidental?
- [ ] O encoding foi preservado?

## Arquitetura

- [ ] A camada está correta?
- [ ] COM+ e ORMEMED não foram misturados?
- [ ] A regra está no Business Service?
- [ ] A persistência está no Data Service?
- [ ] A interface não acessa banco?

## Contratos

- [ ] Assinaturas públicas foram preservadas?
- [ ] XML foi preservado?
- [ ] XSL foi revisado?
- [ ] DTO foi revisado?
- [ ] Rotas foram preservadas?
- [ ] RETURN_VALUE foi preservado?

## Banco

- [ ] SQL Server 2000?
- [ ] Procedure no padrão correto?
- [ ] GRANT ALL presente?
- [ ] WHERE seguro?
- [ ] Tipos corretos?
- [ ] Banco Global ou Individual correto?
- [ ] Contexto do cliente preservado?

## Segurança

- [ ] Autenticação preservada?
- [ ] Autorização preservada?
- [ ] Sem credenciais?
- [ ] Sem dados sensíveis em log?
- [ ] Sem acesso cruzado entre clientes?

## Transação

- [ ] SetComplete/SetAbort corretos?
- [ ] TransactionScope correto?
- [ ] Sem gravação parcial?
- [ ] Chamada externa analisada?

## Publicação

- [ ] Ordem definida?
- [ ] Scripts incluídos?
- [ ] XSL incluído?
- [ ] Compatibilidade temporária?
- [ ] Rollback considerado?

## Testes

- [ ] Cenário principal?
- [ ] Cenários alternativos?
- [ ] Nulos e vazios?
- [ ] Permissões?
- [ ] Reexecução?
- [ ] Limitações registradas?

---

# Checklist específico — VB6/COM+

- [ ] Assinatura pública preservada?
- [ ] `ByVal`, `ByRef` e `Optional` preservados?
- [ ] `ObjectContext` preservado?
- [ ] `CreateInstance` utilizado conforme padrão?
- [ ] `SetComplete` no sucesso?
- [ ] `SetAbort` no erro?
- [ ] `errorHandler` correto?
- [ ] Objetos liberados?
- [ ] XML validado?
- [ ] `global_cd_empresa_conta_emed` propagado?
- [ ] Sem SQL no BS?
- [ ] DS apenas com persistência?

---

# Checklist específico — SQL COM+

- [ ] Nome `p_PREFIXO_DSTabela_Operacao`?
- [ ] Compatível com SQL Server 2000?
- [ ] GET com `FOR XML AUTO, ELEMENTS`?
- [ ] Aliases preservados?
- [ ] XSL revisado?
- [ ] `RETURN` correto?
- [ ] `GRANT ALL` presente?

---

# Checklist específico — SQL ORMEMED

- [ ] GET com `p_PREFIXO_GS_Tabela_Operacao`?
- [ ] Escrita com `p_PREFIXO_DS_Tabela_Operacao`?
- [ ] Retorno tabular?
- [ ] Sem `FOR XML`?
- [ ] Colunas e tipos preservados?
- [ ] `RETURN_VALUE` correto?
- [ ] `GRANT ALL` presente?

---

# Checklist específico — API

- [ ] Rota correta?
- [ ] Verbo HTTP correto?
- [ ] Filtros preservados?
- [ ] Controller enxuto?
- [ ] DTO compatível?
- [ ] Contexto do cliente correto?
- [ ] Códigos HTTP adequados?
- [ ] Sem detalhes internos na resposta?

---

# Checklist específico — React

- [ ] Contrato da API correto?
- [ ] Loading tratado?
- [ ] Erro tratado?
- [ ] Estado atualizado?
- [ ] Ação duplicada evitada?
- [ ] Permissão não depende apenas do frontend?
- [ ] Cenários vazios tratados?

---

# Critérios para aprovação

Uma alteração pode ser aprovada quando:

- atende ao objetivo;
- segue o padrão do repositório;
- preserva contratos;
- não introduz risco crítico;
- possui diff proporcional;
- mantém compatibilidade;
- considera segurança;
- considera o contexto do cliente;
- possui validação adequada;
- possui publicação viável.

---

# Critérios para reprovação

A alteração deve ser rejeitada quando:

- não resolve a tarefa;
- resolve apenas parcialmente o fluxo;
- quebra consumidor;
- mistura padrões arquiteturais;
- contém SQL incompatível;
- compromete segurança;
- permite acesso cruzado;
- perde dados;
- remove transação;
- altera contrato sem coordenação;
- não pode ser publicada com segurança;
- contém diff massivo sem justificativa;
- não permite entender o comportamento resultante.

---

# Ordem de precedência

Durante o review, considerar:

1. comportamento esperado da tarefa;
2. código equivalente no mesmo componente;
3. contratos existentes;
4. documentação específica;
5. padrões arquiteturais;
6. este documento;
7. preferências do revisor.

Preferências pessoais possuem a menor prioridade.

---

# Princípios finais

1. Code review é análise de risco, não disputa de estilo.

2. A alteração deve ser julgada dentro da arquitetura em que está inserida.

3. Compatibilidade é mais importante do que modernização incidental.

4. O menor diff possível facilita revisão e reduz regressão.

5. Toda mudança de contrato exige análise de consumidores.

6. Banco Global e bancos individuais devem permanecer isolados.

7. Segurança e autorização nunca devem ser flexibilizadas por conveniência.

8. Stored Procedures devem respeitar SQL Server 2000 e o padrão correto.

9. COM+ e ORMEMED possuem convenções distintas.

10. Testes devem refletir o risco da alteração.

11. Comentários de review devem ser objetivos, reproduzíveis e acionáveis.

12. O código existente é a principal referência.

13. Uma boa revisão protege o comportamento do sistema sem impor preferências pessoais.

14. O revisor deve ajudar a reduzir risco, não aumentar o escopo.