# Dicionário de Dados — Academia DB

**SGBD:** PostgreSQL  
**Esquema:** público (public)  
**Versão do esquema:** pós-normalização (E3) — inclui `tipo_plano`, remove `valor_total` de `plano`

---

## Sumário de Tabelas

| Tabela | Descrição resumida |
|--------|--------------------|
| `pessoa` | Cadastro unificado de alunos e funcionários |
| `funcionario_telefone` | Telefones multivalorados de funcionários |
| `instrutor` | Especialização de funcionário que ministra aulas |
| `academia` | Unidades físicas da rede |
| `tipo_plano` | Categorias de plano com seus descontos |
| `plano` | Planos de assinatura disponíveis |
| `contrato` | Vínculo entre academias e planos ofertados |
| `matricula` | Matrículas de alunos em unidades/planos |
| `equipamento` | Equipamentos de cada unidade |
| `manutencao` | Histórico de manutenções de equipamentos |
| `aula_coletiva` | Aulas coletivas ministradas por instrutores |
| `registro_frequencia` | Acessos de alunos à academia |
| `utiliza` | Equipamentos usados em cada acesso livre |
| `avaliacao` | Avaliações de alunos sobre academia ou aulas |
| `criterio` | Critérios de avaliação de aulas coletivas |
| `item_avaliado` | Notas por critério dentro de uma avaliação |

---

## 1. Tabela `pessoa`

**Descrição:** Cadastro unificado de todas as pessoas do sistema. Substitui as tabelas `aluno` e `funcionario` do modelo original, utilizando o atributo discriminador `papel` com CHECK constraint. O valor `AMBOS` cobre o caso real em que um funcionário também é aluno da academia.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `cpf` | `INT` | PK, NOT NULL | CPF do indivíduo — identificador único e chave primária. |
| `primeiro_nome` | `VARCHAR(50)` | NOT NULL | Primeiro nome da pessoa. |
| `nome` | `VARCHAR(100)` | NOT NULL | Nome completo da pessoa. |
| `sobrenome` | `VARCHAR(50)` | NOT NULL | Último sobrenome da pessoa. |
| `data_nascimento` | `DATE` | NOT NULL | Data de nascimento. |
| `email` | `VARCHAR(100)` | — | Endereço de e-mail de contato (opcional). |
| `papel` | `VARCHAR(20)` | NOT NULL, CHECK IN ('ALUNO','FUNCIONARIO','AMBOS') | Papel da pessoa no sistema. |

---

## 2. Tabela `funcionario_telefone`

**Descrição:** Armazena os telefones de contato dos funcionários como relação separada, modelando corretamente o atributo multivalorado. PK composta por `(cpf, telefone)` impede duplicatas.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `cpf` | `INT` | PK (parte), FK → `pessoa(cpf)`, NOT NULL | CPF do funcionário — deve ter papel FUNCIONARIO ou AMBOS. |
| `telefone` | `VARCHAR(20)` | PK (parte), NOT NULL | Número de telefone do funcionário. |

---

## 3. Tabela `instrutor`

**Descrição:** Especialização de `pessoa` que representa funcionários habilitados a ministrar aulas coletivas. Herda dados pessoais via FK para `pessoa`. A PK é o próprio CPF, configurando herança por referência (1:1).

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `cpf` | `INT` | PK, FK → `pessoa(cpf)`, NOT NULL | CPF do instrutor — herda dados de `pessoa`. |
| `qtd_parcelas` | `INT` | — | Quantidade de parcelas do contrato do instrutor (opcional). |
| `especialidade` | `VARCHAR(100)` | — | Área de especialidade (ex.: musculação, spinning, yoga). |

---

## 4. Tabela `academia`

**Descrição:** Representa as unidades físicas da rede de academias. O identificador é gerado automaticamente pela sequência do PostgreSQL (`GENERATED ALWAYS AS IDENTITY`).

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_academia` | `INT` | PK, IDENTITY, NOT NULL | Identificador único da unidade (gerado automaticamente). |
| `nome` | `VARCHAR(100)` | NOT NULL | Nome comercial da unidade. |
| `endereco` | `VARCHAR(200)` | NOT NULL | Endereço completo da unidade. |

---

## 5. Tabela `tipo_plano`

**Descrição:** Extraída da tabela `plano` durante a normalização para 3FN (E3). Elimina a dependência transitiva `id_plano → tipo → desconto_anual`. Cada tipo de plano tem exatamente um desconto associado, e essa regra agora é garantida estruturalmente, não apenas por convenção.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `tipo` | `VARCHAR(30)` | PK, CHECK IN ('MENSAL','TRIMESTRAL','ANUAL') | Identificador do tipo de plano — também é a chave primária. |
| `desconto_percentual` | `DECIMAL(5,2)` | NOT NULL, DEFAULT 0, CHECK 0..100 | Percentual de desconto aplicado sobre o valor total para este tipo. |

---

## 6. Tabela `plano`

**Descrição:** Planos de assinatura disponíveis na rede. O atributo `valor_total` foi removido por ser derivável (`valor_mensal × duracao_meses`), conforme identificado na análise de normalização. O desconto migrou para `tipo_plano`.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_plano` | `INT` | PK, IDENTITY | Identificador único do plano. |
| `nome` | `VARCHAR(100)` | NOT NULL | Nome comercial do plano. |
| `valor_mensal` | `DECIMAL(10,2)` | NOT NULL, CHECK > 0 | Valor cobrado mensalmente em reais. |
| `duracao_meses` | `INT` | NOT NULL, CHECK > 0 | Duração total do plano em meses. |
| `descricao` | `TEXT` | — | Descrição dos benefícios incluídos no plano (opcional). |
| `tipo` | `VARCHAR(30)` | NOT NULL, FK → `tipo_plano(tipo)`, CHECK IN ('MENSAL','TRIMESTRAL','ANUAL') | Categoria do plano — referencia `tipo_plano`. |

---

## 7. Tabela `contrato`

**Descrição:** Formaliza quais planos cada unidade disponibiliza para venda. A relação é N:M entre `academia` e `plano`, resolvida por esta tabela associativa.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_contrato` | `INT` | PK, IDENTITY, NOT NULL | Identificador único do contrato. |
| `id_academia` | `INT` | NOT NULL, FK → `academia(id_academia)` | Academia contratante. |
| `id_plano` | `INT` | NOT NULL, FK → `plano(id_plano)` | Plano disponibilizado pela academia. |

---

## 8. Tabela `matricula`

**Descrição:** Registra a inscrição de um aluno em uma unidade da academia com um plano específico. A FK `cpf_aluno` referencia `pessoa`, mas a regra de negócio exige `papel IN ('ALUNO','AMBOS')` — aplicável via trigger ou validação de aplicação, pois CHECK com subquery não é suportado em PostgreSQL.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_matricula` | `INT` | PK, IDENTITY, NOT NULL | Identificador único da matrícula. |
| `cpf_aluno` | `INT` | NOT NULL, FK → `pessoa(cpf)` | CPF do aluno matriculado (papel deve ser ALUNO ou AMBOS). |
| `id_academia` | `INT` | NOT NULL, FK → `academia(id_academia)` | Unidade em que o aluno está matriculado. |
| `id_plano` | `INT` | NOT NULL, FK → `plano(id_plano)` | Plano contratado pelo aluno. |

---

## 9. Tabela `equipamento`

**Descrição:** Representa os equipamentos físicos de cada unidade. Consolida `equip_musculacao` e `equip_cardio` do modelo original usando o campo `categoria` como discriminador. CHECKs condicionais garantem que `velocidade_max` só seja preenchido em equipamentos de musculação e `tipo_resistencia` apenas em equipamentos de cardio.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_equipamento` | `INT` | PK, IDENTITY, NOT NULL | Identificador único do equipamento. |
| `id_academia` | `INT` | NOT NULL, FK → `academia(id_academia)` | Unidade à qual o equipamento pertence. |
| `nome` | `VARCHAR(100)` | NOT NULL | Nome do equipamento. |
| `marca` | `VARCHAR(100)` | — | Fabricante do equipamento. |
| `status` | `VARCHAR(30)` | — | Estado atual: ATIVO, EM_MANUTENCAO ou INATIVO. |
| `data_aquisicao` | `DATE` | — | Data de compra do equipamento. |
| `peso_maximo` | `DECIMAL(8,2)` | — | Capacidade máxima de carga (kg). |
| `categoria` | `VARCHAR(20)` | NOT NULL, CHECK IN ('MUSCULACAO','CARDIO') | Tipo funcional do equipamento. |
| `velocidade_max` | `DECIMAL(8,2)` | CHECK: nulo se categoria ≠ MUSCULACAO | Velocidade máxima de operação (km/h) — exclusivo de MUSCULACAO. |
| `tipo_resistencia` | `VARCHAR(50)` | CHECK: nulo se categoria ≠ CARDIO | Tipo de resistência do mecanismo — exclusivo de CARDIO. |

---

## 10. Tabela `manutencao`

**Descrição:** Histórico de manutenções realizadas nos equipamentos da rede. Permite rastrear o custo acumulado por equipamento ou por unidade ao longo do tempo.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_manutencao` | `INT` | PK, IDENTITY, NOT NULL | Identificador único do registro de manutenção. |
| `id_equipamento` | `INT` | NOT NULL, FK → `equipamento(id_equipamento)` | Equipamento que passou por manutenção. |
| `tipo` | `VARCHAR(50)` | — | Natureza da manutenção: PREVENTIVA ou CORRETIVA. |
| `descricao` | `TEXT` | — | Descrição dos serviços realizados. |
| `custo` | `DECIMAL(10,2)` | — | Custo total da manutenção em reais. |
| `data` | `DATE` | — | Data de realização da manutenção. |

---

## 11. Tabela `aula_coletiva`

**Descrição:** Representa as aulas coletivas ministradas por instrutores credenciados. O modelo não registra data/hora da aula diretamente nesta tabela — essa informação é capturada no `registro_frequencia` no momento do acesso do aluno.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_aula` | `INT` | PK, IDENTITY, NOT NULL | Identificador único da aula coletiva. |
| `cpf_instrutor` | `INT` | NOT NULL, FK → `instrutor(cpf)` | Instrutor responsável pela aula. |

---

## 12. Tabela `registro_frequencia`

**Descrição:** Consolida todos os registros de acesso dos alunos à academia, sejam acessos livres (uso de equipamentos) ou presença em aulas coletivas. Resultado da fusão de `acesso_livre` e `acesso_aula` do modelo original. Possui duas chaves candidatas: `{id_registro}` (surrogada) e `{cpf_aluno, data_hora}` (natural, declarada via UNIQUE). O campo `tipo_acesso` é uma desnormalização controlada de BCNF justificada por clareza semântica e performance.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_registro` | `INT` | PK, IDENTITY, NOT NULL | Identificador único do registro. |
| `cpf_aluno` | `INT` | NOT NULL, FK → `pessoa(cpf)` | Aluno que realizou o acesso. |
| `data_hora` | `TIMESTAMP` | NOT NULL, UNIQUE com cpf_aluno | Data e hora do acesso. |
| `tipo_acesso` | `VARCHAR(20)` | NOT NULL, CHECK IN ('LIVRE','AULA') | Modalidade: LIVRE (equipamentos) ou AULA (aula coletiva). |
| `id_aula` | `INT` | FK → `aula_coletiva(id_aula)`, nullable | Aula frequentada — obrigatório quando tipo_acesso = AULA. |
| `observacao` | `VARCHAR(255)` | — | Observações adicionais sobre o acesso (opcional). |

**Constraints adicionais:**
- `UNIQUE(cpf_aluno, data_hora)` — um aluno não pode ter dois registros simultâneos.
- `CHECK((tipo_acesso = 'AULA' AND id_aula IS NOT NULL) OR (tipo_acesso = 'LIVRE' AND id_aula IS NULL))` — consistência bidirecional entre tipo e referência de aula.

---

## 13. Tabela `utiliza`

**Descrição:** Tabela associativa N:M entre `registro_frequencia` e `equipamento`, indicando quais equipamentos foram utilizados durante um acesso livre. Apenas registros do tipo LIVRE devem ser referenciados — regra de negócio aplicável via trigger ou validação de aplicação.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_registro` | `INT` | PK (parte), FK → `registro_frequencia(id_registro)`, NOT NULL | Registro de acesso (deve ser do tipo LIVRE). |
| `id_equipamento` | `INT` | PK (parte), FK → `equipamento(id_equipamento)`, NOT NULL | Equipamento utilizado durante o acesso. |

---

## 14. Tabela `avaliacao`

**Descrição:** Avaliações realizadas por alunos sobre unidades da academia ou sobre aulas coletivas. Consolida `avaliacao_academia` e `avaliacao_aula` do modelo original usando o campo `tipo` como discriminador. CHECKs condicionais garantem a consistência: avaliações do tipo ACADEMIA exigem `id_academia` e podem ter `nota_academia`; avaliações do tipo AULA exigem `id_aula`.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_avaliacao` | `INT` | PK, IDENTITY, NOT NULL | Identificador único da avaliação. |
| `cpf_aluno` | `INT` | NOT NULL, FK → `pessoa(cpf)` | Aluno que realizou a avaliação. |
| `cpf_funcionario` | `INT` | FK → `pessoa(cpf)`, nullable | Funcionário que conduziu a avaliação (opcional). |
| `data_hora` | `TIMESTAMP` | NOT NULL | Data e hora em que a avaliação foi registrada. |
| `observacao` | `TEXT` | — | Comentário livre do aluno. |
| `tipo` | `VARCHAR(20)` | NOT NULL, CHECK IN ('ACADEMIA','AULA') | Tipo da avaliação. |
| `id_academia` | `INT` | FK → `academia(id_academia)`, nullable | Academia avaliada — obrigatório quando tipo = ACADEMIA. |
| `nota_academia` | `DECIMAL(4,2)` | CHECK 0..10, nullable | Nota geral da academia — preenchido somente quando tipo = ACADEMIA. |
| `id_aula` | `INT` | FK → `aula_coletiva(id_aula)`, nullable | Aula avaliada — obrigatório quando tipo = AULA. |

---

## 15. Tabela `criterio`

**Descrição:** Define os critérios de avaliação utilizados na avaliação detalhada de aulas coletivas. Cada critério é reutilizável em múltiplas avaliações.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_criterio` | `INT` | PK, IDENTITY, NOT NULL | Identificador único do critério. |
| `nome` | `VARCHAR(100)` | NOT NULL | Nome do critério (ex.: Didática, Pontualidade, Segurança). |
| `descricao` | `TEXT` | — | Descrição detalhada do que o critério avalia. |

---

## 16. Tabela `item_avaliado`

**Descrição:** Tabela associativa N:M entre `avaliacao` e `criterio`, armazenando a nota atribuída a cada critério dentro de uma avaliação de aula coletiva. A PK composta garante que cada critério seja avaliado no máximo uma vez por avaliação.

| Nome | Tipo SQL | Restrições | Descrição |
|------|----------|------------|-----------|
| `id_avaliacao` | `INT` | PK (parte), FK → `avaliacao(id_avaliacao)`, NOT NULL | Avaliação à qual este item pertence. |
| `id_criterio` | `INT` | PK (parte), FK → `criterio(id_criterio)`, NOT NULL | Critério sendo avaliado. |
| `nota` | `DECIMAL(4,2)` | NOT NULL, CHECK 0..10 | Nota atribuída ao critério, entre 0,00 e 10,00. |
