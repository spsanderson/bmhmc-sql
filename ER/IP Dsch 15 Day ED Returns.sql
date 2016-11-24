DECLARE @START AS DATE;
DECLARE @END   AS DATE;

SET @START = '2016-07-01';
SET @END   = '2016-10-01';
--------------------------

DECLARE @IP_DISCHARGES TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           CHAR(12)
	, MRN                 CHAR(6)
	, Admit_Date          DATE
	, Dsch_Date           DATE
	, Attending_MD        VARCHAR(100)
	, Principal_Dx        VARCHAR(500)
);

WITH CTE AS (
	SELECT A.PtNo_Num
	, A.Med_Rec_No
	, A.Adm_Date
	, A.Dsch_Date
	, B.pract_rpt_name
	, C.clasf_desc
	
	FROM smsdss.BMH_PLM_PtAcct_V AS A
	LEFT JOIN SMSDSS.pract_dim_v AS B
	ON A.Atn_Dr_No = B.src_pract_no
		AND B.orgz_cd = 'S0X0'
	LEFT JOIN SMSDSS.dx_cd_dim_v AS C
	ON A.prin_dx_cd = C.dx_cd
		AND A.prin_dx_cd_schm = C.dx_cd_schm
	
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
, A.Attending_MD AS INITIAL_ATTENDING_MD
, D.ED_MD        AS INITIAL_ED_MD
, A.Principal_Dx AS INTITAL_PRINCIPAL_DX
, A.Admit_Date
, A.Dsch_Date
, B.Readmit      AS ED_RETURN_VISIT_ID
, B.Admit_Date   AS ED_RETURN_DATE
, C.ED_MD        AS ED_RETURN_MD
, C.Diagnosis    AS ED_RETURN_DX
, DATEDIFF(DAY, A.DSCH_DATE, B.ADMIT_DATE) AS [INTERIM]
, DATEPART(MONTH, A.DSCH_DATE)             AS [INDEX_DSCH_MONTH]
, DATEPART(YEAR, A.Dsch_Date)              AS [INDEX_DSCH_YEAR]
, '1'                                      AS [ENC_FLAG]
, CASE
	WHEN B.[Readmit] IS NULL
		THEN '0'
		ELSE '1'
  END                                      AS [RA_FLAG]
, F.pyr_group2

FROM @IP_DISCHARGES                 AS A
LEFT MERGE JOIN @ED_RETURN          AS B
ON A.Encounter = B.Encounter
-- GET THE ED MD OF THE ED RETURN VISIT
LEFT JOIN smsdss.c_Wellsoft_Rpt_tbl AS C
ON B.Readmit = C.Account
-- GET THE ED MD OF THE INITIAL IP VISIT
LEFT JOIN smsdss.c_Wellsoft_Rpt_tbl AS D
ON A.Encounter = D.Account
-- GET PRIMARY PAYOR CATEGORY
LEFT MERGE JOIN smsdss.BMH_PLM_PtAcct_V   AS E
ON A.Encounter = E.PtNo_Num
LEFT JOIN smsdss.pyr_dim_v          AS F
ON E.Pyr1_Co_Plan_Cd = F.src_pyr_cd
	AND E.Regn_Hosp = F.orgz_cd
