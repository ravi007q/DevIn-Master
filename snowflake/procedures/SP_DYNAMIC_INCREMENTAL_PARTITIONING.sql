-- ============================================================================
-- Procedure : SP_DYNAMIC_INCREMENTAL_PARTITIONING
-- Source map: m_dynamic_incremental_partitioning (Sample_6_Mapping.xml)
-- Pattern   : Incremental load by date watermark window
--
-- NOTE: This mapping is NOT documented in BRD.txt. Logic is derived from the
--       Source Qualifier SQL override, which selects from STG_SALES_HIST using
--       mapping parameters $$SET_LOW_WATERMARK and $$SET_HIGH_WATERMARK:
--         WHERE SALE_DATE >= TO_DATE('$$SET_LOW_WATERMARK','YYYY-MM-DD')
--           AND SALE_DATE <  TO_DATE('$$SET_HIGH_WATERMARK','YYYY-MM-DD')
--
-- Informatica mapping parameters -> Snowflake procedure arguments.
-- The target window is deleted first so re-running the same window is idempotent.
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_DYNAMIC_INCREMENTAL_PARTITIONING(
    SET_LOW_WATERMARK  STRING,   -- inclusive lower bound, 'YYYY-MM-DD'
    SET_HIGH_WATERMARK STRING    -- exclusive upper bound, 'YYYY-MM-DD'
)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    low_dt   DATE DEFAULT TO_DATE(:SET_LOW_WATERMARK, 'YYYY-MM-DD');
    high_dt  DATE DEFAULT TO_DATE(:SET_HIGH_WATERMARK, 'YYYY-MM-DD');
    rows_loaded INTEGER DEFAULT 0;
BEGIN
    -- Idempotent re-load of the requested partition window.
    DELETE FROM SALES_FACT_INCREMENTAL
    WHERE SALE_DATE >= :low_dt
      AND SALE_DATE <  :high_dt;

    INSERT INTO SALES_FACT_INCREMENTAL (SALE_ID, SALE_DATE, AMOUNT, LOAD_TIMESTAMP)
    SELECT SALE_ID, SALE_DATE, AMOUNT, CURRENT_TIMESTAMP()
    FROM STG_SALES_HIST
    WHERE SALE_DATE >= :low_dt
      AND SALE_DATE <  :high_dt;

    rows_loaded := SQLROWCOUNT;
    RETURN 'SP_DYNAMIC_INCREMENTAL_PARTITIONING: loaded ' || rows_loaded
        || ' rows for window [' || :SET_LOW_WATERMARK || ', ' || :SET_HIGH_WATERMARK || ').';
END;
$$;
