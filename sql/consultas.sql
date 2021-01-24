-- Primeira consulta inicial
SELECT nome_produto, preco, descricao, categoria, avg(n_estrelas) as media
FROM produto 
JOIN compra 
ON produto_id = id 
WHERE categoria ILIKE <nome_categoria> 
AND preco BETWEEN <preco_min> AND <preco_max>
AND entregue = true 
GROUP BY id;

-- Segunda consulta inicial
SELECT nome_consumidor, 
 	   cpf, 
	   (SELECT nome_consumidor FROM consumidor WHERE cpf = <cpf>),
	   (SELECT cpf FROM consumidor WHERE cpf = <cpf>), 
	   cidade, 
	   COUNT(cpf) AS qtd_produtos_similares 
FROM 
	(SELECT DISTINCT nome_consumidor, cpf, produto_id, cidade 
	FROM consumidor JOIN compra 
	ON cpf = consumidor_cpf 
	WHERE cpf <> <cpf> AND cidade ILIKE (SELECT cidade FROM consumidor WHERE cpf=<cpf>) 
	AND (produto_id) IN
		(SELECT produto_id 
		 FROM consumidor 
		 JOIN compra 
		 ON cpf=consumidor_cpf 
		 WHERE cpf = <cpf>)) AS resultado 
GROUP BY nome_consumidor, cpf, cidade 
ORDER BY qtd_produtos_similares DESC;
		 
-- Criação do índice sobre a coluna preco da tabela produto
CREATE INDEX preco_index ON produto(preco)

-- Consulta 1 otimizada
SELECT nome_produto, preco, descricao, categoria, media
FROM produto 
WHERE
categoria ILIKE <categoria>
AND preco BETWEEN <preco_min> AND <preco_max>
AND media IS NOT NULL

-- Criação do índice
CREATE INDEX ON compra(consumidor_cpf, produto_id)

-- Consulta 2 otimizada
SELECT nome_consumidor,
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