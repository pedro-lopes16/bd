# Relatório Final — Academia DB
**Disciplina:** Banco de Dados  
**Instituição:** PUC Minas  
**Domínio:** Academia / Fitness  
**SGBD:** PostgreSQL

---

## 1. Domínio e Escopo

O projeto modela o sistema de informações de uma rede de academias de ginástica com múltiplas unidades. O banco de dados foi projetado para suportar as seguintes necessidades operacionais:

- **Gestão de pessoas:** cadastro unificado de alunos, funcionários e instrutores, contemplando o caso real em que um funcionário também é aluno da própria academia.
- **Planos e matrículas:** controle dos planos de assinatura (mensais, trimestrais e anuais) com seus respectivos descontos, e vinculação de alunos a unidades e planos.
- **Infraestrutura:** inventário de equipamentos por unidade, com distinção entre equipamentos de musculação e cardio, e histórico completo de manutenções.
- **Frequência e aulas:** registro de todos os acessos dos alunos — seja por uso livre de equipamentos ou por participação em aulas coletivas ministradas por instrutores.
- **Avaliação:** coleta de avaliações de alunos sobre as unidades físicas e sobre as aulas coletivas, com critérios detalhados de pontuação.

O escopo cobre desde o cadastro inicial até a análise de receita, frequência e qualidade percebida pelos alunos.

---

## 2. DER — Principais Decisões de Modelagem

O processo de modelagem passou por três etapas iterativas: modelagem conceitual (E1 — DER), esquema relacional (E2 — Modelo Lógico e Relacional) e normalização formal (E3). Os documentos de referência estão em `e1-Readme/`, `e2-modelos/` e `e3-normalizacao/`.

### Entidades e Relacionamentos Centrais

O modelo possui cinco agrupamentos principais de entidades:

1. **Pessoas:** `pessoa`, `funcionario_telefone`, `instrutor`. A tabela `pessoa` é o núcleo do modelo, referenciada por todas as entidades que necessitam identificar um indivíduo.
2. **Rede e planos:** `academia`, `tipo_plano`, `plano`, `contrato`, `matricula`. Cobrem a estrutura comercial da rede.
3. **Infraestrutura:** `equipamento`, `manutencao`. Controlam o patrimônio físico e sua manutenção.
4. **Operação diária:** `aula_coletiva`, `registro_frequencia`, `utiliza`. Registram o uso efetivo da academia.
5. **Qualidade:** `avaliacao`, `criterio`, `item_avaliado`. Capturam a percepção dos alunos.

### Decisões de Modelagem Relevantes

**J1 — Unificação de `aluno` e `funcionario` em `pessoa`:**  
O modelo conceitual original possuía duas tabelas (`aluno`, `funcionario`) que funcionavam como subtypes sem atributos próprios. Tabelas com apenas PK/FK sem dados adicionais são um padrão de especialização vazio. A solução foi introduzir o atributo discriminador `papel` com CHECK constraint, e o valor `AMBOS` para o caso de funcionários que também frequentam a academia como alunos.

**J2 e J3 — Eliminação de subtipos de plano e remoção de `valor_total`:**  
As tabelas `plano_mensal`, `plano_trim` e `plano_anual` foram consolidadas em `plano`. O atributo `valor_total` foi removido por ser derivável matematicamente. Essa simplificação só foi possível após identificar que o discriminador `tipo` já estava presente em `plano`, tornando os subtipos estruturalmente redundantes.

**J4 e J5 — Consolidação de subtipos de acesso e avaliação:**  
`acesso_livre`, `acesso_aula`, `avaliacao_academia` e `avaliacao_aula` eram pares de tabelas 1:1 com pouquíssimos atributos. Cada par foi fundido em uma única tabela com campo discriminador e CHECKs condicionais, eliminando JOINs desnecessários em todas as consultas de frequência e avaliação.

**J6 — Consolidação de `equip_musculacao` e `equip_cardio`:**  
Cada subtabela tinha exatamente um atributo específico (`velocidade_max` e `tipo_resistencia`). O custo de um JOIN adicional em toda consulta de equipamento para recuperar um único campo não se justificava. O campo `categoria` em `equipamento` discrimina os casos com CHECKs condicionais.

---

## 3. Esquema Relacional Normalizado

Tabelas resultantes após a normalização (E3). Todas estão em BCNF, com exceção de `registro_frequencia`, que mantém uma desnormalização controlada justificada por trade-off explícito.

| Tabela | Chave Primária | Forma Normal | Observações |
|--------|----------------|--------------|-------------|
| `pessoa` | `cpf` | BCNF | Unifica aluno e funcionário |
| `funcionario_telefone` | `(cpf, telefone)` | BCNF | Atributo multivalorado normalizado |
| `instrutor` | `cpf` | BCNF | Especialização de pessoa |
| `academia` | `id_academia` | BCNF | |
| `tipo_plano` | `tipo` | BCNF | Extraída de `plano` na E3 para eliminar dependência transitiva |
| `plano` | `id_plano` | BCNF | `valor_total` removido (atributo derivado) |
| `contrato` | `id_contrato` | BCNF | Tabela associativa academia × plano |
| `matricula` | `id_matricula` | BCNF | |
| `equipamento` | `id_equipamento` | BCNF | Consolida musculação e cardio |
| `manutencao` | `id_manutencao` | BCNF | |
| `aula_coletiva` | `id_aula` | BCNF | |
| `registro_frequencia` | `id_registro` | 3FN* | Desnormalização controlada de BCNF; `tipo_acesso` mantido explicitamente |
| `utiliza` | `(id_registro, id_equipamento)` | BCNF | Tabela associativa N:M |
| `avaliacao` | `id_avaliacao` | BCNF | Consolida avaliação de academia e de aula |
| `criterio` | `id_criterio` | BCNF | |
| `item_avaliado` | `(id_avaliacao, id_criterio)` | BCNF | |

*Violação restrita ao subconjunto de tuplas onde `id_aula IS NOT NULL`; aceita por trade-off documentado em `e3-normalizacao/normalizacao.md`.

---

## 4. Script SQL

O script completo está em `e4-sql/academia_completo.sql` e está organizado em três seções:

- **Seção 1 — DDL:** criação de todas as 16 tabelas com PKs, FKs, CHECKs, UNIQUEs, `GENERATED ALWAYS AS IDENTITY` e `COMMENT ON TABLE / COLUMN`. Inclui `DROP TABLE IF EXISTS CASCADE` em ordem inversa para idempotência.
- **Seção 2 — DML:** inserção de dados realistas e coerentes entre si. Inclui 12 pessoas, 4 telefones, 2 instrutores, 3 academias, 3 tipos de plano, 5 planos, 6 contratos, 12 matrículas, 12 equipamentos, 8 manutenções, 8 aulas coletivas, 15 registros de frequência, 10 registros de utilização, 10 avaliações, 4 critérios e 15 itens avaliados.
- **Seção 3 — Consultas Q1–Q10:** dez consultas de negócio cobrindo WHERE com operadores lógicos, BETWEEN/LIKE/IN, INNER JOIN múltiplo, LEFT OUTER JOIN, GROUP BY com HAVING, subquery não correlacionada, subquery correlacionada com EXISTS, CTE e consulta complexa com múltiplas agregações.

Os scripts DDL anteriores (`academia.sql` e `academia_ddl.sql`) em `e4-sql/` são versões intermediárias de desenvolvimento mantidas por histórico.

---

## 5. Reflexão

### O que aprendemos ao longo do projeto

Começamos o projeto com uma ideia relativamente vaga do que significa "modelar bem" um banco de dados. Sabíamos que precisávamos identificar entidades, relacionamentos e atributos, mas a real complexidade das decisões só ficou evidente quando tivemos que justificar cada escolha formalmente.

**Modelagem conceitual: a armadilha do óbvio**

No início, modelamos `aluno` e `funcionario` como entidades separadas porque "parecia natural". Cada pessoa tem um papel diferente na academia, logo, entidades diferentes. Só percebemos o problema quando chegamos ao esquema relacional: ambas as tabelas tinham apenas uma coluna — a PK herdada de `pessoa`. Tabelas com PK/FK e nenhum atributo próprio não acrescentam informação; apenas introduzem JOINs obrigatórios em todas as consultas. A solução com o campo discriminador `papel` e CHECK constraint foi mais elegante e eficiente, e o valor `AMBOS` revelou uma necessidade real do negócio que o modelo original ignorava.

O mesmo padrão se repetiu com `plano_mensal`, `plano_trim`, `plano_anual`, `acesso_livre`, `acesso_aula`, `avaliacao_academia`, `avaliacao_aula`, `equip_musculacao` e `equip_cardio`. Em todos os casos, a especialização só se justifica quando os subtipos têm atributos próprios em quantidade significativa. Aprendemos a questionar cada tabela de subtipo: *ela existe porque há dados que precisam dela, ou porque estamos modelando em excesso de granularidade?*

**Normalização: a teoria encontra a realidade**

O exercício de normalização formal foi o mais revelador. Começamos aplicando as formas normais mecanicamente — 1FN, 2FN, 3FN, BCNF — e só depois entendemos o que estávamos fazendo de fato: eliminando redundâncias que poderiam produzir anomalias de atualização, inserção e remoção.

O caso de `tipo → desconto_anual` em `plano` foi particularmente instrutivo. A dependência transitiva `id_plano → tipo → desconto_anual` significava que dois planos do mesmo tipo poderiam, em teoria, ter descontos diferentes — uma inconsistência impossível de detectar apenas olhando os dados. A extração de `tipo_plano` resolveu o problema estruturalmente: agora é literalmente impossível ter dois descontos para o mesmo tipo de plano.

Mais interessante ainda foi o caso de `registro_frequencia`. Identificamos que `id_aula → tipo_acesso` viola BCNF quando `id_aula IS NOT NULL`. A solução textbook seria decompor a tabela. Mas ao analisar o trade-off — um campo de 5 bytes completamente controlado por CHECK, versus um JOIN adicional em toda consulta de frequência — ficou claro que a decomposição traria mais custo que benefício. Percebemos que normalização não é um fim em si mesmo, mas uma ferramenta. Elmasri & Navathe explicitam isso na discussão de desnormalização controlada, e agora entendemos na prática por que essa válvula de escape existe.

**Implementação SQL: constraints como documentação executável**

A etapa de DDL nos ensinou a usar constraints declarativas como primeira linha de defesa. Um CHECK constraint não é apenas validação — é documentação executável que o banco aplica em toda inserção e atualização, independentemente da aplicação que acessa o dado. O conjunto de CHECKs em `avaliacao` (que garante que uma avaliação de tipo ACADEMIA tenha `id_academia` preenchido e `id_aula` nulo, e vice-versa) transformou uma regra de negócio em código que nunca pode ser esquecido ou bypassado.

A opção por `GENERATED ALWAYS AS IDENTITY` em vez de `SERIAL` foi uma escolha deliberada: o padrão SQL moderno é mais explícito sobre a intenção e evita o comportamento inesperado de `SERIAL` em situações de truncagem ou cópia de tabela.

**Trabalho em equipe e versionamento Git**

O uso do Git ao longo das etapas foi essencial para manter a rastreabilidade das decisões. Cada etapa gerou commits que documentam não apenas o código final, mas a evolução do modelo. Quando revisamos os commits iniciais do DER e comparamos com o esquema normalizado, a linha de raciocínio fica clara: cada simplificação foi motivada por um problema identificado na etapa anterior.

O maior desafio colaborativo foi manter o esquema relacional sincronizado com o DER conceitual quando as decisões de modelagem mudavam. Mais de uma vez reescrevemos seções do esquema relacional porque uma mudança na hierarquia de especialização afetava várias outras tabelas em cascata. Isso reforçou a importância de manter um modelo conceitual estável antes de partir para o físico — algo que na prática profissional raramente acontece, mas que o projeto nos forçou a exercitar.

**Conclusão**

Saímos do projeto com uma compreensão muito mais precisa do que significa "um bom modelo de banco de dados": não é o mais normalizado, nem o mais simples, mas aquele em que cada decisão foi consciente e justificada. Saber quando normalizar até BCNF e quando aceitar uma desnormalização controlada é, em última análise, a habilidade central de quem projeta bancos de dados — e esse projeto nos deu a oportunidade de exercitá-la com rigor formal e casos concretos.
