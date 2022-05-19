-- Recreate table 'covid19_case'
DROP TABLE if exists covid19_case cascade;
CREATE TABLE IF NOT EXISTS covid19_case (
    covid_case_id SERIAL,
    covid_case_csv_id INT NOT NULL,
    gender_id CHAR(2),
    age INT,
    symptoms_start_date DATE,
    registration_date DATE,
    death_date DATE,
    respiratory_assistance CHAR(2),
    registration_state_id INT NOT NULL,
    clasification varchar(50),
    residence_state_id INT NOT NULL,
    diagnosis_date DATE,
    residence_department_id INT,
    last_update DATE,
    timestamp timestamp default current_timestamp,
    PRIMARY KEY (covid_case_id),
    CONSTRAINT fk_state FOREIGN KEY(registration_state_id) REFERENCES state(state_id)
);
