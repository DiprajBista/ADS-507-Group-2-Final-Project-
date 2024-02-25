# ADS-507-Group-2-Final-Project-

# California State Jobs Data Pipeline 

The primary objective of this project is to create a project pipeline to provide information on the California state job market. Data is exported from the three sources listed in the repository and then loaded into the landing database. In the landing database, the data is transformed via several mysql commands and the final tables are then loaded into the destination database for analysis. In the destination database, a dashboard is launched to capture the trends of public service employment and income distribution of California. The pipeline needs proper deployment and monitoring with the inclusion of new data. With the help of SQL queries, we seek to discover the trends, similarities, disparities and pattern in the salaries of state jobs and median average income of different counties and how that related to the average cost of real estate in the respective counties. The big counties such as Santa Clara, San Franciso, etc. have different median average income compared with the smaller counties as Yuba, Sutter, etc. The other objectives of this project is to find the disparities between the posted job salaries and average median salaries of the county. It would be interesting to find the highest paying careers and economic characteristics of the particular county. The trends captured form the county might not represent the state. 


This repository contains the 4 csv files that were used to create out data pipeline as listed below: 

California State Jobs csv from Kaggle.com - https://www.kaggle.com/datasets/datasciencedonut/california-state-jobs <br> 
2023 Income Limits by County from CA.gov website - https://data.ca.gov/dataset/income-limits-by-county <br>
Median Prices of Existing Single Family Homes - https://www.car.org/en/marketdata/data/housingdata <br>
      Note: There was a manual deletion of the first 7 lines from the Median Prices of Existing Single Family Homes file and csv conversion before loading into mysql workbench <br>
The repository also contains a Income Limits Data Dictionary that was obatined from https://data.ca.gov/dataset/income-limits-by-county which explains the column names for the 2023 Income Limits by County csv. <br> 

There is a finalproject_azure.sql file which outlines the data extraction, loading and transformation processes that were performed to build the database. <br>
The adsfinalproject.ipynb file contains all of the data analysis, visualizations and build of the dashboard used for the project. <br>
There is a JSON file (template.json) that was exported from Microsoft Azure which defines the infastructure and configuration of the database. <br>

The database is being stored on a Microsoft Azure server and can be accessed with the following credentials: <br>
Host ID: jobsfinal507.mysql.database.azure.com <br>
Username: admin507 <br>
Password: finalproject507! <br>
