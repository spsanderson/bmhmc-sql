DECLARE @SD DATETIME;
DECLARE @ED DATETIME;
SET @SD = '2010-01-01';
SET @ED = '2014-07-01';

SELECT DISTINCT VR.acct_no AS [VISIT ID]
, VR.vst_med_rec_no MRN
, VR.dsch_date
, PV.Days_Stay [LOS]
, VR.dsch_disp
, VR.ward_cd
, DATEPART(MONTH, VR.dsch_date) AS [MONTH]
, DATEPART(YEAR, VR.dsch_date) AS [YEAR]
, (
   CAST(DATEPART(YEAR, VR.Dsch_Date) 
   AS VARCHAR(5)) 
   + '-' 
   + CAST(DATEPART(QUARTER, VR.Dsch_Date)
   AS VARCHAR(5))
   )                                        AS [YYYYqN]
, PDV.pract_rpt_name [ATTENDING MD]
, PDV.med_staff_dept
, PDV.src_spclty_cd
, CASE
	WHEN PDV.src_spclty_cd = 'HOSIM'
		THEN 1
		ELSE 0
  END AS HOSPITALIST_FLAG

FROM smsmir.vst_rpt VR
JOIN smsdss.BMH_PLM_PtAcct_V PV
ON VR.acct_no = PV.PtNo_Num
JOIN smsdss.pract_dim_v PDV
ON PV.Atn_Dr_No = PDV.src_pract_no

WHERE VR.dsch_date >= @SD 
AND VR.dsch_date < @ED
AND ward_cd IS NOT NULL
AND PDV.orgz_cd = 'S0X0'
AND VR.dsch_disp = 'AMA'

ORDER BY VR.dsch_date ASC