-- The Unified Data Cleaning Pipeline
-- Purpose: We found the issues in EDA. Now we use a CTE as a way to clean, cast, normalize, and filter everything in one pass.

-- STEP 1: Create the Master CTE
CREATE OR REPLACE TABLE `c3-w3-01jun.NovaBank.cleaned_novabank_data` AS 
WITH CleanedTransactions AS (
  SELECT
    transaction_id,
    customer_id,

    -- 1. Date Standardization
    -- Using COALESCE as a fallback safety net just in case different date formats slip through.
    COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', transaction_date),
        SAFE.PARSE_DATE('%m/%d/%Y', transaction_date)
    ) AS clean_date,

    -- 2. Text Standardization & NULL Handling
    -- Trimming accidental spaces and forcing uppercase.
    UPPER(TRIM(merchant_name)) AS clean_merchant,
    -- Replacing blank categories with 'Unknown'.
    UPPER(TRIM(COALESCE(merchant_category, 'Unknown'))) AS clean_category,
    UPPER(TRIM(currency)) AS clean_currency,

    -- 3. String Parsing
    -- Breaking the combined location/device string into two separate, usable columns.
    TRIM(SPLIT(location_and_device, '-')[SAFE_OFFSET(0)]) AS city,
    TRIM(SPLIT(location_and_device, '-')[SAFE_OFFSET(1)]) AS device,

    -- 4. Number Casting & Symbol Removal
    -- Using RegEx to remove all letters and dollar signs, commas, and casting the pure number to a Float for math.
    SAFE_CAST(REPLACE(REGEXP_REPLACE(transaction_amount, r'[a-zA-Z$ ]', ''),',','') AS FLOAT64) AS clean_transaction_amount,

    -- 5. Currency Normalization 
    -- We can't sum different currencies together. So we apply an exchange rate engine to standardize everything to USD.
    ROUND(CASE
      WHEN UPPER(TRIM(currency)) = 'COP' THEN SAFE_CAST(REPLACE(REGEXP_REPLACE(transaction_amount, r'[a-zA-Z$ ]', ''),',','') AS FLOAT64) * 0.00025
      WHEN UPPER(TRIM(currency)) = 'PEN' THEN SAFE_CAST(REPLACE(REGEXP_REPLACE(transaction_amount, r'[a-zA-Z$ ]', ''),',','') AS FLOAT64) * 0.27
      WHEN UPPER(TRIM(currency)) = 'MXN' THEN SAFE_CAST(REPLACE(REGEXP_REPLACE(transaction_amount, r'[a-zA-Z$ ]', ''),',','') AS FLOAT64) * 0.05
      WHEN UPPER(TRIM(currency)) = 'BRL' THEN SAFE_CAST(REPLACE(REGEXP_REPLACE(transaction_amount, r'[a-zA-Z$ ]', ''),',','') AS FLOAT64) * 0.20
      ELSE SAFE_CAST(REPLACE(REGEXP_REPLACE(transaction_amount, r'[a-zA-Z$ ]', ''),',','') AS FLOAT64)
    END, 2) AS amount_usd,

    -- 6. Duplicate Flagging
    -- Assigning a '1' to the real transaction and a '2' to the duplicates so we can easily filter them out below.
    ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_date) AS row_num

  FROM `c3-w3-01jun.NovaBank.novabank_transactions`
)

-- STEP 2: The Final Selection & Anti-Join Filters
SELECT 
  t.transaction_id,
  t.customer_id,
  c.age,
  c.country_of_residence,
  t.clean_date,
  t.clean_merchant,
  t.clean_category,
  t.amount_usd,
  t.city,
  t.device
FROM CleanedTransactions AS t

-- Using an INNER JOIN to attach customer demographics (age and country). 
-- This will drops the 200 orphaned transactions.
INNER JOIN `c3-w3-01jun.NovaBank.nova bank_customers` AS c 
  ON t.customer_id = c.customer_id

-- Finally, filtering out the 100 duplicates (row_num > 1) and dropping the 54 impossible time-traveling dates.
WHERE t.row_num = 1
  AND t.clean_date >= c.sign_up_date;
