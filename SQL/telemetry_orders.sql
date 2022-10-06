/*
***********************************************************************
File: telemetry_orders.sql

Input Parameters:
	None

Tables/Views:
	smsmir.sr_ord 
    smsmir.ord_sts_modf_mstr
    smsmir.sr_ord_sts_hist
    smsdss.BMH_PLM_PtAcct_V
    smsmir.dx_grp
    smsdss.dx_cd_dim_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get orders for telemetry

Revision History:
Date		Version		Description
----		----		----
2019-05-17	v1			Initial Creation
***********************************************************************
*/

WITH TelemetryOrders
AS (
	SELECT SO.episode_no AS [Encounter],
		SO.ord_no
		--, SO.ord_obj_id
		--, SO.ord_set_id
		,
		SO.ent_dtime,
		SO.str_dtime
		--, SO.discont_date
		,
		OSH.PRCS_DTIME AS [Order_Status_Process_DTime],
		OSH.SIGNON_ID AS [Order_Updated_By],
		SO.svc_cd,
		SO.svc_desc,
		SO.desc_as_written,
		SO.pty_cd AS [Order_Provider_ID],
		SO.pty_name [Order_Provider_Name]
		--, SO.ord_sts
		--, OSM.ord_sts_modf
		,
		SO.sts_no,
		OSM.ord_sts AS [sts_no_desc],
		SO.ord_src_modf,
		SO.ord_src_mne
		-- Find duplicate orders below and then filter them out later
		,
		[RN] = ROW_NUMBER() OVER (
			PARTITION BY SO.EPISODE_NO,
			CAST(SO.ENT_DTIME AS DATE) ORDER BY SO.ENT_DTIME
			)
	FROM smsmir.sr_ord AS SO
	LEFT OUTER JOIN smsmir.ord_sts_modf_mstr AS OSM ON SO.ord_sts = OSM.ord_sts_modf_cd
	LEFT OUTER JOIN smsmir.sr_ord_sts_hist AS OSH ON SO.ORD_NO = OSH.ORD_NO
		AND SO.ORD_OBJ_ID = OSH.ORD_OBJ_ID
		AND SO.ORD_STS = OSH.HIST_STS
		AND SO.STS_NO = OSH.HIST_NO
		AND SO.EPISODE_NO = OSH.EPISODE_NO
	WHERE (
			(SO.svc_cd = 'PCO_TeleMntrg')
			OR (
				SO.svc_cd = 'ADT03'
				AND SO.desc_as_written = 'Admit to Inpatient - Telemetry'
				)
			)
		AND YEAR(SO.ent_date) = 2018
		--AND SO.episode_no = ''
	)
SELECT A.Encounter,
	CAST(B.Adm_Date AS DATE) AS [Adm_Date],
	CAST(B.Dsch_Date AS DATE) AS [Dsch_Date],
	B.vst_end_dtime,
	A.ord_no,
	A.svc_cd,
	A.svc_desc,
	A.desc_as_written,
	A.ord_src_modf,
	A.ord_src_mne,
	A.ent_dtime,
	A.str_dtime,
	A.Order_Provider_ID,
	A.Order_Provider_Name,
	A.sts_no,
	A.sts_no_desc,
	A.Order_Status_Process_DTime,
	A.Order_Updated_By,
	CASE 
		WHEN B.vst_end_dtime < A.Order_Status_Process_DTime
			THEN DATEDIFF(HOUR, A.str_dtime, B.vst_end_dtime)
		ELSE DATEDIFF(HOUR, A.str_dtime, A.Order_Status_Process_DTime)
		END AS [Hours_On_Telemtry],
	B.Pt_Age,
	B.Pt_Sex,
	C.dx_cd AS [Coded_Admit_Dx_Cd],
	D.alt_clasf_desc AS [Coded_Admit_Dx_Cd_Name],
	DATEPART(MONTH, B.ADM_DATE) AS [Adm_Month],
	DATEPART(MONTH, B.Dsch_Date) AS [Dsch_Month],
	DATENAME(WEEKDAY, B.ADM_DATE) AS [Adm_DOW],
	DATENAME(WEEKDAY, B.Dsch_Date) AS [Dsch_DOW],
	CAST(A.ent_dtime AS DATE) AS [Ord_Ent_Date],
	DATEPART(MONTH, A.ENT_DTIME) AS [Ord_Ent_Month],
	DATENAME(WEEKDAY, A.ENT_Dtime) AS [Ord_Ent_DOW],
	DATEPART(HOUR, A.ENT_DTIME) AS [Ord_Ent_Hour],
	DATEPART(MONTH, A.str_dtime) AS [Ord_Str_Month],
	DATENAME(WEEKDAY, A.str_dtime) AS [Ord_Str_DOW],
	DATEPART(HOUR, A.str_dtime) AS [Ord_Str_Hour],
	DATEPART(MONTH, A.Order_Status_Process_DTime) AS [Ord_End_Month],
	DATENAME(WEEKDAY, A.Order_Status_Process_DTime) AS [Ord_End_DOW],
	DATEPART(HOUR, A.Order_Status_Process_DTime) AS [Ord_End_Hour]
	-- Is the coded admitting dx an indicatd diagnosis for Telemetry
	,
	[Admitting_Dx_Indication_Flag] = CASE 
		WHEN C.dx_cd IN (
				-- SYNCOPE
				'R55', 'G90.1', 'F48.8',
				-- HEART BLOCK
				'I44.0', 'I44.1', 'I44.2', 'I44.30', 'I44.4', 'I44.5', 'I44.60', 'I44.69', 'I44.7', 'I45.0', 'I45.10', 'I45.2', 'I45.3', 'I45.4', 'I45.5', 'I45.6', 'I45.19', 'I45.9',
				-- Atrial Flutter
				'I48.92', 'I48.4', 'I49.8', 'I49.02',
				-- ATRIL FIBRILLATION
				'I48.91', 'I48.1', 'I48.2', 'I49.8', 'I49.01',
				-- CHEST PAIN
				'R07.9', 'R07.89', 'I20.9', 'R07.81', 'R07.2',
				-- NON-STEMI
				'I21.9', 'I21.4', 'I22.2', 'I21.A1', 'I97.790', 'I97.791',
				--UNSTABLE ANGINA
				'I20.0', 'I20.1', 'I20.8', 'I20.9',
				--HEART FAILURE: 
				'I50.20', 'I50.21', 'I50.22', 'I50.23', 'I50.30', 'I50.31', 'I50.32', 'I50.33', 'I50.40', 'I50.41', 'I50.42', 'I50.43', 'I50.810', 'I50.811', 'I50.812', 'I50.813', 'I50.814', 'I50.82', 'I50.9', 'I70.90', 'I01.8', 'I02.0', 'I70.90',
				--STROKE:
				'I63.0', 'I63.1', 'I63.2', 'I63.5', 'I63.6', 'I63.81', 'I63.9', 'I64.XX', 'i97.810', 'I97.811', 'I97.820', 'I97.821',
				--ARRHYTHMIA:
				'I45.9', 'I49.9', 'I49.49', 'I49.8', 'I47.0', 'F45.8'
				)
			THEN 1
				-- HEART FAILURE EXTENSION
		WHEN C.dx_cd BETWEEN 'I97.130'
				AND 'I97.139'
			THEN 1
				-- STROKE EXTENSION
		WHEN C.dx_cd BETWEEN 'I64.00'
				AND 'I64.99'
			THEN 1
				-- DRUG TOXICITY
		WHEN (
				LEFT(C.dx_cd, 3) BETWEEN 'T38'
					AND 'T65'
				AND RIGHT(C.dx_cd, 1) = 'A'
				)
			THEN 1
		ELSE 0
		END,
	[Monitoring_Order_Occurance] = CASE 
		WHEN A.svc_cd = 'PCO_TeleMntrg'
			THEN ROW_NUMBER() OVER (
					PARTITION BY A.Encounter,
					A.SVC_CD ORDER BY A.ENCOUNTER,
						A.ENT_DTIME ASC
					)
		ELSE 0
		END,
	[Tele_Admit_Order_Occurance] = CASE 
		WHEN A.svc_cd = 'ADT03'
			THEN ROW_NUMBER() OVER (
					PARTITION BY A.Encounter,
					A.SVC_CD ORDER BY A.ENCOUNTER,
						A.ENT_DTIME ASC
					)
		ELSE 0
		END,
	[Order_Occurrance_Flag] = ROW_NUMBER() OVER (
		PARTITION BY A.ENCOUNTER ORDER BY A.ENCOUNTER,
			A.ENT_DTIME ASC
		)
INTO #TEMPA
FROM TelemetryOrders AS A
LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS B ON A.Encounter = B.PtNo_Num
LEFT OUTER JOIN smsmir.dx_grp AS C ON B.Pt_No = C.pt_id
	AND B.unit_seq_no = C.unit_seq_no
	AND LEFT(C.dx_cd_type, 2) = 'DA'
	AND C.dx_cd_prio = '01'
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS D ON C.dx_cd = D.dx_cd
	AND C.dx_cd_schm = D.dx_cd_schm
WHERE B.Dsch_Date IS NOT NULL
	AND B.tot_chg_amt > 0
	AND LEFT(B.PTNO_NUM, 1) != '2'
	AND LEFT(B.PTNO_NUM, 4) != '1999'
	AND Plm_Pt_Acct_Type = 'I'
	AND C.dx_cd IS NOT NULL
	-- filter out duplicate orders from above
	AND RN = 1
OPTION (FORCE ORDER);

SELECT A.*,
	[Same_Day_Order_Flag] = CASE 
		WHEN ROW_NUMBER() OVER (
				PARTITION BY A.ENCOUNTER,
				A.ORD_ENT_DATE ORDER BY A.ENCOUNTER,
					A.ORD_ENT_DATE
				) > 1
			THEN 1
		ELSE 0
		END,
	[Monitoring_Order_Flag] = CASE 
		WHEN A.svc_cd = 'ADT03'
			THEN 1
		ELSE 0
		END,
	[Admit_Order_Flag] = CASE 
		WHEN A.svc_cd = 'PCO_TeleMntrg'
			THEN 1
		ELSE 0
		END,
	[Hours_Since_Last_Order] = CASE 
		WHEN A.Order_Occurrance_Flag > 1
			THEN DATEDIFF(HOUR, (
						SELECT TOP 1 ZZZ.ent_dtime
						FROM #TEMPA AS ZZZ
						WHERE ZZZ.Order_Occurrance_Flag = (A.Order_Occurrance_Flag - 1)
							AND ZZZ.Encounter = A.Encounter
						), A.ent_dtime)
		ELSE 0
		END
FROM #TEMPA AS A
	;
DROP TABLE #TEMPA
    ;

