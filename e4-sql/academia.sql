-- =========================================================
-- ACADEMIA DB — DDL
-- =========================================================

-- =========================================================
-- 1. PESSOAS
-- =========================================================

CREATE TABLE pessoa (
    cpf              INT          NOT NULL,
    primeiro_nome    VARCHAR(50)  NOT NULL,
    nome             VARCHAR(100) NOT NULL,
    sobrenome        VARCHAR(50)  NOT NULL,
    data_nascimento  DATE         NOT NULL,
    email            VARCHAR(100),
    -- ALUNO | FUNCIONARIO | AMBOS  (substitui as tabelas aluno e funcionario)
    papel            VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_pessoa PRIMARY KEY (cpf),
    CONSTRAINT chk_pessoa_papel CHECK (papel IN ('ALUNO', 'FUNCIONARIO', 'AMBOS'))
);

CREATE TABLE funcionario_telefone (
    cpf      INT         NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    CONSTRAINT pk_funcionario_telefone PRIMARY KEY (cpf, telefone),
    CONSTRAINT fk_ftelefone_pessoa FOREIGN KEY (cpf) REFERENCES pessoa (cpf)
);

CREATE TABLE instrutor (
    cpf           INT          NOT NULL,
    qtd_parcelas  INT,
    especialidade VARCHAR(100),
    CONSTRAINT pk_instrutor PRIMARY KEY (cpf),
    CONSTRAINT fk_instrutor_pessoa FOREIGN KEY (cpf) REFERENCES pessoa (cpf)
);

-- =========================================================
-- 2. ACADEMIA, PLANOS, CONTRATOS E MATRÍCULAS
-- =========================================================

CREATE TABLE academia (
    id_academia INT          NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(100) NOT NULL,
    endereco    VARCHAR(200) NOT NULL,
    CONSTRAINT pk_academia PRIMARY KEY (id_academia)
);

CREATE TABLE plano (
    id_plano       INT            NOT NULL AUTO_INCREMENT,
    nome           VARCHAR(100)   NOT NULL,
    valor_mensal   DECIMAL(10,2)  NOT NULL,
    valor_total    DECIMAL(10,2)  NOT NULL,
    duracao_meses  INT            NOT NULL,
    descricao      TEXT,
    -- MENSAL | TRIMESTRAL | ANUAL  (substitui plano_mensal, plano_trim, plano_anual)
    tipo           VARCHAR(30)    NOT NULL,
    -- Preenchido apenas quando tipo = 'ANUAL'
    desconto_anual DECIMAL(5,2),
    CONSTRAINT pk_plano PRIMARY KEY (id_plano),
    CONSTRAINT chk_plano_tipo CHECK (tipo IN ('MENSAL', 'TRIMESTRAL', 'ANUAL')),
    CONSTRAINT chk_plano_desconto CHECK (
        (tipo = 'ANUAL')
        OR (tipo <> 'ANUAL' AND desconto_anual IS NULL)
    )
);

CREATE TABLE contrato (
    id_contrato INT NOT NULL AUTO_INCREMENT,
    id_academia INT NOT NULL,
    id_plano    INT NOT NULL,
    CONSTRAINT pk_contrato   PRIMARY KEY (id_contrato),
    CONSTRAINT fk_contrato_academia FOREIGN KEY (id_academia) REFERENCES academia (id_academia),
    CONSTRAINT fk_contrato_plano    FOREIGN KEY (id_plano)    REFERENCES plano    (id_plano)
);

CREATE TABLE matricula (
    id_matricula INT NOT NULL AUTO_INCREMENT,
    -- cpf de pessoa com papel IN ('ALUNO','AMBOS')
    cpf_aluno    INT NOT NULL,
    id_academia  INT NOT NULL,
    id_plano     INT NOT NULL,
    CONSTRAINT pk_matricula PRIMARY KEY (id_matricula),
    CONSTRAINT fk_matricula_aluno   FOREIGN KEY (cpf_aluno)   REFERENCES pessoa   (cpf),
    CONSTRAINT fk_matricula_academia FOREIGN KEY (id_academia) REFERENCES academia (id_academia),
    CONSTRAINT fk_matricula_plano   FOREIGN KEY (id_plano)    REFERENCES plano    (id_plano)
);

-- =========================================================
-- 3. EQUIPAMENTOS E MANUTENÇÃO
-- =========================================================

CREATE TABLE equipamento (
    id_equipamento   INT          NOT NULL AUTO_INCREMENT,
    id_academia      INT          NOT NULL,
    nome             VARCHAR(100) NOT NULL,
    marca            VARCHAR(100),
    status           VARCHAR(30),
    data_aquisicao   DATE,
    peso_maximo      DECIMAL(8,2),
    -- MUSCULACAO | CARDIO  (substitui equip_musculacao e equip_cardio)
    categoria        VARCHAR(20)  NOT NULL,
    -- Preenchido quando categoria = 'MUSCULACAO'
    velocidade_max   DECIMAL(8,2),
    -- Preenchido quando categoria = 'CARDIO'
    tipo_resistencia VARCHAR(50),
    CONSTRAINT pk_equipamento PRIMARY KEY (id_equipamento),
    CONSTRAINT fk_equipamento_academia FOREIGN KEY (id_academia) REFERENCES academia (id_academia),
    CONSTRAINT chk_equip_categoria CHECK (categoria IN ('MUSCULACAO', 'CARDIO')),
    CONSTRAINT chk_equip_velocidade CHECK (
        (categoria = 'MUSCULACAO')
        OR (categoria <> 'MUSCULACAO' AND velocidade_max IS NULL)
    ),
    CONSTRAINT chk_equip_resistencia CHECK (
        (categoria = 'CARDIO')
        OR (categoria <> 'CARDIO' AND tipo_resistencia IS NULL)
    )
);

CREATE TABLE manutencao (
    id_manutencao  INT           NOT NULL AUTO_INCREMENT,
    id_equipamento INT           NOT NULL,
    tipo           VARCHAR(50),
    descricao      TEXT,
    custo          DECIMAL(10,2),
    data           DATE,
    CONSTRAINT pk_manutencao PRIMARY KEY (id_manutencao),
    CONSTRAINT fk_manutencao_equip FOREIGN KEY (id_equipamento) REFERENCES equipamento (id_equipamento)
);

-- =========================================================
-- 4. FREQUÊNCIA / ACESSOS
-- =========================================================

-- aula_coletiva precisa existir antes de registro_frequencia (FK forward)
CREATE TABLE aula_coletiva (
    id_aula       INT NOT NULL AUTO_INCREMENT,
    cpf_instrutor INT NOT NULL,
    CONSTRAINT pk_aula_coletiva   PRIMARY KEY (id_aula),
    CONSTRAINT fk_aula_instrutor  FOREIGN KEY (cpf_instrutor) REFERENCES instrutor (cpf)
);

CREATE TABLE registro_frequencia (
    id_registro  INT          NOT NULL AUTO_INCREMENT,
    cpf_aluno    INT          NOT NULL,
    data_hora    DATETIME     NOT NULL,
    -- LIVRE | AULA  (substitui acesso_livre e acesso_aula)
    tipo_acesso  VARCHAR(20)  NOT NULL,
    -- Preenchido quando tipo_acesso = 'AULA'
    id_aula      INT,
    observacao   VARCHAR(255),
    CONSTRAINT pk_registro          PRIMARY KEY (id_registro),
    CONSTRAINT uq_registro_aluno_dt UNIQUE (cpf_aluno, data_hora),
    CONSTRAINT fk_registro_aluno    FOREIGN KEY (cpf_aluno) REFERENCES pessoa         (cpf),
    CONSTRAINT fk_registro_aula     FOREIGN KEY (id_aula)   REFERENCES aula_coletiva  (id_aula),
    CONSTRAINT chk_registro_tipo    CHECK (tipo_acesso IN ('LIVRE', 'AULA')),
    CONSTRAINT chk_registro_aula    CHECK (
        (tipo_acesso = 'AULA'  AND id_aula IS NOT NULL)
        OR (tipo_acesso = 'LIVRE' AND id_aula IS NULL)
    )
);

CREATE TABLE utiliza (
    id_registro    INT NOT NULL,
    id_equipamento INT NOT NULL,
    CONSTRAINT pk_utiliza        PRIMARY KEY (id_registro, id_equipamento),
    CONSTRAINT fk_utiliza_reg    FOREIGN KEY (id_registro)    REFERENCES registro_frequencia (id_registro),
    CONSTRAINT fk_utiliza_equip  FOREIGN KEY (id_equipamento) REFERENCES equipamento         (id_equipamento)
);

-- =========================================================
-- 5. AVALIAÇÕES
-- =========================================================

CREATE TABLE avaliacao (
    id_avaliacao    INT          NOT NULL AUTO_INCREMENT,
    cpf_aluno       INT          NOT NULL,
    cpf_funcionario INT,
    data_hora       DATETIME     NOT NULL,
    observacao      TEXT,
    -- ACADEMIA | AULA  (substitui avaliacao_academia e avaliacao_aula)
    tipo            VARCHAR(20)  NOT NULL,
    -- Preenchido quando tipo = 'ACADEMIA'
    id_academia     INT,
    nota_academia   DECIMAL(4,2),
    -- Preenchido quando tipo = 'AULA'
    id_aula         INT,
    CONSTRAINT pk_avaliacao       PRIMARY KEY (id_avaliacao),
    CONSTRAINT fk_aval_aluno      FOREIGN KEY (cpf_aluno)       REFERENCES pessoa        (cpf),
    CONSTRAINT fk_aval_func       FOREIGN KEY (cpf_funcionario) REFERENCES pessoa        (cpf),
    CONSTRAINT fk_aval_academia   FOREIGN KEY (id_academia)     REFERENCES academia      (id_academia),
    CONSTRAINT fk_aval_aula       FOREIGN KEY (id_aula)         REFERENCES aula_coletiva (id_aula),
    CONSTRAINT chk_aval_tipo      CHECK (tipo IN ('ACADEMIA', 'AULA')),
    CONSTRAINT chk_aval_academia  CHECK (
        (tipo = 'ACADEMIA' AND id_academia IS NOT NULL)
        OR (tipo <> 'ACADEMIA' AND id_academia IS NULL AND nota_academia IS NULL)
    ),
    CONSTRAINT chk_aval_aula      CHECK (
        (tipo = 'AULA' AND id_aula IS NOT NULL)
        OR (tipo <> 'AULA' AND id_aula IS NULL)
    ),
    CONSTRAINT chk_aval_nota CHECK (nota_academia IS NULL OR nota_academia BETWEEN 0 AND 10)
);

CREATE TABLE criterio (
    id_criterio INT          NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(100) NOT NULL,
    descricao   TEXT,
    CONSTRAINT pk_criterio PRIMARY KEY (id_criterio)
);

CREATE TABLE item_avaliado (
    id_avaliacao INT          NOT NULL,
    id_criterio  INT          NOT NULL,
    nota         DECIMAL(4,2) NOT NULL,
    CONSTRAINT pk_item_avaliado   PRIMARY KEY (id_avaliacao, id_criterio),
    CONSTRAINT fk_item_avaliacao  FOREIGN KEY (id_avaliacao) REFERENCES avaliacao (id_avaliacao),
    CONSTRAINT fk_item_criterio   FOREIGN KEY (id_criterio)  REFERENCES criterio  (id_criterio),
    CONSTRAINT chk_item_nota      CHECK (nota BETWEEN 0 AND 10)
);
