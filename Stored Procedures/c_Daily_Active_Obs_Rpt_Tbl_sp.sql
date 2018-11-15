USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [smsdss].[c_Daily_Active_Obs_Rpt_Tbl_sp]
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
***********************************************************************
*/

IF NOT EXISTS (
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name = 'c_Daily_Active_Obs_Rpt_Tbl' AND xtype = 'U'
)

BEGIN

	CREATE TABLE smsdss.c_Daily_Active_Obs_Rpt_Tbl (
		Encounter        VARCHAR(12) NOT NULL
		, Ord_No         VARCHAR(12) NOT NULL
		, Entry_DTime    DATETIME
		, Svc_Cd         VARCHAR(50)
		, Ord_As_Written VARCHAR(MAX)
		, Ord_Loc        VARCHAR(5)
		, Ord_Sts_Cd     VARCHAR(5)
		, Ord_Sts_Desc   VARCHAR(50)
		, Admit_Date     DATE
		, Discharge_Date DATE
		, RunDate        DATE
		, RunDTime       DATETIME
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

	FROM smsmir.sr_ord AS A
	LEFT OUTER JOIN smsmir.ord_sts_modf_mstr AS B 
	ON A.ord_sts = B.ord_sts_modf_cd
	LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS C
	ON A.EPISODE_NO = C.PTNO_NUM

	WHERE A.ord_sts IN ( -- 10 will most likely be the only sts returned as it is a PCO order
		'10', -- Active
		'14', -- Pending Specimen Collection
		'39', -- Validated
		'41'  -- Active-Per Protocol
	)

	AND svc_cd in (
		'PCO_SafetyWatch',
		'PCO_ConstantoBS'
	)

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

	FROM smsmir.sr_ord AS A
	LEFT OUTER JOIN smsmir.ord_sts_modf_mstr AS B 
	ON A.ord_sts = B.ord_sts_modf_cd
	LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS C
	ON A.EPISODE_NO = C.PTNO_NUM

	WHERE A.ord_sts IN ( -- 10 will most likely be the only sts returned as it is a PCO order
		'10', -- Active
		'14', -- Pending Specimen Collection
		'39', -- Validated
		'41'  -- Active-Per Protocol
	)

	AND svc_cd in (
		'PCO_SafetyWatch',
		'PCO_ConstantoBS'
	)

	AND A.episode_no NOT IN (
		SELECT ZZZ.Encounter
		FROM smsdss.c_Daily_Active_Obs_Rpt_Tbl AS ZZZ
		WHERE CAST(GETDATE() AS date) = (SELECT MAX(RUNDATE) FROM smsdss.c_Daily_Active_Obs_Rpt_Tbl)
	)

END