USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_total_discharged_yesterday_covid_pos_sp]    Script Date: 12/21/2020 7:55:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_total_discharged_yesterday_covid_pos_sp.sql

Input Parameters:
	none

Tables/Views:
	smsdss.c_covid_extract_tbl

Creates Table:
	smsdss.c_tot_dsch_yday_covid_pos_tbl

Functions:
	none

Author: Steven P Sanderson II, MPH

Purpose/Description
	Get Total Discharged Yesterday COVID Positive Patients for Dashboard

Revision History:
Date		Version		Description
----		----		----
2020-12-18	v1			Initial Creation
2020-12-21	v2			DROP A.In_House = '1' - Cannot both be 1 and 
						discharged. 
						Add A.Pt_ADT = 'Discharged'
2020-12-31	v3			Change to run from smsdss.c_tot_dsch_covid_tbl
***********************************************************************
*/
ALTER PROCEDURE [dbo].[c_total_discharged_yesterday_covid_pos_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- Check table exists
	IF OBJECT_ID('smsdss.c_tot_dsch_yday_covid_pos_tbl', 'U') IS NOT NULL
		INSERT INTO smsdss.c_tot_dsch_yday_covid_pos_tbl
		-- SUSPECT PTS DISCHARGED YESTERDAY
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
			sp_run_datetime AS Run_DateTime
		FROM smsdss.c_tot_dsch_covid_tbl
		WHERE SP_Run_DateTime = (
				SELECT MAX(SP_Run_DateTime)
				FROM smsdss.c_tot_dsch_covid_tbl
				)
			AND positive_suspect_noncovid = 'POSITIVE'
			AND DATEDIFF(DAY, DC_DTIME, CAST(GETDATE() AS DATE)) = 1
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
			sp_run_datetime AS Run_DateTime
		INTO smsdss.c_tot_dsch_yday_covid_pos_tbl
		FROM smsdss.c_tot_adm_covid_tbl
		WHERE SP_Run_DateTime = (
				SELECT MAX(SP_Run_DateTime)
				FROM smsdss.c_tot_dsch_covid_tbl
				)
			AND positive_suspect_noncovid = 'POSITIVE'
			AND DATEDIFF(DAY, DC_DTIME, CAST(GETDATE() AS DATE)) = 1
END
