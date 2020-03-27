/*
***********************************************************************
File: wound_care_daily_acknowledgement.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_wound_care_daily_batch

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Capture files arrived by date, show null for those dates no files
	had arrived

Revision History:
Date		Version		Description
----		----		----
2019-01-22	v1			Initial Creation
2019-01-25	v2			Change @ENDDATE to CAST(GETDATE() -1 AS date)
2020-03-26  v3          Cast File_Date AS date
***********************************************************************
*/
DECLARE @STARTDATE DATETIME;
DECLARE @ENDDATE   DATETIME;

SET @STARTDATE = (SELECT MIN(CAST([FILE ARRIVED] AS date)) FROM smsdss.c_wound_care_daily_batch);
--SET @ENDDATE   = (SELECT MAX(CAST([FILE ARRIVED] AS date)) FROM smsdss.c_wound_care_daily_batch);
SET @ENDDATE   = CAST(GETDATE() -1 AS date);

DECLARE @SVC_DATES TABLE (
       [File_Date] DATE
);

WITH CTE1 AS (
       SELECT DISTINCT([File Arrived]) AS SVC_DATE
       FROM SMSDSS.c_wound_care_daily_batch
)

INSERT INTO @SVC_DATES
SELECT * FROM CTE1;
-----------------------------------------------------------------------

DECLARE @HAUPP TABLE (
       [File Arrived] DATE
       , [Count]      INT
);

WITH CTE1 AS (
       SELECT CAST([File Arrived] AS DATE) AS [File Arrived]
       , COUNT([ACCOUNT NUMBER]) AS [# Of Encounters]

       FROM smsdss.c_wound_care_daily_batch

       WHERE [Location] = 'FMSBRHAUPP'

       GROUP BY CAST([File Arrived] AS DATE)
)

INSERT INTO @HAUPP
SELECT * FROM CTE1;

--SELECT * FROM @HAUPP
-----------------------------------------------------------------------

DECLARE @BWC TABLE (
       [File Arrived] DATE
       , [Count]      INT
);

WITH CTE1 AS (
       SELECT CAST([File Arrived] AS DATE) AS [File Arrived]
       , COUNT([account number]) AS [# Of Encounters]

       FROM smsdss.c_wound_care_daily_batch

       WHERE [Location] = 'FMSBWC'

       GROUP BY CAST([File Arrived] AS DATE)
)

INSERT INTO @BWC
SELECT * FROM CTE1;

--SELECT * FROM @BWC
-----------------------------------------------------------------------
DECLARE @HAUPP_LOADED TABLE (
	[File Loaded] DATE
	, [Count]     INT
);

WITH CTE1 AS (
	SELECT CAST([File Loaded] AS DATE) AS [File Loaded]
	, COUNT([Account Number]) AS [# Of Encounters]
	
	FROM smsdss.c_wound_care_daily_batch
	
	WHERE [Location] = 'FMSBRHAUPP'
	
	GROUP BY CAST([File Loaded] AS DATE)
)

INSERT INTO @HAUPP_LOADED
SELECT * FROM CTE1;
-----------------------------------------------------------------------
DECLARE @BWC_LOADED TABLE (
	[File Loaded] DATE
	, [Count]     INT
);

WITH CTE1 AS (
	SELECT CAST([File Loaded] AS DATE) AS [File Loaded]
	, COUNT([Account Number]) AS [# Of Encounters]
	
	FROM smsdss.c_wound_care_daily_batch
	
	WHERE [Location] = 'FMSBWC'
	
	GROUP BY CAST([File Loaded] AS DATE)
)

INSERT INTO @BWC_LOADED
SELECT * FROM CTE1;
-----------------------------------------------------------------------
WITH CALENDARDATES AS (
	SELECT SVC_DATE = @STARTDATE
	UNION ALL
	SELECT DATEADD(DAY, 1, SVC_DATE)
	FROM CALENDARDATES
	WHERE DATEADD(DAY, 1, SVC_DATE) <= @ENDDATE
)

SELECT CAST(ZZZ.SVC_DATE AS date)     AS [File_Date]
, ISNULL(B.[Count], 0)                AS [Hauppauge Arrived Count]
, ISNULL(C.[Count], 0)                AS [Patchogue Arrived Count]
, (
  ISNULL(C.[COUNT], 0) + 
  ISNULL(B.[COUNT], 0)
  )                                   AS [Total Arrived Count]
, ISNULL(D.[Count], 0)                AS [Hauppauge Loaded Count]
, ISNULL(E.[Count], 0)                AS [Patchogue Loaded Count]
, (
  ISNULL(D.[Count], 0) +
  ISNULL(E.[Count], 0)
  )                                   AS [Total Loaded Count]

FROM @SVC_DATES         AS A
LEFT JOIN @HAUPP        AS B
ON A.[File_Date] = B.[File Arrived]
LEFT JOIN @BWC          AS C
ON A.[File_Date] = C.[File Arrived]
LEFT JOIN @HAUPP_LOADED AS D
ON A.[File_Date] = D.[File Loaded]
LEFT JOIN @BWC_LOADED   AS E
ON A.[File_Date] = E.[File Loaded]
RIGHT OUTER JOIN CALENDARDATES AS ZZZ
ON A.File_Date = ZZZ.SVC_DATE

GROUP BY ZZZ.SVC_DATE
, A.[File_Date]
, B.[Count]
, C.[Count]
, D.[Count]
, E.[Count]

ORDER BY CAST(ZZZ.SVC_DATE AS DATE) DESC

OPTION (MAXRECURSION 0)
;