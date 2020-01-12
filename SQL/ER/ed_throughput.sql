/*
***********************************************************************
File: ed_throughput.sql

Input Parameters:
	None

Tables/Views:
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
    smsmir.cen_hist
    smsmir.sr_ord
    smsdss.bmh_plm_ptacct_v
    smsdss.pract_dim_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get elements to help understand ED throughput

Revision History:
Date		Version		Description
----		----		----
2019-12-04	v1			Initial Creation
2019-12-18	v2			Add columns for robustness
2019-12-30	v3			Add datetime of last discharge order
						Add vst_end_dtime
***********************************************************************
*/

-- Declare and Set @START and @END datetime variables
DECLARE @START DATETIME;
DECLARE @END DATETIME;

SET @START = '2019-01-01';
SET @END = '2019-12-18';

-----
SELECT WELLSOFT.Account,
	Wellsoft.EDMDID,
	Wellsoft.ED_MD,
	PLM.Adm_Dr_No,
	PDM.pract_rpt_name AS [Adm_Dr],
	CASE 
		WHEN PDM.src_spclty_cd = 'HOSIM'
			THEN 1
		ELSE 0
		END AS [Hospitalist_Flag],
	AdmitOrdDT.svc_cd AS [Order_Type],
	WELLSOFT.Arrival,
	WELLSOFT.[Decision To Admit],
	AdmitOrdDT.ENT_DTIME AS [Admit_Order_Entry_DTime],
	WELLSOFT.Admit_Confirm,
	WELLSOFT.AdmitOrdersDT,
	WELLSOFT.AddedToADMissionsTrack,
	CenHist.last_data_cngdtime AS [Bed_Occupied_Time],
	CenHist.bed AS [Bed_Admitted_To],
	IP_BED.bed AS [First_Non_ER_Bed],
	IP_BED.last_data_cngdtime AS [Non_ER_Bed_Occupied_Time],
	WELLSOFT.TimeLeftED,
	--[Arrival To DTA Delta Minutes] = DATEDIFF(MINUTE, WELLSOFT.ARRIVAL, WELLSOFT.[DECISION TO ADMIT]),
	--[DTA To AdmOrd Delta Minutes] = DATEDIFF(MINUTE, WELLSOFT.[DECISION TO ADMIT], ADMITORDDT.ENT_DTIME),
	--[AdmOrdEnt To AdmConfirm Delta Minutes] = DATEDIFF(MINUTE, AdmitOrdDT.ENT_DTIME, Wellsoft.Admit_Confirm),
	--[AdmConfirm To Eff DTime Delta Minutes] = DATEDIFF(MINUTE, Wellsoft.Admit_Confirm, Wellsoft.AdmitOrdersDT),
	--[AdmConfirm To Sys Proc DT Delta Minutes] = DATEDIFF(MINUTE, Wellsoft.Admit_Confirm, CenHist.last_data_cngdtime),
	--[AdmOrdEnt to SysProc DT Delta Minutes] = DATEDIFF(MINUTE, AdmitOrdDT.Ent_DTIME, CenHist.last_data_cngdtime)
	PLM.vst_end_dtime,
	DschOrdDT.ent_dtime AS [Last_DschOrd_DT]
INTO #temp_a
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS Wellsoft
LEFT JOIN smsmir.mir_cen_hist AS CenHist ON Wellsoft.Account = CenHist.episode_no
	AND CenHist.cng_type = 'A'
-- get the last admit order placed of either ADT03 or ADT11
LEFT JOIN (
	SELECT B.episode_no,
		B.ENT_DTIME,
		B.svc_cd
	FROM (
		SELECT CAST(EPISODE_NO AS VARCHAR(8)) AS Episode_No,
			svc_cd,
			ENT_DTIME,
			ROW_NUMBER() OVER (
				PARTITION BY EPISODE_NO ORDER BY ORD_NO ASC
				) AS ROWNUM
		FROM smsmir.sr_ord
		WHERE svc_Cd IN (
				'ADT03' -- Admit to
				, 'ADT11' -- PLACE IN OBSERVATION TO PHYSICIAN
				)
			AND episode_no < '20000000'
			-- Get orders before and after the start and date times
			-- check for orders placed 5 days before/after the admission date time
			AND ENT_DTIME >= @START - 5
			AND ENT_DTIME <= @END + 5
		) B
	WHERE B.ROWNUM = 1
	) AdmitOrdDT ON Wellsoft.Account = AdmitOrdDT.EPISODE_NO
LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS PLM ON WELLSOFT.ACCOUNT = PLM.PtNo_Num
LEFT OUTER JOIN smsdss.pract_dim_v AS PDM ON PLM.Adm_Dr_No = PDM.src_pract_no
	AND PLM.Regn_Hosp = PDM.orgz_cd
-- Get first bed after cng_type = 'A'
OUTER APPLY (
	SELECT TOP 1 zzz.episode_no,
		zzz.nurs_sta,
		zzz.hosp_svc,
		zzz.last_data_cngdtime,
		zzz.bed,
		zzz.cng_type,
		zzz.seq_no
	FROM smsmir.mir_cen_hist AS zzz
	WHERE CenHist.seq_no < zzz.seq_no
		AND CenHist.episode_no = zzz.episode_no
	ORDER BY zzz.seq_no
	) AS ip_bed
-- Get last dsch ord
LEFT OUTER JOIN (
	SELECT B.episode_no,
		B.ENT_DTIME,
		B.svc_cd
	FROM (
		SELECT CAST(EPISODE_NO AS VARCHAR(8)) AS Episode_No,
			svc_cd,
			ENT_DTIME,
			ROW_NUMBER() OVER (
				PARTITION BY EPISODE_NO ORDER BY ORD_NO DESC
				) AS ROWNUM
		FROM smsmir.sr_ord
		WHERE svc_desc = 'DISCHARGE TO'
			AND episode_no < '20000000'
		) B
	WHERE B.ROWNUM = 1
	) DschOrdDT ON Wellsoft.Account = DschOrdDT.Episode_No
WHERE WELLSOFT.Arrival >= @START
	AND WELLSOFT.Arrival < @END
	AND LEFT(WELLSOFT.ACCOUNT, 1) = '1'
	-- Exclude those that leave before being seen or AMA or mortality
	AND Wellsoft.disposition NOT IN ('lwbs', 'ama', 'Morgue')
	AND PLM.tot_chg_amt > 0
	AND LEFT(PLM.PTNO_NUM, 1) != '2'
	AND LEFT(PLM.PTNO_NUM, 4) != '1999'
ORDER BY Wellsoft.Arrival
OPTION (FORCE ORDER);

-----
SELECT *
INTO #temp_b
FROM #temp_a
WHERE [DECISION TO ADMIT] IS NOT NULL
	AND [Admit_Order_Entry_DTime] IS NOT NULL
	AND [Admit_Confirm] IS NOT NULL;

-----
SELECT A.Account,
	--A.Order_Type,
	A.Arrival,
	A.[Decision To Admit],
	A.[Admit_Order_Entry_DTime],
	A.Admit_Confirm,
	A.AddedToADMissionsTrack,
	A.[Bed_Occupied_Time],
	A.Bed_Admitted_To,
	A.TimeLeftED,
	A.[First_Non_ER_Bed],
	A.[Non_ER_Bed_Occupied_Time],
	A.Last_DschOrd_DT,
	A.vst_end_dtime AS [Dsch_DT],
	--A.[Arrival To DTA Delta Minutes],
	--A.[DTA To AdmOrd Delta Minutes],
	--A.[AdmOrdEnt To AdmConfirm Delta Minutes],
	--A.[AdmConfirm To Eff DTime Delta Minutes],
	--A.[AdmConfirm To Sys Proc DT Delta Minutes],
	--A.[AdmOrdEnt to SysProc DT Delta Minutes],
	A.EDMDID,
	A.ED_MD,
	A.Adm_Dr_No,
	A.Adm_Dr,
	A.Hospitalist_Flag,
	DATEPART(DW, [Arrival]) AS [Arr_DOW],
	DATEPART(HOUR, [Arrival]) AS [Arr_Hr],
	DATENAME(DW, [Arrival]) AS [Arr_DOW_Name]
FROM #temp_b AS A
WHERE A.TimeLeftED != '-- ::00'
ORDER BY A.[Arrival];

-------
DROP TABLE #TEMP_A,
	#TEMP_B
