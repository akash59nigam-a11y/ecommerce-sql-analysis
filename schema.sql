-- E-commerce Sales Analysis — Database Schema
DROP DATABASE IF EXISTS ecommerce_sales;
CREATE DATABASE ecommerce_sales;
USE ecommerce_sales;

CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL,
    city          VARCHAR(50),
    state         VARCHAR(50),
    signup_date   DATE NOT NULL
);


CREATE TABLE products (
    product_id   INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category     VARCHAR(50) NOT NULL,
    unit_price   DECIMAL(10, 2) NOT NULL,
    cost_price   DECIMAL(10, 2) NOT NULL
);

CREATE TABLE orders (
    order_id       INT PRIMARY KEY,
    customer_id    INT NOT NULL,
    order_date     DATE NOT NULL,
    order_status   VARCHAR(20) NOT NULL,  
    shipping_city  VARCHAR(50),
    shipping_state VARCHAR(50),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);


CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id      INT NOT NULL,
    product_id    INT NOT NULL,
    quantity      INT NOT NULL,
    unit_price    DECIMAL(10, 2) NOT NULL,   -- price at time of sale
    discount_pct  DECIMAL(5, 2) DEFAULT 0,   
    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
);


CREATE INDEX idx_orders_customer   ON orders (customer_id);
CREATE INDEX idx_orders_date       ON orders (order_date);
CREATE INDEX idx_items_order       ON order_items (order_id);
CREATE INDEX idx_items_product     ON order_items (product_id);


