USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_hwac_pivot_sp.sql

Input Parameters:
	None

Tables/Views:
	smsmir.obsv
    smsdss.c_covid_patient_visit_data_tbl

Creates Table:
	smsdss.c_covid_hwac_pivot_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	get ht wt admit and comorbidities

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2021-12-30	v2			Update to get data from PROD SC and then DSS
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_hwac_pivot_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
	-- Create a new table called 'c_covid_a_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_hwac_pivot_tbl', 'U') IS NOT NULL
	DROP TABLE smsdss.c_covid_hwac_pivot_tbl;

	/*
	Height, Weight, Comorbidities and Admitted From Data all from the Admissions Assessment
	*/
	SELECT episode_no AS [PatientAccountID],
		obsv_cd_name,
		obsv_cd,
		perf_dtime,
		REPLACE(REPLACE(REPLACE(REPLACE(dsply_val, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' ') AS [Display_Value],
		form_usage,
		id_num = row_number() OVER (
			PARTITION BY episode_no,
			obsv_cd_name ORDER BY episode_no,
				perf_dtime DESC
			)
	INTO #HWAC
	FROM SMSMIR.obsv
	WHERE obsv_cd IN (
			--'ht',
			--'wt',
			'A_Admit From',
			'A_BMH_ListCoMorb'
		)
		AND form_usage = 'Admission'
		AND LEN(EPISODE_NO) = 8
		AND episode_no IN (
			SELECT DISTINCT PatientAccountID
			FROM smsdss.c_covid_patient_visit_data_tbl
			)
	ORDER BY episode_no,
		perf_dtime DESC;

	--Delete everything but the last assessment for each location, patient  
	DELETE
	FROM #HWAC
	WHERE id_num != '1'

	SELECT PVT.PatientAccountID,
		PVT.[A_Admit From],
		--PVT.Ht,
		--PVT.Wt,
		PVT.A_BMH_ListCoMorb,
		PVT.perf_dtime,
		PVT.form_usage
	INTO smsdss.c_covid_hwac_pivot_tbl
	FROM (
		SELECT PatientAccountID,
			Display_Value,
			obsv_cd,
			perf_dtime,
			form_usage
		FROM #HWAC
		) AS A
	PIVOT(MAX(Display_Value) FOR obsv_cd IN (
			[A_Admit From], 
			[A_BMH_ListCoMorb]
			--[Ht], 
			--[Wt]
		)
	) AS PVT

END;