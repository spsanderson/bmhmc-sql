USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_WellSoft_Stored_Procs_sp.sql

Input Parameters: None

Tables/Views:

Creates Table: 

Functions: None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

This sp runs the following stored procedures in the following order:
	1. smsdss.c_Wellsoft_Rpt_Tbl_sp
	2. smsdss.c_Wellsoft_Rpt_Tbl_cleanup_sp
	3. smsdss.c_Wellsott_Ord_Rpt_Tbl_sp

Revision History:
Date		Version		Description
----		----		----
2018-0-01	v1			Initial Creation
***********************************************************************
*/

CREATE PROCEDURE [smsdss].[c_WellSoft_Stored_Procs_sp]
AS

BEGIN
	EXECUTE smsdss.c_Wellsoft_Rpt_Tbl_sp
	EXECUTE smsdss.c_Wellsoft_Rpt_Tbl_cleanup_sp
	EXECUTE smsdss.c_Wellsoft_Ord_Rpt_Tbl_sp
END