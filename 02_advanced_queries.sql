-- ============================================================
--  HEALTHCARE CLAIMS - INTERVIEW QUERIES (Part 2)
--  Topics: Window Functions, CTEs, Views, Stored Procedures,
--          Indexes, Performance, Advanced Analytics
-- ============================================================

USE healthcare_claims;

-- ══════════════════════════════════════════════════════════════
--  SECTION 6: WINDOW FUNCTIONS (High-Value Interview Topic)
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q21. Rank providers by total billed amount within each specialty
-- ──────────────────────────────────────────────────────────────
SELECT
    prov.provider_name,
    prov.specialty,
    SUM(c.billed_amount)  AS total_billed,
    RANK() OVER (
        PARTITION BY prov.specialty
        ORDER BY SUM(c.billed_amount) DESC
    ) AS rank_within_specialty,
    DENSE_RANK() OVER (
        ORDER BY SUM(c.billed_amount) DESC
    ) AS overall_dense_rank
FROM claims c
JOIN providers prov ON c.provider_id = prov.provider_id
GROUP BY prov.provider_id, prov.provider_name, prov.specialty;


-- ──────────────────────────────────────────────────────────────
-- Q22. Running total of paid amounts ordered by claim date
-- ──────────────────────────────────────────────────────────────
SELECT
    claim_id,
    claim_date,
    paid_amount,
    SUM(paid_amount) OVER (
        ORDER BY claim_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_paid
FROM claims
WHERE paid_amount IS NOT NULL
ORDER BY claim_date;


-- ──────────────────────────────────────────────────────────────
-- Q23. Month-over-month claim volume change using LAG
-- ──────────────────────────────────────────────────────────────
WITH monthly_claims AS (
    SELECT
        DATE_FORMAT(claim_date, '%Y-%m') AS claim_month,
        COUNT(*)                          AS claim_count,
        SUM(billed_amount)                AS total_billed
    FROM claims
    GROUP BY claim_month
)
SELECT
    claim_month,
    claim_count,
    total_billed,
    LAG(claim_count)  OVER (ORDER BY claim_month) AS prev_month_count,
    LAG(total_billed) OVER (ORDER BY claim_month) AS prev_month_billed,
    ROUND(
        (claim_count - LAG(claim_count) OVER (ORDER BY claim_month))
        * 100.0
        / NULLIF(LAG(claim_count) OVER (ORDER BY claim_month), 0),
    2) AS mom_growth_pct
FROM monthly_claims
ORDER BY claim_month;


-- ──────────────────────────────────────────────────────────────
-- Q24. 3-month moving average of billed amounts
-- ──────────────────────────────────────────────────────────────
WITH monthly AS (
    SELECT
        DATE_FORMAT(claim_date, '%Y-%m') AS claim_month,
        SUM(billed_amount)               AS total_billed
    FROM claims
    GROUP BY claim_month
)
SELECT
    claim_month,
    total_billed,
    ROUND(AVG(total_billed) OVER (
        ORDER BY claim_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3m
FROM monthly
ORDER BY claim_month;


-- ──────────────────────────────────────────────────────────────
-- Q25. Percentile rank of each patient's total spend (NTILE)
-- ──────────────────────────────────────────────────────────────
WITH patient_spend AS (
    SELECT
        p.patient_id,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        p.insurance_type,
        SUM(c.billed_amount)                    AS total_billed
    FROM patients p
    JOIN claims c ON p.patient_id = c.patient_id
    GROUP BY p.patient_id, p.first_name, p.last_name, p.insurance_type
)
SELECT
    patient_name,
    insurance_type,
    total_billed,
    NTILE(4) OVER (ORDER BY total_billed) AS spend_quartile,
    PERCENT_RANK() OVER (ORDER BY total_billed) AS percentile_rank
FROM patient_spend
ORDER BY total_billed DESC;


-- ──────────────────────────────────────────────────────────────
-- Q26. FIRST_VALUE / LAST_VALUE — first and last claim per patient
-- ──────────────────────────────────────────────────────────────
SELECT DISTINCT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    FIRST_VALUE(c.claim_date) OVER (
        PARTITION BY c.patient_id
        ORDER BY c.claim_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_claim_date,
    LAST_VALUE(c.claim_date) OVER (
        PARTITION BY c.patient_id
        ORDER BY c.claim_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_claim_date
FROM claims c
JOIN patients p ON c.patient_id = p.patient_id
ORDER BY patient_id;


-- ══════════════════════════════════════════════════════════════
--  SECTION 7: CTEs (Common Table Expressions)
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q27. CTE — High-cost patients (top 20%) and their claim details
-- ──────────────────────────────────────────────────────────────
WITH patient_totals AS (
    SELECT
        patient_id,
        SUM(billed_amount) AS total_billed
    FROM claims
    GROUP BY patient_id
),
high_cost_threshold AS (
    SELECT PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY total_billed)
           -- MySQL equivalent using subquery:
           -- Pick top 20% cutoff
    FROM patient_totals
),
high_cost_patients AS (
    SELECT patient_id
    FROM patient_totals
    WHERE total_billed >= (
        SELECT total_billed
        FROM patient_totals
        ORDER BY total_billed DESC
        LIMIT 1 OFFSET (SELECT FLOOR(COUNT(*) * 0.2) FROM patient_totals)
    )
)
SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.insurance_type,
    d.diagnosis_name,
    COUNT(c.claim_id)                       AS claim_count,
    SUM(c.billed_amount)                    AS total_billed
FROM claims c
JOIN patients   p    ON c.patient_id   = p.patient_id
JOIN diagnoses  d    ON c.diagnosis_id = d.diagnosis_id
WHERE c.patient_id IN (SELECT patient_id FROM high_cost_patients)
GROUP BY p.patient_id, p.first_name, p.last_name, p.insurance_type, d.diagnosis_name
ORDER BY total_billed DESC;


-- ──────────────────────────────────────────────────────────────
-- Q28. Recursive-style CTE — payment gap analysis
--      (days between service date and payment date)
-- ──────────────────────────────────────────────────────────────
WITH claim_payment_gap AS (
    SELECT
        c.claim_id,
        c.service_date,
        cp.payment_date,
        DATEDIFF(cp.payment_date, c.service_date) AS days_to_payment,
        c.billed_amount,
        c.paid_amount
    FROM claims c
    JOIN claim_payments cp ON c.claim_id = cp.claim_id
),
gap_buckets AS (
    SELECT *,
        CASE
            WHEN days_to_payment <= 30  THEN '0-30 days'
            WHEN days_to_payment <= 60  THEN '31-60 days'
            WHEN days_to_payment <= 90  THEN '61-90 days'
            ELSE '90+ days'
        END AS payment_bucket
    FROM claim_payment_gap
)
SELECT
    payment_bucket,
    COUNT(*)                         AS claim_count,
    ROUND(AVG(paid_amount), 2)       AS avg_paid,
    SUM(paid_amount)                 AS total_paid
FROM gap_buckets
GROUP BY payment_bucket
ORDER BY MIN(days_to_payment);


-- ──────────────────────────────────────────────────────────────
-- Q29. Multi-CTE: denial rate by provider specialty
-- ──────────────────────────────────────────────────────────────
WITH total_claims AS (
    SELECT
        prov.specialty,
        COUNT(c.claim_id) AS total
    FROM claims c
    JOIN providers prov ON c.provider_id = prov.provider_id
    GROUP BY prov.specialty
),
denied_claims AS (
    SELECT
        prov.specialty,
        COUNT(c.claim_id) AS denied
    FROM claims c
    JOIN providers prov ON c.provider_id = prov.provider_id
    WHERE c.claim_status = 'Denied'
    GROUP BY prov.specialty
)
SELECT
    t.specialty,
    t.total           AS total_claims,
    COALESCE(d.denied, 0) AS denied_claims,
    ROUND(COALESCE(d.denied, 0) * 100.0 / t.total, 2) AS denial_rate_pct
FROM total_claims t
LEFT JOIN denied_claims d ON t.specialty = d.specialty
ORDER BY denial_rate_pct DESC;


-- ══════════════════════════════════════════════════════════════
--  SECTION 8: VIEWS
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q30. CREATE VIEW — Claims summary dashboard view
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_claims_dashboard AS
SELECT
    c.claim_id,
    DATE_FORMAT(c.claim_date, '%Y-%m')       AS claim_month,
    CONCAT(p.first_name,' ',p.last_name)     AS patient_name,
    TIMESTAMPDIFF(YEAR,p.date_of_birth,CURDATE()) AS patient_age,
    p.gender,
    p.insurance_type,
    p.state                                  AS patient_state,
    prov.provider_name,
    prov.specialty,
    prov.hospital_name,
    d.diagnosis_name,
    d.category                               AS diagnosis_category,
    d.chronic_flag,
    pr.procedure_name,
    pr.category                              AS procedure_category,
    c.admission_type,
    c.claim_status,
    c.billed_amount,
    c.allowed_amount,
    c.paid_amount,
    ROUND(COALESCE(c.paid_amount,0) / NULLIF(c.billed_amount,0) * 100, 2) AS collection_rate,
    c.length_of_stay,
    c.readmission_flag,
    c.denial_reason
FROM claims c
JOIN patients   p    ON c.patient_id   = p.patient_id
JOIN providers  prov ON c.provider_id  = prov.provider_id
JOIN diagnoses  d    ON c.diagnosis_id = d.diagnosis_id
JOIN procedures pr   ON c.procedure_id = pr.procedure_id;


-- ──────────────────────────────────────────────────────────────
-- Q31. CREATE VIEW — Provider performance metrics view
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_provider_performance AS
SELECT
    prov.provider_id,
    prov.provider_name,
    prov.specialty,
    prov.hospital_name,
    prov.state,
    COUNT(c.claim_id)                          AS total_claims,
    SUM(c.billed_amount)                       AS total_billed,
    SUM(c.paid_amount)                         AS total_paid,
    ROUND(AVG(c.billed_amount), 2)             AS avg_claim_value,
    SUM(CASE WHEN c.claim_status = 'Approved' THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN c.claim_status = 'Denied'   THEN 1 ELSE 0 END) AS denied,
    ROUND(
        SUM(CASE WHEN c.claim_status='Denied' THEN 1 ELSE 0 END)*100.0/COUNT(*),2
    ) AS denial_rate_pct,
    ROUND(AVG(c.length_of_stay), 1)            AS avg_los,
    SUM(c.readmission_flag)                    AS total_readmissions
FROM claims c
JOIN providers prov ON c.provider_id = prov.provider_id
GROUP BY prov.provider_id, prov.provider_name, prov.specialty,
         prov.hospital_name, prov.state;


-- ══════════════════════════════════════════════════════════════
--  SECTION 9: STORED PROCEDURES & FUNCTIONS
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q32. Stored Procedure — Get patient claim history
-- ──────────────────────────────────────────────────────────────
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_patient_claim_history$$
CREATE PROCEDURE sp_patient_claim_history(IN p_patient_id INT)
BEGIN
    SELECT
        c.claim_id,
        c.claim_date,
        c.claim_status,
        d.diagnosis_name,
        pr.procedure_name,
        c.billed_amount,
        c.paid_amount,
        c.length_of_stay
    FROM claims c
    JOIN diagnoses  d  ON c.diagnosis_id = d.diagnosis_id
    JOIN procedures pr ON c.procedure_id = pr.procedure_id
    WHERE c.patient_id = p_patient_id
    ORDER BY c.claim_date DESC;
END$$

-- ──────────────────────────────────────────────────────────────
-- Q33. Stored Procedure — Denial rate report by date range
-- ──────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_denial_rate_report$$
CREATE PROCEDURE sp_denial_rate_report(
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    SELECT
        prov.specialty,
        COUNT(c.claim_id) AS total_claims,
        SUM(CASE WHEN c.claim_status = 'Denied' THEN 1 ELSE 0 END) AS denied,
        ROUND(
            SUM(CASE WHEN c.claim_status = 'Denied' THEN 1 ELSE 0 END) * 100.0
            / COUNT(c.claim_id), 2
        ) AS denial_rate_pct
    FROM claims c
    JOIN providers prov ON c.provider_id = prov.provider_id
    WHERE c.claim_date BETWEEN p_start_date AND p_end_date
    GROUP BY prov.specialty
    ORDER BY denial_rate_pct DESC;
END$$

-- ──────────────────────────────────────────────────────────────
-- Q34. User-defined FUNCTION — Calculate patient age
-- ──────────────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS fn_patient_age$$
CREATE FUNCTION fn_patient_age(p_dob DATE)
RETURNS INT DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, p_dob, CURDATE());
END$$

DELIMITER ;

-- Use the function:
SELECT
    patient_id,
    CONCAT(first_name, ' ', last_name) AS patient_name,
    fn_patient_age(date_of_birth)      AS current_age
FROM patients
LIMIT 10;


-- ══════════════════════════════════════════════════════════════
--  SECTION 10: ADVANCED ANALYTICS
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q35. Fraud detection: Claims with billed amount 2x above specialty average
-- ──────────────────────────────────────────────────────────────
WITH specialty_avg AS (
    SELECT
        prov.specialty,
        AVG(c.billed_amount) AS avg_billed
    FROM claims c
    JOIN providers prov ON c.provider_id = prov.provider_id
    GROUP BY prov.specialty
)
SELECT
    c.claim_id,
    prov.provider_name,
    prov.specialty,
    c.billed_amount,
    sa.avg_billed,
    ROUND(c.billed_amount / sa.avg_billed, 2) AS ratio_to_avg,
    'Potential Fraud Flag' AS flag
FROM claims c
JOIN providers prov ON c.provider_id  = prov.provider_id
JOIN specialty_avg sa ON prov.specialty = sa.specialty
WHERE c.billed_amount >= sa.avg_billed * 2
ORDER BY ratio_to_avg DESC;


-- ──────────────────────────────────────────────────────────────
-- Q36. Patient readmission analysis — gap between discharges
-- ──────────────────────────────────────────────────────────────
SELECT
    c1.patient_id,
    CONCAT(p.first_name,' ',p.last_name)    AS patient_name,
    c1.discharge_date                        AS first_discharge,
    c2.service_date                          AS readmit_date,
    DATEDIFF(c2.service_date, c1.discharge_date) AS days_between_admits,
    d1.diagnosis_name                        AS first_diagnosis,
    d2.diagnosis_name                        AS readmit_diagnosis
FROM claims c1
JOIN claims   c2 ON c1.patient_id = c2.patient_id
                 AND c2.service_date > c1.discharge_date
                 AND DATEDIFF(c2.service_date, c1.discharge_date) <= 30
JOIN patients p  ON c1.patient_id = p.patient_id
JOIN diagnoses d1 ON c1.diagnosis_id = d1.diagnosis_id
JOIN diagnoses d2 ON c2.diagnosis_id = d2.diagnosis_id
WHERE c1.discharge_date IS NOT NULL
ORDER BY days_between_admits;


-- ──────────────────────────────────────────────────────────────
-- Q37. Cost efficiency ratio: paid vs billed by insurance type
-- ──────────────────────────────────────────────────────────────
SELECT
    p.insurance_type,
    COUNT(c.claim_id)                               AS total_claims,
    ROUND(SUM(c.billed_amount), 2)                  AS total_billed,
    ROUND(SUM(c.paid_amount), 2)                    AS total_paid,
    ROUND(AVG(c.billed_amount), 2)                  AS avg_billed,
    ROUND(AVG(c.paid_amount), 2)                    AS avg_paid,
    ROUND(SUM(c.billed_amount) - SUM(c.paid_amount), 2) AS write_off_amount,
    ROUND(
        (SUM(c.billed_amount) - SUM(COALESCE(c.paid_amount,0)))
        / SUM(c.billed_amount) * 100, 2
    ) AS write_off_pct
FROM claims c
JOIN patients p ON c.patient_id = p.patient_id
GROUP BY p.insurance_type;


-- ──────────────────────────────────────────────────────────────
-- Q38. Pivot-style: Claim status counts by admission type (CASE WHEN pivot)
-- ──────────────────────────────────────────────────────────────
SELECT
    admission_type,
    COUNT(*) AS total,
    SUM(CASE WHEN claim_status = 'Approved'     THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN claim_status = 'Denied'       THEN 1 ELSE 0 END) AS denied,
    SUM(CASE WHEN claim_status = 'Pending'      THEN 1 ELSE 0 END) AS pending,
    SUM(CASE WHEN claim_status = 'Under Review' THEN 1 ELSE 0 END) AS under_review,
    ROUND(SUM(CASE WHEN claim_status='Denied' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS denial_pct
FROM claims
GROUP BY admission_type
ORDER BY total DESC;


-- ──────────────────────────────────────────────────────────────
-- Q39. Length of stay analysis: avg by diagnosis category
-- ──────────────────────────────────────────────────────────────
SELECT
    d.category,
    d.chronic_flag,
    COUNT(c.claim_id)               AS total_claims,
    ROUND(AVG(c.length_of_stay),1)  AS avg_los,
    MAX(c.length_of_stay)           AS max_los,
    SUM(c.readmission_flag)         AS readmissions,
    ROUND(AVG(c.billed_amount),2)   AS avg_billed
FROM claims c
JOIN diagnoses d ON c.diagnosis_id = d.diagnosis_id
WHERE c.length_of_stay > 0
GROUP BY d.category, d.chronic_flag
ORDER BY avg_los DESC;


-- ──────────────────────────────────────────────────────────────
-- Q40. State-level performance heatmap
-- ──────────────────────────────────────────────────────────────
SELECT
    p.state,
    COUNT(c.claim_id)                    AS total_claims,
    SUM(c.billed_amount)                 AS total_billed,
    SUM(c.paid_amount)                   AS total_paid,
    ROUND(
        SUM(CASE WHEN c.claim_status='Denied' THEN 1 ELSE 0 END)*100.0/COUNT(*), 2
    )                                     AS denial_rate_pct,
    ROUND(AVG(c.length_of_stay),1)        AS avg_los,
    SUM(c.readmission_flag)               AS readmissions
FROM claims c
JOIN patients p ON c.patient_id = p.patient_id
GROUP BY p.state
ORDER BY total_billed DESC;


-- ══════════════════════════════════════════════════════════════
--  SECTION 11: INDEX & PERFORMANCE (Interview Essentials)
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q41. EXPLAIN a complex query to understand its execution plan
-- ──────────────────────────────────────────────────────────────
EXPLAIN SELECT
    prov.specialty,
    COUNT(c.claim_id) AS total_claims,
    SUM(c.billed_amount) AS total_billed
FROM claims c
JOIN providers prov ON c.provider_id = prov.provider_id
WHERE c.claim_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY prov.specialty;


-- ──────────────────────────────────────────────────────────────
-- Q42. Composite index for commonly filtered columns
-- ──────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_claims_status_date
    ON claims (claim_status, claim_date);

CREATE INDEX IF NOT EXISTS idx_claims_patient_date
    ON claims (patient_id, claim_date);


-- ──────────────────────────────────────────────────────────────
-- Q43. SHOW INDEX usage
-- ──────────────────────────────────────────────────────────────
SHOW INDEX FROM claims;


-- ══════════════════════════════════════════════════════════════
--  SECTION 12: NULL HANDLING & DATA QUALITY
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q44. Data quality check — NULLs in critical columns
-- ──────────────────────────────────────────────────────────────
SELECT
    'claims'                                        AS table_name,
    SUM(CASE WHEN paid_amount   IS NULL THEN 1 ELSE 0 END) AS null_paid_amount,
    SUM(CASE WHEN allowed_amount IS NULL THEN 1 ELSE 0 END) AS null_allowed_amount,
    SUM(CASE WHEN discharge_date IS NULL THEN 1 ELSE 0 END) AS null_discharge_date,
    SUM(CASE WHEN denial_reason  IS NULL AND claim_status='Denied' THEN 1 ELSE 0 END) AS denied_no_reason
FROM claims;


-- ──────────────────────────────────────────────────────────────
-- Q45. Replace NULLs using COALESCE / IFNULL
-- ──────────────────────────────────────────────────────────────
SELECT
    claim_id,
    billed_amount,
    COALESCE(allowed_amount, billed_amount * 0.8) AS allowed_amount_clean,
    COALESCE(paid_amount, 0)                       AS paid_amount_clean,
    IFNULL(denial_reason, 'N/A')                   AS denial_reason_clean
FROM claims
ORDER BY claim_id
LIMIT 20;


-- ══════════════════════════════════════════════════════════════
--  SECTION 13: TRANSACTIONS & DATA INTEGRITY
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q46. Transaction — Update claim status atomically
-- ──────────────────────────────────────────────────────────────
START TRANSACTION;

UPDATE claims
SET claim_status = 'Approved',
    paid_amount  = allowed_amount * 0.85
WHERE claim_id = 1
  AND claim_status = 'Pending';

INSERT INTO claim_payments (claim_id, payment_date, payment_amount, payment_method, payer_name)
SELECT
    claim_id,
    DATE_ADD(CURDATE(), INTERVAL 7 DAY),
    paid_amount,
    'EFT',
    'Blue Cross Blue Shield'
FROM claims
WHERE claim_id = 1;

COMMIT;


-- ══════════════════════════════════════════════════════════════
--  SECTION 14: BONUS ADVANCED QUERIES
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q47. Top diagnosis by revenue per insurance type
-- ──────────────────────────────────────────────────────────────
WITH ranked AS (
    SELECT
        p.insurance_type,
        d.diagnosis_name,
        SUM(c.billed_amount)    AS total_billed,
        ROW_NUMBER() OVER (
            PARTITION BY p.insurance_type
            ORDER BY SUM(c.billed_amount) DESC
        ) AS rn
    FROM claims c
    JOIN patients  p ON c.patient_id   = p.patient_id
    JOIN diagnoses d ON c.diagnosis_id = d.diagnosis_id
    GROUP BY p.insurance_type, d.diagnosis_name
)
SELECT insurance_type, diagnosis_name, total_billed
FROM ranked
WHERE rn = 1;


-- ──────────────────────────────────────────────────────────────
-- Q48. Year-over-year comparison using conditional aggregation
-- ──────────────────────────────────────────────────────────────
SELECT
    prov.specialty,
    SUM(CASE WHEN YEAR(c.claim_date) = YEAR(CURDATE())-1 THEN c.billed_amount ELSE 0 END) AS billed_prev_year,
    SUM(CASE WHEN YEAR(c.claim_date) = YEAR(CURDATE())   THEN c.billed_amount ELSE 0 END) AS billed_curr_year,
    ROUND(
        (SUM(CASE WHEN YEAR(c.claim_date)=YEAR(CURDATE())   THEN c.billed_amount ELSE 0 END)
        -SUM(CASE WHEN YEAR(c.claim_date)=YEAR(CURDATE())-1 THEN c.billed_amount ELSE 0 END))
        * 100.0
        / NULLIF(SUM(CASE WHEN YEAR(c.claim_date)=YEAR(CURDATE())-1 THEN c.billed_amount ELSE 0 END),0),
    2) AS yoy_growth_pct
FROM claims c
JOIN providers prov ON c.provider_id = prov.provider_id
GROUP BY prov.specialty
ORDER BY yoy_growth_pct DESC;


-- ──────────────────────────────────────────────────────────────
-- Q49. Cohort analysis — retention of patients by first claim year
-- ──────────────────────────────────────────────────────────────
WITH first_claim AS (
    SELECT
        patient_id,
        YEAR(MIN(claim_date)) AS cohort_year
    FROM claims
    GROUP BY patient_id
),
patient_activity AS (
    SELECT
        c.patient_id,
        fc.cohort_year,
        YEAR(c.claim_date) AS activity_year
    FROM claims c
    JOIN first_claim fc ON c.patient_id = fc.patient_id
    GROUP BY c.patient_id, fc.cohort_year, YEAR(c.claim_date)
)
SELECT
    cohort_year,
    activity_year,
    COUNT(DISTINCT patient_id) AS active_patients,
    (activity_year - cohort_year) AS year_offset
FROM patient_activity
GROUP BY cohort_year, activity_year
ORDER BY cohort_year, activity_year;


-- ──────────────────────────────────────────────────────────────
-- Q50. Ultimate KPI summary dashboard query
-- ──────────────────────────────────────────────────────────────
SELECT
    -- Volume
    COUNT(DISTINCT c.patient_id)    AS unique_patients,
    COUNT(c.claim_id)               AS total_claims,
    -- Revenue
    ROUND(SUM(c.billed_amount),2)   AS total_billed,
    ROUND(SUM(c.allowed_amount),2)  AS total_allowed,
    ROUND(SUM(c.paid_amount),2)     AS total_paid,
    ROUND(
        SUM(COALESCE(c.paid_amount,0)) / SUM(c.billed_amount) * 100, 2
    )                               AS overall_collection_rate_pct,
    -- Efficiency
    ROUND(AVG(c.length_of_stay),2)  AS avg_length_of_stay,
    ROUND(
        SUM(c.readmission_flag)*100.0/COUNT(*), 2
    )                               AS readmission_rate_pct,
    -- Quality
    ROUND(
        SUM(CASE WHEN c.claim_status='Denied' THEN 1 ELSE 0 END)*100.0/COUNT(*),2
    )                               AS denial_rate_pct,
    ROUND(
        SUM(CASE WHEN c.claim_status='Approved' THEN 1 ELSE 0 END)*100.0/COUNT(*),2
    )                               AS approval_rate_pct
FROM claims c;
