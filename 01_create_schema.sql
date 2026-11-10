
DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20),
    city VARCHAR(80),
    state VARCHAR(80),
    signup_date DATE NOT NULL
);

CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    product_name VARCHAR(120) NOT NULL,
    brand VARCHAR(80),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_products_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
);

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_status ENUM('Pending','Processing','Shipped','Delivered','Cancelled') NOT NULL,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    discount_pct DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (discount_pct BETWEEN 0 AND 100),
    CONSTRAINT fk_items_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id),
    CONSTRAINT fk_items_product FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    payment_date DATE NOT NULL,
    payment_method ENUM('UPI','Credit Card','Debit Card','Net Banking','Cash on Delivery') NOT NULL,
    payment_status ENUM('Pending','Paid','Failed','Refunded') NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    transaction_ref VARCHAR(60) UNIQUE,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);

CREATE TABLE shipments (
    shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    courier_name VARCHAR(80),
    shipment_date DATE,
    delivery_date DATE,
    shipping_status ENUM('Not Shipped','In Transit','Delivered','Delayed','Returned') NOT NULL,
    shipping_fee DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (shipping_fee >= 0),
    CONSTRAINT fk_shipments_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id),
    CHECK (delivery_date IS NULL OR shipment_date IS NULL OR delivery_date >= shipment_date)
);

CREATE TABLE returns (
    return_id INT AUTO_INCREMENT PRIMARY KEY,
    order_item_id INT NOT NULL,
    return_date DATE NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    return_reason ENUM('Damaged','Wrong Item','Size Issue','Not as Expected','Late Delivery','Other') NOT NULL,
    refund_amount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (refund_amount >= 0),
    return_status ENUM('Requested','Approved','Rejected','Refunded') NOT NULL,
    CONSTRAINT fk_returns_item FOREIGN KEY (order_item_id)
        REFERENCES order_items(order_item_id)
);

CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
