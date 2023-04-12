use DMDDPROJECT19;

-- DROP IF EXISTS--
Drop table if exists  dbo.patient;
Drop table if exists  dbo.patient_demographics;
drop table if exists dbo.insurance_provider;
drop table if exists dbo.point_of_contact;

Drop table if exists dbo.diagnosis;
Drop table if exists dbo.diagnosis_details;

DROP TABLE IF EXISTS dbo.prescription_Medicine;

Drop table if exists dbo.vital_signs;
Drop table if exists dbo.vital_signs_details;

Drop table if exists dbo.symptoms;
Drop table if exists dbo.symptom_details;

Drop table if exists dbo.billing;
Drop table if exists dbo.prescription;

Drop table if exists dbo.medicine_details;
drop table if exists dbo.patient_appointment_details;

Drop table if exists dbo.doctor;




-- DDL Scripts--

CREATE TABLE patient
(
patient_id INT NOT NULL Identity(1,1), 
first_name VARCHAR(45),
last_name VARCHAR(45),
dob DateTime,
street VARCHAR(45),
city VARCHAR(45),
[state] VARCHAR(45),
zip_code INT,
phone_no BIGINT, 
email VARCHAR(45),
CONSTRAINT patient_PK primary key (patient_id)
);

CREATE TABLE patient_demographics
(
patient_id INT NOT NULL,
gender VARCHAR(45),
race VARCHAR(45),
ethnicity VARCHAR(45),
martial_status VARCHAR(45),
employment_status VARCHAR(45),
CONSTRAINT patientDemo_PK  PRIMARY KEY (patient_id),
CONSTRAINT  patientDemo_FK FOREIGN KEY (patient_id) 
			references patient(patient_id)  
);

CREATE TABLE point_of_contact
(
pc_id INT Identity(1,1),
patient_id INT NOT NULL,
pc_first_name VARCHAR(45),
pc_last_name VARCHAR(45),
pc_phone_no BIGINT,
pc_email VARCHAR(45),
CONSTRAINT PC_PK  PRIMARY KEY (patient_id),
CONSTRAINT PC_FK FOREIGN KEY (patient_id) 
			references patient(patient_id)  
);

CREATE TABLE insurance_provider
(
provider_id INT NOT NULL Identity(1,1),
patient_id INT NOT NULL ,
insurance_provider_name VARCHAR(45),
patient_policy_number VARCHAR(10),
policy_plan_type CHAR(1),
CONSTRAINT insurance_provider_PK  PRIMARY KEY (provider_id),
CONSTRAINT insurance_provider_FK FOREIGN KEY (patient_id) 
			references patient(patient_id)  
);

CREATE TABLE doctor
(
doctor_id INT NOT NULL Identity(1,1), 
first_name VARCHAR(45),
last_name VARCHAR(45),
contact_no BIGINT,
designation VARCHAR(45)
CONSTRAINT doctor_PK PRIMARY KEY (doctor_id),
);

 CREATE TABLE patient_appointment_details
(
appointment_id INT NOT NULL Identity(1,1), 
patient_id INT NOT NULL REFERENCES patient(patient_id),
doctor_id INT NOT NULL REFERENCES doctor(doctor_id),
appointment_date DateTime,
admit_type VARCHAR(45),
hospital_name CHAR(50),
CONSTRAINT patient_appointment_details_PK PRIMARY KEY (appointment_id),
CONSTRAINT patient_appointment_details_FK FOREIGN KEY (patient_id)
            REFERENCES patient(patient_id),
CONSTRAINT patient_appointment_details_FK2 FOREIGN KEY (doctor_id)
            REFERENCES doctor(doctor_id)
);

CREATE TABLE symptom_details
(
symptom_id INT NOT NULL Identity(1,1), 
symptom_name VARCHAR(45),
CONSTRAINT symptom_details_PK PRIMARY KEY (symptom_id)
);


CREATE TABLE symptoms
(
appointment_id INT NOT NULL,
symptom_id INT NOT NULL,
doctor_id INT NOT NULL,
duration INT,
CONSTRAINT symptoms_PK PRIMARY KEY (appointment_id,symptom_id,doctor_id),
CONSTRAINT symptomsA_FK FOREIGN KEY (appointment_id) REFERENCES patient_appointment_details(appointment_id),
CONSTRAINT symptomsS_FK FOREIGN KEY (symptom_id) REFERENCES symptom_details(symptom_id),
CONSTRAINT symptomsD_FK FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id)
);

CREATE TABLE diagnosis_details
(
diagnosis_id INT NOT NULL Identity(1,1),
diagnosis_name VARCHAR(45),
CONSTRAINT diagnosis_details_PK PRIMARY KEY (diagnosis_id)
);


CREATE TABLE diagnosis
(
appointment_id int not null ,
doctor_id int not null,
diagnosis_id int not null,
CONSTRAINT diagnosis_PK PRIMARY KEY (appointment_id,diagnosis_id,doctor_id),
CONSTRAINT diagnosisA_FK FOREIGN KEY (appointment_id) REFERENCES patient_appointment_details(appointment_id),
CONSTRAINT diagnosisD_FK FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id)
);



CREATE TABLE bill
(
bill_number INT NOT NULL Identity(1,1), 
appointment_id INT,
total_amount INT,
payment_mode CHAR(4),
[status] VARCHAR(40),
claim_amount DOUBLE PRECISION
CONSTRAINT bill_PK PRIMARY KEY (bill_number),
CONSTRAINT bill_FK FOREIGN KEY (appointment_id) REFERENCES patient_appointment_details(appointment_id)
);


CREATE TABLE vital_sign_details
(
vital_id INT NOT NULL Identity(1,1),
vital_name VARCHAR(45),
normal_amount VARCHAR(45),
CONSTRAINT vital_signs_details_PK PRIMARY KEY (vital_id)
);

CREATE TABLE vital_signs
(
vital_id INT  NOT NULL,
appointment_id INT NOT NULL,
recorded_date DATE NOT NULL,
recorded_amount INT,
CONSTRAINT vital_signs_PK PRIMARY KEY (vital_id, appointment_id, recorded_date),
CONSTRAINT vital_signs_FK FOREIGN KEY (appointment_id) REFERENCES patient_appointment_details(appointment_id),
CONSTRAINT vital_signs_FK2 FOREIGN KEY (vital_id) REFERENCES vital_sign_details(vital_id)
);

CREATE TABLE prescription
(
prescription_id INT NOT NULL Identity(1,1), 
appointment_id INT,
doctor_id INT,
renewal_time DATETIME,
CONSTRAINT prescription_PK PRIMARY KEY (prescription_id),
CONSTRAINT prescription_FK FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id),
CONSTRAINT prescription_FK2 FOREIGN KEY (appointment_id) REFERENCES patient_appointment_details(appointment_id)
);

CREATE TABLE medicine_details
(
medicine_id INT NOT NULL IDENTITY(1,1), 
medicine_name VARCHAR(45),
medicine_price DOUBLE PRECISION,
CONSTRAINT medicine_details_PK PRIMARY KEY (medicine_id)
);

CREATE TABLE prescription_Medicine
(
    prescription_id INT NOT NULL,
    medicine_id INT NOT NULL,
    dose VARCHAR(30),
    quantity INT,
    CONSTRAINT prescription_Medicine_PK PRIMARY KEY (prescription_id,medicine_id),
    CONSTRAINT prescription_Medicine_FK FOREIGN KEY (prescription_id) REFERENCES prescription(prescription_id),
    CONSTRAINT prescription_Medicine_FK2 FOREIGN KEY (medicine_id) REFERENCES medicine_details(medicine_id)
);

