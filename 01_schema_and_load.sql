-- =====================================================================
-- AegisLife Insurance Capstone  |  STEP 1: create the database and load data
-- Target: MySQL 8.x  (MySQL Workbench)
-- Input : the 5 cleaned CSV files produced from the Excel cleaning step
--         customer_clean.csv, agent_clean.csv, policy_clean.csv,
--         claim_clean.csv, feedback_clean.csv   (all dates are YYYY-MM-DD)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS aegislife;
USE aegislife;

-- Drop in reverse dependency order so the script can be re-run safely
DROP VIEW  IF EXISTS vw_policy_master;
DROP TABLE IF EXISTS feedback;
DROP TABLE IF EXISTS claim;
DROP TABLE IF EXISTS policy;
DROP TABLE IF EXISTS agent;
DROP TABLE IF EXISTS customer;

-- ---------------------------------------------------------------------
-- 1. TABLES (parents first)
-- ---------------------------------------------------------------------
CREATE TABLE customer (
    customer_id          VARCHAR(10)  NOT NULL,
    full_name            VARCHAR(100),
    age                  INT,
    gender               VARCHAR(10),
    marital_status       VARCHAR(15),
    occupation           VARCHAR(20),
    region               VARCHAR(15),
    smoking_status       VARCHAR(3),
    pre_existing_illness VARCHAR(3),
    risk_score           DECIMAL(4,2),
    date_joined          DATE,
    PRIMARY KEY (customer_id)
);

CREATE TABLE agent (
    agent_id            VARCHAR(10) NOT NULL,
    region              VARCHAR(15),
    join_date           DATE,
    total_policies_sold INT,
    lapsed_policies     INT,
    avg_premium_sold    DECIMAL(12,2),
    fraud_association   INT,
    PRIMARY KEY (agent_id)
);

CREATE TABLE policy (
    policy_id         VARCHAR(10) NOT NULL,
    customer_id       VARCHAR(10) NOT NULL,
    product_type      VARCHAR(15),
    coverage_amount   DECIMAL(14,2),
    annual_premium    DECIMAL(12,2),
    policy_start_date DATE,
    policy_end_date   DATE,
    agent_id          VARCHAR(10) NOT NULL,
    status            VARCHAR(10),
    PRIMARY KEY (policy_id),
    FOREIGN KEY (customer_id) REFERENCES customer (customer_id),
    FOREIGN KEY (agent_id)    REFERENCES agent (agent_id)
);

CREATE TABLE claim (
    claim_id        VARCHAR(10) NOT NULL,
    policy_id       VARCHAR(10) NOT NULL,
    claim_date      DATE,
    claim_amount    DECIMAL(14,2),
    claim_status    VARCHAR(10),
    claim_type      VARCHAR(15),
    fraud_flag      VARCHAR(3),
    days_to_process INT,
    PRIMARY KEY (claim_id),
    FOREIGN KEY (policy_id) REFERENCES policy (policy_id)
);

-- NOTE: no foreign key on feedback.customer_id.
-- 369 of the 1,000 feedback rows belong to customers that are NOT in the
-- customer table (found and flagged in Excel). A foreign key would reject them.
CREATE TABLE feedback (
    feedback_id        VARCHAR(10) NOT NULL,
    customer_id        VARCHAR(10),
    date_submitted     DATE,
    feedback_text      VARCHAR(200),
    satisfaction_score INT,
    contacted_agent    VARCHAR(3),
    referred_claim     VARCHAR(3),
    PRIMARY KEY (feedback_id),
    INDEX idx_feedback_customer (customer_id)
);

-- ---------------------------------------------------------------------
-- 2. LOAD THE DATA  (load order matters: parents before children)
-- ---------------------------------------------------------------------
-- OPTION A (easiest for beginners): MySQL Workbench import wizard
--   Right-click the table in the left "Schemas" panel -> Table Data Import
--   Wizard -> choose the CSV -> "Use existing table" -> Next -> Finish.
--   Do it in this order: customer, agent, policy, claim, feedback.
--
-- OPTION B: LOAD DATA. Change the folder path first (use forward slashes).
--   If you see "Loading local data is disabled", run:  SET GLOBAL local_infile = 1;
--   and enable "OPT_LOCAL_INFILE=1" in the Workbench connection's Advanced tab.
--
-- LOAD DATA LOCAL INFILE 'C:/AegisLife/customer_clean.csv' INTO TABLE customer
--   FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- LOAD DATA LOCAL INFILE 'C:/AegisLife/agent_clean.csv'    INTO TABLE agent
--   FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- LOAD DATA LOCAL INFILE 'C:/AegisLife/policy_clean.csv'   INTO TABLE policy
--   FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- LOAD DATA LOCAL INFILE 'C:/AegisLife/claim_clean.csv'    INTO TABLE claim
--   FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- LOAD DATA LOCAL INFILE 'C:/AegisLife/feedback_clean.csv' INTO TABLE feedback
--   FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- (If the file has Windows line endings, use '\r\n' instead of '\n'.)

-- ---------------------------------------------------------------------
-- 3. VERIFY THE LOAD  -> must match the Excel Profile sheet
-- ---------------------------------------------------------------------
SELECT 'customer' AS table_name, COUNT(*) AS row_count FROM customer   -- 1648
UNION ALL SELECT 'policy',   COUNT(*) FROM policy                      -- 2828
UNION ALL SELECT 'claim',    COUNT(*) FROM claim                       -- 1406
UNION ALL SELECT 'agent',    COUNT(*) FROM agent                       -- 300
UNION ALL SELECT 'feedback', COUNT(*) FROM feedback;                  -- 1000
