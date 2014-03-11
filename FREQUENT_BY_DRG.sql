-- VARIABLE INITIALIZATION AND DECLARATION
DECLARE @SD AS DATE;
DECLARE @ED AS DATE;
SET @SD = '2013-01-01';
SET @ED = '2014-01-01';

-- TABLE DECLARATION @T1
DECLARE @T1 TABLE (
	MRN VARCHAR(200)
	, NAME VARCHAR(200)
)
-- WHAT GETS INSERTED INTO @T1
INSERT INTO @T1
SELECT
A.MED_REC_NO-- VARIABLE INITIALIZATION AND DECLARATION
DECLARE @SD AS DATE;
DECLARE @ED AS DATE;
SET @SD = '2013-01-01';
SET @ED = '2014-01-01';

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
	AND Dsch_Date >= @SD 
	AND Dsch_Date < @ED
	AND drg_no IN (        -- DRG'S OF INTEREST
		'190','191','192'  -- COPD
		,'291','292','293' -- CHF
		,'287','313'       -- CHEST PAIN
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
HOSPITAL OVER A DISCHARGE DATE RANGE
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
	AND Dsch_Date >= @SD 
	AND Dsch_Date < @ED 
	GROUP BY Med_Rec_No
	, Pt_Name
) B
/*
-----------------------------------------------------------------------
END OF QUERY 2
-----------------------------------------------------------------------
*/

/*
ER QUERY COUNT
This query gets a count of how many times an individual has been in 
the emergency room as a patient over the specified date range
*/
DECLARE @tmp TABLE
(
MRN INT
, VISIT_DATE DATETIME
, VISIT_ID INT
, PRIMARY KEY (MRN, VISIT_DATE, VISIT_ID)
)

INSERT INTO @tmp
SELECT
DISTINCT MED_REC_NO AS MRN
, VST_START_DTIME AS VISIT_DATE
, PT_NO AS VISIT_ID

FROM smsdss.BMH_PLM_PtAcct_V
WHERE ((
	Plm_Pt_Acct_Type = 'I'
	AND Adm_Source NOT IN (
		'RP'
		)
	)
	OR pt_type = 'E')
AND vst_start_dtime >= @SD
AND vst_start_dtime < @ED

;WITH ERCNT AS (
	SELECT A.MRN
	, A.VISIT_ID
	, A.VISIT_DATE
	, COUNT(B.VISIT_ID) AS VISIT_COUNT
	
	FROM @tmp A
	LEFT JOIN @tmp B
	ON A.MRN = B.MRN
	AND A.VISIT_DATE > B.VISIT_DATE
	
	GROUP BY A.MRN
	, A.VISIT_ID
	, A.VISIT_DATE
)
/*END OF ER QUERY*/

-- PUTTING IT ALL TOGETHER
SELECT DISTINCT T1.MRN
, T1.NAME
, T2.[COUNT]
, max(CNT.VISIT_COUNT) AS [ER VISIT COUNT]

FROM @T1 T1
JOIN @T2 T2
ON T1.MRN = T2.MRN
LEFT OUTER JOIN ERCNT CNT
ON T1.MRN = CNT.MRN

WHERE T2.COUNT >= 4
GROUP BY T1.MRN
, T1.NAME
, T2.COUNT
, A.PT_NAME

-- WHERE IT ALL COMES FROM
FROM (
	SELECT DISTINCT MED_REC_NO
	, PT_NAME

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Plm_Pt_Acct_Type = 'I'
	AND PtNo_Num < '20000000'
	AND Dsch_Date >= @SD 
	AND Dsch_Date < @ED
	AND drg_no IN (        -- DRG'S OF INTEREST
		'190','191','192'  -- COPD
		,'291','292','293' -- CHF
		,'287','313'       -- CHEST PAIN
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
HOSPITAL OVER A DISCHARGE DATE RANGE
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
	AND Dsch_Date >= @SD 
	AND Dsch_Date < @ED 
	GROUP BY Med_Rec_No
	, Pt_Name
) B
/*
-----------------------------------------------------------------------
END OF QUERY 2
-----------------------------------------------------------------------
*/

/*
ER QUERY COUNT
This query gets a count of how many times an individual has been in 
the emergency room as a patient over the specified date range
*/
DECLARE @tmp TABLE
(
MRN INT
, VISIT_DATE DATETIME
, VISIT_ID INT
)

INSERT INTO @tmp
SELECT
MED_REC_NO AS MRN
, VST_START_DTIME AS VISIT_DATE
, PT_NO AS VISIT_ID

FROM smsdss.BMH_PLM_PtAcct_V
WHERE ((
	Plm_Pt_Acct_Type = 'I'
	AND Adm_Source NOT IN (
		'RP'
		)
	)
	OR pt_type = 'E')
AND vst_start_dtime >= @SD
AND vst_start_dtime < @ED

;WITH ERCNT AS (
	SELECT A.MRN
	, A.VISIT_ID
	, A.VISIT_DATE
	, COUNT(B.VISIT_ID) AS VISIT_COUNT
	
	FROM @tmp A
	LEFT JOIN @tmp B
	ON A.MRN = B.MRN
	AND A.VISIT_DATE > B.VISIT_DATE
	
	GROUP BY A.MRN
	, A.VISIT_ID
	, A.VISIT_DATE
)
/*END OF ER QUERY*/

-- PUTTING IT ALL TOGETHER
SELECT DISTINCT T1.MRN
, T1.NAME
, T2.[COUNT]
, max(CNT.VISIT_COUNT) AS [ER VISIT COUNT]

FROM @T1 T1
JOIN @T2 T2
ON T1.MRN = T2.MRN
LEFT OUTER JOIN ERCNT CNT
ON T1.MRN = CNT.MRN

WHERE T2.COUNT >= 4
GROUP BY T1.MRN
, T1.NAME
, T2.COUNT