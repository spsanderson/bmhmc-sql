USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_Daily_Active_Obs_Rpt_Tbl_sp]    Script Date: 11/26/2018 10:31:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [smsdss].[c_Daily_Active_Obs_Rpt_Tbl_sp]
AS

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

/*
***********************************************************************
File: c_Daily_Active_Obs_Rpt_Tbl_sp.sql

Input Parameters:
	None

Tables/Views:
	smsmir.sr_ord
	smsmir.ord_sts_modf_mstr

Creates Table:
	smsdss.c_Daily_Active_Obs_Rpt_Tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Create a report table of Daily Active Observation Patients.

Revision History:
Date		Version		Description
----		----		----
2018-11-14	v1			Initial Creation
2018-11-20	v2			Add the following columns
							1. Order Entry Date
							2. Order Entry Time
							3. Order Start DTime
							3. Order Start Date
							4. Order Start Time
							5. Order Stop DTime
							6. Order Stop Date
							7. Order Stop Time
						
						Add filter to make sure that a specific order is
						not already in the tabel. 
						
						Drop filter for encounter not in table on run date
						more concerned with order

						Patient is not discharged
2018-11-21	v3			Add the following columns
							1. Nursing_Station
							2. Req_Pty_ID
							3. Req_Pty_Name
							4. Room_Bed
							5. Pt_Age
2018-11-26	v4			Kick out orders where stp_date = '1900-01-01 00:00:00.000'
2021-12-14	v5			Add 'PCO_SuicideWatch' to the svc_cd list
***********************************************************************
*/

IF NOT EXISTS (
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name = 'c_Daily_Active_Obs_Rpt_Tbl' AND xtype = 'U'
)

BEGIN

	CREATE TABLE smsdss.c_Daily_Active_Obs_Rpt_Tbl (
		Encounter         VARCHAR(12) NOT NULL
		, Ord_No          VARCHAR(12) NOT NULL
		, Entry_DTime     DATETIME
		, Svc_Cd          VARCHAR(50)
		, Ord_As_Written  VARCHAR(MAX)
		, Ord_Loc         VARCHAR(5)
		, Ord_Sts_Cd      VARCHAR(5)
		, Ord_Sts_Desc    VARCHAR(50)
		, Admit_Date      DATE
		, Discharge_Date  DATE
		, RunDate         DATE
		, RunDTime        DATETIME
		, Ord_Ent_Date    DATE
		, Ord_Ent_Time    TIME
		, Ord_Str_DTime   DATETIME
		, Ord_Str_Date    DATE
		, Ord_Str_Time    TIME
		, Ord_Stop_DTIME  DATETIME
		, Ord_Stop_Date   DATE
		, Ord_Stop_Time   TIME
		, Nursing_Station VARCHAR(20)
		, Req_Pty_ID      VARCHAR(10)
		, Req_Pty_Name    VARCHAR(100)
		, Room_Bed        VARCHAR(5)
		, Pt_Age          INT
	)
	;

	INSERT INTO smsdss.c_Daily_Active_Obs_Rpt_Tbl

	SELECT A.episode_no
	, A.ord_no
	, A.ent_dtime
	, A.svc_cd
	, A.desc_as_written
	, A.ord_loc
	, A.ord_sts
	, B.ord_sts_modf
	, CAST(C.Adm_Date AS date) AS [ADM_DATE]
	, CAST(C.DSCH_DATE AS date) AS [DSCH_DATE]
	, RunDate = CAST(GETDATE() AS date)
	, RunDTime = GETDATE()
	, A.ent_date
	, CAST(A.ENT_DTIME AS time) AS ORD_ENT_TIME
	, A.str_dtime
	, A.str_date
	, CAST(A.str_dtime as time) as [ord_str_time]
	, A.stp_dtime
	, A.stp_date
	, CAST(A.stp_dtime as time) as [ord_stop_time]
	, D.nurs_sta
	, A.pty_cd
	, A.pty_name
	, E.rm_no
	, C.Pt_Age

	FROM smsmir.sr_ord AS A
	LEFT OUTER JOIN smsmir.ord_sts_modf_mstr AS B 
	ON A.ord_sts = B.ord_sts_modf_cd
	LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS C
	ON A.EPISODE_NO = C.PTNO_NUM
	LEFT OUTER JOIN smsdss.dly_cen_occ_fct_v AS D
	ON C.Pt_No = D.pt_id
		AND CAST(a.ent_date as date) = D.cen_date
	LEFT OUTER JOIN smsdss.rm_bed_mstr_v AS E
	ON D.rm_bed_key = E.id_col
	AND D.orgz_cd = E.orgz_cd

	WHERE A.ord_sts IN ( -- 10 will most likely be the only sts returned as it is a PCO order
		'10', -- Active
		'14', -- Pending Specimen Collection
		'39', -- Validated
		'41'  -- Active-Per Protocol
	)
	AND A.svc_cd in (
		'PCO_SafetyWatch',
		'PCO_ConstantObs',
		'PCO_SuicideWatch'
	)
	AND C.Dsch_Date IS NULL
	AND A.stp_date != '1900-01-01 00:00:00.000'

END

ELSE BEGIN

	INSERT INTO smsdss.c_Daily_Active_Obs_Rpt_Tbl

	SELECT A.episode_no
	, A.ord_no
	, A.ent_dtime
	, A.svc_cd
	, A.desc_as_written
	, A.ord_loc
	, A.ord_sts
	, B.ord_sts_modf
	, CAST(C.Adm_Date AS date) AS [ADM_DATE]
	, CAST(C.DSCH_DATE AS date) AS [DSCH_DATE]
	, RunDate = CAST(GETDATE() AS date)
	, RunDTime = GETDATE()
	, A.ent_date
	, CAST(A.ENT_DTIME AS time) AS ORD_ENT_TIME
	, A.str_dtime
	, A.str_date
	, CAST(A.str_dtime as time) as [ord_str_time]
	, A.stp_dtime
	, A.stp_date
	, CAST(A.stp_dtime as time) as [ord_stop_time]
	, D.nurs_sta
	, A.pty_cd
	, A.pty_name
	, E.rm_no
	, C.Pt_Age

	FROM smsmir.sr_ord AS A
	LEFT OUTER JOIN smsmir.ord_sts_modf_mstr AS B 
	ON A.ord_sts = B.ord_sts_modf_cd
	LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS C
	ON A.EPISODE_NO = C.PTNO_NUM
	LEFT OUTER JOIN smsdss.dly_cen_occ_fct_v AS D
	ON C.Pt_No = D.pt_id
		AND CAST(a.ent_date as date) = D.cen_date
	LEFT OUTER JOIN smsdss.rm_bed_mstr_v AS E
	ON D.rm_bed_key = E.id_col
	AND D.orgz_cd = E.orgz_cd

	WHERE A.ord_sts IN ( -- 10 will most likely be the only sts returned as it is a PCO order
		'10', -- Active
		'14', -- Pending Specimen Collection
		'39', -- Validated
		'41'  -- Active-Per Protocol
	)
	AND A.svc_cd in (
		'PCO_SafetyWatch',
		'PCO_ConstantObs',
		'PCO_SuicideWatch'
	)
	AND C.Dsch_Date IS NULL
	AND A.stp_date != '1900-01-01 00:00:00.000'
	AND A.ord_no NOT IN (
		SELECT ZZZ.Ord_No
		FROM smsdss.c_Daily_Active_Obs_Rpt_Tbl AS ZZZ
	)

END