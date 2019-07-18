USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_dly_ed_tracking_sp]    Script Date: 2/9/2018 8:53:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [smsdss].[c_dly_ed_tracking_sp]
AS

/* 
=======================================================================
Author: Steven P Sanderson II, MPH
Create date: 08-13-2010
Description: Stored procedure to track ED records sent to AVIA code
to test exec smsdss.c_dly_ed_tracking_sp 

v1	-	08-13-2010	-	Initial creation by Scott
v2	-	01-29-2018	-	re-work entire sp.
						1. Create intermediate temp tables to house results
						2. large speedup increases

=======================================================================
*/

BEGIN	
	
	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

	DROP TABLE smsdss.c_er_tracking;

	-- create table
	CREATE TABLE smsdss.c_er_tracking (
		rpt_name VARCHAR(40) NULL
		, pt_id CHAR(13) NOT NULL
		, episode_no VARCHAR(20) NOT NULL
		, vst_id VARCHAR(75) NOT NULL
		, med_rec_no VARCHAR(16) NULL
		, preadm_pt_id VARCHAR(13) NULL
		, from_file_ind CHAR(2) NULL
		, hosp_svc CHAR(4) NULL
		, Census_Svc CHAR(4) NULL
		, hosp_svc_from CHAR(4) NULL
		, pt_type VARCHAR(64) NULL
		, pt_type_from VARCHAR(64) NULL
		, Reg_Dtime DATETIME NOT NULL
		, Adm_Dtime DATETIME NOT NULL
		, resp_pty VARCHAR(6) NULL
		, cng_type VARCHAR(4) NULL
		, case_sts CHAR(2) NULL
		, vst_type_cd CHAR(2) NOT NULL
		, ca_sts_desc VARCHAR(40) NULL
		, no_1t_cngs SMALLINT NULL
		, pt_sts_xfer_ind CHAR(2) NULL
		, prin_dx_cd VARCHAR(8) NULL
		, clin_acct_type CHAR(2) NULL
		, adm_pract_no VARCHAR(8) NULL
		, dsch_disp VARCHAR(4) NULL
		, Adm_Dr_Name VARCHAR(30) NULL
		, tot_bal_amt MONEY NULL
		, tot_adj_amt MONEY NULL
		, tot_chg_amt MONEY NULL
		, prim_pract_no VARCHAR(45) NULL
		, Attend_Dr_Name VARCHAR(200) NULL
		, er_level VARCHAR(15) NULL
		, er_vst_qty FLOAT NULL
		, er_vst_chgs DECIMAL NULL
		, sent_to_avia_date DATETIME NULL
		, Chief_Complaint VARCHAR(30) NULL
		, Wlkout_Qty FLOAT NULL
		, Walkout_Ind VARCHAR(22) NULL
		, RunDate DATE
		, RunDateTime DATETIME
		, PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	)
	;
	-- Now that the table is created we can start to gather data to populate it
	/*
	===================================================================
	Create Intial Base population
	===================================================================
	*/
	SELECT A.PT_ID
	, A.episode_no
	, A.vst_id
	, A.hosp_svc AS [Census_Svc]
	, A.hosp_svc_from
	, A.pt_type
	, A.pt_type_from
	, A.xfer_eff_dtime AS [Reg_Dtime]
	, A.pt_id_start_dtime AS [Adm_Dtime]
	, A.resp_pty
	, A.cng_type
	, A.vst_type_cd

	INTO #BASE_POP
	
	FROM smsmir.mir_cen_hist AS A
	
	WHERE a.xfer_eff_dtime >= '2016-01-01 00:00:00.000' 
	AND a.cng_type = 'N'
	AND a.pt_type = 'E'
	AND a.episode_no NOT IN (
		SELECT DISTINCT (preadm_pt_id)
		FROM smsmir.mir_pms_case
		WHERE NOT preadm_pt_id IS NULL
	)
	;
	-- SELECT * FROM #BASE_POP WHERE episode_no = '';
	
	
	/*
	===================================================================
	Create temp table with chief complaint
	===================================================================
	*/
	SELECT pt_id
	, episode_no
	, [Chief_Complaint] = user_data_text

	INTO #ER_Chf_Complaint

	FROM smsmir.pms_user_episo

	WHERE user_data_cd = '2CHFCOMP'
	AND episode_no IN (
		SELECT ZZZ.EPISODE_NO
		FROM #BASE_POP AS ZZZ
	)
	--SELECT * FROM #ER_Chf_Complaint WHERE episode_no = ''
	;

	/*
	===================================================================
	Create Temp Table With Date Sent To Avia. Convert Invision "2" Field to Date
	===================================================================
	*/
	SELECT pt_id
	, Episode_no
	, [Sent_To_Avia_Date] = CAST((left(user_data_text,2)+'-'+substring(user_data_text,3,2)+'-'+right(user_data_text,2)) AS datetime)

	INTO #ER_To_Avia

	FROM smsmir.pms_user_episo

	WHERE user_data_cd = '2TOAVIDT'
	AND episode_no IN (
		SELECT ZZZ.EPISODE_NO
		FROM #BASE_POP AS ZZZ
	)
	--SELECT * FROM #ER_To_Avia WHERE EPISODE_NO = ''
	;

	/*
	===================================================================
	Create temp table with ER Walkout/Non-Billable Indicator
	===================================================================
	*/
	SELECT CAST(RIGHT(RTRIM(xx.PT_ID), 8) AS varchar(20)) AS pt_id
	, CASE
		WHEN xx.ACTV_CD IN ('04600565','04600052')
			THEN 'WALKOUT'
		WHEN xx.actv_cd ='04600094'
			THEN 'NON-BILLABLE AFTERCARE'
			ELSE ''
	  END AS [Walkout_Ind]
	, SUM(xx.actv_tot_qty) AS [Wlkout_Qty]

	INTO #ER_Wlk_Out_Ind

	FROM smsmir.mir_actv AS xx

	WHERE xx.actv_cd IN ('04600565','04600052','04600094')
	AND SUBSTRING(xx.pt_id, 5, 8) IN (
		SELECT ZZZ.EPISODE_NO
		FROM #BASE_POP AS ZZZ
	)
	
	GROUP BY xx.pt_id
	, xx.actv_cd

	HAVING SUM(xx.actv_tot_qty) != 0
	-- SELECT * FROM #ER_Wlk_Out_Ind WHERE PT_ID = ''
	;

	/*
	===================================================================
	Create Temp Table with ER Visit Charges & Servce Levels
	===================================================================
	*/
	SELECT CAST(RIGHT(RTRIM(Q.pt_id), 8) AS varchar(20)) AS pt_id
	, Q.ACTV_CD
	, r.actv_name
	, CASE 
		WHEN q.actv_cd IN ('04600409','04600458') 
			THEN 'LEVEL 1'
		WHEN q.actv_cd IN ('04600508','04600557') 
			THEN 'LEVEL 2'
		WHEN q.actv_cd IN ('04600607','04600656') 
			THEN 'LEVEL 3'
		WHEN q.actv_cd IN ('04600706','04600755') 
			THEN 'LEVEL 4'
		WHEN q.actv_cd IN ('04600805','04600854') 
			THEN 'LEVEL 5'
		WHEN q.actv_cd IN ('04600904','04600953') 
			THEN 'CRITICAL CARE'
		WHEN q.actv_cd IN ('04600011') 
			THEN 'ER IP ADMIT FEE'
	  END AS [er_level]
	, SUM(q.actv_tot_Qty) AS [er_vst_qty]
	, SUM(q.chg_tot_amt) AS [er_vst_chgs]

	INTO #ER_Vist_Chgs

	FROM smsmir.mir_actv AS Q
	INNER JOIN smsmir.actv_mstr AS R
	ON Q.ACTV_CD = R.ACTV_CD

	WHERE Q.ACTV_CD IN (
		'04600011','04600409','04600458','04600508','04600557'
		,'04600607','04600656','04600706','04600755','04600805'
		,'04600854','04600904','04600953'
	)
	AND SUBSTRING(Q.pt_id, 5, 8) IN (
		SELECT ZZZ.EPISODE_NO
		FROM #BASE_POP AS ZZZ 
	)
	
	GROUP BY q.pt_id
	, q.actv_cd
	, r.actv_name

	HAVING SUM(q.actv_tot_qty) != 0
	-- SELECT * FROM #ER_Vist_Chgs WHERE PT_ID = ''
	;

	/*
	===================================================================
	Create Temp table with Attending Phsycian Info
	===================================================================
	*/
	SELECT aa.episode_no
	, aa.pt_id
	, ab.pt_id as [Vst_Pt_Id]
	, ab.prim_pract_no
	, ac.pract_rpt_name

	INTO #ER_Attend_Phys_Name

	FROM smsmir.mir_cen_hist AS aa 
	LEFT JOIN smsmir.mir_vst as ab
	ON CAST(aa.episode_no as int) = CAST(ab.pt_id as int)
	LEFT JOIN smsmir.mir_pract_mstr as ac
	ON ab.prim_pract_no = ac.pract_no
	LEFT JOIN smsmir.mir_pms_case as ad
	ON aa.pt_id = ad.pt_id
		AND aa.episode_no = ad.episode_no
	INNER JOIN #BASE_POP AS ZZZ
	ON aa.episode_no = ZZZ.episode_no
		AND ZZZ.cng_type = aa.cng_type
		AND ZZZ.pt_type = ZZZ.pt_type
		AND ZZZ.Reg_Dtime = aa.xfer_eff_dtime

	WHERE ad.case_sts NOT IN ('15','25','35')
	AND ac.src_sys_id = '#PMSNTX0'

	GROUP BY aa.episode_no
	, aa.pt_id
	, ab.pt_id
	, ab.prim_pract_no
	, ac.pract_rpt_name
	-- SELECT * FROM #ER_ATTEND_PHYS_NAME WHERE EPISODE_NO = ''
	;

	/*
	===================================================================
	Create Temp Table With Admitting ER Physician Name
	===================================================================
	*/
	SELECT ax.episode_no
	, ax.pt_id
	, ax.pt_id_start_dtime
	, av.user_data_text

	INTO #ER_Admit_Phys_Name

	FROM smsmir.mir_cen_hist as ax 
	LEFT JOIN smsmir.mir_pms_user_episo as av
	ON ax.episode_no = av.episode_no
	LEFT JOIN smsmir.mir_pms_case as ay
	ON ax.pt_id = ay.pt_id
		AND ax.episode_no = ay.episode_no
	INNER JOIN #BASE_POP AS ZZZ
	ON ax.episode_no = ZZZ.episode_no
		AND ZZZ.cng_type = ax.cng_type
		AND ZZZ.pt_type = ax.pt_type
		AND ZZZ.Reg_Dtime = ax.xfer_eff_dtime

	WHERE ay.case_sts NOT IN ('15','25','35')
	AND av.src_sys_id = '#PMSNTX0'
	AND av.user_data_cd ='2ADMDRNA'

	GROUP BY ax.episode_no,
	ax.pt_id,
	ax.pt_id_start_dtime,
	av.user_data_text
	-- SELECT * FROM #ER_ADMIT_PHYS_NAME WHERE EPISODE_NO = ''
	;

	/*
	===================================================================
	Get items from smsmir.mir_vst
	===================================================================
	*/
	SELECT SUBSTRING(PT_ID, 5, 8) AS [Episode_No]
	, pt_id
	, ISNULL(PRIN_DX_CD, prin_dx_icd10_cd) AS [prin_dx_cd]
	, tot_chg_amt
	, prim_pract_no
	
	INTO #MIR_VST

	FROM smsmir.mir_vst

	WHERE SUBSTRING(PT_ID, 5, 8) IN (
		SELECT ZZZ.episode_no
		FROM #BASE_POP AS ZZZ
	)
	-- SELECT * FROM #MIR_VST WHERE EPISODE_NO = ''
	;

	/*
	===================================================================
	Brings Together All Data From Temp and MIR Tables
	===================================================================
	*/
	INSERT INTO smsdss.c_er_tracking

	SELECT b.rpt_name
	, a.pt_id
	, a.episode_no
	, a.vst_id
	, b.med_rec_no
	, b.preadm_pt_id
	, v.from_file_ind
	, b.hosp_svc
	, A.Census_Svc
	, A.hosp_svc_from
	, a.pt_type
	, a.pt_type_from
	, A.Reg_Dtime
	, A.Adm_Dtime
	, a.resp_pty
	, a.cng_type
	, b.case_sts
	, a.vst_type_cd
	, e.ca_sts_desc
	, b.no_1t_cngs
	, b.pt_sts_xfer_ind
	, F.prin_dx_cd
	, b.clin_acct_type
	, b.adm_pract_no
	, b.dsch_disp
	, av.user_data_text AS [Adm_Dr_Name]
	, v.tot_bal_amt
	, v.tot_adj_amt
	, f.tot_chg_amt
	, f.prim_pract_no
	, ag.pract_rpt_name AS [Attend_Dr_Name]
	, t.er_level
	, t.er_vst_qty
	, t.er_vst_chgs
	, o.sent_to_avia_date
	, x.Chief_Complaint
	, axx.Wlkout_Qty
	, axx.Walkout_Ind
	, [RunDate] = CAST(GETDATE() AS date)
	, [RunDateTime] = GETDATE()

	FROM #BASE_POP AS A
	LEFT JOIN smsmir.mir_pms_case as b
	ON a.pt_id = b.pt_id 
		AND a.episode_no = b.episode_no 
	LEFT JOIN smsdss.ca_sts_mstr as e
	ON b.case_sts = e.ca_sts
	LEFT JOIN #MIR_VST as f
	ON a.episode_no = f.Episode_No
	LEFT JOIN #ER_Vist_Chgs as t
	ON a.episode_no = t.pt_id
	LEFT JOIN #ER_To_Avia as o
	ON a.episode_no = o.episode_no
	LEFT JOIN #ER_Chf_Complaint as x
	ON a.episode_no = x.episode_no
	LEFT JOIN smsmir.mir_acct as v
	ON a.episode_no = substring(v.pt_id, 5, 8)
	LEFT JOIN #ER_Admit_Phys_Name as av
	ON a.pt_id = av.pt_id 
		AND a.episode_no = av.episode_no
	LEFT JOIN #ER_Attend_Phys_Name as ag
	ON a.pt_id = ag.pt_id 
		AND a.episode_no = ag.episode_no
	LEFT JOIN #ER_Wlk_Out_Ind as axx
	ON a.episode_no = axx.pt_id

	WHERE b.case_sts NOT IN ('15','25','35')
	AND a.episode_no NOT IN (
		SELECT DISTINCT (preadm_pt_id)
		FROM smsmir.mir_pms_case
		WHERE NOT preadm_pt_id IS NULL
	)
	--AND a.episode_no = ''
	;

	/*
	======================================================================
	Drop temp tables
	======================================================================
	*/
	DROP TABLE #BASE_POP, #ER_Admit_Phys_Name, #ER_Attend_Phys_Name, #ER_Chf_Complaint;
	DROP TABLE #ER_To_Avia, #ER_Vist_Chgs, #ER_Wlk_Out_Ind, #MIR_VST;

END
;