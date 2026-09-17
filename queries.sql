-- ============================================================
-- E-commerce Sales Analysis — Business Queries
-- Engine: MySQL 8.0+ (window functions require 8.0+)
-- Revenue = quantity * unit_price * (1 - discount_pct/100)
-- Only "Delivered" orders are counted as realized revenue
-- unless a query is explicitly about order status itself.
-- ============================================================


-- ------------------------------------------------------------
-- Q1. Headline numbers: total revenue, orders, AOV
-- Technique: JOIN + aggregation
-- ------------------------------------------------------------
SELECT
    COUNT(DISTINCT o.order_id)                                  AS delivered_orders,
    ROUND(SUM(oi.quantity * oi.unit_price
              * (1 - oi.discount_pct / 100)), 2)                 AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price
              * (1 - oi.discount_pct / 100))
          / COUNT(DISTINCT o.order_id), 2)                       AS avg_order_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered';


-- ------------------------------------------------------------
-- Q2. Monthly revenue trend
-- Technique: JOIN + GROUP BY + date functions
-- ------------------------------------------------------------
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m')                          AS month,
    COUNT(DISTINCT o.order_id)                                  AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price
              * (1 - oi.discount_pct / 100)), 2)                 AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month;


-- ------------------------------------------------------------
-- Q3. Top 10 best-selling products by revenue
-- Technique: JOIN + GROUP BY + aggregation + LIMIT
-- ------------------------------------------------------------
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity)                                            AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price
              * (1 - oi.discount_pct / 100)), 2)                 AS revenue
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;


-- ------------------------------------------------------------
-- Q4. Revenue and profit margin by category
-- Technique: JOIN + GROUP BY + derived aggregation
-- ------------------------------------------------------------
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price
              * (1 - oi.discount_pct / 100)), 2)                 AS revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price * (1 - oi.discount_pct / 100)
              - p.cost_price)), 2)                                AS profit,
    ROUND(100 * SUM(oi.quantity * (oi.unit_price * (1 - oi.discount_pct / 100)
              - p.cost_price))
          / SUM(oi.quantity * oi.unit_price
              * (1 - oi.discount_pct / 100)), 2)                  AS profit_margin_pct
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY revenue DESC;


-- ------------------------------------------------------------
-- Q5. Repeat customers (more than one delivered order)
-- Technique: JOIN + GROUP BY + HAVING
-- ------------------------------------------------------------
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    COUNT(DISTINCT o.order_id)                                  AS orders_placed,
    ROUND(SUM(oi.quantity * oi.unit_price
              * (1 - oi.discount_pct / 100)), 2)                 AS lifetime_revenue
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.customer_name, c.city
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY lifetime_revenue DESC;


-- ------------------------------------------------------------
-- Q6. Customer segmentation by lifetime spend (New / Regular / VIP)
-- Technique: subquery + CASE
-- ------------------------------------------------------------
SELECT
    segment,
    COUNT(*)                                                    AS customers,
    ROUND(AVG(lifetime_revenue), 2)                             AS avg_lifetime_revenue
FROM (
    SELECT
        c.customer_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS lifetime_revenue,
        CASE
            WHEN SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) >= 50000 THEN 'VIP'
            WHEN SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) >= 15000 THEN 'Regular'
            ELSE 'New'
        END AS segment
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.customer_id
) AS customer_spend
GROUP BY segment
ORDER BY avg_lifetime_revenue DESC;


-- ------------------------------------------------------------
-- Q7. Monthly revenue with running total (cumulative revenue)
-- Technique: CTE + window function (SUM() OVER)
-- ------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m')                      AS month,
        SUM(oi.quantity * oi.unit_price
            * (1 - oi.discount_pct / 100))                      AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    month,
    ROUND(revenue, 2)                                           AS monthly_revenue,
    ROUND(SUM(revenue) OVER (ORDER BY month), 2)                AS running_total_revenue
FROM monthly_revenue
ORDER BY month;


-- ------------------------------------------------------------
-- Q8. Rank products within their category by revenue
-- Technique: window function (RANK() ... PARTITION BY)
-- ------------------------------------------------------------
WITH product_revenue AS (
    SELECT
        p.category,
        p.product_name,
        SUM(oi.quantity * oi.unit_price
            * (1 - oi.discount_pct / 100))                      AS revenue
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY p.category, p.product_name
),
ranked_products AS (
    SELECT
        category,
        product_name,
        ROUND(revenue, 2)                                       AS revenue,
        RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_in_category
    FROM product_revenue
)
SELECT * FROM ranked_products
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category;


-- ------------------------------------------------------------
-- Q9. Month-over-month revenue growth %
-- Technique: CTE + window function (LAG())
-- ------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m')                      AS month,
        SUM(oi.quantity * oi.unit_price
            * (1 - oi.discount_pct / 100))                      AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    month,
    ROUND(revenue, 2)                                           AS revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2)      AS mom_change,
    ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY month))
          / LAG(revenue) OVER (ORDER BY month), 2)               AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;


-- ------------------------------------------------------------
-- Q10. Churn-risk customers: no delivered order in the last 90 days
-- (relative to the most recent order date in the dataset)
-- Technique: subquery + date filtering
-- ------------------------------------------------------------
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    MAX(o.order_date)                                           AS last_order_date
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.customer_name, c.city
HAVING MAX(o.order_date) < (
    SELECT DATE_SUB(MAX(order_date), INTERVAL 90 DAY) FROM orders
)
ORDER BY last_order_date;


-- ------------------------------------------------------------
-- Q11. Top 10 cities by revenue
-- Technique: JOIN + GROUP BY + aggregation
-- ------------------------------------------------------------
SELECT
    o.shipping_city,
    COUNT(DISTINCT o.order_id)                                  AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price
              * (1 - oi.discount_pct / 100)), 2)                 AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY o.shipping_city
ORDER BY revenue DESC
LIMIT 10;


-- ------------------------------------------------------------
-- Q12. Order status breakdown (Delivered / Cancelled / Returned)
-- Technique: GROUP BY + aggregation, no JOIN needed
-- ------------------------------------------------------------
SELECT
    order_status,
    COUNT(*)                                                    AS num_orders,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2)     AS pct_of_total
FROM orders
GROUP BY order_status
ORDER BY num_orders DESC;


-- ------------------------------------------------------------
-- Q13. Top 10 highest profit-margin products (min. 50 units sold)
-- Technique: JOIN + GROUP BY + HAVING + derived aggregation
-- ------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity)                                            AS units_sold,
    ROUND(100 * AVG((oi.unit_price * (1 - oi.discount_pct / 100)
          - p.cost_price) / oi.unit_price), 2)                   AS avg_margin_pct
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category
HAVING SUM(oi.quantity) >= 50
ORDER BY avg_margin_pct DESC
LIMIT 10;


-- ------------------------------------------------------------
-- Q14. Top spending customer in each state
-- Technique: CTE + window function (ROW_NUMBER() ... PARTITION BY)
-- ------------------------------------------------------------
WITH customer_state_spend AS (
    SELECT
        c.state,
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price
            * (1 - oi.discount_pct / 100))                      AS revenue,
        ROW_NUMBER() OVER (
            PARTITION BY c.state ORDER BY
            SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) DESC
        ) AS rn
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.state, c.customer_id, c.customer_name
)
SELECT state, customer_name, ROUND(revenue, 2) AS revenue
FROM customer_state_spend
WHERE rn = 1
ORDER BY revenue DESC;
