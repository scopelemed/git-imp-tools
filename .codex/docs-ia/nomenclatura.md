# Nomenclatura e Convenções de Nomes — Ecossistema EMED

# Objetivo

Este documento define as convenções de nomenclatura utilizadas no ecossistema EMED.

Seu objetivo é garantir que novas implementações mantenham consistência com a arquitetura existente, preservando compatibilidade com:

- COM+ (VB6)
- ASP Classic
- ASP.NET WebForms
- ORMEMED
- API EMED
- React
- SQL Server
- XML
- XSL
- Banco Global
- Bancos Individuais

A nomenclatura existente no repositório sempre possui prioridade sobre sugestões genéricas.

---

# Princípio Geral

Nunca criar nomes baseados apenas em preferência pessoal.

Antes de criar qualquer artefato, pesquisar:

- arquivos equivalentes;
- classes equivalentes;
- procedures equivalentes;
- métodos equivalentes;
- XML equivalente.

Sempre copiar o padrão predominante.

---

# Convenções Gerais

O ecossistema utiliza predominantemente:

```text
snake_case
```

para:

- banco de dados
- XML
- parâmetros SQL
- atributos XML

E utiliza:

```text
PascalCase
```

para:

- classes C#
- métodos públicos
- propriedades C#

E utiliza:

```text
camelCase
```

somente quando o projeto já seguir esse padrão.

Nunca converter automaticamente um padrão para outro.

---

# Prefixos dos Componentes

Cada domínio do sistema possui um prefixo.

Exemplos:

```text
LEMED
LEMED_CAD
LEFIN
LNUC
LINT
LMCR
LMTR
GEMED
```

Esses prefixos aparecem em:

- componentes COM+
- Stored Procedures
- tabelas
- arquivos XSL
- namespaces
- projetos

Nunca inventar novos prefixos.

---

# Tabelas

O padrão predominante é:

```text
PREFIXO_Entidade
```

Exemplos:

```text
LEMED_Agendamento
LEMED_Paciente
LEFIN_MovFinanceira
LNUC_Feriado
```

Não utilizar:

```text
tblPaciente
tbPaciente
PacienteTbl
```

---

# Colunas

O padrão predominante utiliza nomes descritivos.

Exemplos:

```text
cd_paciente
cd_medico
cd_empresa
cd_agendamento

nome_paciente
descr_procedimento
data_agendamento

flag_ativo
flag_cancelado
flag_excluido
```

---

# Prefixos comuns

## cd_

Código

```text
cd_paciente
cd_empresa
cd_medico
```

---

## descr_

Descrição

```text
descr_convenio
descr_procedimento
```

---

## nome_

Nome

```text
nome_paciente
nome_usuario
```

---

## data_

Datas

```text
data_atendimento
data_emissao
```

---

## hora_

Horas

```text
hora_inicial
hora_final
```

---

## flag_

Campos booleanos

```text
flag_ativo
flag_padrao
flag_cancelado
```

Normalmente armazenam:

```text
S
N
```

ou

```text
0
1
```

conforme o padrão existente.

---

## qt_

Quantidade

```text
qt_parcelas
qt_sessoes
```

---

## vl_

Valores

```text
vl_total
vl_desconto
vl_pago
```

---

## perc_

Percentuais

```text
perc_desconto
perc_repasse
```

---

# Stored Procedures

Existem dois padrões.

---

## COM+

```text
p_PREFIXO_DSTabela_Operacao
```

Exemplos

```text
p_LNUC_DSFeriado_GetLista
p_LNUC_DSFeriado_Insert
p_LNUC_DSFeriado_Update
p_LNUC_DSFeriado_Delete
```

---

## ORMEMED

Consultas

```text
p_PREFIXO_GS_Tabela_Operacao
```

Exemplo

```text
p_LEMED_GS_Agendamento_GetLista
```

Escritas

```text
p_PREFIXO_DS_Tabela_Operacao
```

Exemplo

```text
p_LEMED_DS_Agendamento_Insert
```

Nunca misturar os padrões.

---

# Business Services VB6

O padrão é:

```text
BSNomeEntidade
```

Exemplos

```text
BSPaciente
BSAgenda
BSRequisicao
BSFinanceiro
```

Métodos

```text
GetListaPacientes
AtualizaPaciente
DeletePaciente
InsertPaciente
```

ou

```text
GeraPedido
FechaPedido
ValidaAgenda
```

Sempre copiar o padrão existente.

---

# Data Services VB6

O padrão é:

```text
DSNomeEntidade
```

Exemplos

```text
DSPaciente
DSAgenda
DSFeriado
DSMovFinanceira
```

---

# Classes C#

Business Services

```text
AgendaBusiness
PacienteBusiness
```

ou

```text
BSAgenda
```

conforme o projeto.

Nunca misturar estilos.

---

# Métodos

Utilizar verbos.

Exemplos

```text
GetLista()

Insert()

Update()

Delete()

Valida()

Calcula()

Fecha()

Gera()

Importa()

Exporta()

Sincroniza()
```

Evitar nomes genéricos.

Ruim

```text
Processa()
Executa()
Metodo()
```

---

# Variáveis VB6

Objetos

```vb
objXML
objConn
objCmd
objBS
objDS
objPaciente
```

Strings

```vb
strXML
strNome
strDescricao
```

Long

```vb
lngCodigo
lngPaciente
```

Integer

```vb
intIndice
```

Boolean

```vb
blnValido
```

Variant

```vb
vValor
```

Arrays

```vb
arrItens
```

Coleções

```vb
colItens
```

---

# Variáveis C#

O padrão depende do projeto.

Em projetos ORMEMED normalmente:

```csharp
paciente

agenda

sqlCommand

dataTable
```

ou

```text
camelCase
```

Não alterar o padrão do projeto.

---

# XML

Elementos utilizam snake_case.

Exemplo

```xml
<cd_paciente>

<data_atendimento>

<nome_paciente>

<flag_cancelado>
```

Nunca utilizar

```xml
<IdPaciente>

<PacienteId>

<DataAtendimento>
```

quando o contrato existente utiliza snake_case.

---

# Arquivos XSL

O padrão normalmente é:

```text
COMPONENTE.Classe.Metodo.xsl
```

Exemplo

```text
LNUC.DSFeriado.GetLista.xsl
```

Nunca alterar esse padrão.

---

# Arquivos ASP

Normalmente:

```text
agenda.asp

agenda-editar.asp

agenda-lista.asp

pedido-particular.asp
```

Utilizar letras minúsculas.

Separação por hífen.

---

# Classes

VB6

```text
BSAgenda

DSAgenda
```

C#

```text
AgendaBusiness

AgendaDataService
```

ou

```text
BSAgenda

DSAgenda
```

conforme o projeto.

---

# Métodos GET

Preferir

```text
Get

GetLista

GetById

GetResumo
```

Nunca criar

```text
BuscarTudoMesmo
```

ou nomes semelhantes.

---

# Métodos de Escrita

Preferir

```text
Insert

Update

Delete

Save
```

quando esse for o padrão.

---

# XML Root

Normalmente

```text
Retorno
```

ou outro padrão existente.

Nunca inventar novo nome.

---

# Aliases SQL

Devem permanecer curtos.

```sql
p

a

m

f

c
```

Não utilizar aliases excessivamente longos.

---

# Tabelas Temporárias

```text
#Itens

#Resultado

#Movimentos
```

---

# Parâmetros SQL

Sempre utilizar o mesmo nome da coluna.

Correto

```sql
@cd_paciente

@nome_paciente
```

Ruim

```sql
@id

@nome
```

---

# DTOs

Quando o projeto utilizar PascalCase.

```csharp
CodigoPaciente

NomePaciente

DataAtendimento
```

Quando utilizar snake_case.

Respeitar o padrão existente.

---

# Endpoints

Utilizar substantivos.

```text
/api/paciente

/api/agenda

/api/financeiro
```

Evitar verbos na URL.

---

# Constantes

Seguir o padrão existente.

Não criar um padrão novo.

---

# Enumerações

Utilizar nomes descritivos.

```text
TipoMovimento

StatusAgenda
```

---

# Flags

Sempre iniciar por

```text
flag_
```

Exemplos

```text
flag_ativo

flag_cancelado

flag_geral
```

---

# Datas

Sempre iniciar por

```text
data_
```

Nunca

```text
dt
```

se o projeto utilizar

```text
data_
```

Copiar o padrão predominante.

---

# Evitar Abreviações Novas

Correto

```text
descr_procedimento

nome_paciente
```

Ruim

```text
dscProc

nmPac
```

---

# Acrônimos

Preservar os já existentes.

Exemplos

```text
XML

XSL

COM

API

CPF

CNPJ

IBS

CBS

TISS

NFSe
```

---

# Banco Global

Campos normalmente iniciam por

```text
global_
```

Exemplo

```text
global_cd_empresa_conta_emed
```

Nunca remover esse prefixo.

---

# Banco Individual

Não utilizar prefixo

```text
global_
```

---

# Arquivos

Não alterar nomes existentes.

Mesmo que pareçam antigos.

---

# Comentários

Descrever

- motivo

e não

- sintaxe.

---

# Antipadrões

Nunca criar nomes como

```text
TabelaNova

ClasseNova

Teste1

MetodoNovo

ProcessaTudo

Atualiza2

TabelaAux

MinhaClasse

MeuMetodo
```

Também evitar

```text
tmp

x

y

z

obj1

obj2
```

quando houver nome significativo.

---

# Checklist

Antes de criar um novo nome verificar

- [ ] Existe equivalente?
- [ ] O componente utiliza esse padrão?
- [ ] A nomenclatura segue o domínio?
- [ ] O prefixo está correto?
- [ ] O nome é consistente com o restante do projeto?
- [ ] Não existe quebra de padrão?
- [ ] O nome facilita manutenção futura?

---

# Princípios Fundamentais

1. A nomenclatura deve seguir o padrão do componente.

2. Nunca misturar padrões COM+ e ORMEMED.

3. Não modernizar nomes existentes.

4. Não renomear contratos públicos.

5. XML, SQL e banco utilizam predominantemente **snake_case**.

6. Classes C# utilizam o padrão do projeto.

7. Sempre pesquisar implementações equivalentes antes de criar novos nomes.

8. A consistência do ecossistema é mais importante do que preferência individual.

9. A implementação existente é a principal fonte de verdade.