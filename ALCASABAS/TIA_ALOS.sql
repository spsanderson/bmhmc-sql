-- VARIABLE DECLARATION AND INTIALIZATION
DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2014-04-01'
SET @END   = '2014-05-01'

SELECT PDV.pract_rpt_name
, PAV.PtNo_Num
, PAV.Med_Rec_No
, PAV.Pt_Name
, PAV.Adm_Date
, PAV.Dsch_Date
, DATEDIFF(DAY, PAV.Adm_Date, PAV.Dsch_Date) AS LOS

FROM smsdss.BMH_PLM_PtAcct_V        PAV
JOIN smsdss.pract_dim_v		        PDV
ON PAV.Atn_Dr_No = PDV.src_pract_no

WHERE PAV.drg_no IN (67, 68,69)
AND PAV.Dsch_Date >= @START
AND PAV.Dsch_Date < @END
AND PAV.Plm_Pt_Acct_Type = 'I'
AND PAV.PtNo_Num < '20000000'
AND PDV.orgz_cd = 'S0X0'

ORDER BY PDV.pract_rpt_name