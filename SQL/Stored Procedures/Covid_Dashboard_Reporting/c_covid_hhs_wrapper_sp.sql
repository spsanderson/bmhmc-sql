USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_covid_hhs_positive_admitted_wrapper_sp]    Script Date: 3/3/2021 8:17:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: 
	c_covid_hhs_wrapper_sp.sql

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
	This sp runs wrapper runs dbo.c_covid_hhs_sp

Revision History:
Date		Version		Description
----		----		----
2021-03-03	v1			Initial Creation
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_hhs_wrapper_sp]
AS

SET ANSI_NULLS ON
SET ANSI_WARNINGS ON

BEGIN

	EXECUTE dbo.c_covid_hhs_sp

END
