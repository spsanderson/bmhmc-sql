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

SELECT CAST(A.[File_Date] AS DATE) AS [File_Date]
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

GROUP BY A.[File_Date]
, B.[Count]
, C.[Count]
, D.[Count]
, E.[Count]

ORDER BY CAST(a.[File_Date] AS DATE) DESC;
