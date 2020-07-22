USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_dx_code_sp.sql

Input Parameters:
	None

Tables/Views:
	smsmir.dx_grp

Creates Table:
	smsdss.c_covid_dx_cd_ind_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the dx code indicators

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_dx_cd_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
    -- Create a new table called 'c_covid_indicator_text_tbl' in schema 'smsdss'
    -- Drop the table if it already exists
    IF OBJECT_ID('smsdss.c_covid_dx_cd_ind_tbl', 'U') IS NOT NULL
    DROP TABLE smsdss.c_covid_dx_cd_ind_tbl;

	/*
	Select Dx Codes
	Codes:
	B97.29, U07.1, Z20.828, Z03.818
	Any position
	*/
	SELECT PVT.PatientAccountID,
		PVT.[B97.29],
		PVT.[U07.1],
		PVT.[Z20.828],
		PVT.[Z03.818]
	INTO smsdss.c_covid_dx_cd_ind_tbl
	FROM (
		SELECT SUBSTRING(PT_ID, 5, 8) AS [PatientAccountID],
			dx_cd
		FROM smsmir.dx_grp
		WHERE DX_CD IN ('B97.29', 'U07.1', 'Z20.828', 'Z03.818')
			AND LEFT(dx_cd_type, 2) = 'DF'
		) AS CVDX
	PIVOT(MAX(DX_CD) FOR DX_CD IN ("B97.29", "U07.1", "Z20.828", "Z03.818")) AS PVT

END;