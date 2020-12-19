USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_total_admitted_covid_suspect_sp.sql

Input Parameters:
	none

Tables/Views:
	smsdss.c_covid_extract_tbl

Creates Table:
	smsdss.c_tot_adm_covid_suspect_tbl

Functions:
	none

Author: Steven P Sanderson II, MPH

Purpose/Description
	Get Total Admitted COVID Suspect Patients for Dashboard

Revision History:
Date		Version		Description
----		----		----
2020-12-17	v1			Initial Creation
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_total_admitted_covid_suspect_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- Create Table IF NOT EXISTS
	IF OBJECT_ID('smsdss.c_tot_adm_covid_suspect_tbl', 'U') IS NOT NULL
		INSERT INTO smsdss.c_tot_adm_covid_suspect_tbl
		-- Total Admitted AND COVID Suspect
		SELECT *,
			[Run_DateTime] = GETDATE()
		FROM smsdss.c_covid_extract_tbl AS A
		WHERE (
				A.In_House = '1'
				AND A.Distinct_Visit_Flag = '1'
				AND (
					A.RESULT_CLEAN = 'DETECTED'
					AND A.Order_Status != 'Result Signed'
					)
				)
			OR (
				-- Inhouse and distinct visit floag
				A.In_House = '1'
				AND A.Distinct_Visit_Flag = '1'
				-- Patient does NOT meet criteria for Admitted AND Positive
				AND a.PTNO_NUM NOT IN (
					SELECT DISTINCT z.ptno_num
					FROM smsdss.c_covid_extract_tbl AS z
					WHERE (
							z.In_House = '1'
							AND z.Distinct_Visit_Flag = '1'
							AND (
								z.RESULT_CLEAN = 'DETECTED'
								AND z.Order_Status = 'Result Signed'
								)
							)
						OR (
							DATEDIFF(DAY, z.pt_last_test_positive, GETDATE()) <= 30
							AND z.pt_last_test_positive = '1'
							AND (
								z.PatientReasonforSeekingHC LIKE '%Sepsis%'
								OR z.PatientReasonforSeekingHC LIKE '%SEPS%'
								OR z.PatientReasonforSeekingHC LIKE '%PNEUM%'
								OR z.PatientReasonforSeekingHC LIKE '%PNA%'
								OR z.PatientReasonforSeekingHC LIKE '%FEVER%'
								OR z.PatientReasonforSeekingHC LIKE '%CHILLS%'
								OR z.PatientReasonforSeekingHC LIKE '%SOB%'
								OR z.PatientReasonforSeekingHC LIKE '%SHORTNESS OF BREATH%'
								OR z.PatientReasonforSeekingHC LIKE '%SHORT OF BREATH%'
								OR z.PatientReasonforSeekingHC LIKE '%RESPIRATO%FAIL%'
								OR z.PatientReasonforSeekingHC LIKE '%RESP%FAIL%'
								OR z.PatientReasonforSeekingHC LIKE '%COUGH%'
								OR z.PatientReasonforSeekingHC LIKE '%WEAKNESS%'
								OR z.PatientReasonforSeekingHC LIKE '%PN%'
								OR z.PatientReasonforSeekingHC LIKE '%COVID%'
								)
							)
					)
				-- Pt is NOT Admitted AND Positive from directly above AND HAS the following
				AND (
					A.Covid_Indicator = 'COVID 19 or r/o COVID 19 Patient'
					OR (
						A.Covid_Indicator IS NOT NULL
						AND A.Covid_Indicator != ''
						)
					)
				)
	ELSE
		-- Total Admitted AND COVID Suspect
		SELECT *,
			[Run_DateTime] = GETDATE()
		INTO smsdss.c_tot_adm_covid_suspect_tbl
		FROM smsdss.c_covid_extract_tbl AS A
		WHERE (
				A.In_House = '1'
				AND A.Distinct_Visit_Flag = '1'
				AND (
					A.RESULT_CLEAN = 'DETECTED'
					AND A.Order_Status != 'Result Signed'
					)
				)
			OR (
				-- Inhouse and distinct visit flag
				A.In_House = '1'
				AND A.Distinct_Visit_Flag = '1'
				-- Patient does NOT meet criteria for Admitted AND Positive
				AND a.PTNO_NUM NOT IN (
					SELECT DISTINCT z.ptno_num
					FROM smsdss.c_covid_extract_tbl AS z
					WHERE (
							z.In_House = '1'
							AND z.Distinct_Visit_Flag = '1'
							AND (
								z.RESULT_CLEAN = 'DETECTED'
								AND z.Order_Status = 'Result Signed'
								)
							)
						OR (
							DATEDIFF(DAY, z.pt_last_test_positive, GETDATE()) <= 30
							AND z.pt_last_test_positive = '1'
							AND (
								z.PatientReasonforSeekingHC LIKE '%Sepsis%'
								OR z.PatientReasonforSeekingHC LIKE '%SEPS%'
								OR z.PatientReasonforSeekingHC LIKE '%PNEUM%'
								OR z.PatientReasonforSeekingHC LIKE '%PNA%'
								OR z.PatientReasonforSeekingHC LIKE '%FEVER%'
								OR z.PatientReasonforSeekingHC LIKE '%CHILLS%'
								OR z.PatientReasonforSeekingHC LIKE '%SOB%'
								OR z.PatientReasonforSeekingHC LIKE '%SHORTNESS OF BREATH%'
								OR z.PatientReasonforSeekingHC LIKE '%SHORT OF BREATH%'
								OR z.PatientReasonforSeekingHC LIKE '%RESPIRATO%FAIL%'
								OR z.PatientReasonforSeekingHC LIKE '%RESP%FAIL%'
								OR z.PatientReasonforSeekingHC LIKE '%COUGH%'
								OR z.PatientReasonforSeekingHC LIKE '%WEAKNESS%'
								OR z.PatientReasonforSeekingHC LIKE '%PN%'
								OR z.PatientReasonforSeekingHC LIKE '%COVID%'
								)
							)
					)
				-- Pt is NOT Admitted AND Positive from directly above AND HAS the following
				AND (
					A.Covid_Indicator = 'COVID 19 or r/o COVID 19 Patient'
					OR (
						A.Covid_Indicator IS NOT NULL
						AND A.Covid_Indicator != ''
						)
					)
				)
END
