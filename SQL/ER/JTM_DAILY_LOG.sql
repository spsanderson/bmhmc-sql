-- JTM Daily Log for Today()-1
-- 
--*********************************************************************************

-- Declare Variables
DECLARE @M AS INT, @D AS INT, @Y AS INT

-- Initialize Variables
SET @M = 4;
SET @D = 4;
SET @Y = 2013;

-- Column Selection
SELECT 
	(SELECT COUNT(dt_ARRIVAL)
	 -- Database Used: Medhost
	 FROM dbo.JTM_GENERIC_LIST_V
	 
	 -- Filters
	 WHERE DATEPART(month,dt_ARRIVAL) = @M
	 AND DATEPART(day,dt_ARRIVAL) = @D
	 AND DATEPART(year,dt_ARRIVAL) = @Y
	 ) AS 'ED Visits'

--*********************************************************************************
-- End Report
-- Sanderson, Steven 1.8.13