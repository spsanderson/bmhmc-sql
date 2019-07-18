USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [smsdss].[c_BMH_CMDaily_Disch_Disp_sp]
AS

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

/*
Author: Steven P Sanderson II, MPH
Department: Finance, Revenue Cycle

This stored procedure will look for data in the sc_Assessment table view and it's corresponding
Observation in the sc_Observation table view. The Assessment is BMH_CMDaily Discharge Disp
Care Management Daily Dishcarge Disposition.

A primary table of smsdss.c_CM_Daily_DschDisp_Records_tbl will hold all records from epoch:
	2018-04-01
and will go forward in perpetuity with no stop date in site. A row will be returned for each 
observation in the assessment which will then all get rolled up into one record per visit id

The secondary table smsdss.c_CM_Daily_DschDisp_Aggregate_tbl will aggreate the records into
one row per visit id number.

The final table will be smsdss.c_CM_Daily_DschDisp_RptRecords_tbl and will house a report
that will be emailed to the following persons every Monday morning:
	1. MaryAnn Demeo (VP Performance Improvement)
	2. Megan Pontecorvo (Care Coordination Business Manager)
	3. Jacqueline Baranowski-Guido (Director Care Management)

v1 - 2018-05-01		- Initial Creation
v2 - 2018-05-07		- Took out the clause of WHERE FORM_DONE = 0 this will instead
					- be done in the final report query
*/

IF NOT EXISTS (
	SELECT TOP 1 * 
	FROM SYSOBJECTS 
	WHERE name = 'c_CM_Daily_DschDisp_Records_tbl' 
	AND xtype = 'U'
)

BEGIN
	-- Date range for report run
	DECLARE @START DATETIME;
	DECLARE @END   DATETIME;
	DECLARE @ThisDate DATETIME;

	SET @START = '2018-04-01';
	SET @ThisDate = GETDATE();
	--SET @END   = '2018-05-01';
	SET @END = dateadd(wk, datediff(wk, 0, @ThisDate), -1) -- Beginning of this week (Sunday)

	-- if the table does not exist then drop others if they exists
	-- and then create all
	IF EXISTS (
		SELECT TOP 1 * 
		FROM SYSOBJECTS 
		WHERE name = 'c_CM_Daily_DschDisp_Aggregate_tbl' 
		AND xtype = 'U'
	)
	DROP TABLE smsdss.c_CM_Daily_DschDisp_Aggregate_tbl
	
	IF EXISTS (
		SELECT TOP 1 * 
		FROM SYSOBJECTS 
		WHERE name = 'c_CM_Daily_DschDisp_RptRecords_tbl' 
		AND xtype = 'U'
	)
	DROP TABLE smsdss.c_CM_Daily_DschDisp_RptRecords_tbl

	-- Now that tables have been dropped if they exists and the primary
	-- does not, we need to re-create the tables.
	CREATE TABLE smsdss.c_CM_Daily_DschDisp_Records_tbl (
		PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
		, Patient_FirstName VARCHAR(100)
		, Patient_LastName VARCHAR(100)
		, MRN CHAR(6)
		, PtNo_Num CHAR(8)
		, Adm_DTime DATETIME
		, Dsch_DTime DATETIME
		--, Form_Creation_DTime DATETIME
		, Max_Form_Collection_DTime DATETIME
		, Days_Till_Form_Collection INT
		, Form_Collected_by VARCHAR(100)
		, Form_Status VARCHAR(10)
		, Form_FindingAbbr VARCHAR(50)
		, Form_FindingName VARCHAR(250)
		, Form_FindingValue VARCHAR(350)
		, Observation_Last_Change_DTime DATETIME
		, Assessment_Last_Change_DTime DATETIME
		, RunDate DATE
		, RunDTime DATETIME
		, RowNumber INT
		, Anticipated_Discharge_Flag INT
		, List_Provided_Flag INT
		, PT_and_Fam_Notified_Flag INT
		, Post_Hosp_Plan_Rvwd_Flag INT
		, GroupHome_Flag INT
	);

	INSERT INTO smsdss.c_CM_Daily_DschDisp_Records_tbl

	SELECT patient.FirstName AS [Patient_FirstName]
	, patient.LastName AS [Patient_LastName]
	, PLM.Med_Rec_No AS [MRN]
	, pvisit.PatientAccountID AS [PtNo_Num]
	, pvisit.VisitStartDateTime AS [Admit_DTime]
	, pvisit.VisitEndDateTime AS [Disch_DTime]
	--, observation.CreationTime AS [Form_Creation_DTime]
	, assessment.CollectedDT
	, DATEDIFF(DAY
		, pvisit.VisitStartDateTime
		, assessment.CollectedDT
	) AS [Hours_Till_Collection]
	, assessment.UserAbbrName AS [Collected_By]
	, AssessmentStatus AS [Form_Status]
	--, assessMaxID.MaxAssessmentID AS [Assessment_ID]
	, observation.FindingAbbr
	, observation.FindingName
	, observation.[Value]
	, observation.LastCngDtime AS [Observation_Last_Changed_DTime]
	, assessment.LastCngDtime AS [Assessment_Last_Changed_DTime]
	, [RunDate] = CAST(GETDATE() AS date)
	, [RunDTime] = GETDATE()
	, [RN] = ROW_NUMBER() OVER(
		PARTITION BY pvisit.PatientAccountID 
		ORDER BY pvisit.PatientAccountID
	)
	-- ANTICIPATED DISCHARGE DONE -----------------------------------------
	, CASE
		WHEN observation.FindingAbbr = 'A_BMH_AntDCPlan'
			THEN 1
			ELSE 0
		END AS [Anticipated_Discharge_Flag]
	-- LIST PROVIDED DATE ENTERED -----------------------------------------
	, CASE
		WHEN observation.FindingAbbr IN (
			'A_BMH_LT NurHom', --Long Term Nursing Home Facility List Provided On
			'A_BMH_ARListProv', --Acute Rehab Facility List Provide On
			'A_BMH_ALRettoFac', --Assisted Living Facility List Provided On
			'A_BMH_HomCareLis', --Home Care Agency List Provided On
			'A_BMH_FaclityLis', --Facility List Provided On
			'A_BMH_AHRettoFac', --Adult Home List Provided On
			'A_BMH_NurHomList' --Subacute Facility List Provided On

		)
			THEN 1
			ELSE 0
		END AS [List_Provided_Flag]
	-- PATIENT AND FAMILY NOTIFIED ----------------------------------------
	, CASE
		WHEN observation.FindingAbbr IN (
			'A_BMH_AHNotDisc', --Patient and Family Notified
			'A_BMH_ALNotified', --Patient and Family Notified
			'A_BMH_ARNotDisc', --Patient and Family Notified
			'A_BMH_HCNotified', --Patient and Family Notified of Discharge
			'A_BMH_LTNotDisc', --Patient And Family Notified
			'A_BMH_NotifofDis', --Patient and Family Notified
			'A_BMH_PatFamNoti' --Patient and Family Notified

		)
			THEN 1
			ELSE 0
		END AS [PT_and_Fam_Notified_Flag]
	, CASE
		WHEN observation.FindingAbbr = 'A_BMH_PostHosPla'
			AND observation.Value IS NOT NULL
				THEN 1
				ELSE 0
	  END AS [Post_Hosp_Plan_Rvwd_Flag]
	, CASE
		WHEN observation.FindingAbbr = 'A_BMH_GHNotDisc'
			THEN 1
			ELSE 0
	  END AS [GroupHome_Flag]

	FROM smsmir.sc_Patient AS patient
	INNER JOIN smsmir.sc_PatientVisit AS pvisit
	ON patient.RecordId = pvisit.RecordId
		AND patient.ObjectID = pvisit.Patient_oid
	LEFT OUTER JOIN smsmir.sc_Assessment AS assessment
	ON pvisit.Patient_oid = assessment.Patient_oid
		AND pvisit.StartingVisitOID = assessment.PatientVisit_oid
	-- get max assessment id ----------------------------------------------
	INNER JOIN (
		SELECT Patient_oid
		, PatientVisit_oid
		, MAX(AssessmentID) AS MaxAssessmentID
		FROM smsmir.sc_Assessment
		WHERE FormUsage = 'BMH_CMDaily Discharge Disp'
		GROUP BY Patient_oid
		, PatientVisit_oid
	) AS assessMaxID
	ON assessment.Patient_oid = assessMaxID.Patient_oid
		AND assessment.PatientVisit_oid = assessMaxID.PatientVisit_oid
		AND assessment.AssessmentID = assessMaxID.MaxAssessmentID
	-----------------------------------------------------------------------
	LEFT OUTER JOIN smsmir.sc_Observation AS observation
	ON assessment.Patient_oid = observation.Patient_oid
		AND assessment.AssessmentID = observation.AssessmentID
		AND assessment.ObjectID = observation.Assessment_oid
		--AND assessment.LastCngDtime = observation.LastCngDtime
	LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS PLM
	ON pvisit.PatientAccountID = PLM.PtNo_Num

	--WHERE pvisit.PatientAccountID IN (
	--	'',
	--	'',
	--	'',
	--	''
	--)
	WHERE assessment.FormUsage = 'BMH_CMDaily Discharge Disp'
	AND pvisit.VisitEndDateTime >= @START
	AND pvisit.VisitEndDateTime < @END
	AND observation.FindingAbbr IN (
		'A_BMH_AntDCPlan','A_BMH_PostHosPla',
		-- LIST PROVIDED --
		'A_BMH_LT NurHom', --Long Term Nursing Home Facility List Provided On
		'A_BMH_ARListProv', --Acute Rehab Facility List Provide On
		'A_BMH_ALRettoFac', --Assisted Living Facility List Provided On
		'A_BMH_HomCareLis', --Home Care Agency List Provided On
		'A_BMH_FaclityLis', --Facility List Provided On
		'A_BMH_AHRettoFac', --Adult Home List Provided On
		'A_BMH_NurHomList', --Subacute Facility List Provided On
		-- FAMILY NOTIFIED --
		'A_BMH_AHNotDisc', --Patient and Family Notified
		'A_BMH_ALNotified', --Patient and Family Notified
		'A_BMH_ARNotDisc', --Patient and Family Notified
		'A_BMH_GHNotDisc', --Patient and Family Notified
		'A_BMH_HCNotified', --Patient and Family Notified of Discharge
		'A_BMH_LTNotDisc', --Patient And Family Notified
		'A_BMH_NotifofDis', --Patient and Family Notified
		'A_BMH_PatFamNoti' --Patient and Family Notified
	)

	ORDER BY pvisit.VisitStartDateTime
	;

	-------------------------------------------------------------------
	-- Put results into an aggregate form in order enter into the aggreate table
	-------------------------------------------------------------------
	CREATE TABLE smsdss.c_CM_Daily_DschDisp_Aggregate_tbl (
		PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
		, Patient_FirstName VARCHAR(100)
		, Patient_LastName VARCHAR(100)
		, MRN CHAR(6)
		, PtNo_Num CHAR(8)
		, Adm_DTime DATETIME
		, Dsch_DTime DATETIME
		, Max_Form_Collection_DTime DATETIME
		, Form_Collected_by VARCHAR(100)
		, Anticipated_Discharge_Flag INT
		, List_Provided_Flag INT
		, PT_and_Fam_Notified_Flag INT
		, Post_Hosp_Plan_Rvwd INT
		, GroupHome_Flag INT
	);
	-- Get all results into a temp table then write from temp to constant table
	SELECT Patient_FirstName
	, Patient_LastName
	, MRN
	, PtNo_Num
	, Adm_DTime
	, Dsch_DTime
	, Max_Form_Collection_DTime
	, Form_Collected_by
	, SUM(Anticipated_Discharge_Flag) AS [Anticipaged_Discharge_Flag]
	, SUM(List_Provided_Flag) AS [List_Provided_Flag]
	, SUM(PT_and_Fam_Notified_Flag) AS [PT_and_Fam_Notified_Flag]
	, SUM(Post_Hosp_Plan_Rvwd_Flag) AS [Post_Hosp_Plan_Rvwd]
	, SUM(grouphome_flag) AS [GroupHome_Flag]

	INTO #TEMPA

	FROM smsdss.c_cm_daily_dschdisp_records_tbl

	GROUP BY Patient_FirstName
	, Patient_LastName
	, MRN
	, PtNo_Num
	, Adm_DTime
	, Dsch_DTime
	, Max_Form_Collection_DTime
	, Form_Collected_by
	;

	INSERT INTO smsdss.c_CM_Daily_DschDisp_Aggregate_tbl

	SELECT A.Patient_FirstName
	, A.Patient_FirstName
	, A.MRN
	, A.PtNo_Num
	, A.Adm_DTime
	, A.Dsch_DTime
	, Max_Form_Collection_DTime
	, A.Form_Collected_by 
	, CASE
		WHEN Anticipaged_Discharge_Flag != 0
			THEN 1
			ELSE 0
	  END AS Anticipated_Discharge_Flag
	, CASE
		WHEN List_Provided_Flag != 0
			THEN 1
			ELSE 0
	  END AS List_Provided_Flag
	, CASE
		WHEN PT_and_Fam_Notified_Flag != 0
			THEN 1
			ELSE 0
	  END AS PT_and_Fam_Notified_Flag
	, CASE
		WHEN Post_Hosp_Plan_Rvwd != 0
			THEN 1
			ELSE 0
	  END AS Post_Hosp_Plan_Rvwd
	, CASE
		WHEN GroupHome_Flag != 0
			THEN 1
			ELSE 0
	  END AS GroupHome_Flag

	FROM #TEMPA AS A
	;

	DROP TABLE #TEMPA
	;

	-------------------------------------------------------------------
	-- Add in the final report table 
	-------------------------------------------------------------------
	CREATE TABLE smsdss.c_CM_Daily_DschDisp_RptRecords_tbl (
		PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
		, MRN CHAR(6)
		, PtNo_Num CHAR(8)
		, Dsch_Unit VARCHAR(5)
		, Form_Collected_By VARCHAR(250)
		, Anticipated_Discharge_Flag CHAR(1)
		, List_Provided_Flag CHAR(1)
		, PT_and_Fam_Notified_Flag CHAR(1)
		, GroupHome_Flag CHAR(1)
		, Form_Done CHAR(1)
	)
	;

	SELECT MRN
	, PTNO_NUM
	, FORM_COLLECTED_BY
	, CASE
		WHEN LEFT(PtNo_Num, 1) = '8'
			THEN 'ED'
			ELSE B.ward_cd 
	  END AS [Dsch_Unit]
	, Anticipated_Discharge_Flag
	, List_Provided_Flag
	, PT_and_Fam_Notified_Flag
	, GroupHome_Flag
	, CASE
		WHEN GROUPHOME_FLAG = '0'
		AND (
			LIST_PROVIDED_FLAG != '0'
			AND PT_and_Fam_Notified_Flag != '0'
		)
			THEN 1
		WHEN GroupHome_Flag = '1'
			THEN 1
			ELSE 0
	  END AS [FORM_DONE]

	INTO #TEMPB

	FROM smsdss.C_CM_DAILY_DSCHDISP_AGGREGATE_TBL AS A
	LEFT OUTER JOIN smsmir.vst_rpt AS B
	ON RTRIM(LTRIM(A.PTNO_NUM)) = RTRIM(LTRIM(SUBSTRING(B.pt_id, 5, 8)))
	;

	INSERT INTO smsdss.c_CM_Daily_DschDisp_RptRecords_tbl

	SELECT A.MRN
	, A.PtNo_Num
	, A.Dsch_Unit
	, A.Form_Collected_by
	, A.Anticipated_Discharge_Flag
	, A.List_Provided_Flag
	, A.PT_and_Fam_Notified_Flag
	, A.GroupHome_Flag
	, A.FORM_DONE

	FROM #TEMPB AS A
	-- All records are kept, form done and form not done, the final query report
	-- will only show those patients whose form was not done
	;

	DROP TABLE #TEMPB;
END
---------------------------------------------------------------------------------------------------
ELSE BEGIN
	-- If the table already exists then there is no need to load it from epoch
	-- Run procedure for the day and make sure no records are duplicated
	DECLARE @STARTB DATETIME;
	DECLARE @ENDB   DATETIME;
	DECLARE @ThisDateB DATETIME;
	
	SET @ThisDateB = GETDATE(); -- Today
	SET @STARTB = dateadd(wk, datediff(wk, 7, @ThisDateB), -1); -- Last Sunday
	SET @ENDB = DATEADD(WK, DATEDIFF(WK, 0, @ThisDateB), -1);   -- This past Sunday

	-- Insert new records into smsdss.c_CM_Daily_DschDisp_Records_tbl
	INSERT INTO smsdss.c_CM_Daily_DschDisp_Records_tbl

	SELECT patient.FirstName AS [Patient_FirstName]
	, patient.LastName AS [Patient_LastName]
	, PLM.Med_Rec_No AS [MRN]
	, pvisit.PatientAccountID AS [PtNo_Num]
	, pvisit.VisitStartDateTime AS [Admit_DTime]
	, pvisit.VisitEndDateTime AS [Disch_DTime]
	--, observation.CreationTime AS [Form_Creation_DTime]
	, assessment.CollectedDT
	, DATEDIFF(DAY
		, pvisit.VisitStartDateTime
		, assessment.CollectedDT
	) AS [Hours_Till_Collection]
	, assessment.UserAbbrName AS [Collected_By]
	, AssessmentStatus AS [Form_Status]
	--, assessMaxID.MaxAssessmentID AS [Assessment_ID]
	, observation.FindingAbbr
	, observation.FindingName
	, observation.[Value]
	, observation.LastCngDtime AS [Observation_Last_Changed_DTime]
	, assessment.LastCngDtime AS [Assessment_Last_Changed_DTime]
	, [RunDate] = CAST(GETDATE() AS date)
	, [RunDTime] = GETDATE()
	, [RN] = ROW_NUMBER() OVER(
		PARTITION BY pvisit.PatientAccountID 
		ORDER BY pvisit.PatientAccountID
	)
	-- ANTICIPATED DISCHARGE DONE -----------------------------------------
	, CASE
		WHEN observation.FindingAbbr = 'A_BMH_AntDCPlan'
			THEN 1
			ELSE 0
		END AS [Anticipated_Discharge_Flag]
	-- LIST PROVIDED DATE ENTERED -----------------------------------------
	, CASE
		WHEN observation.FindingAbbr IN (
			'A_BMH_LT NurHom', --Long Term Nursing Home Facility List Provided On
			'A_BMH_ARListProv', --Acute Rehab Facility List Provide On
			'A_BMH_ALRettoFac', --Assisted Living Facility List Provided On
			'A_BMH_HomCareLis', --Home Care Agency List Provided On
			'A_BMH_FaclityLis', --Facility List Provided On
			'A_BMH_AHRettoFac', --Adult Home List Provided On
			'A_BMH_NurHomList' --Subacute Facility List Provided On

		)
			THEN 1
			ELSE 0
		END AS [List_Provided_Flag]
	-- PATIENT AND FAMILY NOTIFIED ----------------------------------------
	, CASE
		WHEN observation.FindingAbbr IN (
			'A_BMH_AHNotDisc', --Patient and Family Notified
			'A_BMH_ALNotified', --Patient and Family Notified
			'A_BMH_ARNotDisc', --Patient and Family Notified
			'A_BMH_HCNotified', --Patient and Family Notified of Discharge
			'A_BMH_LTNotDisc', --Patient And Family Notified
			'A_BMH_NotifofDis', --Patient and Family Notified
			'A_BMH_PatFamNoti' --Patient and Family Notified

		)
			THEN 1
			ELSE 0
		END AS [PT_and_Fam_Notified_Flag]
	, CASE
		WHEN observation.FindingAbbr = 'A_BMH_PostHosPla'
			AND observation.Value IS NOT NULL
				THEN 1
				ELSE 0
	  END AS [Post_Hosp_Plan_Rvwd_Flag]
	, CASE
		WHEN observation.FindingAbbr = 'A_BMH_GHNotDisc'
			THEN 1
			ELSE 0
	  END AS [GroupHome_Flag]

	FROM smsmir.sc_Patient AS patient
	INNER JOIN smsmir.sc_PatientVisit AS pvisit
	ON patient.RecordId = pvisit.RecordId
		AND patient.ObjectID = pvisit.Patient_oid
	LEFT OUTER JOIN smsmir.sc_Assessment AS assessment
	ON pvisit.Patient_oid = assessment.Patient_oid
		AND pvisit.StartingVisitOID = assessment.PatientVisit_oid
	-- get max assessment id ----------------------------------------------
	INNER JOIN (
		SELECT Patient_oid
		, PatientVisit_oid
		, MAX(AssessmentID) AS MaxAssessmentID
		FROM smsmir.sc_Assessment
		WHERE FormUsage = 'BMH_CMDaily Discharge Disp'
		GROUP BY Patient_oid
		, PatientVisit_oid
	) AS assessMaxID
	ON assessment.Patient_oid = assessMaxID.Patient_oid
		AND assessment.PatientVisit_oid = assessMaxID.PatientVisit_oid
		AND assessment.AssessmentID = assessMaxID.MaxAssessmentID
	-----------------------------------------------------------------------
	LEFT OUTER JOIN smsmir.sc_Observation AS observation
	ON assessment.Patient_oid = observation.Patient_oid
		AND assessment.AssessmentID = observation.AssessmentID
		AND assessment.ObjectID = observation.Assessment_oid
		--AND assessment.LastCngDtime = observation.LastCngDtime
	LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS PLM
	ON pvisit.PatientAccountID = PLM.PtNo_Num

	--WHERE pvisit.PatientAccountID IN (
	--	'',
	--	'',
	--	'',
	--	''
	--)
	WHERE assessment.FormUsage = 'BMH_CMDaily Discharge Disp'
	AND pvisit.VisitEndDateTime >= @STARTB
	AND pvisit.VisitEndDateTime < @ENDB
	AND observation.FindingAbbr IN (
		'A_BMH_AntDCPlan','A_BMH_PostHosPla',
		-- LIST PROVIDED --
		'A_BMH_LT NurHom', --Long Term Nursing Home Facility List Provided On
		'A_BMH_ARListProv', --Acute Rehab Facility List Provide On
		'A_BMH_ALRettoFac', --Assisted Living Facility List Provided On
		'A_BMH_HomCareLis', --Home Care Agency List Provided On
		'A_BMH_FaclityLis', --Facility List Provided On
		'A_BMH_AHRettoFac', --Adult Home List Provided On
		'A_BMH_NurHomList', --Subacute Facility List Provided On
		-- FAMILY NOTIFIED --
		'A_BMH_AHNotDisc', --Patient and Family Notified
		'A_BMH_ALNotified', --Patient and Family Notified
		'A_BMH_ARNotDisc', --Patient and Family Notified
		'A_BMH_GHNotDisc', --Patient and Family Notified
		'A_BMH_HCNotified', --Patient and Family Notified of Discharge
		'A_BMH_LTNotDisc', --Patient And Family Notified
		'A_BMH_NotifofDis', --Patient and Family Notified
		'A_BMH_PatFamNoti' --Patient and Family Notified
	)
	AND pvisit.PatientAccountID NOT IN (
		SELECT PtNo_Num
		FROM smsdss.c_CM_Daily_DschDisp_Records_tbl
	)

	ORDER BY pvisit.VisitStartDateTime
	;

	-- Insert into the smsdss.c_CM_Daily_DschDisp_Aggregate_tbl
	-- Get all results into a temp table then write from temp to constant table
	SELECT Patient_FirstName
	, Patient_LastName
	, MRN
	, PtNo_Num
	, Adm_DTime
	, Dsch_DTime
	, Max_Form_Collection_DTime
	, Form_Collected_by
	, SUM(Anticipated_Discharge_Flag) AS [Anticipaged_Discharge_Flag]
	, SUM(List_Provided_Flag) AS [List_Provided_Flag]
	, SUM(PT_and_Fam_Notified_Flag) AS [PT_and_Fam_Notified_Flag]
	, SUM(Post_Hosp_Plan_Rvwd_Flag) AS [Post_Hosp_Plan_Rvwd]
	, SUM(grouphome_flag) AS [GroupHome_Flag]

	INTO #TEMPC

	FROM smsdss.c_cm_daily_dschdisp_records_tbl

	GROUP BY Patient_FirstName
	, Patient_LastName
	, MRN
	, PtNo_Num
	, Adm_DTime
	, Dsch_DTime
	, Max_Form_Collection_DTime
	, Form_Collected_by
	;

	INSERT INTO smsdss.c_CM_Daily_DschDisp_Aggregate_tbl

	SELECT A.Patient_FirstName
	, A.Patient_FirstName
	, A.MRN
	, A.PtNo_Num
	, A.Adm_DTime
	, A.Dsch_DTime
	, Max_Form_Collection_DTime
	, A.Form_Collected_by 
	, CASE
		WHEN Anticipaged_Discharge_Flag != 0
			THEN 1
			ELSE 0
	  END AS Anticipated_Discharge_Flag
	, CASE
		WHEN List_Provided_Flag != 0
			THEN 1
			ELSE 0
	  END AS List_Provided_Flag
	, CASE
		WHEN PT_and_Fam_Notified_Flag != 0
			THEN 1
			ELSE 0
	  END AS PT_and_Fam_Notified_Flag
	, CASE
		WHEN Post_Hosp_Plan_Rvwd != 0
			THEN 1
			ELSE 0
	  END AS Post_Hosp_Plan_Rvwd
	, CASE
		WHEN GroupHome_Flag != 0
			THEN 1
			ELSE 0
	  END AS GroupHome_Flag

	FROM #TEMPC AS A

	WHERE A.PtNo_Num NOT IN (
		SELECT PtNo_Num
		FROM smsdss.c_CM_Daily_DschDisp_Aggregate_tbl
	)
	;

	DROP TABLE #TEMPC
	;

	-------------------------------------------------------------------
	-- Add in the final report table 
	-------------------------------------------------------------------
	SELECT MRN
	, PTNO_NUM
	, FORM_COLLECTED_BY
	, CASE
		WHEN LEFT(PtNo_Num, 1) = '8'
			THEN 'ED'
			ELSE B.ward_cd 
	  END AS [Dsch_Unit]
	, Anticipated_Discharge_Flag
	, List_Provided_Flag
	, PT_and_Fam_Notified_Flag
	, GroupHome_Flag
	, CASE
		WHEN GROUPHOME_FLAG = '0'
		AND (
			LIST_PROVIDED_FLAG != '0'
			AND PT_and_Fam_Notified_Flag != '0'
		)
			THEN 1
		WHEN GroupHome_Flag = '1'
			THEN 1
			ELSE 0
	  END AS [FORM_DONE]

	INTO #TEMPD

	FROM smsdss.C_CM_DAILY_DSCHDISP_AGGREGATE_TBL AS A
	LEFT OUTER JOIN smsmir.vst_rpt AS B
	ON RTRIM(LTRIM(A.PTNO_NUM)) = RTRIM(LTRIM(SUBSTRING(B.pt_id, 5, 8)))
	;

	INSERT INTO smsdss.c_CM_Daily_DschDisp_RptRecords_tbl

	SELECT A.MRN
	, A.PtNo_Num
	, A.Dsch_Unit
	, A.Form_Collected_by
	, A.Anticipated_Discharge_Flag
	, A.List_Provided_Flag
	, A.PT_and_Fam_Notified_Flag
	, A.GroupHome_Flag
	, A.FORM_DONE

	FROM #TEMPD AS A
	-- All records are kept, form done and form not done, the final query report
	-- will only show those patients whose form was not done
	WHERE A.PtNo_Num NOT IN (
		SELECT PtNo_Num
		FROM smsdss.c_CM_Daily_DschDisp_RptRecords_tbl
	)
	;

	DROP TABLE #TEMPD;

END
;
