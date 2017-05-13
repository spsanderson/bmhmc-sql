DECLARE @START AS DATE;
DECLARE @END   AS DATE;

SET @START = '2016-07-01';
SET @END   = '2016-10-01';
---------------------------------------------------------------------------------------------------

DECLARE @IP_DISCHARGES TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           CHAR(12)
	, MRN                 CHAR(6)
	, PT_Name             VARCHAR(40)
	, PT_Age_At_Admit     VARCHAR(3)
	, PT_Sex              VARCHAR(5)
	, PT_Marital_Sts      VARCHAR(10)
	, PT_Zip_Code         VARCHAR(10)
	, Admit_Date          DATE
	, Dsch_Date           DATE
	, Attending_MD        VARCHAR(100)
	, Principal_Dx        VARCHAR(500)
	, Dx_Summary_Category VARCHAR(100)
);

WITH CTE AS (
	SELECT A.PtNo_Num
	, A.Med_Rec_No
	, A.Pt_Name
	, A.Pt_Age
	, A.Pt_Sex
	, D.marital_sts_desc
	, A.Pt_Zip_Cd
	, A.Adm_Date
	, A.Dsch_Date
	, B.pract_rpt_name
	, C.clasf_desc
	, C.dx_summ_cat
	
	FROM smsdss.BMH_PLM_PtAcct_V AS A
	LEFT JOIN SMSDSS.pract_dim_v AS B
	ON A.Atn_Dr_No = B.src_pract_no
		AND B.orgz_cd = 'S0X0'
	LEFT JOIN SMSDSS.dx_cd_dim_v AS C
	ON A.prin_dx_cd = C.dx_cd
		AND A.prin_dx_cd_schm = C.dx_cd_schm
	LEFT JOIN smsdss.marital_sts_dim_v AS D
	ON A.Pt_Marital_Sts = D.src_marital_sts
		AND D.src_sys_id = '#PASS0X0'
	
	WHERE A.Dsch_Date >= @START
	AND A.Dsch_Date   <  @END
	AND A.Plm_Pt_Acct_Type = 'I'
	AND A.PtNo_Num < '20000000'
	AND A.tot_chg_amt > 0
	AND LEFT(A.PtNo_Num, 4) != '1999'
	AND LEFT(A.dsch_disp, 1) NOT IN ('C', 'D')
)

INSERT INTO @IP_DISCHARGES
SELECT * FROM CTE;

--SELECT * FROM @IP_DISCHARGES;
---------------------------------------------------------------------------------------------------
DECLARE @ED_RETURN TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           CHAR(12)
	, Readmit             CHAR(12)
	, MRN                 CHAR(6)
	, Admit_Date          DATE
);

WITH CTE AS (
	SELECT A.[INDEX]
	, A.[READMIT]
	, A.[MRN]
	, A.[READMIT DATE]
	
	FROM smsdss.c_Readmission_IP_ER_v AS A
	
	WHERE [INTERIM] < 16
	AND [INTERIM] > 0
	AND LEFT([READMIT], 1) = '8'
	AND A.[INDEX] IN (
		SELECT ZZZ.Encounter
		FROM @IP_DISCHARGES ZZZ
	)
)

INSERT INTO @ED_RETURN
SELECT * FROM CTE;

--SELECT * FROM @ED_RETURN;
---------------------------------------------------------------------------------------------------

SELECT A.MRN
, A.Encounter    AS INITIAL_ENCOUNTER
, A.PT_Name
, A.PT_Age_At_Admit
, A.PT_Sex
, A.PT_Marital_Sts
, A.PT_Zip_Code
, A.Attending_MD AS INITIAL_ATTENDING_MD
, D.ED_MD        AS INITIAL_ED_MD
, A.Principal_Dx AS INTITAL_PRINCIPAL_DX
, A.Dx_Summary_Category
, A.Admit_Date
, A.Dsch_Date
, ISNULL(B.Readmit, '')      AS ED_RETURN_VISIT_ID
, ISNULL(CAST(B.Admit_Date AS VARCHAR), '')   AS ED_RETURN_DATE
, ISNULL(C.ED_MD, '')        AS ED_RETURN_MD
, ISNULL(C.Diagnosis, '')    AS ED_RETURN_DX
, ISNULL(CAST(DATEDIFF(DAY, A.DSCH_DATE, B.ADMIT_DATE) AS VARCHAR),'') AS [INTERIM]
, DATEPART(MONTH, A.DSCH_DATE)             AS [INDEX_DSCH_MONTH]
, DATEPART(YEAR, A.Dsch_Date)              AS [INDEX_DSCH_YEAR]
, '1'                                      AS [ENC_FLAG]
, CASE
	WHEN B.[Readmit] IS NULL
		THEN '0'
		ELSE '1'
  END                                      AS [RA_FLAG]
, [Visit Number] = ROW_NUMBER() OVER(PARTITION BY A.MRN ORDER BY A.ADMIT_DATE)

INTO #TEMP_A

FROM @IP_DISCHARGES                 AS A
LEFT MERGE JOIN @ED_RETURN          AS B
ON A.Encounter = B.Encounter
-- GET THE ED MD OF THE ED RETURN VISIT
LEFT JOIN smsdss.c_Wellsoft_Rpt_tbl AS C
ON B.Readmit = C.Account
-- GET THE ED MD OF THE INITIAL IP VISIT
LEFT JOIN smsdss.c_Wellsoft_Rpt_tbl AS D
ON A.Encounter = D.Account;

---------------------------------------------------------------------------------------------------
SELECT A.MRN
, groupedIPReturns.[Max IP Visit]

INTO #TEMP_B

FROM #TEMP_A AS A
INNER JOIN (
		SELECT ZZZ.MRN, MAX(ZZZ.[Visit Number]) AS [Max IP Visit]
		FROM #TEMP_A AS ZZZ
		GROUP BY ZZZ.MRN
	)groupedIPReturns
ON A.MRN = groupedIPReturns.MRN
	AND A.[Visit Number] = groupedIPReturns.[Max IP Visit]
	
ORDER BY A.MRN;
---------------------------------------------------------------------------------------------------

SELECT A.MRN
, A.ED_RETURN_VISIT_ID
, [15 Day ED Return Number]= ROW_NUMBER() OVER(PARTITION BY A.MRN ORDER BY A.ED_RETURN_DATE)

INTO #TEMP_C

FROM #TEMP_A AS A

WHERE A.ED_RETURN_VISIT_ID != '';
---------------------------------------------------------------------------------------------------

SELECT A.MRN
, groupedEDReturns.[Max ED Visit]

INTO #TEMP_D

FROM #TEMP_C AS A
INNER JOIN (
		SELECT ZZZ.MRN, MAX(ZZZ.[15 DAY ED RETURN NUMBER]) AS [Max ED Visit]
		FROM #TEMP_C AS ZZZ
		GROUP BY ZZZ.MRN
	)groupedEDReturns
ON A.MRN = groupedEDReturns.MRN
	AND A.[15 DAY ED RETURN NUMBER] = groupedEDReturns.[Max ED Visit]
	
ORDER BY A.MRN;

---------------------------------------------------------------------------------------------------

SELECT A.*
, ISNULL(ED.ICD9, '') AS [ED Dx Code]
, ISNULL(DXV.dx_summ_cat, '') AS [ED Dx Category]
, B.[MAX IP VISIT]
, ISNULL(CAST(C.[15 DAY ED RETURN NUMBER] AS VARCHAR), '') AS [Return Enc Number]
, ISNULL(CAST(D.[MAX ED VISIT] AS VARCHAR), '') AS [Max ED Visit]
, ISNULL(ZZZ.[Charity Status], '') AS [Inpatient Charity Status]
, ISNULL(ZZZ.[Medicaid Status], '') AS [Inpatient Mediciad Status]
, ISNULL(ZZZ.paymentAdvisorCategoryName, '') AS [IP Pmt Advice Cat]
, ISNULL(ZZZ.paymentAdvisorSuggestion, '') AS [IP Pmt Advice Suggestion]
, ISNULL(XXX.[Charity Status], '') AS [ED Charity Status]
, ISNULL(XXX.[Medicaid Status], '') AS [ED Medicaid Status]
, ISNULL(XXX.paymentAdvisorCategoryName, '') AS [ED Pmt Advice Cat]
, ISNULL(XXX.paymentAdvisorSuggestion, '') AS [ED Pmt Advice Sugestion]

FROM #TEMP_A AS A
LEFT JOIN #TEMP_B AS B
ON A.MRN = B.MRN
LEFT JOIN #TEMP_C AS C
ON A.ED_RETURN_VISIT_ID = C.ED_RETURN_VISIT_ID
LEFT JOIN #TEMP_D AS D
ON A.MRN = D.MRN
LEFT JOIN smsdss.c_fin_experian_return_file AS ZZZ
ON A.INITIAL_ENCOUNTER = ZZZ.[Account Number]
LEFT JOIN smsdss.c_fin_experian_return_file AS XXX
ON A.ED_RETURN_VISIT_ID = XXX.[Account Number]
LEFT JOIN smsdss.c_Wellsoft_Rpt_tbl AS ED
ON A.ED_RETURN_VISIT_ID = ED.Account
LEFT JOIN smsdss.dx_cd_dim_v AS DXV
ON ED.ICD9 = DXV.dx_cd
;


--DROP TABLE #TEMP_A
--DROP TABLE #TEMP_B
--DROP TABLE #TEMP_C
--DROP TABLE $TEMP_D
