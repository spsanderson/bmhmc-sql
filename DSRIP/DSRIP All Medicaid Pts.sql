SELECT A.Med_Rec_No
, A.PtNo_Num
, A.Pt_No
, CASE
	WHEN C.Med_Rec_No IS NOT NULL
		THEN 1
		ELSE 0
  END AS [MAX_Series_Pt]
, CASE
	WHEN LEFT(A.PTNO_NUM, 1) = '1'
		THEN 1
		ELSE 0
  END AS [IP_Flag]
, CASE
	WHEN LEFT(A.PTNO_NUM, 1) = '8'
		THEN 1
		ELSE 0
  END AS [Treat_Release_Flag]
, A.Adm_Date
, A.Dsch_Date
, A.Days_Stay
, D.[READMIT]
, D.[READMIT DATE]
, D.[READMIT SOURCE DESC]
, D.[INTERIM]
, CASE
	WHEN A.User_Pyr1_Cat = 'III'
		THEN 'Managed Medicaide'
		ELSE'FFS Medicaid'
  END AS [Medicaid_Flag]
, A.ED_Adm
, A.prin_dx_cd
, A.prin_dx_cd_schm
, B.alt_clasf_desc
, RN = ROW_NUMBER() OVER(
	PARTITION BY A.med_rec_no
	ORDER BY A.vst_start_dtime
)

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT JOIN smsdss.dx_cd_dim_v AS B
ON A.prin_dx_cd = B.dx_cd
	AND A.prin_dx_cd_schm = B.dx_cd_schm
LEFT JOIN smsdss.c_DSRIP_COPD AS C
ON A.Med_Rec_No = C.Med_Rec_No
LEFT JOIN smsdss.c_Readmission_IP_ER_v AS D
ON A.PtNo_Num = D.[INDEX]
	AND D.[INTERIM] < 31
	AND D.[READMIT SOURCE DESC] != 'Scheduled Admission'

WHERE User_Pyr1_Cat IN (
	'III', 'WWW'
)
AND A.tot_chg_amt > 0
AND LEFT(A.PtNo_Num, 4) != '1999'
AND LEFT(A.PtNo_Num, 1) IN (
	'1', '8'
)
AND DATEPART(YEAR, A.Dsch_Date) = '2016'

