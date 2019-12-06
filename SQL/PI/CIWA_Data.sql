/*
***********************************************************************
File: CIWA_Data.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
    smsdss.dx_cd_dim_v
    smsmir.mir_sc_Order
    smsmir.mir_sc_PatientVisit
	Customer.Custom_DRG

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get CIWA data for alcohol dependant patients

Revision History:
Date		Version		Description
----		----		----
2019-10-07	v1			Initial Creation
2019-10-10	v2			Add actv_name
						Add ICU flag and ICU LOS
						Add drug record
						Add pt visit flag 1 or null
						Fix LOS and ICU LOS and ICU Count
2019-10-11	v3			Added Aggregate query 
2019-11-20	v4			Added SOI
***********************************************************************
*/

SELECT PAV.Med_Rec_No,
	PAV.PtNo_Num,
	PAV.Pt_No,
	SOI.SEVERITY_OF_ILLNESS,
	PAV.vst_start_dtime AS [Arrival_DTime],
	DATEPART(HOUR, PAV.vst_start_dtime) AS [Arrival_Hr],
	CAST(PAV.ADM_DATE AS DATE) AS [ADM_DATE],
	CAST(PAV.DSCH_DATE AS DATE) AS [DSCH_DATE],
	DATEPART(YEAR, PAV.Adm_Date) AS [Adm_YR],
	PAV.prin_dx_cd,
	DX.alt_clasf_desc,
	ISNULL(CIWA.CIWA_FLAG, 0) AS [CIWA_Flag],
	DATEPART(MONTH, pav.Adm_Date) AS [Adm_Month],
	PAV.Plm_Pt_Acct_Type AS [IP_OP],
	CAST(pav.Days_Stay AS INT) AS [LOS]
INTO #TEMPA
FROM smsdss.BMH_PLM_PtAcct_V AS PAV
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX ON PAV.prin_dx_cd = DX.dx_cd
LEFT OUTER JOIN (
	SELECT b.PatientAccountID,
		MAX(CASE 
				WHEN A.ORDERSETABBRV = 'COS_AlcOpdWthdrw'
					THEN 1
				ELSE 0
				END) AS [CIWA_Flag]
	FROM smsmir.mir_sc_Order AS A
	INNER JOIN smsmir.mir_sc_PatientVisit AS B ON a.Patient_oid = b.Patient_oid
		AND a.PatientVisit_oid = b.StartingVisitOID
	WHERE OrderSetAbbrv = 'COS_AlcOpdWthdrw'
	GROUP BY B.PatientAccountID
	) AS CIWA ON PAV.PtNo_Num = CIWA.PatientAccountID
LEFT OUTER JOIN Customer.Custom_DRG AS SOI
ON PAV.PtNo_Num = SOI.PATIENT#
WHERE PAV.Adm_Date >= '2019-01-01'
	AND PAV.Adm_Date < '2019-11-01'
	AND (
		LEFT(PAV.PTNO_NUM, 1) = '8'
		OR (
			PAV.Plm_Pt_Acct_Type = 'I'
			AND PAV.ED_Adm = 1
			)
		)
	AND PAV.TOT_CHG_AMT > 0
	AND LEFT(PAV.PRIN_DX_CD, 3) = 'F10';

SELECT A.pt_id,
	A.actv_cd,
	B.actv_name,
	SUM(actv_tot_qty) AS [Qty],
	SUM(chg_tot_amt) AS [Tot_Actv_Chg]
INTO #TEMPB
FROM SMSMIR.actv AS A
INNER JOIN SMSDSS.actv_cd_dim_v AS B ON A.actv_cd = B.actv_cd
	AND A.orgz_cd = B.orgz_cd
WHERE pt_id IN (
		SELECT DISTINCT PT_NO
		FROM #TEMPA
		)
	AND a.actv_cd IN ('00300962', '00322610', '00323774', '00326702', '00328161', '00328179', '00328187', '00328203', '00328245', '00329540', '00330548', '00331504', '00331512', '00337287', '00300152', '00300160', '00300178', '00300186', '00300319', '00307827', '00300079', '00300087', '00300095', '00300269', '00300954')
GROUP BY a.pt_id,
	a.actv_cd,
	b.actv_name;

SELECT pt_id,
	actv_cd,
	actv_name,
	Qty,
	CASE 
		WHEN actv_cd = '00300962'
			THEN Qty * 0.25
		WHEN actv_cd = '00322610'
			THEN Qty * 1
		WHEN actv_cd = '00323774'
			THEN Qty * 2
		WHEN actv_cd = '00326702'
			THEN Qty * 0.5
		WHEN actv_cd = '00328161'
			THEN Qty * 5
		WHEN actv_cd = '00328179'
			THEN Qty * 2
		WHEN actv_cd = '00328187'
			THEN Qty * 50
		WHEN actv_cd = '00328203'
			THEN Qty * 30
		WHEN actv_cd = '00328245'
			THEN Qty * 0.5
		WHEN actv_cd = '00329540'
			THEN Qty * 10
		WHEN actv_cd = '00330548'
			THEN Qty * 2
		WHEN actv_cd = '00331504'
			THEN Qty * 10
		WHEN actv_cd = '00331512'
			THEN Qty * 2.5
		WHEN actv_cd = '00337287'
			THEN Qty * 7.5
		WHEN actv_cd = '00300152'
			THEN Qty * 2
		WHEN actv_cd = '00300160'
			THEN Qty * 5
		WHEN actv_cd = '00300178'
			THEN Qty * 10
		WHEN actv_cd = '00300186'
			THEN Qty * 10
		WHEN actv_cd = '00300319'
			THEN Qty * 2
		WHEN actv_cd = '00307827'
			THEN Qty * 15
		WHEN actv_cd = '00300079'
			THEN Qty * 5
		WHEN actv_cd = '00300087'
			THEN Qty * 10
		WHEN actv_cd = '00300095'
			THEN Qty * 25
		WHEN actv_cd = '00300269'
			THEN Qty * 2
		WHEN actv_cd = '00300954'
			THEN Qty * 1
		END AS [Tot_MG],
	Tot_Actv_Chg
INTO #TEMPC
FROM #TEMPB;

SELECT A.Med_Rec_No,
	A.PtNo_Num,
	A.Pt_No,
	A.SEVERITY_OF_ILLNESS,
	A.Arrival_DTime,
	A.Arrival_Hr,
	A.ADM_DATE,
	A.DSCH_DATE,
	A.Adm_YR,
	A.Adm_Month,
	A.prin_dx_cd,
	A.alt_clasf_desc,
	A.CIWA_Flag,
	A.IP_OP,
	[LOS] = CASE 
		WHEN ROW_NUMBER() OVER (
				PARTITION BY A.PtNo_Num ORDER BY A.PtNo_Num
				) = 1
			THEN A.LOS
		ELSE NULL
		END,
	A.LOS AS [LOS_ALL],
	C.actv_cd,
	C.actv_name,
	[ICU_FLAG] = CASE 
		WHEN ICU.pt_id IS NOT NULL
			THEN 1
		ELSE NULL
		END,
	[ICU_LOS] = CASE 
		WHEN ICU.pt_id IS NOT NULL
			THEN ICU.LOS
		ELSE NULL
		END,
	C.Tot_MG AS [Tot_MG],
	[Drug_Record] = 1,
	[Pt_Visit_Flag] = CASE 
		WHEN ROW_NUMBER() OVER (
				PARTITION BY A.PTNO_NUM ORDER BY A.PTNO_NUM
				) = 1
			THEN 1
		ELSE 0
		END
FROM #TEMPA AS A
LEFT OUTER JOIN #TEMPC AS C ON A.Pt_No = C.pt_id
-- GET ICU TIME (MICU, SICU, CCU)
LEFT OUTER JOIN (
	SELECT pt_id,
		SUM(tot_cen) AS [LOS]
	FROM smsdss.dly_cen_occ_fct_v
	WHERE nurs_sta IN ('micu', 'sicu', 'ccu')
	GROUP BY pt_id
	) AS ICU ON A.Pt_No = ICU.pt_id
ORDER BY Med_Rec_No,
	Arrival_DTime;

SELECT A.Adm_Month,
	A.CIWA_Flag,
	A.IP_OP,
	A.SEVERITY_OF_ILLNESS,
	C.actv_cd,
	C.actv_name,
	COUNT(DISTINCT (A.PTNO_NUM)) AS [Visit_Count],
	SUM(A.LOS) AS [Total_Days],
	ROUND(SUM(CAST(A.LOS AS FLOAT)) / NULLIF(COUNT(DISTINCT (A.PTNO_NUM)), 0), 2) AS [ALOS],
	SUM(C.Tot_MG) AS [Total_mg],
	ROUND(SUM(C.TOT_MG) / NULLIF(COUNT(DISTINCT (A.PTNO_NUM)), 0), 2) AS [Avg_MG_PerPt],
	ROUND(SUM(C.TOT_MG) / NULLIF(SUM(A.LOS), 0), 2) AS [Avg_mg/Pt_Day],
	COUNT(DISTINCT (ICU.PT_ID)) AS [ICU_Pts],
	ISNULL(SUM(ICU.LOS), 0) AS [Total_ICU_Days],
	ROUND(ISNULL(SUM(CAST(ICU.LOS AS FLOAT)) / NULLIF(COUNT(DISTINCT (ICU.PT_ID)), 0), 0), 2) AS [ICU_ALOS]
FROM #TEMPA AS A
LEFT OUTER JOIN #TEMPC AS C ON A.Pt_No = C.pt_id
-- GET ICU TIME (MICU, SICU, CCU)
LEFT OUTER JOIN (
	SELECT pt_id,
		SUM(tot_cen) AS [LOS]
	FROM smsdss.dly_cen_occ_fct_v
	WHERE nurs_sta IN ('micu', 'sicu', 'ccu')
	GROUP BY pt_id
	) AS ICU ON A.Pt_No = ICU.pt_id
--WHERE A.PtNo_Num = ''
--WHERE C.actv_name IS NOT NULL
--AND Adm_Month = 6
--AND IP_OP = 'I'
GROUP BY A.Adm_Month,
	A.CIWA_Flag,
	A.IP_OP,
	A.SEVERITY_OF_ILLNESS,
	C.actv_cd,
	C.actv_name;

DROP TABLE #TEMPA,
	#TEMPB,
	#TEMPC;
