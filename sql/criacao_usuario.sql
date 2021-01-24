-- UNIVERSIDADE FEDERAL DE SÃO CARLOS
-- Disciplina: Sistemas de Bancos de Dados
-- Professora: Sahudy Montenegro
-- Autor: Gabriel Viana Teixeira
-- Autor: Guilherme Pereira Fantini
-- Autor: Tales Baltar Lopes da Silva

-- Código para criação de usuários.

-- Administrador

CREATE ROLE administrador
LOGIN
NOINHERIT
CREATEDB
CREATEROLE;

-- Gerente
CREATE ROLE gerente
NOINHERIT;

-- Desenvolvedor
CREATE ROLE desenvolvedor
LOGIN
NOINHERIT;

-- SAC_BI_Marketing
CREATE ROLE sac_bi_marketing
NOINHERIT;

-- Consumidor
CREATE ROLE consumidor
NOINHERIT;

-- Mudança de dono das tabelas
ALTER TABLE compra OWNER TO administrador;
ALTER TABLE consumidor OWNER TO administrador;
ALTER TABLE produto OWNER TO administrador;