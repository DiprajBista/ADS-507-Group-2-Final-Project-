# Download California State Jobs csv from Kaggle.com - https://www.kaggle.com/datasets/datasciencedonut/california-state-jobs
# Download 2023 Income Limits by County from CA.gov website - https://data.ca.gov/dataset/income-limits-by-county
# Remove SQL_SAFE_UPDATES protection 
SET SQL_SAFE_UPDATES = 0;


CREATE SCHEMA CA_job_listings;
USE CA_job_listings;
SELECT * FROM calcareerdata1;
SELECT COUNT(*) AS total_rows FROM calcareerdata1;

# Add Job_ID unique identifier to the jobs table 
ALTER TABLE `ca_job_listings`.`jobs`
MODIFY COLUMN `Job_ID` INT AUTO_INCREMENT,
ADD UNIQUE INDEX `Job_ID_UNIQUE` (`Job_ID` ASC) VISIBLE;

# View Rows of Data imported 
SELECT COUNT(*) AS total_rows FROM jobs;

# Add Job_ID unique identifier to the household_income table 
ALTER TABLE `household_income`
ADD COLUMN `County_ID` INT AUTO_INCREMENT,
ADD UNIQUE INDEX `County_ID_UNIQUE` (`County_ID`) VISIBLE;

# Make the unique identifier the primary key for household_income table 
ALTER TABLE household_income
ADD PRIMARY KEY (County_ID);

# Move it to the first column in the table 
ALTER TABLE household_income
MODIFY COLUMN County_ID INT AUTO_INCREMENT FIRST;

# View the Tables in ca_job_listings database 
SELECT * FROM household_income;
SELECT * FROM jobs;

# Remove $ from Salary Range 
UPDATE jobs
SET Salary = REPLACE(Salary, '$', '')
WHERE Job_ID > 0;

# Change Publish_Date Column from a VARCHAR() to a Date column with MM/DD/YYYY format 
# Step 1: Add a new column to store the converted date values temporarily
ALTER TABLE jobs
ADD COLUMN new_publish_date DATE;

# Step 2: Update the new column with the converted date values
UPDATE jobs
SET new_publish_date = STR_TO_DATE(Publish_Date, '%m/%d/%Y')
WHERE Job_ID > 0;

# Step 3: Drop the old VARCHAR column
ALTER TABLE jobs
DROP COLUMN Publish_Date;

# Step 4: Rename the new column to Publish_Date
ALTER TABLE jobs
CHANGE COLUMN new_publish_date Publish_Date DATE;

# View jobs table to confirm change was successful 
SELECT * FROM jobs;

# Move new Publish_Date column back to column 8 
ALTER TABLE jobs
MODIFY COLUMN Publish_Date DATE AFTER Location;

# Change Filing_Deadline Column from a VARCHAR() to a Date column with MM/DD/YYYY format 
# Step 1: Add a new column to store the converted date values temporarily
ALTER TABLE jobs
ADD COLUMN new_filing_deadline DATE;

# Step 2: Update the new column with the converted date values
UPDATE jobs
SET new_filing_deadline = 
    CASE 
        WHEN Filing_Deadline = 'Until Filled' THEN '12/31/2024'
        ELSE STR_TO_DATE(Filing_Deadline, '%m/%d/%Y')
    END
WHERE Job_ID > 0;

# Step 3: Drop the old VARCHAR column
ALTER TABLE jobs
DROP COLUMN Filing_Deadline;

# Step 4: Rename the new column to Publish_Date
ALTER TABLE jobs
CHANGE COLUMN new_filing_deadline Filing_Deadline DATE;

# Move new Publish_Date column back to column 9 
ALTER TABLE jobs
MODIFY COLUMN Filing_Deadline DATE AFTER Publish_Date;

# Change Null Filing Deadlines to 12/31/2024
UPDATE jobs
SET Filing_Deadline = IFNULL(Filing_Deadline, STR_TO_DATE('12/31/2024', '%m/%d/%Y'))
WHERE Job_ID > 0;


# Changing Salary Column from VARCHAR() to Integer  - Creating 2 columns for low and high end of salary range 
# Create a column to salary_high and extract the high end of salary range  

# Add a new column for low end of salary range and extract the low end of salary range 
ALTER TABLE jobs
ADD COLUMN salary_low INT;

UPDATE jobs
SET salary_low = 
    CASE 
        WHEN Salary LIKE '%-%' THEN -- Handle salary ranges
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(Salary, ' - ', 1), '.', 1) AS UNSIGNED)
        ELSE -- Handle other cases
            CAST(SUBSTRING_INDEX(Salary, '.', 1) AS UNSIGNED) 
    END;

# Move new salary_low column to after Salary column
ALTER TABLE jobs
MODIFY COLUMN salary_low INT AFTER Salary;


# Add a column to salary_high and extract the high end of salary range  
ALTER TABLE jobs
ADD COLUMN salary_high INT;

UPDATE jobs
SET salary_high = 
    CASE 
        WHEN Salary LIKE '%-%' THEN -- Handle salary ranges
            CAST(SUBSTRING_INDEX(Salary, ' - ', -1) AS DECIMAL(10, 2)) -- Extract the value after the '-' character
        ELSE -- Handle other cases
            CAST(SUBSTRING_INDEX(Salary, '.', 1) AS DECIMAL(10, 2)) -- Extract the salary before the decimal point
    END;

# Move new salary_high column to after salary_low column
ALTER TABLE jobs
MODIFY COLUMN salary_high INT AFTER salary_low;

# Create Average Salary Range Column and take average of salary column for each row 
ALTER TABLE jobs
ADD COLUMN avg_salary DECIMAL(10, 2);

UPDATE jobs
SET avg_salary = 
    CASE 
        WHEN salary_low IS NOT NULL AND salary_high IS NOT NULL THEN 
            (CAST(salary_low AS DECIMAL(10, 2)) + CAST(salary_high AS DECIMAL(10, 2))) / 2 
        WHEN salary_low IS NOT NULL THEN 
            CAST(salary_low AS DECIMAL(10, 2)) 
        WHEN salary_high IS NOT NULL THEN 
            CAST(salary_high AS DECIMAL(10, 2)) 
        ELSE -- Both columns are NULL
            NULL -- Set avg_salary to NULL
    END;
    
# Move new avg_salary column to after salary_high column
ALTER TABLE jobs
MODIFY COLUMN avg_salary INT AFTER salary_high;

# View counties found in Location column 
SELECT DISTINCT location
FROM jobs;

# Create New Table from Jobs table that contains Job_ID, Working_title, Salary, avg_salary and Location columns 
CREATE TABLE job_salary_location AS
SELECT Job_ID, Working_title, Salary, avg_salary, Location 
FROM jobs;

# Make Job_ID the primary key 
ALTER TABLE job_salary_location
ADD PRIMARY KEY (Job_ID);

# View job_salary_location table to confirm change was successful 
SELECT * FROM job_salary_location;

# Create New Table from household_income table that contains County_ID, County, and AMI (Average Median Income)  
CREATE TABLE average_median_income AS
SELECT County_ID, County, AMI 
FROM household_income;

# Make County_ID the primary key 
ALTER TABLE average_median_income
ADD PRIMARY KEY (County_ID);

# View average_median_income table to confirm change was successful 
SELECT * FROM average_median_income;