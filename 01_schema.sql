-- ============================================================
--  HEALTHCARE CLAIMS DATABASE - SCHEMA
--  Project: MySQL Analytics for Data Analyst Interview
--  Author: Healthcare Analytics Project
-- ============================================================

CREATE DATABASE IF NOT EXISTS healthcare_claims;
USE healthcare_claims;

-- ─────────────────────────────────────────────────────────────
-- TABLE 1: patients
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS patients (
    patient_id       INT PRIMARY KEY AUTO_INCREMENT,
    first_name       VARCHAR(50)  NOT NULL,
    last_name        VARCHAR(50)  NOT NULL,
    date_of_birth    DATE         NOT NULL,
    gender           ENUM('Male','Female','Other') NOT NULL,
    blood_group      ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-'),
    state            VARCHAR(50)  NOT NULL,
    city             VARCHAR(80)  NOT NULL,
    zip_code         VARCHAR(10),
    insurance_type   ENUM('Private','Medicare','Medicaid','Self-Pay') NOT NULL,
    policy_number    VARCHAR(20)  UNIQUE,
    created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────
-- TABLE 2: providers
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS providers (
    provider_id      INT PRIMARY KEY AUTO_INCREMENT,
    provider_name    VARCHAR(100) NOT NULL,
    specialty        VARCHAR(80)  NOT NULL,
    hospital_name    VARCHAR(120),
    state            VARCHAR(50)  NOT NULL,
    city             VARCHAR(80)  NOT NULL,
    npi_number       VARCHAR(20)  UNIQUE,
    provider_type    ENUM('Physician','Surgeon','Specialist','General Practitioner','Nurse Practitioner') NOT NULL,
    created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────
-- TABLE 3: diagnoses
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS diagnoses (
    diagnosis_id     INT PRIMARY KEY AUTO_INCREMENT,
    icd10_code       VARCHAR(10)  NOT NULL UNIQUE,
    diagnosis_name   VARCHAR(200) NOT NULL,
    category         VARCHAR(100) NOT NULL,
    chronic_flag     TINYINT(1)   DEFAULT 0
);

-- ─────────────────────────────────────────────────────────────
-- TABLE 4: procedures
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS procedures (
    procedure_id     INT PRIMARY KEY AUTO_INCREMENT,
    cpt_code         VARCHAR(10)  NOT NULL UNIQUE,
    procedure_name   VARCHAR(200) NOT NULL,
    category         VARCHAR(100) NOT NULL,
    standard_cost    DECIMAL(10,2) NOT NULL
);

-- ─────────────────────────────────────────────────────────────
-- TABLE 5: claims (CORE TABLE)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS claims (
    claim_id             INT PRIMARY KEY AUTO_INCREMENT,
    patient_id           INT          NOT NULL,
    provider_id          INT          NOT NULL,
    diagnosis_id         INT          NOT NULL,
    procedure_id         INT          NOT NULL,
    claim_date           DATE         NOT NULL,
    service_date         DATE         NOT NULL,
    discharge_date       DATE,
    admission_type       ENUM('Emergency','Elective','Urgent','Newborn') NOT NULL,
    claim_status         ENUM('Approved','Denied','Pending','Under Review') NOT NULL,
    billed_amount        DECIMAL(12,2) NOT NULL,
    allowed_amount       DECIMAL(12,2),
    paid_amount          DECIMAL(12,2),
    denial_reason        VARCHAR(200),
    length_of_stay       INT           DEFAULT 0  COMMENT 'Days',
    readmission_flag     TINYINT(1)    DEFAULT 0,
    created_at           TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id)   REFERENCES patients(patient_id),
    FOREIGN KEY (provider_id)  REFERENCES providers(provider_id),
    FOREIGN KEY (diagnosis_id) REFERENCES diagnoses(diagnosis_id),
    FOREIGN KEY (procedure_id) REFERENCES procedures(procedure_id)
);

-- ─────────────────────────────────────────────────────────────
-- TABLE 6: claim_payments
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS claim_payments (
    payment_id       INT PRIMARY KEY AUTO_INCREMENT,
    claim_id         INT          NOT NULL,
    payment_date     DATE         NOT NULL,
    payment_amount   DECIMAL(12,2) NOT NULL,
    payment_method   ENUM('EFT','Check','ACH','Wire Transfer') NOT NULL,
    payer_name       VARCHAR(100),
    FOREIGN KEY (claim_id) REFERENCES claims(claim_id)
);

-- ─────────────────────────────────────────────────────────────
-- INDEXES for performance
-- ─────────────────────────────────────────────────────────────
CREATE INDEX idx_claims_patient     ON claims(patient_id);
CREATE INDEX idx_claims_provider    ON claims(provider_id);
CREATE INDEX idx_claims_date        ON claims(claim_date);
CREATE INDEX idx_claims_status      ON claims(claim_status);
CREATE INDEX idx_claims_service     ON claims(service_date);
