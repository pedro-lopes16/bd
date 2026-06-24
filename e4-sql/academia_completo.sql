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
DROP TABLE IF EXISTS tipo_plano            CASCADE;
DROP TABLE IF EXISTS academia              CASCADE;
DROP TABLE IF EXISTS instrutor             CASCADE;
DROP TABLE IF EXISTS funcionario_telefone  CASCADE;
DROP TABLE IF EXISTS pessoa                CASCADE;

-- DDL

CREATE TABLE pessoa (
    cpf             BIGINT       NOT NULL,
    primeiro_nome   VARCHAR(50)  NOT NULL,
    nome            VARCHAR(100) NOT NULL,
    sobrenome       VARCHAR(50)  NOT NULL,
    data_nascimento DATE         NOT NULL,
    email           VARCHAR(100),
    papel           VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_pessoa        PRIMARY KEY (cpf),
    CONSTRAINT chk_pessoa_papel CHECK (papel IN ('ALUNO', 'FUNCIONARIO', 'AMBOS'))
);

CREATE TABLE funcionario_telefone (
    cpf      BIGINT      NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    CONSTRAINT pk_funcionario_telefone PRIMARY KEY (cpf, telefone),
    CONSTRAINT fk_ftelefone_pessoa     FOREIGN KEY (cpf) REFERENCES pessoa (cpf)
);

CREATE TABLE instrutor (
    cpf           BIGINT      NOT NULL,
    qtd_parcelas  INT,
    especialidade VARCHAR(100),
    CONSTRAINT pk_instrutor        PRIMARY KEY (cpf),
    CONSTRAINT fk_instrutor_pessoa FOREIGN KEY (cpf) REFERENCES pessoa (cpf)
);

CREATE TABLE academia (
    id_academia INT          GENERATED ALWAYS AS IDENTITY,
    nome        VARCHAR(100) NOT NULL,
    endereco    VARCHAR(200) NOT NULL,
    CONSTRAINT pk_academia PRIMARY KEY (id_academia)
);

CREATE TABLE tipo_plano (
    tipo                VARCHAR(30)  NOT NULL,
    desconto_percentual DECIMAL(5,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_tipo_plano      PRIMARY KEY (tipo),
    CONSTRAINT chk_tipo_plano_val CHECK (tipo IN ('MENSAL', 'TRIMESTRAL', 'ANUAL')),
    CONSTRAINT chk_tipo_desconto  CHECK (desconto_percentual >= 0 AND desconto_percentual <= 100)
);

CREATE TABLE plano (
    id_plano      INT           GENERATED ALWAYS AS IDENTITY,
    nome          VARCHAR(100)  NOT NULL,
    valor_mensal  DECIMAL(10,2) NOT NULL,
    duracao_meses INT           NOT NULL,
    descricao     TEXT,
    tipo          VARCHAR(30)   NOT NULL,
    CONSTRAINT pk_plano      PRIMARY KEY (id_plano),
    CONSTRAINT fk_plano_tipo FOREIGN KEY (tipo) REFERENCES tipo_plano (tipo),
    CONSTRAINT chk_plano_val CHECK (valor_mensal > 0 AND duracao_meses > 0)
);

CREATE TABLE contrato (
    id_contrato INT NOT NULL GENERATED ALWAYS AS IDENTITY,
    id_academia INT NOT NULL,
    id_plano    INT NOT NULL,
    CONSTRAINT pk_contrato          PRIMARY KEY (id_contrato),
    CONSTRAINT fk_contrato_academia FOREIGN KEY (id_academia) REFERENCES academia (id_academia),
    CONSTRAINT fk_contrato_plano    FOREIGN KEY (id_plano)    REFERENCES plano    (id_plano)
);

CREATE TABLE matricula (
    id_matricula INT    NOT NULL GENERATED ALWAYS AS IDENTITY,
    cpf_aluno    BIGINT NOT NULL,
    id_academia  INT    NOT NULL,
    id_plano     INT    NOT NULL,
    CONSTRAINT pk_matricula          PRIMARY KEY (id_matricula),
    CONSTRAINT fk_matricula_aluno    FOREIGN KEY (cpf_aluno)   REFERENCES pessoa   (cpf),
    CONSTRAINT fk_matricula_academia FOREIGN KEY (id_academia) REFERENCES academia  (id_academia),
    CONSTRAINT fk_matricula_plano    FOREIGN KEY (id_plano)    REFERENCES plano     (id_plano)
);

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

CREATE TABLE aula_coletiva (
    id_aula       INT    NOT NULL GENERATED ALWAYS AS IDENTITY,
    cpf_instrutor BIGINT NOT NULL,
    CONSTRAINT pk_aula_coletiva  PRIMARY KEY (id_aula),
    CONSTRAINT fk_aula_instrutor FOREIGN KEY (cpf_instrutor) REFERENCES instrutor (cpf)
);

CREATE TABLE registro_frequencia (
    id_registro INT         NOT NULL GENERATED ALWAYS AS IDENTITY,
    cpf_aluno   BIGINT      NOT NULL,
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

CREATE TABLE utiliza (
    id_registro    INT NOT NULL,
    id_equipamento INT NOT NULL,
    CONSTRAINT pk_utiliza       PRIMARY KEY (id_registro, id_equipamento),
    CONSTRAINT fk_utiliza_reg   FOREIGN KEY (id_registro)    REFERENCES registro_frequencia (id_registro),
    CONSTRAINT fk_utiliza_equip FOREIGN KEY (id_equipamento) REFERENCES equipamento         (id_equipamento)
);

CREATE TABLE avaliacao (
    id_avaliacao    INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    cpf_aluno       BIGINT       NOT NULL,
    cpf_funcionario BIGINT,
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

CREATE TABLE criterio (
    id_criterio INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    nome        VARCHAR(100) NOT NULL,
    descricao   TEXT,
    CONSTRAINT pk_criterio PRIMARY KEY (id_criterio)
);

CREATE TABLE item_avaliado (
    id_avaliacao INT          NOT NULL,
    id_criterio  INT          NOT NULL,
    nota         DECIMAL(4,2) NOT NULL,
    CONSTRAINT pk_item_avaliado  PRIMARY KEY (id_avaliacao, id_criterio),
    CONSTRAINT fk_item_avaliacao FOREIGN KEY (id_avaliacao) REFERENCES avaliacao (id_avaliacao),
    CONSTRAINT fk_item_criterio  FOREIGN KEY (id_criterio)  REFERENCES criterio  (id_criterio),
    CONSTRAINT chk_item_nota     CHECK (nota BETWEEN 0 AND 10)
);

-- DML

INSERT INTO pessoa (cpf, primeiro_nome, nome, sobrenome, data_nascimento, email, papel) VALUES
(10011223344, 'Lucas',    'Lucas Pereira Andrade',      'Andrade',    '1998-03-15', 'lucas.andrade@email.com',    'ALUNO'),
(20022334455, 'Mariana',  'Mariana Costa Silva',        'Silva',      '1995-07-22', 'mariana.silva@email.com',    'ALUNO'),
(30033445566, 'Rafael',   'Rafael Mendes Souza',        'Souza',      '2001-11-03', 'rafael.souza@email.com',     'ALUNO'),
(40044556677, 'Beatriz',  'Beatriz Gomes Ferreira',     'Ferreira',   '1993-05-18', 'bia.ferreira@email.com',     'ALUNO'),
(50055667788, 'Gabriel',  'Gabriel Alves Lima',         'Lima',       '2000-09-27', 'gabriel.lima@email.com',     'ALUNO'),
(60066778899, 'Fernanda', 'Fernanda Rocha Carvalho',    'Carvalho',   '1997-01-12', 'fernanda.rc@email.com',      'ALUNO'),
(70077889900, 'Thiago',   'Thiago Barbosa Nascimento',  'Nascimento', '1999-06-30', 'thiago.nasc@email.com',      'ALUNO'),
(80088990011, 'Camila',   'Camila Oliveira Martins',    'Martins',    '1996-12-08', 'camila.martins@email.com',   'ALUNO'),
(90099001122, 'Roberto',  'Roberto Farias Teixeira',    'Teixeira',   '1985-04-20', 'roberto.tx@email.com',       'AMBOS'),
(40011223300, 'Patricia', 'Patricia Lemos Duarte',      'Duarte',     '1980-08-14', 'patricia.duarte@email.com',  'FUNCIONARIO'),
(51122334400, 'Anderson', 'Anderson Vieira Cunha',      'Cunha',      '1982-02-25', 'anderson.cunha@email.com',   'FUNCIONARIO'),
(62233445500, 'Juliana',  'Juliana Batista Rezende',    'Rezende',    '1988-10-05', 'juliana.rezende@email.com',  'FUNCIONARIO');

INSERT INTO funcionario_telefone (cpf, telefone) VALUES
(40011223300, '(31) 99201-3344'),
(51122334400, '(31) 98302-5566'),
(51122334400, '(31) 3344-7788'),
(62233445500, '(31) 97403-9900');

INSERT INTO instrutor (cpf, qtd_parcelas, especialidade) VALUES
(40011223300, 12, 'Musculação e Hipertrofia'),
(51122334400,  6, 'Spinning e Cardio Funcional');

INSERT INTO academia (nome, endereco) VALUES
('FitLife Centro',  'Av. Afonso Pena, 1500 — Centro, Belo Horizonte/MG'),
('FitLife Norte',   'Rua Padre Eustáquio, 820 — Padre Eustáquio, Belo Horizonte/MG'),
('FitLife Sul',     'Av. Raja Gabaglia, 3200 — Gutierrez, Belo Horizonte/MG');

INSERT INTO tipo_plano (tipo, desconto_percentual) VALUES
('MENSAL',      0.00),
('TRIMESTRAL',  5.00),
('ANUAL',      15.00);

INSERT INTO plano (nome, valor_mensal, duracao_meses, descricao, tipo) VALUES
('Mensal Básico',          89.90,  1, 'Acesso ilimitado à academia em horário comercial.',                          'MENSAL'),
('Mensal Premium',        129.90,  1, 'Acesso ilimitado 24h, incluindo todas as aulas coletivas.',                 'MENSAL'),
('Trimestral Essencial',   79.90,  3, 'Plano trimestral com desconto progressivo e acesso à área de musculação.',  'TRIMESTRAL'),
('Anual Família',          69.90, 12, 'Plano anual para famílias com até 4 membros.',                              'ANUAL'),
('Anual Completo',         99.90, 12, 'Plano anual individual com acesso total e avaliação física mensal.',        'ANUAL');

INSERT INTO contrato (id_academia, id_plano) VALUES
(1, 1), (1, 2), (2, 1), (2, 3), (3, 4), (3, 5);

INSERT INTO matricula (cpf_aluno, id_academia, id_plano) VALUES
(10011223344, 1, 1),
(20022334455, 1, 2),
(30033445566, 1, 2),
(40044556677, 2, 1),
(50055667788, 2, 3),
(60066778899, 2, 3),
(70077889900, 3, 4),
(80088990011, 3, 5),
(90099001122, 3, 5),
(10011223344, 2, 3),
(20022334455, 3, 4),
(30033445566, 3, 5);

INSERT INTO equipamento (id_academia, nome, marca, status, data_aquisicao, peso_maximo, categoria, velocidade_max, tipo_resistencia) VALUES
(1, 'Esteira Profissional',     'Movement',   'ATIVO',         '2022-03-10', NULL,  'CARDIO',     NULL, 'Eletromagnética'),
(1, 'Bicicleta Ergométrica',    'Caloi',      'ATIVO',         '2022-06-15', NULL,  'CARDIO',     NULL, 'Magnética'),
(1, 'Supino Reto',              'Kikos',      'ATIVO',         '2021-11-20', 200.0, 'MUSCULACAO', 0.0,  NULL),
(1, 'Rack de Agachamento',      'Athleticas', 'EM_MANUTENCAO', '2020-08-05', 300.0, 'MUSCULACAO', 0.0,  NULL),
(2, 'Elíptico Magnético',       'Movement',   'ATIVO',         '2023-01-18', NULL,  'CARDIO',     NULL, 'Magnética'),
(2, 'Esteira Dobrável',         'Athletic',   'ATIVO',         '2021-04-22', NULL,  'CARDIO',     NULL, 'Motorizada'),
(2, 'Leg Press 45°',            'Kikos',      'ATIVO',         '2022-09-30', 400.0, 'MUSCULACAO', 0.0,  NULL),
(2, 'Polia Alta e Baixa',       'Technogym',  'ATIVO',         '2023-05-12', 150.0, 'MUSCULACAO', 0.0,  NULL),
(3, 'Spinning Profissional',    'Schwinn',    'ATIVO',         '2023-02-28', NULL,  'CARDIO',     NULL, 'Mecânica'),
(3, 'Remo Indoor',              'Concept2',   'ATIVO',         '2022-07-14', NULL,  'CARDIO',     NULL, 'A ar'),
(3, 'Puxada Frontal',           'Kikos',      'ATIVO',         '2021-12-01', 120.0, 'MUSCULACAO', 0.0,  NULL),
(3, 'Mesa Flexora',             'Athleticas', 'INATIVO',       '2020-03-17', 100.0, 'MUSCULACAO', 0.0,  NULL);

INSERT INTO manutencao (id_equipamento, tipo, descricao, custo, data) VALUES
(4,  'CORRETIVA',  'Substituição do rolamento do pino central e lubrificação geral.',    350.00, '2025-11-10'),
(1,  'PREVENTIVA', 'Troca do deck e lubrificação da correia da esteira.',                280.00, '2025-09-05'),
(7,  'PREVENTIVA', 'Revisão dos cabos de aço e ajuste do ângulo da plataforma.',         180.00, '2025-10-20'),
(12, 'CORRETIVA',  'Reparo no mecanismo de tração da mesa flexora.',                     520.00, '2025-12-01'),
(5,  'PREVENTIVA', 'Calibração da resistência magnética e revisão do guidão.',           220.00, '2025-08-18'),
(2,  'CORRETIVA',  'Troca do sensor de cadência e reaperto do sistema de tensão.',       195.00, '2025-11-25'),
(8,  'PREVENTIVA', 'Revisão dos cabos, pesos e polias.',                                 160.00, '2026-01-08'),
(11, 'PREVENTIVA', 'Lubrificação da guia de deslizamento e inspeção dos cabos de aço.', 140.00, '2026-02-14');

INSERT INTO aula_coletiva (cpf_instrutor) VALUES
(40011223300),
(40011223300),
(51122334400),
(51122334400),
(40011223300),
(51122334400),
(40011223300),
(51122334400);

INSERT INTO registro_frequencia (cpf_aluno, data_hora, tipo_acesso, id_aula, observacao) VALUES
(10011223344, '2026-04-01 07:30:00', 'LIVRE', NULL, 'Treino de peito e tríceps'),
(20022334455, '2026-04-01 08:00:00', 'AULA',  3,    NULL),
(30033445566, '2026-04-01 09:15:00', 'AULA',  1,    NULL),
(40044556677, '2026-04-02 06:45:00', 'LIVRE', NULL, 'Treino de pernas'),
(50055667788, '2026-04-02 07:00:00', 'AULA',  4,    'Primeira aula de spinning intenso'),
(60066778899, '2026-04-02 08:30:00', 'LIVRE', NULL, NULL),
(70077889900, '2026-04-03 07:15:00', 'AULA',  6,    NULL),
(80088990011, '2026-04-03 08:00:00', 'LIVRE', NULL, 'Treino de costas'),
(90099001122, '2026-04-03 09:00:00', 'AULA',  2,    NULL),
(10011223344, '2026-04-05 07:30:00', 'LIVRE', NULL, 'Treino de ombro e bíceps'),
(20022334455, '2026-04-05 08:00:00', 'AULA',  5,    NULL),
(30033445566, '2026-04-07 09:00:00', 'LIVRE', NULL, NULL),
(40044556677, '2026-04-07 07:00:00', 'AULA',  7,    NULL),
(50055667788, '2026-04-08 07:00:00', 'LIVRE', NULL, 'Cardio e core'),
(60066778899, '2026-04-09 08:30:00', 'AULA',  8,    NULL);

INSERT INTO utiliza (id_registro, id_equipamento) VALUES
(1,  3),
(1,  4),
(4,  7),
(4,  8),
(6,  1),
(8,  11),
(8,  8),
(10, 3),
(12, 5),
(14, 9);

INSERT INTO avaliacao (cpf_aluno, cpf_funcionario, data_hora, observacao, tipo, id_academia, nota_academia, id_aula) VALUES
(10011223344, 62233445500, '2026-04-10 10:00:00', 'Ótima estrutura e equipamentos novos.',             'ACADEMIA', 1, 9.0,  NULL),
(20022334455, NULL,        '2026-04-10 11:00:00', 'Limpeza impecável e atendimento cordial.',          'ACADEMIA', 1, 8.5,  NULL),
(30033445566, 62233445500, '2026-04-11 09:30:00', NULL,                                                 'ACADEMIA', 2, 7.5,  NULL),
(40044556677, NULL,        '2026-04-11 10:30:00', 'Faltam mais equipamentos de cardio na unidade.',    'ACADEMIA', 2, 6.5,  NULL),
(70077889900, NULL,        '2026-04-12 09:00:00', 'Academia muito bem localizada e espaçosa.',         'ACADEMIA', 3, 9.5,  NULL),
(80088990011, 62233445500, '2026-04-12 10:00:00', NULL,                                                 'ACADEMIA', 3, 8.0,  NULL),
(20022334455, NULL,        '2026-04-06 12:00:00', 'Excelente ritmo e boa didática do professor.',      'AULA',     NULL, NULL, 3),
(50055667788, 62233445500, '2026-04-06 13:00:00', 'Aula intensa! Superou minhas expectativas.',        'AULA',     NULL, NULL, 4),
(90099001122, NULL,        '2026-04-07 14:00:00', 'Instrutor muito atencioso e motivador.',             'AULA',     NULL, NULL, 2),
(60066778899, NULL,        '2026-04-10 11:30:00', 'Boa aula, mas poderia ter mais variações de ritmo.','AULA',     NULL, NULL, 8);

INSERT INTO criterio (nome, descricao) VALUES
('Didática',     'Clareza e qualidade na transmissão dos exercícios pelo professor.'),
('Pontualidade', 'Respeito ao horário de início e término da aula.'),
('Segurança',    'Orientação sobre postura e prevenção de lesões durante a aula.'),
('Motivação',    'Capacidade de engajar os alunos durante toda a aula.');

INSERT INTO item_avaliado (id_avaliacao, id_criterio, nota) VALUES
(7,  1, 9.0), (7,  2, 8.5), (7,  3, 9.5), (7,  4, 9.0),
(8,  1, 8.0), (8,  2, 9.0), (8,  3, 7.5), (8,  4, 10.0),
(9,  1, 9.5), (9,  2, 8.0), (9,  4, 9.0),
(10, 1, 7.0), (10, 2, 8.5), (10, 3, 8.0), (10, 4, 7.5);

-- Consultas

-- Q1: Quais alunos têm e-mail cadastrado e não são do plano anual?
-- WHERE com AND, OR, NOT.
SELECT p.nome, p.email, p.data_nascimento
FROM pessoa p
WHERE (p.papel = 'ALUNO' OR p.papel = 'AMBOS')
  AND p.email IS NOT NULL
  AND NOT p.cpf IN (
      SELECT m.cpf_aluno FROM matricula m
      JOIN plano pl ON pl.id_plano = m.id_plano
      WHERE pl.tipo = 'ANUAL'
  )
ORDER BY p.nome;

-- Q2: Quais equipamentos estão ativos, foram adquiridos entre 2021 e 2023 e a marca começa com 'K' ou 'M'?
-- WHERE com BETWEEN, LIKE, IN.
SELECT e.nome, e.marca, e.categoria, e.status, e.data_aquisicao
FROM equipamento e
WHERE e.data_aquisicao BETWEEN '2021-01-01' AND '2023-12-31'
  AND e.status IN ('ATIVO', 'EM_MANUTENCAO')
  AND (e.marca LIKE 'K%' OR e.marca LIKE 'M%')
ORDER BY e.data_aquisicao;

-- Q3: Quais alunos estão matriculados em qual academia e em qual plano?
-- INNER JOIN em 3 tabelas.
SELECT p.nome AS aluno, a.nome AS academia, pl.nome AS plano, pl.valor_mensal
FROM matricula m
JOIN pessoa   p  ON p.cpf        = m.cpf_aluno
JOIN academia a  ON a.id_academia = m.id_academia
JOIN plano    pl ON pl.id_plano   = m.id_plano
ORDER BY a.nome, p.nome;

-- Q4: Quais manutenções foram realizadas, em qual equipamento e em qual academia?
-- INNER JOIN em 3 tabelas.
SELECT mn.tipo, mn.data, mn.custo, e.nome AS equipamento, a.nome AS academia
FROM manutencao mn
JOIN equipamento e ON e.id_equipamento = mn.id_equipamento
JOIN academia    a ON a.id_academia    = e.id_academia
ORDER BY mn.data DESC;

-- Q5: Quais alunos nunca registraram presença na academia?
-- LEFT OUTER JOIN.
SELECT p.nome, p.email
FROM pessoa p
LEFT JOIN registro_frequencia rf ON rf.cpf_aluno = p.cpf
WHERE p.papel IN ('ALUNO', 'AMBOS')
  AND rf.id_registro IS NULL
ORDER BY p.nome;

-- Q6: Quantas matrículas cada academia tem e qual a soma do valor mensal arrecadado?
-- GROUP BY com SUM e HAVING.
SELECT a.nome AS academia, COUNT(m.id_matricula) AS total_matriculas, SUM(pl.valor_mensal) AS receita_mensal
FROM academia  a
JOIN matricula m  ON m.id_academia = a.id_academia
JOIN plano     pl ON pl.id_plano   = m.id_plano
GROUP BY a.id_academia, a.nome
HAVING COUNT(m.id_matricula) > 2
ORDER BY receita_mensal DESC;

-- Q7: Quais alunos estão matriculados no plano mais barato disponível?
-- Subquery não correlacionada.
SELECT p.nome AS aluno, pl.nome AS plano, pl.valor_mensal
FROM matricula m
JOIN pessoa p  ON p.cpf       = m.cpf_aluno
JOIN plano  pl ON pl.id_plano = m.id_plano
WHERE m.id_plano = (
    SELECT id_plano FROM plano ORDER BY valor_mensal ASC LIMIT 1
)
ORDER BY p.nome;

-- Q8: Quais alunos já fizeram pelo menos uma avaliação de academia?
-- Subquery correlacionada com EXISTS.
SELECT p.nome, p.email
FROM pessoa p
WHERE EXISTS (
    SELECT 1 FROM avaliacao av
    WHERE av.cpf_aluno = p.cpf
      AND av.tipo = 'ACADEMIA'
)
ORDER BY p.nome;

-- Q9: Total de acessos por aluno.
-- CTE (WITH).
WITH acessos_por_aluno AS (
    SELECT cpf_aluno, COUNT(*) AS total
    FROM registro_frequencia
    GROUP BY cpf_aluno
)
SELECT p.nome AS aluno, a.total AS total_acessos
FROM acessos_por_aluno a
JOIN pessoa p ON p.cpf = a.cpf_aluno
ORDER BY total_acessos DESC;

-- Q10: Qual a nota média das avaliações por academia?
SELECT a.nome AS academia, ROUND(AVG(av.nota_academia), 2) AS media_nota, COUNT(av.id_avaliacao) AS total_avaliacoes
FROM academia a
JOIN avaliacao av ON av.id_academia = a.id_academia
WHERE av.tipo = 'ACADEMIA'
GROUP BY a.id_academia, a.nome
ORDER BY media_nota DESC;
