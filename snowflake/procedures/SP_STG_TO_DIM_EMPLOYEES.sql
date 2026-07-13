-- ============================================================================
-- Procedure : SP_STG_TO_DIM_EMPLOYEES
-- Source map: m_stg_to_dim_employees_standard (Sample_1_Mapping.xml)
-- Pattern   : Full Refresh (Truncate & Reload)
--
-- Transformation pipeline mapped to SQL:
--   SQ_STG_EMPLOYEES   -> FROM STG_EMPLOYEES
--   FIL_Active_Employees -> WHERE STATUS = 'A'
--   EXP_Transform_Fields -> FULL_NAME = FIRST_NAME||' '||LAST_NAME,
--                           LAST_UPDATED = CURRENT_TIMESTAMP() (SYSDATE)
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_STG_TO_DIM_EMPLOYEES()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    rows_loaded INTEGER DEFAULT 0;
BEGIN
    -- BR-4: Target fully refreshed on each run
    TRUNCATE TABLE DIM_EMPLOYEES;

    INSERT INTO DIM_EMPLOYEES (EMP_ID, FULL_NAME, DEPARTMENT, SALARY, LAST_UPDATED)
    SELECT
        EMP_ID,
        FIRST_NAME || ' ' || LAST_NAME AS FULL_NAME,   -- BR-2
        DEPARTMENT,
        SALARY,
        CURRENT_TIMESTAMP()                            -- BR-3
    FROM STG_EMPLOYEES
    WHERE STATUS = 'A';                                -- BR-1 (FIL_Active_Employees)

    rows_loaded := SQLROWCOUNT;
    RETURN 'SP_STG_TO_DIM_EMPLOYEES: loaded ' || rows_loaded || ' active employee rows.';
END;
$$;
