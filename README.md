# E-Commerce Sales & Customer Analytics — MySQL

## Project Overview

This project analyzes an e-commerce dataset using MySQL to understand sales performance, customer behavior, product performance, and order trends.

The analysis focuses on business metrics such as revenue, Average Order Value (AOV), cancellation rate, customer revenue, repeat customers, product performance, and sales trends over time.

## Dataset

- 50 customers
- 20 products
- 100 orders
- 115 order items
- 18 returns
- 60 reviews

The database, tables, and dataset are created using SQL scripts included in the project.

## Tools

- MySQL
- MySQL Workbench

## SQL Skills Used

- SELECT, WHERE, GROUP BY, HAVING, ORDER BY
- INNER JOIN and LEFT JOIN
- CTEs
- Subqueries
- CASE statements
- Aggregate functions
- Date and time functions
- Window functions
- RANK
- DENSE_RANK
- ROW_NUMBER
- LAG
- UNION / UNION ALL
- INTERSECT
- EXCEPT

## Key Metrics

| Metric | Value |
|---|---:|
| Delivered Revenue | ₹15,21,700 |
| Average Order Value | ₹15,527.55 |
| Cancellation Rate | 2% |
| Repeat Customer Rate | 76% |
| Average Delivered Orders per Customer | 1.96 |

## Key Insights

- Electronics generated **87.85% of delivered revenue**.
- The top 10 customers contributed **76.28% of delivered revenue**.
- **Laptop Pro 14** generated the highest product revenue at **₹9,00,000**.
- **Men Cotton Shirt** generated ₹10,500 revenue with an average rating of 3.0.
- **USB-C Charger** had the highest product cancellation rate at 16.67%.
- **Q3 2026** recorded ₹6,91,250 in delivered revenue.
- July 2026 recorded the highest monthly revenue at ₹3,15,900.
- Repeat customer revenue made up a large share of revenue in several months of 2026.

## Project Structure

```text
ecommerce-sql-analysis/
│
├── README.md
│
├── sql/
│   │
│   ├── 00_database_setup.sql
│   │
│   ├── data/
│   │   ├── customer_data.sql
│   │   ├── inserted_data.sql
│   │   ├── orders_data.sql
│   │   ├── order_items_data.sql
│   │   ├── products_data.sql
│   │   ├── return_data.sql
│   │   └── review_data.sql
│   │
│   └── analysis/
│       ├── 01_basic_analysis.sql
│       ├── 02_customer_analysis.sql
│       ├── 03_product_analysis.sql
│       ├── 04_time_analysis.sql
│       └── 05_advance_analysis.sql
│
└── business_insights.md
```

## Analysis Areas

### Basic Analysis

- Dataset overview
- Revenue and AOV
- Order status
- Payment methods
- Product and category performance

### Customer Analysis

- Customer revenue
- Repeat customers
- Customer purchase frequency
- Customer contribution
- Customer segmentation
- Customer behavior by city and category

### Product Analysis

- Product quantity and revenue
- Category performance
- Product rankings
- Product ratings
- Cancellation analysis
- Revenue growth

### Time Analysis

- Monthly revenue
- Quarterly revenue
- Yearly revenue
- Month-over-month growth
- Day-of-week revenue
- New vs repeat customer revenue

### Advanced Analysis

- Customer Lifetime Revenue (CLV proxy)
- Pareto customer analysis
- RFM analysis
- Cohort analysis
- Cross-selling analysis
- Customer spending changes

## How to Run

1. Open MySQL Workbench.
2. Run `sql/00_database_setup.sql` to create the database and tables.
3. Run the SQL files inside `sql/data/` to insert the dataset.
4. Run the analysis files inside `sql/analysis/` to perform the analysis.
5. Review the query results and business insights.

## Notes

Revenue is calculated using product price × quantity for delivered orders.

2026 data is available through September 2026, so 2026 figures represent the available period rather than a complete calendar year.
