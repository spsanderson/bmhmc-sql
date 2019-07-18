-- ED Stats for a specified date range
-- 
--*********************************************************************************

-- Variable Declaration
DECLARE @Report_day INT, @Report_month INT, @Report_year INT;

-- Initialize the variable.
SET @Report_month = 3;
SET @Report_year=2013;

-- Column Selection
-- Databse Used: Medhost (Database Chosen inside of the second select statement)
SELECT 
	(SELECT COUNT(s_VISIT_IDENT) 
		FROM dbo.JTM_GENERIC_LIST_V
		WHERE n_OUTCOME_ID = 1 AND DATEPART(month,dt_ARRIVAL)=@Report_month AND DATEPART(year,dt_ARRIVAL)=@Report_year)	
		AS '# pts Admitted',
	(SELECT COUNT(s_VISIT_IDENT) 
		FROM dbo.JTM_GENERIC_LIST_V
		WHERE n_OUTCOME_ID = 3 AND DATEPART(month,dt_ARRIVAL)=@Report_month AND DATEPART(year,dt_ARRIVAL)=@Report_year)
		AS '# pts Transfer',
	(SELECT COUNT(s_VISIT_IDENT)
		FROM dbo.JTM_GENERIC_LIST_V
		WHERE n_OUTCOME_ID = 2 AND DATEPART(month,dt_ARRIVAL)=@Report_month AND DATEPART(year,dt_ARRIVAL)=@Report_year)	
		AS '# pts Discharged',
    (SELECT COUNT(s_VISIT_IDENT) 
		FROM dbo.JTM_GENERIC_LIST_V
		WHERE n_OUTCOME_ID = 5 AND DATEPART(month,dt_ARRIVAL)=@Report_month AND DATEPART(year,dt_ARRIVAL)=@Report_year)	
		AS '# pts AMA',
	(SELECT COUNT(s_VISIT_IDENT) 
		FROM dbo.JTM_GENERIC_LIST_V
		WHERE n_OUTCOME_ID = 8 AND DATEPART(month,dt_ARRIVAL)=@Report_month AND DATEPART(year,dt_ARRIVAL)=@Report_year)
		AS '# pts LWBS/LTOT',	
	(SELECT COUNT(s_VISIT_IDENT) 
		FROM dbo.JTM_GENERIC_LIST_V
		WHERE n_OUTCOME_ID = 6 AND DATEPART(month,dt_ARRIVAL)=@Report_month AND DATEPART(year,dt_ARRIVAL)=@Report_year)
		AS '# pts Expired',    
	(SELECT COUNT(s_VISIT_IDENT) 
		FROM dbo.JTM_GENERIC_LIST_V
		WHERE n_OUTCOME_ID = 0 AND DATEPART(month,dt_ARRIVAL)=@Report_month AND DATEPART(year,dt_ARRIVAL)=@Report_year)
		AS '# pts Unknown',  
	(SELECT COUNT(s_VISIT_IDENT) 
		FROM dbo.JTM_GENERIC_LIST_V
		WHERE n_OUTCOME_ID IS NULL AND DATEPART(month,dt_ARRIVAL)=@Report_month AND DATEPART(year,dt_ARRIVAL)=@Report_year)	
		AS 'NULL',
	(SELECT COUNT(s_VISIT_IDENT) 
		FROM dbo.JTM_GENERIC_LIST_V
		WHERE DATEPART(month,dt_ARRIVAL)=@Report_month AND DATEPART(year,dt_ARRIVAL)=@Report_year)	
		AS'# pts',
	(SELECT AVG(n_ARR_TO_DEP)
		FROM dbo.JTM_GENERIC_LIST_V
		WHERE DATEPART(month,dt_ARRIVAL)=@Report_month AND DATEPART(year,dt_ARRIVAL)=@Report_year)	
		AS 'AVG TAT'

--*********************************************************************************
-- End Report
-- Sanderson, Steven 1.2.12

--******************************************************************************************
--  n_OUTCOME_ID CODES
--   1 - ADMIT
--   2 - DISCHARGE
--   3 - TRANSFER
--   5 - AMA
--   6 - EXPIRED
--   8 - LWBS and S_OUTCOME_LOCATION = Eloped:LWBS
--   8 - LWOT nd S_OUTCOME_LOCATION = Eloped:LWOT
--   0 - UNKNOWN