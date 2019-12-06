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
***********************************************************************
*/

-- Declare and Set @START and @END datetime variables
DECLARE @START DATETIME;
DECLARE @END DATETIME;

SET @START = '2018-01-01';
SET @END = '2019-07-01';

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
	AdmitOrdDT.svc_cd AS [Order Type],
	WELLSOFT.Arrival AS [Arrival DTime],
	WELLSOFT.[Decision To Admit],
	AdmitOrdDT.ENT_DTIME AS [Admit Order Entry DTime],
	WELLSOFT.Admit_Confirm,
	WELLSOFT.AdmitOrdersDT AS [DTime Unit Sec States as Eff DTime]
	/*
Description: 
In the Active Patient Data File, this field identifies the date that the 
change was processed by the system.
*/
	,
	CenHist.last_data_cngdtime AS [DTime Processed by System]
	-- Get datediff in minutes from step to step
	,
	[Arrival To DTA Delta Minutes] = DATEDIFF(MINUTE, WELLSOFT.ARRIVAL, WELLSOFT.[DECISION TO ADMIT]),
	[DTA To AdmOrd Delta Minutes] = DATEDIFF(MINUTE, WELLSOFT.[DECISION TO ADMIT], ADMITORDDT.ENT_DTIME),
	[AdmOrdEnt To AdmConfirm Delta Minutes] = DATEDIFF(MINUTE, AdmitOrdDT.ENT_DTIME, Wellsoft.Admit_Confirm),
	[AdmConfirm To Eff DTime Delta Minutes] = DATEDIFF(MINUTE, Wellsoft.Admit_Confirm, Wellsoft.AdmitOrdersDT),
	[AdmConfirm To Sys Proc DT Delta Minutes] = DATEDIFF(MINUTE, Wellsoft.Admit_Confirm, CenHist.last_data_cngdtime),
	[AdmOrdEnt to SysProc DT Delta Minutes] = DATEDIFF(MINUTE, AdmitOrdDT.Ent_DTIME, CenHist.last_data_cngdtime)
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
WHERE WELLSOFT.Arrival >= @START
	AND WELLSOFT.Arrival < @END
	AND LEFT(WELLSOFT.ACCOUNT, 1) = '1'
	AND Wellsoft.disposition NOT IN ('lwbs', 'ama')
--and Wellsoft.Account = '14507305'
ORDER BY Wellsoft.Arrival
OPTION (FORCE ORDER);

-----
SELECT *
INTO #temp_b
FROM #temp_a
WHERE [DECISION TO ADMIT] IS NOT NULL
	AND [Admit Order Entry DTime] IS NOT NULL
	AND [Admit_Confirm] IS NOT NULL;

-----
SELECT A.Account,
	A.[Order Type],
	A.[Arrival DTime],
	A.[Decision To Admit],
	A.[Admit Order Entry DTime],
	A.[Admit_Confirm],
	A.[DTime Unit Sec States as Eff DTime],
	A.[DTime Processed by System],
	A.[Arrival To DTA Delta Minutes],
	A.[DTA To AdmOrd Delta Minutes],
	A.[AdmOrdEnt To AdmConfirm Delta Minutes],
	A.[AdmConfirm To Eff DTime Delta Minutes],
	A.[AdmConfirm To Sys Proc DT Delta Minutes],
	A.[AdmOrdEnt to SysProc DT Delta Minutes],
	A.EDMDID,
	A.ED_MD,
	A.Adm_Dr_No,
	A.Adm_Dr,
	A.Hospitalist_Flag
	-- 1 = SUN, 2 = MON, ..., 7 = SAT
	,
	DATEPART(DW, [Arrival DTime]) AS [Arr_DOW]
	-- 0 = MIDNIGHT, 23 = 11PM
	,
	DATEPART(HOUR, [Arrival DTime]) AS [Arr_Hr]
FROM #temp_b AS A;

-----
DROP TABLE #TEMP_A,
	#TEMP_B

