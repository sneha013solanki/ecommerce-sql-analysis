
-- Q1. TOTAL QUANTITY SOLD BY PRODUCT
SELECT
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status = 'Delivered'
GROUP BY p.product_name
ORDER BY total_quantity_sold DESC;

-- Q2. TOTAL QUANTITY SOLD BY CATEGORY
SELECT
    p.category,
    SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status = 'Delivered'
GROUP BY p.category;

-- Q3. PRODUCT REVENUE
SELECT
    p.product_name,
    SUM(oi.quantity * p.price) AS revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status = 'Delivered'
GROUP BY p.product_name
ORDER BY revenue DESC;

-- Q4. AVERAGE PRODUCT PRICE BY CATEGORY
SELECT
    category,
    AVG(price) AS average_product_price
FROM products
GROUP BY category;

-- Q5. HIGHEST-REVENUE PRODUCT IN EACH CATEGORY
-- INCLUDING TIES
WITH sum_price AS (
    SELECT
        p.category,
        p.product_name,
        SUM(oi.quantity * p.price) AS revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY p.category, p.product_name
),
ranking AS (
    SELECT
        category,
        product_name,
        revenue,
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS dn
    FROM sum_price
)
SELECT
    category,
    product_name,
    revenue
FROM ranking
WHERE dn = 1;

-- Q6. PRODUCT REVENUE CONTRIBUTION
WITH product_revenue AS (
    SELECT
        p.product_name,
        SUM(oi.quantity * p.price) AS revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY p.product_name
)
SELECT
    product_name,
    revenue,
    revenue / SUM(revenue) OVER () * 100
        AS revenue_percentage
FROM product_revenue
ORDER BY revenue_percentage DESC;

-- Q7. PRODUCTS NEVER SOLD IN DELIVERED 
SELECT
    p.product_id,
    p.product_name,
    p.category
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
LEFT JOIN orders o
    ON oi.order_id = o.order_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category
HAVING SUM(
    CASE
        WHEN o.status = 'Delivered' THEN 1
        ELSE 0
    END
) = 0;

-- Q8. PRODUCT CANCELLATION RATE
WITH product_revenue AS (
    SELECT
        p.product_name,
        SUM(oi.quantity) AS total_quantity,
        SUM(
            CASE
                WHEN o.status = 'Cancelled'
                THEN oi.quantity
                ELSE 0
            END
        ) AS cancelled_quantity
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    GROUP BY p.product_name
)
SELECT
    product_name,
    total_quantity,
    cancelled_quantity,
    cancelled_quantity / total_quantity * 100
        AS cancellation_rate
FROM product_revenue;

-- Q9. TOP 3 PRODUCTS BY QUANTITY SOLD
-- INCLUDING TIES
WITH quantity_sold AS (
    SELECT
        p.product_name,
        SUM(oi.quantity) AS total_quantity
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY p.product_name
),
ranking AS (
    SELECT
        product_name,
        total_quantity,
        DENSE_RANK() OVER (
            ORDER BY total_quantity DESC
        ) AS dn
    FROM quantity_sold
)
SELECT
    product_name,
    total_quantity
FROM ranking
WHERE dn <= 3
ORDER BY total_quantity DESC;

-- Q10. PRODUCT AVERAGE RATING
SELECT
    p.product_name,
    AVG(r.rating) AS average_rating,
    COUNT(r.rating) AS number_of_reviews
FROM products p
JOIN reviews r
    ON p.product_id = r.product_id
GROUP BY p.product_name
ORDER BY average_rating DESC;

-- Q11. PRODUCTS WITH HIGH REVENUE BUT LOW RATINGS
-- REVENUE GREATER THAN 10000
-- AVERAGE RATING LESS THAN 3.5

WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity * p.price) AS total_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),
product_ratings AS (
    SELECT
        p.product_id,
        AVG(r.rating) AS average_rating
    FROM products p
    JOIN reviews r
        ON p.product_id = r.product_id
    GROUP BY p.product_id
)
SELECT
    pr.product_name,
    pr.category,
    pr.total_revenue,
    rt.average_rating
FROM product_revenue pr
JOIN product_ratings rt
    ON pr.product_id = rt.product_id
WHERE pr.total_revenue > 10000
  AND rt.average_rating < 3.5;


-- Q12. HIGHEST-AVERAGE-RATED CATEGORY INCLUDING TIES
WITH category_rating AS (
    SELECT
        p.category,
        AVG(r.rating) AS average_category_rating
    FROM products p
    JOIN reviews r
        ON p.product_id = r.product_id
    GROUP BY p.category
),
ranking AS (
    SELECT
        category,
        average_category_rating,
        DENSE_RANK() OVER (
            ORDER BY average_category_rating DESC
        ) AS dn
    FROM category_rating
)
SELECT
    category,
    average_category_rating
FROM ranking
WHERE dn = 1;

-- Q13. TOP 3 PRODUCTS BY NUMBER OF REVIEWS INCLUDING TIES
WITH number_of_reviews AS (
    SELECT
        p.product_name,
        p.category,
        COUNT(r.rating) AS reviews
    FROM products p
    JOIN reviews r
        ON p.product_id = r.product_id
    GROUP BY
        p.product_name,
        p.category
),
rating AS (
    SELECT
        product_name,
        category,
        reviews,
        DENSE_RANK() OVER (
            ORDER BY reviews DESC
        ) AS dn
    FROM number_of_reviews
)
SELECT
    product_name,
    category,
    reviews
FROM rating
WHERE dn <= 3
ORDER BY reviews DESC;

-- PRODUCT WITH NO CUSTOMER REVIEW 
SELECT  p.product_name , p.category 
FROM products p LEFT JOIN reviews r 
ON p.product_id = r.product_id 
GROUP BY  p.product_name , p.category
HAVING COUNT(r.rating) = 0 ;

-- TOP 3 PRODUCT WITH HIGHEST CANCELLED QUANTITY 
WITH product_cancelled AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(
            CASE
                WHEN o.status = 'Cancelled' THEN oi.quantity
                ELSE 0
            END
        ) AS cancelled_quantity
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

ranking AS (
    SELECT
        product_name,
        category,
        cancelled_quantity,
        DENSE_RANK() OVER (
            ORDER BY cancelled_quantity DESC
        ) AS dn
    FROM product_cancelled
)

SELECT
    product_name,
    category,
    cancelled_quantity
FROM ranking
WHERE dn <= 3
ORDER BY cancelled_quantity DESC;

-- PRODUCT WITH HIGHEST CANCELLATION RATE 
-- PRODUCT WITH HIGHEST CANCELLATION RATE

WITH product_cancellation AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity) AS total_quantity,
        SUM(
            CASE
                WHEN o.status = 'Cancelled'
                THEN oi.quantity
                ELSE 0
            END
        ) AS cancelled_quantity
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),
ranking AS (
    SELECT
        product_name,
        category,
        total_quantity,
        cancelled_quantity,
        cancelled_quantity / total_quantity * 100 AS cancellation_rate,
        DENSE_RANK() OVER (
            ORDER BY cancelled_quantity / total_quantity DESC
        ) AS dn
    FROM product_cancellation
)
SELECT
    product_name,
    category,
    total_quantity,
    cancelled_quantity,
    cancellation_rate
FROM ranking
WHERE dn = 1;

-- PRODUCT WITH HIGHEST DELIVERED QUANTITY  
WITH delivered_quantity  AS (
SELECT p.product_name , p.category , 
SUM(oi.quantity) AS delivered_quantity 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY p.product_name , p.category ),
ranking AS (
SELECT product_name , category , delivered_quantity ,
DENSE_RANK() OVER(ORDER BY delivered_quantity DESC) AS dn 
FROM delivered_quantity ) 
SELECT product_name , category , delivered_quantity 
FROM ranking WHERE dn <= 5;

-- PRODUCT WITH THE HIGHEST REVENUE PER UNIT SOLD 
WITH total_revenue AS (
SELECT p.product_name , p.category , SUM(oi.quantity * p.price) AS revenue ,
SUM(CASE WHEN o.status = 'Delivered' THEN oi.quantity ELSE 0 END ) AS delivered_quantity 
FROM products p JOIN order_items  oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Delivered' 
GROUP BY p.product_name , p.category ) ,
revenue_per_unit AS ( 
SELECT product_name , category , revenue , delivered_quantity ,
revenue / delivered_quantity AS revenue_per_unit_sold 
FROM total_revenue ) ,
ranking AS ( 
SELECT product_name , category , revenue , delivered_quantity ,  
revenue_per_unit_sold , DENSE_RANK()  OVER(ORDER BY revenue_per_unit_sold DESC) AS dn 
FROM revenue_per_unit ) 
SELECT product_name , category , revenue , delivered_quantity , revenue_per_unit_sold 
FROM ranking WHERE dn <= 5 ; 

-- PRODUCT REVENUE CONTRIBUTION 
WITH total_revenue AS(
SELECT p.product_name , p.category , SUM(oi.quantity * p.price) AS revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY p.product_name , p.category ) 
SELECT product_name , category ,revenue , revenue / SUM(revenue) OVER() * 100 AS revenue_percentage 
FROM total_revenue ORDER BY revenue_percentage DESC ;

-- CATEGORY REVENUE CONTRIBUTION 
WITH total_revenue AS(
SELECT  p.category , SUM(oi.quantity * p.price) AS revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY  p.category ) 
SELECT  category ,revenue , revenue / SUM(revenue) OVER() * 100 AS revenue_percentage 
FROM total_revenue ORDER BY revenue_percentage DESC ;

-- CATEGORY WITH HIGHEST CANCELLED QUANTITY 
WITH cancelled_quantity AS (
SELECT p.category , 
SUM(CASE WHEN o.status = 'Cancelled' THEN oi.quantity ELSE 0 END) AS cancelled_quantity 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
GROUP BY category
HAVING SUM(CASE WHEN o.status = 'Cancelled' THEN oi.quantity ELSE 0 END ) > 0),
ranking AS (
SELECT category , cancelled_quantity , 
DENSE_RANK() OVER( ORDER BY cancelled_quantity DESC ) AS dn 
FROM cancelled_quantity ) 
SELECT category , cancelled_quantity 
FROM ranking WHERE dn <= 3; 

-- CATEGORY WITH THE HIGHEST EVERAGE PRODUCT PRICE 
WITH average_price AS (
SELECT p.category , AVG(p.price)  AS average_product_price  
FROM products p  GROUP BY p.category ) , 
ranking AS (
SELECT category , average_product_price , 
DENSE_RANK() OVER(ORDER BY average_product_price DESC) AS dn  
FROM average_price)
SELECT category , average_product_price 
FROM ranking WHERE dn <= 3
ORDER BY average_product_price DESC; 

-- PRODUCTS WITH HIGH QUANTITY BUT LOW REVENUE 
WITH amounts AS (
SELECT p.product_name , p.category , 
SUM(CASE WHEN o.status = 'Delivered' THEN oi.quantity ELSE 0 END) AS delivered_quantity , 
SUM(CASE WHEN o.status = 'Delivered' THEN oi.quantity * p.price ELSE 0 END) AS revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id  
JOIN orders o ON oi.order_id = o.order_id 
GROUP BY  p.product_name , p.category ) 
SELECT product_name , category , delivered_quantity , revenue 
FROM amounts 
WHERE delivered_quantity > (SELECT AVG(delivered_quantity) FROM amounts) 
AND 
revenue < (SELECT AVG(revenue) FROM amounts) ; 

-- PRODUCTS WITH THE HIGHEST AVERAGE ORDER QUANTITY
WITH order_count AS (
SELECT p.product_name , p.category ,
SUM(CASE WHEN o.status = 'Delivered' THEN oi.quantity ELSE 0 END) /  
COUNT(DISTINCT CASE WHEN o.status = 'Delivered' THEN o.order_id END) AS  average_order_count
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.product_name ,p.category) ,
ranking AS (
SELECT product_name , category , average_order_count , 
DENSE_RANK() OVER(ORDER BY average_order_count DESC) AS dn 
FROM order_count ) 
SELECT product_name , category , average_order_count
FROM ranking WHERE dn <= 5 ;

-- PRODUCTS WITH THE MOST DISTINCT CUSTOMERS
WITH distinct_customer AS (
SELECT COUNT(DISTINCT o.customer_id) AS unique_customers ,
p.product_name , p.category FROM products p 
JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
JOIN customers c ON o.customer_id = c.customer_id 
WHERE o.status ='Delivered'
GROUP BY p.product_name , p.category) ,
ranking AS (
SELECT product_name , category , unique_customers , 
DENSE_RANK() OVER(ORDER BY unique_customers DESC) AS dn 
FROM distinct_customer ) 
SELECT product_name , category , unique_customers 
FROM ranking WHERE dn <= 5 ; 

-- CUSTOMER REACH BY PRODUCT CATEGORY
WITH distinct_customer_per_product AS (
SELECT COUNT(DISTINCT o.customer_id) AS unique_customers_per_product_count ,
p.product_name , p.category FROM products p 
JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
JOIN customers c ON o.customer_id = c.customer_id 
WHERE o.status ='Delivered'
GROUP BY p.product_name , p.category) ,
distinct_customer_per_category AS (
SELECT COUNT(DISTINCT o.customer_id) AS unique_customers_per_category_count ,
p.category FROM products p 
JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
JOIN customers c ON o.customer_id = c.customer_id 
WHERE o.status ='Delivered'
GROUP BY p.category) 
SELECT pp.product_name , pp.category , unique_customers_per_product_count  AS product_customer ,
unique_customers_per_category_count AS category_customers ,
unique_customers_per_product_count / unique_customers_per_category_count * 100 AS percentage 
FROM distinct_customer_per_product AS pp JOIN distinct_customer_per_category AS pc
ON pp.category = pc.category 
ORDER BY percentage DESC ;

-- PRODUCTS WITH REVENUE ABOVE THEIR CATEGORY AVERAGE
WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity * p.price) AS product_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

category_average AS (
    SELECT
        product_id,
        product_name,
        category,
        product_revenue,
        AVG(product_revenue) OVER (
            PARTITION BY category
        ) AS category_average_product_revenue
    FROM product_revenue
)

SELECT
    product_name,
    category,
    product_revenue,
    category_average_product_revenue
FROM category_average
WHERE product_revenue > category_average_product_revenue
ORDER BY category, product_revenue DESC; 

-- PRODUCT WITH INCREASING SALES OVER TIME
-- PRODUCT WITH INCREASING SALES VS PREVIOUS RECORDED MONTH

WITH monthly_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        SUM(oi.quantity) AS monthly_quantity
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        YEAR(o.order_date),
        MONTH(o.order_date)
),
sales_with_previous AS (
    SELECT
        product_id,
        product_name,
        category,
        order_year,
        order_month,
        monthly_quantity,
        LAG(monthly_quantity) OVER (
            PARTITION BY product_id
            ORDER BY order_year, order_month
        ) AS previous_month_quantity
    FROM monthly_sales
),
latest_sales AS (
    SELECT
        product_id,
        product_name,
        category,
        order_year,
        order_month,
        monthly_quantity,
        previous_month_quantity,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY order_year DESC, order_month DESC
        ) AS rn
    FROM sales_with_previous
)
SELECT
    product_name,
    category,
    previous_month_quantity,
    monthly_quantity AS latest_month_quantity
FROM latest_sales
WHERE rn = 1
  AND previous_month_quantity IS NOT NULL
  AND monthly_quantity > previous_month_quantity
ORDER BY latest_month_quantity DESC;
   
-- PRODUCTS WITH THE HIGHEST REVENUE GROWTH BETWEEN TWO MONTHS 
-- PRODUCTS WITH THE HIGHEST REVENUE GROWTH BETWEEN TWO RECORDED MONTHS

WITH monthly_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        SUM(oi.quantity * p.price) AS monthly_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        YEAR(o.order_date),
        MONTH(o.order_date)
),
revenue_with_previous AS (
    SELECT
        product_id,
        product_name,
        category,
        order_year,
        order_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            PARTITION BY product_id
            ORDER BY order_year, order_month
        ) AS previous_month_revenue
    FROM monthly_revenue
),
latest_revenue AS (
    SELECT
        product_id,
        product_name,
        category,
        order_year,
        order_month,
        monthly_revenue,
        previous_month_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY order_year DESC, order_month DESC
        ) AS rn
    FROM revenue_with_previous
)
SELECT
    product_name,
    category,
    previous_month_revenue,
    monthly_revenue AS latest_month_revenue,
    monthly_revenue - previous_month_revenue AS revenue_growth,
    (monthly_revenue - previous_month_revenue)
        / previous_month_revenue * 100 AS revenue_growth_percentage
FROM latest_revenue
WHERE rn = 1
  AND previous_month_revenue IS NOT NULL
  AND previous_month_revenue > 0
  AND monthly_revenue > previous_month_revenue
ORDER BY revenue_growth_percentage DESC;

-- TOP 3 PRODUCTS BASED ON REVENUE IN EACH CATEGORY 
WITH revenue AS (
SELECT p.product_name , category , SUM(oi.quantity * p.price) AS total_revenue 
FROM products p JOIN order_items oi ON p.product_id = oi.product_id 
JOIN orders o ON oi.order_id = o.order_id 
WHERE o.status = 'Delivered' 
GROUP BY p.product_name , p.category ) ,
ranking AS (
SELECT product_name , category , total_revenue , 
DENSE_RANK() OVER(PARTITION BY category ORDER BY total_revenue DESC) AS dn 
FROM revenue )
SELECT product_name , category , total_revenue 
FROM ranking WHERE dn <= 3 ; 