
-- AegisLife Insurance Capstone  |  STEP 2: analysis queries (MySQL 8.x)
-- Run 01_schema_and_load.sql first. Each query answers one business problem.
-- Run one statement at a time (put the cursor in it, press Ctrl+Enter).
-- =====================================================================
USE aegislife;

-- ---------------------------------------------------------------------
-- A. REUSABLE VIEW: the SQL version of your Excel Policy_Master table
--    (one row per policy with customer, agent and claim totals attached).
--    Python and Power BI can read this view directly.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_policy_master;
CREATE VIEW vw_policy_master AS
SELECT  p.policy_id, p.customer_id, p.product_type, p.coverage_amount, p.annual_premium,
        p.policy_start_date, p.policy_end_date, p.agent_id, p.status,
        CASE WHEN p.status = 'Active' THEN 0 ELSE 1 END                     AS lapsed_flag,
        c.age,
        CASE WHEN c.age <= 30 THEN '18-30' WHEN c.age <= 45 THEN '31-45'
             WHEN c.age <= 60 THEN '46-60' ELSE '60+' END                   AS age_band,
        c.gender, c.occupation, c.region AS cust_region,
        c.smoking_status, c.pre_existing_illness, c.risk_score,
        CASE WHEN c.risk_score < 0.36 THEN 'Low'
             WHEN c.risk_score <= 0.62 THEN 'Medium' ELSE 'High' END        AS risk_band,
        a.region AS agent_region,
        a.lapsed_policies * 1.0 / a.total_policies_sold                     AS agent_lapse_rate,
        COALESCE(k.claim_count, 0)  AS claim_count,
        COALESCE(k.claim_amt, 0)    AS claim_amt,
        COALESCE(k.approved_amt, 0) AS approved_amt,
        COALESCE(k.fraud_claims, 0) AS fraud_claims
FROM policy p
JOIN customer c ON c.customer_id = p.customer_id
JOIN agent    a ON a.agent_id    = p.agent_id
LEFT JOIN (
        SELECT policy_id,
               COUNT(*)          AS claim_count,
               SUM(claim_amount) AS claim_amt,
               SUM(CASE WHEN claim_status = 'Approved' THEN claim_amount ELSE 0 END) AS approved_amt,
               SUM(CASE WHEN fraud_flag = 'Yes' THEN 1 ELSE 0 END)                   AS fraud_claims
        FROM claim
        GROUP BY policy_id
) k ON k.policy_id = p.policy_id;

-- ---------------------------------------------------------------------
-- B. DATA QUALITY CHECKS (same findings as the Excel Cleaning_Log)
-- ---------------------------------------------------------------------
-- B1. Feedback rows whose customer is not in the customer table  -> 369
SELECT COUNT(*) AS orphan_feedback_rows
FROM feedback f
LEFT JOIN customer c ON c.customer_id = f.customer_id
WHERE c.customer_id IS NULL;

-- B2. Claims larger than the policy's coverage                   -> 266
SELECT COUNT(*) AS claims_exceeding_coverage
FROM claim cl
JOIN policy p ON p.policy_id = cl.policy_id
WHERE cl.claim_amount > p.coverage_amount;

-- B3. Every claim is linked to a policy: this should equal 1406
SELECT SUM(claim_count) AS total_claims_in_master FROM vw_policy_master;

-- ---------------------------------------------------------------------
-- Q1  UNDERWRITING RISK: average claim cost per policy by risk band and smoking
-- ---------------------------------------------------------------------
SELECT risk_band, smoking_status,
       ROUND(AVG(claim_amt), 0) AS avg_claim_per_policy,
       SUM(claim_count)         AS total_claims
FROM vw_policy_master
GROUP BY risk_band, smoking_status
ORDER BY risk_band, smoking_status;

-- ---------------------------------------------------------------------
-- Q2  PREMIUM ADEQUACY: is price higher for higher risk?
-- ---------------------------------------------------------------------
SELECT product_type, risk_band,
       ROUND(AVG(annual_premium), 0)                 AS avg_premium,
       ROUND(AVG(annual_premium / coverage_amount), 4) AS avg_premium_to_coverage
FROM vw_policy_master
GROUP BY product_type, risk_band
ORDER BY product_type, FIELD(risk_band, 'Low', 'Medium', 'High');

-- ---------------------------------------------------------------------
-- Q3  LAPSE AND CANCELLATION: status mix by product / region / age band
-- ---------------------------------------------------------------------
-- 3a. by product
SELECT product_type AS segment, COUNT(*) AS policies,
       ROUND(100.0 * SUM(CASE WHEN status = 'Active'    THEN 1 ELSE 0 END) / COUNT(*), 1) AS active_pct,
       ROUND(100.0 * SUM(CASE WHEN status = 'Lapsed'    THEN 1 ELSE 0 END) / COUNT(*), 1) AS lapsed_pct,
       ROUND(100.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancelled_pct
FROM vw_policy_master GROUP BY product_type ORDER BY cancelled_pct DESC;

-- 3b. by customer region
SELECT cust_region AS segment, COUNT(*) AS policies,
       ROUND(100.0 * SUM(CASE WHEN status = 'Active'    THEN 1 ELSE 0 END) / COUNT(*), 1) AS active_pct,
       ROUND(100.0 * SUM(CASE WHEN status = 'Lapsed'    THEN 1 ELSE 0 END) / COUNT(*), 1) AS lapsed_pct,
       ROUND(100.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancelled_pct
FROM vw_policy_master GROUP BY cust_region ORDER BY lapsed_pct DESC;

-- 3c. by age band
SELECT age_band AS segment, COUNT(*) AS policies,
       ROUND(100.0 * SUM(CASE WHEN status = 'Active'    THEN 1 ELSE 0 END) / COUNT(*), 1) AS active_pct,
       ROUND(100.0 * SUM(CASE WHEN status = 'Lapsed'    THEN 1 ELSE 0 END) / COUNT(*), 1) AS lapsed_pct,
       ROUND(100.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancelled_pct
FROM vw_policy_master GROUP BY age_band ORDER BY age_band;

-- ---------------------------------------------------------------------
-- Q4  CHURN EARLY-WARNING: % of policies NOT active, by each customer trait
-- ---------------------------------------------------------------------
SELECT 'smoking' AS driver, smoking_status AS value, COUNT(*) AS policies,
       ROUND(100.0 * AVG(lapsed_flag), 1) AS not_active_pct FROM vw_policy_master GROUP BY smoking_status
UNION ALL
SELECT 'pre_existing_illness', pre_existing_illness, COUNT(*),
       ROUND(100.0 * AVG(lapsed_flag), 1) FROM vw_policy_master GROUP BY pre_existing_illness
UNION ALL
SELECT 'risk_band', risk_band, COUNT(*),
       ROUND(100.0 * AVG(lapsed_flag), 1) FROM vw_policy_master GROUP BY risk_band
UNION ALL
SELECT 'age_band', age_band, COUNT(*),
       ROUND(100.0 * AVG(lapsed_flag), 1) FROM vw_policy_master GROUP BY age_band
UNION ALL
SELECT 'occupation', occupation, COUNT(*),
       ROUND(100.0 * AVG(lapsed_flag), 1) FROM vw_policy_master GROUP BY occupation
UNION ALL
SELECT 'gender', gender, COUNT(*),
       ROUND(100.0 * AVG(lapsed_flag), 1) FROM vw_policy_master GROUP BY gender;

-- ---------------------------------------------------------------------
-- Q5  CLAIMS FRAUD: fraud-flag rate by claim type, product and customer region
-- ---------------------------------------------------------------------
-- 5a. by claim type
SELECT claim_type, COUNT(*) AS claims,
       ROUND(100.0 * SUM(CASE WHEN fraud_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS fraud_pct
FROM claim GROUP BY claim_type ORDER BY fraud_pct DESC;

-- 5b. by product
SELECT p.product_type, COUNT(*) AS claims,
       ROUND(100.0 * SUM(CASE WHEN cl.fraud_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS fraud_pct
FROM claim cl JOIN policy p ON p.policy_id = cl.policy_id
GROUP BY p.product_type ORDER BY fraud_pct DESC;

-- 5c. by customer region
SELECT c.region, COUNT(*) AS claims,
       ROUND(100.0 * SUM(CASE WHEN cl.fraud_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS fraud_pct
FROM claim cl
JOIN policy   p ON p.policy_id   = cl.policy_id
JOIN customer c ON c.customer_id = p.customer_id
GROUP BY c.region ORDER BY fraud_pct DESC;

-- ---------------------------------------------------------------------
-- Q6  CLAIMS LEAKAGE: status mix, and approved claims above coverage
-- ---------------------------------------------------------------------
-- 6a. count and amount by status
SELECT claim_status, COUNT(*) AS claims, ROUND(SUM(claim_amount), 0) AS total_amount,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM claim), 1) AS pct_of_claims
FROM claim GROUP BY claim_status;

-- 6b. claims above coverage, by status. Excess = amount above the policy's coverage.
SELECT cl.claim_status, COUNT(*) AS claims_over_coverage,
       ROUND(SUM(cl.claim_amount - p.coverage_amount), 0) AS excess_amount
FROM claim cl JOIN policy p ON p.policy_id = cl.policy_id
WHERE cl.claim_amount > p.coverage_amount
GROUP BY cl.claim_status;

-- 6c. claim volume by year with year-on-year change (window function LAG)
--     Note: 2020 and 2025 are partial years, so read their growth figures with care.
SELECT claim_year, claims, total_amount,
       ROUND(100.0 * (claims - LAG(claims) OVER (ORDER BY claim_year))
                   / LAG(claims) OVER (ORDER BY claim_year), 1) AS claims_growth_pct
FROM (
        SELECT YEAR(claim_date) AS claim_year, COUNT(*) AS claims,
               ROUND(SUM(claim_amount), 0) AS total_amount
        FROM claim GROUP BY YEAR(claim_date)
     ) t
ORDER BY claim_year;

-- ---------------------------------------------------------------------
-- Q7  CLAIMS EFFICIENCY: processing time
-- ---------------------------------------------------------------------
-- 7a. by claim type
SELECT claim_type, ROUND(AVG(days_to_process), 1) AS avg_days,
       MIN(days_to_process) AS fastest, MAX(days_to_process) AS slowest,
       ROUND(100.0 * SUM(CASE WHEN days_to_process > 45 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_over_45_days
FROM claim GROUP BY claim_type ORDER BY avg_days DESC;

-- 7b. by status
SELECT claim_status, ROUND(AVG(days_to_process), 1) AS avg_days, COUNT(*) AS claims
FROM claim GROUP BY claim_status;

-- ---------------------------------------------------------------------
-- Q8  AGENT PERFORMANCE: top 10 agents by lapse rate (window function RANK)
-- ---------------------------------------------------------------------
SELECT agent_id, region, total_policies_sold, lapsed_policies,
       ROUND(lapse_rate, 4) AS lapse_rate, fraud_association, lapse_rank
FROM (
        SELECT agent_id, region, total_policies_sold, lapsed_policies, fraud_association,
               lapsed_policies * 1.0 / total_policies_sold AS lapse_rate,
               RANK() OVER (ORDER BY lapsed_policies * 1.0 / total_policies_sold DESC) AS lapse_rank
        FROM agent
     ) r
WHERE lapse_rank <= 10
ORDER BY lapse_rank;

-- 8b. agent region summary
SELECT region, COUNT(*) AS agents,
       ROUND(AVG(lapsed_policies * 1.0 / total_policies_sold), 4) AS avg_lapse_rate,
       ROUND(AVG(fraud_association), 2)                            AS avg_fraud_association
FROM agent GROUP BY region ORDER BY avg_lapse_rate DESC;

-- ---------------------------------------------------------------------
-- Q9  CUSTOMER EXPERIENCE: satisfaction by feedback theme
--     (theme rules are the same keyword rules used in Excel)
-- ---------------------------------------------------------------------
WITH themed AS (
    SELECT satisfaction_score,
           CASE WHEN feedback_text LIKE '%premium%'       THEN 'Pricing'
                WHEN feedback_text LIKE '%clarity%'       THEN 'Coverage clarity'
                WHEN feedback_text LIKE '%documentation%' THEN 'Documentation'
                WHEN feedback_text LIKE '%wait%'          THEN 'Claim delay'
                WHEN feedback_text LIKE '%faster%'        THEN 'Claim delay'
                WHEN feedback_text LIKE '%mobile app%'    THEN 'App'
                WHEN feedback_text LIKE '%agent%'         THEN 'Agent'
                WHEN feedback_text LIKE '%satisfied%'     THEN 'Claims'
                ELSE 'Service' END AS theme
    FROM feedback
)
SELECT theme, COUNT(*) AS mentions, ROUND(AVG(satisfaction_score), 2) AS avg_score,
       ROUND(100.0 * SUM(CASE WHEN satisfaction_score <= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_low_scores
FROM themed GROUP BY theme ORDER BY avg_score;

-- 9b. does contacting an agent change satisfaction?
SELECT contacted_agent, COUNT(*) AS feedback_rows, ROUND(AVG(satisfaction_score), 2) AS avg_score
FROM feedback GROUP BY contacted_agent;

-- ---------------------------------------------------------------------
-- Q10 PROFITABILITY: premium vs approved claims (loss ratio = claims / premium)
-- ---------------------------------------------------------------------
-- 10a. by product, ranked with a window function
SELECT product_type,
       ROUND(SUM(annual_premium), 0) AS premium,
       ROUND(SUM(approved_amt), 0)   AS approved_claims,
       ROUND(SUM(approved_amt) / SUM(annual_premium), 3) AS loss_ratio,
       RANK() OVER (ORDER BY SUM(approved_amt) / SUM(annual_premium) DESC) AS worst_rank
FROM vw_policy_master
GROUP BY product_type;

-- 10b. by customer region
SELECT cust_region,
       ROUND(SUM(annual_premium), 0) AS premium,
       ROUND(SUM(approved_amt), 0)   AS approved_claims,
       ROUND(SUM(approved_amt) / SUM(annual_premium), 3) AS loss_ratio
FROM vw_policy_master GROUP BY cust_region ORDER BY loss_ratio DESC;

-- 10c. by risk band
SELECT risk_band,
       ROUND(SUM(annual_premium), 0) AS premium,
       ROUND(SUM(approved_amt), 0)   AS approved_claims,
       ROUND(SUM(approved_amt) / SUM(annual_premium), 3) AS loss_ratio
FROM vw_policy_master GROUP BY risk_band ORDER BY loss_ratio DESC;

-- ---------------------------------------------------------------------
-- Q11 BONUS (CUSTOMER VALUE, links to the CLV module in the PDF):
--     top 10 customers by net value = premium paid - approved claims
-- ---------------------------------------------------------------------
WITH cust_value AS (
    SELECT customer_id,
           COUNT(*)                                   AS policies,
           ROUND(SUM(annual_premium), 0)              AS total_premium,
           ROUND(SUM(approved_amt), 0)                AS total_approved_claims,
           ROUND(SUM(annual_premium - approved_amt), 0) AS net_value
    FROM vw_policy_master
    GROUP BY customer_id
)
SELECT customer_id, policies, total_premium, total_approved_claims, net_value,
       RANK() OVER (ORDER BY net_value DESC) AS value_rank
FROM cust_value
ORDER BY value_rank
LIMIT 10;

-- =====================================================================
-- D. POST-LOAD VALIDATION (Step 4) AND ADDED KPIs (Steps 1 and 8)
-- =====================================================================
USE aegislife;

-- D1. Foreign-key consistency after loading: every result must be 0
SELECT COUNT(*) AS policies_without_customer
FROM policy p LEFT JOIN customer c ON c.customer_id = p.customer_id WHERE c.customer_id IS NULL;
SELECT COUNT(*) AS policies_without_agent
FROM policy p LEFT JOIN agent a ON a.agent_id = p.agent_id WHERE a.agent_id IS NULL;
SELECT COUNT(*) AS claims_without_policy
FROM claim cl LEFT JOIN policy p ON p.policy_id = cl.policy_id WHERE p.policy_id IS NULL;

-- D2. Random spot checks (compare 5 rows with the CSV or Excel file)
SELECT * FROM customer ORDER BY RAND() LIMIT 5;
SELECT * FROM policy   ORDER BY RAND() LIMIT 5;
SELECT * FROM claim    ORDER BY RAND() LIMIT 5;

-- D3. Blank or invalid values in critical fields: every result should be 0
SELECT SUM(age IS NULL) AS missing_age, SUM(risk_score IS NULL) AS missing_risk FROM customer;
SELECT SUM(claim_amount IS NULL) AS missing_amount, SUM(claim_status IS NULL OR claim_status = '') AS missing_status FROM claim;

-- D4. KPI: claim frequency (claims per policy) by product
SELECT p.product_type,
       COUNT(DISTINCT p.policy_id)                                AS policies,
       COUNT(cl.claim_id)                                         AS claims,
       ROUND(COUNT(cl.claim_id) / COUNT(DISTINCT p.policy_id), 3) AS claim_frequency
FROM policy p LEFT JOIN claim cl ON cl.policy_id = p.policy_id
GROUP BY p.product_type ORDER BY claim_frequency DESC;

-- D5. KPI: agent productivity and agent fraud ratio (top 10)
SELECT agent_id, region, total_policies_sold,
       ROUND(lapsed_policies / total_policies_sold, 3)    AS lapse_rate,
       ROUND(fraud_association / total_policies_sold, 3)  AS agent_fraud_ratio,
       ROUND(total_policies_sold * avg_premium_sold, 0)   AS premium_book
FROM agent ORDER BY agent_fraud_ratio DESC LIMIT 10;

-- D6. Regional manager view: policies, lapse rate, claims, approval rate, fraud rate by customer region
SELECT c.region AS customer_region,
       COUNT(DISTINCT p.policy_id) AS policies,
       ROUND(100 * COUNT(DISTINCT CASE WHEN p.status <> 'Active' THEN p.policy_id END)
                 / COUNT(DISTINCT p.policy_id), 1)                                        AS lapse_rate_pct,
       COUNT(cl.claim_id)                                                                 AS claims,
       ROUND(100 * SUM(cl.claim_status = 'Approved') / COUNT(cl.claim_id), 1)             AS approval_rate_pct,
       ROUND(100 * SUM(cl.fraud_flag   = 'Yes')      / COUNT(cl.claim_id), 1)             AS fraud_rate_pct
FROM customer c
JOIN policy p      ON p.customer_id = c.customer_id
LEFT JOIN claim cl ON cl.policy_id  = p.policy_id
GROUP BY c.region ORDER BY lapse_rate_pct DESC;

-- =====================================================================
-- D. POST-LOAD VALIDATION (Step 4) AND ADDED KPIs (Steps 1 and 8)
-- =====================================================================
USE aegislife;

-- D1. Foreign-key consistency after loading: every result must be 0
SELECT COUNT(*) AS policies_without_customer
FROM policy p LEFT JOIN customer c ON c.customer_id = p.customer_id WHERE c.customer_id IS NULL;
SELECT COUNT(*) AS policies_without_agent
FROM policy p LEFT JOIN agent a ON a.agent_id = p.agent_id WHERE a.agent_id IS NULL;
SELECT COUNT(*) AS claims_without_policy
FROM claim cl LEFT JOIN policy p ON p.policy_id = cl.policy_id WHERE p.policy_id IS NULL;

-- D2. Random spot checks (compare 5 rows with the CSV or Excel file)
SELECT * FROM customer ORDER BY RAND() LIMIT 5;
SELECT * FROM policy   ORDER BY RAND() LIMIT 5;
SELECT * FROM claim    ORDER BY RAND() LIMIT 5;

-- D3. Blank or invalid values in critical fields: every result should be 0
SELECT SUM(age IS NULL) AS missing_age, SUM(risk_score IS NULL) AS missing_risk FROM customer;
SELECT SUM(claim_amount IS NULL) AS missing_amount, SUM(claim_status IS NULL OR claim_status = '') AS missing_status FROM claim;

-- D4. KPI: claim frequency (claims per policy) by product
SELECT p.product_type,
       COUNT(DISTINCT p.policy_id)                                AS policies,
       COUNT(cl.claim_id)                                         AS claims,
       ROUND(COUNT(cl.claim_id) / COUNT(DISTINCT p.policy_id), 3) AS claim_frequency
FROM policy p LEFT JOIN claim cl ON cl.policy_id = p.policy_id
GROUP BY p.product_type ORDER BY claim_frequency DESC;

-- D5. KPI: agent productivity and agent fraud ratio (top 10)
SELECT agent_id, region, total_policies_sold,
       ROUND(lapsed_policies / total_policies_sold, 3)    AS lapse_rate,
       ROUND(fraud_association / total_policies_sold, 3)  AS agent_fraud_ratio,
       ROUND(total_policies_sold * avg_premium_sold, 0)   AS premium_book
FROM agent ORDER BY agent_fraud_ratio DESC LIMIT 10;

-- D6. Regional manager view: policies, lapse rate, claims, approval rate, fraud rate by customer region
SELECT c.region AS customer_region,
       COUNT(DISTINCT p.policy_id) AS policies,
       ROUND(100 * COUNT(DISTINCT CASE WHEN p.status <> 'Active' THEN p.policy_id END)
                 / COUNT(DISTINCT p.policy_id), 1)                                        AS lapse_rate_pct,
       COUNT(cl.claim_id)                                                                 AS claims,
       ROUND(100 * SUM(cl.claim_status = 'Approved') / COUNT(cl.claim_id), 1)             AS approval_rate_pct,
       ROUND(100 * SUM(cl.fraud_flag   = 'Yes')      / COUNT(cl.claim_id), 1)             AS fraud_rate_pct
FROM customer c
JOIN policy p      ON p.customer_id = c.customer_id
LEFT JOIN claim cl ON cl.policy_id  = p.policy_id
GROUP BY c.region ORDER BY lapse_rate_pct DESC;

-- =====================================================================
-- D. POST-LOAD VALIDATION (Step 4) AND ADDED KPIs (Steps 1 and 8)
-- =====================================================================
USE aegislife;

-- D1. Foreign-key consistency after loading: every result must be 0
SELECT COUNT(*) AS policies_without_customer
FROM policy p LEFT JOIN customer c ON c.customer_id = p.customer_id WHERE c.customer_id IS NULL;
SELECT COUNT(*) AS policies_without_agent
FROM policy p LEFT JOIN agent a ON a.agent_id = p.agent_id WHERE a.agent_id IS NULL;
SELECT COUNT(*) AS claims_without_policy
FROM claim cl LEFT JOIN policy p ON p.policy_id = cl.policy_id WHERE p.policy_id IS NULL;

-- D2. Random spot checks (compare 5 rows with the CSV or Excel file)
SELECT * FROM customer ORDER BY RAND() LIMIT 5;
SELECT * FROM policy   ORDER BY RAND() LIMIT 5;
SELECT * FROM claim    ORDER BY RAND() LIMIT 5;

-- D3. Blank or invalid values in critical fields: every result should be 0
SELECT SUM(age IS NULL) AS missing_age, SUM(risk_score IS NULL) AS missing_risk FROM customer;
SELECT SUM(claim_amount IS NULL) AS missing_amount, SUM(claim_status IS NULL OR claim_status = '') AS missing_status FROM claim;

-- D4. KPI: claim frequency (claims per policy) by product
SELECT p.product_type,
       COUNT(DISTINCT p.policy_id)                                AS policies,
       COUNT(cl.claim_id)                                         AS claims,
       ROUND(COUNT(cl.claim_id) / COUNT(DISTINCT p.policy_id), 3) AS claim_frequency
FROM policy p LEFT JOIN claim cl ON cl.policy_id = p.policy_id
GROUP BY p.product_type ORDER BY claim_frequency DESC;

-- D5. KPI: agent productivity and agent fraud ratio (top 10)
SELECT agent_id, region, total_policies_sold,
       ROUND(lapsed_policies / total_policies_sold, 3)    AS lapse_rate,
       ROUND(fraud_association / total_policies_sold, 3)  AS agent_fraud_ratio,
       ROUND(total_policies_sold * avg_premium_sold, 0)   AS premium_book
FROM agent ORDER BY agent_fraud_ratio DESC LIMIT 10;

-- D6. Regional manager view: policies, lapse rate, claims, approval rate, fraud rate by customer region
SELECT c.region AS customer_region,
       COUNT(DISTINCT p.policy_id) AS policies,
       ROUND(100 * COUNT(DISTINCT CASE WHEN p.status <> 'Active' THEN p.policy_id END)
                 / COUNT(DISTINCT p.policy_id), 1)                                        AS lapse_rate_pct,
       COUNT(cl.claim_id)                                                                 AS claims,
       ROUND(100 * SUM(cl.claim_status = 'Approved') / COUNT(cl.claim_id), 1)             AS approval_rate_pct,
       ROUND(100 * SUM(cl.fraud_flag   = 'Yes')      / COUNT(cl.claim_id), 1)             AS fraud_rate_pct
FROM customer c
JOIN policy p      ON p.customer_id = c.customer_id
LEFT JOIN claim cl ON cl.policy_id  = p.policy_id
GROUP BY c.region ORDER BY lapse_rate_pct DESC;


-- =====================================================================
-- E. SQL FINDINGS AND BUSINESS MEANING (summary of Q1-Q11 and section D)
-- =====================================================================
-- Data checks
--   Row counts match Excel: customer 1648, agent 300, policy 2828, claim 1406, feedback 1000.
--   Foreign keys are consistent after loading (D1 = 0 orphan policies and claims).
--   369 feedback rows belong to customers missing from the customer table (no FK on feedback).
--   266 claims are larger than the policy coverage; 89 of these were approved (12.4M over coverage).
--
-- Risk and pricing
--   Smokers claim more on average (134,016 vs 117,521) but premiums are flat across risk bands
--   (Low 27,631 / Medium 26,422 / High 26,348).
--   Business meaning: price does not follow risk. Reprice by risk band and add smoking status.
--
-- Lapse and agents
--   Only 34.3% of policies are Active (32.3% lapsed, 33.3% cancelled). Lapse is similar across regions.
--   The 10 weakest agents lapse at 28.7%-29.4% against a 14.8% average.
--   Business meaning: retention is an agent and service issue, not a customer-type issue.
--
-- Claims and fraud
--   1,406 claims worth 355.6M: Approved 504 (127.4M), Pending 454, Rejected 448.
--   Fraud flag is Yes on 49% of claims (Death 55.1%, North 53.5%).
--   Average processing time is 31.2 days; 24% of claims take more than 45 days.
--   Business meaning: block payments above coverage, validate the fraud flag, and set a 30-day target.
--
-- Profitability
--   Premium 75.5M against approved claims 127.4M gives a loss ratio of 169%
--   (Health 189%, Whole 178%, Vehicle 168%, Term 164%, Property 146%).
--   Business meaning: the portfolio loses money. Reprice Health and Whole life first, and review the South region.

