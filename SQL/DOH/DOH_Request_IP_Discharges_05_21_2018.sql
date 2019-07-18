SELECT A.Med_Rec_No
, A.PtNo_Num
, A.Pt_Name
, A.Pt_Age
, A.prin_dx_cd
, D.alt_clasf_desc
, CAST(A.Adm_Date AS date) AS [Adm_Date]
, CAST(A.Dsch_Date AS date) AS [Dsch_Date]
, B.pract_rpt_name AS [Admitting_Provider]
, C.WARD_CD

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsdss.pract_dim_v AS B
ON A.Adm_Dr_No = B.src_pract_no
	AND A.Regn_Hosp = B.orgz_cd
LEFT OUTER JOIN smsmir.vst_rpt AS C
ON A.PT_NO = C.PT_ID
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS D
ON A.prin_dx_cd = D.dx_cd
	AND A.prin_dx_cd_schm = D.dx_cd_schm

WHERE A.tot_chg_amt > 0
AND LEFT(A.PtNo_Num, 1) != '2'
AND LEFT(A.PtNo_Num, 4) != '1999'
AND A.Plm_Pt_Acct_Type = 'I'
AND A.Dsch_Date >= '2018-01-01'

ORDER BY Dsch_Date

OPTION(FORCE ORDER)

GO
;