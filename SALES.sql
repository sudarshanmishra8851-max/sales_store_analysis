CREATE TABLE sales_store (
transaction_id VARCHAR(15),
customer_id VARCHAR(15),
customer_name VARCHAR(30),
customer_age INT,
gender VARCHAR(15),
product_id VARCHAR(15),
product_name VARCHAR(15),
product_category VARCHAR(15),
quantiy INT,
prce FLOAT,
payment_mode VARCHAR(15),
purchase_date DATE,
time_of_purchase TIME,
status VARCHAR(15)
)

SELECT * FROM sales_store

SET DATEFORMAT dmy

BULK INSERT sales_store
FROM 'C:\Users\Roshan Mishra\Desktop\project\sales_store_updated_allign_with_video.csv'
	WITH (
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='\n'
		)

------------------------------------------------------------------------------------------------------------------------
--DATA CLEANING 

--step:-1 To check for duplicates
SELECT 
transaction_id
FROM sales
GROUP BY transaction_id
HAVING COUNT(transaction_id) > 1

WITH RANKS AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_id) AS ROW_NUM
FROM sales
)
/*DELETE FROM RANKS
WHERE ROW_NUM = 2*/
SELECT * FROM sales
WHERE transaction_id IN ('TXN240646','TXN342128','TXN855235','TXN981773')


--Step2:- Correction of Headers
SELECT * FROM sales

EXEC sp_rename'sales.quantiy','quantity','COLUMN'

EXEC sp_rename'sales.prce','price','COLUMN'

--step3:- To check Datatype
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'sales'

--step4:- To check Null values

--to check null count

DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName,
     COUNT(*) AS NullCount
     FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales
     WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
    ' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales'

--EXEC the dynamic SQL
EXEC sp_executesql @SQL;


--treating null values 

SELECT * FROM sales
WHERE transaction_id IS NULL
OR 
customer_id IS NULL
OR 
customer_name IS NULL
OR 
customer_age IS NULL
OR 
gender IS NULL
OR
product_id IS NULL
OR 
product_name IS NULL
OR 
product_category IS NULL
OR 
quantity IS NULL
OR 
price is NULL
OR
payment_mode IS NULL
OR 
purchase_date IS NULL
OR 
time_of_purchase IS NULL
OR 
status IS NULL

DELETE FROM sales
WHERE transaction_id IS NULL


SELECT * FROM sales
WHERE customer_name = 'Ehsaan Ram'

UPDATE SALES 
SET customer_id = 'CUST9494'
WHERE transaction_id = 'TXN977900'

SELECT * FROM sales
WHERE customer_id ='CUST1003'

UPDATE sales
SET customer_age = 35,gender ='Male'
WHERE transaction_id = 'TXN432798'

UPDATE sales
SET customer_id = 'CUST1401'
WHERE transaction_id = 'TXN985663'

--Step5:-Data Cleaning 
SELECT DISTINCT gender 
FROM sales

UPDATE sales
SET gender ='M'
WHERE gender = 'Male'

UPDATE sales
SET gender ='F'
WHERE gender = 'Female'


SELECT DISTINCT payment_mode
FROM sales

UPDATE sales
SET payment_mode = 'Credit Card'
WHERE payment_mode = 'CC'

--Data Analysis---

--Q.1-What are the top 5 most selling products by quantity..?
SELECT TOP 5 product_name,SUM(quantity) AS total_qty
FROM sales
WHERE quantity > 0 AND status = 'delivered'
GROUP BY product_name
ORDER BY total_qty DESC

--BUSINESS PROBLEM: We don't know which product are most in demand.
--BUSINESS IMPACT: Helps prioritize stock and boost sales through target promotions

--Q.2:-Which product are most frequently cancelled..?
SELECT TOP 5 product_name, COUNT(product_name) AS total_cancelled
FROM sales
WHERE status = 'cancelled'
GROUP BY product_name
HAVING COUNT(product_name) > 1
ORDER BY total_cancelled DESC

--BUSINESS PROBLEM:Frequently cancellations affect revenue and customer trust.
--BUSINESS IMPACT: Identify poor-performing product to improve quality or remove from catalog.

--Q.3:- What time of the day has the highest number of purchase..?
SELECT 
CASE WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
	 WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
	 WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
	 WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
END AS time_of_day,
COUNT(*) total_orders
FROM sales
GROUP BY 
CASE WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
	 WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
	 WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
	 WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
END 
ORDER BY total_orders DESC

--BUSINESS PROBLEM:Find peak sales time.
--BUSINESS IMPACT:Optimize staffing, promotions, and server loads.

--Q.4:-Who are the top 5 highest spending customer..?
SELECT TOP 5 customer_name,
FORMAT(SUM(price * quantity),'C0','en-IN') AS total_spend
FROM sales
GROUP BY customer_name
ORDER BY SUM(price * quantity) DESC

--BUSINESS PROBLEM: Identify VIP customers.
--BUSINESS IMPACT: Personalized offers, loyalty rewards and retention.

--Q.5:- Which product categories generate the highest revenue..?
SELECT product_category,
FORMAT(SUM(price*quantity),'C0','en-IN') AS total_rev
FROM sales
GROUP BY product_category
ORDER BY SUM(price*quantity) DESC

--BUSINESS PROBLEM: Identify top-performing product categories
--BUSINESS IMPACT: Refine product strategy, supply chain, and promotions allowing the business to invest more in high-margin
--or high-demand categories.

--Q.6:- What is the returned/cancellation rate per product category..?
--cancellation
SELECT product_category,
FORMAT(COUNT(CASE WHEN status = 'cancelled' THEN 1 END)*100.0/COUNT(*),'N3')+' %' AS cancelled_percentage
FROM sales
GROUP BY product_category
ORDER BY cancelled_percentage DESC

--returned
SELECT product_category,
FORMAT(COUNT(CASE WHEN status = 'returned' THEN 1 END)*100.0/COUNT(*),'N3') + ' %' AS returned_percentage
FROM sales
GROUP BY product_category
ORDER BY returned_percentage DESC

--BUSINESS PROBLEM:- Monitor dissatifaction trends per category
--BUSINESS IMPACT:- Reduce returns,improve product descriptions exceptions Helps identify and fix product or logistic issues.

--Q.7:- What is the most preferred payment mode..?
SELECT payment_mode
FROM sales
GROUP BY payment_mode
ORDER BY COUNT(payment_mode) DESC

--BUSINESS PROBLEM:- Know which payment options customer prefer.
--BUSINESS IMPACT:-Streamline payment processing,prioritize popular modes.


--Q.8:-How does age group affect purchasing behaviour..?
SELECT 
CASE WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
	 WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
	 WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
	 ELSE 'Above 50'
END AS age_group,
FORMAT(SUM(price*quantity),'C0','en-IN') AS total_purchase
FROM sales
GROUP BY 
CASE WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
	 WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
	 WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
	 ELSE 'Above 50'
END
ORDER BY SUM(price*quantity) DESC

--BUSINESS PROBLEM:- Understand customer demographics
--BUSINESS IMPACT:-  Targeted and product recommendations by age group

--Q.9--What's the monthly sales Trend..?

--Method-1
SELECT 
FORMAT(purchase_date,'yyyy-MM'),
FORMAT(SUM(price*quantity),'C0','en-IN') AS total_sales,
SUM(quantity) AS total_quantity
FROM sales
GROUP BY FORMAT(purchase_date,'yyyy-MM')
ORDER BY SUM(price*quantity) DESC

--Method-2
SELECT YEAR(purchase_date) AS YEARS,
MONTH(purchase_date) AS MONTHS,
FORMAT(SUM(price*quantity),'C0','en-IN') AS total_sales,
SUM(quantity) AS total_quantity
FROM sales
GROUP BY YEAR(purchase_date),MONTH(purchase_date)
ORDER BY MONTHS 

--BUSINESS PROBLEM:- Sales fluctuations go unnoticed.
--BUSINESS IMPACAT:- Plan inventory and marketing according to seasonal trends.

--Q.10--Are certain genders buying more specific product categories.?
--Method-1
SELECT gender,
product_category,
COUNT(product_category) AS total_purchase
FROM sales
GROUP BY product_category,gender
ORDER BY gender

--Method-2
SELECT * 
FROM (
	SELECT gender,product_category
	FROM sales
	) AS source_table
PIVOT (
	COUNT(gender)
	FOR gender IN ([M],[F])
	) AS pivot_table
ORDER BY product_category

--BUSINESS PROBLEM: Gender based product preferences.
--BUSINESS IMPACT: Personalized ads, gender-focused campaigns.









