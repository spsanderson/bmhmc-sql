DECLARE @INS_CD_NAME TABLE (
	PYR_CD           CHAR(3)
	, PYR_NAME       VARCHAR(100)
);

WITH CTE1 AS (
	SELECT pyr_cd
	, pyr_name

	FROM SMSMIR.pyr_mstr
)

INSERT INTO @INS_CD_NAME
SELECT * FROM CTE1
-----------------------------------------------------------------------

SELECT A.PtNo_Num
, A.Pt_No
, A.Med_Rec_No
, A.Pt_SSA_No
, CASE
	WHEN LEFT(A.PYR1_CO_PLAN_CD, 1) IN ('A', 'Z')
		THEN RTRIM(ISNULL(D.POL_NO, '')) + RTRIM(LTRIM(ISNULL(D.grp_no, '')))
		ELSE ''
  END AS HIC
, CASE 
	WHEN LEFT(a.Pyr1_Co_Plan_Cd, 1) = 'W'
		THEN RTRIM(ISNULL(D.POL_NO, '')) + RTRIM(LTRIM(ISNULL(D.GRP_NO, '')))
		ELSE ''
  END AS MEDICAID_ID_Number
, B.pt_first
, B.pt_last
, B.pt_middle
, A.Pt_Birthdate
, A.Pt_Sex
, B.addr_line1
, B.Pt_Addr_Line2
, B.Pt_Addr_City
, B.Pt_Addr_State
, B.Pt_Phone_No
, A.Adm_Date
, C.Arrival         AS [ED ARRIVAL]
, A.Dsch_Date
, A.hosp_svc        AS [PT TYPE]
, ''                AS [Discharge Floor]
, ''                AS [UB Type of Bill Number]
, a.drg_no          AS [DRG Number]
, a.Days_Stay       AS [Length of Stay]
, a.Pyr1_Co_Plan_Cd AS [Primary Ins Code]
, INS1.PYR_NAME     AS [Primary Insurance Name]
, CASE
	WHEN LEFT(INS1.PYR_CD, 1) IN ('A', 'Z')
		THEN RTRIM(ISNULL(D.POL_NO, '')) + RTRIM(LTRIM(ISNULL(D.grp_no, '')))
	WHEN LEFT(a.Pyr1_Co_Plan_Cd, 1) = 'W'
		THEN RTRIM(ISNULL(D.POL_NO, '')) + RTRIM(LTRIM(ISNULL(D.GRP_NO, '')))
		ELSE ''
  END               AS [Primary Insurance Policy Number] 
, a.Pyr2_Co_Plan_Cd AS [Secondary Ins Code]
, INS2.PYR_NAME     AS [Secondary Insurance Name]
, F.pol_no          AS [Secondary Insurance Policy Number]
, a.Pyr3_Co_Plan_Cd AS [Third Ins Code]
, INS3.PYR_NAME     AS [Third Insurance Name]
, G.pol_no          AS [Third Insurance Policy Number]
, a.Pyr4_Co_Plan_Cd AS [Fourth Ins Code]
, INS4.PYR_NAME     AS [Fourth Insurance Name]
, H.pol_no          AS [Fourth Insurance Policy Number]
, a.tot_chg_amt     AS [Total Charges]
, ISNULL(-(E.tot_pay_amt), 0)  AS [Primary Ins Payment Amount]
, ISNULL(-(F.tot_pay_amt), 0)  AS [Secondary Ins Payment Amount]
, ISNULL(-(G.tot_pay_amt), 0)  AS [Third Ins Payment Amount]
, ISNULL(-(H.tot_pay_amt), 0)  AS [Fourth Ins Payment Amount]
, ''                AS [Mothers Patient ID Number]
, ''                AS [Mothers Name]
, DDD.DISPO         AS [NUBC Standard Patient Discharge Status]

INTO #TMP_A

FROM smsdss.BMH_PLM_PtAcct_V        AS A
LEFT JOIN smsdss.c_patient_demos_v  AS B
ON A.Pt_No = B.pt_id
LEFT JOIN smsdss.c_Wellsoft_Rpt_tbl AS C
ON A.PtNo_Num = C.Account
LEFT JOIN smsmir.mir_pyr_plan       AS D
ON A.Pt_No = D.pt_id
	AND A.Pyr1_Co_Plan_Cd = D.pyr_cd
LEFT JOIN @INS_CD_NAME              AS INS1
ON A.Pyr1_Co_Plan_Cd = INS1.PYR_CD
LEFT JOIN SMSMIR.pyr_plan           AS E
ON A.Pyr1_Co_Plan_Cd = E.pyr_cd
	AND E.pyr_seq_no = 1
	AND E.pt_id = A.Pt_No
LEFT JOIN @INS_CD_NAME              AS INS2
ON A.Pyr2_Co_Plan_Cd = INS2.PYR_CD
LEFT JOIN SMSMIR.pyr_plan           AS F
ON A.Pyr2_Co_Plan_Cd = F.pyr_cd
	AND F.pyr_seq_no = 2
	AND F.pt_id = A.Pt_No
LEFT JOIN @INS_CD_NAME              AS INS3
ON A.Pyr3_Co_Plan_Cd = INS3.PYR_CD
LEFT JOIN SMSMIR.pyr_plan           AS G
ON A.Pyr3_Co_Plan_Cd = G.pyr_cd
	AND G.pyr_seq_no = 3
	AND G.pt_id = A.Pt_No
LEFT JOIN @INS_CD_NAME              AS INS4
ON A.Pyr4_Co_Plan_Cd = INS4.PYR_CD
LEFT JOIN SMSMIR.pyr_plan           AS H
ON A.Pyr4_Co_Plan_Cd = H.pyr_cd
	AND H.pyr_seq_no = 4
	AND H.pt_id = A.Pt_No

CROSS APPLY (
	SELECT
		CASE
			WHEN A.dsch_disp = 'ATW' THEN '06'
			WHEN A.dsch_disp = 'AHI' THEN '51'
			WHEN A.dsch_disp = 'AHR' THEN '01'
			WHEN A.dsch_disp = 'ATE' THEN '03'
			WHEN A.dsch_disp = 'ATL' THEN '03'
			WHEN A.dsch_disp = 'ATH' THEN '02'
			WHEN A.dsch_disp = 'ATP' THEN '65'
			WHEN A.dsch_disp = 'D7N' THEN '20'
			WHEN A.dsch_disp = 'D8N' THEN '20'
			WHEN A.dsch_disp = 'AMA' THEN '07'
			WHEN A.dsch_disp = 'ATF' THEN '43'
			WHEN A.dsch_disp = 'ATN' THEN '43'
			WHEN A.dsch_disp = 'ATB' THEN '21'
		END AS DISPO
) DDD

WHERE A.Dsch_Date >= '2015-01-01'
AND A.Dsch_Date < '2016-01-01'
AND A.Plm_Pt_Acct_Type = 'I'
AND A.PtNo_Num < '20000000'
AND LEFT(A.PTNO_NUM, 4) != '1999'
--AND A.User_Pyr1_Cat IN ('AAA', 'ZZZ', 'WWW')

OPTION(FORCE ORDER);

--SELECT * FROM #TMP_A
-----------------------------------------
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
	INNER JOIN #TMP_A AS A
	ON A.Pt_No = PIP.pt_id
	
	GROUP BY PIP.pt_id, PIP.pyr_cd
)

INSERT INTO @PIP_PMTS
SELECT * FROM CTE

--SELECT * FROM @PIP_PMTS
----------------------------------------
SELECT A.ptno_num
, a.med_rec_no
, a.pt_ssa_no
, a.hic
, a.medicaid_id_number
, a.pt_first
, a.pt_last
, a.pt_middle
, a.pt_birthdate
, a.pt_sex
, a.addr_line1
, a.pt_addr_line2
, a.pt_addr_city
, a.pt_addr_state
, a.pt_phone_no
, a.adm_date
, a.[ed arrival]
, a.dsch_date
, a.[pt type]
, a.[discharge floor]
, a.[ub type of bill number]
, a.[drg number]
, a.[length of stay]
, a.[primary ins code]
, a.[primary insurance name]
, a.[primary insurance policy number]
, a.[secondary ins code]
, a.[secondary insurance name]
, a.[secondary insurance policy number]
, a.[third ins code]
, a.[third insurance name]
, a.[third insurance policy number]
, a.[fourth ins code]
, a.[fourth insurance name]
, a.[fourth insurance policy number]
, a.[total charges]
, B.TOT_PYMTS_W_PIP as [primary ins payment amount]
, C.TOT_PYMTS_W_PIP as [secondary ins payment amount]
, D.TOT_PYMTS_W_PIP as [third ins payment amount]
, E.TOT_PYMTS_W_PIP as [fourth ins payment amount]
, a.[mothers patient id number]
, a.[mothers name]
, a.[nubc standard patient discharge status]

INTO #TMP_B

FROM #TMP_A AS A
LEFT JOIN @PIP_PMTS AS B
ON A.PT_NO = B.PT_ID
	AND A.[Primary Ins Code] = RTRIM(LTRIM(B.PYR_CD))
LEFT JOIN @PIP_PMTS AS C
ON A.PT_NO = C.PT_ID
	AND A.[Secondary Ins Code] = RTRIM(LTRIM(C.PYR_CD))
LEFT JOIN @PIP_PMTS AS D
ON A.PT_NO = D.PT_ID
	AND A.[Third Ins Code] = RTRIM(LTRIM(D.PYR_CD))
LEFT JOIN @PIP_PMTS AS E
ON A.PT_NO	= E.PT_ID
	AND A.[Fourth Ins Code] = RTRIM(LTRIM(E.PYR_CD))

--WHERE A.PTNO_NUM = ''

select * from #tmp_b
----------------------------------------

DROP TABLE #TMP_A
DROP TABLE #TMP_B