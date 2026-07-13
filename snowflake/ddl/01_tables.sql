-- ============================================================================
-- DDL: Source and Target tables for the Informatica -> Snowflake migration
-- Target platform: Snowflake (database ANALYSIS, schema PUBLIC)
-- Generated from the PowerCenter XML mappings + BRD.txt
-- ============================================================================

USE DATABASE ANALYSIS;
USE SCHEMA PUBLIC;

-- ----------------------------------------------------------------------------
-- Mapping #1: m_stg_to_dim_employees_standard
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS STG_EMPLOYEES (
    EMP_ID      INTEGER,
    FIRST_NAME  VARCHAR(50),
    LAST_NAME   VARCHAR(50),
    DEPARTMENT  VARCHAR(50),
    SALARY      DECIMAL(10,2),
    STATUS      VARCHAR(1)              -- 'A' = Active, 'I' = Inactive
);

CREATE TABLE IF NOT EXISTS DIM_EMPLOYEES (
    EMP_ID        INTEGER,
    FULL_NAME     VARCHAR(101),
    DEPARTMENT    VARCHAR(50),
    SALARY        DECIMAL(10,2),
    LAST_UPDATED  TIMESTAMP_NTZ
);

-- ----------------------------------------------------------------------------
-- Mapping #2: m_sales_perf_routing_complex
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS SALES (
    STORE_ID  INTEGER,
    TXN_ID    INTEGER,
    REVENUE   DECIMAL(12,2)
);

CREATE TABLE IF NOT EXISTS STORES (
    STORE_ID  INTEGER,
    REGION    VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS LKP_TARGET_BONUS (
    REGION            VARCHAR(30),
    BONUS_MULTIPLIER  DECIMAL(4,2)
);

CREATE TABLE IF NOT EXISTS HIGH_PERFORMERS (
    STORE_ID           INTEGER,
    TOTAL_REVENUE      DECIMAL(15,2),
    TRANSACTION_COUNT  INTEGER,
    PROJECTED_BONUS    DECIMAL(15,2),
    LOAD_TIMESTAMP     TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS STANDARD_PERFORMERS (
    STORE_ID           INTEGER,
    TOTAL_REVENUE      DECIMAL(15,2),
    TRANSACTION_COUNT  INTEGER,
    PROJECTED_BONUS    DECIMAL(15,2),
    LOAD_TIMESTAMP     TIMESTAMP_NTZ
);

-- ----------------------------------------------------------------------------
-- Mapping #3: m_customer_scd2_enterprise
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS STG_CUSTOMERS (
    CUSTOMER_ID    INTEGER,
    CUSTOMER_NAME  VARCHAR(100),
    ADDRESS        VARCHAR(250),
    PHONE          VARCHAR(20),
    TIER           VARCHAR(10),
    EMAIL          VARCHAR(255),
    REGION_ID      INTEGER
);

CREATE TABLE IF NOT EXISTS STG_REGIONS (
    REGION_ID  INTEGER
);

CREATE TABLE IF NOT EXISTS DIM_CUSTOMER (
    CUSTOMER_SK     INTEGER       AUTOINCREMENT START 1 INCREMENT 1,
    CUSTOMER_ID     INTEGER       NOT NULL,
    CUSTOMER_NAME   VARCHAR(100),
    ADDRESS         VARCHAR(250),
    PHONE           VARCHAR(20),
    TIER            VARCHAR(10),
    ROW_HASH_MD5    VARCHAR(32)   NOT NULL,
    IS_ACTIVE       CHAR(1)       NOT NULL,   -- 'Y' = current, 'N' = expired
    EFF_START_DATE  TIMESTAMP_NTZ NOT NULL,
    EFF_END_DATE    TIMESTAMP_NTZ,
    LOAD_TIMESTAMP  TIMESTAMP_NTZ NOT NULL
);

-- ----------------------------------------------------------------------------
-- Mapping #4: m_txn_state_tracking_complex
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS STG_TXNS (
    ACCOUNT_ID  INTEGER,
    TXN_DATE    TIMESTAMP_NTZ,
    STATUS      VARCHAR(10),
    AMOUNT      DECIMAL(15,2)
);

CREATE TABLE IF NOT EXISTS TXN_STATE_CHANGES (
    ACCOUNT_ID          INTEGER,
    TXN_DATE            TIMESTAMP_NTZ,
    STATUS              VARCHAR(10),
    AMOUNT              DECIMAL(15,2),
    PREV_STATUS         VARCHAR(10),
    STATE_CHANGED_FLAG  INTEGER,
    LOAD_TIMESTAMP      TIMESTAMP_NTZ
);

-- ----------------------------------------------------------------------------
-- Mapping #5: m_hierarchical_xml_generation
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ORDERS (
    ORDER_ID    INTEGER,
    CUST_ID     INTEGER,
    ORDER_DATE  TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS ORDER_ITEMS (
    ORDER_ID     INTEGER,
    ITEM_ID      INTEGER,
    PRODUCT_SKU  VARCHAR(50),
    QTY          INTEGER
);

CREATE TABLE IF NOT EXISTS ORDER_XML_PAYLOADS (
    ORDER_ID        INTEGER,
    CUSTOMER_ID     INTEGER,
    ORDER_DATE      TIMESTAMP_NTZ,
    XML_PAYLOAD     VARCHAR(16777216),     -- 16 MB
    LOAD_TIMESTAMP  TIMESTAMP_NTZ
);

-- ----------------------------------------------------------------------------
-- Mapping #6: m_dynamic_incremental_partitioning
-- NOTE: Not covered by BRD.txt. Source/target inferred from the XML mapping.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS STG_SALES_HIST (
    SALE_ID    INTEGER,
    SALE_DATE  TIMESTAMP_NTZ,
    AMOUNT     DECIMAL(15,2)
);

CREATE TABLE IF NOT EXISTS SALES_FACT_INCREMENTAL (
    SALE_ID         INTEGER,
    SALE_DATE       TIMESTAMP_NTZ,
    AMOUNT          DECIMAL(15,2),
    LOAD_TIMESTAMP  TIMESTAMP_NTZ
);

-- ----------------------------------------------------------------------------
-- Mapping #7: m_transaction_denormalization
-- NOTE: Not covered by BRD.txt. Source/target inferred from the XML mapping.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS STG_INVOICE_LINES (
    INVOICE_ID   INTEGER,
    LINE_TYPE    VARCHAR(20),       -- 'TAX', 'ITEM', 'FREIGHT'
    LINE_AMOUNT  DECIMAL(15,2)
);

CREATE TABLE IF NOT EXISTS INVOICE_DENORMALIZED (
    INVOICE_ID         INTEGER,
    TOTAL_TAX_AMT      DECIMAL(15,2),
    TOTAL_ITEM_AMT     DECIMAL(15,2),
    TOTAL_FREIGHT_AMT  DECIMAL(15,2),
    LOAD_TIMESTAMP     TIMESTAMP_NTZ
);
