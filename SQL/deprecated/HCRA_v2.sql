DECLARE @START_DATE DATE;
DECLARE @END_DATE   DATE;

SET @START_DATE = '2012-01-01';
SET @END_DATE   = '2016-01-01';
---------------------------------------------------------------------------------------------------
DECLARE @HCRA_POP_INS1 TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN                    VARCHAR(10)
	, [Ref Number]           VARCHAR(12)
	, PT_ID                  VARCHAR(12)
	, [Admit Date]           DATE
	, [Discharge Date]       DATE
	, [Payor]                VARCHAR(4)
	, [Ins Name]             VARCHAR(50)
	, [Pyor Sub-Code]        VARCHAR(5)
	, [Medical Service Code] VARCHAR(3)
	, [Service Code Desc]    VARCHAR(75)
	, [Receivable Type]      VARCHAR(1)
	, subscr_ins_grp_name    VARCHAR(50)
	, PAYOR_SEQ_NO           VARCHAR(2)
);

WITH CTE AS (
	SELECT A.Med_Rec_No
	, A.PtNo_Num                AS [Ref Number]
	, A.Pt_No
	, CAST(A.ADM_DATE AS DATE)  AS [Admit Date]
	, CAST(A.DSCH_DATE AS DATE) AS [Discharge Date]
	, A.Pyr1_Co_Plan_Cd         AS [Payor]
	, CASE
		WHEN A.User_Pyr1_Cat = 'MIS' THEN 'Self Pay'
		ELSE B.pyr_name
	  END                       AS [Ins Name] -- WILL NEED TO COALESE RESULTS FROM @INS_INFO TABLE
	, ''                        AS [Payor Sub-Code]
	, A.hosp_svc                AS [Medical Service Code]
	, D.hosp_svc_name
	, A.Plm_Pt_Acct_Type        AS [Receivable Type]
	, Z.subscr_ins_grp_name
	, Z.pyr_seq_no

	FROM smsdss.BMH_PLM_PtAcct_V          AS A
	LEFT JOIN smsmir.pyr_mstr             AS B
	ON A.Pyr1_Co_Plan_Cd = B.pyr_cd
	LEFT MERGE JOIN smsdss.hosp_svc_dim_v AS D
	ON A.hosp_svc = D.hosp_svc
		AND A.Regn_Hosp = D.orgz_cd
	LEFT JOIN smsmir.pyr_plan             AS Z
	ON A.Pt_No = Z.pt_id
		AND A.Pyr1_Co_Plan_Cd = Z.pyr_cd
	
	
	WHERE a.Dsch_Date >= '2012-01-01'
	AND a.Dsch_Date < '2016-01-01'
	AND a.Med_Rec_No IS NOT NULL
	AND a.tot_chg_amt > 0
	AND LEFT(A.PTNO_NUM, 1) != '7'
	--OPTION(FORCE ORDER);
)
INSERT INTO @HCRA_POP_INS1
SELECT * FROM CTE
OPTION(FORCE ORDER);

SELECT A.*
INTO #TEMP_A
FROM @HCRA_POP_INS1 AS A;

---------------------------------------------------------------------------------------------------
DECLARE @HCRA_POP_INS2 TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN                    VARCHAR(10)
	, [Ref Number]           VARCHAR(12)
	, PT_ID                  VARCHAR(12)
	, [Admit Date]           DATE
	, [Discharge Date]       DATE
	, [Payor]                VARCHAR(4)
	, [Ins Name]             VARCHAR(50)
	, [Pyor Sub-Code]        VARCHAR(5)
	, [Medical Service Code] VARCHAR(3)
	, [Service Code Desc]    VARCHAR(75)
	, [Receivable Type]      VARCHAR(1)
	, subscr_ins_grp_name    VARCHAR(50)
	, PAYOR_SEQ_NO           VARCHAR(2)
);

WITH CTE AS (
	SELECT A.Med_Rec_No
	, A.PtNo_Num                AS [Ref Number]
	, A.Pt_No
	, CAST(A.ADM_DATE AS DATE)  AS [Admit Date]
	, CAST(A.DSCH_DATE AS DATE) AS [Discharge Date]
	, A.Pyr2_Co_Plan_Cd         AS [Payor]
	, CASE
		WHEN A.User_Pyr1_Cat = 'MIS' THEN 'Self Pay'
		ELSE B.pyr_name
	  END                       AS [Ins Name] -- WILL NEED TO COALESE RESULTS FROM @INS_INFO TABLE
	, ''                        AS [Payor Sub-Code]
	, A.hosp_svc                AS [Medical Service Code]
	, D.hosp_svc_name
	, A.Plm_Pt_Acct_Type        AS [Receivable Type]
	, Z.subscr_ins_grp_name
	, Z.pyr_seq_no

	FROM smsdss.BMH_PLM_PtAcct_V          AS A
	LEFT JOIN smsmir.pyr_mstr             AS B
	ON A.Pyr2_Co_Plan_Cd = B.pyr_cd
	LEFT MERGE JOIN smsdss.hosp_svc_dim_v AS D
	ON A.hosp_svc = D.hosp_svc
		AND A.Regn_Hosp = D.orgz_cd
	LEFT JOIN smsmir.pyr_plan             AS Z
	ON A.Pt_No = Z.pt_id
		AND A.Pyr2_Co_Plan_Cd = Z.pyr_cd
	
	
	WHERE a.Dsch_Date >= '2012-01-01'
	AND a.Dsch_Date < '2016-01-01'
	AND a.Med_Rec_No IS NOT NULL
	AND a.tot_chg_amt > 0
	AND LEFT(A.PTNO_NUM, 1) != '7'
	AND A.Pyr2_Co_Plan_Cd IS NOT NULL
	AND A.PtNo_Num IN (
		SELECT AAA.[Ref Number]
		from #TEMP_A AS AAA
	)
)
INSERT INTO @HCRA_POP_INS2
SELECT * FROM CTE
OPTION(FORCE ORDER);

SELECT A.*
INTO #TEMP_B
FROM @HCRA_POP_INS2 AS A;

---------------------------------------------------------------------------------------------------

DECLARE @HCRA_POP_INS3 TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN                    VARCHAR(10)
	, [Ref Number]           VARCHAR(12)
	, PT_ID                  VARCHAR(12)
	, [Admit Date]           DATE
	, [Discharge Date]       DATE
	, [Payor]                VARCHAR(4)
	, [Ins Name]             VARCHAR(50)
	, [Pyor Sub-Code]        VARCHAR(5)
	, [Medical Service Code] VARCHAR(3)
	, [Service Code Desc]    VARCHAR(75)
	, [Receivable Type]      VARCHAR(1)
	, subscr_ins_grp_name    VARCHAR(50)
	, PAYOR_SEQ_NO           VARCHAR(2)
);

WITH CTE AS (
	SELECT A.Med_Rec_No
	, A.PtNo_Num                AS [Ref Number]
	, A.Pt_No
	, CAST(A.ADM_DATE AS DATE)  AS [Admit Date]
	, CAST(A.DSCH_DATE AS DATE) AS [Discharge Date]
	, A.Pyr3_Co_Plan_Cd         AS [Payor]
	, CASE
		WHEN A.User_Pyr1_Cat = 'MIS' THEN 'Self Pay'
		ELSE B.pyr_name
	  END                       AS [Ins Name] -- WILL NEED TO COALESE RESULTS FROM @INS_INFO TABLE
	, ''                        AS [Payor Sub-Code]
	, A.hosp_svc                AS [Medical Service Code]
	, D.hosp_svc_name
	, A.Plm_Pt_Acct_Type        AS [Receivable Type]
	, Z.subscr_ins_grp_name
	, Z.pyr_seq_no

	FROM smsdss.BMH_PLM_PtAcct_V          AS A
	LEFT JOIN smsmir.pyr_mstr             AS B
	ON A.Pyr3_Co_Plan_Cd = B.pyr_cd
	LEFT MERGE JOIN smsdss.hosp_svc_dim_v AS D
	ON A.hosp_svc = D.hosp_svc
		AND A.Regn_Hosp = D.orgz_cd
	LEFT JOIN smsmir.pyr_plan             AS Z
	ON A.Pt_No = Z.pt_id
		AND A.Pyr3_Co_Plan_Cd = Z.pyr_cd
	
	
	WHERE a.Dsch_Date >= '2012-01-01'
	AND a.Dsch_Date < '2016-01-01'
	AND a.Med_Rec_No IS NOT NULL
	AND a.tot_chg_amt > 0
	AND LEFT(A.PTNO_NUM, 1) != '7'
	AND A.Pyr3_Co_Plan_Cd IS NOT NULL
	AND A.PtNo_Num IN (
		SELECT AAA.[Ref Number]
		from #TEMP_A AS AAA
	)
)
INSERT INTO @HCRA_POP_INS3
SELECT * FROM CTE
OPTION(FORCE ORDER);

SELECT A.*
INTO #TEMP_C
FROM @HCRA_POP_INS3 AS A;

---------------------------------------------------------------------------------------------------
DECLARE @HCRA_POP_INS4 TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN                    VARCHAR(10)
	, [Ref Number]           VARCHAR(12)
	, PT_ID                  VARCHAR(12)
	, [Admit Date]           DATE
	, [Discharge Date]       DATE
	, [Payor]                VARCHAR(4)
	, [Ins Name]             VARCHAR(50)
	, [Pyor Sub-Code]        VARCHAR(5)
	, [Medical Service Code] VARCHAR(3)
	, [Service Code Desc]    VARCHAR(75)
	, [Receivable Type]      VARCHAR(1)
	, subscr_ins_grp_name    VARCHAR(50)
	, PAYOR_SEQ_NO           VARCHAR(2)
);

WITH CTE AS (
	SELECT A.Med_Rec_No
	, A.PtNo_Num                AS [Ref Number]
	, A.Pt_No
	, CAST(A.ADM_DATE AS DATE)  AS [Admit Date]
	, CAST(A.DSCH_DATE AS DATE) AS [Discharge Date]
	, A.Pyr4_Co_Plan_Cd         AS [Payor]
	, CASE
		WHEN A.User_Pyr1_Cat = 'MIS' THEN 'Self Pay'
		ELSE B.pyr_name
	  END                       AS [Ins Name] -- WILL NEED TO COALESE RESULTS FROM @INS_INFO TABLE
	, ''                        AS [Payor Sub-Code]
	, A.hosp_svc                AS [Medical Service Code]
	, D.hosp_svc_name
	, A.Plm_Pt_Acct_Type        AS [Receivable Type]
	, Z.subscr_ins_grp_name
	, Z.pyr_seq_no

	FROM smsdss.BMH_PLM_PtAcct_V          AS A
	LEFT JOIN smsmir.pyr_mstr             AS B
	ON A.Pyr4_Co_Plan_Cd = B.pyr_cd
	LEFT MERGE JOIN smsdss.hosp_svc_dim_v AS D
	ON A.hosp_svc = D.hosp_svc
		AND A.Regn_Hosp = D.orgz_cd
	LEFT JOIN smsmir.pyr_plan             AS Z
	ON A.Pt_No = Z.pt_id
		AND A.Pyr4_Co_Plan_Cd = Z.pyr_cd
	
	
	WHERE a.Dsch_Date >= '2012-01-01'
	AND a.Dsch_Date < '2016-01-01'
	AND a.Med_Rec_No IS NOT NULL
	AND a.tot_chg_amt > 0
	AND LEFT(A.PTNO_NUM, 1) != '7'
	AND A.Pyr4_Co_Plan_Cd IS NOT NULL
	AND A.PtNo_Num IN (
		SELECT AAA.[Ref Number]
		from #TEMP_A AS AAA
	)
)
INSERT INTO @HCRA_POP_INS4
SELECT * FROM CTE
OPTION(FORCE ORDER);

SELECT A.*
INTO #TEMP_D
FROM @HCRA_POP_INS4 AS A;
---------------------------------------------------------------------------------------------------
DECLARE @HCRA_POP TABLE (
	ID                       INT
	, MRN                    VARCHAR(10)
	, [Ref Number]           VARCHAR(12)
	, PT_ID                  VARCHAR(12)
	, [Admit Date]           DATE
	, [Discharge Date]       DATE
	, [Payor]                VARCHAR(4)
	, [Ins Name]             VARCHAR(50)
	, [Pyor Sub-Code]        VARCHAR(5)
	, [Medical Service Code] VARCHAR(3)
	, [Service Code Desc]    VARCHAR(75)
	, [Receivable Type]      VARCHAR(1)
	, subscr_ins_grp_name    VARCHAR(50)
	, PAYOR_SEQ_NO           VARCHAR(2)
)

INSERT INTO @HCRA_POP
SELECT A.*
FROM (
	SELECT *
	FROM #TEMP_A
	
	UNION
	
	SELECT *
	FROM #TEMP_B 
	
	UNION
	SELECT *
	
	FROM #TEMP_C 
	UNION
	
	SELECT *
	FROM #TEMP_D
) A

SELECT A.[Ref Number]
, 'FMS' AS [System]
, A.[Admit Date]
, A.[Discharge Date]
, A.[PAYOR_SEQ_NO] AS [Primary or Secondary Indicator]
, A.[Payor] + ',' + COALESCE(B.INS_NAME, A.[INS NAME]) AS [Payor Code]
, A.[Ins Name] AS [Payor Desciption]
, isnull(A.[Payor], '') + ',' + ISNULL(B.INS_NAME, '') + ',' 
+ isnull(A.[ins name], '') + ',' + isnull(A.subscr_ins_grp_name, '') as [Pyor Sub-Code]
, a.*

FROM @HCRA_POP AS A
LEFT JOIN smsdss.c_ins_user_fields_v AS B
ON A.PT_ID = B.pt_id
	and A.Payor = B.pyr_cd

ORDER BY A.MRN, A.[Admit Date], A.PAYOR_SEQ_NO

DROP TABLE #TEMP_A, #TEMP_B, #TEMP_C, #TEMP_D