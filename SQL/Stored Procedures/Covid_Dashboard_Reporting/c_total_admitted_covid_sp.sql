USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_total_admitted_covid_positive_sp]    Script Date: 12/28/2020 11:21:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_total_admitted_covid_sp.sql

Input Parameters:
	none

Tables/Views:
	smsdss.c_covid_extract_tbl

Creates Table:
	smsdss.c_tot_adm_covid_tbl

Functions:
	none

Author: Steven P Sanderson II, MPH

Purpose/Description
	Get Total Admitted COVID Patients for Dashboard. This table will
    feed the stored procedures:
    dbo.c_total_admitted_covid_positive_sp
    dbo.c_total_admitted_covid_suspect_sp

Revision History:
Date		Version		Description
----		----		----
2020-12-29	v1			Initial Creation
2020-12-31	v2			Fix issue where the extract had columns Arrival Mode
						and Amb added but we don't care in this procedure
***********************************************************************
*/

ALTER PROCEDURE [dbo].[c_total_admitted_covid_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- CREATE TABLE IF NOT EXISTS
	IF OBJECT_ID('smsdss.c_tot_adm_covid_tbl', 'U') IS NOT NULL
		INSERT INTO smsdss.c_tot_adm_covid_tbl
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
	ELSE
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
				WHEN RESULT_CLEAN = 'detected'
					AND Order_Status != 'result signed'
					THEN 'suspect'
				WHEN Covid_Indicator = 'covid 19 or r/o covid 19 patient'
					THEN 'suspect'
				ELSE 'non_covid'
				END
		INTO smsdss.c_tot_adm_covid_tbl
		FROM smsdss.c_covid_extract_tbl
		WHERE In_House = '1'
			AND Distinct_Visit_Flag = '1'
END
