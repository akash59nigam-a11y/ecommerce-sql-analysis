-- ============================================================
-- E-commerce Sales Analysis — Database Schema
-- Engine: MySQL 8.0+
-- ============================================================

DROP DATABASE IF EXISTS ecommerce_sales;
CREATE DATABASE ecommerce_sales;
USE ecommerce_sales;

-- ------------------------------------------------------------
-- CUSTOMERS
-- ------------------------------------------------------------
CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL,
    city          VARCHAR(50),
    state         VARCHAR(50),
    signup_date   DATE NOT NULL
);

-- ------------------------------------------------------------
-- PRODUCTS
-- ------------------------------------------------------------
CREATE TABLE products (
    product_id   INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category     VARCHAR(50) NOT NULL,
    unit_price   DECIMAL(10, 2) NOT NULL,
    cost_price   DECIMAL(10, 2) NOT NULL
);

-- ------------------------------------------------------------
-- ORDERS
-- ------------------------------------------------------------
CREATE TABLE orders (
    order_id       INT PRIMARY KEY,
    customer_id    INT NOT NULL,
    order_date     DATE NOT NULL,
    order_status   VARCHAR(20) NOT NULL,   -- Delivered / Cancelled / Returned
    shipping_city  VARCHAR(50),
    shipping_state VARCHAR(50),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

-- ------------------------------------------------------------
-- ORDER_ITEMS  (line items — one row per product per order)
-- ------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id      INT NOT NULL,
    product_id    INT NOT NULL,
    quantity      INT NOT NULL,
    unit_price    DECIMAL(10, 2) NOT NULL,   -- price at time of sale
    discount_pct  DECIMAL(5, 2) DEFAULT 0,   -- e.g. 10.00 = 10%
    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
);

-- ------------------------------------------------------------
-- Indexes to speed up common analytical queries
-- ------------------------------------------------------------
CREATE INDEX idx_orders_customer   ON orders (customer_id);
CREATE INDEX idx_orders_date       ON orders (order_date);
CREATE INDEX idx_items_order       ON order_items (order_id);
CREATE INDEX idx_items_product     ON order_items (product_id);

-- ------------------------------------------------------------
-- Load data (run from MySQL client in this project's folder;
-- adjust path and enable local_infile if needed)
-- ------------------------------------------------------------
-- LOAD DATA LOCAL INFILE 'data/customers.csv'
--   INTO TABLE customers FIELDS TERMINATED BY ',' ENCLOSED BY '"'
--   LINES TERMINATED BY '\n' IGNORE 1 ROWS;
--
-- LOAD DATA LOCAL INFILE 'data/products.csv'
--   INTO TABLE products FIELDS TERMINATED BY ',' ENCLOSED BY '"'
--   LINES TERMINATED BY '\n' IGNORE 1 ROWS;
--
-- LOAD DATA LOCAL INFILE 'data/orders.csv'
--   INTO TABLE orders FIELDS TERMINATED BY ',' ENCLOSED BY '"'
--   LINES TERMINATED BY '\n' IGNORE 1 ROWS;
--
-- LOAD DATA LOCAL INFILE 'data/order_items.csv'
--   INTO TABLE order_items FIELDS TERMINATED BY ',' ENCLOSED BY '"'
--   LINES TERMINATED BY '\n' IGNORE 1 ROWS;
