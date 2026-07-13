-- ============================================================================
-- Procedure : SP_SALES_PERF_ROUTING
-- Source map: m_sales_perf_routing_complex (Sample_2_Mapping.xml)
-- Pattern   : Full Refresh with Conditional Routing
--
-- Transformation pipeline mapped to SQL:
--   JNR_Sales_Stores   -> INNER JOIN SALES s / STORES st ON s.STORE_ID = st.STORE_ID
--   AGG_Monthly_Perf   -> GROUP BY STORE_ID, REGION; SUM(REVENUE), COUNT(TXN_ID)
--   LKP_Target_Bonus   -> LEFT JOIN LKP_TARGET_BONUS ON REGION
--   EXP_Final_Calc     -> PROJECTED_BONUS = TOTAL_REVENUE * COALESCE(BONUS_MULTIPLIER, 1)
--   RTR_Performance_Split -> two INSERTs (High >= 100000, Standard default)
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_SALES_PERF_ROUTING()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    rows_high     INTEGER DEFAULT 0;
    rows_standard INTEGER DEFAULT 0;
    load_ts       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP();
BEGIN
    -- BR-6: Both targets truncated before load
    TRUNCATE TABLE HIGH_PERFORMERS;
    TRUNCATE TABLE STANDARD_PERFORMERS;

    -- Common aggregated/calculated result set reused by both router branches.
    CREATE OR REPLACE TEMPORARY TABLE TMP_STORE_PERF AS
    SELECT
        agg.STORE_ID,
        agg.TOTAL_REVENUE,
        agg.TRANSACTION_COUNT,
        ROUND(agg.TOTAL_REVENUE * COALESCE(lkp.BONUS_MULTIPLIER, 1), 2) AS PROJECTED_BONUS  -- BR-3, EXP_Final_Calc
    FROM (
        SELECT
            s.STORE_ID                AS STORE_ID,
            st.REGION                 AS REGION,
            SUM(s.REVENUE)            AS TOTAL_REVENUE,       -- AGG_Monthly_Perf
            COUNT(s.TXN_ID)           AS TRANSACTION_COUNT
        FROM SALES s
        INNER JOIN STORES st                                 -- JNR_Sales_Stores (Normal Join), BR-1
            ON s.STORE_ID = st.STORE_ID
        GROUP BY s.STORE_ID, st.REGION                       -- BR-2
    ) agg
    LEFT JOIN LKP_TARGET_BONUS lkp                           -- LKP_Target_Bonus
        ON lkp.REGION = agg.REGION;

    -- RTR_Performance_Split: High_Performers group (TOTAL_REVENUE >= 100000) -- BR-4
    INSERT INTO HIGH_PERFORMERS
        (STORE_ID, TOTAL_REVENUE, TRANSACTION_COUNT, PROJECTED_BONUS, LOAD_TIMESTAMP)
    SELECT STORE_ID, TOTAL_REVENUE, TRANSACTION_COUNT, PROJECTED_BONUS, :load_ts
    FROM TMP_STORE_PERF
    WHERE TOTAL_REVENUE >= 100000;
    rows_high := SQLROWCOUNT;

    -- RTR_Performance_Split: Standard_Performers DEFAULT group -- BR-5
    INSERT INTO STANDARD_PERFORMERS
        (STORE_ID, TOTAL_REVENUE, TRANSACTION_COUNT, PROJECTED_BONUS, LOAD_TIMESTAMP)
    SELECT STORE_ID, TOTAL_REVENUE, TRANSACTION_COUNT, PROJECTED_BONUS, :load_ts
    FROM TMP_STORE_PERF
    WHERE TOTAL_REVENUE < 100000;
    rows_standard := SQLROWCOUNT;

    RETURN 'SP_SALES_PERF_ROUTING: HIGH_PERFORMERS=' || rows_high
        || ', STANDARD_PERFORMERS=' || rows_standard || '.';
END;
$$;
