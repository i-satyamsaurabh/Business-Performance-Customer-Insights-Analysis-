-- ============================================================================
-- Business Performance & Customer Insights
-- PostgreSQL - EDA
-- ============================================================================

-- 1. Overall KPI Summary
SELECT
    COUNT(transaction_id)       AS total_orders,
    SUM(total_amount)           AS total_revenue,
    SUM(profit)                 AS total_profit,
    AVG(total_amount)           AS avg_order_value,
    AVG(profit_margin_pct)      AS avg_profit_margin,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(quantity)               AS total_units_sold
FROM Sales;

-- 2. Monthly Revenue Trend
-- (PostgreSQL uses TO_CHAR for date formatting)
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM') AS year_month,
    COUNT(transaction_id)                AS total_orders,
    SUM(total_amount)                    AS revenue,
    SUM(profit)                          AS profit,
    AVG(profit_margin_pct)               AS avg_margin
FROM Sales
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
ORDER BY year_month;

-- 3. Category-wise Performance
SELECT
    category,
    COUNT(transaction_id)  AS orders,
    SUM(quantity)          AS units_sold,
    SUM(total_amount)      AS revenue,
    SUM(profit)            AS profit,
    AVG(profit_margin_pct) AS avg_margin,
    SUM(total_amount) * 100.0 / 
        (SELECT SUM(total_amount) FROM Sales) AS revenue_share_pct
FROM Sales
GROUP BY category
ORDER BY revenue DESC;

-- 4. Store / Channel Performance
SELECT
    store_location,
    COUNT(transaction_id)  AS orders,
    SUM(total_amount)      AS revenue,
    SUM(profit)            AS profit,
    AVG(profit_margin_pct) AS avg_margin
FROM Sales
GROUP BY store_location
ORDER BY revenue DESC;

-- 5. Revenue by Customer Type (JOIN Example)
SELECT
    c.customer_type,
    COUNT(DISTINCT s.customer_id) AS customers,
    COUNT(s.transaction_id)       AS orders,
    SUM(s.total_amount)           AS revenue,
    AVG(s.total_amount)           AS avg_order_value,
    SUM(s.total_amount) * 100.0 / 
        (SELECT SUM(total_amount) FROM Sales) AS revenue_share_pct
FROM Sales s
JOIN Customers c
    ON s.customer_id = c.customer_id
GROUP BY c.customer_type
ORDER BY revenue DESC;

-- 6. Revenue by Age Group
SELECT
    c.age_group,
    COUNT(DISTINCT s.customer_id) AS customers,
    COUNT(s.transaction_id)       AS orders,
    SUM(s.total_amount)           AS revenue
FROM Sales s
JOIN Customers c
    ON s.customer_id = c.customer_id
GROUP BY c.age_group
ORDER BY revenue DESC;

-- 7. Top 10 Customers by Revenue
SELECT
    s.customer_id,
    c.customer_name,
    c.customer_type,
    c.city,
    COUNT(s.transaction_id) AS total_orders,
    SUM(s.total_amount)     AS total_revenue
FROM Sales s
JOIN Customers c
    ON s.customer_id = c.customer_id
GROUP BY 
    s.customer_id, 
    c.customer_name, 
    c.customer_type, 
    c.city
ORDER BY total_revenue DESC
LIMIT 10;

-- 8. Customer Retention 
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(transaction_id) AS num_purchases
    FROM Sales
    GROUP BY customer_id
),
segmented AS (
    SELECT
        customer_id,
        num_purchases,
        CASE
            WHEN num_purchases = 1 THEN 'One-time'
            WHEN num_purchases BETWEEN 2 AND 3 THEN 'Occasional'
            WHEN num_purchases BETWEEN 4 AND 6 THEN 'Regular'
            ELSE 'Loyal'
        END AS segment
    FROM customer_orders
)
SELECT
    segment,
    COUNT(customer_id) AS customers,
    AVG(num_purchases) AS avg_purchases
FROM segmented
GROUP BY segment
ORDER BY segment;

-- 9. Top Product per Category (Window Function)
SELECT *
FROM (
    SELECT
        s.category,
        s.product_id,
        p.product_name,
        SUM(s.total_amount) AS revenue,
        SUM(s.quantity)     AS units_sold,
        RANK() OVER (
            PARTITION BY s.category
            ORDER BY SUM(s.total_amount) DESC
        ) AS rank_in_category
    FROM Sales s
    JOIN Products p
        ON s.product_id = p.product_id
    GROUP BY 
        s.category, 
        s.product_id, 
        p.product_name
) ranked
WHERE rank_in_category <= 2
ORDER BY category, rank_in_category;

-- 10. Running Total Revenue (Window Function)
SELECT
    year_month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY year_month) AS cumulative_revenue
FROM (
    SELECT
        TO_CHAR(transaction_date, 'YYYY-MM') AS year_month,
        SUM(total_amount)                    AS monthly_revenue
    FROM Sales
    GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
) t
ORDER BY year_month;

-- 11. Discount Impact on Profit Margin
SELECT
    discount_applied,
    COUNT(transaction_id)  AS orders,
    SUM(total_amount)      AS revenue,
    AVG(profit_margin_pct) AS avg_margin
FROM Sales
GROUP BY discount_applied
ORDER BY discount_applied;

-- 12. Outlier vs Clean Transactions (Subquery)
SELECT
    CASE
        WHEN is_outlier = 1 THEN 'Outlier'
        ELSE 'Clean'
    END AS type,
    COUNT(*)          AS transactions,
    AVG(total_amount) AS avg_order_value,
    SUM(total_amount) AS total_revenue
FROM Sales
GROUP BY 
    CASE
        WHEN is_outlier = 1 THEN 'Outlier'
        ELSE 'Clean'
    END;