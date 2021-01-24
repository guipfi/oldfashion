CREATE DATABASE g1_loja;

CREATE TABLE consumidor(
	cpf varchar(11) PRIMARY KEY,
	nome_consumidor varchar(200) NOT NULL,
	data_nasc DATE NOT NULL,
	telefone varchar(16) NOT NULL, 
	email text UNIQUE NOT NULL,
	senha text NOT NULL,
	endereco text NOT NULL,
	cidade varchar(32) NOT NULL
);

CREATE TABLE produto(
	id serial PRIMARY KEY,
	nome_produto varchar(200) NOT NULL,
	preco float NOT NULL,
	descricao text NOT NULL,
	categoria varchar(100) NOT NULL
);

CREATE TABLE compra(
	produto_id int NOT NULL,
	consumidor_cpf varchar(11) NOT NULL,
	data TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	quantidade int NOT NULL,
	entregue boolean DEFAULT FALSE,
	n_estrelas float CHECK(n_estrelas BETWEEN 0 AND 5) DEFAULT NULL,
	comentario text DEFAULT NULL,
	PRIMARY KEY(produto_id, consumidor_cpf, data),
	FOREIGN KEY(produto_id) REFERENCES produto(id),
	FOREIGN KEY(consumidor_cpf) REFERENCES consumidor(cpf)
);


