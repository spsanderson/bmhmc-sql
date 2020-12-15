USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_er_rt_esi_staff_wrapper_sp.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_real_time_er_staffing_tbl
	smsdss.c_real_time_er_census_tbl

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Executes dbo.c_er_rt_esi_staff_sp

Revision History:
Date		Version		Description
----		----		----
2020-12-10  v1          Initial Creation
***********************************************************************
*/
CREATE PROCEDURE dbo.c_er_rt_esi_staff_wrapper_sp (@LookBackPeriods AS INT = N'96')
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON

BEGIN
    EXECUTE dbo.c_er_rt_esi_staff_sp @LookBackPeriods;
END
