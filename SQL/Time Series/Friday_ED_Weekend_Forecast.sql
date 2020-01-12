/*
***********************************************************************
File: Friday_ED_Weekend_Forecast.sql

Input Parameters:
	None

Tables/Views:
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Entere Here

Revision History:
Date		Version		Description
----		----		----
2019-06-21	v1			Initial Creation
2020-01-07	v2			Group by Date and Hour
***********************************************************************
*/

DECLARE @ThisDate DATETIME;
SET @ThisDate = GETDATE(); 

SELECT DATEADD(HOUR, DATEDIFF(HOUR, 0, Arrival), 0) AS [Arrival_Date]
, COUNT(ACCOUNT) AS [Arrival_Count]

FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]

WHERE Arrival >= '2010-01-01'
AND Arrival < dateadd(dd, datediff(dd, 0, @ThisDate) - 1, 0)
AND TIMELEFTED != '-- ::00'
AND Arrival != '-- ::00'

GROUP BY DATEADD(HOUR, DATEDIFF(HOUR, 0, Arrival), 0)

ORDER BY DATEADD(HOUR, DATEDIFF(HOUR, 0, Arrival), 0)
;