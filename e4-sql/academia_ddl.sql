-- =========================================================
-- ACADEMIA DB — DDL PostgreSQL
-- =========================================================

-- =========================================================
-- IDEMPOTÊNCIA — DROP em ordem inversa às dependências
-- =========================================================
DROP TABLE IF EXISTS item_avaliado         CASCADE;
DROP TABLE IF EXISTS avaliacao             CASCADE;
DROP TABLE IF EXISTS criterio              CASCADE;
DROP TABLE IF EXISTS utiliza               CASCADE;
DROP TABLE IF EXISTS registro_frequencia   CASCADE;
DROP TABLE IF EXISTS aula_coletiva         CASCADE;
DROP TABLE IF EXISTS manutencao            CASCADE;
DROP TABLE IF EXISTS equipamento           CASCADE;
DROP TABLE IF EXISTS matricula             CASCADE;
DROP TABLE IF EXISTS contrato              CASCADE;
DROP TABLE IF EXISTS plano                 CASCADE;
DROP TABLE IF EXISTS academia              CASCADE;
DROP TABLE IF EXISTS instrutor             CASCADE;
DROP TABLE IF EXISTS funcionario_telefone  CASCADE;
DROP TABLE IF EXISTS pessoa                CASCADE;

-- =========================================================
-- 1. PESSOAS
-- =========================================================

CREATE TABLE pessoa (
    cpf             INT          NOT NULL,
    primeiro_nome   VARCHAR(50)  NOT NULL,
    nome            VARCHAR(100) NOT NULL,
    sobrenome       VARCHAR(50)  NOT NULL,
    data_nascimento DATE         NOT NULL,
    email           VARCHAR(100),
    papel           VARCHAR(20)  NOT NULL,

    CONSTRAINT pk_pessoa       PRIMARY KEY (cpf),
    CONSTRAINT chk_pessoa_papel CHECK (papel IN ('ALUNO', 'FUNCIONARIO', 'AMBOS'))
);

COMMENT ON TABLE  pessoa                  IS 'Cadastro unificado de todas as pessoas do sistema (alunos e funcionários).';
COMMENT ON COLUMN pessoa.cpf              IS 'CPF do indivíduo — identificador único e chave primária.';
COMMENT ON COLUMN pessoa.primeiro_nome    IS 'Primeiro nome da pessoa.';
COMMENT ON COLUMN pessoa.nome             IS 'Nome completo da pessoa.';
COMMENT ON COLUMN pessoa.sobrenome        IS 'Último sobrenome da pessoa.';
COMMENT ON COLUMN pessoa.data_nascimento  IS 'Data de nascimento.';
COMMENT ON COLUMN pessoa.email            IS 'Endereço de e-mail de contato (opcional).';
COMMENT ON COLUMN pessoa.papel            IS 'Papel da pessoa no sistema: ALUNO, FUNCIONARIO ou AMBOS.';

-- ---------------------------------------------------------

CREATE TABLE funcionario_telefone (
    cpf      INT         NOT NULL,
    telefone VARCHAR(20) NOT NULL,

    CONSTRAINT pk_funcionario_telefone  PRIMARY KEY (cpf, telefone),
    CONSTRAINT fk_ftelefone_pessoa      FOREIGN KEY (cpf) REFERENCES pessoa (cpf)
);

COMMENT ON TABLE  funcionario_telefone         IS 'Telefones de contato dos funcionários (relação multivalorada).';
COMMENT ON COLUMN funcionario_telefone.cpf     IS 'FK para pessoa — deve ter papel FUNCIONARIO ou AMBOS.';
COMMENT ON COLUMN funcionario_telefone.telefone IS 'Número de telefone do funcionário.';

-- ---------------------------------------------------------

CREATE TABLE instrutor (
    cpf           INT         NOT NULL,
    qtd_parcelas  INT,
    especialidade VARCHAR(100),

    CONSTRAINT pk_instrutor        PRIMARY KEY (cpf),
    CONSTRAINT fk_instrutor_pessoa FOREIGN KEY (cpf) REFERENCES pessoa (cpf)
);

COMMENT ON TABLE  instrutor              IS 'Especialização de funcionário que ministra aulas coletivas.';
COMMENT ON COLUMN instrutor.cpf          IS 'FK para pessoa — herda dados pessoais do funcionário.';
COMMENT ON COLUMN instrutor.qtd_parcelas IS 'Quantidade de parcelas do contrato do instrutor.';
COMMENT ON COLUMN instrutor.especialidade IS 'Área de especialidade do instrutor (ex.: musculação, yoga).';

-- =========================================================
-- 2. ACADEMIA, PLANOS, CONTRATOS E MATRÍCULAS
-- =========================================================

CREATE TABLE academia (
    id_academia INT          GENERATED ALWAYS AS IDENTITY,
    nome        VARCHAR(100) NOT NULL,
    endereco    VARCHAR(200) NOT NULL,

    CONSTRAINT pk_academia PRIMARY KEY (id_academia)
);

COMMENT ON TABLE  academia            IS 'Unidades físicas da rede de academias.';
COMMENT ON COLUMN academia.id_academia IS 'Identificador único da academia (gerado automaticamente).';
COMMENT ON COLUMN academia.nome        IS 'Nome da unidade.';
COMMENT ON COLUMN academia.endereco    IS 'Endereço completo da unidade.';

-- ---------------------------------------------------------

CREATE TABLE plano (
    id_plano       INT           GENERATED ALWAYS AS IDENTITY,
    nome           VARCHAR(100)  NOT NULL,
    valor_mensal   DECIMAL(10,2) NOT NULL,
    valor_total    DECIMAL(10,2) NOT NULL,
    duracao_meses  INT           NOT NULL,
    descricao      TEXT,
    tipo           VARCHAR(30)   NOT NULL,
    desconto_anual DECIMAL(5,2),

    CONSTRAINT pk_plano         PRIMARY KEY (id_plano),
    CONSTRAINT chk_plano_tipo   CHECK (tipo IN ('MENSAL', 'TRIMESTRAL', 'ANUAL')),
    CONSTRAINT chk_plano_desconto CHECK (
        tipo = 'ANUAL'
        OR (tipo <> 'ANUAL' AND desconto_anual IS NULL)
    )
);

COMMENT ON TABLE  plano                IS 'Planos de assinatura oferecidos pelas academias.';
COMMENT ON COLUMN plano.id_plano       IS 'Identificador único do plano.';
COMMENT ON COLUMN plano.nome           IS 'Nome comercial do plano.';
COMMENT ON COLUMN plano.valor_mensal   IS 'Valor cobrado mensalmente.';
COMMENT ON COLUMN plano.valor_total    IS 'Valor total do contrato.';
COMMENT ON COLUMN plano.duracao_meses  IS 'Duração total do plano em meses.';
COMMENT ON COLUMN plano.descricao      IS 'Descrição detalhada do plano.';
COMMENT ON COLUMN plano.tipo           IS 'Categoria do plano: MENSAL, TRIMESTRAL ou ANUAL.';
COMMENT ON COLUMN plano.desconto_anual IS 'Percentual de desconto aplicado; preenchido somente quando tipo = ANUAL.';

-- ---------------------------------------------------------

CREATE TABLE contrato (
    id_contrato INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    id_academia INT NOT NULL,
    id_plano    INT NOT NULL,

    CONSTRAINT pk_contrato          PRIMARY KEY (id_contrato),
    CONSTRAINT fk_contrato_academia FOREIGN KEY (id_academia) REFERENCES academia (id_academia),
    CONSTRAINT fk_contrato_plano    FOREIGN KEY (id_plano)    REFERENCES plano    (id_plano)
);

COMMENT ON TABLE  contrato            IS 'Contratos entre academias e planos disponibilizados.';
COMMENT ON COLUMN contrato.id_contrato IS 'Identificador único do contrato.';
COMMENT ON COLUMN contrato.id_academia IS 'FK para a academia vinculada ao contrato.';
COMMENT ON COLUMN contrato.id_plano    IS 'FK para o plano vinculado ao contrato.';

-- ---------------------------------------------------------

CREATE TABLE matricula (
    id_matricula INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    cpf_aluno    INT NOT NULL,
    id_academia  INT NOT NULL,
    id_plano     INT NOT NULL,

    CONSTRAINT pk_matricula          PRIMARY KEY (id_matricula),
    CONSTRAINT fk_matricula_aluno    FOREIGN KEY (cpf_aluno)   REFERENCES pessoa   (cpf),
    CONSTRAINT fk_matricula_academia FOREIGN KEY (id_academia) REFERENCES academia (id_academia),
    CONSTRAINT fk_matricula_plano    FOREIGN KEY (id_plano)    REFERENCES plano    (id_plano)
);

COMMENT ON TABLE  matricula             IS 'Matrículas de alunos em planos de academias.';
COMMENT ON COLUMN matricula.id_matricula IS 'Identificador único da matrícula.';
COMMENT ON COLUMN matricula.cpf_aluno   IS 'FK para pessoa — deve ter papel ALUNO ou AMBOS.';
COMMENT ON COLUMN matricula.id_academia IS 'FK para a academia onde o aluno está matriculado.';
COMMENT ON COLUMN matricula.id_plano    IS 'FK para o plano contratado pelo aluno.';

-- =========================================================
-- 3. EQUIPAMENTOS E MANUTENÇÃO
-- =========================================================

CREATE TABLE equipamento (
    id_equipamento   INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    id_academia      INT          NOT NULL,
    nome             VARCHAR(100) NOT NULL,
    marca            VARCHAR(100),
    status           VARCHAR(30),
    data_aquisicao   DATE,
    peso_maximo      DECIMAL(8,2),
    categoria        VARCHAR(20)  NOT NULL,
    velocidade_max   DECIMAL(8,2),
    tipo_resistencia VARCHAR(50),

    CONSTRAINT pk_equipamento          PRIMARY KEY (id_equipamento),
    CONSTRAINT fk_equipamento_academia FOREIGN KEY (id_academia) REFERENCES academia (id_academia),
    CONSTRAINT chk_equip_categoria     CHECK (categoria IN ('MUSCULACAO', 'CARDIO')),
    CONSTRAINT chk_equip_velocidade    CHECK (
        categoria = 'MUSCULACAO'
        OR (categoria <> 'MUSCULACAO' AND velocidade_max IS NULL)
    ),
    CONSTRAINT chk_equip_resistencia   CHECK (
        categoria = 'CARDIO'
        OR (categoria <> 'CARDIO' AND tipo_resistencia IS NULL)
    )
);

COMMENT ON TABLE  equipamento                  IS 'Equipamentos disponíveis em cada unidade da academia.';
COMMENT ON COLUMN equipamento.id_equipamento   IS 'Identificador único do equipamento.';
COMMENT ON COLUMN equipamento.id_academia      IS 'FK para a academia à qual o equipamento pertence.';
COMMENT ON COLUMN equipamento.nome             IS 'Nome do equipamento.';
COMMENT ON COLUMN equipamento.marca            IS 'Marca fabricante do equipamento.';
COMMENT ON COLUMN equipamento.status           IS 'Estado atual do equipamento (ex.: ATIVO, EM_MANUTENCAO).';
COMMENT ON COLUMN equipamento.data_aquisicao   IS 'Data em que o equipamento foi adquirido.';
COMMENT ON COLUMN equipamento.peso_maximo      IS 'Capacidade máxima de peso suportada (kg).';
COMMENT ON COLUMN equipamento.categoria        IS 'Tipo do equipamento: MUSCULACAO ou CARDIO.';
COMMENT ON COLUMN equipamento.velocidade_max   IS 'Velocidade máxima de operação — preenchido somente quando categoria = MUSCULACAO.';
COMMENT ON COLUMN equipamento.tipo_resistencia IS 'Tipo de resistência do equipamento — preenchido somente quando categoria = CARDIO.';

-- ---------------------------------------------------------

CREATE TABLE manutencao (
    id_manutencao  INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    id_equipamento INT          NOT NULL,
    tipo           VARCHAR(50),
    descricao      TEXT,
    custo          DECIMAL(10,2),
    data           DATE,

    CONSTRAINT pk_manutencao       PRIMARY KEY (id_manutencao),
    CONSTRAINT fk_manutencao_equip FOREIGN KEY (id_equipamento) REFERENCES equipamento (id_equipamento)
);

COMMENT ON TABLE  manutencao               IS 'Registros de manutenções realizadas nos equipamentos.';
COMMENT ON COLUMN manutencao.id_manutencao  IS 'Identificador único do registro de manutenção.';
COMMENT ON COLUMN manutencao.id_equipamento IS 'FK para o equipamento que sofreu manutenção.';
COMMENT ON COLUMN manutencao.tipo           IS 'Tipo de manutenção (ex.: PREVENTIVA, CORRETIVA).';
COMMENT ON COLUMN manutencao.descricao      IS 'Descrição detalhada dos serviços realizados.';
COMMENT ON COLUMN manutencao.custo          IS 'Custo total da manutenção.';
COMMENT ON COLUMN manutencao.data           IS 'Data em que a manutenção foi realizada.';

-- =========================================================
-- 4. FREQUÊNCIA / ACESSOS
-- =========================================================

-- aula_coletiva criada antes de registro_frequencia (referenciada como FK)
CREATE TABLE aula_coletiva (
    id_aula       INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    cpf_instrutor INT NOT NULL,

    CONSTRAINT pk_aula_coletiva  PRIMARY KEY (id_aula),
    CONSTRAINT fk_aula_instrutor FOREIGN KEY (cpf_instrutor) REFERENCES instrutor (cpf)
);

COMMENT ON TABLE  aula_coletiva              IS 'Aulas coletivas ministradas por instrutores.';
COMMENT ON COLUMN aula_coletiva.id_aula       IS 'Identificador único da aula coletiva.';
COMMENT ON COLUMN aula_coletiva.cpf_instrutor IS 'FK para o instrutor responsável pela aula.';

-- ---------------------------------------------------------

CREATE TABLE registro_frequencia (
    id_registro INT         NOT NULL GENERATED ALWAYS AS IDENTITY,
    cpf_aluno   INT         NOT NULL,
    data_hora   TIMESTAMP   NOT NULL,
    tipo_acesso VARCHAR(20) NOT NULL,
    id_aula     INT,
    observacao  VARCHAR(255),

    CONSTRAINT pk_registro          PRIMARY KEY (id_registro),
    CONSTRAINT uq_registro_aluno_dt UNIQUE      (cpf_aluno, data_hora),
    CONSTRAINT fk_registro_aluno    FOREIGN KEY (cpf_aluno) REFERENCES pessoa        (cpf),
    CONSTRAINT fk_registro_aula     FOREIGN KEY (id_aula)   REFERENCES aula_coletiva (id_aula),
    CONSTRAINT chk_registro_tipo    CHECK (tipo_acesso IN ('LIVRE', 'AULA')),
    CONSTRAINT chk_registro_aula    CHECK (
        (tipo_acesso = 'AULA'  AND id_aula IS NOT NULL)
        OR (tipo_acesso = 'LIVRE' AND id_aula IS NULL)
    )
);

COMMENT ON TABLE  registro_frequencia             IS 'Registros de acesso dos alunos à academia (livre ou em aula coletiva).';
COMMENT ON COLUMN registro_frequencia.id_registro  IS 'Identificador único do registro.';
COMMENT ON COLUMN registro_frequencia.cpf_aluno    IS 'FK para a pessoa (aluno) que realizou o acesso.';
COMMENT ON COLUMN registro_frequencia.data_hora    IS 'Data e hora do acesso.';
COMMENT ON COLUMN registro_frequencia.tipo_acesso  IS 'Modalidade do acesso: LIVRE (uso de equipamentos) ou AULA (aula coletiva).';
COMMENT ON COLUMN registro_frequencia.id_aula      IS 'FK para a aula coletiva — obrigatório quando tipo_acesso = AULA, nulo quando LIVRE.';
COMMENT ON COLUMN registro_frequencia.observacao   IS 'Observações adicionais sobre o acesso.';

-- ---------------------------------------------------------

CREATE TABLE utiliza (
    id_registro    INT NOT NULL,
    id_equipamento INT NOT NULL,

    CONSTRAINT pk_utiliza       PRIMARY KEY (id_registro, id_equipamento),
    CONSTRAINT fk_utiliza_reg   FOREIGN KEY (id_registro)    REFERENCES registro_frequencia (id_registro),
    CONSTRAINT fk_utiliza_equip FOREIGN KEY (id_equipamento) REFERENCES equipamento         (id_equipamento)
);

COMMENT ON TABLE  utiliza               IS 'Relacionamento entre acessos livres e os equipamentos utilizados durante cada acesso.';
COMMENT ON COLUMN utiliza.id_registro    IS 'FK para o registro de frequência (tipo_acesso = LIVRE).';
COMMENT ON COLUMN utiliza.id_equipamento IS 'FK para o equipamento utilizado.';

-- =========================================================
-- 5. AVALIAÇÕES
-- =========================================================

CREATE TABLE avaliacao (
    id_avaliacao    INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    cpf_aluno       INT          NOT NULL,
    cpf_funcionario INT,
    data_hora       TIMESTAMP    NOT NULL,
    observacao      TEXT,
    tipo            VARCHAR(20)  NOT NULL,
    id_academia     INT,
    nota_academia   DECIMAL(4,2),
    id_aula         INT,

    CONSTRAINT pk_avaliacao      PRIMARY KEY (id_avaliacao),
    CONSTRAINT fk_aval_aluno     FOREIGN KEY (cpf_aluno)       REFERENCES pessoa        (cpf),
    CONSTRAINT fk_aval_func      FOREIGN KEY (cpf_funcionario) REFERENCES pessoa        (cpf),
    CONSTRAINT fk_aval_academia  FOREIGN KEY (id_academia)     REFERENCES academia      (id_academia),
    CONSTRAINT fk_aval_aula      FOREIGN KEY (id_aula)         REFERENCES aula_coletiva (id_aula),
    CONSTRAINT chk_aval_tipo     CHECK (tipo IN ('ACADEMIA', 'AULA')),
    CONSTRAINT chk_aval_academia CHECK (
        (tipo = 'ACADEMIA' AND id_academia IS NOT NULL)
        OR (tipo <> 'ACADEMIA' AND id_academia IS NULL AND nota_academia IS NULL)
    ),
    CONSTRAINT chk_aval_aula     CHECK (
        (tipo = 'AULA' AND id_aula IS NOT NULL)
        OR (tipo <> 'AULA' AND id_aula IS NULL)
    ),
    CONSTRAINT chk_aval_nota     CHECK (nota_academia IS NULL OR nota_academia BETWEEN 0 AND 10)
);

COMMENT ON TABLE  avaliacao                IS 'Avaliações feitas por alunos sobre a academia ou sobre aulas coletivas.';
COMMENT ON COLUMN avaliacao.id_avaliacao    IS 'Identificador único da avaliação.';
COMMENT ON COLUMN avaliacao.cpf_aluno       IS 'FK para o aluno que realizou a avaliação.';
COMMENT ON COLUMN avaliacao.cpf_funcionario IS 'FK para o funcionário que conduziu a avaliação (opcional).';
COMMENT ON COLUMN avaliacao.data_hora       IS 'Data e hora em que a avaliação foi realizada.';
COMMENT ON COLUMN avaliacao.observacao      IS 'Observações livres sobre a avaliação.';
COMMENT ON COLUMN avaliacao.tipo            IS 'Tipo da avaliação: ACADEMIA ou AULA.';
COMMENT ON COLUMN avaliacao.id_academia     IS 'FK para a academia avaliada — obrigatório quando tipo = ACADEMIA.';
COMMENT ON COLUMN avaliacao.nota_academia   IS 'Nota de 0 a 10 para a academia — preenchido somente quando tipo = ACADEMIA.';
COMMENT ON COLUMN avaliacao.id_aula         IS 'FK para a aula coletiva avaliada — obrigatório quando tipo = AULA.';

-- ---------------------------------------------------------

CREATE TABLE criterio (
    id_criterio INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    nome        VARCHAR(100) NOT NULL,
    descricao   TEXT,

    CONSTRAINT pk_criterio PRIMARY KEY (id_criterio)
);

COMMENT ON TABLE  criterio             IS 'Critérios de avaliação utilizados nas avaliações de aulas coletivas.';
COMMENT ON COLUMN criterio.id_criterio IS 'Identificador único do critério.';
COMMENT ON COLUMN criterio.nome        IS 'Nome do critério (ex.: Didática, Pontualidade).';
COMMENT ON COLUMN criterio.descricao   IS 'Descrição detalhada do critério de avaliação.';

-- ---------------------------------------------------------

CREATE TABLE item_avaliado (
    id_avaliacao INT          NOT NULL,
    id_criterio  INT          NOT NULL,
    nota         DECIMAL(4,2) NOT NULL,

    CONSTRAINT pk_item_avaliado  PRIMARY KEY (id_avaliacao, id_criterio),
    CONSTRAINT fk_item_avaliacao FOREIGN KEY (id_avaliacao) REFERENCES avaliacao (id_avaliacao),
    CONSTRAINT fk_item_criterio  FOREIGN KEY (id_criterio)  REFERENCES criterio  (id_criterio),
    CONSTRAINT chk_item_nota     CHECK (nota BETWEEN 0 AND 10)
);

COMMENT ON TABLE  item_avaliado             IS 'Notas por critério dentro de uma avaliação de aula coletiva.';
COMMENT ON COLUMN item_avaliado.id_avaliacao IS 'FK para a avaliação à qual este item pertence.';
COMMENT ON COLUMN item_avaliado.id_criterio  IS 'FK para o critério avaliado.';
COMMENT ON COLUMN item_avaliado.nota         IS 'Nota atribuída ao critério, entre 0 e 10.';
