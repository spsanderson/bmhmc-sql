USE [SMSPHDSSS0X0]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_hhs_positive_admitted_sp.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_covid_extract_tbl

Creates Table:
	smsdss.c_covid_hhs_positive_admitted_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get all of the HHS Covid Positive Admitted patients for the record
	exception report.

	This should run after the 9am daily covid extract insert job.

Revision History:
Date		Version		Description
----		----		----
2021-01-26	v1			Initial Creation
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_hhs_positive_admitted_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
	-- Create a new table called 'c_covid_hhs_positive_admitted_tbl' in schema 'smsdss'
	-- Create the table if it does not exist
	IF NOT EXISTS(
		SELECT TOP 1 *
		FROM SYSOBJECTS 
		WHERE NAME = 'c_covid_hhs_positive_admitted_tbl'
		AND XTYPE = 'U'
	)

	-- Get records that from the current extract that match the HHS COVID Positive Admitted definition
	WITH CTE AS (
		SELECT MRN,
			PTNO_NUM,
			Pt_Name,
			Pt_Age,
			Pt_Gender,
			Race_Cd_Desc,
			Adm_Dtime,
			DC_DTime,
			Nurs_Sta,
			Bed,
			In_House,
			Hosp_Svc,
			Pt_Accomodation,
			Dx_Order,
			Covid_Indicator,
			PatientReasonforSeekingHC,
			Mortality_Flag,
			Pos_MRN,
			Pt_ADT,
			RESULT_CLEAN,
			Distinct_Visit_Flag,
			Vented,
			Last_Vent_Check,
			Order_NO,
			Covid_Order,
			Order_DTime,
			Order_Status,
			Order_Status_DTime,
			Result_DTime,
			Result,
			DC_Disp,
			Subseqent_Visit_Flag,
			Order_Flag,
			Result_Flag,
			PT_Street_Address,
			PT_City,
			PT_State,
			PT_Zip_CD,
			PT_Comorbidities,
			PT_Admitted_From,
			Occupation,
			PT_Employer,
			[2BMHEMPL],
			[2EMPCODE],
			PT_DOB,
			State_Age_Group,
			HHS_Admits_Last_24_Hours,
			first_positive_flag_dtime,
			last_negative_flag_dtime,
			pt_last_test_positive,
			Last_Positive_Result_DTime,
			[B97.29],
			[U07.1],
			[Z03.818],
			[Z20.828],
			DC_Summary_CV19_Dx,
			DC_Summary_CV19_Dx_CreatedDTIME,
			Clinical_Note_CV19_Dx,
			Clinical_Note_CV19_Dx_CreatedDTime,
			Attending_Provider,
			Isolation_Indicator,
			Isolation_Indicator_Abbr,
			Dx_Order_Abbr,
			DC_Summary_Abbr,
			Clinical_Note_Abbr,
			Positive_Flu_Flag,
			RunDateTime,
			[SP_Run_DateTime] = GETDATE(),
			[positive_suspect_noncovid] = CASE 
				WHEN distinct_visit_flag = 1
					AND result_clean = 'detected'
					AND order_status = 'result signed'
					THEN 'positive'
				WHEN Distinct_Visit_Flag = '1'
					AND pt_last_test_positive = '1'
					AND datediff(day, last_positive_result_dtime, cast(getdate() AS DATE)) <= 30
					AND PatientReasonforSeekingHC NOT LIKE '%non covid%'
					AND (
						PatientReasonforSeekingHC LIKE '%Sepsis%'
						OR PatientReasonforSeekingHC LIKE '%SEPS%'
						OR PatientReasonforSeekingHC LIKE '%PNEUM%'
						OR PatientReasonforSeekingHC LIKE '%PNA%'
						OR PatientReasonforSeekingHC LIKE '%FEVER%'
						OR PatientReasonforSeekingHC LIKE '%CHILLS%'
						OR PatientReasonforSeekingHC LIKE '%SOB%'
						OR PatientReasonforSeekingHC LIKE '%SHORTNESS OF BREATH%'
						OR PatientReasonforSeekingHC LIKE '%SHORT OF BREATH%'
						OR PatientReasonforSeekingHC LIKE '%RESPIRATO%FAIL%'
						OR PatientReasonforSeekingHC LIKE '%RESP%FAIL%'
						OR PatientReasonforSeekingHC LIKE '%COUGH%'
						OR PatientReasonforSeekingHC LIKE '%WEAKNESS%'
						OR PatientReasonforSeekingHC LIKE '%PN%'
						OR PatientReasonforSeekingHC LIKE '%COVID%'
						)
					THEN 'positive'
				WHEN Pos_MRN = '1'
					AND Last_Positive_Result_DTime >= Adm_Dtime
					THEN 'positive'
				WHEN Pos_MRN = '1'
					AND DATEDIFF(DAY, Last_Positive_Result_DTime, Adm_Dtime) <= 30
					AND PatientReasonforSeekingHC NOT LIKE '%non covid%'
					AND (
						PatientReasonforSeekingHC LIKE '%Sepsis%'
						OR PatientReasonforSeekingHC LIKE '%SEPS%'
						OR PatientReasonforSeekingHC LIKE '%PNEUM%'
						OR PatientReasonforSeekingHC LIKE '%PNA%'
						OR PatientReasonforSeekingHC LIKE '%FEVER%'
						OR PatientReasonforSeekingHC LIKE '%CHILLS%'
						OR PatientReasonforSeekingHC LIKE '%SOB%'
						OR PatientReasonforSeekingHC LIKE '%SHORTNESS OF BREATH%'
						OR PatientReasonforSeekingHC LIKE '%SHORT OF BREATH%'
						OR PatientReasonforSeekingHC LIKE '%RESPIRATO%FAIL%'
						OR PatientReasonforSeekingHC LIKE '%RESP%FAIL%'
						OR PatientReasonforSeekingHC LIKE '%COUGH%'
						OR PatientReasonforSeekingHC LIKE '%WEAKNESS%'
						OR PatientReasonforSeekingHC LIKE '%PN%'
						OR PatientReasonforSeekingHC LIKE '%COVID%'
						)
					THEN 'positive'
				WHEN RESULT_CLEAN = 'detected'
					AND Order_Status != 'result signed'
					THEN 'suspect'
				WHEN Covid_Indicator = 'covid 19 or r/o covid 19 patient'
					THEN 'suspect'
				ELSE 'non_covid'
				END
		FROM smsdss.c_covid_extract_tbl
		WHERE In_House = '1'
			AND Distinct_Visit_Flag = '1'
	)

	-- INSERT RECORDS INTO THE TABLE
	SELECT *
	INTO smsdss.c_covid_hhs_positive_admitted_tbl
	FROM CTE
	WHERE positive_suspect_noncovid = 'positive'


ELSE

	WITH CTEB AS (
		SELECT MRN,
			PTNO_NUM,
			Pt_Name,
			Pt_Age,
			Pt_Gender,
			Race_Cd_Desc,
			Adm_Dtime,
			DC_DTime,
			Nurs_Sta,
			Bed,
			In_House,
			Hosp_Svc,
			Pt_Accomodation,
			Dx_Order,
			Covid_Indicator,
			PatientReasonforSeekingHC,
			Mortality_Flag,
			Pos_MRN,
			Pt_ADT,
			RESULT_CLEAN,
			Distinct_Visit_Flag,
			Vented,
			Last_Vent_Check,
			Order_NO,
			Covid_Order,
			Order_DTime,
			Order_Status,
			Order_Status_DTime,
			Result_DTime,
			Result,
			DC_Disp,
			Subseqent_Visit_Flag,
			Order_Flag,
			Result_Flag,
			PT_Street_Address,
			PT_City,
			PT_State,
			PT_Zip_CD,
			PT_Comorbidities,
			PT_Admitted_From,
			Occupation,
			PT_Employer,
			[2BMHEMPL],
			[2EMPCODE],
			PT_DOB,
			State_Age_Group,
			HHS_Admits_Last_24_Hours,
			first_positive_flag_dtime,
			last_negative_flag_dtime,
			pt_last_test_positive,
			Last_Positive_Result_DTime,
			[B97.29],
			[U07.1],
			[Z03.818],
			[Z20.828],
			DC_Summary_CV19_Dx,
			DC_Summary_CV19_Dx_CreatedDTIME,
			Clinical_Note_CV19_Dx,
			Clinical_Note_CV19_Dx_CreatedDTime,
			Attending_Provider,
			Isolation_Indicator,
			Isolation_Indicator_Abbr,
			Dx_Order_Abbr,
			DC_Summary_Abbr,
			Clinical_Note_Abbr,
			Positive_Flu_Flag,
			RunDateTime,
			[SP_Run_DateTime] = GETDATE(),
			[positive_suspect_noncovid] = CASE 
				WHEN distinct_visit_flag = 1
					AND result_clean = 'detected'
					AND order_status = 'result signed'
					THEN 'positive'
				WHEN Distinct_Visit_Flag = '1'
					AND pt_last_test_positive = '1'
					AND datediff(day, last_positive_result_dtime, cast(getdate() AS DATE)) <= 30
					AND PatientReasonforSeekingHC NOT LIKE '%non covid%'
					AND (
						PatientReasonforSeekingHC LIKE '%Sepsis%'
						OR PatientReasonforSeekingHC LIKE '%SEPS%'
						OR PatientReasonforSeekingHC LIKE '%PNEUM%'
						OR PatientReasonforSeekingHC LIKE '%PNA%'
						OR PatientReasonforSeekingHC LIKE '%FEVER%'
						OR PatientReasonforSeekingHC LIKE '%CHILLS%'
						OR PatientReasonforSeekingHC LIKE '%SOB%'
						OR PatientReasonforSeekingHC LIKE '%SHORTNESS OF BREATH%'
						OR PatientReasonforSeekingHC LIKE '%SHORT OF BREATH%'
						OR PatientReasonforSeekingHC LIKE '%RESPIRATO%FAIL%'
						OR PatientReasonforSeekingHC LIKE '%RESP%FAIL%'
						OR PatientReasonforSeekingHC LIKE '%COUGH%'
						OR PatientReasonforSeekingHC LIKE '%WEAKNESS%'
						OR PatientReasonforSeekingHC LIKE '%PN%'
						OR PatientReasonforSeekingHC LIKE '%COVID%'
						)
					THEN 'positive'
				WHEN Pos_MRN = '1'
					AND Last_Positive_Result_DTime >= Adm_Dtime
					THEN 'positive'
				WHEN Pos_MRN = '1'
					AND DATEDIFF(DAY, Last_Positive_Result_DTime, Adm_Dtime) <= 30
					AND PatientReasonforSeekingHC NOT LIKE '%non covid%'
					AND (
						PatientReasonforSeekingHC LIKE '%Sepsis%'
						OR PatientReasonforSeekingHC LIKE '%SEPS%'
						OR PatientReasonforSeekingHC LIKE '%PNEUM%'
						OR PatientReasonforSeekingHC LIKE '%PNA%'
						OR PatientReasonforSeekingHC LIKE '%FEVER%'
						OR PatientReasonforSeekingHC LIKE '%CHILLS%'
						OR PatientReasonforSeekingHC LIKE '%SOB%'
						OR PatientReasonforSeekingHC LIKE '%SHORTNESS OF BREATH%'
						OR PatientReasonforSeekingHC LIKE '%SHORT OF BREATH%'
						OR PatientReasonforSeekingHC LIKE '%RESPIRATO%FAIL%'
						OR PatientReasonforSeekingHC LIKE '%RESP%FAIL%'
						OR PatientReasonforSeekingHC LIKE '%COUGH%'
						OR PatientReasonforSeekingHC LIKE '%WEAKNESS%'
						OR PatientReasonforSeekingHC LIKE '%PN%'
						OR PatientReasonforSeekingHC LIKE '%COVID%'
						)
					THEN 'positive'
				WHEN RESULT_CLEAN = 'detected'
					AND Order_Status != 'result signed'
					THEN 'suspect'
				WHEN Covid_Indicator = 'covid 19 or r/o covid 19 patient'
					THEN 'suspect'
				ELSE 'non_covid'
				END
		FROM smsdss.c_covid_extract_tbl
		WHERE In_House = '1'
			AND Distinct_Visit_Flag = '1'
	)

	-- INSERT RECORDS INTO THE TABLE
	INSERT INTO smsdss.c_covid_hhs_positive_admitted_tbl
	SELECT *
	FROM CTEB
	WHERE positive_suspect_noncovid = 'positive'

END