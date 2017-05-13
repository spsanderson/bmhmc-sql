DECLARE @SD DATETIME
DECLARE @ED DATETIME
SET @SD = '2013-06-01';
SET @ED = '2013-06-30';

SELECT
DISTINCT PV.PtNo_Num AS [VISIT ID]
, PV.Med_Rec_No AS MRN
, PV.vst_start_dtime AS ADM
, PV.vst_end_dtime AS DISCH
, PV.Days_Stay AS LOS
, PV.pt_type AS [PT TYPE]
, PV.hosp_svc AS [HOSP SVC]
, PV.Pt_Name AS [PT NAME]
, PV.Pt_Age AS AGE
, PV.Pyr1_Co_Plan_Cd AS INS
, PDV.pract_rpt_name AS MD
, SO.ord_no AS [ORD NUM]
, SO.svc_desc as [SVC DESC]
, SO.pty_name AS [PARTY NAME]
, OSM.ord_sts AS [ORD STS]
, SOS.prcs_dtime AS [ORD STS TIME]
, DATEDIFF(DAY,PV.vst_start_dtime,SOS.prcs_dtime) AS [ADM TO ORD STS IN DAYS]

FROM smsdss.BMH_PLM_PtAcct_V PV
JOIN smsmir.sr_ord SO
ON PV.PtNo_Num = SO.episode_no
JOIN smsmir.sr_ord_sts_hist SOS
ON SO.ord_no = SOS.ord_no
JOIN smsmir.ord_sts_modf_mstr OSM
ON SOS.hist_sts = OSM.ord_sts_modf_cd
JOIN smsdss.pract_dim_v PDV
ON PV.Atn_Dr_No = PDV.src_pract_no

WHERE PV.Adm_Date BETWEEN @SD AND @ED
AND PV.hosp_svc NOT IN (
	'DIA'
	,'DMS'
	,'EME'
	)
AND PV.drg_no IN (377, 378, 379)
AND PDV.spclty_desc != 'NO DESCRIPTION'
AND PDV.pract_rpt_name != '?'
AND PDV.orgz_cd = 'S0X0'
AND SO.ord_no NOT IN (
	SELECT SO.ord_no
	
	FROM smsdss.BMH_PLM_PtAcct_V PV
	JOIN smsmir.sr_ord SO
	ON PV.PtNo_Num = SO.episode_no
	JOIN smsmir.sr_ord_sts_hist SOS
	ON SO.ord_no = SOS.ord_no
	JOIN smsmir.ord_sts_modf_mstr OSM
	ON SOS.hist_sts = OSM.ord_sts_modf_cd
	JOIN smsdss.pract_dim_v PDV
	ON PV.Atn_Dr_No = PDV.src_pract_no
		
	WHERE OSM.ord_sts IN (
	'DISCONTINUE'
	, 'CANCEL'
	)
)