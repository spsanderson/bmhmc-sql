USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_real_time_er_staffing_tbl_wrapper_sp.sql

Input Parameters:
	None

Tables/Views:
	[LICOMMHOSP.KRONOS.NET].[tkcsdb].[dbo].[VP_TIMESHTPUNCHV42]
	[smsdss].[c_LI_users]

Creates Table:
	smsdss.c_real_time_er_staffing_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Executes dbo.c_real_time_er_staffing_tbl_sp

Revision History:
Date		Version		Description
----		----		----
2020-11-30	v1			Initial Creation
***********************************************************************
*/

CREATE PROCEDURE dbo.c_real_time_er_staffing_tbl_wrapper_sp
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN

    EXECUTE dbo.c_real_time_er_staffing_tbl_sp

END




