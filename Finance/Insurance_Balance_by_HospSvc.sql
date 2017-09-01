SELECT PYR_CD 
, ISNULL(pvt.AMB,0) AS AMB
, ISNULL(pvt.BFM,0) AS BFM
, ISNULL(pvt.BFS,0) AS BFS
, ISNULL(pvt.BHC,0) AS BHC
, ISNULL(pvt.BOC,0) AS BOC
, ISNULL(pvt.BPC,0) AS BPC
, ISNULL(pvt.CAP,0) AS CAP
, ISNULL(pvt.CCP,0) AS CCP
, ISNULL(pvt.CCU,0) AS CCU
, ISNULL(pvt.COU,0) AS COU
, ISNULL(pvt.CTH,0) AS CTH
, ISNULL(pvt.D23,0) AS D23
, ISNULL(pvt.DEX,0) AS DEX
, ISNULL(pvt.DIA,0) AS DIA
, ISNULL(pvt.DMS,0) AS DMS
, ISNULL(pvt.E23,0) AS E23
, ISNULL(pvt.EAC,0) AS EAC
, ISNULL(pvt.EME,0) AS EME
, ISNULL(pvt.EMP,0) AS EMP
, ISNULL(pvt.EOR,0) AS EOR
, ISNULL(pvt.EPA,0) AS EPA
, ISNULL(pvt.EPC,0) AS EPC
, ISNULL(pvt.EPS,0) AS EPS
, ISNULL(pvt.EPY,0) AS EPY
, ISNULL(pvt.GMS,0) AS GMS
, ISNULL(pvt.GYN,0) AS GYN
, ISNULL(pvt.HSP,0) AS HSP
, ISNULL(pvt.INF,0) AS INF
, ISNULL(pvt.LAD,0) AS LAD
, ISNULL(pvt.LAH,0) AS LAH
, ISNULL(pvt.MBA,0) AS MBA
, ISNULL(pvt.MBV,0) AS MBV
, ISNULL(pvt.MED,0) AS MED
, ISNULL(pvt.MHO,0) AS MHO
, ISNULL(pvt.MIC,0) AS MIC
, ISNULL(pvt.MNV,0) AS MNV
, ISNULL(pvt.MOA,0) AS MOA
, ISNULL(pvt.MOR,0) AS MOR
, ISNULL(pvt.MSR,0) AS MSR
, ISNULL(pvt.NEW,0) AS NEW
, ISNULL(pvt.NVP,0) AS NVP
, ISNULL(pvt.OBS,0) AS OBS
, ISNULL(pvt.OBV,0) AS OBV
, ISNULL(pvt.OMS,0) AS OMS
, ISNULL(pvt.ONC,0) AS ONC
, ISNULL(pvt.OPD,0) AS OPD
, ISNULL(pvt.PAS,0) AS PAS
, ISNULL(pvt.PED,0) AS PED
, ISNULL(pvt.PET,0) AS PET
, ISNULL(pvt.PHP,0) AS PHP
, ISNULL(pvt.PMS,0) AS PMS
, ISNULL(pvt.PRE,0) AS PRE
, ISNULL(pvt.PRO,0) AS PRO
, ISNULL(pvt.PSY,0) AS PSY
, ISNULL(pvt.PUL,0) AS PUL
, ISNULL(pvt.REH,0) AS REH
, ISNULL(pvt.SBH,0) AS SBH
, ISNULL(pvt.SCR,0) AS SCR
, ISNULL(pvt.SDU,0) AS SDU
, ISNULL(pvt.SIC,0) AS SIC
, ISNULL(pvt.SLP,0) AS SLP
, ISNULL(pvt.SPE,0) AS SPE
, ISNULL(pvt.SUN,0) AS SUN
, ISNULL(pvt.SUR,0) AS SUR
, ISNULL(pvt.UNK,0) AS UNK
, ISNULL(pvt.WCC,0) AS WCC
, ISNULL(pvt.WCH,0) AS WCH
, ISNULL(pvt.WIS,0) AS WIS

FROM 
(
	SELECT PYRPLAN.pyr_cd
	, VST.hosp_svc
	, PYRPLAN.tot_amt_due AS INS_BAL_AMT

	FROM SMSMIR.PYR_PLAN AS PYRPLAN
	LEFT JOIN smsmir.vst_rpt VST
	ON PYRPLAN.pt_id = VST.pt_id
		   AND PYRPLAN.unit_seq_no = VST.unit_seq_no
	LEFT JOIN smsdss.c_guarantor_demos_v AS GUAR
	ON VST.pt_id = GUAR.pt_id

	WHERE VST.tot_bal_amt > 0
	AND VST.vst_end_date IS NOT NULL
	AND VST.fc not in (
		'1','2','3','4','5','6','7','8','9'
	)
	--AND PYRPLAN.pyr_cd = 'J18'
) A

PIVOT (
	SUM(INS_BAL_AMT)
	FOR HOSP_SVC IN (
		"AMB","BFM","BFS","BHC","BOC","BPC","CAP","CCP","CCU","COU","CTH",
		"D23","DEX","DIA","DMS","E23","EAC","EME","EMP","EOR","EPA","EPC",
		"EPS","EPY","GMS","GYN","HSP","INF","LAD","LAH","MBA","MBV","MED",
		"MHO","MIC","MNV","MOA","MOR","MSR","NEW","NVP","OBS","OBV","OMS",
		"ONC","OPD","PAS","PED","PET","PHP","PMS","PRE","PRO","PSY","PUL",
		"REH","SBH","SCR","SDU","SIC","SLP","SPE","SUN","SUR","UNK","WCC",
		"WCH","WIS"	
	)
) PVT

ORDER BY pyr_cd;