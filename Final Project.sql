SELECT * FROM cal_career.calcareer;

UPDATE calcareer
SET Salary_Range = REPLACE(Salary_Range, '$', '')

SELECT * FROM cal_career.calcareer;

-- Adding new columns for minimum, maximum, and average salary.
ALTER TABLE calcareer
ADD COLUMN Min_Salary DECIMAL(10, 2),
ADD COLUMN Max_Salary DECIMAL(10, 2),
ADD COLUMN Avg_Salary DECIMAL(10, 2);

-- Filling new columns with min, max and average values.
UPDATE calcareer
SET Min_Salary = SUBSTRING_INDEX(Salary_Range, ' - ', 1),
    Max_Salary = SUBSTRING_INDEX(SUBSTRING_INDEX(Salary_Range, ' - ', -1), ' ', 1),
    Avg_Salary = (SUBSTRING_INDEX(Salary_Range, ' - ', 1) + SUBSTRING_INDEX(SUBSTRING_INDEX(Salary_Range, ' - ', -1), ' ', 1)) / 2;

# Sort to observe the Permanent Fulltime Employee to obtail the average salary range.
SELECT *
FROM calcareer
WHERE WorkType_Schedul = 'Permanent Fulltime';
 
 # We are removing the United States from the data of location so that we can only work with County average salary.
 # Also, we are only considering the Permanent Fulltime employee to compare it with income data salary.
SELECT
    SUBSTRING_INDEX(Location, ' ', -1) AS County,
    AVG(Avg_Salary) AS Average_Salary
FROM
    calcareer
WHERE
    WorkType_Schedul = 'Permanent Fulltime'
    AND Location NOT LIKE '%United States%'
GROUP BY
    County;
    
    
# We are using this query to obtain the average salary for permanent fulltime employee for each county. 
SELECT location, AVG(avg_salary) AS average_salary
FROM calcareer
WHERE WorkType_Schedul = 'Permanent Fulltime'
GROUP BY location;

# Create the table for the county location and its respective average salary
CREATE TABLE adjusted_average_salary (
    location VARCHAR(255),
    average_salary DECIMAL(10, 2)
);

-- Using the avobe calcualted value of average salary with respect to its location to fill the tables 
INSERT INTO adjusted_average_salary (location, average_salary)
SELECT location, AVG(avg_salary) AS average_salary
FROM calcareer
WHERE WorkType_Schedul = 'Permanent Fulltime'
GROUP BY location;

# Tidy the location table by removing county from location name
UPDATE adjusted_average_salary
SET location = REPLACE(location, ' County', '');

# Join the both tables to compare average salary from cal career and county income limit

SELECT a.location,
       a.average_salary,
       b.Median_Income AS income_limit
FROM adjusted_average_salary AS a
JOIN income_limit AS b ON a.location = b.county;






























