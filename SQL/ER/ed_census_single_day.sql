/*
***********************************************************************
File: ed_census_single_day.sql

Input Parameters:
	none

Tables/Views:
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]

Creates Table:
	none

Functions:
	none

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get ED Census for a single day from hour 0 through 23

Revision History:
Date		Version		Description
----		----		----
2020-06-03	v1			Initial Creation
***********************************************************************
*/

/*
For a single 24 hour period
*/
SELECT Arrival
, CASE
	WHEN TimeLeftED = '-- ::00'
		THEN NULL
		ELSE TimeLeftED
  END AS [Departure]
INTO #TEMPA
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
WHERE ARRIVAL >= '2020-04-01'
AND ARRIVAL < '2020-04-02';

DECLARE @CensusHour TABLE (
	Cen_Hr INT NOT NULL
	)
INSERT INTO @CensusHour VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23)

SELECT Cen_Hr,
COUNT(*) AS [Census]
FROM #TEMPA AS A
INNER JOIN @CensusHour AS B
ON B.Cen_Hr BETWEEN DATEPART(HOUR, Arrival) AND DATEPART(HOUR, Departure)
GROUP BY B.Cen_Hr;

DROP TABLE #TEMPA;