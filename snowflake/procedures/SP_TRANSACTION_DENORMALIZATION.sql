-- ============================================================================
-- Procedure : SP_TRANSACTION_DENORMALIZATION
-- Source map: m_transaction_denormalization (Sample_7_Mapping.xml)
-- Pattern   : Full Refresh (conditional-aggregate pivot)
--
-- NOTE: This mapping is NOT documented in BRD.txt. Logic is derived from the
--       AGG_Pivot_Lines aggregator, which groups by INVOICE_ID and pivots
--       LINE_AMOUNT into category columns via SUM(IIF(LINE_TYPE=..., LINE_AMOUNT, 0)):
--         TOTAL_TAX_AMT     = SUM(IIF(LINE_TYPE='TAX',     LINE_AMOUNT, 0))
--         TOTAL_ITEM_AMT    = SUM(IIF(LINE_TYPE='ITEM',    LINE_AMOUNT, 0))
--         TOTAL_FREIGHT_AMT = SUM(IIF(LINE_TYPE='FREIGHT', LINE_AMOUNT, 0))
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_TRANSACTION_DENORMALIZATION()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    rows_loaded INTEGER DEFAULT 0;
BEGIN
    TRUNCATE TABLE INVOICE_DENORMALIZED;

    INSERT INTO INVOICE_DENORMALIZED
        (INVOICE_ID, TOTAL_TAX_AMT, TOTAL_ITEM_AMT, TOTAL_FREIGHT_AMT, LOAD_TIMESTAMP)
    SELECT
        INVOICE_ID,
        SUM(IFF(LINE_TYPE = 'TAX',     LINE_AMOUNT, 0)) AS TOTAL_TAX_AMT,
        SUM(IFF(LINE_TYPE = 'ITEM',    LINE_AMOUNT, 0)) AS TOTAL_ITEM_AMT,
        SUM(IFF(LINE_TYPE = 'FREIGHT', LINE_AMOUNT, 0)) AS TOTAL_FREIGHT_AMT,
        CURRENT_TIMESTAMP()
    FROM STG_INVOICE_LINES
    GROUP BY INVOICE_ID;

    rows_loaded := SQLROWCOUNT;
    RETURN 'SP_TRANSACTION_DENORMALIZATION: loaded ' || rows_loaded || ' invoice row(s).';
END;
$$;
