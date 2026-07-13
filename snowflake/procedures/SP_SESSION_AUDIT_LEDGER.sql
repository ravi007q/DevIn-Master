-- ============================================================================
-- Procedure : SP_SESSION_AUDIT_LEDGER
-- Source map: m_session_audit_ledger (Sample_11_Mapping.xml)
-- Pattern   : Session Audit Ledger
--
-- Transformation pipeline mapped to SQL:
--   SQ_CORE_DATA -> reads metric rows from STG_AUDIT_METRICS
--
-- The Informatica mapping relies on pre/post-session variables to identify the
-- session; this Snowflake procedure accepts an optional session id/name and
-- defaults to a generated UUID so every run produces a distinct audit session.
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_SESSION_AUDIT_LEDGER(
    P_SESSION_ID   STRING DEFAULT NULL,
    P_SESSION_NAME STRING DEFAULT 'AUDIT_LEDGER'
)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    session_id  STRING;
    rows_loaded INTEGER DEFAULT 0;
BEGIN
    IF (P_SESSION_ID IS NULL) THEN
        session_id := UUID_STRING();
    ELSE
        session_id := P_SESSION_ID;
    END IF;

    INSERT INTO AUDIT_LEDGER (SESSION_ID, SESSION_NAME, METRIC_ID, VALUE, LOAD_TIMESTAMP)
    SELECT
        :session_id,
        COALESCE(:P_SESSION_NAME, 'AUDIT_LEDGER'),
        METRIC_ID,
        VALUE,
        CURRENT_TIMESTAMP()
    FROM STG_AUDIT_METRICS;

    rows_loaded := SQLROWCOUNT;
    RETURN 'SP_SESSION_AUDIT_LEDGER: session_id=' || session_id
        || ', rows=' || rows_loaded || '.';
END;
$$;
