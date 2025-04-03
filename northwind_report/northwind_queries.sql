CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT * FROM categories

SELECT * FROM customer_customer_demo

SELECT * FROM customer_demographics

SELECT * FROM customers
WHERE country = 'USA'

SELECT * FROM employee_territories

SELECT * FROM employees

SELECT * FROM order_details

SELECT * FROM orders

SELECT * FROM products

SELECT * FROM region

SELECT * FROM shippers

SELECT * FROM suppliers

SELECT * FROM territories

SELECT * FROM us_states


-- Quantidade de pedidos por país

SELECT
    c.country,
	o.ship_country,
    COUNT(o.customer_id) AS num_orders
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY 1, 2
ORDER BY num_orders DESC

-- Quantidades de pedidos por cliente

SELECT c.customer_id, c.company_name, c.country, COUNT(o.customer_id) AS qt_orders
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.company_name, c.country
ORDER BY qt_orders DESC

-- Quantidades de pedidos por ano, país

SELECT o.ship_country, EXTRACT(YEAR FROM o.order_date) AS year_orders, COUNT(o.order_id)
FROM orders o
GROUP BY o.ship_country, EXTRACT(YEAR FROM o.order_date)

SELECT EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) AS year_orders, COUNT(o.order_id)
FROM orders o
WHERE EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) = 1998
GROUP BY 1


-- Todos os pedidos foram destinados para o mesmo país de origem

SELECT c.country, o.ship_country
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE c.country != o.ship_country

-- Produtos mais vendidos em cada pais, ano

WITH sold_products_summary AS (
	SELECT
		p.product_id, 
		c.category_name,
		p.product_name, 
		p.discontinued,
		o.ship_country,
		EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) AS year_orders,
		(SUM(d.quantity)) AS qt_sold
	FROM categories c
	INNER JOIN products p ON c.category_id = p.category_id
	INNER JOIN order_details d ON p.product_id = d.product_id
	INNER JOIN orders o ON d.order_id = o.order_id
	GROUP BY p.product_id, c.category_name, p.product_name, p.discontinued, o.ship_country, EXTRACT(YEAR FROM CAST(o.order_date AS DATE))
	ORDER BY qt_sold DESC
)
SELECT SUM(qt_sold) FROM sold_products_summary
WHERE ship_country = 'Ireland' AND category_name = 'Beverages'

WITH orders_data_summary AS (
	SELECT 
	    o.order_id,
	    EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) AS year_orders,
	    o.ship_country,
		o.ship_via,
	    d.product_id,
	    p.product_name,
	    c.category_name, 
	    d.quantity AS qt_sold,
	    (d.unit_price * d.quantity) - d.discount  AS total_value
	FROM orders o
	JOIN order_details d ON o.order_id = d.order_id
	JOIN products p ON d.product_id = p.product_id
	JOIN categories c ON p.category_id = c.category_id
)

SELECT DISTINCT order_id
FROM orders_data_summary

-- Quantidade de pedidos e valor de ticket total e ticket médio por ano e país

WITH average_ticket_summary AS (
	SELECT
	    EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) AS years_orders,
	    c.country,
	    COUNT(o.order_id) AS num_orders,
	    SUM(d.unit_price * d.quantity - d.discount) / COUNT(o.order_id) AS average_ticket,
	    COALESCE (LEAD(SUM(d.unit_price * d.quantity - d.discount) / COUNT(o.order_id)) 
			OVER (PARTITION BY c.country ORDER BY EXTRACT(YEAR FROM CAST(o.order_date AS DATE))), 0) AS next_year_average_ticket
	FROM customers c
	JOIN orders o ON c.customer_id = o.customer_id
	JOIN order_details d ON o.order_id = d.order_id
	GROUP BY years_orders, c.country
	ORDER BY c.country, years_orders
) 

SELECT 
	a.*,
	CASE 
		WHEN a.next_year_average_ticket != 0 THEN ((a.next_year_average_ticket - a.average_ticket)/a.average_ticket)*100
		ELSE 0
	END AS increase_or_decrease
FROM average_ticket_summary a

-- Receita gerada ao longo do tempo por cada cliente

SELECT
    c.customer_id,
	c.company_name,
	c.country,
    SUM(CASE 
        WHEN EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) = 1996 
        THEN (d.unit_price * d.quantity) - d.discount 
        ELSE 0 
    END) AS _1996_,
	SUM(CASE 
        WHEN EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) = 1997 
        THEN (d.unit_price * d.quantity) - d.discount 
        ELSE 0 
    END) AS _1997_,
	SUM(CASE 
        WHEN EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) = 1998
        THEN (d.unit_price * d.quantity) - d.discount 
        ELSE 0 
    END) AS _1998_,
	SUM((d.unit_price * d.quantity) - d.discount) AS total_ticket
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details d ON o.order_id = d.order_id
GROUP BY c.customer_id, c.company_name, c.country
ORDER BY total_ticket DESC

SELECT 
    p.*, 
    t.total_ticket 
FROM (
    SELECT * FROM crosstab(
        'SELECT 
            c.customer_id::TEXT,
            EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) AS ano, 
            SUM((d.unit_price * d.quantity) - d.discount) AS total_ticket
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        JOIN order_details d ON o.order_id = d.order_id
        GROUP BY c.customer_id, ano
        ORDER BY c.customer_id, ano',
        
        'VALUES (1996), (1997), (1998)'
    ) 
    AS pivot_table(customer_id TEXT, _1996_ NUMERIC, _1997_ NUMERIC, _1998_ NUMERIC) -- Garante que seja texto
) p
JOIN (
    SELECT 
        c.customer_id::TEXT,
        SUM((d.unit_price * d.quantity) - d.discount) AS total_ticket
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_details d ON o.order_id = d.order_id
    GROUP BY c.customer_id
) t ON p.customer_id = t.customer_id
ORDER BY t.total_ticket DESC



-- Quantidade de pedidos ao longo do tempo por cada cliente

WITH num_orders_years_summary AS (
	SELECT
	    c.customer_id,
	    c.company_name,
	    c.country,
	    COUNT(CASE WHEN EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) = 1996  THEN o.customer_id END) AS _1996_,
	    COUNT(CASE WHEN EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) = 1997  THEN o.customer_id END) AS _1997_,
	    COUNT(CASE WHEN EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) = 1998  THEN o.customer_id END) AS _1998_,
	    COUNT(o.order_id) AS total_num_orders
	FROM customers c
	JOIN orders o ON c.customer_id = o.customer_id
	GROUP BY c.customer_id, c.company_name, c.country
	ORDER BY total_num_orders DESC
)

SELECT country, SUM(total_num_orders) AS total_num_orders_country
FROM num_orders_years_summary
GROUP BY country
HAVING country = 'Austria'

-- Quantidade de pedidos feitos com desconto ou sem desconto

SELECT
	COUNT(CASE WHEN discount > 0 THEN 1 END) AS orders_with_discount,
	COUNT(CASE WHEN discount = 0 THEN 1 END) AS orders_without_discount
FROM order_details d

-- Clientes que tiveram pedidos atrasados

SELECT 
    c.customer_id, 
    c.company_name, 
	o.ship_via,
    COUNT(o.customer_id) AS qt_orders_general,
    COUNT(CASE 
        WHEN CAST(shipped_date AS DATE) > CAST(required_date AS DATE) THEN 1 ELSE NULL 
    END) AS qt_orders_delayed,
	COALESCE(ROUND(AVG(CASE 
        WHEN CAST(shipped_date AS DATE) > CAST(required_date AS DATE) THEN CAST(shipped_date AS DATE) - CAST(required_date AS DATE) 
    END)),0) AS avg_days_delayed
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id IN (
    SELECT DISTINCT customer_id FROM orders
    WHERE CAST(shipped_date AS DATE) > CAST(required_date AS DATE)
)
GROUP BY c.customer_id, c.company_name, o.ship_via
ORDER BY qt_orders_general DESC

-- Transportadoras que atrasaram pedidos

SELECT * FROM shippers
SELECT * FROM orders

SELECT 
    s.shipper_id, 
    s.company_name, 
	o.ship_country,
	EXTRACT(YEAR FROM CAST(o.order_date AS DATE)) AS year_orders,
    COUNT(o.ship_via) AS qt_orders_general,
    COUNT(CASE 
        WHEN CAST(o.shipped_date AS DATE) > CAST(o.required_date AS DATE) 
        THEN 1 ELSE NULL 
    END) AS qt_delayed_orders,
	COALESCE(ROUND(AVG(CASE 
        WHEN CAST(shipped_date AS DATE) > CAST(required_date AS DATE) THEN CAST(shipped_date AS DATE) - CAST(required_date AS DATE) 
    END)),0) AS avg_days_delayed
FROM shippers s
INNER JOIN orders o ON s.shipper_id = o.ship_via
GROUP BY s.shipper_id, s.company_name, s.phone, o.ship_country, EXTRACT(YEAR FROM CAST(o.order_date AS DATE))
HAVING ship_country = 'Austria'
	
