USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_covid_extract_sp]    Script Date: 7/9/2020 2:55:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: 
	c_covid_vents_wrapper_sp.sql

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
	This sp runs wrapper runs dbo.c_covid_vents_sp

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
***********************************************************************
*/

ALTER PROCEDURE [dbo].[c_covid_vents_wrapper_sp]
AS

SET ANSI_NULLS ON
SET ANSI_WARNINGS ON

BEGIN

	EXECUTE dbo.c_covid_vents_sp 

END

