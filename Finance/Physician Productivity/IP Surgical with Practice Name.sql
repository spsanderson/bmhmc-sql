SELECT COUNT(a.pt_no) AS [Cases]
, MONTH(a.adm_Date)   AS [Svc_Month]
, YEAR(a.adm_Date)    AS [Svc_Year]
, a.Pt_No
, a.pt_type
, a.hosp_svc
,
--b.spclty_cd1,
c.spclty_cd_desc
, 
--a.hosp_svc,
a.atn_dr_no
, b.pract_rpt_name    AS [Attending]
, d.resp_pty_cd
, h.pract_rpt_name    AS [Surgeon]
, d.proc_Cd           AS [Prin_Proc_Cd]
, e.clasf_desc        AS [Prin_Proc_Cd_Desc]
, a.tot_Chg_Amt
, G.UserDataCd

INTO #PATIENT_COUNTS

FROM smsdss.bmh_plm_ptacct_v                  AS A 
LEFT JOIN smsmir.mir_pract_mstr               AS B
ON a.atn_dr_no = b.pract_no 
	AND b.src_sys_id='#PASS0X0'
LEFT OUTER JOIN smsdss.pract_spclty_mstr      AS C
ON b.spclty_cd1 = c.spclty_cd 
	AND c.src_sys_id = '#PMSNTX0'
LEFT OUTER JOIN smsmir.mir_sproc              AS D
ON a.Pt_No = d.pt_id 
	AND d.proc_cd_prio IN ('1','01') 
	AND proc_cd_type = 'PC'
LEFT OUTER JOIN smsmir.mir_clasf_mstr         AS E
ON d.proc_cd=e.clasf_cd
-- add in user two field of 571 for orsos case
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V      AS F
ON A.PtNo_Num = F.PtNo_Num
	AND F.UserDataKey = '571'
LEFT OUTER JOIN smsdss.BMH_UserTwoField_Dim_V AS G
ON F.UserDataKey = G.UserTwoKey
LEFT OUTER JOIN smsmir.mir_pract_mstr         AS H
on d.resp_pty_cd = h.pract_no
	and h.src_sys_id = '#PASS0X0'

WHERE (
	a.pt_type NOT IN ('D','G')
	AND hosp_svc NOT IN ('INF','CTH')
	--AND Atn_Dr_No = ''
	AND (
		Adm_Date >= '2015-01-01' 
		AND Adm_Date < '2016-01-01' 
		OR 
		Adm_Date >= '2016-01-01' 
		AND Adm_Date < '2016-06-01'
	)
	AND a.tot_chg_amt > '0'
	AND LEFT(a.pt_no,5) = '00001'
)
AND F.UserDataKey = '571'

GROUP BY MONTH(a.adm_Date)
, YEAR(a.adm_Date) 
, a.Pt_No
, a.pt_type
, a.hosp_svc
,
--b.spclty_cd1,
c.spclty_cd_desc
, 
--a.hosp_svc,
a.atn_dr_no
, b.pract_rpt_name
, d.resp_pty_cd
, h.pract_rpt_name
, d.proc_Cd 
, e.clasf_desc
, a.tot_Chg_Amt
, G.UserDataCd
---------------------------------------------------------------------------------------------------
--SELECT *
--FROM #PATIENT_COUNTS

---------------------------------------------------------------------------------------------------
-- Get practice names and addresses from the old softmed server
DECLARE @Practice_Info TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Practice Name]      VARCHAR(MAX)
	, [Address Line 1]     VARCHAR(100)
	, [Address Line 2]     VARCHAR(100)
	, [Address Line 3]     VARCHAR(100)
	, [City]               VARCHAR(100)
	, [State]              VARCHAR(100)
	, [Zip Code]           VARCHAR(100)
	, [Phone]              VARCHAR(100)
	, [Fax]                VARCHAR(100)
	, [SoftMed Prov Num]   VARCHAR(100)
	, [Prof Title]         VARCHAR(100)
	, [Doc Name]           VARCHAR(100)
	, [Suffix]             VARCHAR(100)
	, [Status]             VARCHAR(100)
	, [Reason]             VARCHAR(MAX)
	, [DSS Prov Num]       VARCHAR(100)
	, [DSS Doc Name]       VARCHAR(100)
	, [DSS Med Staff Dept] VARCHAR(100)
	, [DSS Specialty]      VARCHAR(100)
	, [DSS Spclty Code]    VARCHAR(100)
);

WITH CTE AS (
	select a.name AS PRACTICE_NAME
	, a.address1
	, a.address2
	, a.address3
	, a.city
	, a.state
	, a.postcode
	, a.phone
	, a.fax
	, c.provnum
	, c.proftitle
	, c.name
	, c.suffix
	, c.status
	, c.reason
	, d.src_pract_no
	, d.pract_rpt_name
	, d.med_staff_dept
	, d.spclty_desc
	, d.spclty_cd

	FROM [bmh-softmed-db].[ssi_bmh_live].[dbo].[cre_practice]               AS A
	LEFT JOIN [BMH-SOFTMED-DB].[SSI_BMH_LIVE].[dbo].[cre_provider_practice] AS B
	ON a._PK = b.pPractice
	LEFT JOIN [BMH-SOFTMED-DB].[SSI_BMH_LIVE].[dbo].[cre_provider]          AS C
	ON b._parent = c._PK
	LEFT JOIN smsdss.pract_dim_v                                            AS D
	ON SUBSTRING(c.provnum, 3, 6) = RTRIM(LTRIM(d.src_pract_no))COLLATE SQL_Latin1_General_CP1_CI_AS
		AND d.orgz_cd = 's0x0'
		
	--where a._pk = '1'
)

INSERT INTO @Practice_Info
SELECT * FROM CTE

SELECT *
, ROW_NUMBER() OVER (
	PARTITION BY A.[DSS PROV NUM]
	ORDER BY A.[DSS PROV NUM]
) AS RN
INTO #PRACT_NAME_TEMP
FROM @Practice_Info AS A
WHERE A.[DSS Prov Num] IS NOT NULL
ORDER BY A.[Practice Name]

--SELECT *
--FROM #PRACT_NAME_TEMP AS A
--WHERE A.RN = 1

---------------------------------------------------------------------------------------------------

SELECT a.*
, b.[practice name]

FROM #patient_counts       AS A
LEFT JOIN #pract_name_temp AS B
ON a.resp_pty_cd = b.[dss prov num]
	AND b.rn = 1

---------------------------------------------------------------------------------------------------
DROP TABLE #PATIENT_COUNTS
DROP TABLE #PRACT_NAME_TEMP