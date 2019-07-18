-- JTM Daily Log for Today()-1
-- 
--*********************************************************************************

-- Declare Variables
DECLARE @RPTS AS DATETIME, @RPTE AS DATETIME

-- Initialize Variables
SET @RPTS = '1/1/12';
SET @RPTE = '1/1/13';

-- Column Selection
SELECT 
	(SELECT COUNT(dt_ARRIVAL)
	 
	 -- Database Used: Medhost
	 FROM dbo.JTM_GENERIC_LIST_V
	 
	 -- Filters
	 WHERE DT_ARRIVAL BETWEEN @RPTS AND @RPTE
	 ) AS 'ED Visits'

--*********************************************************************************
-- End Report
-- Sanderson, Steven 3.25.13