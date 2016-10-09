DECLARE @START_DATE DATE;
DECLARE @END_DATE   DATE;

SET @START_DATE = '2012-01-01';
SET @END_DATE   = '2016-01-01';
---------------------------------------------------------------------------------------------------
DECLARE @HCRA_POP TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN VARCHAR(10)
	, [Ref Number] VARCHAR(12)
	, PT_ID VARCHAR(12)
	, [Admit Date] DATE
	, [Discharge Date] DATE
	, [Primary Payor] VARCHAR(4)
	, [Primary Ins Name] VARCHAR(50)
	, [Pyor Sub-Code] VARCHAR(5)
	, [Medical Service Code] VARCHAR(3)
	, [Service Code Desc] VARCHAR(75)
	, [Receivable Type] VARCHAR(1)
);

WITH CTE AS (
	SELECT A.Med_Rec_No
	, A.PtNo_Num                AS [Ref Number]
	, A.Pt_No
	, CAST(A.ADM_DATE AS DATE)  AS [Admit Date]
	, CAST(A.DSCH_DATE AS DATE) AS [Discharge Date]
	, A.Pyr1_Co_Plan_Cd         AS [Primary Payor]
	, CASE
		WHEN A.User_Pyr1_Cat = 'MIS' THEN 'Self Pay'
		ELSE B.pyr_name
	  END                       AS [Primary Ins Name] -- WILL NEED TO COALESE RESULTS FROM @INS_INFO TABLE
	, ''                        AS [Payor Sub-Code]
	, A.hosp_svc                AS [Medical Service Code]
	, D.hosp_svc_name
	, A.Plm_Pt_Acct_Type        AS [Receivable Type]

	FROM smsdss.BMH_PLM_PtAcct_V         AS A
	LEFT JOIN smsmir.pyr_mstr            AS B
	ON A.Pyr1_Co_Plan_Cd = B.pyr_cd
	LEFT JOIN smsmir.pyr_plan            AS C
	ON A.Pt_No = C.pt_id
		AND A.Pyr1_Co_Plan_Cd = C.pyr_cd
		AND C.pyr_seq_no IN ('1', '01')
	LEFT JOIN smsdss.hosp_svc_dim_v      AS D
	ON A.hosp_svc = D.hosp_svc
		AND A.Regn_Hosp = D.orgz_cd
	
	WHERE a.Dsch_Date >= @START_DATE
	AND a.Dsch_Date < @END_DATE
	AND a.Med_Rec_No IS NOT NULL
	AND a.tot_chg_amt > 0
	AND LEFT(A.PTNO_NUM, 1) != '7'
)
INSERT INTO @HCRA_POP
SELECT * FROM CTE
OPTION(FORCE ORDER);

---------------------------------------------------------------------------------------------------
-- GET '5' FIELD INSURANCE INFORMATION FROM SMSDSS.C_INS_USER_FIELDS_V

DECLARE @INS_INFO TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter VARCHAR(12)
	, Pyr_Cd    VARCHAR(5)
	, Ins_Name  VARCHAR(50)
	, Ins_City  VARCHAR(50)
	, Ins_State VARCHAR(50)
);

WITH CTE AS (
	SELECT PT_ID
	, pyr_cd
	, Ins_Name
	, Ins_City
	, Ins_State

	FROM SMSDSS.c_ins_user_fields_v

	WHERE pt_id IN (
		SELECT A.PT_ID
		FROM @HCRA_POP AS A
	)
)

INSERT INTO @INS_INFO
SELECT * FROM CTE

--SELECT * FROM @INS_INFO;
---------------------------------------------------------------------------------------------------
-- PAYMENTS W PIP VIEW
DECLARE @PIP_PMTS TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, PT_ID VARCHAR(12)
	, PYR_CD VARCHAR(5)
	, TOT_PYMTS_W_PIP MONEY
);

WITH CTE AS (
	SELECT PIP.pt_id
	, PIP.pyr_cd
	, SUM(PIP.tot_pymts_w_pip) AS tot_pymts_w_pip
	
	FROM smsdss.c_tot_pymts_w_pip_plan_lvl_v PIP
	INNER JOIN @HCRA_POP A
	ON A.PT_ID= PIP.pt_id
	
	GROUP BY PIP.pt_id, PIP.pyr_cd
)

INSERT INTO @PIP_PMTS
SELECT * FROM CTE
OPTION(FORCE ORDER);
--SELECT * FROM @PIP_PMTS;
---------------------------------------------------------------------------------------------------
SELECT *

FROM @HCRA_POP      AS A
LEFT JOIN @INS_INFO AS B
ON A.PT_ID = B.Encounter
	AND A.[Primary Payor] = B.Pyr_Cd
LEFT MERGE JOIN @PIP_PMTS AS C
ON A.PT_ID = C.PT_ID
	AND A.[Primary Payor] = C.PYR_CD

OPTION(FORCE ORDER);