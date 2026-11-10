-- Ecommerce SQL Analysis Queries
USE ecommerce_db;

-- A. Basic exploration
-- 1. View all customers
SELECT * FROM customers;

-- 2. Count records in each table
SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;

-- 3. List products with category names
SELECT p.product_id, p.product_name, c.category_name, p.price
FROM products p JOIN categories c ON p.category_id = c.category_id
ORDER BY c.category_name, p.product_name;

-- 4. Orders placed in 2025
SELECT * FROM orders
WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01';

-- B. Sales and revenue
-- Revenue here is item value after line-level discount, excluding shipping.
-- 5. Total gross sales before discount
SELECT ROUND(SUM(quantity * unit_price),2) AS gross_sales
FROM order_items oi JOIN orders o ON oi.order_id=o.order_id
WHERE o.order_status <> 'Cancelled';

-- 6. Net item sales after discount
SELECT ROUND(SUM(quantity * unit_price * (1-discount_pct/100)),2) AS net_item_sales
FROM order_items oi JOIN orders o ON oi.order_id=o.order_id
WHERE o.order_status <> 'Cancelled';

-- 7. Total orders and unique customers
SELECT COUNT(*) AS total_orders, COUNT(DISTINCT customer_id) AS unique_customers
FROM orders;

-- 8. Average order value (AOV), excluding cancelled orders
WITH order_totals AS (
  SELECT o.order_id,
         SUM(oi.quantity * oi.unit_price * (1-oi.discount_pct/100)) AS order_value
  FROM orders o JOIN order_items oi ON o.order_id=oi.order_id
  WHERE o.order_status <> 'Cancelled'
  GROUP BY o.order_id
)
SELECT ROUND(AVG(order_value),2) AS average_order_value FROM order_totals;

-- 9. Monthly sales trend
SELECT DATE_FORMAT(o.order_date,'%Y-%m') AS sales_month,
       ROUND(SUM(oi.quantity*oi.unit_price*(1-oi.discount_pct/100)),2) AS revenue
FROM orders o JOIN order_items oi ON o.order_id=oi.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY DATE_FORMAT(o.order_date,'%Y-%m')
ORDER BY sales_month;

-- 10. Monthly order count
SELECT DATE_FORMAT(order_date,'%Y-%m') AS sales_month, COUNT(*) AS orders_count
FROM orders
GROUP BY DATE_FORMAT(order_date,'%Y-%m')
ORDER BY sales_month;

-- C. Product and category performance
-- 11. Top 10 products by revenue
SELECT p.product_name,
       ROUND(SUM(oi.quantity*oi.unit_price*(1-oi.discount_pct/100)),2) AS revenue
FROM order_items oi JOIN products p ON oi.product_id=p.product_id
JOIN orders o ON oi.order_id=o.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY p.product_id,p.product_name
ORDER BY revenue DESC LIMIT 10;

-- 12. Best-selling products by quantity
SELECT p.product_name, SUM(oi.quantity) AS units_sold
FROM order_items oi JOIN products p ON oi.product_id=p.product_id
JOIN orders o ON oi.order_id=o.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY p.product_id,p.product_name
ORDER BY units_sold DESC;

-- 13. Revenue by category
SELECT c.category_name,
       ROUND(SUM(oi.quantity*oi.unit_price*(1-oi.discount_pct/100)),2) AS revenue
FROM categories c JOIN products p ON c.category_id=p.category_id
JOIN order_items oi ON p.product_id=oi.product_id
JOIN orders o ON oi.order_id=o.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY c.category_id,c.category_name
ORDER BY revenue DESC;

-- 14. Products never ordered
SELECT p.product_id,p.product_name
FROM products p LEFT JOIN order_items oi ON p.product_id=oi.product_id
WHERE oi.product_id IS NULL;

-- 15. Low-stock products
SELECT product_name,stock_quantity
FROM products WHERE stock_quantity < 30
ORDER BY stock_quantity;

-- D. Customer analysis
-- 16. Top 10 customers by spending
SELECT c.customer_id,c.customer_name,
       ROUND(SUM(oi.quantity*oi.unit_price*(1-oi.discount_pct/100)),2) AS lifetime_value
FROM customers c JOIN orders o ON c.customer_id=o.customer_id
JOIN order_items oi ON o.order_id=oi.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY c.customer_id,c.customer_name
ORDER BY lifetime_value DESC LIMIT 10;

-- 17. Customers who have never ordered
SELECT c.customer_id,c.customer_name
FROM customers c LEFT JOIN orders o ON c.customer_id=o.customer_id
WHERE o.order_id IS NULL;

-- 18. Customer order frequency
SELECT c.customer_name,COUNT(o.order_id) AS order_count
FROM customers c LEFT JOIN orders o ON c.customer_id=o.customer_id
GROUP BY c.customer_id,c.customer_name
ORDER BY order_count DESC;

-- 19. Customers with more than 3 orders
SELECT c.customer_name,COUNT(*) AS order_count
FROM customers c JOIN orders o ON c.customer_id=o.customer_id
GROUP BY c.customer_id,c.customer_name
HAVING COUNT(*) > 3;

-- 20. Repeat customers
SELECT COUNT(*) AS repeat_customers
FROM (
  SELECT customer_id FROM orders
  GROUP BY customer_id HAVING COUNT(*) > 1
) x;

-- E. Order, payment and delivery analysis
-- 21. Orders by status
SELECT order_status,COUNT(*) AS order_count
FROM orders GROUP BY order_status ORDER BY order_count DESC;

-- 22. Payment method usage
SELECT payment_method,COUNT(*) AS transactions,
       ROUND(SUM(amount),2) AS payment_amount
FROM payments
WHERE payment_status='Paid'
GROUP BY payment_method ORDER BY payment_amount DESC;

-- 23. Failed payment count
SELECT COUNT(*) AS failed_payments
FROM payments WHERE payment_status='Failed';

-- 24. Average delivery time in days
SELECT ROUND(AVG(DATEDIFF(delivery_date,shipment_date)),1) AS avg_delivery_days
FROM shipments WHERE delivery_date IS NOT NULL;

-- 25. Delivered shipments taking more than 5 days
SELECT order_id,courier_name,shipment_date,delivery_date,
       DATEDIFF(delivery_date,shipment_date) AS delivery_days
FROM shipments
WHERE delivery_date IS NOT NULL
  AND DATEDIFF(delivery_date,shipment_date) > 5
ORDER BY delivery_days DESC;

-- F. Returns analysis
-- 26. Return count and refund value by reason
SELECT return_reason,COUNT(*) AS return_cases,
       ROUND(SUM(refund_amount),2) AS total_refund
FROM returns
GROUP BY return_reason ORDER BY return_cases DESC;

-- 27. Returned products
SELECT p.product_name,SUM(r.quantity) AS returned_units,
       ROUND(SUM(r.refund_amount),2) AS refund_amount
FROM returns r JOIN order_items oi ON r.order_item_id=oi.order_item_id
JOIN products p ON oi.product_id=p.product_id
GROUP BY p.product_id,p.product_name
ORDER BY returned_units DESC;

-- 28. Return rate by order item units (simple unit-based rate)
SELECT ROUND(
  100.0 * (SELECT COALESCE(SUM(quantity),0) FROM returns)
  / NULLIF((SELECT COALESCE(SUM(oi.quantity),0)
            FROM order_items oi JOIN orders o ON oi.order_id=o.order_id
            WHERE o.order_status <> 'Cancelled'),0),2
) AS return_unit_rate_pct;



