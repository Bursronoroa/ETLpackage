-- DimPatient (SCD 2)
CREATE TABLE DimPatient (
    PatientKey INT PRIMARY KEY,
    Name VARCHAR(255),
    Gender VARCHAR(10),
    BloodType VARCHAR(10),
    MedicalCondition VARCHAR(255),
    StartDate DATE,
    EndDate DATE
);

-- DimDoctor (SCD 2)
CREATE TABLE DimDoctor (
    DoctorKey INT PRIMARY KEY,
    DoctorName VARCHAR(255),
    Specialization VARCHAR(255),
    StartDate DATE,
    EndDate DATE
);

-- DimHospital (SCD 1)
CREATE TABLE DimHospital (
    HospitalKey INT PRIMARY KEY,
    HospitalName VARCHAR(255),
	HospitalType VARCHAR(255)
);

-- DimInsuranceProvider (SCD 1)
CREATE TABLE DimInsuranceProvider (
    InsuranceProviderKey INT PRIMARY KEY,
    InsuranceProvider VARCHAR(255),
    CoverageLimit DECIMAL(18,2),
    Hospitalization VARCHAR(10)
);

-- DimLocation (SCD 1)
CREATE TABLE DimLocation (
    LocationKey INT PRIMARY KEY,
    City VARCHAR(255),
    Province VARCHAR(255),
	Country VARCHAR(255)
);

-- DimDate (SCD 0)
CREATE TABLE DimDate (
    DateKey  NUMBER(8) NOT NULL,
    DateValue DATE NOT NULL,
    CYear 	 NUMBER(10) NOT NULL,
    CQtr NUMBER(1) NOT NULL,
    CMonth 	 NUMBER(2) NOT NULL,
    DayNo 	NUMBER(2) NOT NULL,
    StartOfMonth  DATE NOT NULL,
    EndOfMonth   DATE NOT NULL,
    MonthName  VARCHAR2(9) NOT NULL,
    DayOfWeekName VARCHAR2(9) NOT NULL,
    CONSTRAINT PK_DimDate PRIMARY KEY ( DateKey )
);

-- FactHospitalAdmissions
CREATE TABLE FactHospitalAdmissions (
    PatientKey INT,
    DoctorKey INT,
    HospitalKey INT,
	LocationKey INT,
    InsuranceProviderKey INT,
    AdmissionDateKey INT,
    DischargeDateKey INT,
    BillingAmount DECIMAL(18,2),
    Medication VARCHAR(255),
    FOREIGN KEY (PatientKey ) REFERENCES DimPatient(PatientKey ),
    FOREIGN KEY (DoctorKey ) REFERENCES DimDoctor(DoctorKey ),
    FOREIGN KEY (HospitalKey ) REFERENCES DimHospital(HospitalKey ),
    FOREIGN KEY (LocationKey ) REFERENCES DimLocation(LocationKey ),
    FOREIGN KEY (InsuranceProviderKey ) REFERENCES DimInsuranceProvider(InsuranceProviderKey ),
    FOREIGN KEY (AdmissionDateKey) REFERENCES DimDate(DateKey),
    FOREIGN KEY (DischargeDateKey) REFERENCES DimDate(DateKey)
);

CREATE INDEX IX_FactHospitalAdmissionsPatientKey  ON FactHospitalAdmissions(PatientKey );
CREATE INDEX IX_FactHospitalAdmissionsDoctorKey  ON FactHospitalAdmissions(DoctorKey );
CREATE INDEX IX_FactHospitalAdmissionsHospitalKey  ON FactHospitalAdmissions(HospitalKey );
CREATE INDEX IX_FactHospitalAdmissionsLocationKey  ON FactHospitalAdmissions(LocationKey );
CREATE INDEX IX_FactHospitalAdmissionsInsuranceProviderKey  ON FactHospitalAdmissions(InsuranceProviderKey );
CREATE INDEX IX_FactHospitalAdmissionsAdmissionDateKey  ON FactHospitalAdmissions(AdmissionDateKey );
CREATE INDEX IX_FactHospitalAdmissionsDischargeDateKey  ON FactHospitalAdmissions(DischargeDateKey );


CREATE TABLE Patients_Stage(
    PatientID INT PRIMARY KEY,
    Name VARCHAR(255),
    Age INT,
    Gender VARCHAR(10),
    BloodType VARCHAR(10),
    MedicalCondition VARCHAR(255)
);

CREATE TABLE Doctors_Stage(
    DoctorID INT PRIMARY KEY,
    DoctorName VARCHAR(255),
    Specialization VARCHAR(255)
);

CREATE TABLE HospitalInformation_Stage (
    HospitalName VARCHAR(255),
    Location VARCHAR(255),
    Province VARCHAR(255),
    Country VARCHAR(255),
	Type VARCHAR(255)
);

CREATE TABLE InsuranceProvider_Stage (
    InsuranceProvider VARCHAR(255),
    CoverageLimit DECIMAL(18,2),
    Hospitalization VARCHAR(10)
);

CREATE TABLE HospitalAdmissions_Stage (
    Patient VARCHAR(255),
    Doctor VARCHAR(255),
    Hospital VARCHAR(255),
    Location VARCHAR(255),
    InsuranceProvider VARCHAR(255),
	AdmissionDate DATE,
	DischargeDate DATE,
    BillingAmount DECIMAL(18,2),
    Medication VARCHAR(255)
);


CREATE TABLE Patient_Preload (
    PatientKey INT PRIMARY KEY,
    Name VARCHAR(255),
    Gender VARCHAR(10),
    BloodType VARCHAR(10),
    MedicalCondition VARCHAR(255),
    StartDate DATE,
    EndDate DATE
);

CREATE TABLE Doctor_Preload (
    DoctorKey INT PRIMARY KEY,
    DoctorName VARCHAR(255),
    Specialization VARCHAR(255),
    StartDate DATE,
    EndDate DATE
);

CREATE TABLE Hospital_Preload (
    HospitalKey INT PRIMARY KEY,
    HospitalName VARCHAR(255),
	HospitalType VARCHAR(255)
);

CREATE TABLE InsuranceProvider_Preload (
	InsuranceProviderKey INT PRIMARY KEY,
    InsuranceProvider VARCHAR(255),
    CoverageLimit DECIMAL(18,2),
    Hospitalization VARCHAR(10)
);

CREATE TABLE Location_Preload (
    LocationKey INT PRIMARY KEY,
    City VARCHAR(255),
    Province VARCHAR(255),
	Country VARCHAR(255)
);

CREATE TABLE Temp_Location_Preload (
    City VARCHAR(255),
    Province VARCHAR(255),
	Country VARCHAR(255)
);

CREATE TABLE HospitalAdmissions_Preload (
    PatientKey INT,
    DoctorKey INT,
    HospitalKey INT,
    LocationKey INT,
    InsuranceProviderKey INT,
    AdmissionDateKey INT,
    DischargeDateKey INT,
    BillingAmount DECIMAL(18,2),
    Medication VARCHAR(255)
);

--DROP SEQUENCE HospitalKey;
--DROP SEQUENCE InsuranceProviderKey;
--DROP SEQUENCE LocationKey;


CREATE SEQUENCE HospitalKey START WITH 1 CACHE 10;
CREATE SEQUENCE InsuranceProviderKey START WITH 1 CACHE 10;
CREATE SEQUENCE LocationKey START WITH 1 CACHE 10;