SELECT a.PtNo_Num
, a.Med_Rec_No
, CAST(a.Adm_Date AS date)  AS [Admit Date]
, CAST(a.Dsch_Date AS date) AS [Dsch Date]
, a.prin_dx_cd
, a.prin_dx_icd10_cd
, a.prin_dx_icd9_cd
, a.drg_no
, b.LIHN_Service_Line
, CASE
	WHEN a.User_Pyr1_Cat in ('www', 'iii') 
		THEN 'Medicaid / Managed Medicaid'
	ELSE 'Other'
  END AS [Insurance]

FROM SMSDSS.BMH_PLM_PTACCT_V                         AS A
LEFT OUTER JOIN SMSDSS.c_LIHN_Svc_Lines_Rpt2_ICD10_v AS B
ON A.Pt_No = B.pt_id

WHERE Adm_Date >= '2015-12-15'
AND Adm_Date < '2016-01-15'
AND Plm_Pt_Acct_Type = 'I'
AND PtNo_Num < '20000000'
AND B.LIHN_Service_Line = 'COPD'
