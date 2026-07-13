-- ============================================================================
-- Procedure : SP_PRIORITY_DEDUPLICATION
-- Source map: m_priority_deduplication (Sample_10_Mapping.xml)
-- Pattern   : Deduplication with Priority (sorted input -> first row per group)
--
-- Transformation pipeline mapped to SQL:
--   SRT_Order_Priority -> ORDER BY CUSTOMER_ID ASC, UPDATED_AT DESC
--   AGG_Keep_First     -> one row per CUSTOMER_ID; QUALIFY/ROW_NUMBER
--                         preserves the newest (highest priority) lead source.
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_PRIORITY_DEDUPLICATION()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    rows_loaded INTEGER DEFAULT 0;
BEGIN
    TRUNCATE TABLE LEADS_PRIORITY;

    INSERT INTO LEADS_PRIORITY (CUSTOMER_ID, LEAD_SOURCE, UPDATED_AT, LOAD_TIMESTAMP)
    SELECT
        CUSTOMER_ID,
        LEAD_SOURCE,
        UPDATED_AT,
        CURRENT_TIMESTAMP()
    FROM STG_LEADS
    QUALIFY ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY UPDATED_AT DESC) = 1;

    rows_loaded := SQLROWCOUNT;
    RETURN 'SP_PRIORITY_DEDUPLICATION: loaded ' || rows_loaded || ' prioritized lead row(s).';
END;
$$;
