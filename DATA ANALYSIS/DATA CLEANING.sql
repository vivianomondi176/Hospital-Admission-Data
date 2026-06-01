--point the script to the right database
USE AutoCareDB
GO;

--create a view from the clean data
CREATE OR ALTER VIEW vw_Admissiondata AS
--create a CTE called 'cleandata' to extact all duplicates
WITH CleanData AS(
--use window function to identify and select all duplicate data as duplicate
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY MRD_No, D_O_A, D_O_D ORDER BY MRD_No) AS duplicate
FROM [AutoCareDB].[dbo].[HDHI Admission data.csv]
--ORDER BY MRD_No
)
--use where clause to filter and generate non duplicate data
SELECT *
FROM CleanData
WHERE MRD_No IS NOT NULL AND duplicate = 1
--ORDER BY MRD_No
;
