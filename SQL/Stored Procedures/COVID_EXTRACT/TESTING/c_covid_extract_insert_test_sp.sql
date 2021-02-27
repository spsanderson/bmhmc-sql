USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************

File: c_covid_extract_insert_test_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].[dbo].HStaff
	[SC_server].[Soarian_Clin_Prd_1].[dbo].HStaffAssociations
	smsdss.c_covid_patient_visit_data_test_tbl
	smsdss.c_covid_rt_census_test_tbl
	smsdss.c_covid_orders_test_tbl
	smsdss.c_covid_order_occ_test_tbl
	smsdss.c_covid_order_results_test_tbl
	smsdss.c_covid_misc_ref_results_test_tbl
	smsdss.c_covid_miscref_test_tbl
	smsdss.c_covid_ext_pos_tbl
	smsdss.c_covid_wellsoft_test_tbl
	smsdss.c_covid_vents_test_tbl
	smsdss.c_covid_posres_subsequent_visits_test_tbl
	smsdss.c_covid_hwac_pivot_test_tbl
	smsdss.c_covid_adt02order_test_tbl
	smsdss.c_covid_indicator_text_test_tbl
	smsdss.c_covid_dx_cd_ind_test_tbl
	smsdss.c_covid_pdoc_test_tbl
	smsdss.c_positive_covid_visits_test_tbl
	smsdss.BMH_UserTwoFact_V
	smsmir.mir_pers_addr
	smsmir.pms_user_episo

Creates Table:
	smsdss.c_covid_extract_test_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Insert final results into smsdss.c_covid_extract_test_tbl

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2020-07-15	v2			Add RunDateTime
2020-08-04	v3			Add Isolation Indicator
						Add Isolation Indicator Abbr
						Add Dx_Order_Abbr
						Add Dc_Summary_Abbr
						Add Clinical_Note_Abbr
2020-08-21	v4			Add HHS Age groupings
							Admits_In_Last_24_Hrs_0_17
							Admits_In_Last_24_Hrs_18_19
							Admits_In_Last_24_Hrs_20_29
							Admits_In_Last_24_Hrs_30_39
							Admits_In_Last_24_Hrs_40_49
							Admits_In_Last_24_Hrs_50_59
							Admits_In_Last_24_Hrs_60_69
							Admits_In_Last_24_Hrs_70_79
2020-08-25	v5			Add HHS Age Grouping
							Admits_In_Last_24_Hrs_80+
2020-08-26	v6			Edit HHS Age Grouping column name and case statement values
2020-08-31	v7			Add two test patient accounts in the account 
						exclusion list.
2020-11-13	v8			Add Employee flag
2020-11-24	v9			Add employer field from smsmir.mir_pers_addr pers_type = 'PE'
2020-12-16	v10			Add OR (A.Result_Flag = '0' AND A.Order_Flag = '1')
						but keep commented out for now.
						Add Arrival Mode and Arrival Mode Desc
2020-12-24	v11			Add B.Result_DTime IS NOT NULL to the OUTER APPLY 
						statements that get the Fist Positive, Last Positive and
						Last Negative times.
						Modify CASE STATEMENTS for 
						1. first_positive_flag_dtime
						2. last_negative_flag_dtime
						3. pt_last_test_positive
						4. last_positive_result_dtime
2020-12-28	v12			Fix issues stemming from 12-24-2020 update
2021-02-25  v13         Rewrite for new stream testing
***********************************************************************
*/
ALTER PROCEDURE [dbo].[c_covid_extract_insert_test_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	/*

	Pull it all together

	Step 1 Intitial results into #TEMPA

	*/
	SELECT PVD.MRN,
		PVD.PatientAccountID,
		PVD.PatientVisitOID,
		PVD.Pt_Name,
		PVD.Pt_Age,
		PVD.Pt_Gender,
		PVD.Race_Cd_Desc,
		PVD.Adm_Dtime,
		PVD.DC_DTime,
		CASE 
			WHEN PVD.DC_DTime IS NULL
				--AND (LEFT(pvd.patientAccountID,1) = '1'  OR PVD.hosp_svc = 'OBV')
				THEN RT.Nurs_Sta
			ELSE ''
			END AS [Nurs_Sta],
		CASE 
			WHEN PVD.DC_DTime IS NULL
				--AND (LEFT(pvd.patientAccountID,1) = '1'  OR PVD.hosp_svc = 'OBV')
				THEN RT.Bed
			ELSE ''
			END AS [Bed],
		CASE 
			WHEN PVD.DC_DTime IS NULL
				AND RT.bed IS NOT NULL
				--AND PVD.Hosp_Svc <> 'D23'
				--AND (LEFT(pvd.patientAccountID,1) = '1'  OR PVD.hosp_svc = 'OBV' or pvd.hosp_svc = 'EOR')
				THEN 1
			ELSE 0
			END AS [In_House],
		PVD.Hosp_Svc,
		PVD.Pt_Accomodation,
		PVD.PatientReasonforSeekingHC,
		COALESCE(CAST(CVORD.OrderID AS VARCHAR), CAST(MREF.OrderID AS VARCHAR), WS.Covid_Test_Outside_Hosp) AS [Order_No],
		CASE 
			WHEN COALESCE(CAST(CVORD.OrderAbbreviation AS VARCHAR), CAST(MREF.OrderAbbreviation AS VARCHAR), WS.Covid_Test_Outside_Hosp) = 'Yes'
				THEN 'EXTERNAL'
			WHEN EXTPOS.Result IS NOT NULL
				THEN 'EXTERNAL'
			WHEN COALESCE(CAST(CVORD.OrderAbbreviation AS VARCHAR), CAST(MREF.OrderAbbreviation AS VARCHAR), WS.Covid_Test_Outside_Hosp) IS NULL
				THEN 'NO ORDER FOUND'
			ELSE COALESCE(CAST(CVORD.OrderAbbreviation AS VARCHAR), CAST(MREF.OrderAbbreviation AS VARCHAR), WS.Covid_Test_Outside_Hosp)
			END AS [Covid_Order],
		COALESCE(CVORD.CreationTime, MREF.OrderDTime) AS [Order_DTime],
		COALESCE(CVOCC.OrderOccurrenceStatus, MREF.OrderOccurrenceStatus, WS.Order_Status) AS [Order_Status],
		COALESCE(CVOCC.StatusEnteredDatetime, MREF.StatusEnteredDateTime) AS [Order_Status_DTime],
		CASE 
			WHEN EXTPOS.Test_Date IS NOT NULL
				THEN EXTPOS.Test_Date
			WHEN MISCREF.Test_Date IS NOT NULL
				THEN MISCREF.Test_Date
			ELSE COALESCE(CVRES.ResultDateTime, MREF.ResultDateTime)
			END AS [Result_DTime],
		CASE 
			WHEN EXTPOS.Result IS NOT NULL
				THEN EXTPOS.Result
			WHEN MISCREF.Result IS NOT NULL
				THEN MISCREF.Result
			ELSE COALESCE(CVRES.ResultValue, MREF.ResultValue, WS.Result)
			END AS [Result],
		PVD.DC_Disp,
		PVD.Mortality_Flag,
		CASE 
			WHEN VENT.PatientVisitOID IS NULL
				THEN ''
			ELSE 'Vented'
			END AS [Vented],
		--CASE 
		--	WHEN VENT.PatientVisitOID IS NULL
		--		THEN 0
		--	ELSE 1
		--	END AS [Vent_Flag],
		VENT.CollectedDT AS [Last_Vent_Check],
		[Subseqent_Visit_Flag] = CASE 
			WHEN SUB.PatientVisitOID IS NOT NULL
				THEN 1
			ELSE 0
			END,
		[Order_Flag] = CASE 
			WHEN COALESCE(CAST(CVORD.OrderID AS VARCHAR), CAST(MREF.OrderID AS VARCHAR), WS.Covid_Test_Outside_Hosp) IS NULL
				THEN 0
			ELSE 1
			END,
		[Result_Flag] = CASE 
			WHEN EXTPOS.Result IS NOT NULL
				THEN 1
			WHEN MISCREF.Result IS NOT NULL
				THEN 1
			WHEN CVRES.ResultValue IS NOT NULL
				THEN 1
			WHEN MREF.ResultValue IS NOT NULL
				THEN 1
			WHEN WS.Result IS NOT NULL
				THEN 1
			ELSE 0
			END,
		PVD.PT_Street_Address,
		PVD.PT_City,
		PVD.PT_State,
		PVD.PT_Zip_CD,
		HWACPvt.[A_Admit From] AS [PT_Admitted_From],
		HWACPvt.A_BMH_ListCoMorb AS [PT_Comorbidities],
		--HWACPvt.Ht AS [PT_Height],
		--HWACPvt.Wt AS [PT_Weight],
		--LABSPvt.A1c,
		--LABSPvt.Chol,
		--LABSPvt.HDL,
		--LABSPvt.LDL,
		--LABSPvt.Trig,
		pvd.PT_DOB,
		ADT02FINALTBL.Dx_Order,
		CVIND.Covid_Indicator,
		CV19DX.[B97.29],
		CV19DX.[U07.1],
		CV19DX.[Z03.818],
		CV19DX.[Z20.828],
		PDOC.Clinical_Note_CV19_Dx,
		PDOC.Clinical_Note_CV19_Dx_CreatedDTime,
		PDOC.DC_Summary_CV19_Dx,
		PDOC.DC_Summary_CV19_Dx_CreatedDTime,
		UPPER(ATN_DR.PRACT_RPT_NAME) AS [Attending_Provider],
		PVD.Isolation_Indicator,
		PVD.Isolation_Indicator_Abbr,
		ADT02FINALTBL.Dx_Order_Abbr,
		PDOC.DC_Summary_Abbr,
		PDOC.Clinical_Note_Abbr,
		CASE 
			WHEN (
					FLU.Flu_A LIKE '%POSITIVE%'
					OR FLU.Flu_B LIKE '%POSITIVE%'
					)
				THEN 1
			ELSE 0
			END AS [Positive_Flu_Flag]
	INTO #TEMPA
	FROM smsdss.c_covid_patient_visit_data_test_tbl AS PVD
	LEFT OUTER JOIN smsdss.c_covid_rt_census_test_tbl AS RT ON PVD.PatientVisitOID = RT.PatientVisitOID
	LEFT OUTER JOIN smsdss.c_covid_orders_test_tbl AS CVORD ON PVD.PatientVisitOID = cvord.PatientVisitOID
	LEFT OUTER JOIN smsdss.c_covid_order_occ_test_tbl AS CVOCC ON CVOCC.Order_OID = CVORD.ObjectID
	LEFT OUTER JOIN smsdss.c_covid_order_results_test_tbl AS CVRES ON CVOCC.ObjectID = CVRES.OccurrenceOID
	--AND PVD.PatientVisitOID = CVRES.PatientVisitOID
	LEFT OUTER JOIN smsdss.c_covid_misc_ref_results_test_tbl AS MREF ON PVD.PatientVisitOID = MREF.PatientVisitOID
	LEFT OUTER JOIN smsdss.c_covid_miscref_test_tbl AS MISCREF ON PVD.PatientVisitOID = MISCREF.PatientVisitOID
	LEFT OUTER JOIN smsdss.c_covid_ext_pos_tbl AS EXTPOS ON PVD.PatientVisitOID = EXTPOS.PatientVisitOID
	LEFT OUTER JOIN smsdss.c_covid_wellsoft_test_tbl AS WS ON PVD.PatientAccountID = WS.Account
	LEFT OUTER JOIN smsdss.c_covid_vents_test_tbl AS VENT ON PVD.PatientVisitOID = VENT.PatientVisitOID
	-- Flu
	LEFT OUTER JOIN SMSDSS.c_covid_flu_results_test_tbl AS FLU ON PVD.PatientVisitOID = FLU.PatientVisitOID
	-- SUBSEQUENT VISIT FLAG
	LEFT OUTER JOIN smsdss.c_covid_posres_subsequent_visits_test_tbl AS SUB ON PVD.PatientVisitOID = SUB.PatientVisitOID
	-- Comorbidities, Admitted From, Height, Weight
	LEFT OUTER JOIN smsdss.c_covid_hwac_pivot_test_tbl AS HWACPvt ON PVD.PatientAccountID = HWACPvt.PatientAccountID
	-- Labs
	--LEFT OUTER JOIN #LabsPivot_Tbl AS LabsPvt ON PVD.PatientVisitOID = LabsPvt.PatientVisit_OID
	-- ADT02
	LEFT OUTER JOIN smsdss.c_covid_adt02order_test_tbl AS ADT02FINALTBL ON PVD.PatientVisitOID = ADT02FINALTBL.PatientVisit_OID
	-- covid indicator text
	LEFT OUTER JOIN smsdss.c_covid_indicator_text_test_tbl AS CVIND ON PVD.PatientVisitOID = CVIND.PatientVisit_OID
	-- CV19DX
	LEFT OUTER JOIN smsdss.c_covid_dx_cd_ind_test_tbl AS CV19DX ON PVD.PatientAccountID = CV19DX.PatientAccountID
	-- PDOC
	LEFT OUTER JOIN smsdss.c_covid_pdoc_test_tbl AS PDOC ON PVD.PatientVisitOID = PDOC.PATIENTVISIT_OID
	-- ATN DOCTOR
	LEFT OUTER JOIN (
		SELECT b.Name AS PRACT_RPT_NAME,
			a.patientvisit_oid
		FROM [SC_server].[Soarian_Clin_Prd_1].[dbo].HStaff B
		INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].HStaffAssociations a ON b.objectid = a.Staff_oid
		WHERE a.RelationType = 0
			AND a.IsVersioned = 0
		) AS ATN_DR ON ATN_DR.PatientVisit_OID = PVD.PatientVisitOID
	WHERE PVD.MRN IS NOT NULL
	ORDER BY PVD.Pt_Name,
		CVRES.ResultDateTime DESC,
		CVORD.CreationTime DESC;

	/*

	Final Join and table insert

	*/
	-- Drop records table and recreate for insert
	-- done if columns change as they often have been
	IF OBJECT_ID('smsdss.c_covid_extract_test_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_covid_extract_test_tbl;

	-- Create the table in the specified schema
	CREATE TABLE smsdss.c_covid_extract_test_tbl (
		MRN INT NULL,
		PTNO_NUM INT NULL,
		[Pt_Name] VARCHAR(500) NULL,
		[Pt_Age] INT NULL,
		[Pt_Gender] VARCHAR(5) NULL,
		[Race_Cd_Desc] VARCHAR(100) NULL,
		[Adm_Dtime] DATETIME2 NULL,
		[DC_DTime] DATETIME2 NULL,
		[Nurs_Sta] VARCHAR(100) NULL,
		[Bed] VARCHAR(100) NULL,
		[In_House] INT NULL,
		[Hosp_Svc] VARCHAR(100) NULL,
		[Pt_Accomodation] VARCHAR(500) NULL,
		[Dx_Order] VARCHAR(8000) NULL,
		[Covid_Indicator] VARCHAR(8000) NULL,
		[PatientReasonforSeekingHC] VARCHAR(8000) NULL,
		[Mortality_Flag] INT NULL,
		[Pos_MRN] INT NULL,
		[Pt_ADT] VARCHAR(100) NULL,
		[RESULT_CLEAN] VARCHAR(8000) NULL,
		[Distinct_Visit_Flag] INT NULL,
		[Vented] VARCHAR(100) NULL,
		[Last_Vent_Check] DATETIME2 NULL,
		[Order_NO] VARCHAR(250) NULL,
		[Covid_Order] VARCHAR(250) NULL,
		[Order_DTime] DATETIME2 NULL,
		[Order_Status] VARCHAR(8000) NULL,
		[Order_Status_DTime] DATETIME2 NULL,
		[Result_DTime] DATETIME2 NULL,
		[Result] VARCHAR(8000) NULL,
		[DC_Disp] VARCHAR(8000) NULL,
		--[Vent_Flag],
		[Subseqent_Visit_Flag] INT NULL,
		[Order_Flag] INT NULL,
		[Result_Flag] INT NULL,
		[PT_Street_Address] VARCHAR(8000) NULL,
		[PT_City] VARCHAR(5000) NULL,
		[PT_State] VARCHAR(100) NULL,
		[PT_Zip_CD] INT NULL,
		--[PT_Height],
		--[PT_Weight],
		[PT_Comorbidities] VARCHAR(8000) NULL,
		[PT_Admitted_From] VARCHAR(8000) NULL,
		--,[Chol]
		--,[HDL]
		--,[LDL]
		--,[Trig]
		--,[A1c]
		[Occupation] VARCHAR(8000) NULL,
		[PT_Employer] VARCHAR(500) NULL,
		[2BMHEMPL] VARCHAR(500) NULL,
		[2EMPCODE] VARCHAR(500) NULL,
		[PT_DOB] DATETIME2 NULL,
		[State_Age_Group] VARCHAR(100) NULL,
		[HHS_Admits_Last_24_Hours] VARCHAR(100) NULL,
		[first_positive_flag_dtime] DATETIME2 NULL,
		[last_negative_flag_dtime] DATETIME2 NULL,
		[pt_last_test_positive] INT NULL,
		[Last_Positive_Result_DTime] DATETIME2 NULL,
		[B97.29] VARCHAR(100) NULL,
		[U07.1] VARCHAR(100) NULL,
		[Z03.818] VARCHAR(100) NULL,
		[Z20.828] VARCHAR(100) NULL,
		[DC_Summary_CV19_Dx] VARCHAR(8000) NULL,
		[DC_Summary_CV19_Dx_CreatedDTIME] DATETIME2 NULL,
		[Clinical_Note_CV19_Dx] VARCHAR(8000) NULL,
		[Clinical_Note_CV19_Dx_CreatedDTime] DATETIME2 NULL,
		[Attending_Provider] VARCHAR(8000) NULL,
		[Isolation_Indicator] VARCHAR(500) NULL,
		[Isolation_Indicator_Abbr] VARCHAR(500) NULL,
		[Dx_Order_Abbr] VARCHAR(500) NULL,
		[DC_Summary_Abbr] VARCHAR(500) NULL,
		[Clinical_Note_Abbr] VARCHAR(500) NULL,
		[Positive_Flu_Flag] INT NULL,
		[Arrival_Mode] VARCHAR(500) NULL,
		[Arrival_Mode_Description] VARCHAR(500) NULL,
		[RunDateTime] DATETIME2
		);

	INSERT INTO smsdss.c_covid_extract_test_tbl
	SELECT A.MRN,
		A.PatientAccountID AS [PTNO_NUM],
		A.Pt_Name,
		A.Pt_Age,
		A.Pt_Gender,
		A.Race_Cd_Desc,
		A.Adm_Dtime,
		A.DC_DTime,
		A.Nurs_Sta,
		A.Bed,
		A.In_House,
		A.Hosp_Svc,
		A.Pt_Accomodation,
		A.Dx_Order,
		A.Covid_Indicator,
		A.PatientReasonforSeekingHC,
		A.Mortality_Flag,
		[Pos_MRN] = CASE 
			WHEN A.MRN IN (
					SELECT DISTINCT MRN
					FROM SMSDSS.c_positive_covid_visits_test_tbl
					)
				THEN '1'
			WHEN A.Result LIKE 'DETECTED%'
				THEN '1'
			WHEN A.Result LIKE 'DETECE%'
				THEN '1'
			WHEN A.Result LIKE 'POSITIV%'
				THEN '1'
			WHEN A.Result LIKE 'PRESUMP% POSITIVE%'
				THEN '1'
			ELSE '0'
			END,
		[Pt_ADT] = CASE 
			WHEN A.Mortality_Flag = '1'
				AND ROW_NUMBER() OVER (
					PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
						A.ORDER_DTIME DESC
					) = 1
				THEN 'Expired'
			WHEN (
					LEFT(A.PatientAccountID, 1) = '1'
					OR A.Hosp_Svc IN ('OBV')
					)
				AND A.DC_DTime IS NULL
				AND ROW_NUMBER() OVER (
					PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
						A.ORDER_DTIME DESC
					) = 1
				THEN 'Admitted'
			WHEN (
					LEFT(A.PatientAccountID, 1) = '1'
					OR A.Hosp_Svc IN ('OBV')
					)
				AND A.DC_DTime IS NOT NULL
				AND ROW_NUMBER() OVER (
					PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
						A.ORDER_DTIME DESC
					) = 1
				THEN 'Discharged'
			WHEN LEFT(A.PatientAccountID, 1) = '8'
				AND ROW_NUMBER() OVER (
					PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
						A.ORDER_DTIME DESC
					) = 1
				THEN 'ED Only'
			WHEN ROW_NUMBER() OVER (
					PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
						A.ORDER_DTIME DESC
					) = 1
				THEN 'Outpatient'
			ELSE 'z - Old Order'
			END,
		[RESULT_CLEAN] = CASE 
			WHEN A.RESULT LIKE 'DETECTED%'
				THEN 'DETECTED'
			WHEN A.RESULT LIKE 'DETECE%'
				THEN 'DETECTED'
			WHEN A.RESULT LIKE 'POSITIV%'
				THEN 'DETECTED'
			WHEN A.RESULT LIKE 'PRESUMP% POSITIVE%'
				THEN 'DETECTED'
			WHEN A.RESULT LIKE '%NOT DETECTED%'
				THEN 'NOT-DETECTED'
			WHEN A.Result LIKE '%NEGATIVE%'
				THEN 'NOT-DETECTED'
			WHEN A.RESULT IS NULL
				THEN 'NO-RESULT'
			ELSE REPLACE(REPLACE(A.RESULT, CHAR(13), ' '), CHAR(10), ' ')
			END,
		[Distinct_Visit_Flag] = CASE 
			WHEN ROW_NUMBER() OVER (
					PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
						A.ORDER_DTIME DESC
					) = 1
				THEN 1
			ELSE 0
			END,
		A.Vented,
		A.Last_Vent_Check,
		'''' + CAST(A.Order_NO AS VARCHAR) + '''' AS [Order_NO],
		'''' + CAST(A.Covid_Order AS VARCHAR) + '''' AS [Covid_Order],
		A.Order_DTime,
		A.Order_Status,
		A.Order_Status_DTime,
		CASE 
			WHEN A.Result_DTime = '1900-01-01 00:00:00.0000000'
				THEN NULL
			ELSE A.Result_DTime
			END AS [Result_DTime],
		A.Result,
		A.DC_Disp,
		--A.Vent_Flag,
		A.Subseqent_Visit_Flag,
		A.Order_Flag,
		A.Result_Flag,
		A.PT_Street_Address,
		A.PT_City,
		A.PT_State,
		A.PT_Zip_CD,
		--A.PT_Height,
		--A.PT_Weight,
		A.PT_Comorbidities,
		A.PT_Admitted_From,
		--A.Chol,
		--A.HDL,
		--A.LDL,
		--A.Trig,
		--A.A1c,
		PTOcc.user_data_text AS [Occupation],
		EMPLOYER.LAST_NAME AS [EMPLOYER],
		EMPLOYEE.[2BMHEMPL],
		EMPLOYEE.[2EMPCODE],
		A.PT_DOB,
		[State_Age_Group] = CASE 
			WHEN A.Pt_Age < 1
				THEN 'a - <1'
			WHEN A.Pt_Age <= 4
				THEN 'b - 1-4'
			WHEN A.Pt_Age <= 19
				THEN 'c - >4-19'
			WHEN A.Pt_Age <= 44
				THEN 'd - >19-44'
			WHEN A.Pt_Age <= 54
				THEN 'e - >44-54'
			WHEN A.Pt_Age <= 64
				THEN 'f - >54-64'
			WHEN A.Pt_Age <= 74
				THEN 'g - >64-74'
			WHEN A.PT_AGE <= 84
				THEN 'h - >74-84'
			WHEN A.PT_AGE > 84
				THEN 'i - >84'
			END,
		[HHS_Age_Group] = CASE 
			WHEN A.Pt_Age < 18
				THEN '0-17'
			WHEN A.PT_AGE < 20
				THEN '18-19'
			WHEN A.Pt_Age < 30
				THEN '20-29'
			WHEN A.Pt_Age < 40
				THEN '30-39'
			WHEN A.Pt_Age < 50
				THEN '40-49'
			WHEN A.Pt_Age < 60
				THEN '50-59'
			WHEN A.Pt_Age < 70
				THEN '60-69'
			WHEN A.Pt_Age < 80
				THEN '70-79'
			ELSE '80+'
			END,
	[first_positive_flag_dtime] = CASE 
		--WHEN FIRST_RES.Result_DTime = (
		--		SELECT MIN(ZZZ.RESULT_DTIME)
		--		FROM #TEMPA AS ZZZ
		--		WHERE ZZZ.MRN = FIRST_RES.MRN
		--		GROUP BY ZZZ.MRN
		--		)
		WHEN FIRST_RES.result_dtime IS NOT NULL 
			THEN FIRST_RES.Result_DTime
		ELSE NULL
		END,
	[last_negative_flag_dtime] = CASE 
		--WHEN LAST_NEG.Result_DTime = (
		--		SELECT MAX(zzz.RESULT_DTIME)
		--		FROM #TEMPA AS ZZZ
		--		WHERE ZZZ.MRN = LAST_NEG.MRN
		--		GROUP BY ZZZ.MRN
		--		)
		WHEN LAST_NEG.Result_DTime IS NOT NULL
			THEN LAST_NEG.Result_DTime
		ELSE NULL
		END,
	[pt_last_test_positive] = CASE 
		WHEN LAST_RES.Result_DTime = (
				SELECT MAX(ZZZ.Result_DTime)
				FROM #TEMPA AS ZZZ
				WHERE ZZZ.MRN = LAST_RES.MRN
				GROUP BY ZZZ.MRN
				)
			THEN 1
		ELSE 0
		END,
	[Last_Positive_Result_DTime] = CASE 
		WHEN LAST_RES.Result_DTime = '1900-01-01 00:00:00.0000000'
			THEN NULL
		ELSE LAST_RES.Result_DTime
		END,
		A.[B97.29],
		A.[U07.1],
		A.[Z03.818],
		A.[Z20.828],
		A.DC_Summary_CV19_Dx,
		A.DC_Summary_CV19_Dx_CreatedDTIME,
		A.Clinical_Note_CV19_Dx,
		A.Clinical_Note_CV19_Dx_CreatedDTime,
		A.Attending_Provider,
		A.Isolation_Indicator,
		A.Isolation_Indicator_Abbr,
		A.Dx_Order_Abbr,
		A.DC_Summary_Abbr,
		A.Clinical_Note_Abbr,
		A.Positive_Flu_Flag,
		-- Comment back in when Cathy Returns
		ArrivalMode.Arrival_Mode,
		ArrivalMode.Arrival_Mode_Description,
		GETDATE() AS [RunDateTime]
	FROM #TEMPA AS A
	-- occupation
	LEFT OUTER JOIN SMSMIR.pms_user_episo AS PTOcc ON CAST(A.PatientAccountID AS VARCHAR) = CAST(PTOcc.episode_no AS VARCHAR)
		AND PTOcc.user_data_cd = '2PTEMP01'
	-- EMPLOYEE 
	LEFT OUTER JOIN (
		SELECT PVT.episode_no,
			PVT.[2BMHEMPL],
			PVT.[2EMPCODE]
		FROM (
			SELECT episode_no,
				user_data_cd,
				user_data_text
			FROM smsmir.pms_user_episo
			WHERE user_data_cd IN ('2BMHEMPL', '2EMPCODE')
			) AS A
		PIVOT(MAX(USER_DATA_TEXT) FOR USER_DATA_CD IN ("2BMHEMPL", "2EMPCODE")) PVT
			--WHERE PVT.[2BMHEMPL] = 'Y'
		) AS EMPLOYEE ON A.PatientAccountID = EMPLOYEE.episode_no
	-- MIR_PERS_ADDR = 'PE'
	LEFT OUTER JOIN SMSMIR.MIR_PERS_ADDR AS EMPLOYER ON CAST(A.PatientAccountID AS VARCHAR) = SUBSTRING(EMPLOYER.PT_ID, 5, 8)
		AND EMPLOYER.PERS_TYPE = 'PE'
	-- Comment back in when Cathy Comes Back
	LEFT OUTER JOIN (
		SELECT pvt.PtNo_Num,
		PVT.[52] AS [Arrival_Mode],
		pvt.[54] AS [Arrival_Mode_Description]
		FROM (
			SELECT A.PtNo_Num,
			A.UserDataKey,
			A.UserDataText
			FROM SMSDSS.BMH_UserTwoFact_V AS A
			INNER JOIN SMSDSS.c_covid_patient_visit_data_test_tbl AS B
			ON A.PtNo_Num = B.PatientAccountID
			WHERE A.UserDataKey IN ('52','54')
		) AS A
		PIVOT (
			MAX(UserDataText)
			FOR UserDataKey IN ("52","54")
		) AS PVT
	) AS ArrivalMode
	ON A.PatientAccountID = ArrivalMode.PtNo_Num
	OUTER APPLY (
	SELECT TOP 1 B.MRN,
		B.PatientAccountID,
		B.RESULT,
		B.RESULT_DTIME
	FROM #TEMPA AS B
	WHERE (
			B.RESULT LIKE 'DETECTED%'
			OR B.RESULT LIKE 'DETECE%'
			OR B.RESULT LIKE 'POSITIV%'
			OR B.RESULT LIKE 'PRESUMP% POSITIVE%'
			)
		AND A.MRN = B.MRN
	ORDER BY B.Result_DTime DESC,
		B.Order_DTime DESC
	) AS LAST_RES
OUTER APPLY (
	SELECT TOP 1 B.MRN,
		B.PatientAccountID,
		B.RESULT,
		B.RESULT_DTIME
	FROM #TEMPA AS B
	WHERE (
			B.RESULT LIKE 'DETECTED%'
			OR B.RESULT LIKE 'DETECE%'
			OR B.RESULT LIKE 'POSITIV%'
			OR B.RESULT LIKE 'PRESUMP% POSITIVE%'
			)
		AND A.MRN = B.MRN
		AND B.result_dtime IS NOT NULL
	ORDER BY B.Result_DTime ASC,
		B.Order_DTime ASC
	) AS FIRST_RES
OUTER APPLY (
	SELECT TOP 1 B.MRN,
		B.PatientAccountID,
		B.RESULT,
		B.RESULT_DTIME
	FROM #TEMPA AS B
	WHERE (
			B.RESULT LIKE '%NOT DETECTED%'
			OR B.RESULT LIKE '%NEGATIVE%'
			)
		AND A.MRN = B.MRN
		AND B.result_dtime IS NOT NULL
	ORDER BY B.Result_DTime DESC,
		B.Order_DTime DESC
	) AS LAST_NEG
	WHERE A.PatientAccountID NOT IN ('14465701', '14244479', '14862411', '88998935', '14860845', '14891139', '14890891')
		AND (
			-- Capture all subsequent visits of previously positive patients
			A.Subseqent_Visit_Flag = '1'
			OR (
				-- capture all patients with orders and with a result
				A.Order_Flag = '1'
				AND A.Result_Flag = '1'
				)
			-- capture all patients who had a result but maybe no order
			OR A.Result_Flag = '1'
			-- OR Patients with an order AND no result
			--OR (A.Result_Flag = '0' AND A.Order_Flag = '1')
			-- capture all patients who had a positive flu result but maybe no covid order
			OR A.Positive_Flu_Flag = '1'
			-- captrue all currently in house patients
			OR A.In_House = '1'
			)
	ORDER BY A.Pt_Name,
		A.Result_DTime DESC,
		A.Order_DTime DESC;

	DROP TABLE #TEMPA;
END;
