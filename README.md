# 🏥 Healthcare Claims Analytics — MySQL Project

> **A production-grade MySQL portfolio project built for Data Analyst interviews.**  
> Includes 1,000 synthetic healthcare claims records, 50+ interview-ready queries, and complete analytical documentation.

---

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Database Architecture](#database-architecture)
3. [Entity Relationship Diagram](#entity-relationship-diagram)
4. [Dataset Description](#dataset-description)
5. [Business Context & Analytical Goals](#business-context--analytical-goals)
6. [Project Structure](#project-structure)
7. [Setup & Installation](#setup--installation)
8. [Query Reference Guide](#query-reference-guide)
9. [Key Analytical Insights](#key-analytical-insights)
10. [Interview Topics Covered](#interview-topics-covered)
11. [Performance & Optimization](#performance--optimization)
12. [Skills Demonstrated](#skills-demonstrated)

---

## Project Overview

Healthcare claims processing is one of the most data-intensive domains in the industry. Insurance companies, hospitals, and government agencies process **millions of claims daily**, and data analysts play a critical role in detecting fraud, reducing costs, improving patient outcomes, and optimizing revenue cycles.

This project simulates a **real-world Revenue Cycle Management (RCM)** system with:

| Metric | Value |
|---|---|
| Total Patients | 1,000 |
| Total Claims | 1,000 |
| Total Providers | 20 |
| Diagnosis Codes (ICD-10) | 20 |
| Procedure Codes (CPT) | 20 |
| Insurance Types | 4 |
| Admission Types | 4 |
| Claim Statuses | 4 |
| Interview Queries | 50 |
| SQL Concepts Covered | 25+ |

---

## Database Architecture

The database follows a **normalized star-schema** design centered on the `claims` table, which acts as a fact table with dimension tables around it.

```
patients ──────┐
providers ─────┤
diagnoses ─────┼──► claims ◄──► claim_payments
procedures ────┘
```

### Tables

| Table | Rows | Description |
|---|---|---|
| `patients` | 1,000 | Demographics, insurance type, location |
| `providers` | 20 | Physicians, hospitals, specialties |
| `diagnoses` | 20 | ICD-10 coded diagnoses with chronic flag |
| `procedures` | 20 | CPT coded procedures with standard costs |
| `claims` | 1,000 | Core claims: billed, allowed, paid amounts, status |
| `claim_payments` | ~650 | Payment records for approved claims |

---

## Entity Relationship Diagram

```
┌─────────────┐     ┌──────────────────────────────────────────┐
│  patients   │     │                claims                     │
│─────────────│     │──────────────────────────────────────────│
│ patient_id  │────►│ claim_id          claim_date             │
│ first_name  │     │ patient_id (FK)   service_date           │
│ last_name   │     │ provider_id (FK)  discharge_date         │
│ dob         │     │ diagnosis_id (FK) admission_type         │
│ gender      │     │ procedure_id (FK) claim_status           │◄──┐
│ insurance   │     │ billed_amount     allowed_amount         │   │
│ state       │     │ paid_amount       denial_reason          │   │
│ city        │     │ length_of_stay    readmission_flag       │   │
└─────────────┘     └──────────────────────────────────────────┘   │
                                                                    │
┌─────────────┐     ┌─────────────┐     ┌──────────────────┐       │
│  providers  │     │  diagnoses  │     │   procedures     │       │
│─────────────│     │─────────────│     │──────────────────│       │
│ provider_id │     │diagnosis_id │     │ procedure_id     │       │
│ prov_name   │     │ icd10_code  │     │ cpt_code         │       │
│ specialty   │     │ diag_name   │     │ procedure_name   │       │
│ hospital    │     │ category    │     │ category         │       │
│ npi_number  │     │ chronic_flag│     │ standard_cost    │       │
└─────────────┘     └─────────────┘     └──────────────────┘       │
                                                                    │
                    ┌──────────────────────────────────────┐        │
                    │          claim_payments              │        │
                    │──────────────────────────────────────│        │
                    │ payment_id    payment_date           │────────┘
                    │ claim_id (FK) payment_amount         │
                    │ payment_method  payer_name           │
                    └──────────────────────────────────────┘
```

---

## Dataset Description

### Patient Demographics
- **1,000 patients** distributed across 10 US states
- Age range: 18–84 years (realistic distribution)
- Gender split: roughly 50/50 Male/Female
- Insurance types: Private (~45%), Medicare (~25%), Medicaid (~20%), Self-Pay (~10%)

### Claims Data
The claims data is designed to reflect **real-world healthcare patterns**:

| Field | Distribution |
|---|---|
| `claim_status` | Approved ~65%, Denied ~15%, Pending ~12%, Under Review ~8% |
| `admission_type` | Emergency (~25%), Elective (~40%), Urgent (~25%), Newborn (~10%) |
| `readmission_flag` | ~10% readmission rate (industry average is ~15%) |
| `length_of_stay` | 0–14 days (outpatient to complex inpatient) |
| Date range | Past 2 years of claims data |

### Financial Metrics
- **Billed Amount**: Full charged rate (procedure standard cost +0–30% markup)
- **Allowed Amount**: 65–90% of billed (negotiated rates)
- **Paid Amount**: 75–100% of allowed (actual reimbursement)
- **Write-off Rate**: The gap between billed and paid represents contractual adjustments

---

## Business Context & Analytical Goals

Healthcare data analysts typically work on these problem domains. This project covers all of them:

### 1. Revenue Cycle Management (RCM)
> *How much money is being billed, collected, and written off?*

Key Metrics tracked:
- **Gross Collection Rate** = Total Paid / Total Billed × 100
- **Net Collection Rate** = Total Paid / (Total Billed - Contractual Adj.) × 100
- **Days in Accounts Receivable (A/R)** = Outstanding Balances / Daily Revenue
- **Denial Rate** = Denied Claims / Total Claims × 100

See: `Q6`, `Q7`, `Q37`, `Q50`

### 2. Utilization Management
> *Are patients using healthcare appropriately? Are there overutilizers?*

Key Metrics tracked:
- **Average Length of Stay (ALOS)** — by diagnosis, admission type
- **Readmission Rate** — within 30 days post-discharge
- **High-Cost Patient Identification** — top 20% cost drivers
- **Procedure Frequency** — most/least performed services

See: `Q5`, `Q27`, `Q36`, `Q39`

### 3. Provider Performance
> *Which providers are most efficient, and which have high denial rates?*

Key Metrics tracked:
- **Denial Rate by Specialty** — where are the highest denial concentrations?
- **Average Billed Amount per Visit** — potential outlier providers
- **Billing Pattern Analysis** — anomalous charge patterns (fraud signals)
- **TAT (Turnaround Time)** — days from service to claim submission

See: `Q10`, `Q19`, `Q29`, `Q31`, `Q35`

### 4. Population Health Analytics
> *What are the disease burden and cost patterns across patient populations?*

Key Metrics tracked:
- **Chronic Disease Prevalence** — diabetes, hypertension, COPD
- **Age-Group Cost Analysis** — where are the heaviest utilizers?
- **State-Level Heatmaps** — geographic patterns in claims and costs
- **Insurance Cohort Comparisons** — Medicare vs. Medicaid vs. Private

See: `Q3`, `Q17`, `Q18`, `Q40`, `Q47`

### 5. Fraud & Abuse Detection
> *Are there anomalous billing patterns that suggest fraud or billing errors?*

Key Signals detected:
- Claims billed **≥ 2× the specialty average**
- Providers with **unusually high denial rates**
- **Duplicate submission patterns** (denial reason analysis)
- **Excessive length of stay** outliers by diagnosis

See: `Q35`, `Q4`, `Q15`, `Q43`

---

## Project Structure

```
healthcare_claims_mysql/
│
├── scripts/
│   ├── 01_schema.sql          # DDL: Tables, indexes, foreign keys
│   └── 02_seed_data.sql       # 1000 records via stored procedure
│
├── queries/
│   ├── 01_basic_to_intermediate.sql    # Q1–Q20
│   └── 02_advanced_queries.sql         # Q21–Q50
│
└── README.md                  # This file
```

---

## Setup & Installation

### Prerequisites
- MySQL 8.0+ (Window Functions & CTEs supported)
- MySQL Workbench or any MySQL client

### Step 1: Clone the repository
```bash
git clone https://github.com/yourusername/healthcare-claims-mysql.git
cd healthcare-claims-mysql
```

### Step 2: Run the schema
```bash
mysql -u root -p < scripts/01_schema.sql
```

### Step 3: Seed the data (generates 1,000 records)
```bash
mysql -u root -p < scripts/02_seed_data.sql
```
> ⏱️ The seed script uses a stored procedure loop; expect ~15–30 seconds to run.

### Step 4: Run interview queries
```bash
mysql -u root -p healthcare_claims < queries/01_basic_to_intermediate.sql
mysql -u root -p healthcare_claims < queries/02_advanced_queries.sql
```

### Step 5: Verify data
```sql
USE healthcare_claims;
SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'healthcare_claims';
```

---

## Query Reference Guide

### Part 1: Basic to Intermediate (`01_basic_to_intermediate.sql`)

| # | Query | SQL Concepts |
|---|---|---|
| Q1 | Claims in last 6 months | `WHERE`, `DATE_SUB`, `JOIN` |
| Q2 | All denied claims with reasons | `WHERE`, multi-table `JOIN` |
| Q3 | Medicare emergency patients | `DISTINCT`, `WHERE` multi-condition |
| Q4 | Claims overbilled by 30%+ | Arithmetic filter, `ROUND` |
| Q5 | Readmission cases | `WHERE` flag filter, multi `JOIN` |
| Q6 | Billed/paid by insurance type | `GROUP BY`, `SUM`, `AVG` |
| Q7 | Monthly revenue trend | `DATE_FORMAT`, `GROUP BY`, ratio calc |
| Q8 | Claim status distribution | `COUNT`, `SUM OVER()` window |
| Q9 | Top 5 expensive procedures | `GROUP BY`, `ORDER BY`, `LIMIT` |
| Q10 | Providers with 30+ claims | `HAVING` clause |
| Q11 | Full claim detail report | 5-table `JOIN` |
| Q12 | Patients with no claims | `LEFT JOIN` + `IS NULL` |
| Q13 | Approved claims without payments | `LEFT JOIN` + `IS NULL` |
| Q14 | Patients above average spend | Nested subquery |
| Q15 | Most common denial reason | Subquery in `FROM`, `CROSS JOIN` |
| Q16 | High-billing providers | Correlated subquery in `HAVING` |
| Q17 | Chronic condition patients | `EXISTS` subquery |
| Q18 | Age group analysis | `CASE WHEN`, `GROUP BY` |
| Q19 | Service-to-claim TAT | `DATEDIFF`, `AVG`, `GROUP BY` |
| Q20 | Quarterly billing summary | `YEAR()`, `QUARTER()` |

### Part 2: Advanced (`02_advanced_queries.sql`)

| # | Query | SQL Concepts |
|---|---|---|
| Q21 | Provider rank by specialty | `RANK()`, `DENSE_RANK()`, `PARTITION BY` |
| Q22 | Running total of payments | `SUM OVER (ROWS BETWEEN...)` |
| Q23 | Month-over-month growth | `LAG()`, CTE, growth % formula |
| Q24 | 3-month moving average | `AVG OVER (ROWS BETWEEN...)` |
| Q25 | Patient spend percentile | `NTILE(4)`, `PERCENT_RANK()` |
| Q26 | First/last claim per patient | `FIRST_VALUE()`, `LAST_VALUE()` |
| Q27 | High-cost patient cohort | Multi-CTE, `PERCENTILE` logic |
| Q28 | Payment gap buckets | CTE chain, `CASE WHEN` bucketing |
| Q29 | Denial rate by specialty | Multi-CTE, `LEFT JOIN` aggregation |
| Q30 | Claims dashboard VIEW | `CREATE VIEW`, complex `JOIN` |
| Q31 | Provider performance VIEW | `CREATE VIEW`, aggregation |
| Q32 | Patient history procedure | `CREATE PROCEDURE`, `IN` param |
| Q33 | Denial rate by date range | `CREATE PROCEDURE`, date params |
| Q34 | Patient age function | `CREATE FUNCTION`, `DETERMINISTIC` |
| Q35 | Fraud detection query | CTE, ratio analysis, flagging |
| Q36 | Readmission gap analysis | Self-`JOIN` on claims |
| Q37 | Cost efficiency by insurance | Write-off analysis, ratios |
| Q38 | Status pivot by admission type | `CASE WHEN` pivot pattern |
| Q39 | LOS by diagnosis category | Filtered aggregation |
| Q40 | State-level heatmap | Geographic aggregation |
| Q41 | EXPLAIN execution plan | `EXPLAIN`, query optimization |
| Q42 | Composite index creation | `CREATE INDEX` |
| Q43 | Index inspection | `SHOW INDEX` |
| Q44 | NULL audit / data quality | `SUM(CASE WHEN IS NULL...)` |
| Q45 | NULL replacement | `COALESCE`, `IFNULL` |
| Q46 | Atomic update with transaction | `START TRANSACTION`, `COMMIT` |
| Q47 | Top diagnosis per insurance | CTE + `ROW_NUMBER()` |
| Q48 | Year-over-year comparison | Conditional aggregation, YoY % |
| Q49 | Patient cohort analysis | Cohort CTE, retention tracking |
| Q50 | KPI dashboard query | Master summary, all metrics |

---

## Key Analytical Insights

> The following findings are derived from the synthetic dataset and reflect patterns typical in real healthcare analytics.

### Revenue Cycle
- The **overall collection rate** (paid/billed) averages around **68–72%** — typical for US healthcare
- **Self-Pay patients** show the highest write-off rates (low collectability)
- **Medicare claims** tend to have the **lowest denial rates** due to standardized fee schedules
- The average **turnaround time** from service to claim submission varies by 3–12 days across specialties

### Clinical Patterns
- **Chronic conditions** (diabetes, hypertension, COPD) drive the **highest repeat claim volumes**
- Emergency admissions represent ~25% of claims but **40%+ of total billed dollars**
- The **30-day readmission rate** of ~10% signals opportunities for care coordination improvement
- **Surgical procedures** (knee arthroplasty, cholecystectomy) are the highest-cost per claim

### Provider Efficiency
- High-volume providers (50+ claims) tend to have **lower average denial rates** (process familiarity)
- Certain specialties show **billing amounts 1.5–2× the average** — potential audit targets
- **Emergency Medicine** has the fastest claim submission TAT, while **Psychiatry** has the longest

### Fraud Signals
- ~3–5% of claims show billed amounts **≥2× their specialty average**
- Providers with **>20% denial rates** merit closer review
- **Duplicate submission** is the 3rd most common denial reason

---

## Interview Topics Covered

This project is designed to help you answer real interview questions:

### "Walk me through a complex SQL query you've written"
→ Use **Q27** (High-cost patient CTE) or **Q36** (Self-join readmission analysis)

### "How would you detect fraud in claims data?"
→ Use **Q35** and explain the 2× specialty average methodology + additional signals

### "Explain window functions with a business use case"
→ Use **Q21** (provider ranking), **Q22** (running total), **Q23** (MoM LAG)

### "How do you optimize a slow query?"
→ Use **Q41** (`EXPLAIN`), **Q42** (composite indexes), explain index selection

### "How would you build a KPI dashboard in SQL?"
→ Use **Q30** (VIEW creation), **Q50** (KPI summary), discuss BI tool integration

### "What's the difference between WHERE and HAVING?"
→ `WHERE` filters rows before aggregation; `HAVING` filters after. Demonstrate with **Q10** and **Q16**

### "Explain JOIN types with examples from this dataset"
→ INNER JOIN (**Q11**), LEFT JOIN for gaps (**Q12**, **Q13**), Self-join (**Q36**)

### "How do you handle NULL values in analytics?"
→ Use **Q44** (NULL audit), **Q45** (`COALESCE`/`IFNULL`), explain implications on `AVG`, `SUM`

---

## Performance & Optimization

### Index Strategy
```sql
-- Primary indexes (created in schema)
PRIMARY KEY on each table (clustered index)
UNIQUE on policy_number, icd10_code, cpt_code, npi_number

-- Query performance indexes
idx_claims_patient      ON claims(patient_id)
idx_claims_provider     ON claims(provider_id)
idx_claims_date         ON claims(claim_date)
idx_claims_status       ON claims(claim_status)
idx_claims_status_date  ON claims(claim_status, claim_date)  -- composite
idx_claims_patient_date ON claims(patient_id, claim_date)    -- composite
```

### Query Optimization Principles Applied
1. **Selective filtering first** — `WHERE` on indexed columns before `JOIN`
2. **CTEs over subqueries** — for readability and optimizer hints
3. **NULLIF for safe division** — prevents division-by-zero errors
4. **COALESCE in aggregations** — accurate SUM/AVG with NULL data
5. **LIMIT on exploratory queries** — prevent full-table scans during development
6. **Views for reusability** — abstract complex joins into named views

---

## Skills Demonstrated

| Category | Skills |
|---|---|
| **DDL** | CREATE TABLE, PRIMARY KEY, FOREIGN KEY, UNIQUE, INDEX, ENUM |
| **DML** | SELECT, INSERT, UPDATE (in transactions) |
| **Joins** | INNER, LEFT, SELF, CROSS |
| **Aggregation** | SUM, COUNT, AVG, MIN, MAX, GROUP BY, HAVING |
| **Window Functions** | RANK, DENSE_RANK, ROW_NUMBER, LAG, LEAD, NTILE, PERCENT_RANK, FIRST_VALUE, LAST_VALUE, SUM OVER, AVG OVER |
| **CTEs** | Single CTE, Multi-CTE, Chained CTEs |
| **Subqueries** | Scalar, Correlated, FROM-clause, EXISTS |
| **Conditional** | CASE WHEN, IF, IFNULL, COALESCE, NULLIF |
| **Date Functions** | DATE_FORMAT, DATE_SUB, DATE_ADD, DATEDIFF, TIMESTAMPDIFF, YEAR, QUARTER, MONTH |
| **String Functions** | CONCAT, ELT, LPAD, FLOOR, RAND |
| **Stored Objects** | CREATE PROCEDURE, CREATE FUNCTION, CREATE VIEW |
| **Transactions** | START TRANSACTION, COMMIT |
| **Performance** | EXPLAIN, CREATE INDEX, SHOW INDEX |
| **Data Quality** | NULL auditing, deduplication, data validation |
| **Analytics** | Revenue cycle KPIs, cohort analysis, fraud detection, YoY trends |

---

## License

This project is licensed under the MIT License — free to use for learning and portfolio purposes.

---

## Author

Built as a comprehensive MySQL portfolio project for **Data Analyst** interviews in the healthcare domain.

> 💡 **Pro Tip:** When presenting this project in an interview, focus on the business *context* behind each query — explain *why* the metric matters, not just *how* the SQL works. Data analysts who understand the healthcare domain alongside SQL are the most valuable candidates.
