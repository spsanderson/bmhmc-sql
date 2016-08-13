DECLARE @SVC_DATES TABLE (
       [File Arrived] DATE
);

WITH CTE1 AS (
       SELECT DISTINCT([File Arrived]) AS SVC_DATE
       FROM SMSDSS.c_wound_care_daily_batch
)

INSERT INTO @SVC_DATES
SELECT * FROM CTE1
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
SELECT * FROM CTE1

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
SELECT * FROM CTE1

--SELECT * FROM @BWC
-----------------------------------------------------------------------

SELECT CAST(A.[File Arrived] AS DATE) AS [File Arrived]
, ISNULL(B.[Count], 0)                AS [Hauppauge Count]
, ISNULL(C.[Count], 0)                AS [Patchogue Count]
, (
  ISNULL(C.[COUNT], 0) + 
  ISNULL(B.[COUNT], 0)
  )                                   AS [Total]


FROM @SVC_DATES  AS A
LEFT JOIN @HAUPP AS B
ON A.[File Arrived] = B.[File Arrived]
LEFT JOIN @BWC AS C
ON A.[File Arrived] = C.[File Arrived]

GROUP BY A.[File Arrived]
, B.[Count]
, C.[Count]

ORDER BY CAST(a.[File Arrived] AS DATE)
