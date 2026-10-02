# Business Insights

## Overview

This project analyzes e-commerce sales, customers, products and order trends using MySQL.

Dataset:
- 50 customers
- 20 products
- 100 orders
- 115 order items
- 18 returns
- 60 reviews

## Sales Performance

Total delivered revenue: ₹15,21,700

AOV: ₹15,527.55

Cancellation rate: 2%

### Revenue by Category

| Category | Revenue | Share |
|---|---:|---:|
| Electronics | ₹13,36,800 | 87.85% |
| Clothing | ₹68,800 | 4.52% |
| Sports | ₹53,900 | 3.54% |
| Home & Kitchen | ₹44,300 | 2.91% |
| Beauty | ₹17,900 | 1.18% |

Electronics generated the largest share of revenue at 87.85%.

## Customer Analysis

The top revenue-generating customers were:

| Customer | Revenue |
|---|---:|
| Sneha | ₹2,31,000 |
| Yash Thakur | ₹1,51,200 |
| Dev Malhotra | ₹1,50,000 |
| Aman Srivastava | ₹1,50,000 |
| Aarav Sharma | ₹97,800 |
| Rahul Verma | ₹86,500 |

The top 10 customers contributed 76.28% of delivered revenue.

Repeat customer rate: 76%.

Average delivered orders per customer: 1.96.

## Product Analysis

Laptop Pro 14 generated the highest product revenue at ₹9,00,000.

Men Cotton Shirt generated ₹10,500 revenue with an average rating of 3.0.

USB-C Charger had the highest product cancellation rate at 16.67%.

## Time Analysis

The highest recorded monthly revenue was July 2026 at ₹3,15,900.

Q3 2026 recorded ₹6,91,250 in delivered revenue.

Note: 2026 data is available only through September.

## New vs Repeat Revenue

July 2026:
- New customer revenue: ₹77,400
- Repeat customer revenue: ₹2,38,500
- Total: ₹3,15,900

August 2026:
- New customer revenue: ₹0
- Repeat customer revenue: ₹2,59,850

September 2026:
- New customer revenue: ₹0
- Repeat customer revenue: ₹1,15,500

## RFM Analysis

The project calculates:

- Recency — days since latest delivered order
- Frequency — number of delivered orders
- Monetary — total delivered revenue

The project currently uses raw RFM values and does not assign RFM scores.

## Business Recommendations

- Monitor the high concentration of revenue in Electronics.
- Analyze high-value customers for retention opportunities.
- Investigate products with relatively low ratings but meaningful revenue.
- Investigate products with higher cancellation rates.
- Explore cross-selling opportunities using customer category combinations.

## Limitations

- Dataset contains only 100 orders.
- 2026 data is available through September.
- Revenue is calculated using product price × quantity.
- Discounts, shipping costs, taxes and profit margins are not included.
- CLV analysis represents historical customer revenue rather than predictive CLV.