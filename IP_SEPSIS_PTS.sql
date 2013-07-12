DECLARE @SD DATETIME
DECLARE @ED DATETIME
SET @SD = '2013-05-01';
SET @ED = '2013-05-31';

-- COLUMN SELECTION
SELECT 
DISTINCT PV.PtNo_Num AS 'VISIT ID'
, PV.Med_Rec_No AS 'MRN'
, PV.vst_start_dtime AS 'ADMIT'
, PV.vst_end_dtime AS 'DISC'
, PV.Days_Stay AS 'LOS'
, PV.pt_type AS 'PT TYPE'
, PV.hosp_svc AS 'HOSP SVC'
, SO.ord_no AS 'ORDER NUMBER'
--, SO.ent_dtime AS 'ORDER ENTRY TIME'
--, DATEDIFF(HOUR,PV.vst_start_dtime,SO.ent_dtime) AS 'ADM TO ENTRY HOURS'
, SO.svc_cd
, SO.svc_desc AS 'ORDER DESCRIPTION'
, OSM.ord_sts AS 'ORDER STATUS'
--, MIN(SOS.prcs_dtime) AS 'ORDER STATUS TIME'
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
AND PV.hosp_svc NOT IN (
	'DIA'
	,'DMS'
	,'EME'
	)
AND PV.Adm_Date BETWEEN @SD AND @ED
AND SO.svc_cd IN (
	'00407304',
	'00507301',
	'00600015',
	'00402347',
	'PRE_P2368',
	'P_2368',
	'P_2372',
	'P_17290',
	'P_2680',
	'PRE_12107BOLUS',
	'P_2501',
	'P_2502',
	'P_12107',
	'P_12106',
	'PRE_P12105',
	'PRE_12107500',
	'PRE_12108BOL',
	'P_2376',
	'P_2371',
	'P_2375',
	'P_48539',
	'P_48540',
	'P_12105',
	'P_12108',
	'PRE_20653IV01',
	'PRE_568701',
	'PRE_P2393OT',
	'P_2393',
	'P_2390',
	'P_25384',
	'PRE_12099IVCD',
	'Dextrose 10% In',
	'P_12098',
	'P_12081',
	'P_48542',
	'P_2500',
	'P_2369',
	'P_12082',
	'P_12078',
	'P_43291',
	'P_12079',
	'P_48541',
	'P_2497',
	'PRE_26881125H',
	'P_12089',
	'P_12088',
	'P_12085',
	'P_12093',
	'P_12092',
	'P_12097',
	'P_12096',
	'PRE_33620IV1',
	'PRE_33620IV2',
	'PRE_33620IV3',
	'PRE_33620IV4',
	'PRE_33620IV5',
	'P_33620',
	'P_12095'
	)
-- THE FOLLOWING GETS RID OF ORDERS THAT WERE DISCONTINUED
-- ONLY FOR EKG, CHEST XRAY PORTABLE, LACTIC ACID, CBC W/DIFF
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
	AND PV.hosp_svc NOT IN (
		'DIA'
		,'DMS'
		,'EME'
		)
	AND SO.svc_cd IN (
		'00407304',
		'00507301',
		'00600015',
		'00402347'
		)
)
ORDER BY PV.PtNo_Num, SO.ord_no, DATEDIFF(HOUR,PV.vst_start_dtime,SOS.prcs_dtime)