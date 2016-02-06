DECLARE @START DATE, @END DATE;
SET @START = '2015-12-01';
SET @END   = '2016-01-01';

DECLARE @SepsisDX_Final TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	--, DX_Eff_Date         DATE
	--, RN                  INT
);

WITH CTE1 AS (
	SELECT DISTINCT(PtNo_Num)
	--, Clasf_Eff_Date
	--, ROW_NUMBER() OVER (
	--					PARTITION BY PTNO_NUM
	--					ORDER BY PTNO_NUM
	--					) AS [RN]

	FROM SMSDSS.BMH_PLM_PtAcct_Clasf_Dx_V

	WHERE (
		ClasfCd in (
		'A02.1', 'A22.7', 'A26.7', 'A32.7', 'A40', 'A40.0', 'A40.1', 'A40.3',
		'A40.8', 'A40.9', 'A41', 'A41.0', 'A41.01', 'A41.02', 'A41.1', 'A41.2',
		'A41.3', 'A41.4', 'A41.5', 'A41.50', 'A41.51', 'A41.52', 'A41.53',
		'A41.59', 'A41.8', 'A41.81', 'A41.89', 'A41.9', 'A42.7', 'A54.86', 'B37.7',
		'O03.37', 'O03.87', 'O04.87', 'O07.37', 'O08.82', 'O85', 'P36', 'P36.0',
		'P36.1', 'P36.10', 'P36.19', 'P36.2', 'P36.3', 'P36.30', 'P36.39', 'P36.4',
		'P36.5', 'P36.8', 'P36.9', 'R65.2', 'R65.20', 'R65.21', 'T82.XXA'
		)
		OR
			(
			ClasfCd BETWEEN 'T82' and 'T85'
		)
	)
	AND SortClasfType = 'df'
)
INSERT INTO @SepsisDX_Final
SELECT *
FROM CTE1 C1
--WHERE C1.RN = 1

--SELECT * FROM @SepsisDX_Final

--

DECLARE @DialysisEncounters TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, Unit_No             VARCHAR(10)
	, Treatment_DTime     DATETIME
	, [# Of Treatments]   INT
);

WITH CTE2 AS (
	SELECT PT_ID
	, [Unit No]
	, ACTV_DTIME
	, SUM(ACTV_TOT_QTY) [# OF TREATMENTS]

	FROM SMSDSS.C_HEMODIALYSIS_V

	WHERE HOSP_SVC IN ('DIA', 'DMS')
	AND ACTV_DTIME >= @START
	AND ACTV_DTIME < @END

	GROUP BY PT_ID
	, [Unit No]
	, ACTV_DTIME

)
INSERT INTO @DialysisEncounters
SELECT * FROM CTE2 C2
WHERE C2.[# OF TREATMENTS] > 0

--SELECT * FROM @DialysisEncounters

--

SELECT a.Encounter
, a.Unit_No
, SUM(a.[# Of Treatments])       AS [Count of Dialysis Treatments]

FROM @DialysisEncounters         AS A
INNER MERGE JOIN @SepsisDX_Final AS B
ON A.Encounter = B.Encounter

GROUP BY A.Encounter, a.Unit_No