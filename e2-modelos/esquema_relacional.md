# Esquema Relacional — Academia DB

---

## Notação

- Atributos sublinhados simples: **chave primária**
- Atributos em itálico: *chave estrangeira*
- `[NN]` : NOT NULL | `[U]` : UNIQUE | `[CK]` : CHECK constraint

---

## 1. Pessoas

**pessoa**(<u>cpf</u>, primeiro_nome [NN], nome [NN], sobrenome [NN], data_nascimento [NN], email, papel [NN, CK: 'ALUNO'|'FUNCIONARIO'|'AMBOS'])

**funcionario_telefone**(<u>*cpf*</u>, <u>telefone</u> [NN])
- *cpf* → pessoa(cpf)

**instrutor**(<u>*cpf*</u>, qtd_parcelas, especialidade)
- *cpf* → pessoa(cpf)

---

## 2. Academia, Planos, Contratos e Matrículas

**academia**(<u>id_academia</u>, nome [NN], endereco [NN])

**tipo_plano**(<u>tipo</u>, desconto_percentual)
- tipo [CK: 'MENSAL'|'TRIMESTRAL'|'ANUAL']
- *Extraído de `plano` na normalização para 3FN: eliminava a dependência transitiva `id_plano → tipo → desconto_anual`*

**plano**(<u>id_plano</u>, nome [NN], valor_mensal [NN], duracao_meses [NN], descricao, *tipo* [NN])
- *tipo* → tipo_plano(tipo)
- valor_total removido: atributo derivável por `valor_mensal × duracao_meses`

**contrato**(<u>id_contrato</u>, *id_academia* [NN], *id_plano* [NN])
- *id_academia* → academia(id_academia)
- *id_plano* → plano(id_plano)

**matricula**(<u>id_matricula</u>, *cpf_aluno* [NN], *id_academia* [NN], *id_plano* [NN])
- *cpf_aluno* → pessoa(cpf)   [CK: papel IN ('ALUNO','AMBOS')]
- *id_academia* → academia(id_academia)
- *id_plano* → plano(id_plano)

---

## 3. Equipamentos e Manutenção

**equipamento**(<u>id_equipamento</u>, *id_academia* [NN], nome [NN], marca, status, data_aquisicao, peso_maximo, categoria [NN, CK: 'MUSCULACAO'|'CARDIO'], velocidade_max, tipo_resistencia)
- *id_academia* → academia(id_academia)
- velocidade_max: preenchido somente se categoria = 'MUSCULACAO'
- tipo_resistencia: preenchido somente se categoria = 'CARDIO'

**manutencao**(<u>id_manutencao</u>, *id_equipamento* [NN], tipo, descricao, custo, data)
- *id_equipamento* → equipamento(id_equipamento)

---

## 4. Frequência e Acessos

**aula_coletiva**(<u>id_aula</u>, *cpf_instrutor* [NN])
- *cpf_instrutor* → instrutor(cpf)

**registro_frequencia**(<u>id_registro</u>, *cpf_aluno* [NN], data_hora [NN], tipo_acesso [NN, CK: 'LIVRE'|'AULA'], *id_aula*, observacao)
- *cpf_aluno* → pessoa(cpf)
- *id_aula* → aula_coletiva(id_aula)
- [U]: (cpf_aluno, data_hora)
- [CK]: tipo_acesso='AULA' ↔ id_aula IS NOT NULL

**utiliza**(<u>*id_registro*</u>, <u>*id_equipamento*</u>)
- *id_registro* → registro_frequencia(id_registro)
- *id_equipamento* → equipamento(id_equipamento)

---

## 5. Avaliações

**avaliacao**(<u>id_avaliacao</u>, *cpf_aluno* [NN], *cpf_funcionario*, data_hora [NN], observacao, tipo [NN, CK: 'ACADEMIA'|'AULA'], *id_academia*, nota_academia, *id_aula*)
- *cpf_aluno* → pessoa(cpf)
- *cpf_funcionario* → pessoa(cpf)
- *id_academia* → academia(id_academia)
- *id_aula* → aula_coletiva(id_aula)
- [CK]: tipo='ACADEMIA' ↔ id_academia IS NOT NULL
- [CK]: tipo='AULA' ↔ id_aula IS NOT NULL
- [CK]: nota_academia BETWEEN 0 AND 10 (quando não nulo)

**criterio**(<u>id_criterio</u>, nome [NN], descricao)

**item_avaliado**(<u>*id_avaliacao*</u>, <u>*id_criterio*</u>, nota [NN, CK: 0..10])
- *id_avaliacao* → avaliacao(id_avaliacao)
- *id_criterio* → criterio(id_criterio)

---

## Justificativa das decisões de modelagem

### J1 — Unificação de `aluno` e `funcionario` em `pessoa`

O modelo original possuía duas tabelas (`aluno`, `funcionario`) que continham exclusivamente a PK herdada de `pessoa`, sem nenhum atributo próprio. Tabelas com apenas uma coluna que é simultaneamente PK e FK são um padrão de especialização vazio: não acrescentam restrição nem dado — apenas adicionam um JOIN obrigatório em toda consulta.

A solução adotada foi incluir o atributo discriminador `papel` diretamente em `pessoa`, com domínio controlado por CHECK constraint. O valor 'AMBOS' contempla o caso real em que um funcionário também é aluno da academia. As tabelas derivadas que antes apontavam para `aluno` ou `funcionario` passam a referenciar `pessoa` diretamente, com a semântica do papel verificável via constraint ou regra de aplicação.

### J2 — Eliminação de `plano_mensal`, `plano_trim` e `plano_anual`

As três tabelas eram subtipos de `plano` sem atributos próprios, exceto `desconto_anual` em `plano_anual`. O campo `tipo` já presente em `plano` tornava as três tabelas completamente redundantes como estrutura de discriminação.

O atributo `desconto_anual` foi inicialmente absorvido como nullable em `plano`. Porém, a análise de normalização (Etapa 3) identificou a dependência transitiva `id_plano → tipo → desconto_anual`, violando a 3FN. A solução correta foi extrair a tabela `tipo_plano(tipo, desconto_percentual)`, eliminando tanto as subtabelas originais quanto a transitividade.

### J3 — Remoção de `valor_total` de `plano`

`valor_total` é funcionalmente determinado por `valor_mensal` e `duracao_meses` pela regra `valor_total = valor_mensal × duracao_meses`. Armazenar um atributo calculável cria redundância e risco de inconsistência: uma atualização em `valor_mensal` que não atualize `valor_total` produz dados contraditórios. O atributo foi removido; seu valor é obtido via expressão na consulta ou coluna gerada no banco.

### J4 — Eliminação de `acesso_livre` e `acesso_aula`

`acesso_livre` era uma tabela com uma única coluna (`id_registro`, PK e FK), sem nenhum atributo próprio — estruturalmente equivalente a um conjunto de IDs válidos. `acesso_aula` acrescentava apenas `id_aula`.

A consolidação em `registro_frequencia` com o campo `tipo_acesso` e `id_aula` nullable elimina dois JOINs em toda consulta de frequência. A integridade da discriminação é mantida pela CHECK constraint bidirecional: `tipo_acesso = 'AULA'` exige `id_aula NOT NULL`, e `tipo_acesso = 'LIVRE'` exige `id_aula IS NULL`. A análise de normalização (Etapa 3) identificou que isso introduz uma desnormalização controlada de BCNF, aceita pelo trade-off de clareza semântica e performance — conforme discussão formal no documento de normalização.

### J5 — Eliminação de `avaliacao_academia` e `avaliacao_aula`

Mesmo padrão de J4: subtipos 1:1 sem massa crítica de atributos para justificar tabelas separadas. `avaliacao_academia` acrescentava `id_academia` e `nota`; `avaliacao_aula` acrescentava `id_aula`. Ambos foram absorvidos em `avaliacao` como campos nullable com CHECK constraints que garantem consistência por tipo.

### J6 — Consolidação de `equip_musculacao` e `equip_cardio`

Cada subtabela possuía exatamente um atributo específico (`velocidade_max` e `tipo_resistencia`). A relação custo/benefício da separação — um JOIN extra em toda consulta de equipamento para obter um único campo — não se sustenta. O campo `categoria` em `equipamento` discrimina os casos; as CHECK constraints garantem que cada atributo condicional só seja preenchido no contexto correto.

### J7 — Chave candidata em `registro_frequencia`

O par `(cpf_aluno, data_hora)` possui constraint UNIQUE, tornando-o uma chave candidata alternativa à PK surrogada `id_registro`. Isso reflete a regra de negócio de que um aluno não pode ter dois registros no mesmo instante, e permite consultas de frequência por período sem necessitar da PK surrogada.
