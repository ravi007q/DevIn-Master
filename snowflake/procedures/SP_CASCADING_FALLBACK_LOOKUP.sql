-- ============================================================================
-- Procedure : SP_CASCADING_FALLBACK_LOOKUP
-- Source map: m_cascading_fallback_lookup (Sample_12_Mapping.xml)
-- Pattern   : Cascading Fallback Lookup
--
-- Transformation pipeline mapped to SQL:
--   LKP_Active_Cache  -> LEFT JOIN DIM_CUSTOMER_ACTIVE
--   LKP_Archive_Cache -> LEFT JOIN DIM_CUSTOMER_ARCHIVE
--   EXP_Evaluate_Fallback -> COALESCE(ACTIVE_ID, ARCHIVE_ID, -1)
--
-- Resolution order: ACTIVE_ID, then ARCHIVE_ID, then -1.
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_CASCADING_FALLBACK_LOOKUP()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    rows_loaded INTEGER DEFAULT 0;
    load_ts     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP();
BEGIN
    TRUNCATE TABLE CUSTOMER_RESOLVED;

    INSERT INTO CUSTOMER_RESOLVED (SRC_KEY, ACTIVE_ID, ARCHIVE_ID, FINAL_ID, LOAD_TIMESTAMP)
    SELECT
        src.SRC_KEY,
        a.ACTIVE_ID,
        ar.ARCHIVE_ID,
        COALESCE(a.ACTIVE_ID, ar.ARCHIVE_ID, -1) AS FINAL_ID,
        :load_ts
    FROM STG_CUSTOMER_KEYS src
    LEFT JOIN DIM_CUSTOMER_ACTIVE a
        ON a.SRC_KEY = src.SRC_KEY
    LEFT JOIN DIM_CUSTOMER_ARCHIVE ar
        ON ar.SRC_KEY = src.SRC_KEY;

    rows_loaded := SQLROWCOUNT;
    RETURN 'SP_CASCADING_FALLBACK_LOOKUP: loaded ' || rows_loaded || ' resolved customer row(s).';
END;
$$;
