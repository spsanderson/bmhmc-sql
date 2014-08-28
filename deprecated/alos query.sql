SELECT UCase(ALOS.[Doctor Name]) AS [Doctor Name]
, UCase(ALOS.[LAST NAME LINK]) AS [LAST NAME LINK]
, ALOS.[Severity of Illness]
, Count(ALOS.[Patient Account]) AS [Patient Count]
, Round(Avg(ALOS.[Actual Measure Performance/Case]),2) AS [Actual ALOS]
, Round(Avg(ALOS.[Expected Measure Performance/Case]),2) AS [Expected ALOS]
, Round(Avg(ALOS.[Performance Index]),2) AS [Avg Index]
, Round(Avg(ALOS.[Total Opportunity]),2) AS [Avg Opportunity] 

INTO [ALOS REPORT TABLE]

FROM ALOS
WHERE ALOS.[Discharge Quarter (YYYYqN)]='2013q3'
GROUP BY ALOS.[Doctor Name]
, ALOS.[LAST NAME LINK]
, ALOS.[Severity of Illness];
