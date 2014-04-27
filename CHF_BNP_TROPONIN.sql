-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @START DATE;
DECLARE @END   DATE;
DECLARE @BNP   VARCHAR(16);
DECLARE @TROP  VARCHAR(16);

SET @START = '2014-01-01';
SET @END   = '2014-02-01';
SET @BNP   = '00408500';
SET @TROP  = '00408492';

-- TABLE DECLARATION
DECLARE @T1 TABLE (
	VISIT VARCHAR(20)
	, MRN VARCHAR(20)
)

-- WHAT GOES INTO THE TABLE
INSERT INTO @T1
SELECT
A.PtNo_Num
, A.Med_Rec_No

FROM (
	SELECT PTNO_NUM
	, Med_Rec_No
	
	FROM smsdss.BMH_PLM_PtAcct_V
	
	WHERE Dsch_Date >= @START
	AND Dsch_Date < @END
	AND Plm_Pt_Acct_Type = 'I'
	AND PtNo_Num < '20000000'
	AND drg_no IN (291, 292, 293) -- CHF DRG NUMBERS
)A

--SELECT * FROM @T1

/* 
BNP RESULTS
*/
DECLARE @T2 TABLE (
	VISIT              VARCHAR(20)
	, [BNP ORDER #]    VARCHAR(20)
	, [ORDER NAME]     VARCHAR(100)
	, VALUE            VARCHAR(150)
)

INSERT INTO @T2
SELECT
B.episode_no
, B.ord_seq_no
, B.obsv_cd_ext_name
, B.dsply_val

FROM (
	SELECT episode_no
	, ord_seq_no
	, obsv_cd_ext_name
	, dsply_val
	, ROW_NUMBER() OVER (
		PARTITION BY EPISODE_NO ORDER BY ORD_SEQ_NO ASC
		) AS ROWNUMBER
	
	FROM smsmir.sr_obsv
	
	WHERE obsv_cd = @BNP
)B
WHERE ROWNUMBER = 1

--SELECT * FROM @T2

/*
TROPONIN RESULTS
*/
DECLARE @T3 TABLE (
	VISIT                VARCHAR(20)
	, [TROPONIN ORDER #] VARCHAR(20)
	, [ORDER NAME]       VARCHAR(100)
	, VALUE              VARCHAR(150)
)

INSERT INTO @T3
SELECT
C.episode_no
, C.ord_seq_no
, C.obsv_cd_ext_name
, C.dsply_val

FROM (
	SELECT episode_no
	, ord_seq_no
	, obsv_cd_ext_name
	, dsply_val
	, ROW_NUMBER() OVER (
		PARTITION BY EPISODE_NO ORDER BY ORD_SEQ_NO ASC
		) AS ROWNUMBER2
	
	FROM smsmir.sr_obsv
	
	WHERE obsv_cd = @TROP
)C
WHERE ROWNUMBER2 = 1

--SELECT * FROM @T3

SELECT T1.VISIT
, T1.MRN
, T2.[BNP ORDER #]
, T2.VALUE                  AS [BNP VALUE]
, T3.[TROPONIN ORDER #]
, SUBSTRING(T3.VALUE, 1, 6) AS [TROPONIN VALUE]

FROM @T1 T1
	LEFT JOIN @T2 T2
	ON T1.VISIT = T2.VISIT
	LEFT JOIN @T3 T3
	ON T1.VISIT = T3.VISIT