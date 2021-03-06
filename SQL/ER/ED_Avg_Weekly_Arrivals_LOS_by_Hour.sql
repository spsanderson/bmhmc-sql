/*
***********************************************************************
File: ED_Avg_Weekly_Arrivals_LOS_by_Hour.sql

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
	Get arrivals and avg_time_here by hour of arrival to the ed for
	some specified period of time

Revision History:
Date		Version		Description
----		----		----
2019-03-05	v1			Initial Creation
***********************************************************************
*/

DECLARE @START DATE;
DECLARE @END   DATE;
DECLARE @TODAY DATE;

SET @TODAY = CAST(GETDATE() AS date);
SET @START = DATEADD(WEEK, DATEDIFF(WEEK, 0, @TODAY)-1, -1);
SET @END   = DATEADD(WEEK, DATEDIFF(WEEK, 0, @TODAY), -1);

SELECT DATEPART(HOUR, arrival) AS [arrival_hour]
, AVG(DATEDIFF(HOUR, CAST(ARRIVAL AS datetime), CAST(TIMELEFTED AS datetime))) AS [avg_time_here]
, COUNT(account) / 7.0 AS [avg_hrl_arr]

FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]

WHERE ARRIVAL >= @START
AND ARRIVAL < @END
AND TIMELEFTED != '-- ::00'

GROUP BY DATEPART(HOUR, arrival)

ORDER BY DATEPART(HOUR, arrival)
;
