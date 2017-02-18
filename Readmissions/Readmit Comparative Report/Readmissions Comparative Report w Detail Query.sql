/*
=======================================================================
THE BELOW IS TO BE USED FOR THE COMPARATIVE READMISSIONS REPORT FOR 
ICD-9
=======================================================================
*/
SELECT a.[INDEX]                      AS [Initial_Encounter]
, a.[READMIT]                         AS [Readmit_Encounter]
, a.[READMIT SOURCE DESC]             AS [Readmit_Source]
, a.MRN                               AS [MRN]
, CAST(b.Adm_Date AS DATE)            AS [Initial_Admit_Date]
, CAST(a.[INITIAL DISCHARGE] AS DATE) AS [Initial_Discharge_Date]
, CAST(a.[READMIT DATE] AS DATE)      AS [Readmit_Date]
, a.[INTERIM]                         AS [Days_Until_Readmit]
, b.dsch_disp                         AS [Initial Disposition]
, c.pract_rpt_name                    AS [Attending_Doctor]
, CASE
	WHEN c.src_spclty_cd = 'HOSIM'
	THEN 1
	ELSE 0
  END                                 AS [Hospitalist_Flag]
, CASE
	WHEN b.User_Pyr1_Cat IN ('AAA','ZZZ') 
		THEN 'Medicare'
	WHEN b.User_Pyr1_Cat = 'WWW' 
		THEN 'Medicaid'
	ELSE 'Other'
  END                                 AS [Summary Ins Flag]
, b.prin_dx_icd9_cd                   AS [Principal_ICD9_Code]
, b.prin_dx_icd10_cd                  AS [Principal_ICD10_Code]
, D.LIHN_Service_Line                 AS [Readmit LIHN Service Line]

FROM smsdss.vReadmits                                AS A
LEFT OUTER MERGE JOIN smsdss.bmh_plm_ptacct_v        AS B
ON a.[INDEX] = b.PtNo_Num
	AND a.MRN = b.Med_Rec_No
LEFT OUTER JOIN smsdss.pract_dim_v                   AS C
ON b.Atn_Dr_No = c.src_pract_no
	AND c.orgz_cd = 'S0X0'
LEFT OUTER MERGE JOIN smsdss.c_LIHN_Svc_Lines_Rpt2_v AS D
ON A.[READMIT] = SUBSTRING(d.pt_id, 5, 8)

WHERE INTERIM < 31
AND a.[READMIT SOURCE DESC] != 'Scheduled Admission'
AND b.hosp_svc != 'PSY'
AND b.Adm_Date >= '2015-09-01'
AND b.Adm_Date < '2015-10-01'
-- edit ---------------------------------------------------------------
AND b.tot_chg_amt > '0'
-- end edit -----------------------------------------------------------

ORDER BY a.[INDEX]

/*
=======================================================================
THE BELOW IS TO BE USED FOR THE COMPARATIVE READMISSIONS REPORT FOR 
ICD-10
=======================================================================
*/
SELECT a.[INDEX]                      AS [Initial_Encounter]
, a.[READMIT]                         AS [Readmit_Encounter]
, a.[READMIT SOURCE DESC]             AS [Readmit_Source]
, a.MRN                               AS [MRN]
, CAST(b.Adm_Date AS DATE)            AS [Initial_Admit_Date]
, CAST(a.[INITIAL DISCHARGE] AS DATE) AS [Initial_Discharge_Date]
, CAST(a.[READMIT DATE] AS DATE)      AS [Readmit_Date]
, a.[INTERIM]                         AS [Days_Until_Readmit]
, b.dsch_disp                         AS [Initial Disposition]
, c.pract_rpt_name                    AS [Attending_Doctor]
, CASE
	WHEN c.src_spclty_cd = 'HOSIM'
	THEN 1
	ELSE 0
  END                                 AS [Hospitalist_Flag]
, CASE
	WHEN b.User_Pyr1_Cat IN ('AAA','ZZZ') 
		THEN 'Medicare'
	WHEN b.User_Pyr1_Cat = 'WWW' 
		THEN 'Medicaid'
	ELSE 'Other'
  END                                 AS [Summary Ins Flag]
, b.prin_dx_icd9_cd                   AS [Principal_ICD9_Code]
, b.prin_dx_icd10_cd                  AS [Principal_ICD10_Code]
, D.LIHN_Service_Line                 AS [Readmit LIHN Service Line]

FROM smsdss.vReadmits                                      AS A
LEFT OUTER JOIN smsdss.bmh_plm_ptacct_v              AS B
ON a.[INDEX] = b.PtNo_Num
	AND a.MRN = b.Med_Rec_No
LEFT OUTER JOIN smsdss.pract_dim_v                         AS C
ON b.Atn_Dr_No = c.src_pract_no
	AND c.orgz_cd = 'S0X0'
LEFT OUTER JOIN smsdss.c_LIHN_Svc_Lines_Rpt2_icd10_v AS D
ON A.[READMIT] = SUBSTRING(d.pt_id, 5, 8)

WHERE INTERIM < 31
AND a.[READMIT SOURCE DESC] != 'Scheduled Admission'
AND b.hosp_svc != 'PSY'
AND b.Adm_Date >= '2015-09-01'
AND b.Adm_Date < '2015-10-01'
-- edit ---------------------------------------------------------------
AND b.tot_chg_amt > '0'
-- end edit -----------------------------------------------------------

OPTION(FORCE ORDER);