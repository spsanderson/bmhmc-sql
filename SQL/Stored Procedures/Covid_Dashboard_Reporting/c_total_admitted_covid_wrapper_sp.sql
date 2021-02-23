USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_total_admitted_covid_wrapper_sp]    Script Date: 12/31/2020 11:18:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: 
	c_total_admitted_covid_wrapper_sp.sql

Input Parameters: 
	None

Tables/Views:
	None

Creates Table: 
	None

Functions: 
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose:
	This sp runs wrapper runs c_total_admitted_covid_sp

Revision History:
Date		Version		Description
----		----		----
2020-12-29	v1			Initial Creation
***********************************************************************
*/

ALTER PROCEDURE [dbo].[c_total_admitted_covid_wrapper_sp]
AS

SET ANSI_NULLS ON
SET ANSI_WARNINGS ON

BEGIN

	EXECUTE dbo.c_total_admitted_covid_sp

END
