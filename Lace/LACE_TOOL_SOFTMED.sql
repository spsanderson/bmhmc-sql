SET ANSI_NULLS OFF
GO
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @D DATETIME;
DECLARE @SD DATETIME;
DECLARE @ED DATETIME;

SET @D = GETDATE()
SET @SD = GETDATE()-180
SET @ED = GETDATE()

-- @T1  -------------------------------------------------------------//
DECLARE @T1 TABLE (
ENCOUNTER_ID VARCHAR(200)
, MRN VARCHAR(200)
, [DAYS STAY] VARCHAR(200)
, [LACE DAYS SCORE] INT
, [ACUTE ADMIT SCORE] INT
, ARRIVAL DATETIME
)
---------------------------------------------------------------------//

-- @T1 RECORD INSERTIONS ############################################//
INSERT INTO @T1
SELECT
A.BILL_NO
, A.MRN
, A.LENGTH_OF_STAY
, A.LACE_DAYS_SCORE
, A.ACUTE_ADMIT_LACE_SCORE
, A.ADMISSION_DATE
--###################################################################//

-- DAYS STAY, ACUTE ADMIT AND RELATED SCORING -----------------------//
FROM
	(SELECT BILL_NO
	, MRN
	, LENGTH_OF_STAY
	, CASE
		WHEN LENGTH_OF_STAY < 1 THEN 0
		WHEN LENGTH_OF_STAY = 1 THEN 1
		WHEN LENGTH_OF_STAY = 2 THEN 2
		WHEN LENGTH_OF_STAY = 3 THEN 3
		WHEN LENGTH_OF_STAY BETWEEN 4 AND 6 THEN 4
		WHEN LENGTH_OF_STAY BETWEEN 7 AND 13 THEN 5
		WHEN LENGTH_OF_STAY >= 14 THEN 7
	  END AS LACE_DAYS_SCORE
	, CASE
		WHEN PATIENT_TYPE = 'I' THEN 3
		ELSE 0
	  END AS ACUTE_ADMIT_LACE_SCORE
	, ADMISSION_DATE	
	
	FROM dbo.visit_view
	/* FROM MODIFICATION starts here, join ctc_visit._fk_visit
	on visit_view.visit_id */
	JOIN ctc_visit 
	ON dbo.visit_view.visit_id = ctc_visit._fk_visit
	/* FROM MODIFICATION ends here */

	WHERE /* FILTER MODIFICATION starts here*/ 
	(ctc_visit.s_cpm_patient_status = 'IA' or ctc_visit.visit_admit_service = 'OBV')
	AND v_changed_on > @D-1
	--discharged IS NULL
	--AND patient_type = 'I'
	--AND institution_no IS NULL
	--AND bill_no < 20000000
	/* FILTER MODIFICATION ends here */
	) A

--SELECT * FROM @T1
--###################################################################//

-- ER VISITS QUERY: THIS QUERY WILL GET A COUNT OF THE AMOUNT OF TIMES
-- AN INDIVIDUAL HAS COME TO THE ER BASED UPON THE CURRENT VISIT ID 

-- @CNT TABLE DECLARATION ###########################################//
DECLARE @CNT TABLE (MRN VARCHAR(100)
					, VISIT_COUNT INT)
--###################################################################//
INSERT INTO @CNT
SELECT
DISTINCT MRN
, COUNT(DISTINCT BILL_NO) AS VISIT_COUNT

FROM DBO.VISIT_VIEW
WHERE patient_type = 'E'
AND admission_date >= GETDATE()-180
GROUP BY MRN

--SELECT * FROM @CNT

--###################################################################//
-- CO-MORBIDITY QUERY: THIS ONE QILL GO THROUGH A LIST OF CODES AND
-- SCORE THE PATIENTS PROSPECTIVE VISIT ACCORDINGLY.

-- @CM TABLE DECLARATION ############################################//
DECLARE @CM TABLE (
ENCOUNTER_ID VARCHAR(200)
, [MRN CM] VARCHAR(200)
, [CC GRP ONE SCORE] VARCHAR(20)
, [CC GRP TWO SCORE] VARCHAR(20)
, [CC GRP THREE SCORE] VARCHAR(20)
, [CC GRP FOUR SCORE] VARCHAR(20)
, [CC GRP FIVE SCORE] VARCHAR(20)
, [CC LACE SCORE] INT
)
--###################################################################//

INSERT INTO @CM
SELECT
C.BILL_NO
, C.MRN
, C.PRIN_DX_CD_1
, C.PRIN_DX_CD_2
, C.PRIN_DX_CD_3
, C.PRIN_DX_CD_4
, C.PRIN_DX_CD_5
, CASE
    WHEN (C.PRIN_DX_CD_1+C.PRIN_DX_CD_2+C.PRIN_DX_CD_3+C.PRIN_DX_CD_4+C.PRIN_DX_CD_5) = 0 THEN 0
    WHEN (C.PRIN_DX_CD_1+C.PRIN_DX_CD_2+C.PRIN_DX_CD_3+C.PRIN_DX_CD_4+C.PRIN_DX_CD_5) = 1 THEN 1
    WHEN (C.PRIN_DX_CD_1+C.PRIN_DX_CD_2+C.PRIN_DX_CD_3+C.PRIN_DX_CD_4+C.PRIN_DX_CD_5) = 2 THEN 2
    WHEN (C.PRIN_DX_CD_1+C.PRIN_DX_CD_2+C.PRIN_DX_CD_3+C.PRIN_DX_CD_4+C.PRIN_DX_CD_5) = 3 THEN 3
    WHEN (C.PRIN_DX_CD_1+C.PRIN_DX_CD_2+C.PRIN_DX_CD_3+C.PRIN_DX_CD_4+C.PRIN_DX_CD_5) >= 4 THEN 5
 --   WHEN (C.PRIN_DX_CD_1+C.PRIN_DX_CD_2+C.PRIN_DX_CD_3+C.PRIN_DX_CD_4+C.PRIN_DX_CD_5) = 5 THEN 5
 --   WHEN (C.PRIN_DX_CD_1+C.PRIN_DX_CD_2+C.PRIN_DX_CD_3+C.PRIN_DX_CD_4+C.PRIN_DX_CD_5) >= 6 THEN 6
  END AS CC_LACE_SCORE
  
FROM (
	SELECT DISTINCT V.BILL_NO
	, V.MRN
	, CASE
	when DxChrlsnWt = 1
	 THEN 1
		ELSE 0
	  END AS PRIN_DX_CD_1
	, CASE
	when  DxChrlsnWt = 2
	 THEN 2
		ELSE 0
	END AS PRIN_DX_CD_2
    , CASE
	when DxChrlsnWt = 3
		THEN 3
		ELSE 0
	  END AS PRIN_DX_CD_3
	, CASE
	when DxChrlsnWt = 4
		THEN 4
		ELSE 0
	  END AS PRIN_DX_CD_4
	, CASE
	when DxChrlsnWt = 6
 	    THEN 6
		ELSE 0
	  END AS PRIN_DX_CD_5
	  
	  FROM DBO.VISIT_VIEW V
	  JOIN DBO.CTC_DIAGNOSIS D
	   ON V.VISIT_ID = D._FK_VISIT
	   left outer join DxCharlsonCondMstr on d.diagnosis between DxCharlsonCondMstr.DxChrlsnCdBegin and DxCharlsonCondMstr.DxChrlsnCdEnd
	   WHERE ADMISSION_DATE BETWEEN @SD-540 AND @ED 
)C

GROUP BY C.BILL_NO
, C.MRN
, C.PRIN_DX_CD_1
, C.PRIN_DX_CD_2
, C.PRIN_DX_CD_3
, C.PRIN_DX_CD_4
, C.PRIN_DX_CD_5
ORDER BY (C.PRIN_DX_CD_1+C.PRIN_DX_CD_2+C.PRIN_DX_CD_3+C.PRIN_DX_CD_4+C.PRIN_DX_CD_5)

--SELECT * FROM @CM

-- @LACE_MSTR TABLE DECLARATION ###################################//
DECLARE @LACE_MSTR TABLE(
MRN VARCHAR(200)
, VISIT_ID VARCHAR(200)
, [LACE DAYS SCORE] INT
, [LACE ACUTE IP SCORE] INT
, [LACE ER SCORE] INT
, [LACE COMORBID SCORE] INT
)
--###################################################################//
INSERT INTO @LACE_MSTR
SELECT
Q1.MRN
, Q1.ENCOUNTER_ID
, Q1.[LACE DAYS SCORE]
, Q1.[ACUTE ADMIT SCORE]
, CASE
    WHEN Q1.VISIT_COUNT IS NULL THEN 0
    WHEN Q1.VISIT_COUNT = 1 THEN 1
    WHEN Q1.VISIT_COUNT = 2 THEN 2
    WHEN Q1.VISIT_COUNT = 3 THEN 3
    WHEN Q1.VISIT_COUNT >= 4 THEN 4
    ELSE 0
  END AS [LACE ER SCORE]
, Q1.[CC LACE SCORE]

FROM
	(
	SELECT
	DISTINCT T1.ENCOUNTER_ID
	, T1.MRN
	, T1.[LACE DAYS SCORE]
	, T1.[ACUTE ADMIT SCORE]
	, CNT.VISIT_COUNT
	, CM.[CC LACE SCORE]
	
	FROM @T1 T1
	LEFT OUTER JOIN @CNT CNT
	ON T1.MRN = CNT.MRN
	JOIN @CM CM
	ON CM.[MRN CM] = T1.[MRN]
	) Q1;

WITH X AS (
	SELECT VISIT_ID
	, MRN
	, [LACE DAYS SCORE]
	, [LACE ACUTE IP SCORE]
	, [LACE ER SCORE]
	, [LACE COMORBID SCORE]
	, RN = ROW_NUMBER() OVER (PARTITION BY VISIT_ID, MRN
	ORDER BY [LACE DAYS SCORE]+[LACE ACUTE IP SCORE]+[LACE ER SCORE]+[LACE COMORBID SCORE] DESC)
	FROM @LACE_MSTR
	)
	
SELECT VISIT_ID
--, MRN
--, [LACE DAYS SCORE] AS L
--, [LACE ACUTE IP SCORE] AS A
--, [LACE COMORBID SCORE] AS C
--, [LACE ER SCORE] AS E
--, [LACE DAYS SCORE]+[LACE ACUTE IP SCORE]+[LACE ER SCORE]+[LACE COMORBID SCORE] AS [SCORE]

FROM X
WHERE RN = 1
AND ([LACE DAYS SCORE]+[LACE ACUTE IP SCORE]+[LACE ER SCORE]+[LACE COMORBID SCORE]) >= 9

/* Change log: 
2013-10-31 9:07am
Made minor change to the first from clause in table @T1 in order 
to get rid of inactive patients, this prevents them from crossing
over. They would never make it to the report anyway but this cleans
them out before the results are sent 
2015-04-24 11:40am
Added OBV patients to the query cw 
2015-09-29 16:39
Changed Lace C to look at dxCharlsonCondMstr to determine weights cw */