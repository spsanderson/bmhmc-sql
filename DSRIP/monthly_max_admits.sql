SELECT a.PtNo_Num
, a.Med_Rec_No
, CAST(a.Adm_Date AS date)  AS [Admit Date]
, CAST(a.Dsch_Date AS date) AS [Dsch Date]
, a.prin_dx_cd
, a.drg_no
, b.LIHN_Service_Line
, D.READMIT
, D.[READMIT DATE]
, D.INTERIM
, CASE
	WHEN LEFT(A.PtNo_Num, 1) = '8'
		THEN 1
		ELSE 0
  END                       AS [ER Visit]
, CASE
	WHEN LEFT(A.PtNo_Num, 1) = '1'
		THEN 1
		ELSE 0
  END                       AS [IP Visit]
, E.adm_src_desc

FROM smsdss.c_DSRIP_COPD                             AS C
INNER MERGE JOIN SMSDSS.BMH_PLM_PTACCT_V             AS A
ON C.Med_Rec_No = A.Med_Rec_No
LEFT OUTER JOIN SMSDSS.c_LIHN_Svc_Lines_Rpt2_ICD10_v AS B
ON A.Pt_No = B.pt_id
LEFT OUTER JOIN SMSDSS.c_Readmission_IP_ER_v         AS D
ON A.PtNo_Num = D.[INDEX]
LEFT OUTER JOIN SMSDSS.adm_src_dim_v                 AS E
ON A.Adm_Source = E.adm_src
	AND E.orgz_cd = 'NTX0'

WHERE Adm_Date >= '2016-02-01'
AND Adm_Date < '2016-03-01'
AND LEFT(A.PTNO_NUM, 4) != '1999'
AND hosp_svc != 'SUR'
AND (
	PtNo_Num < '20000000'
	OR
			(
				A.PtNo_Num >= '80000000' -- ER VISITS
				AND
				A.PtNo_Num < '99999999'
			)
	)

ORDER BY c.Med_Rec_No, Adm_Date
