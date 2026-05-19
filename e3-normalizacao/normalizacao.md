# Normalização — Academia DB
**Referência:** Elmasri & Navathe, Caps. 10–11, 7ª ed.

---

## Notação utilizada

- `X → Y` : X determina funcionalmente Y
- `{A, B} → C` : o conjunto {A, B} determina C
- **PK** : chave primária | **DFP** : dependência funcional parcial | **DFT** : dependência funcional transitiva
- Superchave: conjunto de atributos que determina todos os outros
- Chave candidata: superchave mínima (sem atributo redundante)

---

## Tabela 1 — `pessoa`

### Esquema
```
pessoa(cpf, primeiro_nome, nome, sobrenome, data_nascimento, email, papel)
```

### 1. Dependências funcionais identificadas

| # | Dependência | Tipo |
|---|-------------|------|
| DF1 | `cpf → primeiro_nome` | Trivial (PK → atributo) |
| DF2 | `cpf → nome` | Trivial (PK → atributo) |
| DF3 | `cpf → sobrenome` | Trivial (PK → atributo) |
| DF4 | `cpf → data_nascimento` | Trivial (PK → atributo) |
| DF5 | `cpf → email` | Trivial (PK → atributo) |
| DF6 | `cpf → papel` | Trivial (PK → atributo) |
| DF7 | `nome → primeiro_nome` | **Não trivial** — o nome completo contém o primeiro nome |
| DF8 | `nome → sobrenome` | **Não trivial** — o nome completo contém o sobrenome |

> **Observação sobre DF7 e DF8:** embora `nome` contenha `primeiro_nome` e `sobrenome`,
> essa dependência é **derivável por semântica de string**, não por regra relacional.
> Em modelagem relacional formal, tratamos `nome` como atributo atômico independente.
> As DFs DF7 e DF8 existem na realidade do domínio, mas são resolvidas pela decisão de
> design de armazenar os três campos separadamente para consultas flexíveis.
> Para fins de análise de FN, consideramos apenas as DFs relacionais:
> todas derivam da PK `cpf`.

### 2. Análise das formas normais

**1FN:**
A tabela está em **1FN**. Todos os atributos são atômicos (valores indivisíveis, domínios escalares) e há uma chave primária definida (`cpf`). Não há grupos repetitivos nem atributos multivalorados — os telefones foram corretamente separados para `funcionario_telefone`.

**2FN:**
A tabela está em **2FN**. A chave primária é simples (`cpf`, um único atributo), portanto é impossível existir dependência parcial — toda dependência parcial pressupõe uma PK composta. Por definição, qualquer relação em 1FN com PK simples está automaticamente em 2FN.

**3FN:**
A tabela está em **3FN**. Não existe nenhum atributo não-primo (fora da chave) que determine outro atributo não-primo, ou seja, não há dependência transitiva `cpf → X → Y` onde X não seja chave. Cada atributo depende direta e exclusivamente de `cpf`.

**BCNF:**
A tabela está em **BCNF**. Para cada DF não trivial `X → Y`, X é superchave da relação. A única superchave é `{cpf}`, e todas as DFs relevantes partem de `cpf`. Não há anomalia de BCNF.

### 3. Conclusão

`pessoa` está em **BCNF**. Nenhuma decomposição é necessária.

---

## Tabela 2 — `plano`

### Esquema
```
plano(id_plano, nome, valor_mensal, valor_total, duracao_meses, descricao, tipo, desconto_anual)
```

### 1. Dependências funcionais identificadas

| # | Dependência | Tipo |
|---|-------------|------|
| DF1 | `id_plano → nome` | PK → atributo |
| DF2 | `id_plano → valor_mensal` | PK → atributo |
| DF3 | `id_plano → valor_total` | PK → atributo |
| DF4 | `id_plano → duracao_meses` | PK → atributo |
| DF5 | `id_plano → descricao` | PK → atributo |
| DF6 | `id_plano → tipo` | PK → atributo |
| DF7 | `id_plano → desconto_anual` | PK → atributo (nullable) |
| DF8 | `{valor_mensal, duracao_meses} → valor_total` | **Dependência derivável** |
| DF9 | `tipo → desconto_anual` | **Dependência transitiva candidata** |

> **Análise de DF8:** `valor_total = valor_mensal × duracao_meses` é uma dependência
> funcional derivada (atributo calculável). Manter `valor_total` como atributo armazenado
> viola o princípio de eliminar redundância — qualquer atualização em `valor_mensal` exige
> atualização em `valor_total` para manter consistência.
> **Decisão de design:** remover `valor_total` como atributo e calculá-lo via VIEW ou
> coluna gerada (`GENERATED ALWAYS AS (valor_mensal * duracao_meses) STORED`).

> **Análise de DF9:** `tipo → desconto_anual` indica que o desconto é determinado
> pelo tipo do plano, não pelo plano individual. Isso caracteriza uma dependência
> transitiva: `id_plano → tipo → desconto_anual`.

### 2. Análise das formas normais

**1FN:**
A tabela está em **1FN**. Todos os atributos são atômicos e há PK definida.

**2FN:**
A tabela está em **2FN**. PK simples (`id_plano`), impossibilitando dependências parciais.

**3FN — violação identificada:**
A tabela **viola a 3FN** por causa de DF9.

Formalmente: existe a cadeia `id_plano → tipo → desconto_anual`, onde `tipo` não é chave candidata e `desconto_anual` não é primo (não faz parte de nenhuma chave candidata). Isso é exatamente a definição de dependência transitiva que a 3FN proíbe.

Além disso, a DF8 introduz redundância derivável, que também deve ser eliminada.

**BCNF:**
Pela mesma razão da violação de 3FN, a tabela também **viola BCNF**: na DF `tipo → desconto_anual`, o determinante `tipo` não é superchave de `plano`.

### 3. Decomposição para 3FN / BCNF

**Esquema normalizado:**

```
tipo_plano(tipo, desconto_percentual)
    PK: tipo
    DF: tipo → desconto_percentual

plano(id_plano, nome, valor_mensal, duracao_meses, descricao, tipo)
    PK: id_plano
    FK: tipo → tipo_plano(tipo)
    Atributo derivado eliminado: valor_total calculado como VIEW ou coluna gerada
```

**Dependências funcionais após decomposição:**

Em `tipo_plano`:
- `tipo → desconto_percentual` — tipo é PK, portanto BCNF satisfeita.

Em `plano`:
- Todas as DFs partem de `id_plano` (PK). Sem transitividades. BCNF satisfeita.

**Verificação das propriedades da decomposição:**
- **Sem perda de informação (lossless join):** a decomposição usa `tipo` como atributo comum; o join natural `plano ⋈ tipo_plano` reconstrói a relação original sem tuplas espúrias.
- **Preservação de dependências:** DF8 (`tipo → desconto_percentual`) é preservada em `tipo_plano`; todas as demais DFs são preservadas em `plano`.

### 4. Trade-off BCNF × performance

A extração de `tipo_plano` introduz um JOIN adicional em toda consulta que precise do desconto. Para um sistema de academia, onde `tipo_plano` terá no máximo 3–5 registros (MENSAL, TRIMESTRAL, ANUAL), o custo do JOIN é negligenciável — o otimizador de consultas do PostgreSQL fará um nested loop com hash na memória. O ganho em integridade (impossível ter dois descontos diferentes para o mesmo tipo) supera amplamente esse custo.

---

## Tabela 3 — `registro_frequencia`

### Esquema
```
registro_frequencia(id_registro, cpf_aluno, data_hora, tipo_acesso, id_aula, observacao)
```

### 1. Dependências funcionais identificadas

| # | Dependência | Tipo |
|---|-------------|------|
| DF1 | `id_registro → cpf_aluno` | PK → atributo |
| DF2 | `id_registro → data_hora` | PK → atributo |
| DF3 | `id_registro → tipo_acesso` | PK → atributo |
| DF4 | `id_registro → id_aula` | PK → atributo (nullable) |
| DF5 | `id_registro → observacao` | PK → atributo |
| DF6 | `{cpf_aluno, data_hora} → id_registro` | Chave candidata alternativa |
| DF7 | `id_aula → tipo_acesso` | **Dependência transitiva candidata** |

> **Análise de DF6:** o modelo define `UNIQUE(cpf_aluno, data_hora)`, o que faz
> `{cpf_aluno, data_hora}` ser uma **chave candidata** da relação. A relação possui
> portanto duas chaves candidatas: `{id_registro}` e `{cpf_aluno, data_hora}`.

> **Análise de DF7:** quando `id_aula IS NOT NULL`, o valor de `tipo_acesso` é
> necessariamente 'AULA' — ou seja, `id_aula` determina `tipo_acesso`. Isso cria a
> cadeia `id_registro → id_aula → tipo_acesso`.

### 2. Análise das formas normais

**1FN:**
A tabela está em **1FN**. Atributos atômicos, PK definida, sem grupos repetitivos.

**2FN:**
A tabela está em **2FN**. Analisando pela chave candidata `{cpf_aluno, data_hora}`:
todos os outros atributos dependem do conjunto completo, não de parte dele.
- `cpf_aluno` sozinho não determina `data_hora`, `tipo_acesso` ou `id_aula`.
- `data_hora` sozinha não determina `cpf_aluno` ou `tipo_acesso`.

Não há dependência parcial em nenhuma das chaves candidatas.

**3FN — análise de DF7:**
Existe a cadeia `id_registro → id_aula → tipo_acesso`.

Contudo, a situação exige análise cuidadosa: `id_aula` é nullable. Quando `id_aula IS NULL` (acesso livre), a dependência `id_aula → tipo_acesso` não se aplica — `tipo_acesso = 'LIVRE'` é determinado diretamente por `id_registro`.

**Quando `id_aula IS NOT NULL`:** a DF7 existe e cria uma transitividade. `tipo_acesso` poderia ser derivado de `id_aula`, tornando-o redundante para registros do tipo AULA.

Em sentido estrito formal, a tabela **viola a 3FN** para o subconjunto de tuplas onde `id_aula IS NOT NULL`, pois `tipo_acesso` é determinado transitivamente via `id_aula`.

**BCNF:**
A tabela **viola BCNF**: na DF `id_aula → tipo_acesso`, `id_aula` não é superchave de `registro_frequencia`.

### 3. Decomposição e trade-off

**Decomposição estrita (BCNF):**
```
registro_frequencia(id_registro, cpf_aluno, data_hora, tipo_acesso, observacao)
registro_aula(id_registro, id_aula)
    FK: id_aula → aula_coletiva(id_aula)
```

Neste esquema, `tipo_acesso` seria derivado: se existe registro em `registro_aula`, o tipo é 'AULA'; caso contrário, é 'LIVRE'.

**Trade-off explícito:**

| Critério | Manter `tipo_acesso` em `registro_frequencia` | Decompor (BCNF estrita) |
|---|---|---|
| Redundância | Mínima (1 campo, valor controlado por CHECK) | Nenhuma |
| Integridade | Garantida por `CHECK` + FK | Garantida estruturalmente |
| Performance de leitura | Uma tabela, sem JOIN | Requer JOIN para saber o tipo |
| Clareza semântica | Alta — tipo visível diretamente | Baixa — tipo inferido pela existência de FK |

**Decisão justificada:** manter `tipo_acesso` como atributo explícito com a constraint
`CHECK((tipo_acesso = 'AULA' AND id_aula IS NOT NULL) OR (tipo_acesso = 'LIVRE' AND id_aula IS NULL))`
é uma **desnormalização controlada e intencional**. A redundância é mínima (um único campo
de 5–5 bytes), completamente controlada por constraint declarativa, e a clareza semântica e
performance de consulta justificam a não-decomposição. Essa é uma situação clássica do
trade-off BCNF × performance descrito em Elmasri & Navathe (Cap. 11, Seção 11.4).

---

## Resumo comparativo

| Tabela | 1FN | 2FN | 3FN | BCNF | Ação |
|--------|-----|-----|-----|------|------|
| `pessoa` | ✓ | ✓ | ✓ | ✓ | Nenhuma |
| `plano` | ✓ | ✓ | ✗ | ✗ | Extrair `tipo_plano`; remover `valor_total` como coluna gerada |
| `registro_frequencia` | ✓ | ✓ | ✗* | ✗ | Desnormalização controlada justificada por trade-off |

*Violação restrita ao subconjunto de tuplas com `id_aula IS NOT NULL`.
