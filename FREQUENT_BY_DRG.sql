-- VARIABLE INITIALIZATION AND DECLARATION
DECLARE @SD AS DATE;
DECLARE @ED AS DATE;
SET @SD = '2013-01-01';
SET @ED = '2013-12-31';

-- TABLE DECLARATION @T1
DECLARE @T1 TABLE (
	MRN VARCHAR(200)
	, NAME VARCHAR(200)
)
-- WHAT GETS INSERTED INTO @T1
INSERT INTO @T1
SELECT
A.MED_REC_NO
, A.PT_NAME

-- WHERE IT ALL COMES FROM
FROM (
	SELECT DISTINCT MED_REC_NO
	, PT_NAME

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Plm_Pt_Acct_Type = 'I'
	AND PtNo_Num < '20000000'
	AND Dsch_Date BETWEEN @SD AND @ED
	AND drg_no IN (        -- DRG'S OF INTEREST
		'190','191','192'  -- COPD
		,'291','292','293' -- CHF
		,'193','194','195' -- PN
	)
) A

/*
-----------------------------------------------------------------------
END OF QUERY 1
-----------------------------------------------------------------------
*/
/*
-----------------------------------------------------------------------
QUERY 2: 

THIS QUERY WILL TAKE ALL OF THE DISTINCT MRNS FROM ABOVE
AND COUNT HOW MANY TIMES THE INDIVIDUAL HAS BEEN AN INPATIENT IN THE 
HOSPITAL OVER A DISCHARGE DATE RANGE OF ALL 2013
-----------------------------------------------------------------------
*/
-- TABLE DECLARATION @T2
DECLARE @T2 TABLE (
	MRN VARCHAR(200)
	, NAME VARCHAR(500)
	, [COUNT] INT
)
-- WHAT GETS INSERTED INTO @T2
INSERT INTO @T2
SELECT
B.MED_REC_NO
, B.PT_NAME
, B.[VISIT COUNT]
--WHERE IT ALL COMES FROM
FROM (
	SELECT DISTINCT MED_REC_NO
	, PT_NAME
	, COUNT(PTNO_NUM) AS [VISIT COUNT]

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Plm_Pt_Acct_Type = 'I'
	AND PtNo_Num < '20000000'
	AND Dsch_Date BETWEEN @SD AND @ED
	GROUP BY Med_Rec_No
	, Pt_Name
) B
/*
-----------------------------------------------------------------------
END OF QUERY 2
-----------------------------------------------------------------------
*/
-- PUTTING IT ALL TOGETHER
SELECT DISTINCT T1.MRN
, T1.NAME
, T2.[COUNT]

FROM @T1 T1
JOIN @T2 T2
ON T1.MRN = T2.MRN

WHERE T2.COUNT >= 4
ORDER BY T2.[COUNT] DESC