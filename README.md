# 🏥 Healthcare Claims Analytics — MySQL Project

## Project Overview

A complete end-to-end SQL analytics project on a synthetic healthcare claims dataset (10,000+ records).
Demonstrates skills in data modelling, SQL querying (basic to advanced), and business insight generation — directly relevant to data analyst roles in healthcare, insurance, and BFSI domains.

---

## Dataset Description

### Patient Demographics
- **1,000 patients** distributed across 10 US states
- Age range: 18–84 years (realistic distribution)
- Gender split: roughly 50/50 Male/Female
- Insurance types: Private (~45%), Medicare (~25%), Medicaid (~20%), Self-Pay (~10%)

## SQL Skills Demonstrated

### Basic
- SELECT, WHERE, ORDER BY, LIMIT
- GROUP BY, HAVING, aggregate functions (COUNT, SUM, AVG, MAX)
- CASE WHEN for conditional logic

### Intermediate
- INNER JOIN, LEFT JOIN across 3+ tables
- Multi-level GROUP BY
- Subqueries in WHERE and FROM clauses
- NULLIF for safe division

### Advanced
- **CTEs** (WITH clause) for multi-step logic
- **Window Functions**: RANK(), LAG(), SUM() OVER()
- **PARTITION BY** for group-level rankings
- Running totals and year-over-year calculations
- Fraud detection logic (statistical outliers)
- Revenue leakage analysis

---

## Key Business Questions Answered

1. Which payer type contributes the most to total billed vs total paid gaps?
2. What is the average number of days from service to payment (A/R turnaround)?
3. Which procedures have the highest revenue contribution per claim?
4. What is our denial rate, and which denial reasons are most frequent?
5. Which admission types (emergency, elective) have the highest denial rates?
6. Are there approved claims that were never followed up with payment?
7. Which specialties have the highest denial rates, and why?
8. Which providers consistently bill above the specialty average — potential overbilling?
---

## Sample Insight (from the data)

- Collection rate is below industry benchmark
- 64% of denials are process-preventable
- Critical Care and Psychiatry are denial hotspots
- Surgical procedures dominate high-cost claims
- Chronic conditions drive repeat claim volume
- 10% readmission rate is an avoidable cost signal
- 3–5% of claims show potential overbilling patterns
