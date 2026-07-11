# Padrões SQL — Ecossistema EMED

## Objetivo

Este documento define os padrões obrigatórios para criação, alteração, revisão e análise de scripts SQL no ecossistema EMED.

Aplica-se principalmente a:

- Stored Procedures;
- scripts de criação e alteração de tabelas;
- scripts de carga e atualização de dados;
- consultas auxiliares;
- scripts de publicação;
- persistências consumidas por componentes COM+/VB6;
- persistências consumidas pelo framework ORMEMED em C#.

O objetivo é garantir:

- compatibilidade com SQL Server 2000;
- aderência aos padrões históricos dos projetos;
- compatibilidade com consumidores existentes;
- preservação dos contratos XML e tabulares;
- menor impacto possível no controle de versão;
- execução segura em ambientes com bancos individuais por cliente.

O código existente no repositório em manutenção é sempre a principal fonte de verdade.

---

# Escopo e contexto

O ecossistema EMED possui dois padrões principais de persistência:

```text
Padrão COM+
    VB6
    ADODB
    XML
    XSL
    Stored Procedure com FOR XML

Padrão ORMEMED
    C#
    SqlCommand
    DataTable / DataSet
    Stored Procedure com retorno tabular
```

Embora ambos utilizem SQL Server e Stored Procedures, eles possuem diferenças obrigatórias de:

- nomenclatura;
- formato de retorno;
- consumidores;
- tratamento do resultado;
- organização das classes;
- vínculo com XSL.

Nunca misturar os dois padrões.

---

# Regra fundamental

Antes de criar ou alterar qualquer Stored Procedure:

1. identificar quem consome a procedure;
2. determinar se a implementação pertence ao padrão COM+ ou ORMEMED;
3. localizar uma procedure equivalente no mesmo componente;
4. localizar o Data Service consumidor;
5. verificar se existe XSL associado;
6. preservar nomenclatura, retorno e semântica existentes;
7. implementar o menor ajuste possível.

Não determinar o padrão apenas pelo nome da pasta ou da tabela.

O consumidor real da procedure é o principal indicador.

---

# Compatibilidade com SQL Server 2000

Todo SQL deve ser compatível com SQL Server 2000, salvo quando o repositório comprovar explicitamente o uso de uma versão posterior.

Não utilizar recursos introduzidos em versões posteriores.

## Recursos proibidos

Não utilizar:

```sql
WITH CTE
MERGE
TRY
CATCH
THROW
CREATE OR ALTER
DROP IF EXISTS
ROW_NUMBER()
RANK()
DENSE_RANK()
LAG()
LEAD()
STRING_SPLIT()
STRING_AGG()
CONCAT()
IIF()
FORMAT()
OFFSET
FETCH
SEQUENCE
DATETIME2
DATE
TIME
VARCHAR(MAX)
NVARCHAR(MAX)
XML
```

Também não utilizar sintaxes modernas como:

```sql
ALTER TABLE ... DROP COLUMN IF EXISTS
```

ou:

```sql
CREATE TABLE IF NOT EXISTS
```

---

# Tipos de dados

Utilizar apenas tipos compatíveis com SQL Server 2000 e coerentes com a estrutura existente.

Exemplos comuns:

```sql
int
smallint
tinyint
bit
char
varchar
nvarchar
datetime
smalldatetime
decimal
numeric
money
smallmoney
text
ntext
image
uniqueidentifier
```

## Regras

- Preservar o tipo já utilizado pela tabela e pelas procedures equivalentes.
- Preservar tamanho, precisão e escala.
- Não trocar `int` por `bigint` sem necessidade comprovada.
- Não trocar `varchar` por `nvarchar` automaticamente.
- Não substituir `text` por `varchar(max)`.
- Não substituir `datetime` por `date` ou `datetime2`.
- Não aumentar tamanho de parâmetro por conveniência.
- Não reduzir tamanho de parâmetro.
- Não alterar nulabilidade sem análise de impacto.

---

# Estrutura padrão de arquivo de Stored Procedure

Sempre verificar o modelo utilizado pelo componente.

Uma estrutura comum é:

```sql
IF EXISTS
(
    SELECT 1
    FROM sysobjects
    WHERE id = OBJECT_ID('p_PREFIXO_Procedure')
      AND type = 'P'
)
    DROP PROCEDURE p_PREFIXO_Procedure
GO

CREATE PROCEDURE p_PREFIXO_Procedure
    @parametro int
AS

    SET NOCOUNT ON

    -- Implementação

    RETURN @@ROWCOUNT
GO

GRANT ALL ON p_PREFIXO_Procedure TO GrpLEMED
GO
```

## Observações

- Reproduzir a forma de `DROP` utilizada pelo repositório.
- Não introduzir `CREATE OR ALTER`.
- Não alterar o cabeçalho histórico sem necessidade.
- Preservar `SET NOCOUNT ON` quando utilizado no padrão local.
- Não adicionar `SET NOCOUNT ON` indiscriminadamente quando a procedure depende da contagem de linhas retornada pelo protocolo do consumidor.
- Preservar separadores `GO`.

---

# Permissão obrigatória

Toda Stored Procedure deve terminar com:

```sql
GRANT ALL ON p_NOME_DA_PROCEDURE TO GrpLEMED
GO
```

Exemplo:

```sql
GRANT ALL ON p_LNUC_DSFeriado_GetListaFeriado TO GrpLEMED
GO
```

## Regra

O nome informado no `GRANT` deve ser exatamente igual ao nome criado.

Erros comuns:

- esquecer o `GRANT`;
- copiar o nome de outra procedure;
- escrever nome com prefixo incorreto;
- omitir o `GO`;
- aplicar permissão a uma procedure inexistente.

---

# Padrão COM+

## Contexto

O padrão COM+ é consumido normalmente por:

- Data Services em VB6;
- ADODB.Command;
- execução com `adExecuteStream`;
- XML Root;
- transformação XSL;
- Business Services em VB6.

Fluxo conceitual:

```text
Business Service VB6
        │
        ▼
Data Service VB6
        │
        ▼
Stored Procedure COM+
        │
        ▼
FOR XML AUTO, ELEMENTS
        │
        ▼
XSL
        │
        ▼
XML de retorno
```

---

# Nomenclatura das procedures COM+

O padrão é:

```text
p_PREFIXO_DSTabela_Operacao
```

Exemplos:

```text
p_LNUC_DSFeriado_GetListaFeriado
p_LNUC_DSFeriado_InsertFeriado
p_LNUC_DSFeriado_UpdateFeriado
p_LNUC_DSFeriado_DeleteFeriado
```

## Regras

No padrão COM+:

- `DS` permanece acoplado ao nome da tabela ou domínio;
- consultas também utilizam `DS`;
- insert, update e delete também utilizam `DS`;
- não utilizar `GS`;
- não inserir `_` entre `DS` e o nome da entidade.

Correto:

```text
p_LNUC_DSFeriado_GetListaFeriado
```

Incorreto:

```text
p_LNUC_GS_Feriado_GetListaFeriado
p_LNUC_DS_Feriado_GetListaFeriado
p_LNUC_GSFeriado_GetListaFeriado
```

---

# Retorno de consultas COM+

Procedures GET no padrão COM+ devem retornar XML.

O padrão obrigatório é:

```sql
FOR XML AUTO, ELEMENTS
```

Exemplo:

```sql
SELECT
    f.cd_feriado,
    f.ano_feriado,
    f.mes_feriado,
    f.dia_feriado,
    f.descr_feriado,
    f.flag_geral
FROM LNUC_Feriado f
WHERE f.cd_feriado = @cd_feriado
FOR XML AUTO, ELEMENTS

RETURN @@ROWCOUNT
```

## Regra

Procedures GET COM+ devem possuir:

- `SELECT`;
- aliases compatíveis com o XSL;
- `FOR XML AUTO, ELEMENTS`;
- `RETURN` conforme o padrão equivalente.

Não retornar somente uma tabela convencional quando o consumidor executa a procedure por `adExecuteStream`.

---

# Aliases no padrão COM+

O alias utilizado na consulta influencia diretamente o XML gerado pelo SQL Server.

Exemplo:

```sql
SELECT
    f.cd_feriado,
    f.descr_feriado
FROM LNUC_Feriado f
FOR XML AUTO, ELEMENTS
```

O alias `f` pode originar elementos que são consumidos pelo XSL.

## Regra

Não alterar:

- alias da tabela;
- nome das colunas;
- aliases das colunas;
- hierarquia dos `SELECTs`;
- ordem estrutural do retorno;

sem analisar o XSL e todos os consumidores.

Uma alteração aparentemente estética pode quebrar o XML.

---

# Procedures de escrita COM+

Insert, update e delete seguem o mesmo padrão de nome:

```text
p_PREFIXO_DSTabela_Operacao
```

Exemplo de insert:

```sql
CREATE PROCEDURE p_LNUC_DSFeriado_InsertFeriado
    @ano_feriado smallint,
    @mes_feriado tinyint,
    @dia_feriado tinyint,
    @descr_feriado varchar(100),
    @flag_geral char(1)
AS

    INSERT LNUC_Feriado
    (
        ano_feriado,
        mes_feriado,
        dia_feriado,
        descr_feriado,
        flag_geral
    )
    VALUES
    (
        @ano_feriado,
        @mes_feriado,
        @dia_feriado,
        @descr_feriado,
        @flag_geral
    )

    RETURN @@IDENTITY
GO

GRANT ALL ON p_LNUC_DSFeriado_InsertFeriado TO GrpLEMED
GO
```

O valor de retorno deve reproduzir a semântica da implementação equivalente.

Pode representar:

- `@@ROWCOUNT`;
- identificador incluído;
- código de situação;
- valor específico de negócio.

Não alterar a semântica do `RETURN` sem verificar o Data Service e o Business Service.

---

# Padrão ORMEMED

## Contexto

O padrão ORMEMED é consumido normalmente por:

- Data Services em C#;
- `SqlCommand`;
- `CommandType.StoredProcedure`;
- `ExecuteDataTable`;
- `ExecuteScalar`;
- `DataTable`;
- `DataSet`;
- `TransactionScope`.

Fluxo conceitual:

```text
Business Service C#
        │
        ▼
Data Service C#
        │
        ▼
Stored Procedure ORMEMED
        │
        ▼
Resultado tabular
```

---

# Nomenclatura das procedures ORMEMED

## Consultas

O padrão de consulta é:

```text
p_PREFIXO_GS_Tabela_Operacao
```

Exemplos:

```text
p_LEMED_GS_AgendamentoPerfil_GetAgendamentoMarcacao
p_LINT_GS_Sms_GetListaMsgVerificacao
```

## Escritas

Insert, update e delete utilizam:

```text
p_PREFIXO_DS_Tabela_Operacao
```

Exemplos:

```text
p_LINT_DS_DisplaySenha_InsertDisplaySenha
p_LEMED_DS_AgendamentoPerfil_UpdateAgendamentoPerfil
p_LEMED_DS_AgendamentoPerfil_DeleteAgendamentoPerfil
```

## Regras

Correto:

```text
p_LEMED_GS_Agendamento_GetLista
p_LEMED_DS_Agendamento_InsertAgendamento
```

Incorreto:

```text
p_LEMED_GSAgendamento_GetLista
p_LEMED_DSA­gendamento_InsertAgendamento
p_LEMED_GSTabela_Operacao
p_LEMED_DSTabela_Operacao
```

No ORMEMED existe separador `_` após `GS` e `DS`.

---

# Retorno de consultas ORMEMED

Procedures GET no padrão ORMEMED retornam tabela por `SELECT`.

Exemplo:

```sql
CREATE PROCEDURE p_LEMED_GS_AgendamentoPerfil_GetAgendamentoMarcacao
    @cd_agendamento int
AS

    SELECT
        a.cd_agendamento,
        a.data_agendamento,
        a.cd_paciente
    FROM LEMED_Agendamento a
    WHERE a.cd_agendamento = @cd_agendamento

    RETURN @@ROWCOUNT
GO

GRANT ALL ON p_LEMED_GS_AgendamentoPerfil_GetAgendamentoMarcacao TO GrpLEMED
GO
```

## Regra

Procedures GET ORMEMED:

- retornam resultado tabular;
- não utilizam `FOR XML AUTO, ELEMENTS`;
- possuem `RETURN` conforme o padrão local;
- devem manter a ordem das colunas esperada pelo consumidor.

---

# Procedures de escrita ORMEMED

Exemplo:

```sql
CREATE PROCEDURE p_LINT_DS_DisplaySenha_InsertDisplaySenha
    @nome_display_senha varchar(100),
    @descr_display_senha varchar(255),
    @codigo_display_senha varchar(20),
    @flag_habilitado char(1)
AS

    INSERT LINT_DisplaySenha
    (
        nome_display_senha,
        descr_display_senha,
        codigo_display_senha,
        flag_habilitado
    )
    VALUES
    (
        @nome_display_senha,
        @descr_display_senha,
        @codigo_display_senha,
        @flag_habilitado
    )

    RETURN @@IDENTITY
GO

GRANT ALL ON p_LINT_DS_DisplaySenha_InsertDisplaySenha TO GrpLEMED
GO
```

A classe C# pode recuperar esse valor por meio do parâmetro:

```text
@RETURN_VALUE
```

A semântica deve permanecer compatível com o código consumidor.

---

# Identificação do padrão pelo consumidor

## Indícios de COM+

A procedure provavelmente pertence ao padrão COM+ quando o consumidor possui:

```vb
ADODB.Command
adCmdStoredProc
Properties("XML Root")
Properties("XSL")
Properties("Output Stream")
adExecuteStream
```

E quando existe arquivo XSL como:

```text
COMPONENTE.DSClasse.Metodo.xsl
```

Nesse caso, a procedure GET deve retornar:

```sql
FOR XML AUTO, ELEMENTS
```

---

## Indícios de ORMEMED

A procedure provavelmente pertence ao padrão ORMEMED quando o consumidor possui:

```csharp
SqlCommand
CommandType.StoredProcedure
ExecuteDataTable
ExecuteScalar
DataTable
DataSet
```

Nesse caso, a procedure GET deve retornar tabela.

---

# Parâmetros

## Nomenclatura

Preservar o nome adotado pela tabela, procedure e consumidor.

Exemplo:

```sql
@cd_agendamento
@cd_mov_financeira
@data_apropriacao
```

Não converter automaticamente para:

```sql
@idAgendamento
@codigoMovimentacao
@dataApropriacao
```

Os nomes fazem parte do contrato da procedure.

---

# Ordem dos parâmetros

Preservar a ordem utilizada pelas procedures equivalentes.

Embora chamadas nomeadas não dependam necessariamente da ordem, consumidores legados podem adicionar parâmetros de forma posicional ou reproduzir contratos gerados.

Não reordenar apenas para organização.

---

# Tipos dos parâmetros

O tipo SQL deve ser compatível com:

- coluna da tabela;
- parâmetro ADO;
- `SqlParameter`;
- XML de entrada;
- regra existente.

Exemplo:

```sql
@cd_feriado int
```

deve ser compatível com:

```vb
adInteger
```

E:

```sql
@dia_feriado tinyint
```

pode corresponder a:

```vb
adUnsignedTinyInt
```

Não alterar isoladamente um tipo apenas na Stored Procedure.

---

# Valores nulos

Antes de alterar tratamento de `NULL`, verificar:

- nulabilidade da coluna;
- uso de `NullIfEmpty` no VB6;
- uso de `DBNull.Value` no C#;
- lógica de fallback;
- comparações existentes;
- retorno esperado.

Não substituir arbitrariamente:

```sql
IS NULL
```

por:

```sql
= ''
```

`NULL` e string vazia possuem comportamentos diferentes.

---

# Comparações com NULL

Correto:

```sql
WHERE campo IS NULL
```

ou:

```sql
WHERE campo IS NOT NULL
```

Incorreto:

```sql
WHERE campo = NULL
```

---

# Tratamento de parâmetros opcionais

Um padrão possível é:

```sql
WHERE
    (@cd_agendamento IS NULL OR a.cd_agendamento = @cd_agendamento)
```

Entretanto, esse padrão só deve ser utilizado quando já existir em procedures equivalentes.

Não transformar todos os parâmetros em filtros opcionais.

Isso pode:

- alterar plano de execução;
- retornar dados indevidos;
- mudar a semântica da operação;
- prejudicar performance.

---

# SELECT

## Listagem explícita de colunas

Priorizar:

```sql
SELECT
    a.cd_agendamento,
    a.data_agendamento,
    a.cd_paciente
FROM LEMED_Agendamento a
```

Evitar:

```sql
SELECT *
FROM LEMED_Agendamento
```

## Motivos

`SELECT *` pode:

- alterar o contrato quando a tabela recebe nova coluna;
- modificar o XML gerado;
- modificar a ordem das colunas;
- aumentar tráfego;
- expor dados não esperados;
- quebrar XSL ou consumidores.

Se uma procedure existente utiliza `SELECT *`, não a refatorar fora do escopo.

---

# Ordem das colunas

Preservar a ordem existente.

Consumidores legados podem depender de:

- índice da coluna;
- ordem do `DataTable`;
- ordem do XML;
- transformação XSL;
- geração automatizada.

Não reordenar apenas por estética.

---

# Aliases de colunas

Exemplo:

```sql
SELECT
    p.cd_paciente AS cd_paciente,
    p.nome_paciente AS nome_paciente
```

O alias pode fazer parte do contrato.

Não renomear para camelCase, PascalCase ou nomes considerados mais claros sem revisar todos os consumidores.

---

# JOIN

Preservar o padrão predominante do repositório.

SQL Server 2000 suporta `INNER JOIN` e `LEFT JOIN`, mas projetos antigos podem conter sintaxe histórica.

Não converter joins existentes apenas por preferência.

Ao criar nova consulta, utilizar o padrão encontrado nas procedures equivalentes.

---

# Subconsultas e tabelas temporárias

SQL Server 2000 permite:

- subconsultas;
- tabelas temporárias;
- variáveis locais;
- cursores;
- tabelas derivadas.

Utilizar somente quando necessário e seguindo exemplos locais.

Antes de introduzir tabela temporária, verificar:

- volume de dados;
- índices;
- escopo da transação;
- concorrência;
- limpeza;
- comportamento em erro.

---

# Tabelas temporárias

Exemplo:

```sql
CREATE TABLE #Resultado
(
    cd_item int NOT NULL,
    descr_item varchar(100) NULL
)
```

Ao utilizar tabelas temporárias:

- declarar tipos compatíveis;
- criar índices quando comprovadamente necessário;
- não utilizar recursos de versões posteriores;
- garantir que o resultado final preserve o contrato esperado.

Não introduzir tabela temporária apenas para simplificar leitura.

---

# Cursores

Evitar criar novos cursores quando uma operação set-based equivalente for viável e compatível.

Entretanto, não remover cursores existentes durante uma correção pontual sem análise específica.

Cursores podem estar associados a:

- ordem de processamento;
- regras sequenciais;
- chamadas dependentes;
- comportamento histórico.

---

# INSERT

Listar explicitamente as colunas.

Correto:

```sql
INSERT LEMED_Tabela
(
    campo_a,
    campo_b,
    campo_c
)
VALUES
(
    @campo_a,
    @campo_b,
    @campo_c
)
```

Evitar:

```sql
INSERT LEMED_Tabela
VALUES
(
    @campo_a,
    @campo_b,
    @campo_c
)
```

A listagem explícita protege contra alterações futuras na estrutura.

---

# UPDATE

Sempre revisar cuidadosamente o `WHERE`.

Exemplo:

```sql
UPDATE LEMED_Tabela
SET
    descr_tabela = @descr_tabela,
    flag_ativo = @flag_ativo
WHERE cd_tabela = @cd_tabela
```

Antes de concluir:

- confirmar chave correta;
- confirmar contexto do registro;
- confirmar filtros adicionais;
- verificar possibilidade de atualizar múltiplas linhas;
- verificar semântica do `RETURN`.

Nunca executar um `UPDATE` sem `WHERE` salvo quando a tarefa explicitamente exigir atualização integral.

---

# DELETE

Exemplo:

```sql
DELETE LEMED_Tabela
WHERE cd_tabela = @cd_tabela
```

Antes de criar ou alterar:

- verificar dependências;
- verificar chaves estrangeiras;
- verificar exclusão lógica;
- verificar histórico;
- verificar auditoria;
- verificar procedures equivalentes;
- verificar se há regra no Business Service.

Não converter exclusão lógica em física ou o contrário sem análise.

---

# Exclusão lógica

Quando o sistema utilizar flags como:

```text
flag_ativo
flag_excluido
flag_habilitado
```

seguir o padrão existente.

Não assumir que todo registro deve ser fisicamente removido.

---

# Identificadores inseridos

SQL Server 2000 suporta `@@IDENTITY`.

Procedures históricas podem utilizá-lo:

```sql
RETURN @@IDENTITY
```

Não substituir automaticamente por recursos indisponíveis ou por outro padrão sem verificar o ambiente e os consumidores.

Quando houver trigger, analisar cuidadosamente a semântica existente antes de modificar a forma de obtenção do identificador.

---

# RETURN

O `RETURN` é parte do contrato da Stored Procedure.

Pode representar:

```text
@@ROWCOUNT
@@IDENTITY
código de sucesso
código de erro funcional
quantidade encontrada
identificador gerado
resultado específico
```

## Regra

Não padronizar todas as procedures para o mesmo retorno.

Antes de alterar, verificar:

- Data Service VB6;
- classe C#;
- parâmetro `@RETURN_VALUE`;
- Business Service;
- comparação do valor;
- XML de retorno;
- telas consumidoras.

---

# @@ROWCOUNT

Quando utilizado, deve ser capturado imediatamente após a instrução relevante.

Exemplo:

```sql
UPDATE LEMED_Tabela
SET flag_ativo = @flag_ativo
WHERE cd_tabela = @cd_tabela

RETURN @@ROWCOUNT
```

Não executar outra instrução antes do `RETURN`, pois `@@ROWCOUNT` pode ser alterado.

Quando for necessário executar outras instruções:

```sql
DECLARE @rowcount int

UPDATE LEMED_Tabela
SET flag_ativo = @flag_ativo
WHERE cd_tabela = @cd_tabela

SELECT @rowcount = @@ROWCOUNT

-- Outras instruções

RETURN @rowcount
```

---

# SET NOCOUNT ON

`SET NOCOUNT ON` reduz mensagens de linhas afetadas.

Pode ser utilizado conforme o padrão do componente:

```sql
SET NOCOUNT ON
```

## Atenção

Não adicionar ou remover indiscriminadamente.

Consumidores antigos podem possuir comportamento dependente das mensagens do SQL Server.

A procedure equivalente deve orientar a decisão.

---

# Transações

O ecossistema pode controlar transações em diferentes camadas:

```text
COM+              → ObjectContext
ORMEMED           → TransactionScope
Stored Procedure  → participa da transação existente
```

## Regra

Não adicionar:

```sql
BEGIN TRAN
COMMIT TRAN
ROLLBACK TRAN
```

sem analisar:

- Business Service;
- Data Service;
- configuração COM+;
- `TransactionScope`;
- chamadas encadeadas;
- possibilidade de transação distribuída.

Uma transação SQL local pode interferir no controle transacional superior.

---

# Tratamento de erros SQL

SQL Server 2000 não possui `TRY/CATCH`.

Quando o padrão exigir tratamento, utilizar mecanismos compatíveis, como:

```sql
IF @@ERROR <> 0
BEGIN
    RETURN -1
END
```

ou guardar imediatamente:

```sql
DECLARE @erro int
DECLARE @rowcount int

UPDATE LEMED_Tabela
SET campo = @campo
WHERE cd_tabela = @cd_tabela

SELECT
    @erro = @@ERROR,
    @rowcount = @@ROWCOUNT

IF @erro <> 0
    RETURN -1

RETURN @rowcount
```

Não introduzir tratamento diferente sem observar o padrão do componente.

---

# RAISERROR

SQL Server 2000 suporta `RAISERROR` em sintaxe compatível com a versão.

Utilizar somente quando houver padrão equivalente.

Não utilizar:

```sql
THROW
```

Mensagens e códigos de erro podem ser consumidos pelas camadas superiores.

Não alterá-los apenas por preferência.

---

# Datas

Utilizar tipos:

```sql
datetime
smalldatetime
```

Não utilizar:

```sql
date
datetime2
time
```

## Conversões

Preservar o padrão existente.

Evitar depender de formatos regionais ambíguos.

Preferir formatos não ambíguos quando necessário, observando compatibilidade com SQL Server 2000.

Exemplo conceitual:

```sql
CONVERT(datetime, '20260711', 112)
```

Não introduzir conversões desnecessárias quando o parâmetro já chega tipado.

---

# Datas UTC e tipos de domínio

O ecossistema pode utilizar conceitos como:

```text
smallDT_UTC
```

ou outros tipos representados na documentação funcional.

Antes de gerar SQL, confirmar o tipo físico real na tabela.

Não assumir que uma descrição arquitetural corresponde a um tipo nativo do SQL Server.

---

# Strings

## Concatenação

SQL Server 2000 utiliza:

```sql
+
```

Exemplo:

```sql
SELECT @texto = @nome + ' - ' + @descricao
```

Não utilizar:

```sql
CONCAT()
```

## NULL em concatenação

Em SQL Server, concatenar com `NULL` pode resultar em `NULL`.

Quando o comportamento desejado for string vazia, seguir o padrão existente:

```sql
ISNULL(@descricao, '')
```

Não aplicar `ISNULL` indiscriminadamente, pois isso altera a semântica.

---

# Funções compatíveis

Exemplos disponíveis em SQL Server 2000:

```sql
ISNULL
COALESCE
SUBSTRING
CHARINDEX
LEN
LTRIM
RTRIM
UPPER
LOWER
REPLACE
CONVERT
CAST
DATEADD
DATEDIFF
DATEPART
GETDATE
ABS
ROUND
```

Mesmo quando compatível, utilizar apenas quando adequado ao padrão do projeto.

---

# Paginação

SQL Server 2000 não possui:

```sql
OFFSET
FETCH
ROW_NUMBER()
```

Quando houver necessidade de paginação, localizar implementação equivalente no repositório.

Não inventar mecanismo novo sem análise.

---

# Ordenação

Uma Stored Procedure só deve utilizar `ORDER BY` quando a ordem fizer parte do comportamento esperado.

Preservar:

- campos;
- direção;
- critérios secundários;
- tratamento de nulos.

Não remover `ORDER BY` por considerar desnecessário.

Não adicionar ordenação apenas para facilitar testes.

---

# Performance

Antes de alterar uma consulta, considerar:

- índices existentes;
- seletividade dos filtros;
- volume de dados por cliente;
- joins;
- subconsultas;
- funções aplicadas a colunas;
- tabelas temporárias;
- chamadas repetidas;
- bloqueios;
- `NOLOCK`;
- plano compatível com SQL Server 2000.

Evitar aplicar funções diretamente em colunas filtradas quando isso impedir uso de índice, salvo quando o padrão ou a regra exigir.

Exemplo potencialmente problemático:

```sql
WHERE CONVERT(varchar, data_atendimento, 112) = @data
```

Pesquisar uma abordagem equivalente no projeto antes de alterar.

---

# NOLOCK

O uso de `NOLOCK` pode estar presente em consultas históricas.

## Regra

- Preservar quando já existir.
- Não adicionar automaticamente.
- Não remover automaticamente.
- Tratar a alteração como mudança de comportamento de isolamento.

`NOLOCK` pode permitir:

- leitura suja;
- dados não confirmados;
- registros duplicados ou ausentes durante concorrência.

Sua utilização deve seguir o padrão da funcionalidade.

---

# Índices

Não criar, remover ou alterar índices como efeito colateral de uma correção funcional.

Mudanças de índice devem considerar:

- todas as bases individuais;
- volume de clientes;
- tempo de publicação;
- bloqueios;
- espaço;
- impacto em insert/update/delete;
- planos existentes;
- SQL Server 2000.

Quando a tarefa exigir índice, gerar script separado e reversível conforme o padrão de publicação.

---

# Tabelas e alterações estruturais

Antes de alterar uma tabela:

1. pesquisar procedures que a utilizam;
2. pesquisar classes DS e GS;
3. pesquisar XSL;
4. pesquisar páginas e APIs;
5. verificar bancos individuais;
6. verificar Banco Global;
7. verificar carga inicial;
8. verificar scripts de publicação;
9. verificar migração de clientes existentes.

---

# Inclusão de coluna

Exemplo compatível:

```sql
ALTER TABLE LEMED_Tabela
ADD novo_campo varchar(50) NULL
GO
```

## Regras

- Definir nulabilidade conscientemente.
- Não incluir `NOT NULL` sem valor padrão ou estratégia de carga para registros existentes.
- Não usar tipos modernos.
- Atualizar procedures de insert, update e get quando necessário.
- Atualizar DS, BS, XSL, DTOs e telas consumidoras.
- Considerar todas as bases individuais.

---

# Alteração de coluna

Alterações de tipo, tamanho ou nulabilidade exigem análise especial.

Podem impactar:

- dados existentes;
- índices;
- constraints;
- parâmetros;
- componentes VB6;
- classes C#;
- XML;
- relatórios;
- integrações.

Não alterar diretamente sem script de validação e estratégia de publicação.

---

# Constraints

Preservar o padrão de nomenclatura do banco.

Antes de criar:

- `PRIMARY KEY`;
- `FOREIGN KEY`;
- `DEFAULT`;
- `CHECK`;
- `UNIQUE`;

pesquisar constraints equivalentes.

SQL Server 2000 possui limitações diferentes de versões modernas.

---

# Banco Global e bancos individuais

Antes de gerar qualquer script, determinar onde ele será executado:

```text
Banco Global
ou
Bancos Individuais
```

## Banco Global

Contém informações compartilhadas ou centralizadas por cliente, como:

- identificação de contas;
- habilitação de serviços;
- configurações centrais;
- dados de referência compartilhados.

## Bancos individuais

Contêm dados operacionais:

- pacientes;
- agendas;
- atendimentos;
- pedidos;
- financeiro;
- estoque;
- prontuário;
- faturamento;
- configurações operacionais.

## Regra

Não executar script de banco individual no Banco Global.

Não armazenar dados operacionais de cliente no Banco Global.

Não fixar nome de banco no script sem que o processo de publicação exija explicitamente.

---

# Scripts para múltiplos clientes

Alterações estruturais e procedures dos bancos individuais serão aplicadas em várias bases com a mesma estrutura.

Por isso, os scripts devem ser:

- determinísticos;
- compatíveis com dados existentes;
- seguros para repetição quando exigido;
- sem referência fixa a um cliente;
- sem dados reais;
- com tratamento de cenários já publicados quando necessário.

---

# Scripts idempotentes

Quando a tarefa exigir possibilidade de reexecução, utilizar verificações compatíveis com SQL Server 2000.

Exemplo:

```sql
IF NOT EXISTS
(
    SELECT 1
    FROM sysobjects
    WHERE name = 'LEMED_Tabela'
      AND type = 'U'
)
BEGIN
    CREATE TABLE LEMED_Tabela
    (
        cd_tabela int NOT NULL
    )
END
GO
```

Para colunas:

```sql
IF NOT EXISTS
(
    SELECT 1
    FROM syscolumns
    WHERE id = OBJECT_ID('LEMED_Tabela')
      AND name = 'novo_campo'
)
BEGIN
    ALTER TABLE LEMED_Tabela
    ADD novo_campo varchar(50) NULL
END
GO
```

Reproduzir o padrão do repositório e do processo de publicação.

---

# Scripts de dados

Scripts de inclusão ou atualização de dados devem considerar:

- duplicidade;
- execução em clientes já parcialmente atualizados;
- chaves existentes;
- diferenças históricas;
- fallback;
- rollback, quando aplicável;
- ausência do registro esperado.

Exemplo conceitual:

```sql
IF NOT EXISTS
(
    SELECT 1
    FROM LEMED_TabelaDominio
    WHERE cd_dominio = @cd_dominio
)
BEGIN
    INSERT LEMED_TabelaDominio
    (
        cd_dominio,
        descr_dominio
    )
    VALUES
    (
        @cd_dominio,
        @descr_dominio
    )
END
```

Não criar registros duplicados em scripts reaplicáveis.

---

# Fallback em scripts

Quando uma atualização depender de registro existente, prever comportamento seguro conforme a tarefa.

Exemplo conceitual:

```sql
IF EXISTS
(
    SELECT 1
    FROM LEMED_Tabela
    WHERE cd_tabela = 10
)
BEGIN
    UPDATE LEMED_Tabela
    SET descr_tabela = 'Nova descrição'
    WHERE cd_tabela = 10
END
ELSE
BEGIN
    INSERT LEMED_Tabela
    (
        cd_tabela,
        descr_tabela
    )
    VALUES
    (
        10,
        'Nova descrição'
    )
END
```

O fallback deve ser definido pela regra funcional, e não inventado automaticamente.

---

# Scripts destrutivos

Considerar destrutivos:

```sql
DROP TABLE
TRUNCATE TABLE
DELETE sem filtro
UPDATE sem filtro
DROP COLUMN
DROP INDEX
```

Não gerar ou executar sem solicitação explícita e análise de impacto.

Quando necessários:

- separar em script específico;
- documentar impacto;
- prever backup;
- prever validação;
- prever rollback quando possível;
- confirmar ambiente.

---

# Arquivos SQL

Preservar:

- encoding;
- CRLF;
- indentação;
- capitalização predominante;
- comentários;
- estrutura do cabeçalho;
- `GO`;
- ordem das procedures;
- nomes físicos dos arquivos.

Não reformatar o arquivo inteiro para alterar poucas linhas.

---

# Encoding

Arquivos SQL legados podem utilizar Windows-1252.

Não converter automaticamente para UTF-8.

A conversão pode:

- alterar acentos;
- produzir diff no arquivo inteiro;
- afetar ferramentas de publicação;
- quebrar textos e mensagens.

---

# Comentários SQL

Comentários devem explicar:

- regra;
- exceção;
- razão funcional;
- dependência histórica;
- comportamento não evidente.

Bom exemplo:

```sql
-- Mantém o favorecido da movimentação financeira vinculado
-- ao favorecido já definido para a Nota Fiscal.
```

Comentário pouco útil:

```sql
-- Atualiza a tabela
UPDATE ...
```

Não remover comentários históricos sem necessidade.

---

# Cabeçalhos

Quando o componente utilizar cabeçalho de autoria ou histórico, preservar o formato.

Não atualizar datas, autores ou versões automaticamente durante alteração pontual.

Adicionar informação apenas quando o processo do projeto exigir.

---

# Alterações cirúrgicas

Durante uma manutenção:

- alterar somente a procedure necessária;
- não reordenar parâmetros;
- não reformatar todo o script;
- não alterar capitalização global;
- não substituir aliases sem necessidade;
- não modernizar sintaxe;
- não incluir índices fora do escopo;
- não ajustar procedures semelhantes sem solicitação.

---

# Análise de impacto de uma Stored Procedure COM+

Antes de alterar:

```text
Stored Procedure
       │
       ▼
XML bruto gerado
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
Proxy C# / ASP / WebForms
```

Verificar especialmente:

- aliases;
- nome dos elementos;
- hierarquia XML;
- `ReturnValue`;
- parâmetros ADO;
- tipos ADO;
- nome do XSL.

---

# Análise de impacto de uma Stored Procedure ORMEMED

Antes de alterar:

```text
Stored Procedure
       │
       ▼
DataTable / DataSet
       │
       ▼
Data Service C#
       │
       ▼
Business Service C#
       │
       ▼
API / WebForms / serviço
```

Verificar especialmente:

- nomes das colunas;
- ordem das colunas;
- tipos;
- nulabilidade;
- `RETURN_VALUE`;
- `TableName`;
- conversões no C#;
- DTOs.

---

# Inclusão de parâmetro

Ao incluir um parâmetro em uma operação COM+, verificar:

1. tela ou consumidor;
2. Business Service VB6;
3. XML de critério;
4. Data Service VB6;
5. validação do nó;
6. `CreateParameter`;
7. tipo ADO;
8. Stored Procedure;
9. tabela;
10. tratamento de nulo.

Em ORMEMED, verificar:

1. consumidor;
2. Business Service C#;
3. Data Service C#;
4. `SqlParameter`;
5. `SqlDbType`;
6. Stored Procedure;
7. tabela;
8. tratamento de `DBNull`.

---

# Inclusão de campo no retorno

## COM+

Verificar:

1. `SELECT`;
2. alias da coluna;
3. alias da tabela;
4. `FOR XML AUTO, ELEMENTS`;
5. XSL;
6. XML final;
7. BS;
8. proxy;
9. tela.

## ORMEMED

Verificar:

1. `SELECT`;
2. nome da coluna;
3. ordem;
4. tipo;
5. `DataTable`;
6. BS;
7. DTO;
8. API;
9. tela.

---

# Antipadrões

Nunca:

- utilizar sintaxe incompatível com SQL Server 2000;
- misturar nomenclatura COM+ e ORMEMED;
- retornar tabela em GET COM+;
- retornar XML em GET ORMEMED;
- esquecer o `RETURN`;
- alterar a semântica do `RETURN_VALUE`;
- esquecer o `GRANT ALL`;
- alterar aliases sem revisar XSL;
- utilizar `SELECT *` em novos contratos;
- reordenar colunas por estética;
- fixar nome de banco de cliente;
- adicionar transação SQL sem analisar COM+ ou `TransactionScope`;
- criar SQL direto no Business Service;
- incluir regra de negócio complexa na persistência;
- usar dados de produção em scripts;
- converter encoding;
- reformatar arquivos inteiros;
- declarar sucesso sem validar o consumidor.

---

# Checklist para Stored Procedure COM+

Antes de concluir:

- [ ] A procedure é realmente do padrão COM+?
- [ ] O nome segue `p_PREFIXO_DSTabela_Operacao`?
- [ ] O SQL é compatível com SQL Server 2000?
- [ ] Os parâmetros correspondem ao Data Service VB6?
- [ ] Os tipos correspondem aos tipos ADO?
- [ ] A consulta utiliza `FOR XML AUTO, ELEMENTS`?
- [ ] Os aliases foram preservados?
- [ ] O XSL foi revisado?
- [ ] O `RETURN` mantém a semântica esperada?
- [ ] O `GRANT ALL` foi incluído?
- [ ] O encoding foi preservado?
- [ ] O diff contém somente alterações necessárias?

---

# Checklist para Stored Procedure ORMEMED

Antes de concluir:

- [ ] A procedure é realmente do padrão ORMEMED?
- [ ] GET utiliza `p_PREFIXO_GS_Tabela_Operacao`?
- [ ] Escrita utiliza `p_PREFIXO_DS_Tabela_Operacao`?
- [ ] O SQL é compatível com SQL Server 2000?
- [ ] A consulta retorna tabela?
- [ ] Não foi adicionado `FOR XML`?
- [ ] Os nomes e a ordem das colunas foram preservados?
- [ ] Os parâmetros correspondem aos `SqlParameter`?
- [ ] O `RETURN_VALUE` mantém a semântica esperada?
- [ ] O `GRANT ALL` foi incluído?
- [ ] O encoding foi preservado?
- [ ] O diff é mínimo?

---

# Checklist para alteração estrutural

- [ ] A tabela pertence ao Banco Global ou aos bancos individuais?
- [ ] A alteração é compatível com SQL Server 2000?
- [ ] Registros existentes foram considerados?
- [ ] A nulabilidade foi analisada?
- [ ] Procedures de insert foram atualizadas?
- [ ] Procedures de update foram atualizadas?
- [ ] Procedures de consulta foram atualizadas?
- [ ] Classes DS/GS foram revisadas?
- [ ] Business Services foram revisados?
- [ ] XSL foi revisado?
- [ ] DTOs e APIs foram revisados?
- [ ] O script pode ser aplicado a todos os clientes?
- [ ] Existe estratégia de reexecução?
- [ ] Existe risco de bloqueio ou demora?
- [ ] O rollback foi considerado?
- [ ] O script foi separado da alteração de código quando necessário?

---

# Ordem de precedência

Em caso de dúvida, utilizar esta ordem:

1. procedure equivalente consumida pela mesma classe;
2. procedures da mesma entidade;
3. procedures do mesmo componente;
4. Data Service consumidor;
5. XSL associado;
6. documentação específica do componente;
7. este documento;
8. conhecimento genérico de SQL.

O padrão comprovado no repositório prevalece sobre exemplos genéricos.

---

# Princípios fundamentais

1. Todo SQL deve ser compatível com SQL Server 2000.

2. COM+ e ORMEMED possuem padrões distintos e não devem ser misturados.

3. Procedures GET COM+ retornam XML com `FOR XML AUTO, ELEMENTS`, além de `RETURN`.

4. Procedures GET ORMEMED retornam tabela por `SELECT`, além de `RETURN`.

5. O padrão COM+ utiliza:

   ```text
   p_PREFIXO_DSTabela_Operacao
   ```

6. O padrão ORMEMED utiliza:

   ```text
   p_PREFIXO_GS_Tabela_Operacao
   p_PREFIXO_DS_Tabela_Operacao
   ```

7. Toda Stored Procedure deve terminar com:

   ```sql
   GRANT ALL ON p_NOME_DA_PROCEDURE TO GrpLEMED
   GO
   ```

8. O `RETURN_VALUE` faz parte do contrato.

9. Aliases e ordem de colunas podem fazer parte do contrato.

10. Procedure, Data Service e XSL devem permanecer compatíveis.

11. Alterações em bancos individuais devem considerar todos os clientes.

12. O menor diff possível é o resultado esperado.

13. A implementação existente é a principal fonte de verdade.

14. O agente deve adaptar-se ao padrão SQL do EMED, e não adaptar o EMED ao seu estilo.