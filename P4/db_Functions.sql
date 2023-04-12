
-------- VIEWS ----------
CREATE VIEW PatientDetails AS
SELECT
pat.patient_id, pat.first_name as first_name, pat.last_name as last_name, pat.dob, pat.street, pat.city, pat.state, pat.zip_code, pat.phone_no as phone_no, pat.email, patdemo.gender, patdemo.ethnicity, patdemo.martial_status, patdemo.employement_status,ins.insurance_provider_name, poc.pc_first_name, poc.pc_last_name, poc.pc_phone_no 
FROM patient pat INNER JOIN patient_demographics patdemo ON pat.patient_id = patdemo.patient_id
JOIN point_of_contact poc ON pat.patient_id = poc.patient_id
JOIN insurance_provider ins ON ins.patient_id = pat.patient_id

SELECT * FROM PatientDetails

CREATE VIEW PatAppointmentSympDiagnoDetails AS 
SELECT
app.appointment_id, app.patient_id, app.doctor_id, app.appointment_date, app.admit_type,
app.hospital_name, symp.symptom_id, sympdet.symptom_name, diag.diagnosis_id, 
diagdet.diagnosis_name
FROM patient_appointment_details app
LEFT JOIN symptoms symp ON app.appointment_id = symp.appointment_id
LEFT JOIN symptom_details sympdet ON symp.symptom_id = sympdet.symptom_id
LEFT JOIN diagnosis diag ON app.appointment_id = diag.appointment_id
LEFT JOIN diagnosis_details diagdet ON diag.diagnosis_id = diagdet.diagnosis_id

SELECT * FROM PatAppointmentSympDiagnoDetails

CREATE VIEW PatientAppointmentVitals AS
SELECT 
patapp.appointment_id,
patapp.admit_type,
patapp.hospital_name,
vsd.vital_name,
( cast(vs.recorded_amount as varchar) + ' ' + vsd.vital_name) as vital_value
FROM patient_appointment_details patapp 
left JOIN vital_signs vs
    ON patapp.appointment_id = vs.appointment_id
left JOIN vital_sign_details vsd
	on vs.vital_id = vsd.vital_id

Select * from PatientAppointmentVitals

------ Functions --------

CREATE FUNCTION fn_CalculateAge(@PatID int) 
RETURNS int AS 
begin
	Declare @age int = 
		(
			SELECT 
            DATEDIFF(hour, pat.dob, GETDATE())/8766 AS Age       
			from Patient pat		
			WHERE pat.patient_id = @PatID
        );
    RETURN @age;
end

alter table dbo.patient_demographics Add age as (dbo.fn_CalculateAge(patient_id));

SELECT * FROM patient_demographics;

CREATE FUNCTION fn_DifferenceInVitals(
    @recorded_amount DOUBLE PRECISION, @normal_amount DOUBLE PRECISION
)
RETURNS INT
AS 
BEGIN 
--declare the return variable ---
DECLARE @c INT
SET @c = @recorded_amount - @normal_amount
--- return function---
RETURN @c
END
GO



CREATE FUNCTION fn_Evaluate(@vital_id int,@appointment_id int)
Returns Varchar(25) AS
BEGIN
DECLARE @Range VARCHAR(25);
DECLARE @recorded_amount INT = (
	SELECT vs.recorded_amount from vital_signs vs where vs.vital_id = @vital_id AND vs.appointment_id = @appointment_id);
DECLARE @Amount VARCHAR(3)= ( 
	SELECT SUBSTRING(vsd.normal_amount, 0, CHARINDEX('-', vsd.normal_amount))  
	from vital_sign_details vsd 
	where vsd.vital_id = @vital_id);
DECLARE @normal_amount INT = (CAST(@Amount AS INT));
DECLARE @diff INT = (dbo.fn_DifferenceInVitals(@recorded_amount,@normal_amount));
	IF @diff = 0
		set @Range = 'Normal Results';
	ELSE
		IF @diff > 0
		set @Range = 'Above Normal';
		ELSE
		set @Range = 'Below Normal';
RETURN @Range
END


alter table dbo.vital_signs Add result_range as (dbo.fn_Evaluate(vital_id,appointment_id));
SELECT * FROM vital_signs

----------- INDEXES -----------

CREATE NONCLUSTERED INDEX IX_patient_appointment_details_info_hospital_name on patient_appointment_details (hospital_name ASC)

CREATE NONCLUSTERED INDEX IX_insuranceprovider_info_insuranceprovidername on insurance_provider (insurance_provider_name ASC)

CREATE NONCLUSTERED INDEX IX_doctor_info_name_designation on Doctor(first_name ASC, last_name ASC, designation ASC)

----------- TRIGGERS ------------
Create trigger tr_UpdatePaymentStatus
on bill
after INSERT, UPDATE, DELETE
As begin
declare @TotalAmt money = 0;
declare @appointment_id varchar(20);
declare @ClaimAmt money = 0;
declare @status varchar(40);
select @appointment_id = isnull (i.appointment_id, d.appointment_id)
   from inserted i full join deleted d 
   on i.appointment_id = d.appointment_id;
select @TotalAmt = total_amount,
		@ClaimAmt= claim_amount
   from bill
       where appointment_id = @appointment_id;
if @ClaimAmt <= (@TotalAmt*0.7)
set @status = 'Follow up required'
else if @ClaimAmt > (@TotalAmt*0.7) AND @ClaimAmt <= (@TotalAmt)
set @status = 'Partial Payment Received'
else 
set @status = 'Complete Payment Received'
update bill
set Status = @status
where appointment_id = @appointment_id
end

--- to check the trigger inserting new record and verfying the status column by fetching whole bill table records-----
insert into bill(appointment_id, total_amount, payment_mode,claim_amount) values (108, 20, 'CARD',28);
SELECT * FROM Bill


----- CHECK CONSTRAINTS -------

ALTER TABLE bill
ADD CONSTRAINT ChckPayMode CHECK(payment_mode IN (
    'CARD','CASH'
));

ALTER TABLE insurance_provider
ADD CONSTRAINT ChckPlanType CHECK(policy_plan_type IN(
    'F','C','I'));

ALTER TABLE patient_demographics
ADD CONSTRAINT ChckEmploymentStatus CHECK(employement_status IN(
	'Employed','Unemployed','Retired','Unavailable'
	));

--------- COLUMN ENCRYPTION ------------
--- 1. create master key-----
DROP MASTER KEY 
create MASTER KEY 
ENCRYPTION BY PASSWORD = 'Dmddproject@19'

select name KeyName from sys.symmetric_keys

--- 2. create certificate ---

CREATE CERTIFICATE InsPolNumber
WITH SUBJECT = 'Insurance Policy Number';

--- 3. create symmteric key -----

CREATE SYMMETRIC KEY InsPolNumber_SM
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE InsPolNumber

--- 4. openning symmetric key with doctor's contact number ----

OPEN SYMMETRIC KEY InsPolNumber_SM
DECRYPTION BY CERTIFICATE InsPolNumber;

ALTER TABLE dbo.insurance_provider
ADD patient_policy_number_encrypt varbinary(MAX)

--- 5. Encrypting column contact number with the symmertic key with default password Pass1234 -----
UPDATE dbo.insurance_provider set [patient_policy_number_encrypt] = EncryptByKey(Key_GUID('InsPolNumber_SM'), convert(varbinary,patient_policy_number) )
GO

SELECT * FROM insurance_provider
---- 6. closing key after encryption----
CLOSE SYMMETRIC KEY InsPolNumber_SM;
            GO

---- 7. decrypting to check the encryption ------
OPEN SYMMETRIC KEY InsPolNumber_SM
DECRYPTION BY CERTIFICATE InsPolNumber;

SELECT provider_id,patient_id, insurance_provider_name,patient_policy_number_encrypt AS 'Encrypted data',
            CONVERT(varchar, DecryptByKey(patient_policy_number_encrypt)) AS 'Decrypted patient policy number'
            FROM dbo.insurance_provider;

CLOSE SYMMETRIC KEY InsPolNumber_SM;
            GO

---------- Stored Procedures ---------
CREATE PROC ChangeDoctorDesignation @doctor_id int, @new_designation varchar(45)
AS
BEGIN

update doctor 
SET designation = @new_designation
WHERE doctor_id = @doctor_id

END

EXEC ChangeDoctorDesignation 5,'Surgeon'
SELECT * FROM doctor


CREATE PROC AddNewdiagnosis @diagnosis_name varchar(45)
AS
BEGIN
INSERT INTO diagnosis_details(diagnosis_name) VALUES (@diagnosis_name)
END

EXEC AddNewdiagnosis 'Osteoporosis'

SELECT * FROM diagnosis_details


CREATE PROC CountPatientAppointments @patient_id INT , @count_appointments INT OUTPUT AS
DECLARE @count INT
BEGIN
SELECT @count = COUNT(patient_id) from patient_appointment_details where patient_id = @patient_id
SELECT hospital_name,appointment_date 
from patient_appointment_details 
where patient_id = @patient_id
set @count_appointments = @count
END

declare @total_appointment int
exec CountPatientAppointments 27, @count_appointments=@total_appointment OUTPUT
SELECT @total_appointment AS TOTAL_PATIENT_APPOINTMENTS

