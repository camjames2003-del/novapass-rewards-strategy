# NovaPass Rewards Strategy Analysis

A data-driven case study analyzing transaction data to optimize a fintech rewards program for the Latin American market.

## 📋 Project Index

1.- Executive Summary

2.- Executive Dashboard

3.- SQL: Exploratory Data Analysis (EDA)

4.- SQL: Data Cleaning

4.- SQL: Data Analysis

5.- Main Findings

6.- Final Recommendations

7.- Presentation

## 🎯 Executive Summary

Business Problem: NovaBank’s current flat 1.5x rewards model is uncompetitive and fails to optimize profit margins. Transitioning to a dynamic tiering system is essential to capture high-value market segments.

Business Question: Based on transaction data, what specific spending tiers and categories will maximize customer engagement while maintaining sustainable revenue?

## 📊 Executive Dashboard

The final visualization was built to communicate the "Travel-First" strategy to stakeholders.

View Full Dashboard Image in: NovaBank Dashboard.png file

## 💻 SQL Workflows

## 1. SQL: Exploratory Data Analysis (EDA)

File: eda_exploratory_analysis.sql

In this phase, I audited 10,001 transactions and 2,500 customers to identify data quality traps. I uncovered 121 duplicate IDs, 498 NULL categories, 208 orphaned records (transactions without valid customers), and 54 "time-traveling" transactions that were logged before an account was even opened.

## 2. SQL: Data Cleaning

File: data_cleaning.sql

In this phase, I built a unified cleaned data set using a Master CTE to transform messy raw logs into a validated source. I used RegEx to clean numeric fields, parsed complex strings to separate city and device data, and implemented a custom exchange rate engine to normalize five local currencies into a unified USD base. Finally, I enforced strict data integrity by deduplicating records and removing orphaned or logically impossible "time-traveling" transactions through targeted filters and Joins.

## 3. SQL: Strategic Data Analysis

File: strategic_analysis.sql

In this final layer, I translated the cleaned data into business intelligence. I used window functions to rank VIP customers and calculated percentage-of-total metrics for spend categories and geographical hotspots. I developed a custom mapping logic to identify cross-border transactions, which revealed a surprise 83% international travel spend. Finally, I segmented data into spend brackets to prove that high-value purchases (>$100) drive 78% of revenue, providing the mathematical foundation for the proposed 3/2/1 rewards tier structure.

## 🔍 Main Findings

83% International Spend: The vast majority of revenue is generated through cross-border transactions.

The Profitability Paradox: 79% of revenue comes from high-value swipes (>$100), despite those being less frequent than small daily purchases.

Category Drivers: Flights and Hotels are the primary anchors for high-ticket revenue.

## ✅ Final Recommendations

Adopt a "Premium Travel" Identity: Align marketing with the 83% international spending behavior found in the data.

Eliminate FX Fees: Remove foreign transaction fees to lock in high-value travelers and ensure "top-of-wallet" status abroad.

Implement 3/2/1 Reward Tiers: Use a tiered structure (3x Travel, 2x Daily Habits, 1x Base) to protect margins while incentivizing high-revenue categories.

## ✅ Presentation of Findings

File: NovaPass Rewards Strategy Case Study.ppx

This 12-slide executive presentation details the strategic shift from a flat rewards model to a data-backed 3/2/1 tiered system. It bridges technical SQL analysis with business storytelling, highlighting key insights on international spending patterns and high-value revenue concentration to justify the new NovaPass brand identity.



