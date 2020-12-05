USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: 
	c_er_rt_staff_pt_ratio_wrapper_sp.sql

Input Parameters: 
	@LookBackPeriods

Tables/Views:
	None

Creates Table: 
	None

Functions: 
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose:
	This sp runs wrapper runs dbo.c_er_rt_staff_pt_ratio_sp

Revision History:
Date		Version		Description
----		----		----
2020-12-03	v1			Initial Creation
***********************************************************************
*/
ALTER PROCEDURE [dbo].[c_er_rt_staff_pt_ratio_wrapper_sp] (@LookBackPeriods AS INT = N'96')
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON

BEGIN
	EXECUTE [dbo].[c_er_rt_staff_pt_ratio_sp]
END
