-- Patients that come into the ER and Expire for a specified date range
--*********************************************************************************

-- Variable Declaration
DECLARE @Report_day INT, @Report_month INT, @Report_year INT;

-- Initialize the variable.
SET @Report_month = 3;
SET @Report_year=2013;

-- Column Selection
SELECT s_PATIENT_FULL_NAME AS 'Name', s_VISIT_IDENT AS 'Acct Num', n_OUTCOME_ID AS 'Outcome', 
s_OUTCOME_LOCATION AS 'End Loc', s_DIAGNOSIS AS 'Dx', s_COMPLAINT AS 'Complaint'

-- Database Used: Medhost
FROM dbo.JTM_GENERIC_LIST_V

-- Filters
WHERE n_OUTCOME_ID = 6 
AND DATEPART(month,dt_ARRIVAL)=@Report_month 
AND DATEPART(year,dt_ARRIVAL)=@Report_year
ORDER BY s_PATIENT_FULL_NAME

--*********************************************************************************
-- End Report
-- Sanderson, Steven 1.4.12