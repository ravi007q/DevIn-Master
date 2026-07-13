# Informatica PowerCenter → Snowflake Stored Procedures

This folder contains the Snowflake conversion of the Informatica PowerCenter
(PowerMart) XML mappings in the repository root, based on the requirements in
[`BRD.txt`](../BRD.txt).

Target platform: **Snowflake**, database `ANALYSIS`, schema `PUBLIC`.

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
│   └── SP_TRANSACTION_DENORMALIZATION.sql
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

> **Mappings 6 & 7 are not documented in `BRD.txt`.** They were converted from
> the XML alone. Their target tables (`SALES_FACT_INCREMENTAL`,
> `INVOICE_DENORMALIZED`) and the source `STG_INVOICE_LINES` were inferred from
> the transformation logic — adjust names/columns to match your real schema.

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
```

Each procedure returns a status string with the affected row counts.

## Validation

Validation criteria for procedures 1–5 are defined in section 9 of
[`BRD.txt`](../BRD.txt) (row counts, hash correctness, SCD2 invariants,
state-change rules, XML well-formedness, idempotency).
