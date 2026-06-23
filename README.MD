# 🏋️ Academia DB

> **Trabalho de Banco de Dados** — Modelagem, normalização e implementação de um sistema de gerenciamento de academias.

---

## 📋 Sumário

- [Sobre o Projeto](#sobre-o-projeto)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Etapas do Trabalho](#etapas-do-trabalho)
  - [E1 — Modelo Conceitual (DER)](#e1--modelo-conceitual-der)
  - [E2 — Modelo Lógico Relacional](#e2--modelo-lógico-relacional)
  - [E3 — Normalização](#e3--normalização)
  - [E4 — Implementação SQL](#e4--implementação-sql)
- [Principais Decisões de Modelagem](#principais-decisões-de-modelagem)
- [Como Executar](#como-executar)
- [Tecnologias](#tecnologias)

---

## Sobre o Projeto

Este repositório documenta o desenvolvimento completo de um banco de dados relacional para um **sistema de gerenciamento de academias**, cobrindo desde a modelagem conceitual até a implementação em SQL.

O sistema contempla:

- Cadastro unificado de **pessoas** (alunos e funcionários)
- Gerenciamento de **planos**, **contratos** e **matrículas**
- Controle de **equipamentos** e histórico de **manutenções**
- Registro de **frequência** — acesso livre e aulas coletivas
- **Avaliações** de academia e de aulas coletivas por critério

---

## Estrutura do Repositório

```
BD/
├── e1-der/
│   └── README.MD                  # Descrição do modelo conceitual (DER)
│
├── e2-logico/
│   ├── Modelo Logico.pdf          # Diagrama do modelo lógico relacional
│   └── esquema_relacional.md      # Esquema em notação relacional com justificativas
│
├── e3-normalizacao/
│   └── normalizacao.md            # Análise formal de 1FN, 2FN, 3FN e BCNF
│
├── e4-sql/
│   ├── academia_ddl.sql           # DDL — PostgreSQL (versão principal)
│   └── academia.sql               # DDL — MySQL (versão alternativa)
│
└── README.MD                      # Este arquivo
```

---

## Etapas do Trabalho

### E1 — Modelo Conceitual (DER)

Diagrama Entidade-Relacionamento desenvolvido com notação padrão. Identificação de entidades, atributos e relacionamentos do domínio de academias.

**Entidades principais identificadas:** Pessoa, Aluno, Funcionário, Instrutor, Academia, Plano, Equipamento, Manutenção, Aula Coletiva, Registro de Frequência, Avaliação.

---

### E2 — Modelo Lógico Relacional

Transformação do DER em esquema relacional, com mapeamento de entidades, especializações e relacionamentos.

**Arquivo:** [`e2-logico/esquema_relacional.md`](e2-logico/esquema_relacional.md)

Destaques do modelo lógico:

| Tabela | Descrição |
|---|---|
| `pessoa` | Cadastro unificado de alunos e funcionários (discriminador `papel`) |
| `plano` + `tipo_plano` | Planos com subtipo extraído após normalização |
| `equipamento` | Equipamentos de musculação e cardio em tabela única |
| `registro_frequencia` | Acesso livre e aulas coletivas consolidados |
| `avaliacao` | Avaliações de academia e de aulas com critérios |

---

### E3 — Normalização

Análise formal das formas normais (1FN, 2FN, 3FN e BCNF) com base em **Elmasri & Navathe, Caps. 10–11, 7ª ed.**

**Arquivo:** [`e3-normalizacao/normalizacao.md`](e3-normalizacao/normalizacao.md)

**Resumo dos resultados:**

| Tabela | 1FN | 2FN | 3FN | BCNF | Ação tomada |
|---|:---:|:---:|:---:|:---:|---|
| `pessoa` | ✅ | ✅ | ✅ | ✅ | Nenhuma |
| `plano` | ✅ | ✅ | ❌ | ❌ | Extraída `tipo_plano`; `valor_total` removido como coluna gerada |
| `registro_frequencia` | ✅ | ✅ | ❌* | ❌ | Desnormalização controlada justificada por trade-off de performance |

> \* Violação restrita ao subconjunto de tuplas com `id_aula IS NOT NULL`.

**Principais dependências analisadas:**

- `plano`: cadeia transitiva `id_plano → tipo → desconto_anual` → violação de 3FN → extração de `tipo_plano`
- `plano`: atributo derivável `valor_total = valor_mensal × duracao_meses` → removido como coluna gerada
- `registro_frequencia`: `id_aula → tipo_acesso` → desnormalização aceita com `CHECK` constraint bidirecional

---

### E4 — Implementação SQL

DDL completo implementado em duas variações de SGBD.

**Arquivos:**
- [`e4-sql/academia_ddl.sql`](e4-sql/academia_ddl.sql) — PostgreSQL *(versão principal)*
- [`e4-sql/academia.sql`](e4-sql/academia.sql) — MySQL *(versão alternativa)*

**Características da implementação:**

- Scripts **idempotentes** — `DROP TABLE IF EXISTS ... CASCADE` antes da criação
- Todas as tabelas com `COMMENT ON` (PostgreSQL) documentando colunas e propósitos
- `CHECK` constraints declarativas para integridade de subtipos (sem necessidade de triggers)
- Chaves substitutas geradas automaticamente (`GENERATED ALWAYS AS IDENTITY` no PostgreSQL / `AUTO_INCREMENT` no MySQL)
- Chave candidata alternativa em `registro_frequencia`: `UNIQUE(cpf_aluno, data_hora)`

---

## Principais Decisões de Modelagem

### Unificação de `aluno` e `funcionario` em `pessoa`
As tabelas originais continham apenas a PK herdada, sem atributos próprios — um padrão de especialização vazio. A unificação com o discriminador `papel` (`ALUNO | FUNCIONARIO | AMBOS`) elimina JOINs desnecessários e cobre o caso real em que um funcionário também é aluno.

### Eliminação dos subtipos de `plano`
`plano_mensal`, `plano_trim` e `plano_anual` eram subtipos sem massa crítica de atributos. O campo `tipo` já presente em `plano` os tornava redundantes. Após a análise de normalização, a dependência transitiva `tipo → desconto_anual` motivou a extração de `tipo_plano`.

### Remoção de `valor_total` como atributo armazenado
`valor_total = valor_mensal × duracao_meses` é um atributo derivado. Armazená-lo cria risco de inconsistência. O valor é obtido via expressão na consulta ou coluna gerada (`GENERATED ALWAYS AS`).

### Consolidação de `acesso_livre` e `acesso_aula`
`acesso_livre` era uma tabela com uma única coluna (PK e FK). A consolidação em `registro_frequencia` com `tipo_acesso` e `id_aula` nullable elimina dois JOINs em toda consulta de frequência, com integridade garantida por `CHECK` constraint bidirecional.

### Consolidação de `avaliacao_academia` e `avaliacao_aula`
Mesmo padrão: subtipos 1:1 sem atributos suficientes para justificar tabelas separadas. Absorvidos em `avaliacao` com campos nullable e `CHECK` constraints.

### Consolidação de `equip_musculacao` e `equip_cardio`
Cada subtabela possuía exatamente um atributo específico. O campo `categoria` discrimina os casos; `CHECK` constraints garantem que cada atributo condicional só seja preenchido no contexto correto.

---

## Como Executar

### PostgreSQL

```bash
psql -U <usuario> -d <banco> -f e4-sql/academia_ddl.sql
```

### MySQL

```bash
mysql -u <usuario> -p <banco> < e4-sql/academia.sql
```

> O script PostgreSQL é idempotente — pode ser executado múltiplas vezes sem erros.

---

## Tecnologias

- **PostgreSQL 15+** — SGBD principal
- **MySQL 8+** — SGBD alternativo
- **BRModelo / draw.io** — Modelagem conceitual e lógica
- **Markdown** — Documentação

---

*Disciplina de Banco de Dados*