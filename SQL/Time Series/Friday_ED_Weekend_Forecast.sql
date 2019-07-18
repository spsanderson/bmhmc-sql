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
***********************************************************************
*/

DECLARE @ThisDate DATETIME;
SET @ThisDate = GETDATE(); 

SELECT Arrival AS [Arrival_Date]
, COUNT(ACCOUNT) AS [Arrival_Count]

FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]

WHERE ARRIVAL >= '2010-01-01'
AND ARRIVAL < dateadd(dd, datediff(dd, 0, @ThisDate) - 1, 0)
AND TIMELEFTED != '-- ::00'
AND ARRIVAL != '-- ::00'

GROUP BY ARRIVAL   

ORDER BY ARRIVAL
;