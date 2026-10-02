-- REVENUE BY MONTH 
SELECT MONTHNAME(o.order_date) AS month , YEAR(o.order_date) AS year ,
SUM(oi.quantity * p.price) AS monthly_revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'delivered'
GROUP BY MONTHNAME(o.order_date) , YEAR(o.order_date) 
ORDER BY YEAR(o.order_date) ;

-- MONTH WITH HIGHEST REVENUE IN EACH YEAR 
WITH revenue AS (
SELECT MONTHNAME(o.order_date) AS month , YEAR(o.order_date) AS year , 
SUM(oi.quantity * p.price) AS revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'delivered'
GROUP BY MONTHNAME(o.order_date) , YEAR(o.order_date) ) ,
ranking AS (
SELECT month , year , revenue , 
RANK() OVER(PARTITION BY year ORDER BY revenue DESC) AS rn 
FROM revenue ) 
SELECT month , year , revenue 
FROM ranking 
WHERE rn = 1
ORDER BY year ;

-- TOTAL NUMBER OF ORDERS AND TOTAL REVENUE FOR EACH YEAR 
SELECT YEAR(o.order_date) AS year , COUNT(o.order_id) as total_orders ,
SUM(oi.quantity * p.price) AS total_revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY YEAR(o.order_date) ; 

-- AVERAGE ORDER VALUE FOR EACH MONTH 
SELECT MONTHNAME(o.order_date) AS month , YEAR(o.order_date) AS year , 
SUM(oi.quantity * p.price) AS revenue , COUNT(DISTINCT o.order_id) AS total_orders,
SUM(oi.quantity * p.price) / COUNT(DISTINCT o.order_id)  AS aov  
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY MONTHNAME(o.order_date) , YEAR(o.order_date) 
ORDER BY YEAR(o.order_date) ;

-- NUMBER OF NEW CUSTOMER ACQUIRED EACH MONTH 
SELECT
    YEAR(signup_date) AS year,
    MONTHNAME(signup_date) AS month,
    COUNT(customer_id) AS new_customers
FROM customers
GROUP BY
    YEAR(signup_date),
    MONTH(signup_date),
    MONTHNAME(signup_date)
ORDER BY
    YEAR(signup_date) ,
    MONTH(signup_date);

-- AVERAGE DAILY REVENUE FOR EACH MONTH 
SELECT YEAR(o.order_date) AS year , MONTHNAME(o.order_date) AS month ,
SUM(oi.quantity * p.price) AS  monthly_revenue , 
SUM(oi.quantity * p.price) / COUNT(DISTINCT o.order_date) AS average_daily_revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY MONTHNAME(o.order_date),  MONTH(o.order_date), YEAR(o.order_date) 
ORDER BY YEAR(o.order_date)  , MONTH(o.order_date) ;

-- HIGHEST REVENUE DAY IN EACH MONTH
WITH revenue AS (
SELECT YEAR(o.order_date) AS year , MONTHNAME(o.order_date) AS month ,
o.order_date AS order_date , SUM(oi.quantity * p.price) AS daily_revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered'
GROUP BY o.order_date ,  MONTHNAME(o.order_date) ,
MONTH(o.order_date) , YEAR(o.order_date) ) ,
ranking AS ( 
SELECT year , month , order_date , daily_revenue ,
DENSE_RANK() OVER(PARTITION BY month , year ORDER BY daily_revenue DESC) AS dn 
FROM revenue )
SELECT year , month , order_date , daily_revenue 
FROM ranking 
WHERE dn = 1 
ORDER BY  year  , month ; 

-- REVENUE GROWTH COMPARE TO PREVIOUS MONTH 
WITH revenue AS (
SELECT  YEAR(o.order_date) AS year , MONTH(o.order_date) AS month , 
SUM(oi.quantity * p.price) AS monthly_revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY MONTH(o.order_date) , YEAR(o.order_date) ) , 
previous AS (
SELECT year , month , monthly_revenue ,
LAG(monthly_revenue) OVER(ORDER BY year ,  month) AS previous_month_revenue
FROM revenue )
SELECT year , month , monthly_revenue , previous_month_revenue ,
monthly_revenue - previous_month_revenue  AS diference  
FROM previous  
WHERE previous_month_revenue IS NOT NULL ;

-- MONTH OVER MONTH REVENUE GROWTH % 
WITH revenue AS (
SELECT  YEAR(o.order_date) AS year , MONTH(o.order_date) AS month , 
SUM(oi.quantity * p.price) AS monthly_revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY MONTH(o.order_date) , YEAR(o.order_date) ) , 
previous AS (
SELECT year , month , monthly_revenue ,
LAG(monthly_revenue) OVER(ORDER BY year ,  month) AS previous_month_revenue
FROM revenue )
SELECT year , month , monthly_revenue , previous_month_revenue ,
ROUND((monthly_revenue - previous_month_revenue) / previous_month_revenue * 100 ,2) AS growth_percentage  
FROM previous  
WHERE previous_month_revenue IS NOT NULL ;

-- MONTH WITH HIGHEST REVENUE GROWTH 
WITH revenue AS (
SELECT  YEAR(o.order_date) AS year , MONTH(o.order_date) AS month , 
SUM(oi.quantity * p.price) AS monthly_revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY MONTH(o.order_date) , YEAR(o.order_date) ) , 
previous AS (
SELECT year , month , monthly_revenue ,
LAG(monthly_revenue) OVER(ORDER BY year ,  month) AS previous_month_revenue
FROM revenue ) ,
growth AS (
SELECT year , month , monthly_revenue , previous_month_revenue ,
ROUND((monthly_revenue - previous_month_revenue) / previous_month_revenue * 100 ,2) AS growth_percentage  
FROM previous  
WHERE previous_month_revenue IS NOT NULL ),
ranking AS (
SELECT year , month , monthly_revenue , previous_month_revenue ,
growth_percentage , DENSE_RANK() OVER(ORDER BY growth_percentage DESC ) AS dn 
FROM growth )
SELECT year , month , monthly_revenue , previous_month_revenue , growth_percentage 
FROM ranking WHERE dn = 1 ;

-- MONTH WITH HIGHEST NUMBER OF DELIVERED ORDER 
WITH order_number AS (
SELECT YEAR(o.order_date) AS year , MONTH(o.order_date) AS month  ,
COUNT(o.order_id) AS order_count 
FROM orders o 
WHERE o.status = 'Delivered' 
GROUP BY MONTH(o.order_date) , YEAR(o.order_date) ) , 
ranking AS (
SELECT year , month , order_count ,
DENSE_RANK() OVER(ORDER BY order_count DESC) AS dn 
FROM order_number ) 
SELECT year , month , order_count 
FROM ranking WHERE dn = 1 ; 

-- AVERAGE ORDER VALUE BY YEAR  
SELECT YEAR(o.order_date) AS year , 
SUM(oi.quantity * p.price) AS revenue , COUNT(DISTINCT o.order_id) AS total_orders ,
SUM(oi.quantity * p.price)  / COUNT(DISTINCT o.order_id) AS average_order_value 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY YEAR(o.order_date) 
ORDER BY  YEAR(o.order_date) ;

-- REVENUE BY QUARTER 
SELECT YEAR(o.order_date) AS year , CONCAT('Q',QUARTER(o.order_date)) AS quarter ,
SUM(oi.quantity * p.price) AS revenue
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY YEAR(o.order_date) , CONCAT('Q',QUARTER(o.order_date)) 
ORDER BY YEAR(o.order_date) , CONCAT('Q',QUARTER(o.order_date)) ;

-- QUARTERLY REVENUE GROWTH 
WITH quarter_revenue AS (
SELECT YEAR(o.order_date) AS year , CONCAT('Q',QUARTER(o.order_date)) AS quarter ,
SUM(oi.quantity * p.price) AS current_quarter
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY YEAR(o.order_date) , CONCAT('Q',QUARTER(o.order_date)) 
ORDER BY YEAR(o.order_date) , CONCAT('Q',QUARTER(o.order_date)) ) ,
previous_quarter  AS (
SELECT year , quarter , current_quarter , 
LAG(current_quarter) OVER(ORDER BY year , quarter ) AS previous_revenue
FROM quarter_revenue )
SELECT year , quarter , current_quarter , previous_revenue , 
ROUND((current_quarter - previous_revenue) / previous_revenue * 100, 2) AS growth_percentage
FROM previous_quarter
WHERE previous_revenue IS NOT NULL ;

-- AVERAGE MONTHLY REVENUE BY YEAR 
WITH monthly_revenue AS (
SELECT YEAR(o.order_date) AS year , MONTH(o.order_date) AS month ,
SUM(oi.quantity * p.price) AS revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY YEAR(o.order_date) , MONTH(o.order_date) )
SELECT year , ROUND(AVG(revenue) , 2)  AS average_monthly_revenue 
FROM monthly_revenue 
GROUP BY year 
ORDER BY year ; 

-- REVENUE BY DAY OF WEEK 
SELECT DAYNAME(o.order_date) AS day , 
SUM(oi.quantity * p.price) AS revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered'
GROUP BY DAYNAME(o.order_date) , WEEKDAY(o.order_date)
ORDER BY WEEKDAY(o.order_date)  ; 

-- REVENUE BY WEEK OF MONTH 
SELECT
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    FLOOR((DAY(o.order_date) - 1) / 7) + 1 AS week_of_month,
    SUM(oi.quantity * p.price) AS total_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status = 'Delivered'
GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date),
    FLOOR((DAY(o.order_date) - 1) / 7) + 1
ORDER BY
    year,
    month,
    week_of_month; 
    
-- MONTH WITH HIGHEST AVERAGE DAILY REVENUE 
WITH revenue_by_month AS (
SELECT YEAR(o.order_date) AS year , MONTH(o.order_date) AS month , 
SUM(oi.quantity * p.price) AS revenue ,
COUNT(DISTINCT o.order_date) AS sales_days
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY  YEAR(o.order_date) , MONTH(o.order_date)  ) ,
daily_revenue AS (
SELECT year , month , revenue , revenue / sales_days AS average_daily_revenue
FROM revenue_by_month ) ,
ranking AS(
SELECT year , month , revenue , average_daily_revenue ,
DENSE_RANK() OVER(ORDER BY average_daily_revenue DESC) AS dn 
FROM daily_revenue ) 
SELECT year , month , revenue , average_daily_revenue 
FROM ranking WHERE dn = 1 ; 

WITH revenue_by_month AS (
    SELECT
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        SUM(oi.quantity * p.price) AS revenue,
        COUNT(DISTINCT o.order_date) AS sales_days
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY
        YEAR(o.order_date),
        MONTH(o.order_date)
),
daily_revenue AS (
    SELECT
        year,
        month,
        revenue,
        revenue / sales_days AS average_daily_revenue
    FROM revenue_by_month
),
ranking AS (
    SELECT
        year,
        month,
        revenue,
        average_daily_revenue,
        DENSE_RANK() OVER (
            ORDER BY average_daily_revenue DESC
        ) AS dn
    FROM daily_revenue
)
SELECT
    year,
    month,
    revenue,
    average_daily_revenue
FROM ranking
WHERE dn = 1;

-- MONTH WITH HIGHEST CANCELLATION RATE
WITH cancellation AS (
    SELECT
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        COUNT(*) AS total_orders,
        SUM(
            CASE
                WHEN status = 'Cancelled' THEN 1
                ELSE 0
            END
        ) AS cancelled_orders
    FROM orders
    GROUP BY
        YEAR(order_date),
        MONTH(order_date)
),
ranking AS (
    SELECT
        year,
        month,
        total_orders,
        cancelled_orders,
        cancelled_orders / total_orders * 100 AS cancellation_rate,
        DENSE_RANK() OVER (
            ORDER BY cancelled_orders / total_orders DESC
        ) AS dn
    FROM cancellation
)
SELECT
    year,
    month,
    total_orders,
    cancelled_orders,
    cancellation_rate
FROM ranking
WHERE dn = 1;

-- MONTH ORDER REVENUE VS VOLUME 
SELECT YEAR(o.order_date) AS year , MONTH(o.order_date) AS month , 
SUM(oi.quantity * p.price) AS revenue , COUNT(DISTINCT o.order_id) AS total_orders ,
SUM(oi.quantity * p.price) / COUNT(DISTINCT o.order_id) AS average_revenue_per_order 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered'
GROUP BY YEAR(o.order_date) , MONTH(o.order_date) 
ORDER BY YEAR(o.order_date) , MONTH(o.order_date) ; 
 
-- CUSTOMER ACQUISITION VS SALES 
WITH new_customers AS (
    SELECT
        YEAR(signup_date) AS year,
        MONTH(signup_date) AS month,
        COUNT(*) AS new_customers
    FROM customers
    GROUP BY YEAR(signup_date), MONTH(signup_date)
),
delivered_orders AS (
    SELECT
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        COUNT(DISTINCT order_id) AS delivered_orders
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT
    COALESCE(n.year, d.year) AS year,
    COALESCE(n.month, d.month) AS month,
    COALESCE(n.new_customers, 0) AS new_customers,
    COALESCE(d.delivered_orders, 0) AS delivered_orders
FROM new_customers n
LEFT JOIN delivered_orders d
    ON n.year = d.year
    AND n.month = d.month
ORDER BY year, month; 

-- MONTHLY REPEAT CUSTOMER ORDERS 
WITH repeat_customers AS (
    SELECT
        customer_id
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
    HAVING COUNT(DISTINCT order_id) > 1
)
SELECT
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    COUNT(DISTINCT o.order_id) AS repeat_customer_orders
FROM orders o
JOIN repeat_customers rc
    ON o.customer_id = rc.customer_id
WHERE o.status = 'Delivered'
GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date)
ORDER BY
    YEAR(o.order_date),
    MONTH(o.order_date);
    
-- MONTHLY REVENUE BY REPEATED CUSTOMERS 
WITH repeated_customers AS (
SELECT o.customer_id 
FROM orders o
WHERE o.status = 'Delivered'
GROUP BY o.customer_id 
HAVING COUNT(DISTINCT o.order_id) > 1) 
SELECT YEAR(o.order_date) AS year , MONTHNAME(o.order_date) AS month,
SUM(oi.quantity * p.price) AS repeat_customer_revenue
FROM products p JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id 
JOIN repeated_customers rc ON o.customer_id = rc.customer_id 
GROUP BY YEAR(o.order_date) , MONTHNAME(o.order_date) , MONTH(o.order_date) 
ORDER BY YEAR(o.order_date) , MONTH(o.order_date) ;

-- MONTHLY REVENUE FROM NEW CUSTOMER 
WITH first_order AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    SUM(oi.quantity * p.price) AS new_customer_revenue
FROM orders o
JOIN first_order fo
    ON o.customer_id = fo.customer_id
    AND o.order_date = fo.first_order_date
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date)
ORDER BY
    YEAR(o.order_date),
    MONTH(o.order_date);
    
-- NEW CUSTOMER REVENUE VS REPEATED CUSTOMER REVENUE
WITH first_order AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
),

new_customer_revenue AS (
    SELECT
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        SUM(oi.quantity * p.price) AS new_customer_revenue
    FROM orders o
    JOIN first_order fo
        ON o.customer_id = fo.customer_id
        AND o.order_date = fo.first_order_date
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
    GROUP BY YEAR(o.order_date), MONTH(o.order_date)
),

repeat_customers AS (
    SELECT
        customer_id
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
    HAVING COUNT(DISTINCT order_id) > 1
),

repeat_customer_revenue AS (
    SELECT
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        SUM(oi.quantity * p.price) AS repeat_customer_revenue
    FROM orders o
    JOIN repeat_customers rc
        ON o.customer_id = rc.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
    GROUP BY YEAR(o.order_date), MONTH(o.order_date)
)

SELECT
    COALESCE(n.year, r.year) AS year,
    COALESCE(n.month, r.month) AS month,
    COALESCE(n.new_customer_revenue, 0) AS new_customer_revenue,
    COALESCE(r.repeat_customer_revenue, 0) AS repeat_customer_revenue
FROM new_customer_revenue n
LEFT JOIN repeat_customer_revenue r
    ON n.year = r.year
    AND n.month = r.month
ORDER BY year, month;

-- REVENUE SHARE BY MONTH 
WITH monthly_revenue AS(
SELECT YEAR(o.order_date) AS year , MONTH(o.order_date) AS month , 
SUM(oi.quantity* p.price) AS monthly_revenue 
FROM orders o JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered' 
GROUP BY YEAR(o.order_date) , MONTH(o.order_date) 
ORDER BY  YEAR(o.order_date) , MONTH(o.order_date) ) ,
total_revenue AS(
SELECT SUM(oi.quantity* p.price) AS total_revenue 
FROM orders o JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered' )
SELECT mv.year , mv.month ,mv.monthly_revenue , tv.total_revenue ,
(mv.monthly_revenue /tv.total_revenue) * 100  AS revenue_percentage
FROM monthly_revenue mv CROSS JOIN total_revenue tv ;

-- BEST SELLING MONTH FOR EACH PRODUCT 
WITH product_revenue AS (
SELECT p.product_name , YEAR(o.order_date) AS year ,
MONTHNAME(o.order_date) AS month , SUM(oi.quantity * p.price) AS product_revenue  
FROM orders o JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered' 
GROUP BY p.product_name ,  YEAR(o.order_date) , MONTHNAME(o.order_date) ,MONTH(o.order_date) ) ,
ranking AS (
SELECT product_name , year , month , product_revenue ,
DENSE_RANK() OVER(PARTITION BY product_name ORDER BY product_revenue DESC) AS dn 
FROM product_revenue ) 
SELECT product_name , year , month , product_revenue 
FROM ranking WHERE dn = 1 
ORDER BY product_name , year, month ;

-- BEST SELLING MONTH FOR EACH CATEGORY 
WITH category_revenue AS (
SELECT p.category , YEAR(o.order_date) AS year ,
MONTHNAME(o.order_date) AS month , SUM(oi.quantity * p.price) AS category_revenue  
FROM orders o JOIN order_items oi ON o.order_id = oi.order_id 
JOIN products p ON oi.product_id = p.product_id 
WHERE o.status = 'Delivered' 
GROUP BY p.category ,  YEAR(o.order_date) , MONTHNAME(o.order_date) ,MONTH(o.order_date) ) ,
ranking AS (
SELECT category, year , month , category_revenue ,
DENSE_RANK() OVER(PARTITION BY category ORDER BY category_revenue DESC) AS dn 
FROM category_revenue ) 
SELECT category, year , month , category_revenue 
FROM ranking WHERE dn = 1 
ORDER BY category, year, month ;