DECLARE @SD DATETIME;
DECLARE @ED DATETIME;
SET @SD = '2014-01-01';
SET @ED = '2014-02-28';

SELECT DISTINCT VR.acct_no AS [VISIT ID]
, VR.vst_med_rec_no MRN
, VR.dsch_date 
, PV.Days_Stay [LOS]
, VR.dsch_disp
, VR.ward_cd
, DATEPART(MONTH, VR.dsch_date) AS [MONTH]
, DATEPART(YEAR, VR.dsch_date) AS [YEAR]
, PDV.pract_rpt_name [ATTENDING MD]
, PDV.med_staff_dept

FROM smsmir.vst_rpt VR
JOIN smsdss.BMH_PLM_PtAcct_V PV
ON VR.acct_no = PV.PtNo_Num
JOIN smsdss.pract_dim_v PDV
ON PV.Atn_Dr_No = PDV.src_pract_no

WHERE VR.dsch_date BETWEEN @SD AND @ED
AND ward_cd IS NOT NULL
AND PDV.med_staff_dept = 'Family Practice'
AND PDV.orgz_cd = 'S0X0'
AND VR.dsch_disp = 'AMA'

ORDER BY VR.dsch_date ASC
