SELECT Arrival AS [Arrival_Date]
, COUNT(ACCOUNT) AS [Arrival_Count]

FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]

WHERE ARRIVAL >= '2010-01-01'
AND ARRIVAL < '2019-03-01'
AND TIMELEFTED != '-- ::00'
AND ARRIVAL != '-- ::00'

GROUP BY ARRIVAL   

ORDER BY ARRIVAL
;