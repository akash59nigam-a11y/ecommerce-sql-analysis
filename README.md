# E-commerce Sales Analysis — SQL

End-to-end SQL analysis of a two-year e-commerce transaction dataset — revenue trends, top products, customer segmentation, and churn risk — using joins, CTEs, window functions, and aggregations on a 50,000+ row relational dataset.

## Business Problem

An e-commerce company wants to understand:
1. Where is revenue coming from — which products, categories, and cities?
2. Who are the most valuable (repeat) customers, and which customers are at risk of churning?
3. How is revenue trending month over month, and what does growth look like?
4. Which products are most profitable, not just highest-selling?

This project answers these questions purely in SQL, on a realistic relational schema.

## Dataset

Synthetic but realistic dataset generated with seasonal purchase patterns (festive-season spike in Oct–Nov), a mix of one-time and repeat customers, and 8 product categories — modeled to mirror real e-commerce transaction data.

| Table | Rows | Description |
|---|---:|---|
| `customers` | 4,000 | Customer profile: name, city, state, signup date |
| `products` | 134 | Product catalog across 8 categories, with unit price & cost price |
| `orders` | 23,000 | One row per order: date, status, shipping location |
| `order_items` | 50,616 | One row per product per order (quantity, price, discount) |

**Entity relationship:**
```
customers 1---* orders 1---* order_items *---1 products
```

## Tech Stack
SQL (MySQL 8.0+) · joins · CTEs · window functions (`RANK`, `ROW_NUMBER`, `LAG`, running totals) · subqueries · `GROUP BY`/`HAVING` aggregation

## Project Structure
```
ecommerce-sql-analysis/
├── data/                     # customers.csv, products.csv, orders.csv, order_items.csv
├── assets/                   # chart exports (revenue trend, top products, category mix)
├── schema.sql                # CREATE TABLE statements + indexes
├── queries.sql                # 14 business queries
├── generate_data.py          # synthetic data generator (reproducible, seeded)
└── README.md
```

## How to Run
1. Import the schema: `mysql -u root -p < schema.sql`
2. Load the CSVs from `data/` into the tables (see `LOAD DATA` commands at the bottom of `schema.sql`, or import via MySQL Workbench's Table Data Import Wizard)
3. Run any query from `queries.sql` against the `ecommerce_sales` database

## Key Queries (see `queries.sql` for all 14)
- **Q3** — Top 10 products by revenue (JOIN + GROUP BY)
- **Q6** — Customer segmentation (New/Regular/VIP) by lifetime spend (subquery + CASE)
- **Q7** — Running total of monthly revenue (CTE + window function)
- **Q8** — Rank top 3 products within each category (CTE + `RANK() OVER PARTITION BY`)
- **Q9** — Month-over-month revenue growth % (`LAG()` window function)
- **Q10** — Churn-risk customers: no order in the last 90 days (subquery + date filtering)
- **Q14** — Top spending customer per state (`ROW_NUMBER() OVER PARTITION BY`)

## Key Insights
*(computed directly from this dataset — see `queries.sql` to reproduce)*

- **₹36.7 Crore** total revenue across **19,407 delivered orders** (avg order value ≈ **₹18,913**)
- **3,586** customers placed at least one delivered order — of these, **2,792 (77.9%)** were repeat customers (2+ orders), showing strong retention
- **Electronics** is the leading category — **₹21.9 Cr revenue** at a **30.5% profit margin**, outperforming every other category combined
- Top single product — **LED Monitor Everyday** — generated **₹2.06 Cr** in revenue (504 units)
- Monthly revenue grew from **₹0.38 Cr (Jan 2024)** to a peak of **₹3.51 Cr (Nov 2025)** — a ~9× increase, driven by both a growing customer base and a clear festive-season (Oct–Nov) spike each year
- Order status split: **84.4% Delivered, 8.2% Cancelled, 7.4% Returned**
- **1,531 customers** haven't ordered in the last 90 days — flagged as churn-risk for re-engagement campaigns

![Monthly Revenue Trend](assets/monthly_revenue_trend.png)
![Top 10 Products by Revenue](assets/top10_products.png)
![Revenue by Category](assets/revenue_by_category.png)

## Possible Extensions
- Connect `queries.sql` outputs to Power BI / Tableau for an interactive dashboard
- Add a cohort retention analysis (revenue by signup-month cohort)
- Build a simple RFM (Recency-Frequency-Monetary) scoring model on top of Q6
