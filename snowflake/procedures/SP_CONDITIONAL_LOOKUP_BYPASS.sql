-- ============================================================================
-- Procedure : SP_CONDITIONAL_LOOKUP_BYPASS
-- Source map: m_conditional_lookup_bypass (Sample_8_Mapping.xml)
-- Pattern   : Conditional Lookup Bypass
--
-- Transformation pipeline mapped to SQL:
--   RTR_Bypass_Check          -> split rows into two branches
--   STRAIGHT_THROUGH branch   -> load source rows without lookup
--   NEED_HIST_LOOKUP branch   -> LEFT JOIN FACT_TRANSACTION_HISTORY to
--                                retrieve ORIGINAL_VAL for reversed/adjusted
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_CONDITIONAL_LOOKUP_BYPASS()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    rows_straight INTEGER DEFAULT 0;
    rows_lookup   INTEGER DEFAULT 0;
    load_ts       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP();
BEGIN
    -- Reset target tables
    TRUNCATE TABLE TXN_STRAIGHT_THROUGH;
    TRUNCATE TABLE TXN_HIST_LOOKUP;

    -- STRAIGHT_THROUGH group: any status that does not require historical verification
    INSERT INTO TXN_STRAIGHT_THROUGH (TXN_ID, LINE_STATUS, AMOUNT, LOAD_TIMESTAMP)
    SELECT TXN_ID, LINE_STATUS, AMOUNT, :load_ts
    FROM STG_TXN_LINES
    WHERE LINE_STATUS NOT IN ('REVERSED', 'ADJUSTED');
    rows_straight := SQLROWCOUNT;

    -- NEED_HIST_LOOKUP group: reversed or adjusted rows are enriched with the
    -- original value from FACT_TRANSACTION_HISTORY.
    INSERT INTO TXN_HIST_LOOKUP (TXN_ID, LINE_STATUS, AMOUNT, ORIGINAL_VAL, LOAD_TIMESTAMP)
    SELECT
        src.TXN_ID,
        src.LINE_STATUS,
        src.AMOUNT,
        COALESCE(hist.ORIGINAL_VAL, src.AMOUNT) AS ORIGINAL_VAL,
        :load_ts
    FROM STG_TXN_LINES src
    LEFT JOIN FACT_TRANSACTION_HISTORY hist
        ON hist.HIST_TXN_ID = src.TXN_ID
    WHERE src.LINE_STATUS IN ('REVERSED', 'ADJUSTED');
    rows_lookup := SQLROWCOUNT;

    RETURN 'SP_CONDITIONAL_LOOKUP_BYPASS: STRAIGHT_THROUGH=' || rows_straight
        || ', HIST_LOOKUP=' || rows_lookup || '.';
END;
$$;
