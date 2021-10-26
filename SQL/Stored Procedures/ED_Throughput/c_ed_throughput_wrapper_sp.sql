USE [SMSPHDSSS0X0]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: 
	c_ed_throughput_wrapper_sp.sql

Input Parameters: 
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
	smsdss.pract_dim_v
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
	smsmir.cen_hist
	smsmir.mir_cen_hist
	smsmir.sr_ord

Creates Table: 
	smsdss.c_ed_throughput_tbl

Functions: 
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose:
	This sp runs wrapper runs dbo.c_ed_throughput_sp

Revision History:
Date		Version		Description
----		----		----
2021-10-14	v1			Initial Creation
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_ed_throughput_wrapper_sp]
AS

SET ANSI_NULLS ON
SET ANSI_WARNINGS ON

BEGIN

	EXECUTE dbo.c_ed_throughput_sp

END
