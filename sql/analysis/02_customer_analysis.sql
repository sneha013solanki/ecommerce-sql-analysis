-- CUSTOMER ORDER COUNT
SELECT c.customer_name, COUNT(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;

-- CUSTOMER REVENUE
SELECT c.customer_name, SUM(oi.quantity * p.price) 
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id 
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered'
GROUP BY o.customer_id; 

-- CUSTOMER AVERAGE ORDER VALUE
WITH customer_average_order AS (
    SELECT
        c.customer_id,
        c.customer_name,
        o.order_id,
        SUM(oi.quantity * p.price) AS order_revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name, o.order_id
)
SELECT
    customer_id,
    customer_name,
    AVG(order_revenue) AS average_order_value
FROM customer_average_order
GROUP BY customer_id, customer_name; 

-- TOP REVENUE CUSTOMER 
WITH customer_revenue AS (
    SELECT c.customer_name, 
           SUM(oi.quantity * p.price) AS revenue 
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id 
    JOIN order_items oi 
        ON o.order_id = oi.order_id 
    JOIN products p 
        ON oi.product_id = p.product_id 
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
),
ranking AS (
    SELECT customer_name, revenue, 
           DENSE_RANK() OVER(ORDER BY revenue DESC) AS dn 
    FROM customer_revenue
)
SELECT customer_name, revenue 
FROM ranking 
WHERE dn = 1; 

-- TOP DELIVERED ORDERS CUSTOMER
WITH highest_order AS (
    SELECT c.customer_name, 
           COUNT(o.customer_id) AS order_count
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id 
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
),
ranking AS (
    SELECT customer_name, order_count, 
           DENSE_RANK() OVER(ORDER BY order_count DESC) AS dn 
    FROM highest_order
)
SELECT customer_name, order_count 
FROM ranking
WHERE dn = 1; 

-- FIRST ORDER DATE
SELECT c.customer_name, MIN(o.order_date) 
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
GROUP BY o.customer_id;

-- LAST ORDER DATE
SELECT c.customer_name, MAX(o.order_date) 
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
GROUP BY o.customer_id; 

-- ORDER DATE DIFFERENCE 
SELECT 
    c.customer_name,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS differences
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
GROUP BY o.customer_id;

-- LATEST ORDER CANCELLED
SELECT 
    c.customer_name,
    o.order_date AS last_order_date,
    o.status
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_date = (
    SELECT MAX(o2.order_date)
    FROM orders o2
    WHERE o2.customer_id = o.customer_id
)
AND o.status = 'Cancelled'; 

-- TOP QUANTITY CUSTOMER 
SELECT 
    c.customer_name,
    SUM(oi.quantity) AS total_quantity
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY c.customer_id, c.customer_name
HAVING SUM(oi.quantity) = (
    SELECT MAX(total_quantity)
    FROM (
        SELECT SUM(oi2.quantity) AS total_quantity
        FROM orders o2
        JOIN order_items oi2 
            ON o2.order_id = oi2.order_id
        WHERE o2.status = 'Delivered'
        GROUP BY o2.customer_id
    ) AS x
);

WITH customer_quantity AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity) AS total_quantity
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name
),
ranking AS (
    SELECT 
        customer_name,
        total_quantity,
        DENSE_RANK() OVER (ORDER BY total_quantity DESC) AS dn
    FROM customer_quantity
)
SELECT customer_name, total_quantity
FROM ranking
WHERE dn = 1;

-- REPEAT CUSTOMER RATE
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) AS delivered_orders
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
),
repeat_customers AS (
    SELECT COUNT(*) AS repeat_customer_count
    FROM customer_orders
    WHERE delivered_orders > 1
),
total_customers AS (
    SELECT COUNT(*) AS total_customer_count
    FROM customer_orders
)
SELECT
    repeat_customer_count / total_customer_count * 100
        AS repeat_customer_rate
FROM repeat_customers
CROSS JOIN total_customers;

-- CUSTOMERS WITH NO ORDERS 
SELECT COUNT(*) AS customers_with_no_orders
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL; 

-- CUSTOMERS WITH NO DELIVERED ORDERS
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

-- CUSTOMER REVENUE ABOVE AVERAGE
WITH avg_revenue AS (
SELECT c.customer_name , SUM(oi.quantity * p.price) AS revenue 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered'
GROUP BY o.customer_id )
SELECT customer_name , revenue AS total_revenue FROM avg_revenue 
WHERE revenue > (SELECT AVG(revenue) FROM avg_revenue) ;

-- CUSTOMER CONTRIBUTION 
WITH total_contribution AS (
SELECT c.customer_name , SUM(oi.quantity * p.price) AS total_revenue 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered' ) 
SELECT customer_name , SUM(oi.quantity *p.price) / total_revenue * 100 AS contribution 
FROM total_contribution join customers c JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id ;

SELECT customer_name , per_customer_revenue/ total_revenue  * 100 as contribution FROM (
(SELECT SUM(revenue) AS total_revenue FROM (
SELECT c.customer_name , SUM(oi.quantity * p.price) AS revenue 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered' 
GROUP BY o.customer_id ) AS x)  AS y  ,
( SELECT  c.customer_name , SUM(oi.quantity * p.price) AS per_customer_revenue 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered' 
GROUP BY o.customer_id ) AS z ) ;

SELECT 
    z.customer_name,
    z.per_customer_revenue,
    z.per_customer_revenue / y.total_revenue * 100 AS revenue_percentage
FROM
(
    SELECT SUM(revenue) AS total_revenue
    FROM (
        SELECT 
            c.customer_name,
            SUM(oi.quantity * p.price) AS revenue
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
        WHERE o.status = 'Delivered'
        GROUP BY o.customer_id
    ) AS x
) AS y
CROSS JOIN
(
    SELECT 
        c.customer_name,
        SUM(oi.quantity * p.price) AS per_customer_revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
) AS z; 

WITH customer_revenue AS (
    SELECT
        c.customer_name,
        SUM(oi.quantity * p.price) AS total_revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_name,
    total_revenue,
    total_revenue / SUM(total_revenue) OVER () * 100 AS revenue_percentage
FROM customer_revenue;

-- ORDER WITHIN 7 DAYS OF SIGNUP 
WITH minimum AS (
SELECT c.customer_name , c.signup_date ,o.customer_id , MIN(o.order_date) AS first_order_date 
FROM  customers c JOIN orders o ON c.customer_id = o.customer_id 
GROUP BY o.customer_id 
) 
SELECT customer_name  , signup_date , first_order_date FROM minimum 
WHERE DATEDIFF( first_order_date, signup_date ) <= 7;

-- AVERAGE SIGNUP TO FIRST ORDER 
WITH difference AS (
SELECT c.customer_name , c.signup_date ,o.customer_id , MIN(o.order_date)   
AS first_order_date
FROM  customers c JOIN orders o ON c.customer_id = o.customer_id 
GROUP BY o.customer_id 
) 
SELECT AVG(date_differences) FROM (
SELECT DATEDIFF( first_order_date, signup_date ) AS date_differences  
FROM difference) AS x ;

-- CUSTOMER ORDER FREQUENCY
WITH customer_orders AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id) AS number_of_orders
    FROM orders o
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
)
SELECT
    AVG(number_of_orders) AS average_orders_per_customer
FROM customer_orders; 

-- CUSTOMER REVENUE BY CITY 
SELECT c.city,SUM(oi.quantity * p.price) AS city_revenue 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY c.city ;

-- BEST CITY BY AVERAGE CUSTOMER REVENUE 
WITH cities_revenue AS (
SELECT c.city,SUM(oi.quantity * p.price) AS city_revenue 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY o.customer_id) ,
avg_city_revenue AS( 
SELECT city , AVG(city_revenue) AS avg_city_revenue_value 
FROM cities_Revenue
GROUP BY city ) 
SELECT city,  avg_city_revenue_value FROM avg_city_revenue
WHERE avg_city_revenue_value = ( SELECT MAX(avg_city_revenue_value) FROM avg_city_revenue); 

-- CUSTOMERS WITH ONLY CANCELLED ORDERS 
SELECT c.customer_name , COUNT(o.order_id) AS 
total_order FROM customers c JOIN orders o 
ON c.customer_id = o.customer_id  
GROUP BY o.customer_id  
HAVING SUM(o.status = 'Delivered') = 0 ;

-- CUSTOMER CANCELLATION RATE FOR EACH CUSTOMER 
SELECT customer_name , COUNT(o.order_id) AS total_count ,
SUM(o.status = 'Cancelled') AS cancelled_order ,
SUM(o.status = 'Cancelled') / COUNT(o.order_id) * 100 AS cancellation_rate
FROM customers c JOIN orders o 
ON c.customer_id = o.customer_id
GROUP BY c.customer_id  ; 

-- TOP REVENUE CUSTOMER EACH CITY 
WITH customer_revenue AS (
SELECT c.customer_name , c.city , SUM(oi.quantity * p.price) AS total_revenue 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered' 
GROUP BY o.customer_id ),
customer_ranking AS (
SELECT customer_name , city , total_revenue , 
DENSE_RANK() OVER(PARTITION BY city ORDER BY total_revenue DESC) AS ranking 
FROM customer_revenue )
SELECT customer_name , city , total_revenue 
FROM customer_ranking WHERE ranking = 1;

-- TOP CUSTOMER BY REVENUE IN EACH CATEGORY
WITH customer_revenue AS (
SELECT c.customer_name , p.category , SUM(oi.quantity * p.price) AS total_revenue 
FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered' 
GROUP BY o.customer_id, p.category),
customer_ranking AS (
SELECT customer_name , category , total_revenue , 
DENSE_RANK() OVER(PARTITION BY category ORDER BY total_revenue DESC) AS ranking 
FROM customer_revenue )
SELECT customer_name , category , total_revenue 
FROM customer_ranking WHERE ranking = 1;

-- CUSTOMER PURCHASE FREQUENCY 
WITH order_dates AS (
SELECT c.customer_id , c.customer_name , o.order_date ,
LAG(o.order_date) OVER ( PARTITION BY c.customer_id ORDER BY o.order_date ) AS
previous_order_date FROM customers c JOIN orders o ON c.customer_id = o.customer_id 
WHERE o.status = 'Delivered' ),
order_gaps AS( 
SELECT customer_id , customer_name , 
DATEDIFF(order_date , previous_order_date) AS days_between_orders 
FROM order_dates WHERE previous_order_date IS NOT NULL )
SELECT customer_name , AVG(days_between_orders) AS average_days_between_orders
FROM order_gaps GROUP BY customer_id , customer_name ;

-- SECOND ORDER WITHIN 30 DAYS OF FIRST ORDER 
WITH ranking AS (
SELECT c.customer_name , c.customer_id ,o.order_date , 
ROW_NUMBER() OVER(PARTITION BY c.customer_id ORDER BY o.order_date ) AS rn 
FROM customers c JOIN orders o 
ON c.customer_id = o.customer_id  
WHERE o.status = 'Delivered'
),
first_second_order AS (
SELECT customer_name , customer_id , 
MAX(CASE WHEN rn = 1 THEN order_date END) AS first_order_date,
MAX(CASE WHEN rn = 2 THEN order_date END) AS second_order_date
FROM ranking 
WHERE rn <= 2 
GROUP BY customer_id,customer_name ) 
SELECT customer_name ,first_order_date, second_order_date  , 
DATEDIFF(second_order_date ,first_order_date) AS days_to_second_order 
FROM first_second_order
WHERE DATEDIFF(second_order_date ,first_order_date ) <= 30 ;

-- CUSTOMERS WITH 2+ ORDERS WHO NEVER CANCELLED
SELECT
    c.customer_name,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) >= 2
   AND SUM(
       CASE
           WHEN o.status = 'Cancelled' THEN 1
           ELSE 0
       END
   ) = 0;

-- CUSTOMER REVENUE GROWTH
-- FIRST VS LAST ORDER REVENUE

WITH order_revenue AS (
    SELECT
        c.customer_id,
        c.customer_name,
        o.order_id,
        o.order_date,
        SUM(oi.quantity * p.price) AS order_revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
    GROUP BY
        c.customer_id,
        c.customer_name,
        o.order_id,
        o.order_date
),
ranked_orders AS (
    SELECT
        customer_id,
        customer_name,
        order_date,
        order_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS first_rank,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date DESC, order_id DESC
        ) AS last_rank
    FROM order_revenue
)
SELECT
    customer_name,
    MAX(CASE
        WHEN first_rank = 1 THEN order_revenue
    END) AS first_order_revenue,

    MAX(CASE
        WHEN last_rank = 1 THEN order_revenue
    END) AS last_order_revenue,

    MAX(CASE
        WHEN last_rank = 1 THEN order_revenue
    END)
    -
    MAX(CASE
        WHEN first_rank = 1 THEN order_revenue
    END) AS revenue_change

FROM ranked_orders
GROUP BY customer_id, customer_name
HAVING COUNT(*) >= 2;
  
-- CUSTOMER PURCHASE CATEGORY
-- CUSTOMER PURCHASE CATEGORY

WITH category AS (
    SELECT DISTINCT
        c.customer_id,
        c.customer_name,
        p.category
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
)
SELECT
    customer_name,
    COUNT(category) AS unique_categories
FROM category
GROUP BY customer_id, customer_name;

-- CUSTOMER SEGMENTATION 
SELECT
    c.customer_name,
    SUM(oi.quantity * p.price) AS total_revenue,
    CASE
        WHEN SUM(oi.quantity * p.price) >= 10000 THEN 'High Value'
        WHEN SUM(oi.quantity * p.price) >= 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY c.customer_id, c.customer_name;

