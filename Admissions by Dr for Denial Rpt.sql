-- Get the Doctors Name from SoftMed
DECLARE @SM_MD TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Name                VARCHAR(50)
	, NPI                 INT
	, MD_Status           CHAR(8)
);

WITH CTE1 AS (
	SELECT A.NAME
	, A.NPI
	, A.STATUS

	FROM [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[BMH_RosterList_V] AS A

	WHERE A.STATUS = 'Approved'
)

INSERT INTO @SM_MD
SELECT * FROM CTE1

--SELECT * FROM @SM_MD

-- Get the doctors information from the pract_dim_v to join up
-- on the softmed view
DECLARE @PRACT_DIM_MD TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Name                VARCHAR(50)
	, NPI                 INT
	, ID_NUM              CHAR(6)
);

WITH CTE2 AS(
	SELECT pract_rpt_name
	, npi_no
	, src_pract_no

	FROM SMSDSS.pract_dim_v
	WHERE orgz_cd = 'S0X0'
	AND npi_no != '?'
)

INSERT INTO @PRACT_DIM_MD
SELECT * FROM CTE2

--SELECT * FROM @PRACT_DIM_MD

-- Pull the softmed and pract_dim_v together
DECLARE @Final TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Name                VARCHAR(50)
	, ID_num              CHAR(6)
);

WITH Final AS (
	SELECT B.Name
	, A.ID_NUM

	FROM @PRACT_DIM_MD AS A
	INNER JOIN @SM_MD  AS B
	ON A.NPI = B.NPI
)

INSERT INTO @Final
SELECT * FROM Final

--SELECT * FROM @Final

-- Get the admits by Doctor with the SoftMed Name
SELECT COUNT(DISTINCT(pt_no)) AS [Pt Count]
, CASE
	WHEN User_Pyr1_Cat IN ('AAA','ZZZ') THEN 'Medicare'
	WHEN User_Pyr1_Cat = 'WWW' THEN 'Medicaid'
	WHEN User_Pyr1_Cat = 'MIS' THEN 'Self Pay'
	WHEN User_Pyr1_Cat = 'CCC' THEN 'Comp'
	WHEN User_Pyr1_Cat = 'NNN' THEN 'No Fault'
	ELSE 'Other'
  END             AS [Payer Category]
, Atn_Dr_No
, b.pract_rpt_name
, MONTH(Adm_Date) AS [Adm_Mo]
, YEAR(Adm_Date)  AS [Adm_Yr]
, a.Pyr1_Co_Plan_Cd
, F.Name          AS [SoftMed Name]

FROM smsdss.BMH_PLM_PtAcct_V          AS A
LEFT OUTER JOIN smsmir.mir_pract_mstr AS B
ON a.Atn_Dr_No = b.pract_no 
	AND b.src_sys_id = '#PMSNTX0'
LEFT OUTER JOIN @Final                AS F
ON A.Atn_Dr_No = F.ID_num

WHERE Adm_Date BETWEEN '2013-01-01 00:00:00.000' AND '2015-12-31 23:59:59.000' 
AND tot_chg_amt > '0'
AND Plm_Pt_Acct_Type='I'
AND Atn_Dr_No != '000059' -- TESTCPOE DOCTOR
--AND hosp_svc <> 'PSY'

GROUP BY user_pyr1_cat
, Atn_Dr_No
, pract_rpt_name
, MONTH(Adm_Date)
, YEAR(Adm_Date)
, Pyr1_Co_Plan_Cd
, f.Name