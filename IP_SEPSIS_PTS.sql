DECLARE @SD DATETIME
DECLARE @ED DATETIME
SET @SD = '2013-05-01';
SET @ED = '2013-05-31';

-- COLUMN SELECTION
SELECT DISTINCT PV.PtNo_Num AS 'VISIT ID'
, PV.Med_Rec_No AS 'MRN'
, PV.vst_start_dtime AS 'ADMIT'
, PV.vst_end_dtime AS 'DISC'
, PV.Days_Stay AS 'LOS'
, PV.pt_type AS 'PT TYPE'
, PV.hosp_svc AS 'HOSP SVC'
, SO.ord_no AS 'ORDER NUMBER'
--, SO.ent_dtime AS 'ORDER ENTRY TIME'
--, DATEDIFF(HOUR,PV.vst_start_dtime,SO.ent_dtime) AS 'ADM TO ENTRY HOURS'
, SO.svc_desc AS 'ORDER DESCRIPTION'
, OSM.ord_sts AS 'ORDER STATUS'
, SOS.prcs_dtime AS 'ORDER STATUS TIME'
-- NEGATIVE HRS INDICATES THAT TEST WAS ORDERED PRE-ADMIT SENT OVER BY
-- ED
, DATEDIFF(HOUR,PV.vst_start_dtime,SOS.prcs_dtime) AS 'ADM TO ORD STS IN HRS'

FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V PDV
JOIN smsdss.BMH_PLM_PtAcct_V PV
ON PDV.PtNo_Num = PV.PtNo_Num
JOIN smsdss.dx_cd_dim_v DX
ON PV.prin_dx_cd = DX.dx_cd
JOIN smsmir.sr_ord SO
ON PV.PtNo_Num = SO.episode_no
JOIN smsmir.sr_ord_sts_hist SOS
ON SO.ord_no = SOS.ord_no
JOIN smsmir.ord_sts_modf_mstr OSM
ON SOS.hist_sts = OSM.ord_sts_modf_cd

WHERE PDV.ClasfCd IN (
'785.52', '995.91', '995.92', '995.93', '995.94', '999.39', '999.89'
)
AND PV.Adm_Date BETWEEN @SD AND @ED
AND SO.svc_desc IN (
'CBC WITH WBC DIFFERENTIAL'
,'LACTIC ACID'
,'CHEST PORTABLE XRAY'
,'EKG'
)
-- THE FOLLOWING GETS RID OF ORDERS THAT WERE DISCONTINUED
AND SO.ord_no NOT IN (
	SELECT SO.ord_no
	
	FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V PDV
	JOIN smsdss.BMH_PLM_PtAcct_V PV
	ON PDV.PtNo_Num = PV.PtNo_Num
	JOIN smsdss.dx_cd_dim_v DX
	ON PV.prin_dx_cd = DX.dx_cd
	JOIN smsmir.sr_ord SO
	ON PV.PtNo_Num = SO.episode_no
	JOIN smsmir.sr_ord_sts_hist SOS
	ON SO.ord_no = SOS.ord_no
	JOIN smsmir.ord_sts_modf_mstr OSM
	ON SOS.hist_sts = OSM.ord_sts_modf_cd
	
	WHERE OSM.ord_sts IN (
	'DISCONTINUE'
	,'CANCEL'
	)
	AND PDV.ClasfCd IN (
	'785.52', '995.91', '995.92', '995.93', '995.94', '999.39', '999.89'
	)
	AND SO.svc_desc IN (
	'CBC WITH WBC DIFFERENTIAL'
	,'LACTIC ACID'
	,'CHEST PORTABLE XRAY'
	,'EKG'
	)
)
ORDER BY PV.PtNo_Num, SO.ord_no, SOS.prcs_dtime