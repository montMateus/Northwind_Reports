-- Average Ticket

--- Total Revenue
WITH total_revenue_summary AS (
	SELECT SUM((d.unit_price * d.quantity) - d.discount) AS total_revenue
	FROM orders o
	JOIN order_details d ON o.order_id = d.order_id
),

--- General Average Ticket

WITH total_revenue_summary AS (
	SELECT SUM((d.unit_price * d.quantity) - d.discount) AS total_revenue
	FROM orders o
	JOIN order_details d ON o.order_id = d.order_id
),

total_orders AS (
	SELECT COUNT(DISTINCT o.order_id) AS total_num_orders
	FROM orders o
)

SELECT 
    (SELECT total_revenue FROM total_revenue_summary) / 
    (SELECT total_num_orders FROM total_orders) AS general_avg_ticket

-- Costumers

--- Total Num of Orders By Customer Troughout the Years

WITH total_orders_by_costumer_year AS (
    SELECT 
        c.customer_id, 
		EXTRACT(YEAR FROM o.order_date) AS year_order,
        COUNT(o.customer_id) AS total_num_orders_year
    FROM customers c
	JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, EXTRACT(YEAR FROM o.order_date)
)
SELECT 
    c.customer_id,
	c.country,
    EXTRACT(YEAR FROM o.order_date) AS year_order,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 1 THEN 1 END) AS january,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 2 THEN 1 END) AS february,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 3 THEN 1 END) AS march,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 4 THEN 1 END) AS april,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 5 THEN 1 END) AS may,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 6 THEN 1 END) AS june,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 7 THEN 1 END) AS july,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 8 THEN 1 END) AS august,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 9 THEN 1 END) AS september,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 10 THEN 1 END) AS october,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 11 THEN 1 END) AS november,
    COUNT(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 12 THEN 1 END) AS december,
    t.total_num_orders_year
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN total_orders_by_costumer_year t ON c.customer_id = t.customer_id AND EXTRACT(YEAR FROM o.order_date) = t.year_order
GROUP BY c.customer_id, c.country, EXTRACT(YEAR FROM o.order_date), t.total_num_orders_year
ORDER BY c.customer_id

	
SELECT * FROM orders WHERE customer_id = 'ANATR'

--- Total Revenue By Costumer Troughout the Years

WITH total_revenue_by_customer AS (
    SELECT 
        c.customer_id, 
        EXTRACT(YEAR FROM o.order_date) AS year_order,
        SUM((d.unit_price * d.quantity) - d.discount) AS total_revenue_year
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_details d ON o.order_id = d.order_id
    GROUP BY c.customer_id, EXTRACT(YEAR FROM o.order_date)
), a AS (
	SELECT 
	    c.customer_id,
	    c.country,
	    EXTRACT(YEAR FROM o.order_date) AS year_order,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 1 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS january,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 2 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS february,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 3 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS march,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 4 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS april,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 5 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS may,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 6 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS june,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 7 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS july,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 8 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS august,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 9 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS september,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 10 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS october,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 11 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS november,
	    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 12 THEN (d.unit_price * d.quantity) - d.discount ELSE 0 END)::numeric, 2) AS december,
	    t.total_revenue_year
	FROM customers c
	JOIN orders o ON c.customer_id = o.customer_id
	JOIN order_details d ON o.order_id = d.order_id
	JOIN total_revenue_by_customer t ON c.customer_id = t.customer_id AND EXTRACT(YEAR FROM o.order_date) = t.year_order
	GROUP BY c.customer_id, c.country, EXTRACT(YEAR FROM o.order_date), t.total_revenue_year
	ORDER BY c.customer_id, year_order
)

--- Top 10 Revenue from Customers annualy

SELECT c.customer_id, c.company_name, ROUND(SUM(total_revenue_year)::numeric, 2) AS total_revenue_year_ranked
FROM a
JOIN customers c ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.company_name
ORDER BY total_revenue_year_ranked DESC
LIMIT 10

-- Top 10 Revenue from Customers

SELECT * FROM order_details

SELECT 
    c.customer_id, 
    c.company_name, 
    ROUND(SUM((d.quantity * d.unit_price) - d.discount)::numeric, 2) AS total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details d ON o.order_id = d.order_id
GROUP BY c.customer_id, c.company_name
ORDER BY total_revenue DESC
LIMIT 10

-- Top 10 Revenue from Products

SELECT 
    p.product_id, 
    p.product_name, 
    ROUND(SUM((d.quantity * d.unit_price) - d.discount)::numeric, 2) AS total_revenue
FROM products p
JOIN order_details d ON p.product_id = d.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10

-- Products

SELECT * FROM Products

--- Most sold products

SELECT p.product_id, p.product_name, COUNT(d.product_id) AS num_orders
FROM orders o
JOIN order_details d ON o.order_id = d.order_id
JOIN products p ON d.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY num_orders DESC
LIMIT 10

--- Less sold products

SELECT p.product_id, p.product_name, COUNT(d.product_id) AS num_orders
FROM orders o
JOIN order_details d ON o.order_id = d.order_id
JOIN products p ON d.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY num_orders
LIMIT 10

--- Inactive Customers

WITH active_customers AS (
    SELECT DISTINCT 
        o.customer_id, 
        EXTRACT(YEAR FROM o.order_date) AS year, 
        EXTRACT(MONTH FROM o.order_date) AS month
    FROM orders o
)
SELECT 
    c.customer_id, 
    c.company_name, 
    y.year, 
    y.month
FROM customers c
CROSS JOIN (
    SELECT DISTINCT EXTRACT(YEAR FROM order_date) AS year, EXTRACT(MONTH FROM order_date) AS month 
    FROM orders
) y
LEFT JOIN active_customers a 
    ON c.customer_id = a.customer_id 
    AND y.year = a.year 
    AND y.month = a.month
WHERE a.customer_id IS NULL  
ORDER BY c.customer_id, y.year, y.month

-- Inactive Costumers

SELECT c.customer_id, c.company_name
FROM customers c
WHERE c.customer_id NOT IN
(SELECT customer_id FROM orders WHERE EXTRACT(YEAR FROM order_date) = 1996 OR EXTRACT(MONTH FROM order_date) = 2)

-- Average delivery time by shipper

SELECT 
    s.shipper_id, 
    s.company_name, 
    AVG(EXTRACT(EPOCH FROM (o.shipped_date - o.order_date)) / 86400) AS avg_delivery_time
FROM shippers s
JOIN orders o ON s.shipper_id = o.ship_via
WHERE o.shipped_date IS NOT NULL
GROUP BY s.shipper_id, s.company_name

-- Average freight by shipper

SELECT 
    s.shipper_id, 
    s.company_name, 
    ROUND(AVG(o.freight)::numeric, 2) AS avg_freight
FROM shippers s
JOIN orders o ON s.shipper_id = o.ship_via
WHERE o.shipped_date IS NOT NULL
GROUP BY s.shipper_id, s.company_name

-- Distinct delivered products by shipper

SELECT 
    s.shipper_id, 
    s.company_name, 
    COUNT(DISTINCT d.product_id)
FROM shippers s
JOIN orders o ON s.shipper_id = o.ship_via
JOIN order_details d ON o.order_id = d.order_id
GROUP BY s.shipper_id, s.company_name

	