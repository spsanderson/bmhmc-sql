/*
***********************************************************************
File: ed_throughput_mpeddie.sql

Input Parameters:
	None

Tables/Views:
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
    [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
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

Special Notes:
From the discharge section we are excluding patients that
1.	Leave AMA
2.	Expire
3.	Are obs and then subsequently admitted
4.	Patients that were admitted to a procedure room directly from the ER (DOS, Cath, Pacu)
5.	Hospice patients

From the admission section we are excluding patients that
1.	Are obs and then subsequently admitted
2.	Patients that were admitted to a procedure room directly from the ER (DOS, Cath, Pacu)
3.	Hospice patients
4.	Patients that were direct admits


Revision History:
Date		Version		Description
----		----		----
2021-07-14	v1			Initial Creation
2021-07-20	v2			For Discharges:
						- Drop AMA
						- Drop Mortality from Discharges
						- Drop Obs pts that were subsequently admitted
						- Drop pts who's first non-er bed is DOS, PAR, CTH (a,b,c,d etc)
						- Drop Hospice Patients
						- Add discharge dispo description
						- Add discharge data entry date time
***********************************************************************
*/
DECLARE @START DATETIME;
DECLARE @END DATETIME;

SET @START = '2021-06-01';
SET @END = '2021-07-01';

-- Discharge Section
-----
DROP TABLE IF EXISTS #TEMP_A
	CREATE TABLE #TEMP_A (
		account VARCHAR(12),
		edmdid VARCHAR(12),
		edmd VARCHAR(255),
		adm_dr_no VARCHAR(12),
		adm_dr VARCHAR(255),
		hospitalist_flag INT,
		arrival SMALLDATETIME,
		decision_to_admit SMALLDATETIME,
		admit_confirm SMALLDATETIME,
		admitordersdt SMALLDATETIME,
		addedtoadmissionstrack SMALLDATETIME,
		timelefted SMALLDATETIME,
		vst_end_dtime SMALLDATETIME,
		hosp_svc VARCHAR(5),
		dsch_disp VARCHAR(5)
		);

INSERT INTO #TEMP_A (
	account,
	edmdid,
	edmd,
	adm_dr_no,
	adm_dr,
	hospitalist_flag,
	arrival,
	decision_to_admit,
	admit_confirm,
	admitordersdt,
	addedtoadmissionstrack,
	timelefted,
	vst_end_dtime,
	hosp_svc,
	dsch_disp
	)
SELECT PAV.PtNo_Num AS [Account],
	Wellsoft.EDMDID,
	Wellsoft.ED_MD,
	PAV.Adm_Dr_No,
	PDM.pract_rpt_name AS [Adm_Dr],
	CASE 
		WHEN PDM.src_spclty_cd = 'HOSIM'
			THEN 1
		ELSE 0
		END AS [Hospitalist_Flag],
	WELLSOFT.Arrival,
	WELLSOFT.[Decision To Admit],
	WELLSOFT.Admit_Confirm,
	WELLSOFT.AdmitOrdersDT,
	WELLSOFT.AddedToADMissionsTrack,
	WELLSOFT.TimeLeftED,
	PAV.vst_end_dtime,
	PAV.hosp_svc,
	PAV.dsch_disp
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
LEFT JOIN [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS Wellsoft ON PAV.PtNo_Num = Wellsoft.Account
LEFT OUTER JOIN smsdss.pract_dim_v AS PDM ON PAV.Adm_Dr_No = PDM.src_pract_no
	AND PAV.Regn_Hosp = PDM.orgz_cd
WHERE PAV.Dsch_Date >= @START
	AND PAV.Dsch_Date < @END
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND (
		PAV.hosp_svc = 'OBV'
		OR PAV.Plm_Pt_Acct_Type = 'I'
		);

-- get the last admit order placed of ADT03
DROP TABLE IF EXISTS #AdmitOrdDT
	CREATE TABLE #AdmitOrdDT (
		episode_no VARCHAR(12),
		ent_dtime SMALLDATETIME,
		svc_cd VARCHAR(255)
		);

INSERT INTO #AdmitOrdDT (
	episode_no,
	ent_dtime,
	svc_cd
	)
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
	FROM smsmir.sr_ord AS ZZZ
	INNER JOIN #TEMP_A AS XXX ON ZZZ.episode_no = XXX.account
	WHERE svc_Cd IN (
			'ADT03' -- Admit to
			)
	) B
WHERE B.ROWNUM = 1;

-- get the last admit order placed of ADT11
DROP TABLE IF EXISTS #OBSAdmitOrdDT
	CREATE TABLE #OBSAdmitOrdDT (
		episode_no VARCHAR(12),
		ent_dtime SMALLDATETIME,
		svc_cd VARCHAR(255)
		);

INSERT INTO #OBSAdmitOrdDT (
	episode_no,
	ent_dtime,
	svc_cd
	)
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
	FROM smsmir.sr_ord AS ZZZ
	INNER JOIN #TEMP_A AS XXX ON ZZZ.episode_no = XXX.account
	WHERE svc_Cd IN (
			'ADT11' -- PLACE IN OBSERVATION TO PHYSICIAN
			)
	) B
WHERE B.ROWNUM = 1;

DROP TABLE IF EXISTS #DschOrdDT
	CREATE TABLE #DschOrdDT (
		episode_no VARCHAR(12),
		ent_dtime SMALLDATETIME,
		svc_cd VARCHAR(255)
		);

INSERT INTO #DschOrdDT (
	episode_no,
	ent_dtime,
	svc_cd
	)
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
	FROM smsmir.sr_ord AS ZZZ
	INNER JOIN #TEMP_A AS XXX ON ZZZ.episode_no = XXX.account
	WHERE svc_desc = 'DISCHARGE TO'
	) B
WHERE B.ROWNUM = 1;

DROP TABLE IF EXISTS #CenHist
	CREATE TABLE #CenHist (
		episode_no VARCHAR(12),
		nurs_sta VARCHAR(12),
		hosp_svc VARCHAR(12),
		xfer_eff_dtime SMALLDATETIME,
		entered_dtime SMALLDATETIME,
		bed VARCHAR(12),
		cng_type VARCHAR(12),
		rn INT
		);

INSERT INTO #CenHist (
	episode_no,
	nurs_sta,
	hosp_svc,
	xfer_eff_dtime,
	entered_dtime,
	bed,
	cng_type,
	rn
	)
SELECT CenHist.episode_no,
	CenHist.nurs_sta,
	CenHist.hosp_svc,
	CenHist.xfer_eff_dtime,
	CenHist.last_data_cngdtime,
	CenHist.bed,
	CenHist.cng_type,
	[rn] = ROW_NUMBER() OVER (
		PARTITION BY CENHIST.EPISODE_NO ORDER BY CENHIST.XFER_EFF_DTIME ASC
		)
FROM smsmir.mir_cen_hist AS CenHist
INNER JOIN #TEMP_A AS ZZZ ON CenHist.episode_no = ZZZ.account
WHERE CenHist.cng_type IN ('A', 'P')
	AND Cenhist.src_sys_id = '#PMSNTX0';

DELETE
FROM #CenHist
WHERE RN != 1;

DROP TABLE IF EXISTS #ip_bed 
CREATE TABLE #ip_bed (
		episode_no VARCHAR(12),
		nurs_sta VARCHAR(12),
		hosp_svc VARCHAR(12),
		xfer_eff_dtime SMALLDATETIME,
		entered_dtime SMALLDATETIME,
		bed VARCHAR(12),
		cng_type VARCHAR(12),
		rn INT
		);

INSERT INTO #ip_bed (
	episode_no,
	nurs_sta,
	hosp_svc,
	xfer_eff_dtime,
	entered_dtime,
	bed,
	cng_type,
	rn
	)
SELECT ip_bed.episode_no,
	ip_bed.nurs_sta,
	ip_bed.hosp_svc,
	ip_bed.xfer_eff_dtime,
	ip_bed.last_data_cngdtime,
	ip_bed.bed,
	ip_bed.cng_type,
	[rn] = ROW_NUMBER() OVER (
		PARTITION BY ip_bed.EPISODE_NO ORDER BY ip_bed.XFER_EFF_DTIME ASC
		)
FROM SMSMIR.mir_cen_hist AS ip_bed
INNER JOIN #TEMP_A AS ZZZ ON ip_bed.episode_no = ZZZ.account
INNER JOIN #CenHist AS XXX ON XXX.episode_no = ZZZ.account
	AND XXX.xfer_eff_dtime < IP_BED.xfer_eff_dtime
WHERE LEFT(ip_bed.bed, 1) != 'E'
	AND ip_bed.cng_type IN ('A', 'S', 'T')
	AND ip_bed.src_sys_id = '#PMSNTX0';

DELETE
FROM #ip_bed
WHERE RN != 1;

-- Pull it all together
SELECT A.account,
	A.edmdid,
	A.edmd,
	A.adm_dr_no,
	A.adm_dr,
	A.hosp_svc,
	A.hospitalist_flag,
	A.arrival,
	A.decision_to_admit,
	OBS_Admit.ent_dtime AS [Obs_Admit_Order_Entry_DTime],
	B.ent_dtime AS [Admit_Order_Entry_DTime],
	CenHist.xfer_eff_dtime AS [Effective_Bed_Occupied_Time],
	CenHist.entered_dtime AS [Bed_Data_Entry_DTime],
	CenHist.bed AS [Bed_Admitted_To],
	IP_BED.bed AS [First_Non_ER_Bed],
	A.timelefted,
	IP_BED.xfer_eff_dtime AS [Effective_Non_ER_Bed_Occupied_Time],
	IP_BED.entered_dtime AS [Non_ER_Bed_Data_Entry_DTime],
	C.ent_dtime AS [Last_DschOrd_DT],
	--A.dsch_disp,
	[Disp_Description] = CASE
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'HB' THEN 'Drug/Alcohol Rehab Non-Hospital Facility'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'HI' THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'HR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'MA' THEN 'Left Against Medical Advice, Elopement'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TB' THEN 'Correctional Institution'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TE' THEN 'SNF -Sub Acute'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TF' THEN 'Specialty Hospital ( i.e Sloan, Schneiders)'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TH' THEN 'Hospital - Med/Surg (i.e Stony Brook)'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TL' THEN 'SNF - Long Term'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TN' THEN 'Hospital - VA'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TP' THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TT' THEN 'Hospice at Home, Adult Home, Assisted Living'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TW' THEN 'Home, Adult Home, Assisted Living with Homecare'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TX' THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = '1A' THEN 'Postoperative Death, Autopsy'
		WHEN LEFT(A.dsch_disp, 1) IN ('C', 'D') THEN 'Mortality'
	END,
	CAST(HPV.VisitEndDateTime AS smalldatetime) AS [Discharge_DTime],
	[Discharge_DataEntryDTime] = CAST(Dsch_Entry_Dtime.last_data_cngdtime AS smalldatetime),
	[AdmOrd_to_TimeLeftED_Hours] = CASE
		WHEN B.ENT_DTIME IS NOT NULL
			THEN ROUND(CAST(DATEDIFF(MINUTE, B.ent_dtime, A.timelefted) / 60.0 as float), 2)
		ELSE ROUND(CAST(DATEDIFF(MINUTE, OBS_ADMIT.ent_dtime, A.timelefted) / 60.0 AS float), 2)
		END,
	[AdmOrd_to_EffBedOccDTime] = CASE
		WHEN B.ENT_DTIME IS NOT NULL
			THEN ROUND(CAST(DATEDIFF(MINUTE, B.ENT_DTIME, IP_BED.XFER_EFF_DTIME) / 60.0 AS float), 2)
		ELSE ROUND(CAST(DATEDIFF(MINUTE, OBS_ADMIT.ENT_DTIME, IP_BED.xfer_eff_dtime) / 60.0 AS FLOAT), 2)
		END,
	[AdmOrd_to_BedDataEntryDTime] = CASE
		WHEN B.ENT_DTIME IS NOT NULL
			THEN ROUND(CAST(DATEDIFF(MINUTE, B.ENT_DTIME, IP_BED.ENTERED_DTIME) / 60.0 AS FLOAT), 2)
		ELSE ROUND(CAST(DATEDIFF(MINUTE, OBS_ADMIT.ENT_DTIME, IP_BED.ENTERED_DTIME) / 60.0 AS float), 2)
		END,
	[DschOrd_to_DschDTime] = ROUND(CAST(DATEDIFF(MINUTE, C.ent_dtime, HPV.VISITENDDATETIME) / 60.0 AS float), 2),
	[DschOrd_to_DschDataEntryDTime] = ROUND(CAST(DATEDIFF(MINUTE, C.ent_dtime, Dsch_Entry_Dtime.last_data_cngdtime) / 60.0 AS FLOAT), 2)
FROM #TEMP_A AS A
LEFT JOIN #AdmitOrdDT AS B ON A.account = B.episode_no
LEFT JOIN #DschOrdDT AS C ON A.account = C.episode_no
LEFT JOIN #CenHist AS CenHist ON A.account = CenHist.episode_no
LEFT JOIN #ip_bed AS ip_bed ON A.account = ip_bed.episode_no
LEFT JOIN #OBSAdmitOrdDT AS OBS_Admit ON A.account = OBS_Admit.episode_no
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS HPV ON A.account = HPV.PatientAccountID
LEFT JOIN smsmir.cen_hist AS Dsch_Entry_Dtime ON A.account = Dsch_Entry_Dtime.episode_no
	AND Dsch_Entry_Dtime.src_sys_id = '#PMSNTX0'
	AND Dsch_Entry_Dtime.cng_type = 'D'
WHERE (
	-- EXCLUDE THOSE THAT LEAVE AMA OR EXPIRE
	A.dsch_disp != 'AMA'
	AND LEFT(A.dsch_disp, 1) NOT IN ('C','D')
)
AND (
	-- Exclude those that were obs and subsequently admitted
	OBS_Admit.ent_dtime IS NULL -- obs is null
	OR B.ent_dtime IS NULL      -- admit is null
)
-- Exclude Procedure patients
AND LEFT(IP_BED.bed, 3) NOT IN ('PAR','DOS','CTH')
AND LEFT(IP_BED.bed, 1) != 'K'
-- Exclude hosp_svc HSP - Hospice
AND A.hosp_svc != 'HSP'

/* 
-----------------------------------------------------------------------
Admit Section 
-----------------------------------------------------------------------
*/
DROP TABLE IF EXISTS #TEMP_B
	CREATE TABLE #TEMP_B (
		account VARCHAR(12),
		edmdid VARCHAR(12),
		edmd VARCHAR(255),
		adm_dr_no VARCHAR(12),
		adm_dr VARCHAR(255),
		hospitalist_flag INT,
		arrival SMALLDATETIME,
		decision_to_admit SMALLDATETIME,
		admit_confirm SMALLDATETIME,
		admitordersdt SMALLDATETIME,
		addedtoadmissionstrack SMALLDATETIME,
		timelefted SMALLDATETIME,
		vst_end_dtime SMALLDATETIME,
		hosp_svc VARCHAR(5),
		dsch_disp VARCHAR(5)
		);

INSERT INTO #TEMP_B (
	account,
	edmdid,
	edmd,
	adm_dr_no,
	adm_dr,
	hospitalist_flag,
	arrival,
	decision_to_admit,
	admit_confirm,
	admitordersdt,
	addedtoadmissionstrack,
	timelefted,
	vst_end_dtime,
	hosp_svc,
	dsch_disp
	)
SELECT PAV.PtNo_Num AS [Account],
	Wellsoft.EDMDID,
	Wellsoft.ED_MD,
	PAV.Adm_Dr_No,
	PDM.pract_rpt_name AS [Adm_Dr],
	CASE 
		WHEN PDM.src_spclty_cd = 'HOSIM'
			THEN 1
		ELSE 0
		END AS [Hospitalist_Flag],
	WELLSOFT.Arrival,
	WELLSOFT.[Decision To Admit],
	WELLSOFT.Admit_Confirm,
	WELLSOFT.AdmitOrdersDT,
	WELLSOFT.AddedToADMissionsTrack,
	WELLSOFT.TimeLeftED,
	PAV.vst_end_dtime,
	PAV.hosp_svc,
	PAV.dsch_disp
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
LEFT JOIN [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS Wellsoft ON PAV.PtNo_Num = Wellsoft.Account
LEFT OUTER JOIN smsdss.pract_dim_v AS PDM ON PAV.Adm_Dr_No = PDM.src_pract_no
	AND PAV.Regn_Hosp = PDM.orgz_cd
WHERE PAV.Adm_Date >= @START
	AND PAV.Adm_Date < @END
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Adm_Source NOT IN ('RP','RA') -- DIRECT ADMITS
	AND (
		PAV.hosp_svc = 'OBV'
		OR PAV.Plm_Pt_Acct_Type = 'I'
		)
	AND WELLSOFT.Arrival IS NOT NULL;

-- get the last admit order placed of ADT03
DROP TABLE IF EXISTS #AdmitOrdDT_B
	CREATE TABLE #AdmitOrdDT_B (
		episode_no VARCHAR(12),
		ent_dtime SMALLDATETIME,
		svc_cd VARCHAR(255)
		);

INSERT INTO #AdmitOrdDT_B (
	episode_no,
	ent_dtime,
	svc_cd
	)
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
	FROM smsmir.sr_ord AS ZZZ
	INNER JOIN #TEMP_B AS XXX ON ZZZ.episode_no = XXX.account
	WHERE svc_Cd IN (
			'ADT03' -- Admit to
			)
	) B
WHERE B.ROWNUM = 1;

-- get the last admit order placed of ADT11
DROP TABLE IF EXISTS #OBSAdmitOrdDT_B
	CREATE TABLE #OBSAdmitOrdDT_B (
		episode_no VARCHAR(12),
		ent_dtime SMALLDATETIME,
		svc_cd VARCHAR(255)
		);

INSERT INTO #OBSAdmitOrdDT_B (
	episode_no,
	ent_dtime,
	svc_cd
	)
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
	FROM smsmir.sr_ord AS ZZZ
	INNER JOIN #TEMP_B AS XXX ON ZZZ.episode_no = XXX.account
	WHERE svc_Cd IN (
			'ADT11' -- PLACE IN OBSERVATION TO PHYSICIAN
			)
	) B
WHERE B.ROWNUM = 1;

DROP TABLE IF EXISTS #DschOrdDT_B
	CREATE TABLE #DschOrdDT_B (
		episode_no VARCHAR(12),
		ent_dtime SMALLDATETIME,
		svc_cd VARCHAR(255)
		);

INSERT INTO #DschOrdDT_B (
	episode_no,
	ent_dtime,
	svc_cd
	)
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
	FROM smsmir.sr_ord AS ZZZ
	INNER JOIN #TEMP_B AS XXX ON ZZZ.episode_no = XXX.account
	WHERE svc_desc = 'DISCHARGE TO'
	) B
WHERE B.ROWNUM = 1;

DROP TABLE IF EXISTS #CenHist_B
	CREATE TABLE #CenHist_B (
		episode_no VARCHAR(12),
		nurs_sta VARCHAR(12),
		hosp_svc VARCHAR(12),
		xfer_eff_dtime SMALLDATETIME,
		entered_dtime SMALLDATETIME,
		bed VARCHAR(12),
		cng_type VARCHAR(12),
		rn INT
		);

INSERT INTO #CenHist_B (
	episode_no,
	nurs_sta,
	hosp_svc,
	xfer_eff_dtime,
	entered_dtime,
	bed,
	cng_type,
	rn
	)
SELECT CenHist.episode_no,
	CenHist.nurs_sta,
	CenHist.hosp_svc,
	CenHist.xfer_eff_dtime,
	CenHist.last_data_cngdtime,
	CenHist.bed,
	CenHist.cng_type,
	[rn] = ROW_NUMBER() OVER (
		PARTITION BY CENHIST.EPISODE_NO ORDER BY CENHIST.XFER_EFF_DTIME ASC
		)
FROM smsmir.mir_cen_hist AS CenHist
INNER JOIN #TEMP_B AS ZZZ ON CenHist.episode_no = ZZZ.account
WHERE CenHist.cng_type IN ('A', 'P')
	AND Cenhist.src_sys_id = '#PMSNTX0';

DELETE
FROM #CenHist_B
WHERE RN != 1;

DROP TABLE IF EXISTS #ip_bed_B
CREATE TABLE #ip_bed_B (
		episode_no VARCHAR(12),
		nurs_sta VARCHAR(12),
		hosp_svc VARCHAR(12),
		xfer_eff_dtime SMALLDATETIME,
		entered_dtime SMALLDATETIME,
		bed VARCHAR(12),
		cng_type VARCHAR(12),
		rn INT
		);

INSERT INTO #ip_bed_B (
	episode_no,
	nurs_sta,
	hosp_svc,
	xfer_eff_dtime,
	entered_dtime,
	bed,
	cng_type,
	rn
	)
SELECT ip_bed.episode_no,
	ip_bed.nurs_sta,
	ip_bed.hosp_svc,
	ip_bed.xfer_eff_dtime,
	ip_bed.last_data_cngdtime,
	ip_bed.bed,
	ip_bed.cng_type,
	[rn] = ROW_NUMBER() OVER (
		PARTITION BY ip_bed.EPISODE_NO ORDER BY ip_bed.XFER_EFF_DTIME ASC
		)
FROM SMSMIR.mir_cen_hist AS ip_bed
INNER JOIN #TEMP_B AS ZZZ ON ip_bed.episode_no = ZZZ.account
INNER JOIN #CenHist_B AS XXX ON XXX.episode_no = ZZZ.account
	AND XXX.xfer_eff_dtime < IP_BED.xfer_eff_dtime
WHERE LEFT(ip_bed.bed, 1) != 'E'
	AND ip_bed.cng_type IN ('A', 'S', 'T')
	AND ip_bed.src_sys_id = '#PMSNTX0';

DELETE
FROM #ip_bed_B
WHERE RN != 1;

-- Pull it all together
SELECT A.account,
	A.edmdid,
	A.edmd,
	A.adm_dr_no,
	A.adm_dr,
	A.hosp_svc,
	A.hospitalist_flag,
	A.arrival,
	A.decision_to_admit,
	OBS_Admit.ent_dtime AS [Obs_Admit_Order_Entry_DTime],
	B.ent_dtime AS [Admit_Order_Entry_DTime],
	CenHist.xfer_eff_dtime AS [Effective_Bed_Occupied_Time],
	CenHist.entered_dtime AS [Bed_Data_Entry_DTime],
	CenHist.bed AS [Bed_Admitted_To],
	IP_BED.bed AS [First_Non_ER_Bed],
	A.timelefted,
	IP_BED.xfer_eff_dtime AS [Effective_Non_ER_Bed_Occupied_Time],
	IP_BED.entered_dtime AS [Non_ER_Bed_Data_Entry_DTime],
	C.ent_dtime AS [Last_DschOrd_DT],
	--A.dsch_disp,
	[Disp_Description] = CASE
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'HB' THEN 'Drug/Alcohol Rehab Non-Hospital Facility'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'HI' THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'HR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'MA' THEN 'Left Against Medical Advice, Elopement'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TB' THEN 'Correctional Institution'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TE' THEN 'SNF -Sub Acute'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TF' THEN 'Specialty Hospital ( i.e Sloan, Schneiders)'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TH' THEN 'Hospital - Med/Surg (i.e Stony Brook)'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TL' THEN 'SNF - Long Term'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TN' THEN 'Hospital - VA'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TP' THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TT' THEN 'Hospice at Home, Adult Home, Assisted Living'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TW' THEN 'Home, Adult Home, Assisted Living with Homecare'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = 'TX' THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
		WHEN RIGHT(RTRIM(LTRIM(A.dsch_disp)), 2) = '1A' THEN 'Postoperative Death, Autopsy'
		WHEN LEFT(A.dsch_disp, 1) IN ('C', 'D') THEN 'Mortality'
	END,
	CAST(HPV.VisitEndDateTime AS smalldatetime) AS [Discharge_DTime],
	[Discharge_DataEntryDTime] = CAST(Dsch_Entry_Dtime.last_data_cngdtime AS smalldatetime),
	[AdmOrd_to_TimeLeftED_Hours] = CASE
		WHEN B.ENT_DTIME IS NOT NULL
			THEN ROUND(CAST(DATEDIFF(MINUTE, B.ent_dtime, A.timelefted) / 60.0 as float), 2)
		ELSE ROUND(CAST(DATEDIFF(MINUTE, OBS_ADMIT.ent_dtime, A.timelefted) / 60.0 AS float), 2)
		END,
	[AdmOrd_to_EffBedOccDTime] = CASE
		WHEN B.ENT_DTIME IS NOT NULL
			THEN ROUND(CAST(DATEDIFF(MINUTE, B.ENT_DTIME, IP_BED.XFER_EFF_DTIME) / 60.0 AS float), 2)
		ELSE ROUND(CAST(DATEDIFF(MINUTE, OBS_ADMIT.ENT_DTIME, IP_BED.xfer_eff_dtime) / 60.0 AS FLOAT), 2)
		END,
	[AdmOrd_to_BedDataEntryDTime] = CASE
		WHEN B.ENT_DTIME IS NOT NULL
			THEN ROUND(CAST(DATEDIFF(MINUTE, B.ENT_DTIME, IP_BED.ENTERED_DTIME) / 60.0 AS FLOAT), 2)
		ELSE ROUND(CAST(DATEDIFF(MINUTE, OBS_ADMIT.ENT_DTIME, IP_BED.ENTERED_DTIME) / 60.0 AS float), 2)
		END,
	[DschOrd_to_DschDTime] = ROUND(CAST(DATEDIFF(MINUTE, C.ent_dtime, HPV.VISITENDDATETIME) / 60.0 AS float), 2),
	[DschOrd_to_DschDataEntryDTime] = ROUND(CAST(DATEDIFF(MINUTE, C.ent_dtime, Dsch_Entry_Dtime.last_data_cngdtime) / 60.0 AS FLOAT), 2)
FROM #TEMP_B AS A
LEFT JOIN #AdmitOrdDT_B AS B ON A.account = B.episode_no
LEFT JOIN #DschOrdDT_B AS C ON A.account = C.episode_no
LEFT JOIN #CenHist_B AS CenHist ON A.account = CenHist.episode_no
LEFT JOIN #ip_bed_B AS ip_bed ON A.account = ip_bed.episode_no
LEFT JOIN #OBSAdmitOrdDT_B AS OBS_Admit ON A.account = OBS_Admit.episode_no
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS HPV ON A.account = HPV.PatientAccountID
LEFT JOIN smsmir.cen_hist AS Dsch_Entry_Dtime ON A.account = Dsch_Entry_Dtime.episode_no
	AND Dsch_Entry_Dtime.src_sys_id = '#PMSNTX0'
	AND Dsch_Entry_Dtime.cng_type = 'D'
WHERE (
	-- Exclude those that were obs and subsequently admitted
	OBS_Admit.ent_dtime IS NULL -- obs is null
	OR B.ent_dtime IS NULL      -- admit is null
)
-- Exclude Procedure patients
AND LEFT(IP_BED.bed, 3) NOT IN ('PAR','DOS','CTH')
AND LEFT(IP_BED.bed, 1) != 'K'
-- Exclude hosp_svc HSP - Hospice
AND A.hosp_svc != 'HSP'