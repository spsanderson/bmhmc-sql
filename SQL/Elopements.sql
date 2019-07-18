SELECT A.dsch_disp
, A.PtNo_Num
, A.Med_Rec_No
, A.Pt_Name
, CONVERT(VARCHAR, A.Dsch_Date, 110) as dsch_date
, A.DschDay
, A.DschMonth
, YEAR(A.Dsch_Date)                  AS DSCH_YR
, DATEPART(HOUR, A.Dsch_DTime)       AS [HOUR]
, A.hosp_svc
, CAST(A.Days_Stay AS INT)           AS [LOS]
, A.User_Pyr1_Cat
, C.pyr_group2
, A.drg_no
, B.LIHN_Service_Line

FROM smsdss.BMH_PLM_PtAcct_V                   AS A
LEFT OUTER JOIN smsdss.c_LIHN_Svc_Lines_Rpt2_v AS B
ON A.Pt_No = B.pt_id
LEFT OUTER JOIN smsdss.pyr_dim_v               AS C
ON A.Pyr1_Co_Plan_Cd = C.src_pyr_cd
	AND C.orgz_cd = 'S0X0'

WHERE A.PtNo_Num < '20000000'
AND A.dsch_disp IS NOT NULL
AND A.Dsch_Date > '2015-01-01'
AND A.dsch_disp = 'AMA'
AND A.prin_dx_cd_schm = '9'

ORDER BY A.PtNo_Num