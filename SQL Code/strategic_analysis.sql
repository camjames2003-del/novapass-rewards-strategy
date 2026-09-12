--Project: NovaBank Dynamic Tier Analysis
--Business Problem: Update Dynamic Rewards Tier System
--Business Task: Analyze data to recommend a profitable 1x/2x/3x point multiplier

-- First a quick look at the clean data to make sure everything is ready
SELECT *
FROM `c3-w3-01jun.NovaBank.cleaned_novabank_data`
LIMIT 10;

-- Q1: What are the primary spending categories?
SELECT
  clean_category,
  COUNT(transaction_id) AS transaction_volume,
  ROUND(SUM(amount_usd),2) AS total_spend_usd,
  ROUND(AVG(amount_usd),2) AS average_transaction_usd,
  ROUND(SUM(amount_usd) / SUM(SUM(amount_usd)) OVER() * 100, 2) AS percentage_of_total_spend
FROM `c3-w3-01jun.NovaBank.cleaned_novabank_data`
GROUP BY clean_category
ORDER BY total_spend_usd DESC;
-- Insight: Flights and Groceries make up roughly 54% of our total spend, bringing in $325K in revenue.

-- Q2: Where are our geographical hotspots? 
-- What cities are the cards are being used in most frequently.
SELECT
  city,
  COUNT(transaction_id) AS transaction_volume,
  ROUND(SUM(amount_usd),2) AS total_spend_usd,
  ROUND(AVG(amount_usd),2) AS average_transaction_usd,
  ROUND(SUM(amount_usd) / SUM(SUM(amount_usd)) OVER() * 100, 2) AS percentage_of_total_spend
FROM `c3-w3-01jun.NovaBank.cleaned_novabank_data`
GROUP BY city
ORDER BY total_spend_usd DESC;
-- Insight: The top 3 cities are Sao Paulo, Mexico City, and Buenos Aires, 
-- which together account for 42% of total spend.

-- Where do our biggest spenders actually live?
SELECT
  country_of_residence,
  COUNT(transaction_id) AS transaction_volume,
  ROUND(SUM(amount_usd),2) AS total_spend_usd,
  ROUND(AVG(amount_usd),2) AS average_transaction_usd,
  ROUND(SUM(amount_usd) / SUM(SUM(amount_usd)) OVER() * 100, 2) AS percentage_of_total_spend
FROM `c3-w3-01jun.NovaBank.cleaned_novabank_data`
GROUP BY country_of_residence
ORDER BY total_spend_usd DESC;
-- Insight: 24% of our user base actually resides in Colombia.

-- Q3: Cross-Border Spending 
-- While looking at the hotspots, I noticed many transactions happen in a different 
-- country than the customer's residence. Let's confirm this
WITH Mapped_Transactions AS (
  SELECT
    transaction_id,
    country_of_residence,
    city,
    amount_usd,
    -- Manually mapping known cities to their respective countries  
    CASE
      WHEN UPPER(city) IN ('BOGOTA', 'MEDELLIN', 'CALI', 'CARTAGENA') THEN 'Colombia'
      WHEN UPPER(city) IN ('SAO PAULO', 'RIO DE JANEIRO', 'BRASILIA', 'BELO HORIZONTE') THEN 'Brazil'
      WHEN UPPER(city) IN ('LIMA', 'CUSCO', 'AREQUIPA') THEN 'Peru'
      WHEN UPPER(city) IN ('MEXICO CITY', 'CANCUN', 'MONTERREY', 'GUADALAJARA') THEN 'Mexico'
      WHEN UPPER(city) IN ('BUENOS AIRES', 'CORDOBA', 'ROSARIO') THEN 'Argentina'
      WHEN UPPER(city) IN ('QUITO', 'GUAYAQUIL', 'CUENCA') THEN 'Ecuador'
      ELSE 'Other/Unknown'
    END AS transaction_country
  FROM `c3-w3-01jun.NovaBank.cleaned_novabank_data`
)
SELECT
  -- Flag if the transaction was domestic or international
  CASE
    WHEN transaction_country != country_of_residence THEN 'International Travel Spend'
    ELSE 'Domestic Spend'
  END AS spend_type,
  COUNT(transaction_id) AS total_volume,
  ROUND(SUM(amount_usd),2) AS total_revenue,
  ROUND(COUNT(transaction_id) / SUM(COUNT(transaction_id)) OVER() * 100, 2) AS percentage_of_total_volume
FROM Mapped_Transactions
GROUP BY spend_type
ORDER BY total_revenue DESC;
-- Insight: A massive 83% of our transaction volume comes from International Travel Spend. Very suprising

-- Q4: High-Frequency vs High-Value Spending
-- We need to identify high-value/low-frequency purchases to protect profit margins on the reward tiers.
SELECT 
  CASE
    WHEN amount_usd < 20 THEN 'Small (<$20)'
    WHEN amount_usd BETWEEN 20 AND 100 THEN 'Medium ($20-$100)'
    WHEN amount_usd BETWEEN 101 AND 500 THEN 'High ($101-$500)'
    ELSE 'Premium (>$500)'
  END AS spend_bracket,
  COUNT(transaction_id) AS volume_of_purchases,
  ROUND(COUNT(transaction_id) / SUM(COUNT(transaction_id)) OVER() * 100, 2) AS percentage_of_total_volume,
  ROUND(SUM(amount_usd),2) AS total_revenue,
  ROUND(SUM(amount_usd) / SUM(SUM(amount_usd)) OVER() * 100, 2) AS percentage_of_total_spend
FROM `c3-w3-01jun.NovaBank.cleaned_novabank_data`
GROUP BY spend_bracket
ORDER BY total_revenue DESC;
-- Insight: Small and medium transactions make up 67% of the volume, but nearly 78% of the actual revenue comes from High and Premium purchases (over $100).

-- Q5: Who are our VIP users?
WITH RankedCustomers AS (
  SELECT
    customer_id,
    COUNT(transaction_id) AS total_transactions,
    ROUND(SUM(amount_usd),2) AS total_spend,
    RANK() OVER(ORDER BY SUM(amount_usd) DESC) as spend_rank
  FROM `c3-w3-01jun.NovaBank.cleaned_novabank_data`
  GROUP BY customer_id
)
SELECT 
  r.spend_rank,
  r.customer_id,
  c.first_name,
  c.last_name,
  r.total_transactions,
  r.total_spend
FROM RankedCustomers r
INNER JOIN `c3-w3-01jun.NovaBank.nova bank_customers` c
  ON r.customer_id = c.customer_id 
WHERE r.spend_rank <= 50
ORDER BY r.spend_rank ASC;
-- Insight: Our #1 biggest customer is Bruno Santos. They spent a total of $47K.

-- Q6: Age Spending Habits
-- Which age demographic is driving the most volume and revenue?
SELECT
  CASE
    WHEN age BETWEEN 18 AND 24 THEN '(18-24)'
    WHEN age BETWEEN 25 AND 34 THEN '(25-34)'
    WHEN age BETWEEN 35 AND 49 THEN '(35-49)'
    ELSE '(50+)'
  END AS age_group,
  COUNT(transaction_id) AS total_volume,
  ROUND(COUNT(transaction_id) / SUM(COUNT(transaction_id)) OVER() * 100, 2) AS percentage_of_total_volume,
  ROUND(SUM(amount_usd),2) AS total_revenue,
  ROUND(SUM(amount_usd) / SUM(SUM(amount_usd)) OVER() * 100, 2) AS percentage_of_total_spend,
  ROUND(AVG(amount_usd),2) AS average_value
FROM `c3-w3-01jun.NovaBank.cleaned_novabank_data`
GROUP BY age_group
ORDER BY age_group ASC;
-- Insight: There is a clear trend showing the (50+) demographic is our most valuable, generating 35% of total revenue.

-- Q7: Day of the Week Analysis
-- Identifying the highest volume days
SELECT 
  FORMAT_DATE('%A', clean_date) AS day_of_the_week,
  COUNT(transaction_id) AS total_transactions,
  ROUND(SUM(amount_usd),2) AS daily_revenue
FROM `c3-w3-01jun.NovaBank.cleaned_novabank_data`
GROUP BY day_of_the_week
ORDER BY total_transactions DESC;
-- Insight: Wednesday, Tuesday, and Monday are our peak days. 

-- Q8: Average Swipes per User
-- How many times does a typical user swipe their card in a given month?
WITH UserActivity AS (
  SELECT
    customer_id,
    COUNT(transaction_id) AS swipe_count
  FROM `c3-w3-01jun.NovaBank.cleaned_novabank_data`
  GROUP BY customer_id
)
SELECT 
  ROUND(AVG(swipe_count),2) AS average_swipes_per_user,
  MAX(swipe_count) AS max_swipes_by_one_user
FROM UserActivity;
-- Insight: The average user swipes 4.29 times, but our top power user swiped 390 times

-- Q9: Device Ecosystem
-- What platform are customers using to use the card?
SELECT
  UPPER(TRIM(device)) AS device_platform,
  COUNT(transaction_id) AS total_swipes,
  ROUND(SUM(amount_usd), 2) AS total_revenue
FROM `c3-w3-01jun.NovaBank.cleaned_novabank_data`
GROUP BY device_platform
ORDER BY total_swipes DESC;
-- Insight: IOS leads heavily, generating $629K in total revenue.


/*
   SUMMARY OF FINDINGS (Pre-Strategy Phase)

   1. Top Categories: Flights and Groceries drive over half of all card spend.
   2. Top Cities: Sao Paulo, Mexico City, and Buenos Aires are the biggest hotspots.
   3. Top Country: 25% of users live in Colombia.
   4. Travel Metric: 83% of all transactions are happening internationally.
   5. Volume vs Revenue: Small/Medium swipes make up 66% of volume, but High/Premium purchases drive 80% of actual revenue.
   6. Demographics: The older the user (50+), the higher the volume and revenue they generate.
   7. Peak Days: Mid-week (Wednesday/Tuesday) sees the highest transaction volume
   8. Tech Ecosystem: iOS users generate significantly more revenue compared to Android.
*/
