USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_total_admitted_covid_positive_sp.sql

Input Parameters:
	none

Tables/Views:
	smsdss.c_covid_extract_tbl

Creates Table:
	smsdss.c_tot_adm_covid_pos_tbl

Functions:
	none

Author: Steven P Sanderson II, MPH

Purpose/Description
	Get Total Admitted COVID Positive Patients for Dashboard

Revision History:
Date		Version		Description
----		----		----
2020-12-17	v1			Initial Creation
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_total_admitted_covid_positive_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;

	-- Create Table IF NOT EXISTS
	IF OBJECT_ID('smsdss.c_tot_adm_covid_pos_tbl','U') IS NOT NULL
		INSERT INTO smsdss.c_tot_adm_covid_pos_tbl
		-- Total Admitted AND COVID Positive
		SELECT *,
			[Run_DateTime] = GETDATE()
		FROM smsdss.c_covid_extract_tbl AS A
		WHERE (
				A.In_House = '1'
				AND A.Distinct_Visit_Flag = '1'
				AND (
					A.RESULT_CLEAN = 'DETECTED'
					AND A.Order_Status = 'Result Signed'
					)
				)
			OR (
				DATEDIFF(DAY, A.pt_last_test_positive, GETDATE()) <= 30
				AND A.pt_last_test_positive = '1'
				AND (
					A.PatientReasonforSeekingHC LIKE '%Sepsis%'
					OR A.PatientReasonforSeekingHC LIKE '%SEPS%'
					OR A.PatientReasonforSeekingHC LIKE '%PNEUM%'
					OR A.PatientReasonforSeekingHC LIKE '%PNA%'
					OR A.PatientReasonforSeekingHC LIKE '%FEVER%'
					OR A.PatientReasonforSeekingHC LIKE '%CHILLS%'
					OR A.PatientReasonforSeekingHC LIKE '%SOB%'
					OR A.PatientReasonforSeekingHC LIKE '%SHORTNESS OF BREATH%'
					OR A.PatientReasonforSeekingHC LIKE '%SHORT OF BREATH%'
					OR A.PatientReasonforSeekingHC LIKE '%RESPIRATO%FAIL%'
					OR A.PatientReasonforSeekingHC LIKE '%RESP%FAIL%'
					OR A.PatientReasonforSeekingHC LIKE '%COUGH%'
					OR A.PatientReasonforSeekingHC LIKE '%WEAKNESS%'
					OR A.PatientReasonforSeekingHC LIKE '%PN%'
					OR A.PatientReasonforSeekingHC LIKE '%COVID%'
					)
				)
		ORDER BY a.PTNO_NUM
	ELSE
		-- Total Admitted AND COVID Positive
		SELECT *,
			[Run_DateTime] = GETDATE()
		INTO smsdss.c_tot_adm_covid_pos_tbl
		FROM smsdss.c_covid_extract_tbl AS A
		WHERE (
				A.In_House = '1'
				AND A.Distinct_Visit_Flag = '1'
				AND (
					A.RESULT_CLEAN = 'DETECTED'
					AND A.Order_Status = 'Result Signed'
					)
				)
			OR (
				DATEDIFF(DAY, A.pt_last_test_positive, GETDATE()) <= 30
				AND A.pt_last_test_positive = '1'
				AND (
					A.PatientReasonforSeekingHC LIKE '%Sepsis%'
					OR A.PatientReasonforSeekingHC LIKE '%SEPS%'
					OR A.PatientReasonforSeekingHC LIKE '%PNEUM%'
					OR A.PatientReasonforSeekingHC LIKE '%PNA%'
					OR A.PatientReasonforSeekingHC LIKE '%FEVER%'
					OR A.PatientReasonforSeekingHC LIKE '%CHILLS%'
					OR A.PatientReasonforSeekingHC LIKE '%SOB%'
					OR A.PatientReasonforSeekingHC LIKE '%SHORTNESS OF BREATH%'
					OR A.PatientReasonforSeekingHC LIKE '%SHORT OF BREATH%'
					OR A.PatientReasonforSeekingHC LIKE '%RESPIRATO%FAIL%'
					OR A.PatientReasonforSeekingHC LIKE '%RESP%FAIL%'
					OR A.PatientReasonforSeekingHC LIKE '%COUGH%'
					OR A.PatientReasonforSeekingHC LIKE '%WEAKNESS%'
					OR A.PatientReasonforSeekingHC LIKE '%PN%'
					OR A.PatientReasonforSeekingHC LIKE '%COVID%'
					)
				)
		ORDER BY a.PTNO_NUM
END