SELECT DISTINCTROW UCase(ALOS.[Doctor Name]) AS [Doctor Name]
, UCase(ALOS.[LAST NAME LINK])
, Round(Avg(ALOS.[Actual Measure Performance/Case]),2) AS [Avg / Case]
, Round(Avg(ALOS.[Expected Measure Performance/Case]),2) AS [Expected Avg / Case]
, Round(Avg(ALOS.[Performance Index]),2) AS [Avg Index]
, Round(Avg(ALOS.[Total Opportunity]),2) AS [Avg Opportunity] 

INTO [ALOS TOTALS REPORT TABLE]

FROM ALOS
WHERE ALOS.[Discharge Quarter (YYYYqN)]='2013q3'
GROUP BY ALOS.[Doctor Name]
, ALOS.[LAST NAME LINK];
