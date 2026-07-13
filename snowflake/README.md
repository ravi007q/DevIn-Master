# Informatica PowerCenter → Snowflake Stored Procedures

This folder contains the Snowflake conversion of all Informatica PowerCenter
(PowerMart) XML mappings in the repository root (`Sample_1_Mapping.xml` through
`Sample_13_Mapping.xml` on the `new-mapping` branch).

Target platform: **Snowflake**, database `ANALYSIS`, schema `PUBLIC`.

A detailed Business Requirements Document for all 13 mappings is available at
[`BRD.txt`](../BRD.txt).

## Layout

```
snowflake/
├── ddl/
│   └── 01_tables.sql            -- source + target table DDL
├── procedures/
│   ├── SP_STG_TO_DIM_EMPLOYEES.sql
│   ├── SP_SALES_PERF_ROUTING.sql
│   ├── SP_CUSTOMER_SCD2.sql
│   ├── SP_TXN_STATE_TRACKING.sql
│   ├── SP_HIERARCHICAL_XML_GENERATION.sql
│   ├── SP_DYNAMIC_INCREMENTAL_PARTITIONING.sql
│   ├── SP_TRANSACTION_DENORMALIZATION.sql
│   ├── SP_CONDITIONAL_LOOKUP_BYPASS.sql
│   ├── SP_MULTI_TARGET_CLEARINGHOUSE.sql
│   ├── SP_PRIORITY_DEDUPLICATION.sql
│   ├── SP_SESSION_AUDIT_LEDGER.sql
│   ├── SP_CASCADING_FALLBACK_LOOKUP.sql
│   └── SP_CRITICAL_EXCEPTION_ABORT.sql
└── README.md
```

## Mapping → Procedure traceability

| # | XML mapping | Informatica name | Snowflake procedure | Source tables | Target tables | Pattern |
|---|-------------|------------------|---------------------|---------------|---------------|---------|
| 1 | Sample_1 | `m_stg_to_dim_employees_standard` | `SP_STG_TO_DIM_EMPLOYEES` | STG_EMPLOYEES | DIM_EMPLOYEES | Truncate & reload |
| 2 | Sample_2 | `m_sales_perf_routing_complex` | `SP_SALES_PERF_ROUTING` | SALES, STORES, LKP_TARGET_BONUS | HIGH_PERFORMERS, STANDARD_PERFORMERS | Truncate & reload + routing |
| 3 | Sample_3 | `m_customer_scd2_enterprise` | `SP_CUSTOMER_SCD2` | STG_CUSTOMERS, STG_REGIONS | DIM_CUSTOMER | SCD Type 2 |
| 4 | Sample_4 | `m_txn_state_tracking_complex` | `SP_TXN_STATE_TRACKING` | STG_TXNS | TXN_STATE_CHANGES | Truncate & reload (stateful) |
| 5 | Sample_5 | `m_hierarchical_xml_generation` | `SP_HIERARCHICAL_XML_GENERATION` | ORDERS, ORDER_ITEMS | ORDER_XML_PAYLOADS | Truncate & reload (XML) |
| 6 | Sample_6 | `m_dynamic_incremental_partitioning` | `SP_DYNAMIC_INCREMENTAL_PARTITIONING` | STG_SALES_HIST | SALES_FACT_INCREMENTAL | Incremental (watermark window) |
| 7 | Sample_7 | `m_transaction_denormalization` | `SP_TRANSACTION_DENORMALIZATION` | STG_INVOICE_LINES | INVOICE_DENORMALIZED | Truncate & reload (pivot) |
| 8 | Sample_8 | `m_conditional_lookup_bypass` | `SP_CONDITIONAL_LOOKUP_BYPASS` | STG_TXN_LINES, FACT_TRANSACTION_HISTORY | TXN_STRAIGHT_THROUGH, TXN_HIST_LOOKUP | Conditional lookup bypass |
| 9 | Sample_9 | `m_multi_target_clearinghouse` | `SP_MULTI_TARGET_CLEARINGHOUSE` | STG_CLEARINGHOUSE | CLEARINGHOUSE_DOMESTIC_HIGH_RISK, CLEARINGHOUSE_INTERNATIONAL, CLEARINGHOUSE_AUDIT_LOG | Multi-target router |
| 10 | Sample_10 | `m_priority_deduplication` | `SP_PRIORITY_DEDUPLICATION` | STG_LEADS | LEADS_PRIORITY | Deduplication with priority |
| 11 | Sample_11 | `m_session_audit_ledger` | `SP_SESSION_AUDIT_LEDGER` | STG_AUDIT_METRICS | AUDIT_LEDGER | Session audit ledger |
| 12 | Sample_12 | `m_cascading_fallback_lookup` | `SP_CASCADING_FALLBACK_LOOKUP` | STG_CUSTOMER_KEYS, DIM_CUSTOMER_ACTIVE, DIM_CUSTOMER_ARCHIVE | CUSTOMER_RESOLVED | Cascading fallback lookup |
| 13 | Sample_13 | `m_critical_exception_abort` | `SP_CRITICAL_EXCEPTION_ABORT` | STG_BATCH_BALANCE | BATCH_VALIDATED | Validation with abort |

> **Source/target names for mappings 8-13 are inferred from the XML**
> (transformation logic, lookup source table names, and field names). Adjust
> names and columns to match your real schema if necessary.

## Transformation type mapping

| Informatica transformation | Snowflake equivalent |
|----------------------------|----------------------|
| Source Qualifier | `FROM` / custom `SELECT` (incl. SQL overrides) |
| Filter | `WHERE` clause |
| Expression | `SELECT` expressions / `CASE` / `IFF` |
| Joiner | `INNER JOIN` / `LEFT JOIN` |
| Lookup | `LEFT JOIN` to reference table |
| Aggregator | `GROUP BY` + `SUM`/`COUNT` |
| Router | multiple `INSERT`s with `WHERE` conditions |
| Update Strategy | `UPDATE` statement |
| Sequence Generator | `AUTOINCREMENT` column |
| XML Generator | `LISTAGG` + string concatenation |
| Variable Ports (stateful) | `LAG()` window function |
| Mapping Parameters (`$$...`) | stored-procedure arguments |
| ABORT | `RAISE` of a custom `EXCEPTION` |

## Deployment

Run in order against the `ANALYSIS.PUBLIC` schema:

```sql
-- 1. Create tables
!source snowflake/ddl/01_tables.sql

-- 2. Create procedures (run each file in snowflake/procedures/)
```

Then execute, e.g.:

```sql
CALL SP_STG_TO_DIM_EMPLOYEES();
CALL SP_SALES_PERF_ROUTING();
CALL SP_CUSTOMER_SCD2();
CALL SP_TXN_STATE_TRACKING();
CALL SP_HIERARCHICAL_XML_GENERATION();
CALL SP_DYNAMIC_INCREMENTAL_PARTITIONING('2026-01-01', '2026-02-01');
CALL SP_TRANSACTION_DENORMALIZATION();
CALL SP_CONDITIONAL_LOOKUP_BYPASS();
CALL SP_MULTI_TARGET_CLEARINGHOUSE();
CALL SP_PRIORITY_DEDUPLICATION();
CALL SP_SESSION_AUDIT_LEDGER();
CALL SP_CASCADING_FALLBACK_LOOKUP();
CALL SP_CRITICAL_EXCEPTION_ABORT();
```

Each procedure returns a status string with the affected row counts.

## Validation

- Procedures that produce a single target are idempotent (full-refresh).
- Incremental procedures (e.g. `SP_DYNAMIC_INCREMENTAL_PARTITIONING`) delete the
  target window before loading so they can be re-run safely.
- SCD2 logic preserves history by expiring old versions and inserting new active
  rows.
- `SP_CRITICAL_EXCEPTION_ABORT` raises an exception when `TOTAL_BALANCE < 0` and
  loads nothing.
