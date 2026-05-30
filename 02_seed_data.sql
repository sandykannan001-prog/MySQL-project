-- ============================================================
--  HEALTHCARE CLAIMS DATABASE - SEED DATA (1000 CLAIMS)
--  Generates realistic synthetic healthcare data
-- ============================================================

USE healthcare_claims;

-- ─────────────────────────────────────────────────────────────
-- SEED: diagnoses (ICD-10 codes)
-- ─────────────────────────────────────────────────────────────
INSERT INTO diagnoses (icd10_code, diagnosis_name, category, chronic_flag) VALUES
('E11.9',  'Type 2 Diabetes Mellitus',                    'Endocrine',          1),
('I10',    'Essential Hypertension',                       'Cardiovascular',     1),
('J18.9',  'Pneumonia, Unspecified',                       'Respiratory',        0),
('M54.5',  'Low Back Pain',                                'Musculoskeletal',    0),
('I25.10', 'Coronary Artery Disease',                      'Cardiovascular',     1),
('J44.1',  'COPD with Acute Exacerbation',                 'Respiratory',        1),
('N18.3',  'Chronic Kidney Disease Stage 3',               'Nephrology',         1),
('F32.9',  'Major Depressive Disorder',                    'Mental Health',      1),
('K21.0',  'GERD with Esophagitis',                        'Gastrointestinal',   0),
('Z00.00', 'General Adult Medical Examination',            'Preventive',         0),
('I63.9',  'Cerebral Infarction',                          'Neurology',          0),
('C34.10', 'Malignant Neoplasm of Upper Lobe Lung',        'Oncology',           0),
('S72.001','Fracture of Femoral Neck',                     'Orthopedics',        0),
('E78.5',  'Hyperlipidemia',                               'Endocrine',          1),
('J06.9',  'Acute Upper Respiratory Infection',            'Respiratory',        0),
('K35.80', 'Acute Appendicitis',                           'Gastrointestinal',   0),
('A09',    'Infectious Gastroenteritis',                   'Infectious Disease', 0),
('G43.909','Migraine Unspecified',                         'Neurology',          1),
('L40.0',  'Psoriasis Vulgaris',                           'Dermatology',        1),
('H26.9',  'Unspecified Cataract',                         'Ophthalmology',      0);

-- ─────────────────────────────────────────────────────────────
-- SEED: procedures (CPT codes)
-- ─────────────────────────────────────────────────────────────
INSERT INTO procedures (cpt_code, procedure_name, category, standard_cost) VALUES
('99213', 'Office Visit - Established Patient, Low Complexity',   'Evaluation & Management', 150.00),
('99214', 'Office Visit - Established Patient, Moderate Complexity','Evaluation & Management',225.00),
('99285', 'Emergency Department Visit - High Complexity',          'Emergency',               800.00),
('99232', 'Subsequent Hospital Care',                              'Inpatient',               300.00),
('93000', 'Electrocardiogram (ECG)',                               'Cardiology',              120.00),
('71046', 'Chest X-Ray, 2 Views',                                  'Radiology',               180.00),
('80053', 'Comprehensive Metabolic Panel',                         'Lab / Pathology',          95.00),
('85025', 'Complete Blood Count (CBC)',                            'Lab / Pathology',          55.00),
('27447', 'Total Knee Arthroplasty',                               'Surgery',               18500.00),
('47562', 'Laparoscopic Cholecystectomy',                          'Surgery',               12000.00),
('99396', 'Preventive Visit - Age 40-64',                          'Preventive',              300.00),
('90837', 'Psychotherapy 60 min',                                  'Mental Health',           200.00),
('70553', 'MRI Brain with Contrast',                               'Radiology',              2800.00),
('43239', 'Upper GI Endoscopy with Biopsy',                        'Gastroenterology',       2200.00),
('45378', 'Colonoscopy Diagnostic',                                'Gastroenterology',       3000.00),
('36415', 'Routine Venipuncture',                                  'Lab / Pathology',          30.00),
('99291', 'Critical Care - First 30-74 min',                       'Critical Care',          1200.00),
('97110', 'Therapeutic Exercise (Physical Therapy)',               'Rehabilitation',          120.00),
('92012', 'Ophthalmological Exam - Established',                   'Ophthalmology',           180.00),
('29881', 'Arthroscopy Knee with Meniscectomy',                    'Surgery',                8500.00);

-- ─────────────────────────────────────────────────────────────
-- SEED: providers (20 providers)
-- ─────────────────────────────────────────────────────────────
INSERT INTO providers (provider_name, specialty, hospital_name, state, city, npi_number, provider_type) VALUES
('Dr. Sarah Mitchell',    'Cardiology',              'St. Mary Medical Center',        'California',  'Los Angeles',    '1234567890', 'Specialist'),
('Dr. James Thornton',    'Internal Medicine',       'County General Hospital',        'Texas',       'Houston',        '1234567891', 'Physician'),
('Dr. Priya Nair',        'Endocrinology',           'Metro Health System',            'New York',    'New York City',  '1234567892', 'Specialist'),
('Dr. Robert Hayes',      'Orthopedic Surgery',      'Orthopedic Institute',           'Florida',     'Miami',          '1234567893', 'Surgeon'),
('Dr. Linda Vasquez',     'Pulmonology',             'Lakeside Medical Center',        'Illinois',    'Chicago',        '1234567894', 'Specialist'),
('Dr. Michael Chen',      'Neurology',               'University Hospital',            'Massachusetts','Boston',        '1234567895', 'Specialist'),
('Dr. Angela Brooks',     'General Practice',        'Community Health Clinic',        'Georgia',     'Atlanta',        '1234567896', 'General Practitioner'),
('Dr. Kevin Patel',       'Oncology',                'Cancer Treatment Centers',       'Pennsylvania','Philadelphia',   '1234567897', 'Specialist'),
('Dr. Rachel Kim',        'Psychiatry',              'Behavioral Health Institute',    'Washington',  'Seattle',        '1234567898', 'Specialist'),
('Dr. Thomas Wilson',     'Gastroenterology',        'Digestive Health Center',        'Ohio',        'Columbus',       '1234567899', 'Specialist'),
('Dr. Nancy Edwards',     'Emergency Medicine',      'Regional Trauma Center',         'Arizona',     'Phoenix',        '1234567900', 'Physician'),
('Dr. David Santos',      'Nephrology',              'Kidney Care Specialists',        'Michigan',    'Detroit',        '1234567901', 'Specialist'),
('Dr. Lisa Huang',        'Dermatology',             'Skin & Allergy Clinic',          'North Carolina','Charlotte',    '1234567902', 'Specialist'),
('Dr. William Turner',    'Ophthalmology',           'Eye Care Associates',            'Virginia',    'Richmond',       '1234567903', 'Specialist'),
('Dr. Maria Gonzalez',    'Obstetrics & Gynecology', 'Women''s Health Center',         'Colorado',    'Denver',         '1234567904', 'Physician'),
('Dr. Samuel Johnson',    'Physical Medicine',       'Rehabilitation Institute',       'Tennessee',   'Nashville',      '1234567905', 'Specialist'),
('Dr. Elizabeth Parker',  'Critical Care',           'Metro ICU Hospital',             'Minnesota',   'Minneapolis',    '1234567906', 'Physician'),
('Dr. Christopher Lee',   'Radiology',               'Imaging Diagnostics Center',     'Missouri',    'St. Louis',      '1234567907', 'Specialist'),
('Dr. Amanda Scott',      'General Surgery',         'Surgical Associates',            'Wisconsin',   'Milwaukee',      '1234567908', 'Surgeon'),
('Dr. Brian Murphy',      'Family Medicine',         'Family Care Physicians',         'Oregon',      'Portland',       '1234567909', 'General Practitioner');

-- ─────────────────────────────────────────────────────────────
-- STORED PROCEDURE: Generate 1000 patients + 1000 claims
-- ─────────────────────────────────────────────────────────────
DELIMITER $$

DROP PROCEDURE IF EXISTS generate_healthcare_data$$

CREATE PROCEDURE generate_healthcare_data()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE v_patient_id INT;
    DECLARE v_dob DATE;
    DECLARE v_age_offset INT;
    DECLARE v_service_date DATE;
    DECLARE v_claim_date DATE;
    DECLARE v_discharge_date DATE;
    DECLARE v_billed DECIMAL(12,2);
    DECLARE v_allowed DECIMAL(12,2);
    DECLARE v_paid DECIMAL(12,2);
    DECLARE v_los INT;
    DECLARE v_status ENUM('Approved','Denied','Pending','Under Review');
    DECLARE v_denial VARCHAR(200);
    DECLARE v_proc_cost DECIMAL(10,2);

    -- First names arrays (encoded as repeated inserts in loop)
    WHILE i <= 1000 DO

        -- ── Patient Data ──────────────────────────────────────
        SET v_age_offset = FLOOR(RAND() * 17520) + 6570; -- 18–66 years in days
        SET v_dob = DATE_SUB(CURDATE(), INTERVAL v_age_offset DAY);

        INSERT INTO patients (
            first_name, last_name, date_of_birth, gender,
            blood_group, state, city, zip_code,
            insurance_type, policy_number
        ) VALUES (
            ELT(FLOOR(RAND()*20)+1,
                'James','Mary','John','Patricia','Robert','Jennifer','Michael',
                'Linda','William','Barbara','David','Susan','Richard','Jessica',
                'Joseph','Sarah','Thomas','Karen','Charles','Lisa'),
            ELT(FLOOR(RAND()*20)+1,
                'Smith','Johnson','Williams','Brown','Jones','Garcia','Miller',
                'Davis','Wilson','Anderson','Taylor','Thomas','Jackson','White',
                'Harris','Martin','Thompson','Moore','Young','Allen'),
            v_dob,
            ELT(FLOOR(RAND()*2)+1, 'Male','Female'),
            ELT(FLOOR(RAND()*8)+1, 'A+','A-','B+','B-','AB+','AB-','O+','O-'),
            ELT(FLOOR(RAND()*10)+1,
                'California','Texas','New York','Florida','Illinois',
                'Pennsylvania','Ohio','Georgia','North Carolina','Michigan'),
            ELT(FLOOR(RAND()*10)+1,
                'Los Angeles','Houston','Chicago','Phoenix','Philadelphia',
                'San Antonio','San Diego','Dallas','San Jose','Austin'),
            LPAD(FLOOR(RAND()*89999+10000), 5, '0'),
            ELT(FLOOR(RAND()*4)+1, 'Private','Medicare','Medicaid','Self-Pay'),
            CONCAT('POL-', LPAD(i, 6, '0'))
        );

        SET v_patient_id = LAST_INSERT_ID();

        -- ── Claim Data ────────────────────────────────────────
        SET v_service_date  = DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*730) DAY);
        SET v_claim_date    = DATE_ADD(v_service_date, INTERVAL FLOOR(RAND()*15) DAY);
        SET v_los           = FLOOR(RAND()*14);  -- 0-14 days
        SET v_discharge_date = CASE WHEN v_los > 0 THEN DATE_ADD(v_service_date, INTERVAL v_los DAY) ELSE NULL END;

        -- Pull standard cost from procedures table
        SELECT standard_cost INTO v_proc_cost
        FROM procedures
        WHERE procedure_id = FLOOR(RAND()*20)+1
        LIMIT 1;

        SET v_billed  = ROUND(v_proc_cost * (1 + RAND()*0.3), 2);
        SET v_allowed = ROUND(v_billed   * (0.65 + RAND()*0.25), 2);

        -- Status & payment logic
        SET v_status = ELT(
            FIELD(FLOOR(RAND()*100),
                  -- Approved ~65%, Denied ~15%, Pending ~12%, Under Review ~8%
                  0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,
                  15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,
                  30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,
                  45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,
                  60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,
                  75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,
                  90,91,92,93,94,95,96,97,98,99),
            'Approved','Approved','Approved','Approved','Approved','Approved','Approved',
            'Approved','Approved','Approved','Approved','Approved','Approved','Approved','Approved',
            'Approved','Approved','Approved','Approved','Approved','Approved','Approved','Approved',
            'Approved','Approved','Approved','Approved','Approved','Approved','Approved',
            'Approved','Approved','Approved','Approved','Approved','Approved','Approved',
            'Approved','Approved','Approved','Approved','Approved','Approved','Approved','Approved',
            'Approved','Approved','Approved','Approved','Approved','Approved','Approved',
            'Approved','Approved','Approved','Approved','Approved','Approved','Approved','Approved',
            'Approved','Approved','Approved','Approved','Approved',
            'Denied','Denied','Denied','Denied','Denied','Denied','Denied','Denied','Denied','Denied',
            'Denied','Denied','Denied','Denied','Denied',
            'Pending','Pending','Pending','Pending','Pending','Pending','Pending','Pending','Pending','Pending','Pending','Pending',
            'Under Review','Under Review','Under Review','Under Review','Under Review',
            'Under Review','Under Review','Under Review'
        );

        SET v_denial = CASE
            WHEN v_status = 'Denied' THEN
                ELT(FLOOR(RAND()*5)+1,
                    'Not Medically Necessary',
                    'Prior Authorization Required',
                    'Service Not Covered',
                    'Duplicate Claim Submission',
                    'Exceeded Policy Limit')
            ELSE NULL
        END;

        SET v_paid = CASE
            WHEN v_status = 'Approved' THEN ROUND(v_allowed * (0.75 + RAND()*0.25), 2)
            WHEN v_status = 'Denied'   THEN 0.00
            ELSE NULL
        END;

        INSERT INTO claims (
            patient_id, provider_id, diagnosis_id, procedure_id,
            claim_date, service_date, discharge_date,
            admission_type, claim_status,
            billed_amount, allowed_amount, paid_amount,
            denial_reason, length_of_stay, readmission_flag
        ) VALUES (
            v_patient_id,
            FLOOR(RAND()*20)+1,
            FLOOR(RAND()*20)+1,
            FLOOR(RAND()*20)+1,
            v_claim_date,
            v_service_date,
            v_discharge_date,
            ELT(FLOOR(RAND()*4)+1, 'Emergency','Elective','Urgent','Newborn'),
            v_status,
            v_billed,
            v_allowed,
            v_paid,
            v_denial,
            v_los,
            FLOOR(RAND()*10) < 1   -- ~10% readmission rate
        );

        -- ── Payment record for approved claims ────────────────
        IF v_status = 'Approved' AND v_paid IS NOT NULL THEN
            INSERT INTO claim_payments (
                claim_id, payment_date, payment_amount,
                payment_method, payer_name
            ) VALUES (
                LAST_INSERT_ID(),
                DATE_ADD(v_claim_date, INTERVAL FLOOR(RAND()*30+7) DAY),
                v_paid,
                ELT(FLOOR(RAND()*4)+1, 'EFT','Check','ACH','Wire Transfer'),
                ELT(FLOOR(RAND()*5)+1,
                    'Blue Cross Blue Shield','Aetna','UnitedHealthcare',
                    'Cigna','Humana')
            );
        END IF;

        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

-- Run the data generator
CALL generate_healthcare_data();

-- Verify row counts
SELECT 'patients'       AS table_name, COUNT(*) AS row_count FROM patients
UNION ALL
SELECT 'providers',       COUNT(*) FROM providers
UNION ALL
SELECT 'diagnoses',       COUNT(*) FROM diagnoses
UNION ALL
SELECT 'procedures',      COUNT(*) FROM procedures
UNION ALL
SELECT 'claims',          COUNT(*) FROM claims
UNION ALL
SELECT 'claim_payments',  COUNT(*) FROM claim_payments;
