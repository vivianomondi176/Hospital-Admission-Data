SELECT *
FROM [AutoCareDB].[dbo].[vw_Admissiondata]


--Total discharge
--primary indicator of operational throughput
SELECT COUNT(*) as Total_discharge
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
WHERE OUTCOME = 'Discharge'


--Average daily discharge rate
--it is total discharges divided by total length of stay * 100
--This metric allows management to mathematically balance the Admission-to-Discharge equilibrium, forecast bed availability, and eliminate administrative bottlenecks that delay room sanitation and billing clearance.
 SELECT
(SELECT COUNT(*) as Total_discharges
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
WHERE OUTCOME = 'DISCHARGE') / (SELECT SUM(DURATION_OF_STAY) AS Total_length_of_stay
FROM [AutoCareDB].[dbo].[vw_Admissiondata])
--casting this
SELECT 
  CAST(
     CAST((SELECT COUNT(*) AS Total_discharges
     FROM [AutoCareDB].[dbo].[vw_Admissiondata]
     WHERE OUTCOME = 'DISCHARGE') AS FLOAT)/
     CAST ((SELECT SUM(DURATION_OF_STAY) AS Total_length_of_stay
     FROM [AutoCareDB].[dbo].[vw_Admissiondata]) AS FLOAT)
 AS DECIMAL (10,2) )* 100 AS Avg_DailyDischargeRate

 --OR 
 SELECT 
   ROUND(SUM(CASE WHEN OUTCOME = 'DISCHARGE' THEN 1.0 ELSE 0.0 END) /
   SUM(DURATION_OF_STAY), 2) * 100 AS Avg_DailyDischargeRate
   FROM [AutoCareDB].[dbo].[vw_Admissiondata]


--Average length of stay 
--It is the total length of stay divided by the total discharges 
--A lower ALOS means beds empty out faster, allowing the hospital to admit new patients without building expensive new wards. If ALOS climbs, it causes "bed blocking" and emergencies get backed up in the waiting room.
SELECT 
ROUND(SUM(DURATION_OF_STAY) / 
SUM(CASE WHEN OUTCOME = 'DISCHARGE' THEN 1.0 ELSE 0.0 END), 0) AS Average_length_of_stay
FROM [AutoCareDB].[dbo].[vw_Admissiondata]


--Distribution of discharges by Age group
--Predicting Hospital Readmissions
--Prioritize Resource Allocation & Clinical Specialization
SELECT 
   CASE 
   WHEN AGE <= 16 THEN 'Peadriatic'
   WHEN AGE BETWEEN 17 AND 64 THEN 'adult'
   WHEN AGE >= 65 THEN 'Senior Citizen'
     ELSE 'Unknown'
       END AS Age_group, COUNT(*) AS Age_Distribution
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
WHERE OUTCOME = 'DISCHARGE'
GROUP BY CASE 
   WHEN AGE <= 16 THEN 'Peadriatic'
   WHEN AGE BETWEEN 17 AND 64 THEN 'adult'
   WHEN AGE >= 65 THEN 'Senior Citizen'
     ELSE 'Unknown'
       END 
ORDER BY 2 DESC


--Distribution of discharge by gender 
--Tracking whether stay patterns differ heavily between genders helps managers build accurate predictive models,
--for bed availability and streamline post-discharge recovery planning frameworks.
SELECT GENDER, COUNT(*) AS Age_distribution
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
WHERE OUTCOME = 'DISCHARGE'
GROUP BY GENDER


--Distribution of discharge by day of the week
SELECT DATEPART(WEEKDAY, D_O_D) AS Day_of_week, COUNT(*) AS Day_Distribution
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
WHERE OUTCOME = 'DISCHARGE'
GROUP BY DATEPART(WEEKDAY, D_O_D)
ORDER BY 2 DESC
--Get date name
SELECT FORMAT(D_O_D, 'ddd') AS Day_of_week, COUNT(*) AS Day_Distribution
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
WHERE OUTCOME = 'DISCHARGE'
GROUP BY FORMAT(D_O_D, 'ddd')
ORDER BY 2 DESC


--To highlight demographic group that are most vulnerable
--transitions hospital administration from reactive patient care to proactive population health management.
SELECT 
    CASE 
        WHEN AGE < 18 THEN 'Pediatric'
        WHEN AGE BETWEEN 18 AND 45 THEN 'Young Adult'
        WHEN AGE BETWEEN 46 AND 65 THEN 'Middle Aged'
        ELSE 'Senior'
    END AS Age_Group,
    COUNT(*) AS Total_Patients,
    ROUND(AVG(DURATION_OF_STAY), 2) AS Avg_Stay,
    ROUND(SUM(CASE WHEN OUTCOME = 'EXPIRY' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Mortality_Rate
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
GROUP BY CASE 
        WHEN AGE < 18 THEN 'Pediatric'
        WHEN AGE BETWEEN 18 AND 45 THEN 'Young Adult'
        WHEN AGE BETWEEN 46 AND 65 THEN 'Middle Aged'
        ELSE 'Senior'
    END 
ORDER BY Mortality_Rate DESC;


-- Identifying the top 5 longest-staying patients per Age Group
--Helps in Identifying "Long-Stay" Outliers & Bed-Blocking Drivers
WITH Ranked AS(
SELECT 
        MRD_No AS Patient_ID,
        AGE,
        CASE WHEN AGE < 60 THEN 'Under 60' ELSE '60 and Over' END AS Age_Group,
        DURATION_OF_STAY AS Stay_Duration,
        RANK() OVER(PARTITION BY CASE WHEN AGE < 60 THEN 'Under 60' ELSE '60 and Over' END 
                    ORDER BY "DURATION_OF_STAY" DESC) as Stay_Rank
    FROM [AutoCareDB].[dbo].[vw_Admissiondata]
    )
SELECT TOP 5
    Patient_ID,
    Age_Group,
    Stay_Duration,
    Stay_Rank
    FROM Ranked ;
   

--calculating the month-over-month growth of admissions.
--calculating the growth rate of admissions month by month using the LAG window function.
--Month-over-Month (MoM) Growth is the ultimate metric for tracking Operational Velocity and Capacity Scaling
WITH MonthlyStats AS (
    SELECT 
        -- Truncating date to the first of the month
        DATEADD(MONTH, DATEDIFF(MONTH, 0, TRY_CONVERT(DATE, D_O_A, 103)), 0) AS Admission_Month,
        COUNT(*) AS Monthly_Count
    FROM [AutoCareDB].[dbo].[vw_Admissiondata]
    GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, TRY_CONVERT(DATE, D_O_A, 103)), 0)
)
SELECT 
    Admission_Month,
    Monthly_Count,
    LAG(Monthly_Count) OVER (ORDER BY Admission_Month) AS Previous_Month_Count,
    -- Calculating % change
    CAST(((Monthly_Count - LAG(Monthly_Count) OVER (ORDER BY Admission_Month)) * 100.0) / 
    NULLIF(LAG(Monthly_Count) OVER (ORDER BY Admission_Month), 0) AS DECIMAL(10,2)) AS Growth_Rate_Pct
FROM MonthlyStats
ORDER BY Admission_Month;


--query to check if patients with both Diabetes (DM) and Hypertension (HTN),
--have a significantly higher rate of Acute Kidney Injury (AKI) compared to those without.
SELECT 
    DM, 
    HTN,
    COUNT(*) AS Total_Patients,
    -- Fix: Cast AKI to an Integer so SQL Server can sum it
    SUM(CAST(AKI AS INT)) AS AKI_Cases,
    -- For AVG, multiplying by 100.0 usually auto-converts it, 
    -- but we'll be explicit to be safe
    CAST(AVG(CAST(AKI AS FLOAT) * 100.0) AS DECIMAL(10,2)) AS AKI_Incidence_Rate,
    CAST(AVG(DURATION_OF_STAY * 1.0) AS DECIMAL(10,2)) AS Avg_Total_Stay
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
GROUP BY DM, HTN
ORDER BY DM DESC, HTN DESC;


--Analyze the impact of "Triple Threat" conditions (Diabetes, Hypertension, and CKD) on intensive unit stay duration.
--This query focuses on specific high-risk sub-populations, how specific comorbidities significantly increase the burden on hospital resources (ICU time).
SELECT 
    DM, HTN, CKD,
    COUNT(*) AS Patient_Count,
    ROUND(AVG(duration_of_intensive_unit_stay), 2) AS Avg_ICU_Stay,
    ROUND(AVG(DURATION_OF_STAY), 2) AS Total_Avg_Stay
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
WHERE DM = 1 AND HTN = 1 AND CKD = 1
GROUP BY DM, HTN, CKD;


--To predict how many beds and nurses they will need next month. we use ROWS BETWEEN windowing clause.
--If a hospital sees a sudden jump in patients in December, the moving average helps them see if it's a trend or just a one-time event.
WITH MonthlyCounts AS (
    SELECT 
        DATEADD(MONTH, DATEDIFF(MONTH, 0, TRY_CONVERT(DATE, D_O_A, 103)), 0) AS Admission_Month,
        COUNT(*) AS Monthly_Admissions
    FROM [AutoCareDB].[dbo].[vw_Admissiondata]
    GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, TRY_CONVERT(DATE, D_O_A, 103)), 0)
)
SELECT 
    Admission_Month,
    Monthly_Admissions,
    -- Calculating the average of the current month + the 2 months before it
    AVG(Monthly_Admissions) OVER (
        ORDER BY Admission_Month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS [3_Month_Moving_Avg]
FROM MonthlyCounts;


--Identifying "Cardio-Renal" Patients
--This helps doctors prioritize patients. 
--A patient with both issues is much more likely to have a long stay or high mortality.
SELECT 
    MRD_No AS Patient_ID,
    AGE,
    HEART_FAILURE AS Has_Heart_Failure,
    TRY_CAST(CREATININE AS FLOAT) AS Creatinine_Level,
    CASE 
        WHEN HEART_FAILURE = 1 AND TRY_CAST(CREATININE AS FLOAT) > 1.5 THEN 'High Risk: Cardio-Renal'
        WHEN HEART_FAILURE = 1 THEN 'Heart Failure Only'
        WHEN TRY_CAST(CREATININE AS FLOAT) > 1.5 THEN 'Renal Issue Only'
        ELSE 'Stable'
    END AS Clinical_Profile
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
WHERE HEART_FAILURE = 1 OR TRY_CAST(CREATININE AS FLOAT) > 1.5;


--Comparing Admission Type to Outcome
--This query confirms if the hospital's Emergency department is handling higher-risk cases effectively.
SELECT 
    TYPE_OF_ADMISSION_EMERGENCY_OPD AS Admission_Type,
    COUNT(*) AS Total_Patients,
    -- Counting specific outcomes for each admission type
    SUM(CASE WHEN OUTCOME = 'DISCHARGE' THEN 1 ELSE 0 END) AS Discharged,
    SUM(CASE WHEN OUTCOME = 'EXPIRY' THEN 1 ELSE 0 END) AS Deceased,
    SUM(CASE WHEN OUTCOME = 'LAMA' THEN 1 ELSE 0 END) AS Left_Against_Advice,
    -- Percentage of successful discharges
    CAST(SUM(CASE WHEN OUTCOME = 'DISCHARGE' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(10,2)) AS Success_Rate_Pct
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
GROUP BY TYPE_OF_ADMISSION_EMERGENCY_OPD;



--Data Integrity Query:Finding "Impossible" Records
--Now that the clinical insights are complete, this final section serves as a Data Quality Audit. 
--The query below was engineered to catch systemic data-entry errors where the recorded length of stay does not mathematically match the calendar dates."
SELECT 
    MRD_No AS Patient_ID,
    D_O_A AS Admit_Date,
    D_O_D AS Discharge_Date,
    DURATION_OF_STAY AS Recorded_Stay,
    DATEDIFF(DAY, TRY_CONVERT(DATE, D_O_A, 103), TRY_CONVERT(DATE, D_O_D, 103)) AS Calculated_Stay
FROM [AutoCareDB].[dbo].[vw_Admissiondata]
WHERE DATEDIFF(DAY, TRY_CONVERT(DATE, D_O_A, 103), TRY_CONVERT(DATE, D_O_D, 103)) != DURATION_OF_STAY
   OR TRY_CONVERT(DATE, D_O_A, 103) > TRY_CONVERT(DATE, D_O_D, 103);
