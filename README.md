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

# Geração de dados

A especificação define que é necessário um mínimo de 500 000 tuplas por tabela. Para isso, foi utilizada a linguagem ```Python``` com as bibliotecas ```pandas``` e ```psycopg2```. 

Antes da elaboração do script, é necessário que as tabelas estejam criadas no postgres.

## Adequação do banco de dados

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

## Geração dos valores

### Módulos utilizados

Inicialmente, os seguintes módulos foram adicionados:

```python
#!pip install psycopg2
from random import randint, random
import psycopg2
import pandas as pd
print("Pacote carregado")
print("Tempo estimado: 25 minutos")
```

### Estruturas de apoio

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

### Conexão com o banco de dados

Caso decida usar o código, troque os valores ```user``` e ```passoword``` para os seus usuários e senha, respectivamente.

```python
conexao_bd = psycopg2.connect(
    host="localhost",
    database="g1_loja",
    user="postgres",
    password="root")

cursor_principal = conexao_bd.cursor()
```

### Funções de apoio - tabela consumidor

As seguintes funções de apoio para a tabela consumidor foram criadas:

```python
#Utiliza o nome definido e o número da iteração para gerar o e-mail no formato @gmail.com.
def gerar_email(name, qtd):
    email = name.lower() + str(qtd) + "@gmail.com"
    return email

# Utiliza a estrutura letra definida anteriormente para gerar uma senha com 20 caracteres minúsculos randômicos.
def gerar_senha():
    senha = ''
    for i in range(0, 20):
        senha = senha + letra[randint(0, len(letra) - 1)]
    return senha

# Gerar o cpf pegando 11 números randômicos entre 0 e 9 e concatenando na variável cpf.
def gerar_cpf():
    cpf = ''
    for i in range(0, 11):
        cpf = cpf + str(randint(0, 9))
    return cpf

def gerar_telefone():
    telefone = '0'
    ddd = str(randint(11, 99))
    telefone = telefone + ddd + ' '
    for i in range(0, 10):
        if i == 5:
            telefone = telefone + '-'
        else:
            telefone = telefone + str(randint(0, 9))
    return telefone

def gerar_data():
    ano = randint(1940, 2001)
    mes = randint(1, 12)
    # O próximo bloco de condições é para saber qual intervalo de valores a variável dia pode assumir.
    # Levando em consideração o mês e se o ano é bissexto.
    if(mes == 1 | mes == 3 | mes == 5 | mes == 7 | mes == 8 | mes == 10 | mes == 12):    
        dia = randint(1, 31)
    elif(mes == 2 & 
         (ano % 400 == 0 | 
          ano % 4 == 0 & ano % 100 != 0)):
        dia = randint(1, 29)
    elif(mes == 2):
        dia = randint(1, 28)
    else:
        dia = randint(1, 30)
    # Depois é uma conversão da variável dia e mês para str, se for entre 1 e 9, adicionará um 0.
    if dia < 10:
        dia = '0' + str(dia)
    else:
        dia = str(dia)
        
    if mes < 10:
        mes = '0' + str(mes)
    else:
        mes = str(mes)
    # Concatenação dos valores
    data = dia + '/' + mes + '/' + str(ano)
    return data

def gerar_cidade():
    return cidade[randint(0, len(cidade) - 1)]

def gerar_nome():
    return nome[randint(0, len(nome) - 1)]

def gerar_endereco():
    endereco_final = endereco[randint(0, len(endereco) - 1)]
    numero = str(randint(0, 2000))
    endereco_final = endereco_final + ', ' + numero
    return endereco_final
```

### Funções de apoio - tabela compra

As seguintes funções são para apoiar na criação dos dados para a tabela Compra.

```python
"""## Funções de Apoio - Tabela Compra"""

def gerar_data_compra():
    ano = randint(2015, 2020)
    mes = randint(1, 12)
    # O próximo bloco de condições é para saber qual intervalo de valores a variável dia pode assumir.
    # Levando em consideração o mês e se o ano é bissexto.
    if(mes == 1 | mes == 3 | mes == 5 | mes == 7 | mes == 8 | mes == 10 | mes == 12):    
        dia = randint(1, 31)
    elif(mes == 2 & 
         (ano % 400 == 0 | 
          ano % 4 == 0 & ano % 100 != 0)):
        dia = randint(1, 29)
    elif(mes == 2):
        dia = randint(1, 28)
    else:
        dia = randint(1, 30)
    # Depois é uma conversão da variável dia e mês para str, se for entre 1 e 9, adicionará um 0.
    if dia < 10:
        dia = '0' + str(dia)
    else:
        dia = str(dia)
        
    if mes < 10:
        mes = '0' + str(mes)
    else:
        mes = str(mes)
    # Concatenação dos valores
    data = dia + '/' + mes + '/' + str(ano)
    return data

"""O método ```random()``` pega um valor entre 0 e 1, então para determinar o número de estrelas que é entre 0 e 5, é utilizado esse valor multiplicado por 5 com uma casa decimal de precisão."""

def gerar_estrelas():
    return (round(random() * 5, 1))

def gerar_comentario(n_estrelas):
    if n_estrelas > 3.5:
        return comentarios_positivos[randint(0, len(comentarios_positivos) - 1)]
    else:
        return comentarios_negativos[randint(0, len(comentarios_negativos) - 1)]

def gerar_entregue():
    if randint(0, 1) == 1:
        return True
    return False

def gerar_quantidade():
    return randint(1, 10)

def gerar_hora():
    hora = randint(0, 23)
    minuto = randint(0, 59)
    segundo = randint(0, 59)
    return str(hora) + ':' + str(minuto) + ':' + str(segundo)
```

### Adição das tuplas

```python

# Tabela consumidor

def adicionar_consumidor(cursor_principal):
    print("Adicionando 500000 consumidores, aguarde...")
    i=0
    while i < 500000:
        cpf = gerar_cpf()
        nome = gerar_nome()
        data_nasc = gerar_data()
        telefone = gerar_telefone()
        email = gerar_email(nome, i)
        senha = gerar_senha()
        endereco = gerar_endereco()
        cidade = gerar_cidade()
        try:
            cursor_principal.execute('INSERT INTO consumidor VALUES(%s, %s, %s, %s, %s, %s, %s, %s)', (cpf, nome, data_nasc, telefone, email, senha, endereco, cidade))
            conexao_bd.commit()
            i+=1
        except psycopg2.IntegrityError as err:
            # if duplicated, repeat the operation with other values
            conexao_bd.rollback()
	    
# Tabela produto	    
def adicionar_produto(cursor_principal):
  print("Adicionando 500000 produtos, aguarde...")
  i=0
  while i < 500000:
    produto_id=randint(0,len(nome_produto)-1)
    if produto_id < 24:
        descricao = descricao_vestuario[randint(0,len(descricao_vestuario)-1)]
        tipo_final = tipo_produto[0]
    elif produto_id < 31:
        descricao = descricao_acessorio[randint(0,len(descricao_acessorio)-1)]
        tipo_final = tipo_produto[1]
    elif produto_id <41:
        descricao = descricao_calcados[randint(0,len(descricao_calcados)-1)]
        tipo_final = tipo_produto[2]
    elif produto_id <46:
        descricao = descricao_viagem[randint(0,len(descricao_viagem)-1)]
        tipo_final = tipo_produto[3]    
    else:
        descricao=descricao_higiene[randint(0,len(descricao_higiene)-1)]
        tipo_final = tipo_produto[4]  
    try:
        cursor_principal.execute('INSERT INTO produto(nome_produto, preco, descricao, categoria) VALUES(%s, %s, %s, %s)', (nome_produto[produto_id], round(random() * 1000, 2), nome_produto[produto_id] + ' ' + descricao, tipo_final))
        conexao_bd.commit()
        i+=1
    except psycopg2.IntegrityError:
        # if duplicated, repeat the operation with other values
        conexao_bd.rollback()	    
	
# Tabela compra

def adicionar_compra(conexao_bd):
    
    cursor_compra = conexao_bd.cursor()
    
    cursor_compra.execute("SELECT cpf FROM consumidor")
    cpf_consumidor = cursor_compra.fetchall()
    cpf_consumidor = pd.DataFrame(cpf_consumidor, columns = ['cpf'])
    
    cursor_compra.execute("SELECT id FROM produto")
    id_produto = cursor_compra.fetchall()
    id_produto = pd.DataFrame(id_produto, columns = ['id'])
    
    print("Adicionando 500000 compras, aguarde...")
    i=0
    while i < 500000:
        cpf = cpf_consumidor['cpf'][randint(0, len(cpf_consumidor) - 1)]
        produto_id = id_produto['id'][randint(0, len(id_produto) - 1)]
        data = gerar_data_compra() + ' ' + gerar_hora()
        quantidade = gerar_quantidade()
        entregue = gerar_entregue()
        n_estrelas = gerar_estrelas()
        comentario = gerar_comentario(n_estrelas)
        try:
            cursor_compra.execute('INSERT INTO compra VALUES(%s, %s, %s, %s, %s, %s, %s)', (int(produto_id), cpf, data, quantidade, entregue, n_estrelas, comentario))
            conexao_bd.commit()
            i+=1
        except psycopg2.IntegrityError:
            # if duplicated, repeat the operation with other values
            conexao_bd.rollback()
```

### Execução do código

```python
adicionar_consumidor(cursor_principal)

adicionar_produto(cursor_principal)

adicionar_compra(conexao_bd)
```

### Desconexão com o banco de dados

```python
cursor_principal.close()
conexao_bd.close()
```

# Otimizações

Após a definição inicial das consultas em SQL, foi requisitada a otimização delas utilizando as técnicas aprendidas em sala de aula. Para isso, foi necessário analisar os planos de execução utilizando o comando ```sql EXPLAIN ANALYZE <consulta>```.

## Otimização da consulta 1

A primeira consulta apresentava um custo alto para calcular a média dos produtos. Dessa forma, a primeira proposta de otimização foi alterar o esquema da tabela ```Produto```, assim foram adicionadas as colunas ```media``` (média de avaliação do produto) e ```vendidos``` (quantidade de vezes que o produto foi vendido).

```sql
ALTER TABLE produto ADD media real;
ALTER TABLE produto ADD vendidos int;
```

Para isso, foi necessário atualizar o banco de dados, assim cada produto terá sua atual média e quantidade de vendas.

### Atualização da média

```sql
UPDATE produto
SET media = compra.media_produto
FROM (	SELECT produto_id, avg(n_estrelas) as media_produto 
	FROM compra 
	GROUP BY produto_id) AS compra
WHERE compra.produto_id = id;
```

### Atualização dos vendidos

```sql
UPDATE produto
SET vendidos = compra.num_vendidos
FROM (	SELECT produto_id, count(*) as num_vendidos 
	FROM compra 
	GROUP BY produto_id) AS compra
WHERE compra.produto_id=produto.id

```

Após isso, um índice sobre a coluna ```preco``` foi criado, uma vez que o plano de execução apresentou uma busca sequencial sob esse atributo.

```sql
CREATE INDEX preco_index ON produto(preco)
```

Por último, a consulta foi alterada para retratar as mudanças idealizadas.

```sql
SELECT nome_produto, preco, descricao, categoria, media
FROM produto
WHERE 	categoria ILIKE <categoria>
	AND preco BETWEEN <preco_min> AND <preco_max>
	AND media IS NOT NULL
```

A tabela seguinte mostra o tempo de execução (em ms) da consulta na máquina dos três autores do projeto e a diferença (em %) entre a versão inicial e a otimizada.

|    |      Consulta Inicial      |  Consulta Otimizada |  Diferença (%) |
|----------|:-------------:|:------:|:------:|
| Tempo de Execução (Gabriel) 	|  392,359 	| 71,347 | 81,82% |
| Tempo de Execução (Guilherme) |    2319,933   |   73,377 |   96,83% |
| Tempo de Execução (Tales)  	| 5201,979 	|    390,461 |    92,49% |

## Otimização da consulta 2

Como a consulta necessita encontrar todos os produtos comprados por cada consumidor e, assim, comparar com a lista de produtos compradas pelo cpf de entrada, então a proposta de otimização é ter um índice composto que envolve o cpf e os produtos comprados, facilitando a contagem, que é a operação mais custosa dessa consulta.

```sql
CREATE INDEX compra(consumidor_cpf, produto_id)
```

Além disso, colocamos todas as condições na cláusula ```WHERE``` antes de realizar a junção.

```sql
SELECT 	nome_consumidor,
	cpf,
	(SELECT nome_consumidor FROM consumidor WHERE cpf=<cpf>),
	(SELECT cpf FROM consumidor WHERE cpf=<cpf>),
	cidade,
	COUNT(cpf) AS qtd_produtos_similares
FROM
	(SELECT DISTINCT nome_consumidor, cpf, produto_id, cidade
	 FROM consumidor
	 JOIN compra
	 ON cpf=consumidor_cpf
	    AND cpf <> <cpf>
	    AND cidade ILIKE (SELECT cidade FROM consumidor WHERE cpf=<cpf>)
	    AND (produto_id) IN
		(SELECT produto_id
		 FROM consumidor
		 JOIN compra
		 ON cpf=consumidor_cpf
		    AND cpf=<cpf>)) AS resultado
GROUP BY nome_consumidor, cpf, cidade
ORDER BY qtd_produtos_similares DESC;
```

A tabela seguinte mostra o tempo de execução (em ms) da versão inicial e otimizada. Também mostra a diferença entre elas (em %).

|    |      Consulta Inicial      |  Consulta Otimizada |  Diferença (%) |
|----------|:-------------:|:------:|:------:|
| Tempo de Execução (Gabriel) 	|  51,693 	| 3,587 | 93,061% |
| Tempo de Execução (Guilherme) |    1966,338   |   0,846 |   99,95% |
| Tempo de Execução (Tales)  	| 2501,300 	|    1,069 |    99,957% |


# Programação no banco de dados

Para a segunda iteração do projeto, foi requisitado a criação de stored procedures sobre as consultas.

## Consulta 1

A função refere-se à primeira consulta: “Mostrar a média de notas de produtos de uma determinada categoria dentro de uma faixa de preços”. A situação de uso desse tipo de função pode ser imaginada na visão do consumidor, que está em busca de consumir os produtos com maior nota média .Com isso, ela recebe como parâmetros, três valores: 

- $1, do tipo texto, que recebe o nome da categoria. Na implementação da função, temos que a busca por esse parâmetro é relativo, por isso se utiliza “categoria ILIKE $1”. 

- $2 e $3, são do tipo double e são referentes a faixa de preço do produto, de tal forma que o preço esteja entre $2 e $3. Na implementação da função, temos que a busca por esse parâmetro é absoluto, por isso se utiliza “preco BETWEEN $2 AND $3”.

A saída dessa função é uma tabela, que contém o nome do produto, o preço, descrição do produto, categoria do produto e média de preço.

```sql
CREATE OR REPLACE FUNCTION media_notas(text, double precision, double precision)
RETURNS TABLE(name varchar, price double precision, description text, category varchar, average real) AS $$
BEGIN
	RETURN QUERY SELECT nome_produto, preco, descricao, categoria, media
		     FROM produto
		     WHERE categoria ILIKE $1
			AND preco BETWEEN $2 AND $3
			AND media IS NOT NULL;
END;
$$ LANGUAGE plpgsql;
```

## Consulta 2

A função refere-se à segunda consulta: “Recuperar todos os consumidores que possuem um histórico de compras similar a um dado consumidor e que morem na mesma cidade, ordenado por maior nível de similaridade”. A situação de uso desse tipo de função pode ser imaginada em uma possível análise de dados, no qual é possível por exemplo ver os perfis dos usuários que consomem os mesmos tipos de produtos. Com isso, ela recebe como parâmetros, dois valores:

- $1, do tipo texto, que recebe o cpf do usuário que terá as suas compras comparadas com os demais usuários (Note que o esse parâmetro recebe o cpf como texto, pois em nossa tabela, a coluna cpf é do tipo VARCHAR). Na implementação da função, temos que a busca por esse parâmetro é absoluta, por isso se utiliza “cpf = $1”.

- $2, do tipo texto, que recebe o nome da cidade do consumidor que terá as suas compras comparadas com os demais usuários como parâmetro. Na implementação da função, temos que a busca por esse parâmetro é relativa, por isso se utiliza “cidade ILIKE $2”.

```sql
CREATE OR REPLACE FUNCTION consumidores_semelhantes(text,text)
RETURNS TABLE (consumidor_semelhante varchar, cpf_semelhante varchar, nome_consumidor_procurado varchar, cpf1 varchar, cidade_origem varchar, qtd_produtos_similares bigint) AS $$
BEGIN
	RETURN QUERY SELECT nome_consumidor,
			    cpf,
			    (SELECT nome_consumidor FROM consumidor WHERE cpf=$1),
			    (SELECT cpf FROM consumidor WHERE cpf=$1),
			    cidade,
			    COUNT(cpf) AS qtd_produtos_similares
		      FROM
			   (SELECT DISTINCT nome_consumidor, cpf, produto_id, cidade
  			    FROM consumidor
			    JOIN compra
			    ON cpf=consumidor_cpf
				AND cpf <> $1
				AND cidade ILIKE (SELECT DISTINCT cidade FROM consumidor WHERE cidade ILIKE $2 )
			    AND (produto_id) IN
				(SELECT produto_id
				FROM consumidor
				JOIN compra
				ON cpf=consumidor_cpf
			    AND cpf=$1)) AS resultado
		      GROUP BY nome_consumidor, cpf, cidade
		      ORDER BY qtd_produtos_similares DESC;
END;
$$ LANGUAGE plpgsql;
```

# Controle de acesso

Um dos aspectos mais importantes para manter a segurança dos dados é definir um controle de acesso de usuários. Assim, o respectivo usuário tem acesso somente aos dados relevantes para o seu uso. 

No contexto do e-commerce e levando em conta o tema “Avaliação de produtos por consumidores”, os seguintes usuários foram considerados.

- Administrador: usuário dono do banco de dados, é o usuário que tem mais controle sobre o sistema.
- Gerente: usuário responsável por supervisionar o usuário SAC-BI-Marketing, por isso tem mais autorizações no sistema.
- Desenvolvedor: usuário responsável por fazer a manutenção da página da loja, ou seja, entre as suas atribuições estão: cadastrar novos produtos, atualizar os preços e remover produtos que não são mais vendidos.
- SAC-BI-Marketing: usuário padrão que tem autorização básica (somente leitura) nas tabelas do banco de dados.
- Consumidor: usuário que realiza compras no e-commerce.

A figura seguinte mostra o esquema de concessão de privilégios.

<img src="https://github.com/tales-lopes/oldfashion/blob/main/screenshots/concessao-grafo%20de%20concessao.png">

A próxima figura mostra como seria a conexão entre o banco de dados e uma aplicação.

<img src="https://github.com/tales-lopes/oldfashion/blob/main/screenshots/concessao-conexao.png">

Para mais informações sobre o projeto, leia o <a href="https://github.com/tales-lopes/oldfashion/blob/main/docs/Relat%C3%B3rio.pdf">relatório final</a>.

# Conceitos

- Definição de minimundo.
- Criação de consultas.
- Geração de tuplas utilizando Python.
- Análise de plano de execução.
- Otimização de consultas.
- Controle de acesso.

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

