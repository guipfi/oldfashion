# Old Fashion

O old fashion é um projeto de um sistema de bancos de dados para um e-commerce com o objetivo de realizar as funcionalidades relacionadas a avaliações de produtos por consumidores. A motivação foi aplicar o conhecimento dos conceitos aprendidos na sala de aula com um projeto prático.

# Pré-Requisitos

Para a utilização, é necessário ter instalado na sua máquina as seguintes ferramentas:

- PostgreSQL (versão >= 12): O sistema de gerenciamento do bancos de dados (SGBD) do componente. Para baixar, <a href="https://www.postgresql.org/download/">clique aqui</a>. A leitura da <a href="https://www.postgresql.org/docs/current/index.html">documentação</a> é recomendada.
- Python (versão >= 3): Linguagem de programação que tem como objetivo executar o <i>script</i> de geração de tuplas. Para baixar o Python, <a href="https://www.python.org/downloads/">clique aqui</a>. Recomendamos a leitura da <a href="https://docs.python.org/3/">documentação</a> da linguagem, caso tenha dúvidas.
- Psycopg2: Interface do Python com o postgres. Para instalação dessa interface, basta executar o seguinte comando:
```
pip install psycopg2
```

# Sobre

Inicialmente, o minimundo foi elaborado com o intuito de entender o domínio do componente. Como é um projeto voltado a avaliação de produtos por consumidores, a definição do minimundo é: 

Em um e-commerce, um consumidor pode realizar diversas compras de diversos produtos. Para cada compra, o consumidor pode avaliar os produtos adquiridos. O consumidor é identificado pelo CPF e dispõe de nome, data de nascimento, e-mail, senha e cidade. O produto é identificado por um id próprio e contém nome, preço, descrição e
categoria. A compra é identificada pelo consumidor, produto e a data de compra e dispõe de quantidade, identificador se a compra foi entregue, número de estrelas avaliada pelo consumidor e comentário.

Dessa forma, ficamos com o seguinte modelo relacional:

<p align="center">
  <img src="https://github.com/tales-lopes/oldfashion/blob/main/screenshots/diagrama_relacional.png" alt="Imagem do diagrama relacional do projeto">
</p>
Assim, o projeto tem as seguintes tabelas:

```
consumidor(cpf, nome_consumidor, data_nasc, email, senha, cidade);
produto(id, nome_produto, preco, descricao, categoria);
compra(produto_id, consumidor_cpf, data, quantidade, entregue, n_estrelas, comentario).
```

Após a definição do esquema relacional do projeto, duas consultas foram definidas. Foram elaboradas seguindo a especificação definida pela professora orientadora. 

## Consulta 1

**Enunciado**: Mostrar a média de notas de produtos de uma determinada categoria dentro de uma faixa de preços

**Campos de visualização do resultado**: ```nome_produto, preco, descricao, categoria, media```

**Campos de busca**: ```categoria (relativa), preco (absoluta)```

**Operadores de condição**:  ```categoria (ILIKE), preco (<=, >=)```

**SQL**:

```sql
SELECT nome_produto, preco, descricao, categoria, avg(n_estrelas) AS media
FROM produto
JOIN compra
  ON produto_id = id
WHERE categoria ILIKE <nome_categoria>
  AND preco BETWEEN <preco_min> AND <preco_max>
  AND entregue = true
GROUP BY id;
```
## Consulta 2

**Enunciado**: Recuperar todos os consumidores que possuem um histórico de compras similar a um dado consumidor e que morem na mesma cidade, ordenado por maior nível de similaridade.

**Campos de visualização do resultado**: ```nome_consumidor, cpf, nome_consumidor', cpf', cidade, qtd_produtos_similares```

**Campos de busca**: ```cidade (relativa), cpf_consumidor(absoluta).```

**Operadores de condição**:  ```cidade (ILIKE), cpf_consumidor(==)```

**SQL**:

```sql
SELECT  nome_consumidor, 
        cpf,
        (SELECT nome_consumidor FROM consumidor WHERE cpf = <cpf>),
        (SELECT cpf FROM consumidor WHERE cpf = <cpf>),
        cidade,
        COUNT(cpf) AS qtd_produtos_similares
FROM
        (SELECT DISTINCT nome_consumidor, cpf, produto_id, cidade
        FROM consumidor JOIN compra
        ON cpf = consumidor_cpf
        WHERE cpf <> <cpf> AND cidade ILIKE (SELECT cidade FROM consumidor
WHERE cpf=<cpf>)
        AND (produto_id) IN
            (SELECT produto_id
             FROM consumidor
             JOIN compra
                ON cpf=consumidor_cpf
             WHERE cpf = <cpf>)) AS resultado
GROUP BY nome_consumidor, cpf, cidade
ORDER BY qtd_produtos_similares DESC;
```

# Populando o banco de dados

A especificação define que é necessário um mínimo de 500 000 tuplas por tabela. Para isso, foi utilizada a linguagem ```Python``` com as bibliotecas ```pandas``` e ```psycopg2```. 

Antes da elaboração do script, é necessário que as tabelas estejam criadas no postgres.

```sql
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
```

Inicialmente, os seguintes módulos foram adicionados:

```python
#!pip install psycopg2
from random import randint, random
import psycopg2
import pandas as pd
print("Pacote carregado")
print("Tempo estimado: 25 minutos")
```

Depois disso, estruturas de apoio foram definidas com o intuito de auxiliar na geração de tuplas com valores diferentes:

```python
nome = ['Ana', 'Anathan', 'Alice', 'Anderson', 'Amanda', 'Antonio', 'Andreia', 'Alberto', 'Andre', 'Aline', 'Alexandre', 'Alessandra', 'Beatriz', 'Bruno', 'Bianca', 'Breno', 'Barbara', 'Bernardo', 'Bruna', 'Benedito', 'Caroline', 'Cesar', 'Carlos', 'Cecilia', 'Cristiane','Cristian', 'Danilo', 'Dalberto', 'Daniela', 'Douglas', 'Debora', 'Denis', 'Ester', 'Eduardo', 'Enzo', 'Fabricia', 'Fabio', 'Francisco', 'Francisca', 'Franciene', 'Fabricio', 'Fabiola', 'Fatima', 'Fernando', 'Fernanda', 'Fagner', 'Gabriela', 'Gabriel', 'Geovana', 'Gustavo', 'Guilherme', 'Jessica', 'Joao', 'Jonathan', 'Jenifer', 'James', 'Julio', 'Julia', 'Lauren', 'Luan', 'Luana', 'Laura', 'Leandro', 'Luis', 'Lucas', 'Lauana', 'Luiza', 'Luciana', 'Lucia', 'Matheus', 'Mariana', 'Maria', 'Mariano', 'Marcos', 'Maisa', 'Miguel', 'Michel', 'Mauricio', 'Michele', 'Milton', 'Nathalia', 'Nicolas', 'Nathan', 'Nicole', 'Otavio', 'Paulo', 'Paula', 'Pamela', 'Pedro', 'Roberta', 'Roberto', 'Rosane', 'Rosangela', 'Renan', 'Rafael', 'Sabrina', 'Samantha', 'Sandra', 'Sandro','Tales', 'Tatiana', 'Tatiane', 'Valeria', 'Viviane', 'Vitor', 'Valesca', 'Vanessa', 'Willian', 'Wilson', 'Wagner'  ]
cidade = ['Angra dos reis', 'Araras', 'Araraquara', 'Boituva', 'Belo horizonte', 'Campinas', 'Campina grande', 'Campos de jordão', 'Campo grande', 'Goiania', 'Garulhos', 'Itu', 'Itaporanga', 'Joinville', 'Juiz de Fora','Manaus', 'Marilia', 'Maua', 'Macapa', 'Mogi das Cruzes', 'Mossoró','Osasco', 'Praia Grande', 'Porto feliz', 'Porto alegre', 'Peruibe', 'Porto seguro', 'Rio de Janeiro', 'Recife', 'Salvador', 'Sao Luis', 'Sao Gonçalo', 'Sao José do Rio Preto', 'Serra', 'São Vicente','Santos', 'Santa Maria', 'Sete Lagoas', 'São Paulo', 'Sorocaba', 'Votorantim' ]
endereco = ['Rua Washington Luiz',
           'Rua Getúlio Vargas',
           'Rua Castro Alves',
           'Rua São José',
           'Rua Duque de Caxias',
           'Rua Santos Dumont',
           'Rua Sete de Setembro',
           'Rua Alagoas',
           'Rua Boa Vista',
           'Rua Rui Barbosa',
           'Rua Amazonas',
           'Rua Tiradentes',
           'Rua Blumenau',
           'Rua Santa Rita',
           'Rua Dom Pedro II',
           'Rua São Luiz',
           'Rua São Jorge',
           'Rua 15 de novembro',
           'Rua São Sebastião',
           'Rua José Bonifácio',
           'Rua Paraíba',
           'Rua São João']
letra = 'abcdefghijklmnopqrstuvwxyz'

nome_produto = ['Camiseta de Algodão', 'Camiseta Polo', 'Camisa Social', 'Calça Jeans', 'Calça Social', 'Calça Sarja', 'Calça Legging', 'Calça Jogger', 'Calça Flare', 'Vestido', 'Meia', 'Jaqueta', 'Cardigã', 'Moletom', 'Blazer', 'Blusa de lã', 'Blusa de linho', 'Camiseta esportiva', 'Shorts', 'Saia', 'Bermuda de Moletom', 'Bermuda de Sarja', 'Bermuda Tactel', 'Calça de moletom', 'Relógio', 'Brinco', 'Pulseira', 'Colar', 'Bracelete', 'Anél', 'Aliança',
                'Tenis esportivo', 'Tenis casual', 'Sapato social', 'Sapatênis', 'Salto', 'Sapatilha', 'Rasteirinha', 'Chinelo', 'Bota', 'Sandália', 
               'Bolsa de Viagem', 'Mala de Viagem','Travesseiro de Pescoço', 'Carregador portátil', 'Fone de ouvido',
               'Shampoo', 'Sabonete', 'Pasta de Dente', 'Toalha de banho', 'Toalha de rosto', 'Creme', 'Escova de dentes', 'Escova de cabelo' 'Roupão' ]
tipo_produto = ['Vestuário', 'Acessório', 'Calçados', 'Viagem', 'Higiene']
descricao_vestuario = ['Cor azul, tamanho: PP', 'Cor azul, tamanho: P', 'Cor azul, tamanho: M', 'Cor azul, tamanho: G', 'Cor azul, tamanho: GG','Cor preto, tamanho: PP', 'Cor preto, tamanho: P', 'Cor preto, tamanho: M', 'Cor preto, tamanho: G', 'Cor preto, tamanho: GG','Cor branco, tamanho: PP', 'Cor branco, tamanho: P', 'Cor branco, tamanho: M', 'Cor branco, tamanho: G', 'Cor branco, tamanho: GG','Cor vermelha, tamanho: PP', 'Cor vermelha, tamanho: P', 'Cor vermelha, tamanho: M', 'Cor vermelha, tamanho: G', 'Cor vermelha, tamanho: GG','Cor cinza, tamanho: PP', 'Cor cinza, tamanho: P', 'Cor cinza, tamanho: M', 'Cor cinza, tamanho: G', 'Cor cinza, tamanho: GG','Cor mostarda, tamanho: PP', 'Cor mostarda, tamanho: P' 'Cor mostarda, tamanho: M', 'Cor mostarda, tamanho: G', 'Cor mostarda, tamanho: GG','Cor lilás, tamanho: PP', 'Cor lilás, tamanho: P', 'Cor lilás, tamanho: M', 'Cor lilás, tamanho: G', 'Cor lilás, tamanho: GG','Cor roxo, tamanho: PP', 'Cor roxo, tamanho: P', 'Cor roxo, tamanho: M', 'Cor roxo, tamanho: G', 'Cor roxo, tamanho: GG']
descricao_acessorio=['Ouro', 'Banhado a Ouro' 'Banhado a Prata', 'Prata', 'Bronze', 'Latão', 'Alumínio', 'Ferro', 'Inox', 'Anti alérgico']
descricao_calcados=['Cor azul, tamanho: 35', 'Cor azul, tamanho: 36', 'Cor azul, tamanho: 37', 'Cor azul, tamanho: 38', 'Cor azul, tamanho: 39', 'Cor azul, tamanho: 40', 'Cor azul, tamanho: 41', 'Cor azul, tamanho: 42', 'Cor azul, tamanho: 43', 'Cor azul, tamanho: 44', 'Cor preto, tamanho: 35', 'Cor preto, tamanho: 36', 'Cor preto, tamanho: 37', 'Cor preto, tamanho: 38', 'Cor preto, tamanho: 39','Cor branco, tamanho: 35', 'Cor branco, tamanho: 36', 'Cor branco, tamanho: 37','Cor branco, tamanho: 38', 'Cor branco, tamanho: 39', 'Cor branco, tamanho: 40', 'Cor branco, tamanho: 41', 'Cor branco, tamanho: 42', 'Cor branco, tamanho: 43', 'Cor branco, tamanho: 44','Cor vermelha, tamanho: 35', 'Cor vermelha, tamanho: 36', 'Cor vermelha, tamanho: 37', 'Cor vermelha, tamanho: 38', 'Cor vermelha, tamanho: 39', 'Cor vermelha, tamanho: 40', 'Cor vermelha, tamanho: 41', 'Cor vermelha, tamanho: 42', 'Cor vermelha, tamanho: 43', 'Cor vermelha, tamanho: 44','Cor cinza, tamanho: 35', 'Cor cinza, tamanho: 36', 'Cor cinza, tamanho: 37', 'Cor cinza, tamanho: 38', 'Cor cinza, tamanho: 39', 'Cor cinza, tamanho: 40', 'Cor cinza, tamanho: 41', 'Cor cinza, tamanho: 42', 'Cor cinza, tamanho: 43', 'Cor cinza, tamanho: 44','Cor mostarda, tamanho: 35', 'Cor mostarda, tamanho: 36' 'Cor mostarda, tamanho: 37', 'Cor mostarda, tamanho: 38', 'Cor mostarda, tamanho: 39', 'Cor mostarda, tamanho: 40', 'Cor mostarda, tamanho: 41', 'Cor mostarda, tamanho: 42', 'Cor mostarda, tamanho: 43', 'Cor mostarda, tamanho: 44','Cor lilás, tamanho: 35', 'Cor lilás, tamanho: 36', 'Cor lilás, tamanho: 37', 'Cor lilás, tamanho: 38', 'Cor lilás, tamanho: 39', 'Cor lilás, tamanho: 40','Cor roxo, tamanho: 35', 'Cor roxo, tamanho: 36', 'Cor roxo, tamanho: 37', 'Cor roxo, tamanho: 38', 'Cor roxo, tamanho: 39', 'Cor roxo, tamanho: 40']
descricao_viagem=['Cor: preto', 'Cor: branco', 'Cor: cinza', 'Cor: vermelho', 'Cor: azul']
descricao_higiene=['Marca: Lux', 'Marca: MM', 'Marca: J&W', 'Marca: FX', 'Marca: Nature', 'Marca: Cristal', 'Marca: Diamond', 'Marca: Bela']

comentarios_positivos = ['Adorei', 'Gostei', 'Melhor escolha', 'Bom', 'Muito bom', 'Sensacional', 
                         'Fantástico', 'Não me arrependo', 'Podem comprar']
comentarios_negativos = ['Odiei', 'Não gostei', 'Pior Escolha', 'Ruim', 'Muito Ruim', 'Horrível',
                         'Horroroso', 'Eu me arrependi', 'Não comprem']
```

# Otimização de consultas

# Programação no banco de dados

# Controle de acesso

# Conceitos

# Autores

Em ordem alfabética:

<h4>Gabriel Viana Teixeira</h4>

- <a href="www.github.com/gabteixeira">GitHub</a>
- <a href="www.linkedin.com/gabteixeira">Linkedin</a>

<h4>Guilherme Pereira Fantini</h4>

- <a href="www.github.com/guipfi">GitHub</a>
- <a href="https://www.linkedin.com/in/guilhermefantini/">Linkedin</a>

<h4>Tales Baltar Lopes da Silva</h4>

- <a href="www.github.com/tales-lopes">GitHub</a>
- <a href="www.linkedin.com/tales-lopes">Linkedin</a>

