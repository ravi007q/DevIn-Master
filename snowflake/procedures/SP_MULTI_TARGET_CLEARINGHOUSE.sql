-- ============================================================================
-- Procedure : SP_MULTI_TARGET_CLEARINGHOUSE
-- Source map: m_multi_target_clearinghouse (Sample_9_Mapping.xml)
-- Pattern   : Multi-Target Router (non-exclusive groups)
--
-- Transformation pipeline mapped to SQL:
--   RTR_Data_Clearinghouse -> three non-exclusive groups:
--     GRP_DOMESTIC_HIGH_RISK  : COUNTRY_CODE = 'USA' AND RISK_SCORE > 80
--     GRP_INTERNATIONAL       : COUNTRY_CODE != 'USA'
--     GRP_AUDIT_LOG           : RISK_SCORE > 50
--
-- A row may satisfy multiple groups and is therefore inserted into each
-- applicable target table.
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MULTI_TARGET_CLEARINGHOUSE()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    rows_domestic INTEGER DEFAULT 0;
    rows_intl     INTEGER DEFAULT 0;
    rows_audit    INTEGER DEFAULT 0;
    load_ts       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP();
BEGIN
    TRUNCATE TABLE CLEARINGHOUSE_DOMESTIC_HIGH_RISK;
    TRUNCATE TABLE CLEARINGHOUSE_INTERNATIONAL;
    TRUNCATE TABLE CLEARINGHOUSE_AUDIT_LOG;

    INSERT INTO CLEARINGHOUSE_DOMESTIC_HIGH_RISK (RECORD_ID, COUNTRY_CODE, RISK_SCORE, LOAD_TIMESTAMP)
    SELECT RECORD_ID, COUNTRY_CODE, RISK_SCORE, :load_ts
    FROM STG_CLEARINGHOUSE
    WHERE COUNTRY_CODE = 'USA' AND RISK_SCORE > 80;
    rows_domestic := SQLROWCOUNT;

    INSERT INTO CLEARINGHOUSE_INTERNATIONAL (RECORD_ID, COUNTRY_CODE, RISK_SCORE, LOAD_TIMESTAMP)
    SELECT RECORD_ID, COUNTRY_CODE, RISK_SCORE, :load_ts
    FROM STG_CLEARINGHOUSE
    WHERE COUNTRY_CODE != 'USA';
    rows_intl := SQLROWCOUNT;

    INSERT INTO CLEARINGHOUSE_AUDIT_LOG (RECORD_ID, COUNTRY_CODE, RISK_SCORE, LOAD_TIMESTAMP)
    SELECT RECORD_ID, COUNTRY_CODE, RISK_SCORE, :load_ts
    FROM STG_CLEARINGHOUSE
    WHERE RISK_SCORE > 50;
    rows_audit := SQLROWCOUNT;

    RETURN 'SP_MULTI_TARGET_CLEARINGHOUSE: DOMESTIC_HIGH=' || rows_domestic
        || ', INTERNATIONAL=' || rows_intl
        || ', AUDIT_LOG=' || rows_audit || '.';
END;
$$;
