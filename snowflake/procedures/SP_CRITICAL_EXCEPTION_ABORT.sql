-- ============================================================================
-- Procedure : SP_CRITICAL_EXCEPTION_ABORT
-- Source map: m_critical_exception_abort (Sample_13_Mapping.xml)
-- Pattern   : Data Integrity Validation with Abort
--
-- Transformation pipeline mapped to SQL:
--   EXP_Sanity_Check -> IIF(TOTAL_BALANCE < 0, ABORT('...'), 'Y')
--
-- The procedure aborts with a custom exception if any source row has a
-- negative total balance. If the validation passes, it loads the rows into
-- BATCH_VALIDATED with a 'PASSED' status.
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_CRITICAL_EXCEPTION_ABORT()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    bad_count     INTEGER DEFAULT 0;
    rows_loaded   INTEGER DEFAULT 0;
    load_ts       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP();
    NEGATIVE_BALANCE_EXCEPTION EXCEPTION (-20001, 'CRITICAL DATA INTEGRITY VIOLATION: NEGATIVE BATCH BALANCES DETECTED');
BEGIN
    SELECT COUNT(*) INTO :bad_count
    FROM STG_BATCH_BALANCE
    WHERE TOTAL_BALANCE < 0;

    IF (bad_count > 0) THEN
        RAISE NEGATIVE_BALANCE_EXCEPTION;
    END IF;

    TRUNCATE TABLE BATCH_VALIDATED;

    INSERT INTO BATCH_VALIDATED (BATCH_ID, TOTAL_BALANCE, VALIDATION_STATUS, LOAD_TIMESTAMP)
    SELECT BATCH_ID, TOTAL_BALANCE, 'PASSED', :load_ts
    FROM STG_BATCH_BALANCE;
    rows_loaded := SQLROWCOUNT;

    RETURN 'SP_CRITICAL_EXCEPTION_ABORT: validated ' || rows_loaded || ' batch row(s).';
END;
$$;
