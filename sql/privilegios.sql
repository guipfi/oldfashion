-- UNIVERSIDADE FEDERAL DE SÃO CARLOS
-- Disciplina: Sistemas de Bancos de Dados
-- Professora: Sahudy Montenegro
-- Autor: Gabriel Viana Teixeira
-- Autor: Guilherme Pereira Fantini
-- Autor: Tales Baltar Lopes da Silva

-- Código para concessão de privilégios aos usuários do sistema.

-- Troca de acesso no BD para o administrador.
SET ROLE administrador;

-- Gerente
GRANT SELECT, DELETE, UPDATE(cpf) 
ON consumidor
TO gerente;
GRANT SELECT, DELETE
ON compra
TO gerente;

GRANT SELECT
ON produto
TO gerente;

-- Desenvolvedor
GRANT SELECT, INSERT, DELETE, UPDATE
ON produto
TO desenvolvedor;

-- SAC-BI-Marketing
GRANT SELECT
ON consumidor
TO sac_bi_marketing;

GRANT SELECT
ON compra
TO sac_bi_marketing;

GRANT SELECT
ON produto
TO sac_bi_marketing;

-- Consumidor
GRANT INSERT, DELETE, UPDATE 
ON consumidor
TO consumidor;

GRANT SELECT, INSERT, UPDATE(comentario, n_estrelas) 
ON compra
TO consumidor;

GRANT SELECT 
ON produto
TO consumidor;