--extract

CREATE OR REPLACE PROCEDURE Patients_Extract
IS
    RowCt NUMBER(10):=0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE Patients_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    INSERT INTO Patients_Stage
    SELECT p.patientid,
    p.name,
    p.age,
    p.gender,
    p.bloodtype,
    p.medicalcondition
    FROM group6.patients p;

    RowCt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Number of patients added: ' || TO_CHAR(SQL%ROWCOUNT));
END;
/
/*
TRUNCATE TABLE Patients_Stage;
EXECUTE Patients_Extract;
SELECT * FROM Patients_Stage;
*/


CREATE OR REPLACE PROCEDURE Doctors_Extract
IS
    RowCt NUMBER(10):=0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE Doctors_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    INSERT INTO Doctors_Stage
    SELECT d.DoctorID,
    d.doctorname,
    d.specialization
    FROM group6.doctors d;

    RowCt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Number of doctors added: ' || TO_CHAR(SQL%ROWCOUNT));
END;
/

/*
TRUNCATE TABLE Doctors_Stage;
EXECUTE Doctors_Extract;
SELECT * FROM Doctors_Stage;
*/


CREATE OR REPLACE PROCEDURE HospitalInformation_Extract AS
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE HospitalInformation_Stage';

    INSERT INTO hospitalinformation_stage (hospitalname, location, province, country, type)
    SELECT hospitalname, location, province, country, type
    FROM group6.hospitalinformation;

    dbms_output.put_line(SQL%ROWCOUNT || ' rows inserted into HospitalInformation_Stage.');

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error encountered: ' || SQLERRM);
END;
/

/*
TRUNCATE TABLE HospitalInformation_Stage;
EXECUTE HospitalInformation_Extract;
SELECT * FROM HospitalInformation_Stage;
*/

CREATE OR REPLACE PROCEDURE InsuranceProvider_Extract AS
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE InsuranceProvider_Stage';

    INSERT INTO InsuranceProvider_stage (insuranceprovider, coveragelimit, hospitalization)
    SELECT insuranceprovider, coveragelimit, hospitalization
    FROM group6.insuranceproviders;

    dbms_output.put_line(SQL%ROWCOUNT || ' rows inserted into InsuranceProvider_stage.');

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error encountered: ' || SQLERRM);
END;
/

/*
TRUNCATE TABLE InsuranceProvider_Stage;
EXECUTE InsuranceProvider_Extract;
SELECT * FROM InsuranceProvider_Stage;
*/

CREATE OR REPLACE PROCEDURE HospitalAdmissions_Extract
AS
    RowCt NUMBER(10);
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE HospitalAdmissions_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    INSERT INTO HospitalAdmissions_Stage (Patient, Doctor, Hospital, Location, InsuranceProvider, AdmissionDate, DischargeDate, BillingAmount, Medication)
    SELECT
        P.name AS Patient,
        D.doctorname AS Doctor,
        HI.hospitalname AS Hospital,
        HI.Location AS Location,
        IP.InsuranceProvider AS InsuranceProvider,
        HA.DateOfAdmission AS AdmissionDate,
        HA.DischargeDate AS DischargeDate,
        HA.BillingAmount AS BillingAmount,
        HA.Medication AS Medication
    FROM group6.HospitalAdmission HA
    JOIN group6.Patients P ON HA.PatientID = P.PatientID
    JOIN group6.Doctors D ON HA.DoctorID = D.DoctorID
    JOIN group6.HospitalInformation HI ON HA.HospitalID = HI.HospitalID
    JOIN group6.InsuranceProviders IP ON HA.InsuranceProviderID = IP.InsuranceProviderID;


EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;
/

/*
TRUNCATE TABLE HospitalAdmissions_Stage;
EXECUTE HospitalAdmissions_Extract;
SELECT * FROM HospitalAdmissions_Stage;
*/

--transform

CREATE OR REPLACE PROCEDURE Patients_Transform
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Patient_Preload DROP STORAGE';
  StartDate DATE := SYSDATE;
  EndDate DATE := SYSDATE - 1;
BEGIN
    EXECUTE IMMEDIATE v_sql;
--BEGIN TRANSACTION;
-- Add updated records
    INSERT INTO Patient_Preload /* Column list excluded for brevity */
    SELECT stg.patientid,
           stg.name,
           stg.Gender,
           stg.BloodType,
           stg.MedicalCondition,
           StartDate,
           NULL
    FROM Patients_Stage stg
    JOIN DimPatient pt
        ON stg.Name = pt.Name AND pt.EndDate IS NULL
    WHERE stg.Gender <> pt.Gender
          OR stg.BloodType <> pt.BloodType
          OR stg.MedicalCondition <> pt.MedicalCondition;

    -- Add existing records, and expire as necessary
    INSERT INTO Patient_Preload /* Column list excluded for brevity */
    SELECT pt.PatientKey,
           pt.Name,
           pt.Gender,
           pt.BloodType,
           pt.MedicalCondition,
           pt.StartDate,
           CASE
               WHEN pl.Name IS NULL THEN NULL
               ELSE pt.EndDate
           END AS EndDate
    FROM DimPatient pt
    LEFT JOIN Patient_Preload pl
        ON pl.Name = pt.Name
        AND pt.EndDate IS NULL;
-- Create new records
    INSERT INTO Patient_Preload /* Column list excluded for brevity */
    SELECT stg.patientid,
           stg.name,
           stg.Gender,
           stg.BloodType,
           stg.MedicalCondition,
           StartDate,
           NULL
    FROM Patients_Stage stg
    WHERE NOT EXISTS ( SELECT 1 FROM DimPatient pt WHERE stg.Name = pt.Name );
    -- Expire missing records
    INSERT INTO Patient_Preload /* Column list excluded for brevity */
    SELECT pt.PatientKey,
           pt.Name,
           pt.Gender,
           pt.BloodType,
           pt.MedicalCondition,
           pt.StartDate,
           EndDate
    FROM DimPatient pt
    WHERE NOT EXISTS ( SELECT 1 FROM Patients_Stage stg WHERE stg.Name = pt.Name )
          AND pt.EndDate IS NULL;

    RowCt := SQL%ROWCOUNT;
    dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
--COMMIT TRANSACTION;
  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;
/

/*
TRUNCATE TABLE patient_preload;
EXECUTE Patients_Transform;
SELECT * FROM patient_preload;
select count(*) from patient_preload;
*/

CREATE OR REPLACE PROCEDURE Doctors_Transform
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Doctor_Preload DROP STORAGE';
  StartDate DATE := SYSDATE;
  EndDate DATE := SYSDATE - 1;
BEGIN
    EXECUTE IMMEDIATE v_sql;
--BEGIN TRANSACTION;
-- Add updated records
    INSERT INTO Doctor_Preload /* Column list excluded for brevity */
    SELECT stg.doctorid,
           stg.doctorname,
           stg.specialization,
           StartDate,
           NULL
    FROM Doctors_Stage stg
    JOIN DimDoctor dr
        ON stg.DoctorName = dr.DoctorName AND dr.EndDate IS NULL
    WHERE stg.specialization <> dr.specialization;

    -- Add existing records, and expire as necessary
    INSERT INTO Doctor_Preload /* Column list excluded for brevity */
    SELECT dr.DoctorKey,
           dr.DoctorName,
           dr.Specialization,
           dr.StartDate,
           CASE
               WHEN dl.DoctorName IS NULL THEN NULL
               ELSE dr.EndDate
           END AS EndDate
    FROM DimDoctor dr
    LEFT JOIN Doctor_Preload dl
        ON dl.DoctorName = dr.DoctorName
        AND dr.EndDate IS NULL;
-- Create new records
    INSERT INTO Doctor_Preload /* Column list excluded for brevity */
    SELECT stg.DoctorId,
           stg.DoctorName,
           stg.Specialization,
           StartDate,
           NULL
    FROM Doctors_Stage stg
    WHERE NOT EXISTS ( SELECT 1 FROM DimDoctor dr WHERE stg.DoctorName = dr.DoctorName );
    -- Expire missing records
    INSERT INTO Doctor_Preload /* Column list excluded for brevity */
    SELECT dr.DoctorKey,
           dr.DoctorName,
           dr.Specialization,
           dr.StartDate,
           EndDate
    FROM DimDoctor dr
    WHERE NOT EXISTS ( SELECT 1 FROM Doctors_Stage stg WHERE stg.DoctorName = dr.DoctorName )
          AND dr.EndDate IS NULL;

    RowCt := SQL%ROWCOUNT;
    dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
--COMMIT TRANSACTION;
  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;
/

/*
TRUNCATE TABLE doctor_preload;
EXECUTE Doctors_Transform;
SELECT * FROM doctor_preload;
select count(*) from doctor_preload;
*/


CREATE OR REPLACE PROCEDURE hospital_Transform --Type 1 SCD
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE hospital_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
--BEGIN TRANSACTION;
    INSERT INTO hospital_Preload /* Column list excluded for brevity */
    SELECT HospitalKey.NEXTVAL AS HospitalKey,
           his.hospitalname,
           his.type
    FROM hospitalinformation_stage his
    WHERE NOT EXISTS
	( SELECT 1
              FROM dimhospital dh
              WHERE his.hospitalname = dh.hospitalname
                AND his.type = dh.hospitaltype
        );

    INSERT INTO hospital_Preload /* Column list excluded for brevity */
    SELECT dh.hospitalkey,
           his.hospitalname,
           his.type
    FROM hospitalinformation_stage his
    JOIN dimhospital dh
        ON his.hospitalname = dh.hospitalname
        AND his.type = dh.hospitaltype;
--COMMIT TRANSACTION;
    RowCt := SQL%ROWCOUNT;
    IF SQL%ROWCOUNT = 0 THEN
       dbms_output.put_line('No records found. Check with source system.');
    ELSIF SQL%ROWCOUNT > 0 THEN
       dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;
/

/*
TRUNCATE TABLE hospital_preload;
EXECUTE hospital_transform;
SELECT * FROM hospital_preload;
select count(*) from hospital_preload;
*/

CREATE OR REPLACE PROCEDURE InsuranceProvider_Transform --Type 1 SCD
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE InsuranceProvider_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
--BEGIN TRANSACTION;
    INSERT INTO InsuranceProvider_Preload /* Column list excluded for brevity */
    SELECT InsuranceProviderKey.NEXTVAL AS InsuranceProviderKey,
           ips.insuranceprovider,
           ips.coveragelimit,
           ips.hospitalization
    FROM InsuranceProvider_stage ips
    WHERE NOT EXISTS
	( SELECT 1
              FROM diminsuranceprovider dip
              WHERE ips.insuranceprovider = dip.insuranceprovider
                AND ips.coveragelimit = dip.coveragelimit
                AND ips.hospitalization = dip.hospitalization
        );

    INSERT INTO InsuranceProvider_Preload /* Column list excluded for brevity */
    SELECT dip.InsuranceProviderKey,
           ips.insuranceprovider,
           ips.coveragelimit,
           ips.hospitalization
    FROM InsuranceProvider_stage ips
    JOIN diminsuranceprovider dip
        ON ips.insuranceprovider = dip.insuranceprovider
        AND ips.coveragelimit = dip.coveragelimit
        AND ips.hospitalization = dip.hospitalization;
--COMMIT TRANSACTION;
    RowCt := SQL%ROWCOUNT;
    IF SQL%ROWCOUNT = 0 THEN
       dbms_output.put_line('No records found. Check with source system.');
    ELSIF SQL%ROWCOUNT > 0 THEN
       dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;
/

/*
TRUNCATE TABLE insuranceprovider_preload;
EXECUTE insuranceprovider_transform;
SELECT * FROM insuranceprovider_preload;
*/


CREATE OR REPLACE PROCEDURE location_transform --Type 1 SCD
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Location_Preload DROP STORAGE';
  v_sql1 VARCHAR(255) := 'TRUNCATE TABLE Temp_Location_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    EXECUTE IMMEDIATE v_sql1;
    INSERT INTO Temp_Location_Preload
    SELECT cu.location,
           cu.province,
           cu.country
    FROM hospitalinformation_stage cu
    WHERE NOT EXISTS
    ( SELECT 1
              FROM DimLocation loc
              WHERE cu.location = loc.city
                AND cu.province = loc.province
                AND cu.country = loc.country
        );
    INSERT INTO Location_Preload
    WITH DistinctRows AS (
    SELECT DISTINCT CITY,PROVINCE,COUNTRY FROM Temp_Location_Preload)
    SELECT LocationKey.NEXTVAL as LocationKey,
    dr.CITY,dr.PROVINCE,
    dr.COUNTRY FROM DistinctRows dr;

    INSERT INTO Location_Preload /* Column list excluded for brevity */
    SELECT loc.LocationkEY,
           cu.location,
           cu.province,
           cu.country
    FROM hospitalinformation_stage cu
    JOIN DimLocation loc
        ON cu.location = loc.city
                AND cu.province = loc.province
                AND cu.country = loc.country
                ;
    RowCt := SQL%ROWCOUNT;
  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;
/

/*
TRUNCATE TABLE location_preload;
TRUNCATE TABLE Temp_Location_Preload;
EXECUTE location_transform;
SELECT * FROM location_preload;
select count(*) from location_preload;
*/

CREATE OR REPLACE PROCEDURE HospitalAdmissions_Transform
AS
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE HospitalAdmissions_Preload';

    INSERT INTO HospitalAdmissions_Preload (
        PatientKey, DoctorKey, HospitalKey, LocationKey,
        InsuranceProviderKey, AdmissionDateKey, DischargeDateKey,
        BillingAmount, Medication
    )
    SELECT
        MIN(PP.PatientKey) AS PatientKey,
        MIN(DP.DoctorKey) AS DoctorKey,
        HP.HospitalKey,
        LP.LocationKey,
        IPP.InsuranceProviderKey,
        EXTRACT(YEAR FROM HAS.admissiondate)*10000 + EXTRACT(MONTH FROM HAS.admissiondate)*100 + EXTRACT(DAY FROM HAS.admissiondate) AS AdmissionDateKey,
        EXTRACT(YEAR FROM HAS.dischargedate)*10000 + EXTRACT(MONTH FROM HAS.dischargedate)*100 + EXTRACT(DAY FROM HAS.dischargedate) AS DischargeDateKey,
        HAS.BillingAmount,
        HAS.Medication
    FROM HospitalAdmissions_Stage HAS
    LEFT JOIN Patient_Preload PP ON HAS.Patient = PP.Name
    LEFT JOIN Doctor_Preload DP ON HAS.Doctor = DP.DoctorName
    LEFT JOIN Hospital_Preload HP ON HAS.Hospital = HP.HospitalName
    LEFT JOIN Location_Preload LP ON HAS.Location = LP.City
    LEFT JOIN InsuranceProvider_Preload IPP ON HAS.InsuranceProvider = IPP.InsuranceProvider
    GROUP BY
        HAS.AdmissionDate, HAS.DischargeDate, HAS.BillingAmount, HAS.Medication,
        HP.HospitalKey, LP.LocationKey, IPP.InsuranceProviderKey;
END;
/



/*
TRUNCATE TABLE HospitalAdmissions_Preload;
EXECUTE HospitalAdmissions_Transform;
SELECT * FROM HospitalAdmissions_Preload;
select count(*) from HospitalAdmissions_Preload;
*/



--load

CREATE OR REPLACE PROCEDURE DimDate_Load ( DateValue IN DATE )
IS
BEGIN
 INSERT INTO DimDate
SELECT
    EXTRACT(YEAR FROM DateValue) * 10000 + EXTRACT(Month FROM DateValue) * 100 + EXTRACT(Day FROM DateValue) DateKey
    ,DateValue DateValue
    ,EXTRACT(YEAR FROM DateValue) CYear
    ,CAST(TO_CHAR(DateValue, 'Q') AS INT) CQtr
    ,EXTRACT(Month FROM DateValue) CMonth
    ,EXTRACT(Day FROM DateValue) "Day"
    ,TRUNC(DateValue) - (TO_NUMBER (TO_CHAR(DateValue,'DD')) - 1) StartOfMonth
    ,ADD_Months(TRUNC(DateValue) - (TO_NUMBER(TO_CHAR(DateValue,'DD')) - 1), 1) -1 EndOfMonth
    ,TO_CHAR(DateValue, 'MONTH') MonthName
    ,TO_CHAR(DateValue, 'DY') DayOfWeekName
FROM dual;
END;
/

CREATE OR REPLACE PROCEDURE Populate_DimDate_From_2018
IS
    v_StartDate DATE := TO_DATE('01-JAN-2018', 'DD-MON-YYYY');
    v_EndDate DATE := ADD_MONTHS(v_StartDate, 12 * 6);
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dimdate';
    WHILE v_StartDate < v_EndDate LOOP
        DimDate_Load(v_StartDate);
        v_StartDate := v_StartDate + 1;
    END LOOP;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;
/

/*
TRUNCATE TABLE dimdate;
EXECUTE populate_dimdate_from_2018;
Select * from dimdate;
select count(*) from dimdate;
*/

CREATE OR REPLACE PROCEDURE patients_load
AS
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE Dimpatient';
    BEGIN
    DELETE FROM Dimpatient  WHERE EXISTS (
            SELECT 1 FROM patient_preload
            WHERE Dimpatient.PatientKey = patient_preload.PatientKey
        );

    INSERT INTO Dimpatient
    SELECT * FROM patient_preload;

    COMMIT;
    EXCEPTION
        WHEN others THEN
            ROLLBACK;
            RAISE;
    END;
END;
/

/*
TRUNCATE TABLE dimpatient;
EXECUTE patients_load;
Select * from dimpatient;
select count(*) from dimpatient;
*/

CREATE OR REPLACE PROCEDURE doctor_load
AS
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE Dimdoctor';
    BEGIN
    DELETE FROM Dimdoctor  WHERE EXISTS (
            SELECT 1 FROM doctor_preload
            WHERE Dimdoctor.DoctorKey = doctor_preload.DoctorKey
        );

    INSERT INTO Dimdoctor
    SELECT * FROM doctor_preload;

    COMMIT;
    EXCEPTION
        WHEN others THEN
            ROLLBACK;
            RAISE;
    END;

END;
/

/*
TRUNCATE TABLE Dimdoctor;
EXECUTE doctor_load;
Select * from Dimdoctor;
select count(*) from Dimdoctor;
*/

CREATE OR REPLACE PROCEDURE Hospital_Load AS
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dimhospital';
    UPDATE dimhospital d
    SET (d.hospitalname, d.hospitaltype) =
        (SELECT p.hospitalname, p.hospitaltype
         FROM hospital_preload p
         WHERE p.hospitalkey = d.hospitalkey)
    WHERE EXISTS (
        SELECT 1
        FROM hospital_preload p
        WHERE p.hospitalkey = d.hospitalkey
    );


    INSERT INTO dimhospital
    SELECT *
    FROM hospital_preload p
    WHERE NOT EXISTS (
        SELECT 1
         FROM dimhospital d
        WHERE d.hospitalkey = p.hospitalkey
    );

    dbms_output.put_line('Hospitals updated: ' || SQL%ROWCOUNT);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('An error occurred: ' || SQLERRM);
END;
/

/*
TRUNCATE TABLE dimhospital;
EXECUTE Hospital_Load;
Select * from dimhospital;
select count(*) from dimhospital;
*/


CREATE OR REPLACE PROCEDURE InsuranceProvider_Load AS
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE diminsuranceprovider';
    UPDATE diminsuranceprovider d
    SET (d.insuranceprovider, d.coveragelimit, d.hospitalization) =
        (SELECT p.insuranceprovider, p.coveragelimit, p.hospitalization
         FROM insuranceprovider_preload p
         WHERE p.insuranceproviderkey = d.insuranceproviderkey)
    WHERE EXISTS (
        SELECT 1
        FROM insuranceprovider_preload p
        WHERE p.insuranceproviderkey = d.insuranceproviderkey
    );


    INSERT INTO diminsuranceprovider
    SELECT *
    FROM insuranceprovider_preload p
    WHERE NOT EXISTS (
        SELECT 1
         FROM diminsuranceprovider d
        WHERE d.insuranceproviderkey = p.insuranceproviderkey
    );

    dbms_output.put_line('Hospitals updated: ' || SQL%ROWCOUNT);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('An error occurred: ' || SQLERRM);
END;
/

/*
TRUNCATE TABLE diminsuranceprovider;
EXECUTE InsuranceProvider_Load;
Select * from diminsuranceprovider;
select count(*) from diminsuranceprovider;
*/

CREATE OR REPLACE PROCEDURE Location_Load AS
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimLocation';

    UPDATE DimLocation d
    SET (d.City, d.Province, d.Country) =
        (SELECT p.City, p.Province, p.Country
         FROM Location_Preload p
         WHERE p.LocationKey = d.LocationKey)
    WHERE EXISTS (
        SELECT 1
        FROM Location_Preload p
        WHERE p.LocationKey = d.LocationKey
    );

    INSERT INTO DimLocation (LocationKey, City, Province, Country)
    SELECT p.LocationKey, p.City, p.Province, p.Country
    FROM Location_Preload p
    WHERE NOT EXISTS (
        SELECT 1
        FROM DimLocation d
        WHERE d.LocationKey = p.LocationKey
    );

    dbms_output.put_line('Locations loaded.');

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('An error occurred in Location_Load: ' || SQLERRM);
END;
/

/*
TRUNCATE TABLE Dimlocation;
EXECUTE Location_Load;
Select * from dimlocation;
*/

CREATE OR REPLACE PROCEDURE HospitalAdmissions_Load
AS
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE facthospitaladmissions';
    INSERT INTO facthospitaladmissions /* Columns excluded for brevity */
    SELECT * /* Columns excluded for brevity */
    FROM hospitaladmissions_preload;
END;
/

/*
TRUNCATE TABLE facthospitaladmissions;
EXECUTE HospitalAdmissions_Load;
Select * from facthospitaladmissions;
select count(*) from facthospitaladmissions
*/


-- ETL statements

EXECUTE populate_dimdate_from_2018;

EXECUTE doctors_extract;
EXECUTE doctors_transform;
EXECUTE doctor_load;

EXECUTE HospitalInformation_Extract ;
EXECUTE hospital_Transform ;
EXECUTE Hospital_Load ;

EXECUTE insuranceprovider_Extract ;
EXECUTE insuranceprovider_Transform ;
EXECUTE insuranceprovider_Load ;

EXECUTE location_transform;
EXECUTE location_load;

EXECUTE patients_extract;
EXECUTE patients_transform;
EXECUTE patients_load;

EXECUTE hospitaladmissions_extract;
EXECUTE hospitaladmissions_transform;
EXECUTE hospitaladmissions_load;

