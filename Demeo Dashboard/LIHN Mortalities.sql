DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2016-01-01';
SET @END   = '2016-08-01';
---------------------------------------------------------------------------------------------------

DECLARE @DISCHARGES TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN                 CHAR(6)
	, Encounter           CHAR(12)
	, Mortality_Flag      CHAR(1)
	, Discharge_Date      DATE
);

WITH CTE AS (
	SELECT Med_Rec_No
	, Pt_No
	, CASE
		WHEN LEFT(DSCH_DISP, 1) IN ('C', 'D')
			THEN '1'
			ELSE '0'
	  END AS MORTALITY_FLAG
	, Dsch_Date
	
	FROM smsdss.BMH_PLM_PtAcct_V
	
	WHERE Dsch_Date >= @START
	AND Dsch_Date < @END
	AND Plm_Pt_Acct_Type = 'I'
	AND PtNo_Num < '20000000'
	AND tot_chg_amt > 0
	AND LEFT(PTNO_NUM, 4) != '1999'
	AND Pt_Name != 'TEST ,PATIENT'
)

INSERT INTO @DISCHARGES
SELECT * FROM CTE;
---------------------------------------------------------------------------------------------------

DECLARE @PALLIATIVE TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           VARCHAR(12)
	, DX_CD               VARCHAR(15)
	, DX_CD_TYPE          VARCHAR(5)
	, RN                  INT
);

WITH CTE AS (
	SELECT pt_id
	, dx_cd
	, dx_cd_type
	, ROW_NUMBER() OVER(
		PARTITION BY PT_ID
		ORDER BY PT_ID
	) AS RN

	FROM smsmir.dx_grp

	WHERE dx_cd IN (
		'Z51.5', 'V66.7'
	)
	AND orgz_cd = 'S0X0'
	AND LEFT(dx_cd_type, 2) = 'DF'
)

INSERT INTO @PALLIATIVE
SELECT * FROM CTE AS A
WHERE A.RN = 1;
---------------------------------------------------------------------------------------------------

SELECT A.MRN
, A.Encounter
, A.Discharge_Date
, A.Mortality_Flag
, B.Encounter AS PALLIATIVE_ENCOUNTER
, B.DX_CD
, B.DX_CD_TYPE
, CASE
	WHEN B.RN IS NULL
	THEN '0'
	ELSE B.RN
END AS RN

INTO #TEMP

FROM @DISCHARGES      AS A
LEFT JOIN @PALLIATIVE AS B
ON A.Encounter = B.Encounter
--------------------------------------------------------------------------------------------------

SELECT A.*
, DATEPART(MONTH, A.DISCHARGE_DATE) AS DISCHARGE_MONTH
, DATEPART(YEAR, A.DISCHARGE_DATE) AS DISCHARGE_YEAR
, (A.MORTALITY_FLAG + A.RN) as [check_sum]
, B.LIHN_Service_Line

FROM #TEMP AS A
LEFT JOIN smsdss.c_LIHN_Svc_Lines_Rpt2_ICD10_v AS B
ON A.ENCOUNTER = B.pt_id

WHERE (
	(A.MORTALITY_FLAG + A.RN) != 2
)

------------------

DROP TABLE #TEMP