-- Unified Exploratory Data Analysis (EDA) for NovaBank
-- Purpose: Audit the Customers and Transactions tables to identify duplicates, nulls, and logical inconsistencies before cleaning.


-- SECTION 1: CUSTOMER TABLE PROFILING


-- 1.1 THE SHAPE OF THE DATA
-- Checking the row count for the customer base.
SELECT COUNT(*) AS total_rows
FROM `c3-w3-01jun.NovaBank.nova bank_customers`;
-- Result: 2,500 rows

SELECT *
FROM `c3-w3-01jun.NovaBank.nova bank_customers`
LIMIT 10;

-- 1.2 PRIMARY KEY CHECK
-- Ensuring there is no duplicate customers.
SELECT
  COUNT(customer_id) AS total_rows,
  COUNT(DISTINCT customer_id) AS unique_ids
FROM `c3-w3-01jun.NovaBank.nova bank_customers`;
-- Result: 0 duplicates. 

-- 1.3 CATEGORICAL PROFILING
-- Identifying the geographical distribution of our users.
SELECT country_of_residence, COUNT(*) AS total_customers
FROM `c3-w3-01jun.NovaBank.nova bank_customers`
GROUP BY country_of_residence
ORDER BY total_customers DESC;
-- Result: Users are distributed across 6 different countries.


-- SECTION 2: TRANSACTIONS TABLE PROFILING


-- 2.1 THE SHAPE OF THE DATA
-- Checking the volume of transactions logged.
SELECT COUNT(*) AS total_rows
FROM `c3-w3-01jun.NovaBank.novabank_transactions`;
-- Result: 10,001 rows

SELECT *
FROM `c3-w3-01jun.NovaBank.novabank_transactions`
LIMIT 10;
-- Result: Eye-balling reveals mixed data types and messy currency strings.

-- 2.2 PRIMARY KEY CHECK
-- Investigating potential duplicate transaction entries.
SELECT
  COUNT(transaction_id) AS total_rows,
  COUNT(DISTINCT transaction_id) AS unique_ids
FROM `c3-w3-01jun.NovaBank.novabank_transactions`;
-- Result: Discovered 101 duplicate IDs.

-- 2.3 THE NULL HUNT
-- Isolating missing values across all columns.
SELECT
  COUNT(*) - COUNT(transaction_id) AS missing_id,
  COUNT(*) - COUNT(customer_id) AS missing_customer,
  COUNT(*) - COUNT(transaction_date) AS missing_date,
  COUNT(*) - COUNT(merchant_name) AS missing_merchant,
  COUNT(*) - COUNT(merchant_category) AS missing_category,
  COUNT(*) - COUNT(transaction_amount) AS missing_amount,
  COUNT(*) - COUNT(currency) AS missing_currency,
  COUNT(*) - COUNT(location_and_device) AS missing_location
FROM `c3-w3-01jun.NovaBank.novabank_transactions`;
-- Result: 498 NULLs found specifically in the merchant_category column.

-- 2.4 CATEGORICAL & TEXT PROFILING
-- Checking for typos, inconsistent casing, and currency variety.

-- Merchant Categories
SELECT merchant_category, COUNT(*) AS total_transactions
FROM `c3-w3-01jun.NovaBank.novabank_transactions`
GROUP BY merchant_category
ORDER BY total_transactions DESC;

-- Currency Variety
SELECT currency, COUNT(*) AS total_transactions
FROM `c3-w3-01jun.NovaBank.novabank_transactions`
GROUP BY currency
ORDER BY total_transactions DESC;
-- Result: 5 different currencies identified (COP, PEN, MXN, BRL, USD).

-- Merchant Name Inconsistency
SELECT DISTINCT merchant_name
FROM `c3-w3-01jun.NovaBank.novabank_transactions`
ORDER BY merchant_name ASC
LIMIT 30;


-- SECTION 3: CROSS-TABLE INTEGRITY CHECKS


-- 3.1 THE 'ORPHAN' HUNT
-- Ensuring every transaction is tied to a valid customer in the Customer table.
SELECT
  t.transaction_id,
  t.customer_id AS transaction_customer_id,
  c.customer_id AS actual_customer_id
FROM `c3-w3-01jun.NovaBank.novabank_transactions` AS t 
LEFT JOIN `c3-w3-01jun.NovaBank.nova bank_customers` AS c 
  ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- Result: Found 200 orphaned transactions tied to non-existing accounts.

-- 3.2 LOGICAL IMPOSSIBILITIES (TIME TRAVELERS)
-- Identifying transactions dated BEFORE the user's sign-up date.
SELECT
  t.transaction_id,
  t.customer_id,
  t.transaction_date,
  c.sign_up_date,
  DATE_DIFF(
      c.sign_up_date, 
      COALESCE(
          SAFE.PARSE_DATE('%Y-%m-%d', t.transaction_date),
          SAFE.PARSE_DATE('%m/%d/%Y', t.transaction_date)
      ), 
      DAY
  ) AS days_before_signup
FROM `c3-w3-01jun.NovaBank.novabank_transactions` t
INNER JOIN `c3-w3-01jun.NovaBank.nova bank_customers` c
  ON t.customer_id = c.customer_id
WHERE COALESCE(
          SAFE.PARSE_DATE('%Y-%m-%d', t.transaction_date),
          SAFE.PARSE_DATE('%m/%d/%Y', t.transaction_date)
      ) < c.sign_up_date
ORDER BY days_before_signup DESC;
-- Result: Found 54 "time-traveling" transactions.


-- FINAL EDA FINDINGS & CLEANING TO-DO LIST

/* 1. Duplicates: 101 transaction IDs repeat; need deduplication.
   2. Missing Data: 498 NULLs in merchant_category; need to impute 'Unknown'.
   3. Integrity: 200 orphaned records and 54 pre-signup transactions; must be filtered out.
   4. Normalization: 5 currencies need conversion to USD base.
   5. Formatting: merchant_name requires TRIMMING and UPPER casing; transaction_amount requires RegEx cleaning and Casting.
*/
