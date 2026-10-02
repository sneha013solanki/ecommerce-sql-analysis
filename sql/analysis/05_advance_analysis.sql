-- CUSTOMER LIFETIME VALUE 
SELECT c.customer_id , c.customer_name ,
SUM(oi.quantity * p.price) AS clv 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered' 
GROUP BY c.customer_id , c.customer_name 
ORDER BY clv DESC ;

-- CUSTOMER REVENUE CONTRIBUTION 
WITH customer_revenue AS (
SELECT c.customer_id , c.customer_name ,
SUM(oi.quantity * p.price) AS customer_revenue
FROM customers c JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered' 
GROUP BY c.customer_id , c.customer_name ) 
SELECT customer_id , customer_name , customer_revenue ,
customer_revenue / SUM(customer_revenue) OVER()  * 100 AS revenue_contribution_percentage
FROM customer_revenue ;

-- PARETO / 80-20 REVENUE ANALYSIS 
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * p.price) AS customer_revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name
),
cumulative_revenue AS (
    SELECT
        customer_id,
        customer_name,
        customer_revenue,
        SUM(customer_revenue) OVER (
            ORDER BY customer_revenue DESC
        ) AS cumulative_revenue
    FROM customer_revenue
)
SELECT
    customer_id,
    customer_name,
    customer_revenue,
    cumulative_revenue,
    cumulative_revenue
        / SUM(customer_revenue) OVER () * 100
        AS cumulative_revenue_percentage
FROM cumulative_revenue
ORDER BY customer_revenue DESC;

-- CUSTOMER SEGEMENTATION 
WITH revenue AS (
SELECT c.customer_id , c.customer_name , 
SUM(oi.quantity * p.price) AS customer_revenue 
FROM products p  JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id 
WHERE o.status = 'Delivered' 
GROUP BY c.customer_id , c.customer_name ) 
SELECT customer_id ,customer_name , customer_revenue ,
CASE WHEN customer_revenue >= 50000 THEN 'HIGH VALUE' 
WHEN customer_revenue >= 25000 THEN 'MEDIUM VALUE' 
ELSE 'LOW VALUE' 
END AS customer_segmentation 
FROM revenue ;

-- RFM ANALYSIS (RECENCY , FREQUENCY , MONETARY) 
SELECT c.customer_id , c.customer_name , 
 CONCAT( DATEDIFF(
        (SELECT MAX(order_date) FROM orders
        WHERE status = 'Delivered'),
        MAX(o.order_date)
    ),"  days ago ") AS recency , 
COUNT(DISTINCT o.order_id) AS frequency , 
SUM(oi.quantity * p.price) AS monetary 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered' 
GROUP BY c.customer_id , c.customer_name ;

-- CUSTOMER BUYING ACROSS DIFFERENT CATEGORIES (atleast have 2 different categories)
SELECT c.customer_id , c.customer_name ,
COUNT(DISTINCT p.category) AS number_of_category ,
GROUP_CONCAT(DISTINCT p.category ORDER BY p.category SEPARATOR ', ') AS categories
FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status ='Delivered'
GROUP BY c.customer_id , c.customer_name 
HAVING COUNT(DISTINCT p.category) >= 2;

-- CUSTOMERS MOST PURCHASE CATEGORY 
WITH purchase_category AS (
SELECT c.customer_id , c.customer_name ,p.category,
SUM(oi.quantity) as total_quantity 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id  
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status ='Delivered' 
GROUP BY c.customer_id , c.customer_name ,p.category) 
select customer_id , customer_name , category , total_quantity 
from purchase_category p
where total_quantity = 
(select max(total_quantity) from purchase_category r
where r.customer_id = p.customer_id);

WITH purchase_category AS (
SELECT c.customer_id , c.customer_name ,p.category,
SUM(oi.quantity) as total_quantity 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id  
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status ='Delivered' 
GROUP BY c.customer_id , c.customer_name ,p.category) ,
ranking AS (
SELECT customer_id , customer_name , category , total_quantity ,
DENSE_RANK() OVER(PARTITION BY customer_id , customer_name ORDER BY total_quantity DESC) AS dn 
from purchase_category)
SELECT customer_id , customer_name , category , total_quantity 
FROM ranking WHERE dn = 1;

-- PRODUCT RANKING WITH IN EACH CATEGORY 
WITH product_revenue AS (
SELECT p.category , p.product_name ,
SUM(oi.quantity * p.price) AS product_revenue 
FROM products p JOIN order_items oi ON oi.product_id = p.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY p.category , p.product_name ) ,
ranking AS (
SELECT category , product_name , product_revenue ,
DENSE_RANK() OVER(PARTITION BY category  ORDER BY product_revenue DESC) AS dn 
FROM product_revenue ) 
SELECT category , product_name , product_revenue  
FROM ranking WHERE dn <= 2 ;

-- CATEGORY PERFORMANCE COMPARISON
SELECT p.category , SUM(oi.quantity * p.price) AS total_revenue ,
SUM(oi.quantity) AS total_quantity , COUNT(DISTINCT oi.product_id) AS number_of_products_sold
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY p.category ;

-- CUSTOMER SPENDING CHANGE 
WITH monthly_spending AS(
SELECT c.customer_id , YEAR(o.order_date) AS year ,MONTH(o.order_date) AS month , MONTHNAME(o.order_date) AS month_name ,
SUM(oi.quantity * p.price) AS monthly_revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
JOIN customers c ON o.customer_id =c.customer_id
WHERE o.status = 'Delivered' 
GROUP BY c.customer_id , YEAR(o.order_date) , MONTHNAME(o.order_date) , MONTH(o.order_date)
ORDER BY YEAR(o.order_date) , MONTH(o.order_date)), 
ranking AS (
SELECT customer_id , year , month ,month_name, monthly_revenue , 
LAG(monthly_revenue) OVER(PARTITION BY customer_id ORDER BY year , month ) AS previous_revenue
FROM monthly_spending )
SELECT customer_id , year, month_name , monthly_revenue , previous_revenue , 
monthly_revenue - previous_revenue AS comparison 
FROM ranking
ORDER BY year , month ;

-- CROSS SELLING ANALYSIS 
WITH customer_category AS(
SELECT o.customer_id ,p.category 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Delivered') 
SELECT c1.category AS category_1 , c2.category AS category_2 ,
COUNT(DISTINCT c1.customer_id) AS number_of_customers
FROM customer_category c1 JOIN customer_category c2 
ON c1.customer_id = c2.customer_id 
AND c1.category < c2.category
GROUP BY c1.category, c2.category
ORDER BY number_of_customers DESC; 


-- CUSTOMER COHORT ANALYSIS 
WITH first_purchase AS (
SELECT customer_id , 
MIN(o.order_date) AS first_order_date
FROM orders o WHERE o.status = 'Delivered' 
GROUP BY customer_id ) 
SELECT
    DATE_FORMAT(fp.first_order_date, '%Y-%m') AS cohort_month,
    DATE_FORMAT(o.order_date, '%Y-%m') AS purchase_month,
    COUNT(DISTINCT fp.customer_id) AS number_of_customers
FROM first_purchase fp
JOIN orders o
    ON fp.customer_id = o.customer_id
WHERE o.status = 'Delivered'
GROUP BY
    DATE_FORMAT(fp.first_order_date, '%Y-%m'),
    DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY
    cohort_month,
    purchase_month;

-- CUSTOMER PURCHASE FREQUENCY AND REVENUE 
SELECT c.customer_id , c.customer_name , 
COUNT(DISTINCT o.order_id) AS total_orders , SUM(oi.quantity * p.price) AS total_revenue ,
SUM(oi.quantity * p.price)/COUNT(DISTINCT o.order_id)  AS average_order_revenue 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered' 
GROUP BY c.customer_id , c.customer_name ;




 