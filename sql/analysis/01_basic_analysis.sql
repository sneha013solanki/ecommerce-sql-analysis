USE ecommerce_analytics ;

-- BASIC
SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM products) AS total_products,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM order_items) AS total_order_items,
    (SELECT COUNT(*) FROM returns) AS total_returns,
    (SELECT COUNT(*) FROM reviews) AS total_reviews;

-- TOTAL REVENUE
SELECT SUM(p.price * oi.quantity) AS total_revenue FROM products p JOIN order_items oi 
ON p.product_id = oi.product_id JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Delivered' ; 

-- AVG ORDER VALUE
WITH avg_order_value as(
SELECT o.order_id, SUM(p.price * oi.quantity) AS total_revenue FROM products p JOIN order_items oi 
ON p.product_id = oi.product_id JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Delivered' GROUP BY o.order_id )
SELECT avg(total_revenue) FROM avg_order_value;

-- TOTAL NUMBER OF DELIEVERED ORDER 
SELECT COUNT(*) FROM orders WHERE status =  'Delivered';

-- TOTAL NUMBER OF CANCELLED ORDER 
SELECT COUNT(*) FROM orders WHERE status =  'Cancelled';

-- TOTAL CANCELLATION RATE
SELECT SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) /
COUNT(*) * 100 AS cancellation_rate FROM orders;

SELECT 
(cancelled_orders / total_orders) * 100 AS cancelled_rate 
FROM (
SELECT 
(SELECT COUNT(*) FROM orders WHERE status = 'cancelled') AS cancelled_orders,
(SELECT COUNT(*) FROM orders) AS total_orders 
) AS x;

-- Total Quantity Sold 
SELECT SUM(oi.quantity) FROM order_items oi join orders o on oi.order_id = o.order_id 
WHERE o.status = 'delivered';

SELECT SUM(quantity) AS total_quantity_sold
FROM order_items
WHERE order_id IN (
    SELECT order_id
    FROM orders
    WHERE status = 'Delivered'
);

-- MOST USED PAYMENT METHOD 
SELECT payment_method , COUNT(*) FROM ORDERS 
GROUP BY payment_method;

-- AVERAGE ITEMS PER DELIVERED ORDER
SELECT AVG(per_delivered_count) FROM (
SELECT SUM(oi.quantity) AS per_delivered_count FROM order_items oi 
JOIN orders o on oi.order_id = o.order_id 
WHERE o.status = 'delivered'  
GROUP BY o.order_id) AS x;

-- AVERAGE ORDER PER CUSTOMER 
SELECT AVG(order_per_customer) AS avg_order_per_customer
FROM (
    SELECT customer_id,
           COUNT(*) AS order_per_customer
    FROM orders
    GROUP BY customer_id
) AS x;

-- TOTAL REVENUE BY PAYMENT METHOD   
SELECT payment_method, SUM(oi.quantity * p.price) AS revenue FROM order_items oi 
JOIN products p ON oi.product_id = p.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY o.payment_method;

-- TOTAL REVENUE BY ORDER STATUS 
SELECT o.status , SUM(oi.quantity * p.price) AS revenue FROM order_items oi 
JOIN products p ON oi.product_id = p.product_id 
JOIN orders o ON oi.order_id = o.order_id 
GROUP BY o.status ;

-- TOTAL REVENUE BY PRODUCT CATEGORY 
SELECT p.category , SUM(oi.quantity * p.price) AS revenue FROM order_items oi
JOIN products p ON oi.product_id = p.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered'
GROUP BY p.category ;

-- TOP SELLING PRODUCT 
SELECT p.product_name , SUM(oi.quantity * p.price) AS revenue FROM order_items oi
JOIN products p ON oi.product_id = p.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered'
GROUP BY p.product_name
ORDER BY revenue DESC LIMIT 1 ;

-- TOP THREE PRODUCTS INCLUDING TIES 
WITH high_product as (
SELECT p.product_name  ,
SUM(oi.quantity * p.price) AS revenue 
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY p.product_name ) ,
ranked_products AS( 
SELECT product_name , revenue , 
DENSE_RANK() OVER(ORDER BY revenue DESC) AS revenue_rank 
FROM high_product)
SELECT product_name , revenue FROM ranked_products 
WHERE revenue_rank <= 3 
ORDER BY REVENUE DESC;

-- REVENUE BY CATEGORY WITH PERCENTAGE CONTRIBUTION 
WITH category_revenue AS (
    SELECT 
        p.category,
        SUM(oi.quantity * p.price) AS revenue
    FROM order_items oi
    JOIN products p 
        ON oi.product_id = p.product_id
    JOIN orders o 
        ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY p.category
),
total_revenue AS (
    SELECT 
        SUM(oi.quantity * p.price) AS total_revenue
    FROM order_items oi
    JOIN products p 
        ON oi.product_id = p.product_id
    JOIN orders o 
        ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
)
SELECT 
    cr.category,
    cr.revenue,
    (cr.revenue / tr.total_revenue) * 100 AS revenue_percentage
FROM category_revenue cr
CROSS JOIN total_revenue tr; 

-- AVERAGE REVENUE PER CATEGORY 
SELECT 
    x.category,
    AVG(x.product_revenue) AS avg_revenue_per_product
FROM (
    SELECT 
        p.category,
        p.product_id,
        SUM(p.price * oi.quantity) AS product_revenue
    FROM products p
    JOIN order_items oi 
        ON p.product_id = oi.product_id
    JOIN orders o 
        ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY p.category, p.product_id
) AS x
GROUP BY x.category; 

 
-- "Find the top 3 customers including ties." 
WITH revenue_per_customer as (
SELECT c.customer_name , SUM(p.price * oi.quantity) AS revenue 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id JOIN order_items oi
ON o.order_id = oi.order_id  JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered'
GROUP BY c.customer_id  ),
ranking as (
SELECT customer_name , revenue , DENSE_RANK() OVER(ORDER BY revenue DESC) AS dn 
FROM revenue_per_customer )
SELECT customer_name , revenue FROM ranking 
WHERE dn <= 3 ; 

-- CUSTOMERS WITH NO DELIEVERED ORDER 
SELECT
    c.customer_name
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(
    CASE
        WHEN o.status = 'Delivered' THEN 1
        ELSE 0
    END
) = 0;

-- REPEAT CUSTOMERS
-- Customers with more than one delivered order
SELECT
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS delivered_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.status = 'Delivered'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.order_id) > 1;

-- REVENUE BY REPEATED CUSTOMERS -- REVENUE FROM REPEAT CUSTOMERS
SELECT
    SUM(p.price * oi.quantity) AS repeat_customer_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
  AND c.customer_id IN (
      SELECT customer_id
      FROM orders
      WHERE status = 'Delivered'
      GROUP BY customer_id
      HAVING COUNT(*) > 1
  );