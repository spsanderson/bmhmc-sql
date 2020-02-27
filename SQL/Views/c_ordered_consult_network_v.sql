/*
***********************************************************************
File: c_ordered_consult_network_v.sql

Input Parameters:
	None

Tables/Views:
	smsmir.ord
    smsdss.bmh_plm_ptacct_v
    smsdss.pract_dim_v
    sc_server.soarian_clin_prd_1.dbo.hstaff

Creates Table:
	smsdss.c_ordered_consult_network_v

Functions:
	Enter Here

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get ordered consults in a target/source manner with attending provider
    for network anlaysis/oppe reporting

Revision History:
Date		Version		Description
----		----		----
2020-01-01	v1			Initial Creation
2020-02-18	v2			Change Attending to Soarian HStaff
***********************************************************************
*/

USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [smsdss].[c_ordered_consult_network_v]
AS
SELECT DISTINCT SO.episode_no,
	PDV.src_pract_no AS [Attending_ID],
	Attending.STAFFSIGNATURE AS [Attending],
	CASE 
		WHEN PDV.src_spclty_cd = 'HOSIM'
			THEN 'Private'
		ELSE 'Community'
		END AS [Hospitalist_Private],
	SO.pty_cd AS [Ordering_Provider_ID],
	ORDERING.STAFFSIGNATURE AS [Source] -- [Ordering_Provider]
	,
	RTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(SO.DESC_AS_WRITTEN, 21, 40), 'Today', ''), 'Stat', ''), 'In Am', '')) AS [Target] --[CONSULTANT CONTACTED]
	,
	SO.ent_dtime
-- WHERE IT COMES FROM
FROM smsmir.sr_ord AS SO
LEFT MERGE JOIN smsdss.BMH_PLM_PtAcct_V AS PAV ON SO.episode_no = PAV.PtNo_Num
LEFT MERGE JOIN smsdss.pract_dim_v AS PDV ON PAV.Atn_Dr_No = PDV.src_pract_no
	AND PAV.Regn_Hosp = PDV.orgz_cd
LEFT MERGE JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HSTAFF AS ORDERING ON SO.pty_cd = ORDERING.MSINUMBER
LEFT MERGE JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HSTAFF AS Attending ON PAV.Atn_Dr_No = Attending.MSINUMBER
-- FILTER(S)
WHERE SO.ent_date >= '2010-01-01'
	AND SO.ent_date < CAST(GETDATE() AS DATE)
	AND PAV.Plm_Pt_Acct_Type = 'I'
	AND LEFT(PAV.PtNo_Num, 1) NOT IN ('2', '7')
	AND LEFT(PAV.PtNo_Num, 4) != '19999'
	AND PDV.orgz_cd = 'S0X0'
	AND PDV.spclty_cd = 'HOSIM'
	AND so.svc_cd = 'Consult: Doctor'
	AND SO.signon_id != 'HSF_JS'
	AND SO.pty_cd != '000000'


GO





