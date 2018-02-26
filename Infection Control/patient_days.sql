DECLARE @SD DATETIME;
DECLARE @ED DATETIME;

SET @SD = '2017-07-01';
SET @ED = '2018-02-01';

----------

SELECT A.pt_id
, a.hosp_svc
, a.nurs_sta
, CAST(a.cen_date AS date) AS [cen_date]
, DATEPART(YEAR, A.CEN_DATE) AS [cen_yr]
, DATEPART(MONTH, A.CEN_DATE) AS [cen_mo]
, a.tot_cen
, a.pract_no AS [Attending_ID]
, UPPER(B.pract_rpt_name) AS [Attending_Name]
, CASE
	WHEN B.src_spclty_cd = 'HOSIM'
		THEN 'Hospitalist'
		ELSE 'Private'
  END AS [Hospitalist_Private]
, CASE
	WHEN B.src_spclty_cd = 'HOSIM'
		THEN '1'
		ELSE '0'
  END AS [Hospitalist_Atn_Flag]
, CASE
	WHEN B.src_spclty_cd != 'HOSIM'
		THEN '1'
		ELSE '0'
  END AS [Private_Atn_Flag]
, CAST(C.Adm_Date AS date) AS [Adm_Date]
, CAST(C.Dsch_Date AS date) AS [Dsch_Date]
-- IF THE DSCH_DATE IS NOT NULL AND THERE ARE $0.00 CHARGES KICK IT OUT
, CASE
	WHEN C.Dsch_Date IS NOT NULL
	AND C.tot_chg_amt <= 0
		THEN 1
		ELSE 0
  END AS [Kick_Out_Flag]

INTO #TEMPA

FROM smsdss.dly_cen_occ_fct_v AS A
LEFT OUTER JOIN smsdss.pract_dim_v AS B
ON A.pract_no = B.src_pract_no
	AND B.orgz_cd = 's0x0'
LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS C
ON A.pt_id = C.Pt_No

WHERE cen_date >= @SD
AND cen_date < @ED

ORDER BY pt_id
, cen_date

GO
;

----------

SELECT A.pt_id
, A.hosp_svc
, A.nurs_sta
, A.cen_date
, A.cen_yr
, A.cen_mo
, A.tot_cen
, A.Attending_ID
, A.Attending_Name
, A.Hospitalist_Private
, A.Hospitalist_Atn_Flag
, A.Private_Atn_Flag
, A.Adm_Date
, A.Dsch_Date
, [RN] = ROW_NUMBER() OVER(PARTITION BY A.PT_ID, A.CEN_DATE ORDER BY A.CEN_DATE)

FROM #TEMPA AS A

WHERE A.Kick_Out_Flag = 0

GO
;

----------

DROP TABLE #TEMPA
GO
;