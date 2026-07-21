-- =============================================
-- PROJETO: Análise E-commerce Olist
-- AUTOR: Vitor Fernandes
-- DATA: 2025
-- =============================================


-- Q1: Faturamento e volume de pedidos por estado (top 10)
-- Insight: SP concentra quase 3x mais faturamento que RJ (2º lugar)
SELECT 
    c.customer_state                    AS estado,
    ROUND(SUM(oi.price))                AS faturamento_total,
    COUNT(DISTINCT o.order_id)          AS total_pedidos
FROM order_items AS oi
JOIN orders    AS o ON oi.order_id   = o.order_id
JOIN customers AS c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY faturamento_total DESC
LIMIT 10;


-- Q2: Top 10 categorias por faturamento
-- Insight: beleza_saude lidera com 1.25M, seguida de relogios_presentes
SELECT 
    ct.product_category_name            AS categoria,
    ROUND(SUM(oi.price), 2)             AS faturamento_total
FROM category_translation AS ct
JOIN products    AS p  ON ct.product_category_name = p.product_category_name
JOIN order_items AS oi ON p.product_id             = oi.product_id
GROUP BY ct.product_category_name
ORDER BY faturamento_total DESC
LIMIT 10;


-- Q3: Taxa de cancelamento por categoria (top 10)
-- Insight: pc_gamer tem 11% mas só 9 pedidos — amostra pequena, pouco confiável
WITH contagem AS (
    SELECT 
        p.product_category_name,
        COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END) AS cancelados,
        COUNT(o.order_id)                                        AS total
    FROM orders      AS o
    JOIN order_items AS oi ON o.order_id   = oi.order_id
    JOIN products    AS p  ON oi.product_id = p.product_id
    GROUP BY p.product_category_name
)
SELECT 
    product_category_name               AS categoria,
    cancelados,
    total,
    ROUND(CAST(cancelados AS FLOAT) / total * 100, 2) AS taxa_cancelamento
FROM contagem
ORDER BY taxa_cancelamento DESC
LIMIT 10;


-- Q4: Ranking de estados por faturamento (todos os estados)
-- Insight: SP em 1º, GO em 9º com 294k
SELECT 
    c.customer_state                                        AS estado,
    ROUND(SUM(oi.price), 2)                                 AS faturamento,
    RANK() OVER (ORDER BY SUM(oi.price) DESC)               AS posicao
FROM order_items AS oi
JOIN orders    AS o ON oi.order_id   = o.order_id
JOIN customers AS c ON o.customer_id = c.customer_id
GROUP BY c.customer_state;


-- Q5: Tempo médio de entrega em dias por estado (top 10 mais lentos)
-- Insight: estados do Norte chegam a 29 dias — quase 3x mais que SP
SELECT 
    c.customer_state                                                AS estado,
    ROUND(AVG(
        JULIANDAY(o.order_delivered_customer_date) - 
        JULIANDAY(o.order_purchase_timestamp)
    ), 1)                                                           AS tempo_medio_dias
FROM orders    AS o
JOIN customers AS c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
AND   o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY tempo_medio_dias DESC
LIMIT 10;


-- Q6: Top 10 vendedores por faturamento
-- Insight: top vendedor fatura 229k — quase o dobro do 10º colocado
SELECT 
    s.seller_id,
    ROUND(SUM(oi.price), 2) AS faturamento_total
FROM sellers     AS s
JOIN order_items AS oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id
ORDER BY faturamento_total DESC
LIMIT 10;


-- Q7: Avaliação média por estado do vendedor
-- Insight: GO em 4º com 4.25 e 518 avaliações — volume representativo
WITH avaliacoes AS (
    SELECT 
        s.seller_state,
        AVG(orv.review_score)       AS media_avaliacoes,
        COUNT(orv.review_id)        AS total_avaliacoes
    FROM order_reviews AS orv
    JOIN order_items   AS oi ON orv.order_id  = oi.order_id
    JOIN sellers       AS s  ON oi.seller_id  = s.seller_id
    WHERE orv.review_score IS NOT NULL
    GROUP BY s.seller_state
)
SELECT 
    seller_state                        AS estado,
    ROUND(media_avaliacoes, 2)          AS media_avaliacao,
    total_avaliacoes
FROM avaliacoes
ORDER BY media_avaliacao DESC;


-- Q8: Clientes recorrentes (mais de 1 pedido)
-- Insight: apenas 2997 de 99k clientes são recorrentes — taxa de recompra < 3%
WITH pedidos_por_cliente AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS total_pedidos
    FROM orders    AS o
    JOIN customers AS c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT COUNT(*) AS clientes_recorrentes
FROM pedidos_por_cliente
WHERE total_pedidos >= 2;


-- Q9: Faturamento mensal
-- Insight: crescimento consistente de 120k (jan/2017) para ~1M (nov/2017)
SELECT 
    STRFTIME('%Y-%m', o.order_purchase_timestamp) AS mes,
    ROUND(SUM(oi.price), 2)                        AS faturamento_total
FROM orders      AS o
JOIN order_items AS oi ON o.order_id = oi.order_id
GROUP BY mes
ORDER BY mes;