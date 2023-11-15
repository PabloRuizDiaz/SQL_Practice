/* 
#### Final MySQL Project - Group A ####
## Task 1 ##

The data to work with is in various file formats (json, csv, xlsx and sql). To deal with them we need to 
upload all data in only one format (sql using DBMS MySQL) and create a temporary schema named "vivak_data_temp". 
All of these to analyze and get a final schema/database, thus, we can handle them correctly as data analysts 
for our client.

With json and csv files we can upload directly using workbench software ("Table Data Import Wizard"). However, 
with the xlsx file we should divide all the sheets and change them to csv files.

Finally, the sql file made a new schema named "HR". As a consequence of it, we have to migrate the tables 
from this schema to the vivak_data_temp schema to definitely have all tables in one schema/database.
*/


-- Creating the temporary schema "vivak_data_temp" and selecting it
CREATE SCHEMA IF NOT EXISTS vivak_data_temp;
USE vivak_data_temp;

-- Migrate tables from "HR" schema to "vivak_data_temp" schema
CREATE TABLE vivak_data_temp.regions AS
    SELECT * FROM HR.regions;

CREATE TABLE vivak_data_temp.countries AS
    SELECT * FROM HR.countries;

CREATE TABLE vivak_data_temp.locations AS
    SELECT * FROM HR.locations;

/*
After uploading all the tables and data inside the "vivak_data_temp" schema, we have to analyze all the 
observations, recognize the proper entities and attributes to have a final schema.

To do this, we applied the following steps:

## Step 1) The tables named "OrgStructure_v2_Location-####" have the same information but for each office 
around the world. For that reason, we can merge all rows in only one table. To differentiate between them 
we add a new column named "location_id" with a default value (this value came from "OrgStructure_v2_Locations" 
table -"location_id" column- because they are similar).
*/

-- Adding new columns with a default value (this value is from "OrgStructure_v2_Locations")
ALTER TABLE `OrgStructure_v2_Location-1400-HO` ADD location_id TINYINT NOT NULL DEFAULT 1;
ALTER TABLE `OrgStructure_v2_Location-1500` ADD location_id TINYINT NOT NULL DEFAULT 2;
ALTER TABLE `OrgStructure_v2_Location-1700` ADD location_id TINYINT NOT NULL DEFAULT 3;
ALTER TABLE `OrgStructure_v2_Location-1800` ADD location_id TINYINT NOT NULL DEFAULT 4;
ALTER TABLE `OrgStructure_v2_Location-2400` ADD location_id TINYINT NOT NULL DEFAULT 5;
ALTER TABLE `OrgStructure_v2_Location-2500` ADD location_id TINYINT NOT NULL DEFAULT 6;
ALTER TABLE `OrgStructure_v2_Location-2700` ADD location_id TINYINT NOT NULL DEFAULT 7;

-- Creating the table "office_staff"
CREATE TABLE office_staff(
	employee_location_id INT AUTO_INCREMENT
	, job_title VARCHAR(50) NOT NULL
	, fullName VARCHAR(100) NOT NULL
	, location_id INT NOT NULL
	, PRIMARY KEY(employee_location_id)
);

-- Inserting the data to the new table
INSERT INTO office_staff (job_title, fullName, location_id_fk)
	SELECT 
		d.job_title 
		, d.`Full Name` AS fullName
		, d.location_id_fk
	FROM (
		SELECT * FROM `OrgStructure_v2_Location-1400-HO` osvlh 
		UNION
		SELECT * FROM `OrgStructure_v2_Location-1500` osvl 
		UNION
		SELECT * FROM `OrgStructure_v2_Location-1700` osvl2 
		UNION
		SELECT * FROM `OrgStructure_v2_Location-1800` osvl3 
		UNION
		SELECT * FROM `OrgStructure_v2_Location-2400` osvl4 
		UNION
		SELECT * FROM `OrgStructure_v2_Location-2500` osvl5 
		UNION
		SELECT * FROM `OrgStructure_v2_Location-2700` osvl6
	) d;

-- Dropping the tables to clean the database
DROP TABLE `OrgStructure_v2_Location-1400-HO`;
DROP TABLE `OrgStructure_v2_Location-1500`;
DROP TABLE `OrgStructure_v2_Location-1700`;
DROP TABLE `OrgStructure_v2_Location-1800`;
DROP TABLE `OrgStructure_v2_Location-2400`;
DROP TABLE `OrgStructure_v2_Location-2500`;
DROP TABLE `OrgStructure_v2_Location-2700`;

/*
Analyzing the new table's data, we recognize that 
  > "fullName" column’s data is in the "employees" table;
  > "job_title" column’s data is in "OrgStructure_v2_OrgStructure" table and this can be linked with "employee" table;
  > the others columns were created by us.

To conclude, this table can be dropped.
*/

-- Checking data in "office_staff" is in "employee" table
SELECT count(*) FROM office_staff; -- 85 rows
SELECT count(*) FROM employees e WHERE CONCAT(first_name, ' ', last_name) IN (SELECT fullName FROM office_staff)
GROUP BY concat(first_name, ' ', last_name); -- 85 rows

DROP TABLE office_staff;

-- ## Step 2) Rename Tables
RENAME TABLE OrgStructure_v2_Departments TO department;
RENAME TABLE OrgStructure_v2_OrgStructure TO structure;
RENAME TABLE employees TO employee;

-- ## Step 3) Solving an error: "department_id" column in "employee" table will be named as "location_id"
ALTER TABLE vivak_data_temp.employee CHANGE department_id location_id INT NULL;

/* 
## Step 4) We need to analyze "OrgStructure_v2_Locations" and "locations" tables. Both of them
have data about the offices around the world. Thus, we will check which of them have better data.
*/
SELECT
	location_id 
	, location_code 
	, street_address 
	, postal_code 
	, city 
	, state_province 
    , NULL AS country_id
FROM OrgStructure_v2_Locations osvl  
UNION
SELECT
	location_id
    , NULL AS location_code
    , street_address
    , postal_code
    , city
    , state_province
    , country_id
FROM locations l 
ORDER BY city;

/*
Looking at the result, "OrgStructure_v2_Locations" table is the best one. Nevertheless, we should complete
"country_id" column from "locations" table.
*/

UPDATE OrgStructure_v2_Locations t1
	INNER JOIN locations t2 ON t1.location_code = t2.location_id 
SET t1.country_id = t2.country_id 
WHERE t2.country_id IS NULL;

SELECT * FROM OrgStructure_v2_Locations;

DROP TABLE locations;

RENAME TABLE vivak_data_temp.OrgStructure_v2_Locations TO vivak_data_temp.office_location;

/*
## Step 5) One of the last comparisons we may apply is between the "department" table and "structure" table.
The first one has 11 rows, the same as the other table. Then if we check in "department" table
the data inside, we notice the same names that "structure" table.

In Conclusion, "department" table is not necessary.
*/
SELECT * FROM department d ; -- -> 11 
SELECT DISTINCT department_name  FROM structure s ; -- -> 11
SELECT * FROM department d WHERE department_name IN (SELECT DISTINCT department_name FROM structure s); -- -> 11

DROP TABLE department;

/* 
## Step 6) To reduce the number of tables to organize the final schema, "regions" table's data and 
"countries" table's data can be merged into the "office_location" table. For that, the necessary columns 
in the "office_location" table are "region_name" and "country_name".
*/

SELECT * FROM regions r;
SELECT * FROM countries c;

ALTER TABLE countries ADD region_name VARCHAR(25) NOT NULL;

UPDATE countries c
	INNER JOIN regions r USING(region_id)
SET c.region_name = r.region_name;

DROP TABLE regions;

SELECT * FROM office_location ol;

ALTER TABLE office_location ADD country_name VARCHAR(40) NOT NULL;
ALTER TABLE office_location ADD region_name VARCHAR(25) NOT NULL;

UPDATE office_location ol
	INNER JOIN countries c USING(country_id)
SET ol.region_name = c.region_name,
    ol.country_name = c.country_name;

DROP TABLE countries;

/*
Finally, we get a database with four entities:
    1. office_location
    2. employee
    3. dependent
    4. structure
*/

/*
Task 2
The next step is t obtain all the queries from the model to create the corresponding tables in the database 
which be in production for VivaK company.

Of course, from MySQL Workbench in model we create the links (foreign keys between tables) and Forward Engineering
to get the queries to create the final tables. Take into consideration we made some changes to optimaze them.
*/

CREATE SCHEMA IF NOT EXISTS VivaKHR DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci ;
USE VivaKHR ;

-- -----------------------------------------------------
-- Table VivaKHR.office_location
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS VivaKHR.office_location (
  location_id INT NOT NULL,  -- location_id will be the primary for table office_location, so we set it as not null
  location_code SMALLINT NOT NULL,  -- all location codes are 4 integers and less than 65535, we chose SMALLINT
  street_address VARCHAR (40) NOT NULL,
  postal_code VARCHAR (12),
  city VARCHAR (30) NOT NULL,
  state_province VARCHAR (25),
  country_abbr VARCHAR(2) NOT NULL, -- all country abbreviations in this table are two letters like UK, US etc.
  country_name VARCHAR(40) NOT NULL,
  region_name VARCHAR(40) NOT NULL,
  PRIMARY KEY (location_id), 
  UNIQUE INDEX location_code_UNIQUE (location_code ASC) VISIBLE, -- location code for each office should be unique
  UNIQUE INDEX street_address_UNIQUE (street_address ASC) VISIBLE) -- street address for each office should be unique (even in the same building, should be in different units)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table VivaKHR.structure
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS VivaKHR.structure (
  job_id INT NOT NULL, -- job_id will be the primary for table structure, so we set it as not null
  job_title VARCHAR(50) NOT NULL,
  min_salary DOUBLE(8,2) NOT NULL, -- as required from the project, all salary related columnb should be in double data type with two decimals
  max_salary DOUBLE(8,2) NOT NULL, -- as required from the project, all salary related columnb should be in double data type with two decimals
  department_name VARCHAR(50) NOT NULL,
  reports_to INT,  -- the job id of the person will be reported to
  PRIMARY KEY (job_id),
  UNIQUE INDEX job_title_UNIQUE (job_title ASC) VISIBLE) -- all job titles in structure table should be unique, one job title matches one job id
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table VivaKHR.employee
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS VivaKHR.employee (
  employee_id INT NOT NULL, -- employee_id will be the primary for table structure, so we set it as not null
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL,
  phone_number VARCHAR(20) DEFAULT '+000-000-000-0000', -- We set the format for phone numbers in +###-###-###-####
  job_id INT NOT NULL, -- this column is foreign key of employee table and from structure table, so the data type should be same as job_id in structure table
  salary DOUBLE(8,2) DEFAULT 0, -- as required from the project, all salary related columnb should be in double data type with two decimals, for employees who don't have salary at the beginning, we set it as 0 in the table
  salary_after_increment DOUBLE(8,2), -- -- as required from the project, all salary related columnb should be in double data type with two decimals
  report_to INT, -- the job id of the person will be reported to
  location_id INT NOT NULL, -- this column is foreign key of employee table and from office_location table, so the data type should be same as location_id in office_location table
  hire_date DATE NOT NULL, -- as required from the project, all dates related columns should be with DATE data type
  experience_at_VivaK TINYINT, -- number of months employees worked at Vivak, should be integers less than 255
  last_performance_rating TINYINT, 
  annual_dependent_benefit DOUBLE(8,2), -- similar as salary for employees, we set same data type for the benefits column
  PRIMARY KEY (employee_id),
  UNIQUE INDEX email_UNIQUE (email ASC) VISIBLE, -- every employee should have their own unique email address
  UNIQUE INDEX phone_number_UNIQUE (phone_number ASC) VISIBLE, -- every employee should have their own unique phone number
  INDEX office_location_fk_idx (location_id ASC) VISIBLE,
  INDEX structure_fk_idx (job_id ASC) VISIBLE,
  INDEX employee_fk_idx (report_to ASC) VISIBLE,
  CONSTRAINT office_location_fk
    FOREIGN KEY (location_id)
    REFERENCES VivaKHR.office_location (location_id)
    ON DELETE RESTRICT -- when location id has been deleted from office_location table,employee table won't be affected
    ON UPDATE CASCADE, -- when location id has been updated from office_location table,the observation in employee table will be updated as well
  CONSTRAINT structure_fk
    FOREIGN KEY (job_id)
    REFERENCES VivaKHR.structure (job_id)
    ON DELETE RESTRICT -- when job id has been deleted from structure table,employee table won't be affected
    ON UPDATE CASCADE, -- when job id has been updated from structure table, the observation in employee table will be updated as well
  CONSTRAINT employee_fk
    FOREIGN KEY (report_to)
    REFERENCES VivaKHR.employee (employee_id)
    ON DELETE RESTRICT -- when reports to has been deleted from structure table,employee table won't be affected 
    ON UPDATE RESTRICT) -- when reports to has been updated from structure table,employee table won't be affected
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

-- -----------------------------------------------------
-- Table VivaKHR.dependent
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS VivaKHR.dependent (
  dependent_id INT NOT NULL, -- dependent id will be the primary for table dependent, so we set it as not null
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  relationship VARCHAR(50) NOT NULL,
  employee_id INT NOT NULL, -- this column is foreign key of dependent table and from employee table, so the data type should be same as employee_id in employee table
  PRIMARY KEY (dependent_id),
  INDEX employee_fk_idx (employee_id ASC) VISIBLE,
  CONSTRAINT dependent_fk
    FOREIGN KEY (employee_id)
    REFERENCES VivaKHR.employee (employee_id)
    ON DELETE CASCADE -- when employee has been deleted from employee table,observation in dependent will be deleted as well 
    ON UPDATE CASCADE) -- when employee has been updated from employee table,observation in dependent will be updated as well 
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

/* 
Task 3
After creating the VivaKHR schema, in Task 3, we will import data from vivak_data_temp, and clean up the data at the same time.
Check if there are duplicate values, ensure the data format, and fill up the missing values.
*/

-- Part 1. Handle Duplicates
-- Insert data and handle duplicates in the office_location table from vivak_data_temp schema

USE VivaKHR;
INSERT INTO VivaKHR.office_location
(location_id, location_code,street_address,postal_code,city,state_province,country_name,country_abbr,region_name)
SELECT t.location_id,t.location_code,t.street_address,t.postal_code,t.city,state_province,t.country_name,t.country_id,t.region_name
FROM vivak_data_temp.office_location t;

-- Calculate how much data is in the VivaKHR: 7 rows
SELECT COUNT(location_id)
FROM VivaKHR.office_location;

-- Calculate how much data is in the vivak_data_temp: 7 rows
SELECT COUNT(location_id)
FROM vivak_data_temp.office_location;
  
-- Use location_id, location_code, and street_address as candidate keys to check the duplicates: no duplicates
SELECT location_id, location_code, street_address, COUNT(*)
FROM VivaKHR.office_location
GROUP BY location_id , location_code , street_address
HAVING COUNT(*) > 1;


-- Insert data and handle duplicates in the structure table from vivak_data_temp schema 
-- An error occurred when we import the data, because we set the reports_to column of VivaKHR to an integer
-- The data type of the Reports_to column in vivak_data_temp is text, we need to change it as integer
USE vivak_data_temp;

-- Set the blank in the reports_to column to NULL
UPDATE structure 
SET Reports_to = NULL
WHERE Reports_to = '';

-- Modify data type in the Reports_to column
ALTER TABLE structure
MODIFY Reports_to INT;

-- Import data in the structure table from vivak_data_temp schema 
USE VivaKHR;
INSERT INTO VivaKHR.structure(job_id,job_title,min_salary,max_salary,department_name,reports_to)
SELECT *
FROM vivak_data_temp.structure;

-- Use job_title, and department_name as candidate keys to check the duplicates: no duplicates
SELECT job_title, department_name, COUNT(*)
FROM VivaKHR.structure
GROUP BY job_title , department_name
HAVING COUNT(*) > 1;


-- Insert data and handle duplicates in the employee table from vivak_data_temp schema 
-- An error occurred when we import the data
-- Because we set the reports_to column of VivaKHR to an integer and create a unique constraint in the phone_number column
-- The data type of the manager_id column in vivak_data_temp is text, we need to change it as integer
USE vivak_data_temp;
-- Set the blank in the manager_id column to NULL
UPDATE employee 
SET manager_id = NULL
WHERE manager_id = '';

-- Modify data type in the manager_id column
ALTER TABLE employee
MODIFY manager_id INT;

-- Blanks are treated as duplicate values, we need to change to NULL
UPDATE employee 
SET phone_number = NULL
WHERE phone_number = '';

-- Import data in the employee table from vivak_data_temp schema 
USE VivaKHR;
INSERT INTO VivaKHR.employee
(employee_id,first_name,last_name,email,phone_number,job_id,salary,report_to,location_id,hire_date)
SELECT *
FROM vivak_data_temp.employee;

SELECT *
FROM VivaKHR.employee;

-- Use email, and phone_number as candidate keys to check the duplicates: no duplicates
SELECT email, phone_number, COUNT(*)
FROM VivaKHR.employee
GROUP BY email , phone_number
HAVING COUNT(*) > 1;   


-- Insert data and handle duplicates in the dependent table from vivak_data_temp schema 
-- Before inserting the data, we found that the dependent_id in the dependent table of vivak_data_temp has duplicate values
USE vivak_data_temp;
SELECT dependent_id, COUNT(*)
FROM dependent 
GROUP BY dependent_id
HAVING COUNT(*) > 1;

-- If first_name, last_name, relationship, and employee_id have the same value, we will determine that they are duplicate
SELECT first_name, last_name, relationship, employee_id, COUNT(*)
FROM dependent
GROUP BY first_name , last_name , relationship, employee_id
HAVING COUNT(*) > 1;
-- result: no duplicates

-- Discard the dependent_id column in vivak_data_temp and change the dependent_id column in VivaKHR to auto increment
USE VivaKHR;
ALTER TABLE dependent
MODIFY dependent_id INT AUTO_INCREMENT;

-- Import data in the employee table from vivak_data_temp schema
-- Use the employee_id that occurred in the employee table as valid data
INSERT INTO VivaKHR.dependent(first_name,last_name,relationship,employee_id)
SELECT t.first_name,t.last_name,t.relationship,t.employee_id
FROM 
(SELECT vivak_data_temp.d.*
FROM vivak_data_temp.employee e
INNER JOIN vivak_data_temp.dependent d USING (employee_id)) t;

USE VivaKHR;
SELECT *
FROM dependent;

-- Use first_name, last_name, relationship, and employee_id as candidate keys to check the duplicates
SELECT first_name, last_name, relationship, employee_id, COUNT(*)
FROM VivaKHR.dependent
GROUP BY first_name , last_name , relationship , employee_id
HAVING COUNT(*) > 1;


-- Part 2. Format the data
-- 1) floating-point data is represented as double
-- Add a check constraint to ensure that the salary column of the employee table must be greater than or equal to zero
ALTER TABLE employee
ADD CONSTRAINT salaryCheck CHECK (salary>=0);
-- USE DESCRIBE statement to provide a result set with details about the table's structure
DESCRIBE employee;
-- Check the data type of salary, salary_after_increment, and annual_dependent_benefit are double
DESCRIBE structure;
-- Check the data type of min_salary, and max_salary are double


-- 2) phone numbers are all recorded in the format
-- Replace the symbols '.' in the original data with '-'
UPDATE employee 
SET phone_number = REPLACE(phone_number, '.', '-');

-- Create a temporary table t1, then use the country_abbr column in the office_location table to determine its country code
-- Country code: US +001, CA +001, UK +044, DE +049
-- Update the phone_number column of the employee table by joining with the t1 on the employee_id column
WITH t1 AS
(SELECT concat(t.countryCodePhone, '-', t.phone_number) AS phone_number ,t.employee_id
FROM (
SELECT 
	CASE country_abbr
		WHEN 'US' THEN '+001'
        WHEN 'CA' THEN '+001'
        WHEN 'UK' THEN '+044'
        ELSE '+049'
	END AS countryCodePhone, phone_number, employee_id
FROM employee
LEFT JOIN office_location USING (location_id)) t)
UPDATE employee e
INNER JOIN t1 USING(employee_id)
SET e.phone_number=t1.phone_number;

-- Add a check constraint to ensure that the phone_number column of the employee table must have the format: '+000-000-000-0000'
ALTER TABLE employee
ADD CONSTRAINT phone_numberCheck CHECK (phone_number LIKE '+___-___-___-____');

-- 3) dates are recorded in the format
-- Add a check constraint to ensure that the hire_date column of the employee table must have the format: 'yyyy-mm-dd'
ALTER TABLE employee
ADD CONSTRAINT hire_dateCheck CHECK (hire_date = DATE_FORMAT(hire_date, '%Y-%m-%d'));


-- Part3. Treat Missing Values
-- 1）report_to column
-- Use data in the structure table to determine the report_to column in the employee table
-- Use LEFT JOIN to check its relationship
SELECT *
FROM employee 
LEFT JOIN structure USING (job_id);

-- Create two temporary tables: t1 and t2
-- Treat t1 table as employee table
-- Treat t2 table as manager table
-- Combine t1 and t2 tables, when the employee is in the same office as the manager and the employee reports to the same job id
-- Fill the manager_id in the report_to column in the employee table
WITH t1 AS (
	SELECT 
		e.employee_id
		, e.location_id
		, s.reports_to 
	FROM employee e 
	INNER JOIN structure s USING(job_id)
), t2 AS (
	SELECT 
		e.employee_id AS manager_id
		, e.location_id 
		, e.job_id
	FROM employee e )
UPDATE employee e
INNER JOIN (
SELECT 
	t1.employee_id
	, t1.reports_to AS report_to_job_title
	, t2.manager_id 
FROM t1
LEFT JOIN t2 ON (t1.location_id=t2.location_id AND t1.reports_to=t2.job_id)) t3 USING(employee_id)
SET e.report_to =  t3.manager_id ;

-- Because there are no location restrictions on who the vice president can report to, they all need to report to the president
-- The president does not need to report to anyone
-- President's location id = 1
-- Use the president's employee id (=100) to import the NULL value and exclude the value with location_id = 1
UPDATE employee 
SET report_to = 100
WHERE report_to IS NULL AND location_id != 1;



-- 2）salary column
-- If the salary column in the employee table is NULL or 0, it is recognized as a missing value
SELECT *
FROM employee
WHERE salary IS NULL OR salary = 0;

-- Use the min_salary and max_salary columns in the structure table to calculate the average salary 
-- Use the average salary to fill the missing values
UPDATE employee e
	INNER JOIN
    (SELECT 
        job_id, (min_salary + max_salary) / 2 AS avg_salary
    FROM structure) t4 USING (job_id) 
SET e.salary = t4.avg_salary
WHERE e.salary = 0 or e.salary IS NULL;


/*
 Task 4: Perform the following calculations and updates. 
You must include all the statements in your SQL file and only the important statements/outputs in your presentation.*/

/* 
Question 1: experience_at_VivaK: calculate the time difference (in months) between the hire date 
and the current date for each employee and update the column.*/

UPDATE employee
SET experience_at_VivaK = TIMESTAMPDIFF(MONTH,hire_date,CURDATE());

/* The argument for TIMESTAMDIFF function was determined including 
MONTH as unit of measurement, hire_date as starting time, and current date as ending time.*/

/* 
Question 2: last_performance_rating: to test the system, 
generate a random performance rating figure (a decimal number with two decimal points between 0 and 10) 
for each employee and update the column.*/

-- Change the data type for adding a number with two decimal places.
ALTER TABLE employee
MODIFY last_performance_rating DECIMAL(4,2); 

UPDATE employee
SET last_performance_rating = (SELECT ROUND(RAND()*10,2)); 
/* RAND() produce the number 0-0.9, then multiply by 10 to get the number 1-10, 
then round it to a two-decimal number.*/

/* 
Question 3: salary_after_increment: calculate the salary after the performance appraisal and 
update the column by using the following formulas */

WITH t1 AS (
	SELECT 
		employee_id, last_performance_rating
        , experience_at_VivaK,
		CASE WHEN last_performance_rating >= 9 THEN 0.15
			WHEN last_performance_rating >= 8 THEN 0.12
            WHEN last_performance_rating >= 7 THEN 0.10
            WHEN last_performance_rating >= 6 THEN 0.08
            WHEN last_performance_rating >= 5 THEN 0.05
            ELSE 0.02
            END AS rating_increment 
	FROM employee)
UPDATE employee e
INNER JOIN t1 USING (employee_id)
SET e.salary_after_increment = ( e.salary * (1+(0.01 * e.experience_at_VivaK) + t1.rating_increment));

/* Generate temporary t1 table that select specific column to calculates the rating_increment 
based on the value of last_performance_rating using a CASE statement.
And performing UPDATE operation on the employee table joining with the t1 table.
Then SET the salary_after_increment column data from the calculation. */

--  Ensuring whether salary_after_increment is completely fill in 
SELECT*
FROM employee
WHERE salary_after_increment IS NULL;

/* 
Question 4: annual_dependent_benefit: Calculate the annual dependent benefit per dependent (in USD) 
and update the column as per the table below*/

UPDATE employee e
INNER JOIN structure s USING(job_id)
SET annual_dependent_benefit = CASE WHEN s.job_title LIKE "%Executive%" THEN 0.2* e.salary*12
		WHEN s.job_title LIKE "%Manager%" THEN 0.15* e.salary*12
        ELSE 0.05 * salary*12
        END;

/* Obtaining the job_title by capturing observations from 
the employee and structure tables that completely match by an INNER JOIN using the job_id column.
The annual_dependent_benefit column will then be set as calculated salary depending on job_title.
*/

-- Rename the column to annual_dependent_benefit_in_USD
ALTER TABLE employee
RENAME COLUMN annual_dependent_benefit TO annual_dependent_benefit_in_USD;


/* 
Question 5: email: Until recently, the employees were using their private email addresses, 
and the company has recently bought the domain VivaK.com. 
Replace employee email addressed to ‘<emailID>@vivaK.com’. 
emailID is the part of the current employee email before the @ sign.*/

UPDATE employee
SET email = concat(SUBSTRING_INDEX(email,'@',1),"@vivaK.com");

/*Performing SUBSTRING_INDEX with 1  is to extract the portion before @. 
Then concatenate with @vivaK.com*/