use retail_events_db
SELECT * FROM dim_campaigns
SELECT * FROM dim_products
SELECT * FROM dim_stores
SELECT * FROM fact_events

SELECT 
	store_id,
   SUM(base_price * `quantity_sold(after_promo)`) AS Sales_after_promo
FROM fact_events
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- 10 BOTTOM STORES ON SOLD UNITS 
SELECT
	store_id,
    `quantity_sold(after_promo)`
FROM fact_events
ORDER BY 2 ASC
LIMIT 10

-- STORE PERFORMANCE BY CITIES
SELECT 
	fe.store_id,
    ds.city,
    fe.promo_type,
    `quantity_sold(after_promo)`
FROM fact_events fe
	LEFT JOIN dim_stores ds
		ON ds.store_id = fe.store_id
ORDER BY 4 DESC
LIMIT 10; -- the promo type among top quantity sold in performing sotres is BOGOF

-- PROMOTION TYPE ANALYSIS
-- 2 TOP PROMOTION TYPE

SELECT
		promo_type,
        SUM(base_price * `quantity_sold(after_promo)`) AS Sales_after_promo
FROM fact_events
GROUP BY 1
ORDER BY 2
LIMIT 2;

 -- BOTTOM 2 PROMOTION TYPE AND ITS IMPACT QUANTITY SOLD
 SELECT 
	promo_type,
    SUM(`quantity_sold(after_promo)`) AS Qnty_sold_after_promo
 FROM fact_events
 GROUP BY 1
 ORDER BY 2 ASC
 LIMIT 2
 
 -- difference in promotoion type 
 SELECT
	promo_type,
    SUM(CASE WHEN promo_type = '50% OFF' THEN `quantity_sold(after_promo)` ELSE NULL END) AS Qnty_sold_50_discount,
    SUM(CASE WHEN promo_type = '25% OFF' THEN `quantity_sold(after_promo)` ELSE NULL END) AS Qnty_sold_25_discount,
    SUM(CASE WHEN promo_type = '500 Cashback' THEN `quantity_sold(after_promo)` ELSE NULL END) AS Qnty_sold_cashback,
    SUM(CASE WHEN promo_type = 'BOGOF' THEN `quantity_sold(after_promo)` ELSE NULL END) AS Qnty_sold_BOGOF
 FROM fact_events
 GROUP BY 1
 
 SELECT
	promo_type,
    SUM(`quantity_sold(after_promo)`) AS Qnty_sold
 FROM fact_events
 GROUP BY 1;
 
 -- PRODUCT AND CATEGORY
 SELECT 
	dm.category,
    SUM(base_price * `quantity_sold(before_promo)`) AS Before_promo_sales, -- to compare the sales before and after promo
    SUM(base_price * `quantity_sold(after_promo)`) AS After_promo_sales
 FROM fact_events fe
	LEFT JOIN dim_products dm
		ON dm.product_code = fe.product_code
GROUP BY 1
ORDER BY 3, 2 DESC;

-- Specific Product Response
 SELECT 
	dm.product_name,
    SUM(base_price * `quantity_sold(after_promo)`) AS After_promo_sales,
    SUM(base_price * `quantity_sold(before_promo)`) AS Before_promo_sales, 
    SUM(base_price * `quantity_sold(after_promo)`) - SUM(base_price * `quantity_sold(before_promo)`) AS Diff_promo
 FROM fact_events fe
	LEFT JOIN dim_products dm
		ON dm.product_code = fe.product_code
GROUP BY 1
ORDER BY 2, 3 ASC;

-- CORRELATION BETWEEN PRODUCT CATEGORY AND PROMOTION TYPE 
SELECT
	category,
	promo_type,
    SUM(`quantity_sold(after_promo)`) AS Qnty_sold
FROM fact_events fe
	LEFT JOIN dim_products dp 
		ON dp.product_code = fe.product_code
GROUP BY 1, 2
ORDER BY 3 DESC;

-- NOTE BUSINESS REGUESTS
-- 1. PRODUCT WITH PRICE GREATER THAN 500 IN (BOGOF) PROMOTION TYPE.
SELECT 
	DISTINCT product_name AS Product
FROM fact_events fe
	LEFT JOIN dim_products dp 
		ON dp.product_code = fe.product_code
WHERE base_price > 500 
AND promo_type = 'BOGOF'

-- 2. NUMBER OF STORES IN EACH CITIES 
SELECT
	city,
    COUNT(store_id) AS Num_of_stores
FROM dim_stores
GROUP BY 1;

-- 3. TOTAL REVENUE GENARATED BEFORE AND AFTER CAMPAIGN
SELECT
	campaign_name,
    SUM(base_price * `quantity_sold(before_promo)`) AS Sales_before_promo,
    SUM(base_price * `quantity_sold(after_promo)`) AS Sales_after_promo
FROM fact_events fe
	LEFT JOIN dim_campaigns dc
		ON dc.campaign_id = fe.campaign_id
GROUP BY 1;

-- 4. INCREMENTAL QUANTITY SOLD BASED ON CATEGORY FOR DIWALI CAMPAIGN
SELECT
	category,
    Qnty_sold,
    ratio_of_qnty_after_promo,
    RANK() OVER (ORDER BY a.ratio_of_qnty_after_promo DESC) AS Ranks
FROM
(SELECT
	DISTINCT category,
    SUM(`quantity_sold(after_promo)`) OVER (PARTITION BY category) AS Qnty_sold,
    SUM(`quantity_sold(after_promo)`) OVER () / SUM(`quantity_sold(after_promo)`) OVER (PARTITION BY category) AS ratio_of_qnty_after_promo
FROM fact_events fe
	LEFT JOIN dim_products dp
		ON dp.product_code = fe.product_code
	LEFT JOIN dim_campaigns dc
		ON dc.campaign_id = fe.campaign_id
WHERE campaign_name = 'Diwali') AS a

-- 5. TOP 5 PRODUCT BY INCREMENTAL REVENUE  PERCENTAGE.
SELECT
	DISTINCT category,
    product_name,
    SUM(`quantity_sold(after_promo)`) OVER () / SUM(base_price * `quantity_sold(after_promo)`) OVER (PARTITION BY category) AS Percent_of_qnty
FROM fact_events fe
	LEFT JOIN dim_products dp
		ON dp.product_code = fe.product_code
	LEFT JOIN dim_campaigns dc
		ON dc.campaign_id = fe.campaign_id
WHERE campaign_name IN ('Diwali', 'Sankranti')
ORDER BY 3 DESC
LIMIT 5;

-- ADDITIONAL ANALYSIS
-- CITY SALES PERFORMANCE B4 AND AFTER PROMO
SELECT 
	city,
    campaign_name,
    fe.store_id,
    SUM(base_price * `quantity_sold(before_promo)`) AS Sales_b4_promo,
    SUM(base_price * `quantity_sold(after_promo)`) AS Sales_af_promo
FROM fact_events fe
	LEFT JOIN dim_stores ds
		ON ds.store_id = fe.store_id
	LEFT JOIN dim_campaigns dc
		ON dc.campaign_id = fe.campaign_id
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

-- 
 SELECT 
	store_id,
	category,
	dm.product_name,
    SUM(base_price * `quantity_sold(after_promo)`) AS After_promo_sales,
    SUM(base_price * `quantity_sold(before_promo)`) AS Before_promo_sales, 
    SUM(base_price * `quantity_sold(after_promo)`) - SUM(base_price * `quantity_sold(before_promo)`) AS Diff_promo
 FROM fact_events fe
	LEFT JOIN dim_products dm
		ON dm.product_code = fe.product_code
GROUP BY 1, 2, 3
ORDER BY 2, 3 DESC;