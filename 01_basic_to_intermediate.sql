-- ============================================================
--  HEALTHCARE CLAIMS - INTERVIEW QUERIES (Part 1)
--  Topics: Basic SELECT, Filtering, Aggregation, GROUP BY,
--          HAVING, JOINs, Subqueries, Date Functions
-- ============================================================

USE healthcare_claims;

-- ══════════════════════════════════════════════════════════════
--  SECTION 1: BASIC RETRIEVAL & FILTERING
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q1. Retrieve all claims submitted in the last 6 months
-- ──────────────────────────────────────────────────────────────
SELECT
    c.claim_id,
    CONCAT(p.first_name, ' ', p.last_name)  AS patient_name,
    c.claim_date,
    c.claim_status,
    c.billed_amount
FROM claims c
JOIN patients p ON c.patient_id = p.patient_id
WHERE c.claim_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
ORDER BY c.claim_date DESC;


-- ──────────────────────────────────────────────────────────────
-- Q2. Find all DENIED claims with their denial reasons
-- ──────────────────────────────────────────────────────────────
SELECT
    c.claim_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    c.claim_date,
    c.billed_amount,
    c.denial_reason
FROM claims c
JOIN patients p ON c.patient_id = p.patient_id
WHERE c.claim_status = 'Denied'
ORDER BY c.billed_amount DESC;


-- ──────────────────────────────────────────────────────────────
-- Q3. List patients with Medicare insurance who had Emergency admissions
-- ──────────────────────────────────────────────────────────────
SELECT DISTINCT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.insurance_type,
    p.state
FROM patients p
JOIN claims c ON p.patient_id = c.patient_id
WHERE p.insurance_type = 'Medicare'
  AND c.admission_type = 'Emergency';


-- ──────────────────────────────────────────────────────────────
-- Q4. Show claims where billed amount exceeds allowed amount by more than 30%
-- ──────────────────────────────────────────────────────────────
SELECT
    claim_id,
    billed_amount,
    allowed_amount,
    ROUND((billed_amount - allowed_amount) / allowed_amount * 100, 2) AS over_billed_pct
FROM claims
WHERE allowed_amount IS NOT NULL
  AND billed_amount > allowed_amount * 1.30
ORDER BY over_billed_pct DESC;


-- ──────────────────────────────────────────────────────────────
-- Q5. Find all readmission cases with patient and diagnosis details
-- ──────────────────────────────────────────────────────────────
SELECT
    c.claim_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    d.diagnosis_name,
    c.service_date,
    c.discharge_date,
    c.length_of_stay
FROM claims c
JOIN patients p  ON c.patient_id   = p.patient_id
JOIN diagnoses d ON c.diagnosis_id = d.diagnosis_id
WHERE c.readmission_flag = 1
ORDER BY c.service_date DESC;


-- ══════════════════════════════════════════════════════════════
--  SECTION 2: AGGREGATION & GROUP BY
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q6. Total claims and total billed amount per insurance type
-- ──────────────────────────────────────────────────────────────
SELECT
    p.insurance_type,
    COUNT(c.claim_id)           AS total_claims,
    SUM(c.billed_amount)        AS total_billed,
    SUM(c.paid_amount)          AS total_paid,
    ROUND(AVG(c.billed_amount), 2) AS avg_claim_amount
FROM claims c
JOIN patients p ON c.patient_id = p.patient_id
GROUP BY p.insurance_type
ORDER BY total_billed DESC;


-- ──────────────────────────────────────────────────────────────
-- Q7. Monthly claims volume and revenue trend (last 12 months)
-- ──────────────────────────────────────────────────────────────
SELECT
    DATE_FORMAT(claim_date, '%Y-%m')    AS claim_month,
    COUNT(claim_id)                     AS total_claims,
    SUM(billed_amount)                  AS total_billed,
    SUM(paid_amount)                    AS total_paid,
    ROUND(SUM(paid_amount) / SUM(billed_amount) * 100, 2) AS collection_rate_pct
FROM claims
WHERE claim_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY claim_month
ORDER BY claim_month;


-- ──────────────────────────────────────────────────────────────
-- Q8. Claim status distribution with percentage
-- ──────────────────────────────────────────────────────────────
SELECT
    claim_status,
    COUNT(*)                                          AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM claims
GROUP BY claim_status
ORDER BY count DESC;


-- ──────────────────────────────────────────────────────────────
-- Q9. Top 5 most expensive procedures by average billed amount
-- ──────────────────────────────────────────────────────────────
SELECT
    pr.procedure_name,
    pr.category,
    COUNT(c.claim_id)              AS times_performed,
    ROUND(AVG(c.billed_amount), 2) AS avg_billed,
    SUM(c.billed_amount)           AS total_billed
FROM claims c
JOIN procedures pr ON c.procedure_id = pr.procedure_id
GROUP BY pr.procedure_id, pr.procedure_name, pr.category
ORDER BY avg_billed DESC
LIMIT 5;


-- ──────────────────────────────────────────────────────────────
-- Q10. Providers with more than 30 claims — using HAVING
-- ──────────────────────────────────────────────────────────────
SELECT
    prov.provider_name,
    prov.specialty,
    prov.hospital_name,
    COUNT(c.claim_id)              AS total_claims,
    ROUND(AVG(c.billed_amount), 2) AS avg_billed_per_claim
FROM claims c
JOIN providers prov ON c.provider_id = prov.provider_id
GROUP BY prov.provider_id, prov.provider_name, prov.specialty, prov.hospital_name
HAVING total_claims > 30
ORDER BY total_claims DESC;


-- ══════════════════════════════════════════════════════════════
--  SECTION 3: JOINS (INNER, LEFT, SELF)
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q11. Full claim detail report (multi-table JOIN)
-- ──────────────────────────────────────────────────────────────
SELECT
    c.claim_id,
    CONCAT(p.first_name, ' ', p.last_name)  AS patient_name,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS patient_age,
    p.insurance_type,
    prov.provider_name,
    prov.specialty,
    d.diagnosis_name,
    d.category                               AS diagnosis_category,
    pr.procedure_name,
    c.admission_type,
    c.claim_status,
    c.billed_amount,
    c.allowed_amount,
    c.paid_amount,
    c.length_of_stay,
    c.readmission_flag
FROM claims c
JOIN patients   p    ON c.patient_id   = p.patient_id
JOIN providers  prov ON c.provider_id  = prov.provider_id
JOIN diagnoses  d    ON c.diagnosis_id = d.diagnosis_id
JOIN procedures pr   ON c.procedure_id = pr.procedure_id
ORDER BY c.claim_date DESC
LIMIT 50;


-- ──────────────────────────────────────────────────────────────
-- Q12. LEFT JOIN — patients who have never filed a claim
-- ──────────────────────────────────────────────────────────────
SELECT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.insurance_type,
    p.state
FROM patients p
LEFT JOIN claims c ON p.patient_id = c.patient_id
WHERE c.claim_id IS NULL;


-- ──────────────────────────────────────────────────────────────
-- Q13. Claims with no corresponding payment record (LEFT JOIN)
-- ──────────────────────────────────────────────────────────────
SELECT
    c.claim_id,
    c.claim_status,
    c.billed_amount,
    c.paid_amount,
    c.claim_date
FROM claims c
LEFT JOIN claim_payments cp ON c.claim_id = cp.claim_id
WHERE cp.payment_id IS NULL
  AND c.claim_status = 'Approved';


-- ══════════════════════════════════════════════════════════════
--  SECTION 4: SUBQUERIES & CORRELATED QUERIES
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q14. Patients whose total billed amount is above average
-- ──────────────────────────────────────────────────────────────
SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.insurance_type,
    SUM(c.billed_amount)                   AS total_billed
FROM patients p
JOIN claims c ON p.patient_id = c.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name, p.insurance_type
HAVING SUM(c.billed_amount) > (
    SELECT AVG(total) FROM (
        SELECT SUM(billed_amount) AS total
        FROM claims
        GROUP BY patient_id
    ) sub
)
ORDER BY total_billed DESC;


-- ──────────────────────────────────────────────────────────────
-- Q15. Most common denial reason (subquery in FROM)
-- ──────────────────────────────────────────────────────────────
SELECT
    denial_reason,
    denial_count,
    ROUND(denial_count * 100.0 / total_denied, 2) AS pct_of_denials
FROM (
    SELECT
        denial_reason,
        COUNT(*) AS denial_count
    FROM claims
    WHERE claim_status = 'Denied' AND denial_reason IS NOT NULL
    GROUP BY denial_reason
) dr
CROSS JOIN (
    SELECT COUNT(*) AS total_denied FROM claims WHERE claim_status = 'Denied'
) totals
ORDER BY denial_count DESC;


-- ──────────────────────────────────────────────────────────────
-- Q16. Providers whose average billed amount exceeds overall average
-- ──────────────────────────────────────────────────────────────
SELECT
    prov.provider_name,
    prov.specialty,
    ROUND(AVG(c.billed_amount), 2)  AS avg_billed,
    (SELECT ROUND(AVG(billed_amount), 2) FROM claims) AS overall_avg
FROM claims c
JOIN providers prov ON c.provider_id = prov.provider_id
GROUP BY prov.provider_id, prov.provider_name, prov.specialty
HAVING avg_billed > (SELECT AVG(billed_amount) FROM claims)
ORDER BY avg_billed DESC;


-- ──────────────────────────────────────────────────────────────
-- Q17. Chronic condition patients with multiple claims (EXISTS)
-- ──────────────────────────────────────────────────────────────
SELECT DISTINCT
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.insurance_type,
    d.diagnosis_name
FROM patients p
JOIN claims c    ON p.patient_id   = c.patient_id
JOIN diagnoses d ON c.diagnosis_id = d.diagnosis_id
WHERE d.chronic_flag = 1
  AND EXISTS (
      SELECT 1 FROM claims c2
      WHERE c2.patient_id = p.patient_id
      GROUP BY c2.patient_id
      HAVING COUNT(*) > 2
  );


-- ══════════════════════════════════════════════════════════════
--  SECTION 5: DATE & STRING FUNCTIONS
-- ══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- Q18. Patient age groups and their claim counts
-- ──────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) BETWEEN 18 AND 30 THEN '18-30'
        WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) BETWEEN 31 AND 45 THEN '31-45'
        WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) BETWEEN 46 AND 60 THEN '46-60'
        WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) BETWEEN 61 AND 75 THEN '61-75'
        ELSE '75+'
    END                         AS age_group,
    COUNT(c.claim_id)           AS total_claims,
    SUM(c.billed_amount)        AS total_billed,
    ROUND(AVG(c.billed_amount), 2) AS avg_billed
FROM patients p
JOIN claims c ON p.patient_id = c.patient_id
GROUP BY age_group
ORDER BY MIN(TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()));


-- ──────────────────────────────────────────────────────────────
-- Q19. Average days from service date to claim submission (TAT)
-- ──────────────────────────────────────────────────────────────
SELECT
    prov.specialty,
    ROUND(AVG(DATEDIFF(c.claim_date, c.service_date)), 1) AS avg_days_to_submit,
    MIN(DATEDIFF(c.claim_date, c.service_date))           AS min_days,
    MAX(DATEDIFF(c.claim_date, c.service_date))           AS max_days
FROM claims c
JOIN providers prov ON c.provider_id = prov.provider_id
GROUP BY prov.specialty
ORDER BY avg_days_to_submit DESC;


-- ──────────────────────────────────────────────────────────────
-- Q20. Quarter-wise billing summary
-- ──────────────────────────────────────────────────────────────
SELECT
    YEAR(claim_date)    AS claim_year,
    QUARTER(claim_date) AS claim_quarter,
    COUNT(*)            AS total_claims,
    SUM(billed_amount)  AS total_billed,
    SUM(paid_amount)    AS total_paid
FROM claims
GROUP BY claim_year, claim_quarter
ORDER BY claim_year, claim_quarter;
