-- ============================================================================
-- Procedure : SP_TXN_STATE_TRACKING
-- Source map: m_txn_state_tracking_complex (Sample_4_Mapping.xml)
-- Pattern   : Full Refresh (Stateful Row Comparison)
--
-- Transformation pipeline mapped to SQL:
--   SQ_STG_TXNS       -> SELECT ... ORDER BY ACCOUNT_ID, TXN_DATE ASC
--   EXP_State_Engine  -> Informatica VARIABLE PORTS translated to LAG():
--                          V_PREV_STATUS = LAG(STATUS) OVER (PARTITION BY ACCOUNT_ID ORDER BY TXN_DATE)
--                          V_STATE_CHANGED = (first row of account) OR (STATUS <> prev status)
--   RTR_State_Changes -> WHERE STATE_CHANGED_FLAG = 1 (no DEFAULT group)
--
-- BR-2: First txn of an account is always a state change (PREV_STATUS NULL).
-- BR-3: Subsequent rows only when STATUS differs from previous.
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_TXN_STATE_TRACKING()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    rows_loaded INTEGER DEFAULT 0;
BEGIN
    TRUNCATE TABLE TXN_STATE_CHANGES;

    INSERT INTO TXN_STATE_CHANGES
        (ACCOUNT_ID, TXN_DATE, STATUS, AMOUNT, PREV_STATUS, STATE_CHANGED_FLAG, LOAD_TIMESTAMP)
    WITH ranked AS (
        SELECT
            ACCOUNT_ID,
            TXN_DATE,
            STATUS,
            AMOUNT,
            LAG(STATUS) OVER (PARTITION BY ACCOUNT_ID ORDER BY TXN_DATE) AS PREV_STATUS
        FROM STG_TXNS
    )
    SELECT
        ACCOUNT_ID,
        TXN_DATE,
        STATUS,
        AMOUNT,
        PREV_STATUS,                       -- BR-6: NULL for first row of each account
        1 AS STATE_CHANGED_FLAG,           -- only state-change rows reach the target
        CURRENT_TIMESTAMP()
    FROM ranked
    WHERE PREV_STATUS IS NULL              -- first transaction of the account (BR-2)
       OR STATUS <> PREV_STATUS;           -- status changed (BR-3)

    rows_loaded := SQLROWCOUNT;
    RETURN 'SP_TXN_STATE_TRACKING: loaded ' || rows_loaded || ' state-change rows.';
END;
$$;
