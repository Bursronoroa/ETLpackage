ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

--DROP TABLE HospitalAdmission CASCADE CONSTRAINTS;
--DROP TABLE Doctors CASCADE CONSTRAINTS;
--DROP TABLE CInsuranceProviders CASCADE CONSTRAINTS;
--DROP TABLE Patients CASCADE CONSTRAINTS;
--DROP TABLE HospitalInformation CASCADE CONSTRAINTS;





-- Create table for Doctors
CREATE TABLE Doctors (
    DoctorID INT PRIMARY KEY,
    DoctorName VARCHAR(255),
    Specialization VARCHAR(255)
);

-- Create table for Insurance Providers
CREATE TABLE InsuranceProviders (
    InsuranceProviderID INT PRIMARY KEY,
    InsuranceProvider VARCHAR(255),
    CoverageLimit DECIMAL(18,2),
    Hospitalization VARCHAR(10),
    DoctorVisits VARCHAR(10),
    DiagnosticTests VARCHAR(10),
    PrescriptionDrugs VARCHAR(10),
    MentalHealthServices VARCHAR(10),
    Rehabilitation VARCHAR(10),
    Surgeries VARCHAR(10),
    ERVisits VARCHAR(10),
    Ambulance VARCHAR(10),
    PreventiveCare VARCHAR(10),
    Vaccinations VARCHAR(10)
);

-- Create table for Patients
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY,
    Name VARCHAR(255),
    Age INT,
    Gender VARCHAR(10),
    BloodType VARCHAR(10),
    MedicalCondition VARCHAR(255)
);

-- Create table for Hospital Information
CREATE TABLE HospitalInformation (
    HospitalID INT PRIMARY KEY,
    HospitalName VARCHAR(255),
    Location VARCHAR(255),
    Province VARCHAR(255),
    Country VARCHAR(255),
    TYPE VARCHAR(255)
);

/*
CREATE TABLE HospitalAdmission (
    AdmissionID INT PRIMARY KEY,
    Patient VARCHAR(255),
    DateOfAdmission DATE,
    Doctor VARCHAR(255),
    Hospital VARCHAR(255),
    InsuranceProvider VARCHAR(255),
    BillingAmount DECIMAL(18, 2),
    RoomNumber INT,
    AdmissionType VARCHAR(20),
    DischargeDate DATE,
    Medication VARCHAR(255),
    TestResults VARCHAR(255),
    FOREIGN KEY (Patient ) REFERENCES Patients(Name),
    FOREIGN KEY (Doctor ) REFERENCES Doctors(DoctorName ),
    FOREIGN KEY (Hospital ) REFERENCES HospitalInformation(HospitalName ),
    FOREIGN KEY (InsuranceProvider ) REFERENCES InsuranceProviders(InsuranceProvider )
);
*/


-- Create table for Hospital Admission
CREATE TABLE HospitalAdmission (
    AdmissionID INT PRIMARY KEY,
    PatientID INT,
    DateOfAdmission DATE,
    DoctorID INT,
    HospitalID INT,
    InsuranceProviderID INT,
    BillingAmount DECIMAL(18, 2),
    RoomNumber INT,
    AdmissionType VARCHAR(20),
    DischargeDate DATE,
    Medication VARCHAR(255),
    TestResults VARCHAR(255),
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
    FOREIGN KEY (HospitalID) REFERENCES HospitalInformation(HospitalID),
    FOREIGN KEY (InsuranceProviderID) REFERENCES InsuranceProviders(InsuranceProviderID)
);
