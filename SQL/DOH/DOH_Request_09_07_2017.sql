SELECT A.[MRN]
, B.Pt_Name
--, A.[INDEX]
--, B.PtNo_Num
, C.dsch_disp
, CASE
	WHEN C.dsch_disp = 'ATW'
		THEN 'Home, Adult Home, Assisted Living with Homecare'
	WHEN C.dsch_disp = 'ATL'
		THEN 'SNF - Long Term'
	WHEN C.dsch_disp = 'AHI'
		THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
	WHEN C.dsch_disp = 'ATX'
		THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
	WHEN C.dsch_disp = 'ATT'
		THEN 'Hospice at Home, Adult Home, Assisted Living'
		ELSE D.dsch_disp_desc
  END AS [Initial_Disposition]
, A.[READMIT]
--, A.[READMIT SOURCE DESC]
, A.[READMIT DATE]
--, A.[INTERIM]

FROM smsdss.vReadmits AS A
LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS B
ON A.[READMIT] = B.PtNo_Num
-- Get initial disposition
LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS C
ON A.[INDEX] = C.PtNo_Num
LEFT JOIN smsdss.dsch_disp_dim_v AS D
ON C.dsch_disp = D.dsch_disp
	AND D.orgz_cd = 'NTX0'

WHERE [INTERIM] < 31
AND [INITIAL DISCHARGE] >= '2017-02-01'
AND [INITIAL DISCHARGE] < '2017-08-01'
AND [READMIT SOURCE DESC] != 'SCHEDULED ADMISSION'
AND B.tot_chg_amt > 0;

---------------------------------------------------------------------------------------------------

SELECT A.Med_Rec_No
, A.Pt_Name
, A.PtNo_Num
, CAST(A.Dsch_Date AS date) AS [Dsch_Date]
, A.dsch_disp
, CASE
	WHEN A.dsch_disp = 'ATW'
		THEN 'Home, Adult Home, Assisted Living with Homecare'
	WHEN A.dsch_disp = 'ATL'
		THEN 'SNF - Long Term'
	WHEN A.dsch_disp = 'AHI'
		THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
	WHEN A.dsch_disp = 'ATX'
		THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
	WHEN A.dsch_disp = 'ATT'
		THEN 'Hospice at Home, Adult Home, Assisted Living'
		ELSE B.dsch_disp_desc
  END AS Disp_Desc

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT JOIN smsdss.dsch_disp_dim_v AS B
ON A.dsch_disp = B.dsch_disp
	AND B.orgz_cd = 'NTX0'

WHERE A.Dsch_Date >= '2017-06-01'
AND A.Dsch_Date < '2017-09-01'
AND A.Plm_Pt_Acct_Type = 'I'
AND LEFT(A.PtNo_Num, 4) != '1999'
AND LEFT(A.PTNO_NUM, 1) != '2'
AND A.tot_chg_amt > 0

ORDER BY A.Dsch_Date;
