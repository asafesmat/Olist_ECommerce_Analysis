use Olist_Ecommerce;

SELECT * FROM olist_customers_dataset

-- =====================================================
-- TASK 1: SALES & REVENUE ANALYSIS
-- =====================================================

SELECT 
    YEAR(o.order_purchase_timestamp) AS Year,
    MONTH(o.order_purchase_timestamp) AS Month,
    FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS Year_Month,
    p.product_category_name AS Category,
    COUNT(DISTINCT o.order_id) AS Total_Orders,
    COUNT(oi.order_item_id) AS Items_Sold,
    ROUND(SUM(oi.price), 2) AS Total_Revenue,
    ROUND(SUM(op.payment_value), 2) AS Total_Payment,
    ROUND(AVG(oi.price), 2) AS Avg_Item_Price,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS Revenue_Per_Order
FROM dbo.olist_orders_dataset o
INNER JOIN dbo.olist_order_items_dataset oi 
    ON o.order_id = oi.order_id
INNER JOIN dbo.olist_products_dataset p 
    ON oi.product_id = p.product_id
LEFT JOIN dbo.olist_order_payments_dataset op 
    ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
    AND o.order_purchase_timestamp IS NOT NULL
GROUP BY 
    YEAR(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp),
    FORMAT(o.order_purchase_timestamp, 'yyyy-MM'),
    p.product_category_name
ORDER BY Year_Month DESC, Total_Revenue DESC;



-- =====================================================
-- TASK 2: DELIVERY PERFORMANCE ANALYSIS
-- =====================================================

SELECT 
    c.customer_state AS State,
    COUNT(DISTINCT o.order_id) AS Total_Orders,
    COUNT(CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 1 
    END) AS Late_Orders,
    ROUND(
        CAST(COUNT(CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
            THEN 1 
        END) AS FLOAT) / COUNT(*) * 100, 
        2
    ) AS Late_Delivery_Percent,
    ROUND(
        AVG(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)), 
        2
    ) AS Avg_Delivery_Days,
    ROUND(
        AVG(CAST(
            DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) 
            AS FLOAT
        )), 
        2
    ) AS Avg_Days_Late,
    MIN(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS Min_Delivery_Days,
    MAX(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS Max_Delivery_Days
FROM dbo.olist_orders_dataset o
INNER JOIN dbo.olist_customers_dataset c 
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' 
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY Late_Delivery_Percent DESC, Total_Orders DESC;


-- =====================================================
-- TASK 3: SELLER PERFORMANCE ANALYSIS
-- =====================================================

SELECT 
    s.seller_id AS Seller_ID,
    s.seller_state AS Seller_State,
    COUNT(DISTINCT o.order_id) AS Total_Orders,
    COUNT(DISTINCT oi.order_item_id) AS Total_Items,
    ROUND(SUM(oi.price), 2) AS Total_Revenue,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS Avg_Revenue_Per_Order,
    ROUND(AVG(CAST(r.review_score AS FLOAT)), 2) AS Avg_Rating,
    COUNT(CASE WHEN r.review_score <= 2 THEN 1 END) AS Low_Ratings_Count,
    COUNT(CASE WHEN r.review_score >= 4 THEN 1 END) AS High_Ratings_Count,
    COUNT(CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 1 
    END) AS Late_Deliveries,
    ROUND(
        AVG(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)), 
        2
    ) AS Avg_Delivery_Days,
    ROUND(
        CAST(COUNT(CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
            THEN 1 
        END) AS FLOAT) / COUNT(DISTINCT o.order_id) * 100, 
        2
    ) AS Late_Delivery_Percent
FROM dbo.olist_sellers_dataset s
INNER JOIN dbo.olist_order_items_dataset oi 
    ON s.seller_id = oi.seller_id
INNER JOIN dbo.olist_orders_dataset o 
    ON oi.order_id = o.order_id
LEFT JOIN dbo.olist_order_reviews_dataset r 
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 5
ORDER BY Total_Revenue DESC;

-- =====================================================
-- TASK 4: CUSTOMER SATISFACTION & REVIEW ANALYSIS
-- =====================================================

SELECT 
    p.product_category_name AS Category,
    r.review_score AS Review_Score,
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 'Late'
        ELSE 'On Time'
    END AS Delivery_Status,
    COUNT(r.review_id) AS Review_Count,
    ROUND(
        CAST(COUNT(r.review_id) AS FLOAT) / 
        (SELECT COUNT(*) FROM dbo.olist_order_reviews_dataset) * 100, 
        2
    ) AS Percentage_Of_Total,
    COUNT(DISTINCT o.order_id) AS Distinct_Orders,
    ROUND(AVG(CAST(r.review_score AS FLOAT)), 2) AS Avg_Score_In_Group,
    COUNT(CASE WHEN r.review_score = 1 THEN 1 END) AS Score_1_Count,
    COUNT(CASE WHEN r.review_score = 2 THEN 1 END) AS Score_2_Count,
    COUNT(CASE WHEN r.review_score = 3 THEN 1 END) AS Score_3_Count,
    COUNT(CASE WHEN r.review_score = 4 THEN 1 END) AS Score_4_Count,
    COUNT(CASE WHEN r.review_score = 5 THEN 1 END) AS Score_5_Count
FROM dbo.olist_order_reviews_dataset r
INNER JOIN dbo.olist_order_items_dataset oi 
    ON r.order_id = oi.order_id
INNER JOIN dbo.olist_products_dataset p 
    ON oi.product_id = p.product_id
INNER JOIN dbo.olist_orders_dataset o 
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY 
    p.product_category_name, 
    r.review_score,
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 'Late'
        ELSE 'On Time'
    END
ORDER BY Review_Count DESC, Review_Score DESC;