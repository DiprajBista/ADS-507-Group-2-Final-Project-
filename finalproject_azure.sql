# Download California State Jobs csv from Kaggle.com - https://www.kaggle.com/datasets/datasciencedonut/california-state-jobs
# Download 2023 Income Limits by County from CA.gov website - https://data.ca.gov/dataset/income-limits-by-county
# Download Historical Housing Data - https://www.car.org/en/marketdata/data/housingdata  



# Remove SQL_SAFE_UPDATES protection 
SET SQL_SAFE_UPDATES = 0;

##  Create Database CA_job_listings
CREATE SCHEMA CA_job_listings; # Run Only Once

USE CA_job_listings;

# Create jobs table
CREATE TABLE `jobs` (
  `Job_ID` int NOT NULL AUTO_INCREMENT,
  `Listing_Title` varchar(90) NOT NULL,
  `Working_title` varchar(95) NOT NULL,
  `Req_ID` varchar(45) NOT NULL,
  `Salary` varchar(25) NOT NULL,
  `salary_low` int DEFAULT NULL,
  `salary_high` int DEFAULT NULL,
  `avg_salary` int DEFAULT NULL,
  `annual_salary` int DEFAULT NULL,
  `Employment_type` varchar(45) NOT NULL,
  `Department` varchar(75) NOT NULL,
  `Location` varchar(45) NOT NULL,
  `Publish_Date` date DEFAULT NULL,
  `Filing_Deadline` date DEFAULT NULL,
  `URL` varchar(95) NOT NULL,
  PRIMARY KEY (`Job_ID`),
  UNIQUE KEY `Job_ID_UNIQUE` (`Job_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=27861 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


# View Rows of Data imported 
SELECT * FROM jobs;

# Count Rows of Data Imported
SELECT COUNT(*) AS total_rows FROM jobs;

## Transformations for jobs table 
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

# Add a new column to calculate the annual salary
ALTER TABLE jobs
ADD COLUMN annual_salary INT;

# Update the new column with the calculated annual salary values
UPDATE jobs
SET annual_salary = avg_salary * 12;

# Move new annual_salary column to after avg_salary column
ALTER TABLE jobs
MODIFY COLUMN annual_salary INT AFTER avg_salary;

# View jobs table to confirm change was successful 
SELECT * FROM jobs;

# View counties found in Location column 
SELECT DISTINCT location
FROM jobs;




## Create New Table from Jobs table that contains Job_ID, Working_title, Salary, avg_salary and Location columns 
CREATE TABLE job_salary_location (
    Job_ID INT,
    Working_title VARCHAR(95) NOT NULL,
    Salary VARCHAR(25) NOT NULL,
    annual_salary INT,
    Location VARCHAR(45) NOT NULL,
    PRIMARY KEY (Job_ID)
) ENGINE=InnoDB;

INSERT INTO job_salary_location (Job_ID, Working_title, Salary, annual_salary, Location)
SELECT Job_ID, Working_title, Salary, annual_salary, Location 
FROM jobs;


## Transformations for job_salary_location table
ALTER TABLE job_salary_location
RENAME COLUMN annual_salary TO avg_annual_salary;

# Drop the word County from each row in the job_salary_location table 
UPDATE job_salary_location
SET Location = REPLACE(Location, 'County', '');

# View job_salary_location table to confirm change was successful 
SELECT * FROM job_salary_location;




# Create Household income table 
CREATE TABLE `household_income` (
  `County_ID` int NOT NULL AUTO_INCREMENT,
  `County` varchar(75) NOT NULL,
  `AMI` int NOT NULL,
  `ALI_1` int NOT NULL,
  `ALI_2` int NOT NULL,
  `ALI_3` int NOT NULL,
  `ALI_4` int NOT NULL,
  `ALI_5` int NOT NULL,
  `ALI_6` int NOT NULL,
  `ALI_7` int NOT NULL,
  `ALI_8` int NOT NULL,
  `ELI_1` int NOT NULL,
  `ELI_2` int NOT NULL,
  `ELI_3` int NOT NULL,
  `ELI_4` int NOT NULL,
  `ELI_5` int NOT NULL,
  `ELI_6` int NOT NULL,
  `ELI_7` int NOT NULL,
  `ELI_8` int NOT NULL,
  `VLI_1` int NOT NULL,
  `VLI_2` int NOT NULL,
  `VLI_3` int NOT NULL,
  `VLI_4` int NOT NULL,
  `VLI_5` int NOT NULL,
  `VLI_6` int NOT NULL,
  `VLI_7` int NOT NULL,
  `VLI_8` int NOT NULL,
  `LI_1` int NOT NULL,
  `LI_2` int NOT NULL,
  `LI_3` int NOT NULL,
  `LI_4` int NOT NULL,
  `LI_5` int NOT NULL,
  `LI_6` int NOT NULL,
  `LI_7` int NOT NULL,
  `LI_8` int NOT NULL,
  `MOD_1` int NOT NULL,
  `MOD_2` int NOT NULL,
  `MOD_3` int NOT NULL,
  `MOD_4` int NOT NULL,
  `MOD_5` int NOT NULL,
  `MOD_6` int NOT NULL,
  `MOD_7` int NOT NULL,
  `MOD_8` int NOT NULL,
  PRIMARY KEY (`County_ID`),
  UNIQUE KEY `County_ID_UNIQUE` (`County_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=59 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



## Transformations for household_income table 
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

SELECT * FROM household_income;





## Create New Table from household_income table that contains County_ID, County, and AMI (Average Median Income)  
CREATE TABLE average_median_income AS
SELECT County_ID, County, AMI 
FROM household_income;

INSERT INTO average_median_income (County_ID, County, AMI)
SELECT County_ID, County, AMI 
FROM household_income;

## Transformations for average_median_income table 
# Make County_ID the primary key 
ALTER TABLE average_median_income
ADD PRIMARY KEY (County_ID);

ALTER TABLE average_median_income
MODIFY COLUMN County VARCHAR(45);

# View average_median_income table to confirm change was successful 
SELECT * FROM average_median_income;




## Preparation for JOINING Tables 
# Trim Location data in jsl table to align with the County column in ami table and confirm the location/counties match in both tables 
SELECT jsl.Location
FROM job_salary_location jsl
WHERE NOT EXISTS (
    SELECT 1
    FROM average_median_income ami
    WHERE LOWER(TRIM(jsl.Location)) = LOWER(TRIM(ami.County))
);

# drop rows that dont match both columns Location_County
DELETE jsl
FROM job_salary_location jsl
LEFT JOIN average_median_income ami ON UPPER(TRIM(jsl.Location)) = UPPER(TRIM(ami.County))
WHERE ami.County IS NULL;

# View Counties in common in both columns (Location/Country)
SELECT DISTINCT UPPER(jsl.Location) AS jsl_County
FROM job_salary_location jsl
WHERE UPPER(jsl.Location) NOT IN (
    SELECT UPPER(ami.County)
    FROM average_median_income ami
);



## Create Combined Data Table to Join based on County 
CREATE TABLE combined_data AS
SELECT jsl.Job_ID, 
       jsl.working_title, 
       jsl.avg_annual_salary, 
       UPPER(TRIM(jsl.Location)) AS jsl_County,
       ami.County_ID, 
       ami.County AS ami_County, 
       ami.AMI
FROM job_salary_location jsl
LEFT JOIN average_median_income ami ON UPPER(TRIM(jsl.Location)) = UPPER(TRIM(ami.County));

ALTER TABLE combined_data
MODIFY COLUMN my_row_id bigint unsigned NOT NULL AUTO_INCREMENT,
MODIFY COLUMN Job_ID INT DEFAULT NULL,
MODIFY COLUMN working_title VARCHAR(95) NOT NULL,
MODIFY COLUMN avg_annual_salary INT DEFAULT NULL,
MODIFY COLUMN County_ID INT DEFAULT NULL,
MODIFY COLUMN County VARCHAR(45) DEFAULT NULL,
MODIFY COLUMN Avg_Median_Income INT DEFAULT NULL;


# View combined Data Table 
SELECT * FROM combined_data;

# Count how many jobs in combined data 
SELECT COUNT(*) FROM combined_data;


# Count how many jobs average annual salary exceeds the average median income 
SELECT COUNT(*) AS count_exceeding_ami
FROM combined_data
WHERE avg_annual_salary > Avg_Median_Income;


# Select jobs where the average annual salary exceeds the average median income 
SELECT *
FROM combined_data
WHERE avg_annual_salary > Avg_Median_Income;



## Create Table for Housing_data and Importing Housing_data
CREATE TABLE housing_data (
    Mon_Yr VARCHAR(15),
    Alameda VARCHAR(15),
    Amador VARCHAR(15),
    Butte VARCHAR(15),
    Calaveras VARCHAR(15),
    Contra_Costa VARCHAR(15),
    Del_Norte VARCHAR(15),
    El_Dorado VARCHAR(15),
    Fresno VARCHAR(15),
    Glenn VARCHAR(15),
    Humboldt VARCHAR(15),
    Kern VARCHAR(15),
    Kings VARCHAR(15),
    Lake VARCHAR(15),
    Lassen VARCHAR(15),
    Los_Angeles VARCHAR(15),
    Madera VARCHAR(15),
    Marin VARCHAR(15),
    Mariposa VARCHAR(15),
    Mendocino VARCHAR(15),
    Merced VARCHAR(15),
    Mono VARCHAR(15),
    Monterey VARCHAR(15),
    Napa VARCHAR(15),
    Nevada VARCHAR(15),
    Orange VARCHAR(15),
    Placer VARCHAR(15),
    Plumas VARCHAR(15),
    Riverside VARCHAR(15),
    Sacramento VARCHAR(15),
    San_Benito VARCHAR(15),
    San_Bernardino VARCHAR(15),
    San_Diego VARCHAR(15),
    San_Francisco VARCHAR(15),
    San_Joaquin VARCHAR(15),
    San_Luis_Obispo VARCHAR(15),
    San_Mateo VARCHAR(15),
    Santa_Barbara VARCHAR(15),
    Santa_Clara VARCHAR(15),
    Santa_Cruz VARCHAR(15),
    Shasta VARCHAR(15),
    Siskiyou VARCHAR(15),
    Solano VARCHAR(15),
    Sonoma VARCHAR(15),
    Stanislaus VARCHAR(15),
    Sutter VARCHAR(15),
    Tehama VARCHAR(15),
    Trinity VARCHAR(15),
    Tulare VARCHAR(15),
    Tuolumne VARCHAR(15),
    Ventura VARCHAR(15),
    Yolo VARCHAR(15),
    Yuba VARCHAR(15)
);

# View Housing_data table to confirm
SELECT * FROM housing_data;

# Make table visible 
ALTER TABLE housing_data
MODIFY COLUMN my_row_id bigint unsigned NOT NULL AUTO_INCREMENT;




## Transformations for Housing_data Table 
# Drop all rows except 2023 Housing Data 
DELETE FROM housing_data WHERE `Mon_Yr` NOT LIKE '%-23';


INSERT INTO housing_data (Mon_Yr, Alameda, Amador, Butte, Calaveras, Contra_Costa, Del_Norte, El_Dorado, Fresno, Glenn, Humboldt, Kern, Kings, Lake, Lassen, Los_Angeles, Madera, Marin, Mariposa, Mendocino, Merced, Mono, Monterey, Napa, Nevada, Orange, Placer, Plumas, Riverside, Sacramento, San_Benito, San_Bernardino, San_Diego, San_Francisco, San_Joaquin, San_Luis_Obispo, San_Mateo, Santa_Barbara, Santa_Clara, Santa_Cruz, Shasta, Siskiyou, Solano, Sonoma, Stanislaus, Sutter, Tehama, Trinity, Tulare, Tuolumne, Ventura, Yolo, Yuba)
SELECT 'Average_Rounded',
       ROUND(AVG(REPLACE(REPLACE(Alameda, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Amador, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Butte, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Calaveras, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Contra_Costa, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Del_Norte, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(El_Dorado, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Fresno, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Glenn, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Humboldt, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Kern, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Kings, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Lake, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Lassen, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Los_Angeles, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Madera, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Marin, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Mariposa, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Mendocino, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Merced, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Mono, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Monterey, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Napa, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Nevada, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Orange, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Placer, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Plumas, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Riverside, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Sacramento, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(San_Benito, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(San_Bernardino, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(San_Diego, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(San_Francisco, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(San_Joaquin, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(San_Luis_Obispo, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(San_Mateo, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Santa_Barbara, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Santa_Clara, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Santa_Cruz, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Shasta, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Siskiyou, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Solano, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Sonoma, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Stanislaus, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Sutter, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Tehama, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Trinity, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Tulare, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Tuolumne, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Ventura, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Yolo, ',', ''), '$', '')), 0),
       ROUND(AVG(REPLACE(REPLACE(Yuba, ',', ''), '$', '')), 0)
FROM housing_data
WHERE Mon_Yr LIKE '%-23'; 


# Create Transposed_Housing_Data Table 
CREATE TABLE Transposed_Housing_Data AS
SELECT 'Alameda' AS County, AVG(REPLACE(REPLACE(Alameda, ',', ''), '$', '')) AS Home_Price_Average FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Alameda NOT LIKE '%na%'
UNION ALL
SELECT 'Amador', AVG(REPLACE(REPLACE(Amador, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Amador NOT LIKE '%na%'
UNION ALL
SELECT 'Butte', AVG(REPLACE(REPLACE(Butte, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Butte NOT LIKE '%na%'
UNION ALL
SELECT 'Calaveras', AVG(REPLACE(REPLACE(Calaveras, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Calaveras NOT LIKE '%na%'
UNION ALL
SELECT 'Contra Costa', AVG(REPLACE(REPLACE(Contra_Costa, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Contra_Costa NOT LIKE '%na%'
UNION ALL
SELECT 'Del Norte', AVG(REPLACE(REPLACE(Del_Norte, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Del_Norte NOT LIKE '%na%'
UNION ALL
SELECT 'El Dorado', AVG(REPLACE(REPLACE(El_Dorado, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND El_Dorado NOT LIKE '%na%'
UNION ALL
SELECT 'Fresno', AVG(REPLACE(REPLACE(Fresno, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Fresno NOT LIKE '%na%'
UNION ALL
SELECT 'Glenn', AVG(REPLACE(REPLACE(Glenn, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Glenn NOT LIKE '%na%'
UNION ALL
SELECT 'Humboldt', AVG(REPLACE(REPLACE(Humboldt, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Humboldt NOT LIKE '%na%'
UNION ALL
SELECT 'Kern', AVG(REPLACE(REPLACE(Kern, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Kern NOT LIKE '%na%'
UNION ALL
SELECT 'Kings', AVG(REPLACE(REPLACE(Kings, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Kings NOT LIKE '%na%'
UNION ALL
SELECT 'Lake', AVG(REPLACE(REPLACE(Lake, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Lake NOT LIKE '%na%'
UNION ALL
SELECT 'Lassen', AVG(REPLACE(REPLACE(Lassen, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Lassen NOT LIKE '%na%'
UNION ALL
SELECT 'Los Angeles', AVG(REPLACE(REPLACE(Los_Angeles, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Los_Angeles NOT LIKE '%na%'
UNION ALL
SELECT 'Madera', AVG(REPLACE(REPLACE(Madera, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Madera NOT LIKE '%na%'
UNION ALL
SELECT 'Marin', AVG(REPLACE(REPLACE(Marin, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Marin NOT LIKE '%na%'
UNION ALL
SELECT 'Mariposa', AVG(REPLACE(REPLACE(Mariposa, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Mariposa NOT LIKE '%na%'
UNION ALL
SELECT 'Mendocino', AVG(REPLACE(REPLACE(Mendocino, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Mendocino NOT LIKE '%na%'
UNION ALL
SELECT 'Merced', AVG(REPLACE(REPLACE(Merced, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Merced NOT LIKE '%na%'
UNION ALL
SELECT 'Mono', AVG(REPLACE(REPLACE(Mono, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Mono NOT LIKE '%na%'
UNION ALL
SELECT 'Monterey', AVG(REPLACE(REPLACE(Monterey, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Monterey NOT LIKE '%na%'
UNION ALL
SELECT 'Napa', AVG(REPLACE(REPLACE(Napa, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Napa NOT LIKE '%na%'
UNION ALL
SELECT 'Nevada', AVG(REPLACE(REPLACE(Nevada, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Nevada NOT LIKE '%na%'
UNION ALL
SELECT 'Orange', AVG(REPLACE(REPLACE(Orange, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Orange NOT LIKE '%na%'
UNION ALL
SELECT 'Placer', AVG(REPLACE(REPLACE(Placer, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Placer NOT LIKE '%na%'
UNION ALL
SELECT 'Plumas', AVG(REPLACE(REPLACE(Plumas, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Plumas NOT LIKE '%na%'
UNION ALL
SELECT 'Riverside', AVG(REPLACE(REPLACE(Riverside, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Riverside NOT LIKE '%na%'
UNION ALL
SELECT 'Sacramento', AVG(REPLACE(REPLACE(Sacramento, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Sacramento NOT LIKE '%na%'
UNION ALL
SELECT 'San Benito', AVG(REPLACE(REPLACE(San_Benito, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND San_Benito NOT LIKE '%na%'
UNION ALL
SELECT 'San Bernardino', AVG(REPLACE(REPLACE(San_Bernardino, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND San_Bernardino NOT LIKE '%na%'
UNION ALL
SELECT 'San Diego', AVG(REPLACE(REPLACE(San_Diego, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND San_Diego NOT LIKE '%na%'
UNION ALL
SELECT 'San Francisco', AVG(REPLACE(REPLACE(San_Francisco, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND San_Francisco NOT LIKE '%na%'
UNION ALL
SELECT 'San Joaquin', AVG(REPLACE(REPLACE(San_Joaquin, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND San_Joaquin NOT LIKE '%na%'
UNION ALL
SELECT 'San Luis Obispo', AVG(REPLACE(REPLACE(San_Luis_Obispo, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND San_Luis_Obispo NOT LIKE '%na%'
UNION ALL
SELECT 'San Mateo', AVG(REPLACE(REPLACE(San_Mateo, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND San_Mateo NOT LIKE '%na%'
UNION ALL
SELECT 'Santa Barbara', AVG(REPLACE(REPLACE(Santa_Barbara, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Santa_Barbara NOT LIKE '%na%'
UNION ALL
SELECT 'Santa Clara', AVG(REPLACE(REPLACE(Santa_Clara, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Santa_Clara NOT LIKE '%na%'
UNION ALL
SELECT 'Santa Cruz', AVG(REPLACE(REPLACE(Santa_Cruz, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Santa_Cruz NOT LIKE '%na%'
UNION ALL
SELECT 'Shasta', AVG(REPLACE(REPLACE(Shasta, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Shasta NOT LIKE '%na%'
UNION ALL
SELECT 'Siskiyou', AVG(REPLACE(REPLACE(Siskiyou, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Siskiyou NOT LIKE '%na%'
UNION ALL
SELECT 'Solano', AVG(REPLACE(REPLACE(Solano, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Solano NOT LIKE '%na%'
UNION ALL
SELECT 'Sonoma', AVG(REPLACE(REPLACE(Sonoma, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Sonoma NOT LIKE '%na%'
UNION ALL
SELECT 'Stanislaus', AVG(REPLACE(REPLACE(Stanislaus, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Stanislaus NOT LIKE '%na%'
UNION ALL
SELECT 'Sutter', AVG(REPLACE(REPLACE(Sutter, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Sutter NOT LIKE '%na%'
UNION ALL
SELECT 'Tehama', AVG(REPLACE(REPLACE(Tehama, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Tehama NOT LIKE '%na%'
UNION ALL
SELECT 'Trinity', AVG(REPLACE(REPLACE(Trinity, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Trinity NOT LIKE '%na%'
UNION ALL
SELECT 'Tulare', AVG(REPLACE(REPLACE(Tulare, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Tulare NOT LIKE '%na%'
UNION ALL
SELECT 'Tuolumne', AVG(REPLACE(REPLACE(Tuolumne, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Tuolumne NOT LIKE '%na%'
UNION ALL
SELECT 'Ventura', AVG(REPLACE(REPLACE(Ventura, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Ventura NOT LIKE '%na%'
UNION ALL
SELECT 'Yolo', AVG(REPLACE(REPLACE(Yolo, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Yolo NOT LIKE '%na%'
UNION ALL
SELECT 'Yuba', AVG(REPLACE(REPLACE(Yuba, ',', ''), '$', '')) FROM housing_data WHERE Mon_Yr LIKE '%-23' AND Mon_Yr <> 'Average_Rounded' AND Yuba NOT LIKE '%na%';

# Make table visible 
ALTER TABLE transposed_housing_data
MODIFY COLUMN my_row_id bigint unsigned NOT NULL AUTO_INCREMENT;

# View transposed_housing_data table to confirm
SELECT * FROM transposed_housing_data;


## Transformations for the Transposed_Housing_Data Table 
# Round the average home price to whole number 
UPDATE Transposed_Housing_Data
SET Home_Price_Average = ROUND(Home_Price_Average);



## Create new table to JOIN home price with average annual salary and average median income 
CREATE TABLE combined_data_with_home_price AS
SELECT 
    cd.*,
    thd.Home_Price_Average
FROM 
    combined_data cd
LEFT JOIN 
    transposed_housing_data thd 
ON 
    UPPER(TRIM(cd.jsl_County)) = UPPER(TRIM(thd.County));
    
    
# View new table
SELECT * FROM combined_data_with_home_price;

# Make table visible 
ALTER TABLE combined_data_with_home_price
MODIFY COLUMN my_row_id bigint unsigned NOT NULL AUTO_INCREMENT;


## Final Transformations on combined_data_with_home_price table

ALTER TABLE combined_data_with_home_price
DROP COLUMN jsl_County;

ALTER TABLE combined_data_with_home_price
CHANGE COLUMN AMI Avg_Median_Income INT;

ALTER TABLE combined_data_with_home_price
CHANGE COLUMN ami_County County VARCHAR(45);


# View combined_data_with_home_price table to confirm the join and alterations 
SELECT * FROM combined_data_with_home_price;


## Final Transformations on combined_data table
# Updates to combined_data table
ALTER TABLE combined_data
DROP COLUMN jsl_County;

ALTER TABLE combined_data
CHANGE COLUMN AMI Avg_Median_Income INT;

ALTER TABLE combined_data
CHANGE COLUMN ami_County County VARCHAR(45);