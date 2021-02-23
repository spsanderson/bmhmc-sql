USE [Soarian_Clin_Tst_1]
GO
/****** Object:  StoredProcedure [dbo].[ORE_BHMC_SBAR_Q_Shift_Report_New_SPS]    Script Date: 1/27/2021 9:15:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*--------------------------------------------------------------------------------    
    
File:      ORE_BHMC_SBAR_Q_Shift_Report_New_SPS.sql    
    
Input  Parameters:      
       @HSF_CONTEXT_PATIENTID as PatientOID used to select specific patient     
       @VisitOID             as Visit OID Of patient displayed in UI    
       @pvchLocation         as Patient Location               
       @pchReportUsage          as Used to indicate how the report is being run    
                                1 = Context Senstive (CSP) Patient Context    
                                2 = Operational Reporting (OPR)    
                                3 = Job Scheduler (JS)    
  
Tables:     
   HOrder  
   HOrderSuppInfo    
   HAssessment      
   HObservation    
   HPatient    
   HPatientVisit    
   HPerson   
   HHealthCareUnit   
   HExtendedPatient  
  
    
Functions:     
   fn_ORE_GetPatientAge    
   fn_ORE_GetPatientAllergies    
   fn_GetStrParmTable    
   fn_ORE_GetPatientWt    
   fn_ORE_GetExternalPatientID   
   fn_ORE_GetPhysicianName   

Purpose:  This procedure will retrieve fields needed to print the patient    
          header and detail for the Shift report.     
     
    
Revision History:    
---------------------------------------------------------------------------------    
Date    	Revised By   			Description
2019-09-04	Steven Sanderson MPH	Add the following fields
2019-12-06	Steven Sanderson MPH	Change OrderName to OrderDescAsWritten for Last
									Orders
2020-08-17	Steven Sanderson MPH	Add Bed Rest Orders
2020-11-20  Steven Sanderson MPH	Add MEWSScore
2021-01-27	Steven Sanderson MPH	Pivot out at most 4 Last Activity Orders
------------------------------------------------------------------------------- 
*/  
    
--EXEC dbo.ORE_BHMC_SBAR_Q_Shift_Report_New_SPS '2180269','180034','3SOU','1' --test patient
    
ALTER PROCEDURE [dbo].[ORE_BHMC_SBAR_Q_Shift_Report_New_SPS] @HSF_CONTEXT_PATIENTID VARCHAR(20) = NULL,
	@VisitOID VARCHAR(20) = NULL,
	@pvchLocation AS TEXT,
	@pchReportUsage AS CHAR(1)
AS
BEGIN
	DECLARE @iPatientOID INT,
		@iVisitOID INT,
		@vchLocation VARCHAR(20)
	DECLARE @tblPatientOID TABLE (
		PatientOID INT,
		VisitOID INT
		)
	--Table to hold parsed Location Names    
	DECLARE @tblLocation TABLE (Location VARCHAR(75))
	DECLARE @Patient TABLE (
		PatientName VARCHAR(184),
		RoomBed VARCHAR(75),
		Age VARCHAR(20),
		VisitStartDateTime DATETIME,
		BirthDate DATETIME,
		Sex VARCHAR(6),
		MRNumber VARCHAR(20),
		PatientAcctNum VARCHAR(20),
		AdmittingDr VARCHAR(184),
		AttendDr VARCHAR(184),
		ConsultingDr VARCHAR(4000),
		Allergies TEXT,
		Weight VARCHAR(40),
		ChiefComplaint VARCHAR(255),
		DNR VARCHAR(64),
		HealthcareProxy VARCHAR(255),
		HealthcareProxyName VARCHAR(255),
		LivingWill VARCHAR(255),
		DNI VARCHAR(255),
		IsolationIndicator VARCHAR(64),
		PatientLocationName VARCHAR(75),
		UnitContactedName VARCHAR(75),
		PatientOID INTEGER,
		PatientVisitOID INTEGER
		)
	DECLARE @AssessmentObsValues TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		FormUsageDisplayName VARCHAR(100),
		CollectedDateTime SMALLDATETIME,
		Assessmentid INT,
		FindingAbbr VARCHAR(16),
		FindingValue VARCHAR(2000),
		SlNo INT
		)
	DECLARE @DietModifier TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		DietModifier VARCHAR(1000),
		SlNo INT
		)
	DECLARE @DietaryOrders TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		slNO INT,
		OrderDescAsWritten VARCHAR(MAX),
		EnterdDateTime VARCHAR(50)
	)
	DECLARE @LastDietaryOrder TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		LastDietaryOrder VARCHAR(MAX),
		LastDietaryOrderEnteredDateTime VARCHAR(50)
	)
	DECLARE @TelemetryOrders TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		slNO INT,
		OrderDescAsWritten VARCHAR(MAX),
		EnterdDateTime VARCHAR(50)
	)
	DECLARE @LastTelemetryOrder TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		LastTelemetryOrder VARCHAR(MAX),
		LastTeleOrderEnteredDateTime VARCHAR(50)
	)
	DECLARE @PhysicalTherapyOrders TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		slNO INT,
		OrderDescAsWritten VARCHAR(MAX),
		EnterdDateTime VARCHAR(50)
	)
	DECLARE @LastPhysicalTherapyOrder TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		LastPTOrder VARCHAR(MAX),
		LastPTOrderEnteredDateTime VARCHAR(50)
	)
	DECLARE @ActivityOrders TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		slNO INT,
		OrderDescAsWritten VARCHAR(MAX),
		EnterdDateTime VARCHAR(50)
	)
	DECLARE @LastActivityOrder TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		LastActivityOrder VARCHAR(MAX),
		LastActivityOrderEnteredDateTime VARCHAR(50),
		OrderNumber INT
	)
	DECLARE @BedrestOrders TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		slNO INT,
		OrderDescAsWritten VARCHAR(MAX),
		EnterdDateTime VARCHAR(50)
	)
	DECLARE @LastBedrestOrder TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		LastBedrestOrder VARCHAR(MAX),
		LastBedrestOrderEnteredDateTime VARCHAR(50)
	)
	DECLARE @GlucoseOrders TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		slNO INT,
		OrderDescAsWritten VARCHAR(MAX),
		EnterdDateTime VARCHAR(50)
	)
	DECLARE @LastGlucoseOrder TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		LastGlucoseOrder VARCHAR(MAX),
		LastGlucoseOrderEnteredDateTime VARCHAR(50)
	)
	--neuro
	DECLARE @NeuroChecksOrders TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		slNO INT,
		OrderDescAsWritten VARCHAR(MAX),
		EnterdDateTime VARCHAR(50)
	)
	DECLARE @LastNeuroCheckOrder TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		LastNeuroOrder VARCHAR(MAX),
		LastNeuroOrderEnteredDateTime VARCHAR(50)
	)
	-- IV Order
	DECLARE @IVOrders TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		slNO INT,
		OrderDescAsWritten VARCHAR(MAX),
		EnterdDateTime VARCHAR(50)
	)
	DECLARE @LastIVOrder TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		LastIVOrder VARCHAR(MAX),
		LastIVOrderEnteredDateTime VARCHAR(50)
	)
	-- LAST GLUCOSE
	DECLARE @GlucoseResults TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		slNO INT,
		GlucoseValue VARCHAR(MAX),
		CreationDateTime VARCHAR(50)
	)
	DECLARE @LastGlucoseResult TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		LastGlucoseResult VARCHAR(MAX),
		LastGlucoseResultCreationDateTime VARCHAR(50)
	)
	DECLARE @AssessmentStatus TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		FormUsageDisplayName VARCHAR(100),
		Assessmentid INT,
		AssessmentStatus VARCHAR(16),
		CollectedDT VARCHAR(50)
		)
	DECLARE @pivotAssessmentStatus TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		IsAdmissionAssmentCharted VARCHAR(10),
		AdmissionAssmtStatus VARCHAR(100),
		IsAdmissionAssmtComplete VARCHAR(10),
		IsIPHomeMedListAssmentCharted VARCHAR(10),
		IPHomeMedListAssmtStatus VARCHAR(100),
		IsIPHomeMedListAssmtComplete VARCHAR(10),
		-- vitals
		IsVitalsAssmtCharted VARCHAR(10),
		VitalsAssmtStatus VARCHAR(100),
		ISVitalsAssmtComplete VARCHAR(10),
		VitalsAssmtCollectedDT VARCHAR(50)
		)
	DECLARE @pivotObsValues TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		LIHNType VARCHAR(2000),
		PatientOnIsolation VARCHAR(2000),
		Observation VARCHAR(2000),
		FallRiskScore VARCHAR(2000),
		FallPrecautions VARCHAR(2000),
		BedAlarmOn VARCHAR(2000),
		Restraints VARCHAR(2000),
		O2Sat VARCHAR(2000),
		Telemetry VARCHAR(2000),
		Pain VARCHAR(2000),
		PainLocation VARCHAR(2000),
		AccuCheck VARCHAR(2000),
		SkinIntegrity VARCHAR(2000),
		WoundType VARCHAR(2000),
		Foley VARCHAR(2000),
		insertionDate DATETIME,
		CardioPulmonary VARCHAR(2000),
		NeuroOrientedTo VARCHAR(2000),
		RestraintType VARCHAR(2000),
		AdmittedFrom VARCHAR(2000),
		AccPainLevel VARCHAR(2000),
		Temperature VARCHAR(2000),
		Pulse VARCHAR(2000),
		BP VARCHAR(2000),
		Respiration VARCHAR(2000),
		IVSite1 VARCHAR(2000),
		IVInsertDt1 DATETIME,
		IVDressChDt1 DATETIME,
		IVtubeChDt1 DATETIME,
		IVSite2 VARCHAR(2000),
		IVInsertDt2 DATETIME,
		IVDressChDt2 DATETIME,
		IVtubeChDt2 DATETIME,
		IVSite3 VARCHAR(2000),
		IVInsertDt3 DATETIME,
		IVDressChDt3 DATETIME,
		IVtubeChDt3 DATETIME,
		IVSite4 VARCHAR(2000),
		IVInsertDt4 DATETIME,
		IVDressChDt4 DATETIME,
		IVtubeChDt4 DATETIME,
		Oxygen VARCHAR(2000),
		O2Per VARCHAR(2000),
		O2LPM VARCHAR(2000),
		NIHScaleScore VARCHAR(2000),
		NIHScaleScoreCollectedDt DATETIME,
		TrachTube VARCHAR(2000),
		TubeDrain VARCHAR(2000),
		ATD1Location VARCHAR(2000),
		TubeDrain2 VARCHAR(2000),
		ATD2Location VARCHAR(2000),
		IVType1 VARCHAR(2000),
		IVType2 VARCHAR(2000),
		IVType3 VARCHAR(2000),
		IVType4 VARCHAR(2000),
		TobaccoUse VARCHAR(2000),
		WDL VARCHAR(2000), -- A_BMH_WDL  
		MorseFallRisk VARCHAR(2000),
		Pneumovax VARCHAR(2000),
		PneuImmunizationDt VARCHAR(50),
		Influenza VARCHAR(2000),
		InfluImmunizationDt VARCHAR(50),
		CardiacRhythm VARCHAR(2000),
		RhythmDesc VARCHAR(2000),
		SkinColor VARCHAR(2000),
		SkinTemp VARCHAR(2000),
		SkinMoisture VARCHAR(2000),
		CapillaryRefill VARCHAR(2000),
		CVEdemaNoted VARCHAR(2000),
		AbnormalPulses VARCHAR(2000),
		RecentFalls VARCHAR(2000),
		VentType VARCHAR(2000),
		VentTube VARCHAR(2000),
		ChestTube1Loc VARCHAR(2000),
		ChestTube2Loc VARCHAR(2000),
		ChestTube3Loc VARCHAR(2000),
		PtMedComp VARCHAR(2000),
		PtMedCompCmt VARCHAR(2000),
		PtAttGrps VARCHAR(2000),
		PtAttGrpsCmt VARCHAR(2000),
		TapBell VARCHAR(2000),
		Affect VARCHAR(2000),
		Behavior VARCHAR(2000),
		Cognitive VARCHAR(2000),
		HrsSlept VARCHAR(2000),
		SleepProb VARCHAR(2000),
		BhvrObsLvl VARCHAR(2000),
		BhvrCmt VARCHAR(2000),
		SpirRcrs VARCHAR(2000),
		FamInvolve VARCHAR(2000),
		SpirConcerns VARCHAR(2000),
		SpirConcernsDesc VARCHAR(2000),
		SpirConcernsCmt VARCHAR(2000),
		LastBMDate DATETIME,
		BreakfastAmt VARCHAR(2000),
		LunchAmt VARCHAR(2000),
		DinnerAmt VARCHAR(2000),
		PatientBelongings VARCHAR(2000),
		Clothing VARCHAR(2000),
		CreditCard VARCHAR(2000),
		WalletHandbag VARCHAR(2000),
		Jewelry VARCHAR(2000),
		Glasses VARCHAR(2000),
		Contacts VARCHAR(2000),
		Dentures VARCHAR(2000),
		HearingAid VARCHAR(2000),
		Crutches VARCHAR(2000),
		ArtificialEye VARCHAR(2000),
		ArtificialArm VARCHAR(2000),
		ArtificialLeg VARCHAR(2000),
		WheelChair VARCHAR(2000),
		CaneWalker VARCHAR(2000),
		Brace VARCHAR(2000),
		OtherHomeItems VARCHAR(2000),
		ClothingCmt VARCHAR(2000),
		CreditCardCmt VARCHAR(2000),
		WalletHandbagCmt VARCHAR(2000),
		JewelryCmt VARCHAR(2000),
		GlassesCmt VARCHAR(2000),
		ContactsCmt VARCHAR(2000),
		DenturesCmt VARCHAR(2000),
		HearingAidCmt VARCHAR(2000),
		CrutchesCmt VARCHAR(2000),
		ArtificialEyeCmt VARCHAR(2000),
		ArtificialArmCmt VARCHAR(2000),
		ArtificialLegCmt VARCHAR(2000),
		WheelChairCmt VARCHAR(2000),
		CaneWalkerCmt VARCHAR(2000),
		BraceCmt VARCHAR(2000),
		OtherHomeItemsCmt VARCHAR(2000),
		BelongingsCmt VARCHAR(2000),
		DNR VARCHAR(64),
		IV1DCDt DATETIME,
		IV2DCDt DATETIME,
		IV3DCDt DATETIME,
		IV4DCDt DATETIME,
		ListCoMorb VARCHAR(2000),
		PresSoreSite1 VARCHAR(2000),
		PresSoreSite1Other VARCHAR(2000),
		PresSoreSite1Laterality VARCHAR(2000),
		PresSoreSite1Type VARCHAR(2000),
		PresSoreSite1POA VARCHAR(2000),
		PresSoreSite1TypeOther VARCHAR(2000),
		PresSoreSite1DressingCondition VARCHAR(2000),
		PresSoreSite1DressConOther VARCHAR(2000),
		PresSoreSite2 VARCHAR(2000),
		PresSoreSite2Other VARCHAR(2000),
		PresSoreSite2Laterality VARCHAR(2000),
		PresSoreSite2Type VARCHAR(2000),
		PresSoreSite2POA VARCHAR(2000),
		PresSoreSite2TypeOther VARCHAR(2000),
		PresSoreSite2DressingCondition VARCHAR(2000),
		PresSoreSite2DressConOther VARCHAR(2000),
		PresSoreSite3 VARCHAR(2000),
		PresSoreSite3Other VARCHAR(2000),
		PresSoreSite3Laterality VARCHAR(2000),
		PresSoreSite3Type VARCHAR(2000),
		PresSoreSite3POA VARCHAR(2000),
		PresSoreSite3TypeOther VARCHAR(2000),
		PresSoreSite3DressingCondition VARCHAR(2000),
		PresSoreSite3DressConOther VARCHAR(2000),
		PresSoreSite4 VARCHAR(2000),
		PresSoreSite4Other VARCHAR(2000),
		PresSoreSite4Laterality VARCHAR(2000),
		PresSoreSite4Type VARCHAR(2000),
		PresSoreSite4POA VARCHAR(2000),
		PresSoreSite4TypeOther VARCHAR(2000),
		PresSoreSite4DressingCondition VARCHAR(2000),
		PresSoreSite4DressConOther VARCHAR(2000),
		PresSoreSite5 VARCHAR(2000),
		PresSoreSite5Other VARCHAR(2000),
		PresSoreSite5Laterality VARCHAR(2000),
		PresSoreSite5Type VARCHAR(2000),
		PresSoreSite5POA VARCHAR(2000),
		PresSoreSite5TypeOther VARCHAR(2000),
		PresSoreSite5DressingCondition VARCHAR(2000),
		PresSoreSite5DressConOther VARCHAR(2000),
		PresSoreSite6 VARCHAR(2000),
		PresSoreSite6Other VARCHAR(2000),
		PresSoreSite6Laterality VARCHAR(2000),
		PresSoreSite6Type VARCHAR(2000),
		PresSoreSite6POA VARCHAR(2000),
		PresSoreSite6TypeOther VARCHAR(2000),
		PresSoreSite6DressingCondition VARCHAR(2000),
		PresSoreSite6DressConOther VARCHAR(2000),
		PresSoreSite7 VARCHAR(2000),
		PresSoreSite7Other VARCHAR(2000),
		PresSoreSite7Laterality VARCHAR(2000),
		PresSoreSite7Type VARCHAR(2000),
		PresSoreSite7POA VARCHAR(2000),
		PresSoreSite7TypeOther VARCHAR(2000),
		PresSoreSite7DressingCondition VARCHAR(2000),
		PresSoreSite7DressConOther VARCHAR(2000),
		PresSoreSite8 VARCHAR(2000),
		PresSoreSite8Other VARCHAR(2000),
		PresSoreSite8Laterality VARCHAR(2000),
		PresSoreSite8Type VARCHAR(2000),
		PresSoreSite8POA VARCHAR(2000),
		PresSoreSite8TypeOther VARCHAR(2000),
		PresSoreSite8DressingCondition VARCHAR(2000),
		PresSoreSite8DressConOther VARCHAR(2000),
		WeightObtainedDT DATETIME,
		MEWSScore VARCHAR(2000)
		)

	IF isnumeric(@HSF_CONTEXT_PATIENTID) = 1
		SET @iPatientOID = cast(@HSF_CONTEXT_PATIENTID AS INT)
	ELSE
		SET @iPatientOID = - 1

	IF isnumeric(@VisitOID) = 1
		SET @iVisitOID = cast(@VisitOID AS INT)
	ELSE
		SET @iVisitOID = - 1

	IF (@pvchLocation IS NOT NULL)
		AND (@pvchLocation NOT LIKE '%All,%')
		AND (@pvchLocation NOT LIKE 'All')
		INSERT INTO @tblLocation (Location)
		SELECT *
		FROM fn_GetStrParmTable(@pvchLocation)
	ELSE
		SET @vchLocation = 'All'

	--  INSERT INTO @tblLocation  
	--    (  
	--      Location  
	--     )  
	--   SELECT t1.HealthcareUnitName  
	--       FROM HHealthCareUnit t1 with (nolock)  
	--      WHERE ( t1.Active = 1  
	--            AND t1.OrganizationType = 2 )  
	IF @pchReportUsage = '1' -- Report is being printed from CSP -- Single Patient  
	BEGIN
		INSERT INTO @tblPatientOID
		SELECT Patient_OID = @iPatientOID,
			VisitOID = @iVisitOID
	END
	ELSE
	BEGIN -- Want all patients for a Location  
		INSERT INTO @tblPatientOID
		SELECT PatientOID = pt.ObjectID,
			VisitOID = pv.ObjectID
		FROM HPatient pt WITH (NOLOCK)
		INNER JOIN HPatientVisit pv WITH (NOLOCK) ON pv.Patient_oid = pt.ObjectID
			AND pv.isdeleted = 0
		--    inner join @tblLocation a   
		--    on (a.Location = pv.PatientLocationName)  
		WHERE pt.isdeleted = 0
			AND pv.VisitStatus IN (0, 4)
			AND (
				EXISTS (
					SELECT Location
					FROM @tblLocation t1
					WHERE t1.location = pv.PatientLocationName
					)
				OR (@vchLocation = 'All')
				)
	END

	-- Select Patient info into the Patient table  
	INSERT INTO @Patient
	SELECT DISTINCT PatientName = CASE ISNULL(pt.GenerationQualifier, '')
			WHEN ''
				THEN pt.LastName + ', ' + pt.FirstName + ' ' + ISNULL(SUBSTRING(pt.MiddleName, 1, 1), ' ')
			ELSE pt.LastName + ' ' + pt.GenerationQualifier + ', ' + pt.FirstName + ' ' + ISNULL(SUBSTRING(pt.MiddleName, 1, 1), ' ')
			END,
		RoomBed = isnull(pv.LatestBedName, ''),
		Age = (.dbo.fn_ORE_GetPatientAge(per.BirthDate, getdate())),
		VisitStartDateTime = pv.VisitStartDateTime,
		BirthDate = convert(VARCHAR(10), per.BirthDate, 101),
		Sex = cast(CASE per.Sex
				WHEN 0
					THEN 'M'
				WHEN 1
					THEN 'F'
				ELSE ' '
				END AS CHAR(6)),
		MRNumber = isnull(.dbo.fn_ORE_GetExternalPatientID(pt.ObjectID, pv.entity_oid), ''),
		PatientAcctNum = isnull(pv.PatientAccountID, ''),
		AdmittingDr = isnull(.dbo.fn_ORE_GetPhysicianName(pv.ObjectID, 4, 6), ''),
		AttendDr = isnull(.dbo.fn_ORE_GetPhysicianName(pv.ObjectID, 0, 6), ''),
		ConsultingDr = isnull(.dbo.fn_ORE_GetPhysicianName(pv.ObjectID, 3, 6), ''),
		Allergies = Substring(IsNull(dbo.Fn_ORE_GetPatientAllergies(pt.ObjectID), IsNull(.dbo.fn_ORE_VisitAllergiesCheck(pt.ObjectID, pv.ObjectID), '')), 1, 512),
		Weight = isnull(.dbo.fn_ORE_GetPatientWt(pt.ObjectID), ''),
		ChiefComplaint = isnull(pv.PatientReasonForSeekingHC, ''),
		DNR = isnull(pt.advancedDirectiveOnFile, ''),
		HealthcareProxy = isnull(hep.UserDefinedString3, ''),
		HealthcareProxyName = isnull(hep.UserDefinedString5, ''),
		LivingWill = isnull(hep.UserDefinedString4, ''),
		DNI = isnull(hep.UserDefinedString7, ''),
		IsolationIndicator = isnull(pv.IsolationIndicator, ''),
		PatientLocationName = isnull(pv.PatientLocationName, ''),
		UnitContactedName = IsNull(pv.UnitContactedName, ''),
		PatientOID = pt.ObjectID,
		PatientVisitOID = pv.ObjectID
	FROM @tblPatientOID tb1
	INNER JOIN HPatient pt WITH (NOLOCK) ON pt.ObjectID = tb1.PatientOID
	INNER JOIN HPatientVisit pv WITH (NOLOCK) ON tb1.VisitOID = pv.ObjectID
		AND tb1.PatientOID = pv.Patient_oid
		AND pv.isdeleted = 0
	INNER JOIN HPerson per WITH (NOLOCK) ON pt.ObjectID = per.ObjectID
		AND per.isdeleted = 0
	LEFT OUTER JOIN HExtendedPatient Hep WITH (NOLOCK) ON pt.patientextension_oid = hep.objectid
	WHERE pt.isdeleted = 0

	INSERT INTO @AssessmentObsValues
	SELECT PatientOID = ha.Patient_OID,
		PatientVisitOID = ha.PatientVisit_OID,
		FormUsageDisplayName = ha.FormUsageDisplayName,
		CollectedDateTime = ha.collecteddt,
		AssessmentID = ha.AssessmentID,
		FindingAbbr = ha.FindingAbbr,
		FindingValue = replace(isnull(ha.Value, ''), CHAR(30), ', '),
		SlNo = row_number() OVER (
			PARTITION BY ha.patientvisit_oid,
			ha.FindingAbbr ORDER BY ha.patientvisit_oid,
				ha.FindingAbbr,
				ha.collecteddt DESC,
				ha.AssessmentID DESC
			)
	FROM --vw_ore_assessmentObservation  -- 3.4 upgrade view changes
		(
		SELECT Patient_oid = HAssessment.Patient_oid,
			PatientVisit_oid = HAssessment.PatientVisit_oid,
			FormUsageDisplayName = IsNull(HAssessment.FormUsageDisplayName, ''),
			CollectedDt = HAssessment.CollectedDT,
			AssessmentID = HAssessment.AssessmentID,
			FindingAbbr = isnull(HObservation.FindingAbbr, HAssessmentFormElement.Name),
			Value = CASE 
				WHEN ISNULL(HObservation.Value, '') = ''
					THEN HObservation.InternalValue
				ELSE HObservation.Value
				END,
			ObservationEndDT = HObservation.EndDT,
			ObservationStatus = HObservation.ObservationStatus,
			AssessmentStatusCode = HAssessment.AssessmentStatusCode
		FROM HAssessment HAssessment WITH (NOLOCK)
		INNER JOIN HAssessmentCategory HAssessmentCategory WITH (NOLOCK) ON HAssessment.AssessmentID = HAssessmentCategory.assessmentID
			AND HAssessmentCategory.CategoryStatus NOT IN (0, 3)
			AND HAssessmentCategory.IsLatest = 1
		INNER JOIN HAssessmentFormElement HAssessmentFormElement WITH (NOLOCK) ON HAssessmentCategory.form_oid = HAssessmentFormElement.formid
			AND HAssessmentCategory.formversion = HAssessmentFormElement.formversion
		LEFT OUTER JOIN HObservation HObservation WITH (NOLOCK) ON HAssessmentCategory.assessmentid = HObservation.assessmentid
			AND HAssessment.patient_oid = HObservation.patient_oid
			AND HObservation.enddt IS NULL
			AND HObservation.ObservationStatus LIKE 'A%'
			AND HObservation.FindingAbbr = HAssessmentFormElement.Name
			AND HObservation.Finding_oid = HAssessmentFormElement.OID
		--- 3.4 upgrade view changes 
		WHERE HAssessment.EndDt IS NULL
		) ha --with (noLock)  
	INNER JOIN @tblPatientOID tp ON tp.patientOID = ha.patient_oid
		AND tp.VisitOID = ha.patientvisit_oid
	WHERE ha.ObservationEndDT IS NULL
		AND ha.ObservationStatus LIKE 'AV'
		AND ha.FindingAbbr IN (
			'A_Temperature', 'A_Pulse', 'A_BP', 'A_Respirations', 'A_Pulse Ox', 'A_BMH_Restraints', 'A_LIHN TYPE', 'A_BMH_Isolation?', 'A_BMH_ObsLevel', 'A_Fall Risk', 'A_BMH_FallPrec?', 'A_BMH_BedAlarm?', 'A_BMH_TobacUse', 'A_BMH_Telemetry', 'A_BMH_Pain Score', 'A_Pain1 Location', 'A_BMH_Accuchecks', 'A_BMH_SkinInteg', 'A_BMH_Wound Type', 'A_Urine Chars', 'A_BMH_CathInstDt', 'A_BMH_CP_Screen', 'A_Oriented To', 'A_IV1 Site', 'A_IV1 Insert Dt', 'A_IV1DressChDt', 'A_IV1 TubeChDt', 'A_IV1 Type', 'A_IV2 Site', 'A_IV2 Insert Dt', 'A_IV2DressChDt', 'A_IV2 TubeChDt', 'A_IV2 Type', 'A_IV3 Site', 'A_IV3 Insert Dt', 'A_IV3DressChDt', 'A_IV3 TubeChDt', 'A_IV3 Type', 'A_IV4 Site', 'A_IV4 Insert Dt', 'A_IV4DressChDt', 'A_IV4 TubeChDt', 'A_IV4 Type', 'A_RstrntType', 'A_Admit From', 'A_BMH_AccPnLevel', 'A_BMH_Oxygen?', 'A_O2 %', 'A_O2 LPM', 'A_BMH_TotalStkSc', 'A_BMH_Trach', 'A_Tube/Drain1', 'A_T/D1 Loc', 'A_Tube/Drain2', 'A_T/D2 Loc', 'A_BMH_WDL', 'A_MorseFallRisk', 'A_Pneumo Immun', 'A_Pneum Im Dt', 'A_InfluenzaImmun', 'A_InfluenzaImDt', 'A_Cardiac Rhythm', 
			'A_BMH_RhyDesc', 'A_Skin Color', 'A_Skin Temp', 'A_Skin Moisture', 'A_CapRefill>3sec', 'A_CV Edema', 'A_Abnormal Pulses', 'A_RecentFalls', 'A_Vent Type', 'A_Vent Tube', 'A_CT1 Location', 'A_CT2 Location', 'A_CT3 Location', 'A_BMH_PatMedCom', 'A_BMH_MedComm', 'A_BMH_PatAttGr', 'A_BMH_AttGrComm', 'A_BMH_TapBell?', 'A_Affect', 'A_Behavior', 'A_Cognitive', 'A_Hours Slept', 'A_Sleep Problems', 'A_BMH_ObsvnLevel', 'A_BMH_BhvrComent', 'A_Need Spir Rcrs', 'A_BMH_FamInvolve', 'A_Spir Concerns', 'A_Desc Spir Conc', 'A_P/S Cmnts', 'A_Last BM Date', 'A_Breakfast Amt', 'A_Lunch Amt', 'A_Dinner Amt', 'A_BMH_PtNoBelong', 'A_BMH_ClothDesc', 'A_BMH_CredCdDesc', 'A_BMH_WaletHanBg', 'A_BMH_JewlryDesc', 'A_BMH_GlasesDesc', 'A_BMH_ContacDesc', 'A_BMH_DenturDesc', 'A_BMH_HearAdDesc', 'A_BMH_CrutchDesc', 'A_BMH_ArtEyeDesc', 'A_BMH_ArtArmDesc', 'A_BMH_ArtLegDesc', 'A_BMH_WhelChDesc', 'A_BMH_CanWkrDesc', 'A_BMH_BraceDesc', 'A_BMH_OthHmIDesc', 'A_BMH_ClothCmt', 'A_BMH_CCCmt', 'A_BMH_WalHanbgCt', 'A_BMH_JewelryCmt', 'A_BMH_GlassesCmt', 'A_BMH_ContactCmt'
			, 'A_BMH_DentureCmt', 'A_BMH_HearAidCmt', 'A_BMH_CrutchCmt', 'A_BMH_ArtEyeCmt', 'A_BMH_ArtArmCmt', 'A_BMH_ArtLegCmt', 'A_BMH_WheelChCmt', 'A_BMH_CaneWlkCmt', 'A_BMH_BraceCmt', 'A_BMH_OtHmItmCmt', 'A_BMH_BelongCmt', 'A_BMH_DNR', 'A_IV1 DC Dt', 'A_IV2 DC Dt', 'A_IV3 DC Dt', 'A_IV4 DC Dt',
			'A_BMH_ListCoMorb','A_PresSoreSite1','A_BMH_SiteOth1','A_BMH_Later1','A_BMH_Type1','A_BMH_PrOnAdm1','A_BMH_TypOth1','A_BMH_DressCon1','A_BMH_DreCoOth1',
			'A_PresSoreSite2','A_BMH_SiteOth2','A_BMH_Later2','A_BMH_Type2','A_BMH_PrOnAdm2','A_BMH_TypOth2','A_BMH_DressCon2','A_BMH_DreCoOth2',
			'A_PresSoreSite3','A_BMH_SiteOth3','A_BMH_Later3','A_BMH_Type3','A_BMH_PrOnAdm3','A_BMH_TypOth3','A_BMH_DressCon3','A_BMH_DreCoOth3',
			'A_PresSoreSite4','A_BMH_SiteOth4','A_BMH_Later4','A_BMH_Type4','A_BMH_PrOnAdm4','A_BMH_TypOth4','A_BMH_DressCon4','A_BMH_DreCoOth4',
			'A_PresSoreSite5','A_BMH_SiteOth5','A_BMH_Later5','A_BMH_Type5','A_BMH_PrOnAdm5','A_BMH_TypOth5','A_BMH_DressCon5','A_BMH_DreCoOth5',
			'A_PresSoreSite6','A_BMH_SiteOth6','A_BMH_Later6','A_BMH_Type6','A_BMH_PrOnAdm6','A_BMH_TypOth6','A_BMH_DressCon6','A_BMH_DreCoOth6',
			'A_PresSoreSite7','A_BMH_SiteOth7','A_BMH_Later7','A_BMH_Type7','A_BMH_PrOnAdm7','A_BMH_TypOth7','A_BMH_DressCon7','A_BMH_DreCoOth7',
			'A_PresSoreSite8','A_BMH_SiteOth8','A_BMH_Later8','A_BMH_Type8','A_BMH_PrOnAdm8','A_BMH_TypOth8','A_BMH_DressCon8','A_BMH_DreCoOth8',
			'A_WeightObtained','A_BMH_MEWSScore'
			)
		AND (
			ha.FindingAbbr NOT IN ('A_BMH_Trach', 'A_Tube/Drain1', 'A_T/D1 Loc', 'A_Tube/Drain2', 'A_T/D2 Loc')
			OR ha.formusagedisplayname IN ('Med Surg Shift Assessment', 'Behavioral Shift Assessment', 'Shift Assessment', 'Shift Flowsheet', 'Patient Belongings'
				, 'Integumentary Assessment'
				)
			)
		AND (
				(
					ha.FindingAbbr NOT IN ('A_BMH_TobacUse')
					OR ha.formusagedisplayname IN ('Admission')
				)
				OR
				(
					ha.FindingAbbr IN ('A_Admit From', 'A_BMH_TobacUse')
					OR ha.CollectedDt >= (getdate() - 1)
				)
			)
		AND ha.assessmentstatuscode IN (1, 3)
		--AND (
		--	ha.FindingAbbr IN ('A_Admit From', 'A_BMH_TobacUse')
		--	OR ha.collecteddt >= (getdate() - 1)
		--	)

	--  insert into @AssessmentObsValues  
	--  select PatientOID = ha.Patient_OID,  
	--     PatientVisitOID  = ha.PatientVisit_OID,   
	--     FormUsageDisplayName = ha.FormUsageDisplayName,  
	--    CollectedDateTime = ha.collecteddt,  
	--    AssessmentID = ha.AssessmentID,      
	--    FindingAbbr  = ha.FindingAbbr,  
	--    FindingValue  = replace(isnull(ha.Value,''), char(30), ', '),  
	--    SlNo = row_number() over (partition by ha.patientvisit_oid,ha.FindingAbbr order by ha.patientvisit_oid,ha.FindingAbbr,ha.collecteddt desc,ha.AssessmentID desc)   
	--  from vw_ore_assessmentObservation ha with (noLock)  
	--   inner join @tblPatientOID tp   
	--        on tp.patientOID = ha.patient_oid   
	--        and tp.VisitOID = ha.patientvisit_oid   
	--   where ha.ObservationEndDT is null and ha.ObservationStatus like 'AV'       
	--    and ha.FindingAbbr in ('A_BMH_Trach','A_Tube/Drain1','A_T/D1 Loc','A_Tube/Drain2','A_T/D2 Loc')  
	--    and ha.formusagedisplayname in ('Med Surg Shift Assessment','Behavioral Shift Assessment','Shift Assessment')  
	--    and ha.assessmentstatuscode in (1,3 )   
	--    and ha.collecteddt >= (getdate()-1)   
	DELETE
	FROM @AssessmentObsValues
	WHERE SlNo > 1

	INSERT INTO @DietModifier
	SELECT PatientOID = tp.PatientOID,
		PatientVisitOID = tp.VisitOID,
		DietModifier = hos.DietModifier1,
		slNo = rank() OVER (
			PARTITION BY ho.patient_oid,
			ho.patientvisit_oid ORDER BY ho.enteredDateTime DESC
			)
	FROM HOrderSuppInfo hos WITH (NOLOCK)
	INNER JOIN Horder ho WITH (NOLOCK) ON hos.objectid = ho.OrderSuppInfo_oid
		AND ho.orderTypeAbbr = 'Dietary'
	INNER JOIN @tblPatientOID tp ON tp.patientOID = ho.patient_oid
		AND tp.VisitOID = ho.patientvisit_oid
	WHERE hos.DietModifier1 IS NOT NULL

	DELETE
	FROM @DietModifier
	WHERE slno > 1

	INSERT INTO @DietaryOrders
	SELECT HO.Patient_oid,
		HO.PatientVisit_oid,
		slNo = rank() OVER (
			PARTITION BY ho.patient_oid,
			ho.patientvisit_oid ORDER BY ho.enteredDateTime DESC
			),
		HO.OrderDescAsWritten,
		HO.EnteredDateTime
	FROM HOrderSuppInfo hos WITH (NOLOCK)
	INNER JOIN Horder ho WITH (NOLOCK) ON hos.objectid = ho.OrderSuppInfo_oid
		AND ho.orderTypeAbbr = 'Dietary'
	INNER JOIN @tblPatientOID tp ON tp.patientOID = ho.patient_oid
		AND tp.VisitOID = ho.patientvisit_oid

	INSERT INTO @LastDietaryOrder
	SELECT A.PatientOID
	, A.PatientVisitOID
	, A.OrderDescAsWritten
	, A.EnterdDateTime
	FROM @DietaryOrders AS A
	WHERE slNO = 1
	;

	INSERT INTO @TelemetryOrders
	SELECT HO.Patient_oid,
		HO.PatientVisit_oid,
		slNo = rank() OVER (
			PARTITION BY ho.patient_oid,
			ho.patientvisit_oid ORDER BY ho.enteredDateTime DESC
			),
		HO.OrderDescAsWritten,
		HO.EnteredDateTime
	FROM HOrderSuppInfo hos WITH (NOLOCK)
	INNER JOIN Horder ho WITH (NOLOCK) ON hos.objectid = ho.OrderSuppInfo_oid
		AND ho.OrderName in (
			'Continue Telemetry Monitoring'
			, 'Telemetry Monitoring'
			, 'Telemetry Monitoring in ICU/StepDown'
			, 'TELEMETRY MONITORING DISCONTINUED'
		)
	INNER JOIN @tblPatientOID tp ON tp.patientOID = ho.patient_oid
		AND tp.VisitOID = ho.patientvisit_oid

	INSERT INTO @LastTelemetryOrder
	SELECT A.PatientOID
	, A.PatientVisitOID
	, A.OrderDescAsWritten
	, A.EnterdDateTime
	FROM @TelemetryOrders AS A
	WHERE slNO = 1
	;

	INSERT INTO @PhysicalTherapyOrders
	SELECT HO.Patient_oid,
		HO.PatientVisit_oid,
		slNo = rank() OVER (
			PARTITION BY ho.patient_oid,
			ho.patientvisit_oid ORDER BY ho.enteredDateTime DESC
			),
		HO.OrderDescAsWritten,
		HO.EnteredDateTime
	FROM HOrderSuppInfo hos WITH (NOLOCK)
	INNER JOIN Horder ho WITH (NOLOCK) ON hos.objectid = ho.OrderSuppInfo_oid
		AND ho.OrderSubTypeAbbr = 'Physical Therapy'
	INNER JOIN @tblPatientOID tp ON tp.patientOID = ho.patient_oid
		AND tp.VisitOID = ho.patientvisit_oid

	INSERT INTO @LastPhysicalTherapyOrder
	SELECT A.PatientOID
	, A.PatientVisitOID
	, A.OrderDescAsWritten
	, A.EnterdDateTime
	FROM @PhysicalTherapyOrders AS A
	WHERE slNO = 1
	;

	INSERT INTO @ActivityOrders
	SELECT HO.Patient_oid,
		HO.PatientVisit_oid,
		slNo = rank() OVER (
			PARTITION BY ho.patient_oid,
			ho.patientvisit_oid ORDER BY ho.enteredDateTime DESC
			),
		HO.OrderDescAsWritten,
		HO.EnteredDateTime
	FROM HOrderSuppInfo hos WITH (NOLOCK)
	INNER JOIN Horder ho WITH (NOLOCK) ON hos.objectid = ho.OrderSuppInfo_oid
		AND ho.OrderSubTypeAbbr IN ('Activity','Activity - PC')
	INNER JOIN @tblPatientOID tp ON tp.patientOID = ho.patient_oid
		AND tp.VisitOID = ho.patientvisit_oid

	INSERT INTO @LastActivityOrder
	SELECT A.PatientOID
	, A.PatientVisitOID
	, A.OrderDescAsWritten
	, A.EnterdDateTime
	, [OrderNumber] = ROW_NUMBER() OVER(ORDER BY PatientOID)
	FROM @ActivityOrders AS A
	WHERE slNO = 1
	;

	DELETE
	FROM @LastActivityOrder
	WHERE OrderNumber > 4
	;

	INSERT INTO @BedrestOrders
	SELECT HO.Patient_oid,
		HO.PatientVisit_oid,
		slNo = rank() OVER (
			PARTITION BY ho.patient_oid,
			ho.patientvisit_oid ORDER BY ho.enteredDateTime DESC
			),
		HO.OrderDescAsWritten,
		HO.EnteredDateTime
	FROM HOrderSuppInfo hos WITH (NOLOCK)
	INNER JOIN Horder ho WITH (NOLOCK) ON hos.objectid = ho.OrderSuppInfo_oid
		AND ho.OrderSubTypeAbbr IN ('Activity','Activity - PC')
		AND HO.OrderDescAsWritten LIKE '%BED%REST%'
	INNER JOIN @tblPatientOID tp ON tp.patientOID = ho.patient_oid
		AND tp.VisitOID = ho.patientvisit_oid

	INSERT INTO @LastBedrestOrder
	SELECT A.PatientOID
	, A.PatientVisitOID
	, A.OrderDescAsWritten
	, A.EnterdDateTime
	FROM @BedrestOrders AS A
	WHERE slNO = 1
	;

	INSERT INTO @GlucoseOrders
	SELECT HO.Patient_oid,
		HO.PatientVisit_oid,
		slNo = rank() OVER (
			PARTITION BY ho.patient_oid,
			ho.patientvisit_oid ORDER BY ho.enteredDateTime DESC
			),
		HO.OrderDescAsWritten,
		HO.EnteredDateTime
	FROM HOrderSuppInfo hos WITH (NOLOCK)
	INNER JOIN Horder ho WITH (NOLOCK) ON hos.objectid = ho.OrderSuppInfo_oid
		AND HO.OrderName LIKE '%GLUCOSE%TOLERANCE%'
	INNER JOIN @tblPatientOID tp ON tp.patientOID = ho.patient_oid
		AND tp.VisitOID = ho.patientvisit_oid

	INSERT INTO @LastGlucoseOrder
	SELECT A.PatientOID
	, A.PatientVisitOID
	, A.OrderDescAsWritten
	, A.EnterdDateTime
	FROM @GlucoseOrders AS A
	WHERE slNO = 1
	;

	INSERT INTO @NeuroChecksOrders
	SELECT HO.Patient_oid,
		HO.PatientVisit_oid,
		slNo = rank() OVER (
			PARTITION BY ho.patient_oid,
			ho.patientvisit_oid ORDER BY ho.enteredDateTime DESC
			),
		HO.OrderDescAsWritten,
		HO.EnteredDateTime
	FROM HOrderSuppInfo hos WITH (NOLOCK)
	INNER JOIN Horder ho WITH (NOLOCK) ON hos.objectid = ho.OrderSuppInfo_oid
		AND HO.OrderName LIKE '%NEURO%CHECKS%'
	INNER JOIN @tblPatientOID tp ON tp.patientOID = ho.patient_oid
		AND tp.VisitOID = ho.patientvisit_oid

	INSERT INTO @LastNeuroCheckOrder
	SELECT A.PatientOID
	, A.PatientVisitOID
	, A.OrderDescAsWritten
	, A.EnterdDateTime
	FROM @NeuroChecksOrders AS A
	WHERE slNO = 1
	;

	INSERT INTO @IVOrders
	SELECT HO.Patient_oid,
		HO.PatientVisit_oid,
		slNo = rank() OVER (
			PARTITION BY ho.patient_oid,
			ho.patientvisit_oid ORDER BY ho.enteredDateTime DESC
			),
		HO.OrderDescAsWritten,
		HO.EnteredDateTime
	FROM HOrderSuppInfo hos WITH (NOLOCK)
	INNER JOIN Horder ho WITH (NOLOCK) ON hos.objectid = ho.OrderSuppInfo_oid
		AND ho.CommonDefName like '%PREREGIVPCO%'
	INNER JOIN @tblPatientOID tp ON tp.patientOID = ho.patient_oid
		AND tp.VisitOID = ho.patientvisit_oid

	INSERT INTO @LastIVOrder
	SELECT A.PatientOID
	, A.PatientVisitOID
	, A.OrderDescAsWritten
	, A.EnterdDateTime
	FROM @IVOrders AS A
	WHERE slNO = 1
	;

	-- glucose result
	INSERT INTO @GlucoseResults
	SELECT HO.Patient_oid
	, HA.PatientVisit_oid
	, [slNO] = ROW_NUMBER() OVER(PARTITION BY HO.pATIENT_OID ORDER BY HO.CREATIONTIME DESC)
	, HO.Value
	, HO.CreationTime

	FROM HObservation AS HO
	INNER JOIN HAssessment AS HA
	on HO.Patient_oid = HA.Patient_oid
		AND HO.AssessmentID = ha.AssessmentID
		AND ho.EndDT IS NULL
	INNER JOIN @tblPatientOID AS PT
	ON HA.PatientVisit_oid = PT.visitoid
		AND ha.Patient_oid = pt.PatientOID

	WHERE HO.InternalValue IN (
		'2650','82948','9018'
	)
	
	INSERT INTO @LastGlucoseResult
	SELECT A.PatientOID
	, A.PatientVisitOID
	, A.GlucoseValue
	, A.CreationDateTime
	FROM @GlucoseResults AS A

	WHERE A.slNO = 1
	;

	INSERT INTO @AssessmentStatus
	SELECT PatientOID = tp.PatientOID,
		PatientVisitOID = tp.VisitOID,
		formusagedisplayname = ha.formusagedisplayname,
		AssessmentID = ha.AssessmentID,
		AssessmentStatus = ha.AssessmentStatus,
		CollectedDT = ha.CollectedDT
	FROM @tblPatientOID tp
	INNER JOIN Hassessment ha WITH (NOLOCK) ON tp.patientOID = ha.patient_oid
		AND tp.VisitOID = ha.patientvisit_oid
		AND ha.enddt IS NULL
		AND formusagedisplayname IN ('Admission', 'Inpatient Home Medication List','Integumentary Assessment', 'Vital Signs')
		AND assessmentStatuscode IN (1, 3)

	INSERT INTO @pivotObsValues (
		PatientOID,
		PatientVisitOID,
		LIHNType,
		PatientOnIsolation,
		Observation,
		FallRiskScore,
		FallPrecautions,
		BedAlarmOn,
		Restraints,
		O2Sat,
		Telemetry,
		Pain,
		PainLocation,
		AccuCheck,
		SkinIntegrity,
		WoundType,
		Foley,
		insertionDate,
		CardioPulmonary,
		NeuroOrientedTo,
		RestraintType,
		AdmittedFrom,
		AccPainLevel,
		Temperature,
		Pulse,
		BP,
		Respiration,
		IVSite1,
		IVInsertDt1,
		IVDressChDt1,
		IVtubeChDt1,
		IVSite2,
		IVInsertDt2,
		IVDressChDt2,
		IVtubeChDt2,
		IVSite3,
		IVInsertDt3,
		IVDressChDt3,
		IVtubeChDt3,
		IVSite4,
		IVInsertDt4,
		IVDressChDt4,
		IVtubeChDt4,
		Oxygen,
		O2Per,
		O2LPM,
		NIHScaleScore,
		NIHScaleScoreCollectedDt,
		TrachTube,
		TubeDrain,
		ATD1Location,
		TubeDrain2,
		ATD2Location,
		IVType1,
		IVType2,
		IVType3,
		IVType4,
		TobaccoUse,
		WDL,
		MorseFallRisk,
		Pneumovax,
		PneuImmunizationDt,
		Influenza,
		InfluImmunizationDt,
		CardiacRhythm,
		RhythmDesc,
		SkinColor,
		SkinTemp,
		SkinMoisture,
		CapillaryRefill,
		CVEdemaNoted,
		AbnormalPulses,
		RecentFalls,
		VentType,
		VentTube,
		ChestTube1Loc,
		ChestTube2Loc,
		ChestTube3Loc,
		PtMedComp,
		PtMedCompCmt,
		PtAttGrps,
		PtAttGrpsCmt,
		TapBell,
		Affect,
		Behavior,
		Cognitive,
		HrsSlept,
		SleepProb,
		BhvrObsLvl,
		BhvrCmt,
		SpirRcrs,
		FamInvolve,
		SpirConcerns,
		SpirConcernsDesc,
		SpirConcernsCmt,
		LastBMDate,
		BreakfastAmt,
		LunchAmt,
		DinnerAmt,
		PatientBelongings,
		Clothing,
		CreditCard,
		WalletHandbag,
		Jewelry,
		Glasses,
		Contacts,
		Dentures,
		HearingAid,
		Crutches,
		ArtificialEye,
		ArtificialArm,
		ArtificialLeg,
		WheelChair,
		CaneWalker,
		Brace,
		OtherHomeItems,
		ClothingCmt,
		CreditCardCmt,
		WalletHandbagCmt,
		JewelryCmt,
		GlassesCmt,
		ContactsCmt,
		DenturesCmt,
		HearingAidCmt,
		CrutchesCmt,
		ArtificialEyeCmt,
		ArtificialArmCmt,
		ArtificialLegCmt,
		WheelChairCmt,
		CaneWalkerCmt,
		BraceCmt,
		OtherHomeItemsCmt,
		BelongingsCmt,
		DNR,
		IV1DCDt,
		IV2DCDt,
		IV3DCDt,
		IV4DCDt,
		ListCoMorb,
		PresSoreSite1,
		PresSoreSite1Other,
		PresSoreSite1Laterality,
		PresSoreSite1Type,
		PresSoreSite1POA,
		PresSoreSite1TypeOther,
		PresSoreSite1DressingCondition,
		PresSoreSite1DressConOther,
		PresSoreSite2,
		PresSoreSite2Other,
		PresSoreSite2Laterality,
		PresSoreSite2Type,
		PresSoreSite2POA,
		PresSoreSite2TypeOther,
		PresSoreSite2DressingCondition,
		PresSoreSite2DressConOther,
		PresSoreSite3,
		PresSoreSite3Other,
		PresSoreSite3Laterality,
		PresSoreSite3Type,
		PresSoreSite3POA,
		PresSoreSite3TypeOther,
		PresSoreSite3DressingCondition,
		PresSoreSite3DressConOther,
		PresSoreSite4,
		PresSoreSite4Other,
		PresSoreSite4Laterality,
		PresSoreSite4Type,
		PresSoreSite4POA,
		PresSoreSite4TypeOther,
		PresSoreSite4DressingCondition,
		PresSoreSite4DressConOther,
		PresSoreSite5,
		PresSoreSite5Other,
		PresSoreSite5Laterality,
		PresSoreSite5Type,
		PresSoreSite5POA,
		PresSoreSite5TypeOther,
		PresSoreSite5DressingCondition,
		PresSoreSite5DressConOther,
		PresSoreSite6,
		PresSoreSite6Other,
		PresSoreSite6Laterality,
		PresSoreSite6Type,
		PresSoreSite6POA,
		PresSoreSite6TypeOther,
		PresSoreSite6DressingCondition,
		PresSoreSite6DressConOther,
		PresSoreSite7,
		PresSoreSite7Other,
		PresSoreSite7Laterality,
		PresSoreSite7Type,
		PresSoreSite7POA,
		PresSoreSite7TypeOther,
		PresSoreSite7DressingCondition,
		PresSoreSite7DressConOther,
		PresSoreSite8,
		PresSoreSite8Other,
		PresSoreSite8Laterality,
		PresSoreSite8Type,
		PresSoreSite8POA,
		PresSoreSite8TypeOther,
		PresSoreSite8DressingCondition,
		PresSoreSite8DressConOther,
		WeightObtainedDT,
		MEWSScore
		)
	SELECT tov.PatientOID,
		tov.PatientVisitOID,
		LIHNType = max(CASE tov.findingabbr
				WHEN 'A_LIHN TYPE'
					THEN tov.findingValue
				ELSE ''
				END),
		PatientOnIsolation = max(CASE tov.findingabbr
				WHEN 'A_BMH_Isolation?'
					THEN tov.findingValue
				ELSE ''
				END),
		Observation = max(CASE tov.findingabbr
				WHEN 'A_BMH_ObsLevel'
					THEN tov.findingValue
				ELSE ''
				END),
		FallRiskScore = max(CASE tov.findingabbr
				WHEN 'A_Fall Risk'
					THEN tov.findingValue
				ELSE ''
				END),
		FallPrecautions = max(CASE tov.findingabbr
				WHEN 'A_BMH_FallPrec?'
					THEN tov.findingValue
				ELSE ''
				END),
		BedAlarmOn = max(CASE tov.findingabbr
				WHEN 'A_BMH_BedAlarm?'
					THEN tov.findingValue
				ELSE ''
				END),
		Restraints = max(CASE tov.findingabbr
				WHEN 'A_BMH_Restraints'
					THEN tov.findingValue
				ELSE ''
				END),
		O2Sat = max(CASE tov.findingabbr
				WHEN 'A_Pulse Ox'
					THEN tov.findingValue
				ELSE ''
				END),
		Telemetry = max(CASE tov.findingabbr
				WHEN 'A_BMH_Telemetry'
					THEN tov.findingValue
				ELSE ''
				END),
		Pain = max(CASE tov.findingabbr
				WHEN 'A_BMH_Pain Score'
					THEN tov.findingValue
				ELSE ''
				END),
		PainLocation = max(CASE tov.findingabbr
				WHEN 'A_Pain1 Location'
					THEN tov.findingValue
				ELSE ''
				END),
		AccuCheck = max(CASE tov.findingabbr
				WHEN 'A_BMH_Accuchecks'
					THEN tov.findingValue
				ELSE ''
				END),
		SkinIntegrity = max(CASE tov.findingabbr
				WHEN 'A_BMH_SkinInteg'
					THEN tov.findingValue
				ELSE ''
				END),
		WoundType = max(CASE tov.findingabbr
				WHEN 'A_BMH_Wound Type'
					THEN tov.findingValue
				ELSE ''
				END),
		Foley = max(CASE tov.findingabbr
				WHEN 'A_Urine Chars'
					THEN (
							CASE 
								WHEN tov.findingValue LIKE '%Foley Catheter%'
									THEN tov.findingValue
								ELSE ''
								END
							)
				ELSE ''
				END),
		insertionDate = max(CASE tov.findingabbr
				WHEN 'A_BMH_CathInstDt'
					THEN tov.findingValue
				ELSE NULL
				END),
		CardioPulmonary = max(CASE tov.findingabbr
				WHEN 'A_BMH_CP_Screen'
					THEN tov.findingValue
				ELSE ''
				END),
		NeuroOrientedTo = max(CASE tov.findingabbr
				WHEN 'A_Oriented To'
					THEN tov.findingValue
				ELSE ''
				END),
		RestraintType = max(CASE tov.findingabbr
				WHEN 'A_RstrntType'
					THEN tov.findingValue
				ELSE ''
				END),
		AdmittedFrom = max(CASE tov.findingabbr
				WHEN 'A_Admit From'
					THEN tov.findingValue
				ELSE ''
				END),
		AccPainLevel = max(CASE tov.findingabbr
				WHEN 'A_BMH_AccPnLevel'
					THEN tov.findingValue
				ELSE ''
				END),
		Temperature = max(CASE tov.findingabbr
				WHEN 'A_Temperature'
					THEN tov.findingValue
				ELSE ''
				END),
		Pulse = max(CASE tov.findingabbr
				WHEN 'A_Pulse'
					THEN tov.findingValue
				ELSE ''
				END),
		BP = max(CASE tov.findingabbr
				WHEN 'A_BP'
					THEN tov.findingValue
				ELSE ''
				END),
		Respiration = max(CASE tov.findingabbr
				WHEN 'A_Respirations'
					THEN tov.findingValue
				ELSE ''
				END),
		IVSite1 = max(CASE tov.findingabbr
				WHEN 'A_IV1 Site'
					THEN tov.findingValue
				ELSE ''
				END),
		IVInsertDt1 = max(CASE tov.findingabbr
				WHEN 'A_IV1 Insert Dt'
					THEN tov.findingValue
				ELSE NULL
				END),
		IVDressChDt1 = max(CASE tov.findingabbr
				WHEN 'A_IV1DressChDt'
					THEN tov.findingValue
				ELSE NULL
				END),
		IVtubeChDt1 = max(CASE tov.findingabbr
				WHEN 'A_IV1 TubeChDt'
					THEN tov.findingValue
				ELSE NULL
				END),
		IVSite2 = max(CASE tov.findingabbr
				WHEN 'A_IV2 Site'
					THEN tov.findingValue
				ELSE ''
				END),
		IVInsertDt2 = max(CASE tov.findingabbr
				WHEN 'A_IV2 Insert Dt'
					THEN tov.findingValue
				ELSE NULL
				END),
		IVDressChDt2 = max(CASE tov.findingabbr
				WHEN 'A_IV2DressChDt'
					THEN tov.findingValue
				ELSE NULL
				END),
		IVtubeChDt2 = max(CASE tov.findingabbr
				WHEN 'A_IV2 TubeChDt'
					THEN tov.findingValue
				ELSE NULL
				END),
		IVSite3 = max(CASE tov.findingabbr
				WHEN 'A_IV3 Site'
					THEN tov.findingValue
				ELSE ''
				END),
		IVInsertDt3 = max(CASE tov.findingabbr
				WHEN 'A_IV3 Insert Dt'
					THEN tov.findingValue
				ELSE NULL
				END),
		IVDressChDt3 = max(CASE tov.findingabbr
				WHEN 'A_IV3DressChDt'
					THEN tov.findingValue
				ELSE NULL
				END),
		IVtubeChDt3 = max(CASE tov.findingabbr
				WHEN 'A_IV3 TubeChDt'
					THEN tov.findingValue
				ELSE NULL
				END),
		IVSite4 = max(CASE tov.findingabbr
				WHEN 'A_IV4 Site'
					THEN tov.findingValue
				ELSE ''
				END),
		IVInsertDt4 = max(CASE tov.findingabbr
				WHEN 'A_IV4 Insert Dt'
					THEN tov.findingValue
				ELSE NULL
				END),
		IVDressChDt4 = max(CASE tov.findingabbr
				WHEN 'A_IV4DressChDt'
					THEN tov.findingValue
				ELSE NULL
				END),
		IVtubeChDt4 = max(CASE tov.findingabbr
				WHEN 'A_IV4 TubeChDt'
					THEN tov.findingValue
				ELSE NULL
				END),
		Oxygen = max(CASE tov.findingabbr
				WHEN 'A_BMH_Oxygen?'
					THEN tov.findingValue
				ELSE ''
				END),
		O2Per = max(CASE tov.findingabbr
				WHEN 'A_O2 %'
					THEN tov.findingValue
				ELSE ''
				END),
		O2LPM = max(CASE tov.findingabbr
				WHEN 'A_O2 LPM'
					THEN tov.findingValue
				ELSE ''
				END),
		NIHScaleScore = max(CASE tov.findingabbr
				WHEN 'A_BMH_TotalStkSc'
					THEN tov.findingValue
				ELSE ''
				END),
		NIHScaleScoreCollectedDt = max(CASE tov.findingabbr
				WHEN 'A_BMH_TotalStkSc'
					THEN tov.CollectedDateTime
				ELSE NULL
				END),
		TrachTube = max(CASE tov.findingabbr
				WHEN 'A_BMH_Trach'
					THEN tov.findingValue
				ELSE ''
				END),
		TubeDrain = max(CASE tov.findingabbr
				WHEN 'A_Tube/Drain1'
					THEN tov.findingValue
				ELSE ''
				END),
		ATD1Location = max(CASE tov.findingabbr
				WHEN 'A_T/D1 Loc'
					THEN tov.findingValue
				ELSE ''
				END),
		TubeDrain2 = max(CASE tov.findingabbr
				WHEN 'A_Tube/Drain2'
					THEN tov.findingValue
				ELSE ''
				END),
		ATD2Location = max(CASE tov.findingabbr
				WHEN 'A_T/D2 Loc'
					THEN tov.findingValue
				ELSE ''
				END),
		IVType1 = max(CASE tov.findingabbr
				WHEN 'A_IV1 Type'
					THEN tov.findingValue
				ELSE ''
				END),
		IVType2 = max(CASE tov.findingabbr
				WHEN 'A_IV2 Type'
					THEN tov.findingValue
				ELSE ''
				END),
		IVType3 = max(CASE tov.findingabbr
				WHEN 'A_IV3 Type'
					THEN tov.findingValue
				ELSE ''
				END),
		IVType4 = max(CASE tov.findingabbr
				WHEN 'A_IV4 Type'
					THEN tov.findingValue
				ELSE ''
				END),
		TobaccoUse = max(CASE tov.findingabbr
				WHEN 'A_BMH_TobacUse'
					THEN CASE 
							WHEN (
									(PATINDEX('%Current use%', tov.findingValue) > 0)
									OR (PATINDEX('%Past use, less than 1 year ago%', tov.findingValue) > 0)
									)
								THEN 'Y'
							ELSE 'N'
							END
				ELSE ''
				END),
		WDL = max(CASE tov.findingabbr
				WHEN 'A_BMH_WDL'
					THEN tov.findingValue
				ELSE ''
				END),
		MorseFallRisk = max(CASE tov.findingabbr
				WHEN 'A_MorseFallRisk'
					THEN tov.findingValue
				ELSE ''
				END),
		Pneumovax = max(CASE tov.findingabbr
				WHEN 'A_Pneumo Immun'
					THEN tov.findingValue
				ELSE ''
				END),
		PneuImmunizationDt = max(CASE tov.findingabbr
				WHEN 'A_Pneum Im Dt'
					THEN tov.findingValue
				ELSE ''
				END),
		Influenza = max(CASE tov.findingabbr
				WHEN 'A_InfluenzaImmun'
					THEN tov.findingValue
				ELSE ''
				END),
		InfluImunizationDt = max(CASE tov.findingabbr
				WHEN 'A_InfluenzaImDt'
					THEN tov.findingValue
				ELSE ''
				END),
		CardiacRhythm = max(CASE tov.findingabbr
				WHEN 'A_Cardiac Rhythm'
					THEN tov.findingValue
				ELSE ''
				END),
		RhythmDesc = max(CASE tov.findingabbr
				WHEN 'A_BMH_RhyDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		SkinColor = max(CASE tov.findingabbr
				WHEN 'A_Skin Color'
					THEN tov.findingValue
				ELSE ''
				END),
		SkinTemp = max(CASE tov.findingabbr
				WHEN 'A_Skin Temp'
					THEN tov.findingValue
				ELSE ''
				END),
		SkinMoisture = max(CASE tov.findingabbr
				WHEN 'A_Skin Moisture'
					THEN tov.findingValue
				ELSE ''
				END),
		CapillaryRefill = max(CASE tov.findingabbr
				WHEN 'A_CapRefill>3sec'
					THEN tov.findingValue
				ELSE ''
				END),
		CVEdemaNoted = max(CASE tov.findingabbr
				WHEN 'A_CV Edema'
					THEN tov.findingValue
				ELSE ''
				END),
		AbnormalPulses = max(CASE tov.findingabbr
				WHEN 'A_Abnormal Pulses'
					THEN tov.findingValue
				ELSE ''
				END),
		RecentFalls = max(CASE tov.findingabbr
				WHEN 'A_RecentFalls'
					THEN tov.findingValue
				ELSE ''
				END),
		VentType = max(CASE tov.findingabbr
				WHEN 'A_Vent Type'
					THEN tov.findingValue
				ELSE ''
				END),
		VentTube = max(CASE tov.findingabbr
				WHEN 'A_Vent Tube'
					THEN tov.findingValue
				ELSE ''
				END),
		ChestTube1Loc = max(CASE tov.findingabbr
				WHEN 'A_CT1 Location'
					THEN tov.findingValue
				ELSE ''
				END),
		ChestTube2Loc = max(CASE tov.findingabbr
				WHEN 'A_CT2 Location'
					THEN tov.findingValue
				ELSE ''
				END),
		ChestTube3Loc = max(CASE tov.findingabbr
				WHEN 'A_CT3 Location'
					THEN tov.findingValue
				ELSE ''
				END),
		PtMedComp = max(CASE tov.findingabbr
				WHEN 'A_BMH_PatMedCom'
					THEN tov.findingValue
				ELSE ''
				END),
		PtMedCompCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_MedComm'
					THEN tov.findingValue
				ELSE ''
				END),
		PtAttGrp = max(CASE tov.findingabbr
				WHEN 'A_BMH_PatAttGr'
					THEN tov.findingValue
				ELSE ''
				END),
		PtAttGrpCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_AttGrComm'
					THEN tov.findingValue
				ELSE ''
				END),
		TapBell = max(CASE tov.findingabbr
				WHEN 'A_BMH_TapBell?'
					THEN tov.findingValue
				ELSE ''
				END),
		Affect = max(CASE tov.findingabbr
				WHEN 'A_Affect'
					THEN tov.findingValue
				ELSE ''
				END),
		Behavior = max(CASE tov.findingabbr
				WHEN 'A_Behavior'
					THEN tov.findingValue
				ELSE ''
				END),
		Cognitive = max(CASE tov.findingabbr
				WHEN 'A_Cognitive'
					THEN tov.findingValue
				ELSE ''
				END),
		HrsSlept = max(CASE tov.findingabbr
				WHEN 'A_Hours Slept'
					THEN tov.findingValue
				ELSE ''
				END),
		SleepProb = max(CASE tov.findingabbr
				WHEN 'A_Sleep Problems'
					THEN tov.findingValue
				ELSE ''
				END),
		BhvrObsLvl = max(CASE tov.findingabbr
				WHEN 'A_BMH_ObsvnLevel'
					THEN tov.findingValue
				ELSE ''
				END),
		BhvrCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_BhvrComent'
					THEN tov.findingValue
				ELSE ''
				END),
		SpirConcerns = max(CASE tov.findingabbr
				WHEN 'A_Need Spir Rcrs'
					THEN tov.findingValue
				ELSE ''
				END),
		FamInvolve = max(CASE tov.findingabbr
				WHEN 'A_BMH_FamInvolve'
					THEN tov.findingValue
				ELSE ''
				END),
		SpirConcerns = max(CASE tov.findingabbr
				WHEN 'A_Spir Concerns'
					THEN tov.findingValue
				ELSE ''
				END),
		SpirConcernsDesc = max(CASE tov.findingabbr
				WHEN 'A_Desc Spir Conc'
					THEN tov.findingValue
				ELSE ''
				END),
		SpirConcernsCmt = max(CASE tov.findingabbr
				WHEN 'A_P/S Cmnts'
					THEN tov.findingValue
				ELSE ''
				END),
		LastBMDate = max(CASE tov.findingabbr
				WHEN 'A_Last BM Date'
					THEN tov.findingValue
				ELSE ''
				END),
		BreakfastAmt = max(CASE tov.findingabbr
				WHEN 'A_Breakfast Amt'
					THEN tov.findingValue
				ELSE ''
				END),
		LunchAmt = max(CASE tov.findingabbr
				WHEN 'A_Lunch Amt'
					THEN tov.findingValue
				ELSE ''
				END),
		DinnerAmt = max(CASE tov.findingabbr
				WHEN 'A_Dinner Amt'
					THEN tov.findingValue
				ELSE ''
				END),
		PatientBelongings = max(CASE tov.findingabbr
				WHEN 'A_BMH_PtNoBelong'
					THEN tov.findingValue
				ELSE ''
				END),
		Clothing = max(CASE tov.findingabbr
				WHEN 'A_BMH_ClothDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		CreditCard = max(CASE tov.findingabbr
				WHEN 'A_BMH_CredCdDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		WalletHandbag = max(CASE tov.findingabbr
				WHEN 'A_BMH_WaletHanBg'
					THEN tov.findingValue
				ELSE ''
				END),
		Jewelry = max(CASE tov.findingabbr
				WHEN 'A_BMH_JewlryDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		Glasses = max(CASE tov.findingabbr
				WHEN 'A_BMH_GlasesDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		Contacts = max(CASE tov.findingabbr
				WHEN 'A_BMH_ContacDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		Dentures = max(CASE tov.findingabbr
				WHEN 'A_BMH_DenturDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		HearingAid = max(CASE tov.findingabbr
				WHEN 'A_BMH_HearAdDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		Crutches = max(CASE tov.findingabbr
				WHEN 'A_BMH_CrutchDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		ArtificialEye = max(CASE tov.findingabbr
				WHEN 'A_BMH_ArtEyeDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		ArtificialArm = max(CASE tov.findingabbr
				WHEN 'A_BMH_ArtArmDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		ArtificialLeg = max(CASE tov.findingabbr
				WHEN 'A_BMH_ArtLegDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		WheelChair = max(CASE tov.findingabbr
				WHEN 'A_BMH_WhelChDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		CaneWalker = max(CASE tov.findingabbr
				WHEN 'A_BMH_CanWkrDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		Brace = max(CASE tov.findingabbr
				WHEN 'A_BMH_BraceDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		OtherHomeItems = max(CASE tov.findingabbr
				WHEN 'A_BMH_OthHmIDesc'
					THEN tov.findingValue
				ELSE ''
				END),
		ClothingCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_ClothCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		CredCardCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_CCCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		WalletHandbagCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_WalHanbgCt'
					THEN tov.findingValue
				ELSE ''
				END),
		JewelryCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_JewelryCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		GlassesCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_GlassesCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		ContactsCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_ContactCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		DenturesCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_DentureCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		HearingAidCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_HearAidCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		CrutchesCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_CrutchCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		ArtificialEyeCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_ArtEyeCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		ArtificialArmCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_ArtArmCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		ArtificialLegCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_ArtLegCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		WheelChairCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_WheelChCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		CaneWalkerCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_CaneWlkCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		BraceCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_BraceCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		OtherHomeItemsCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_OtHmItmCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		BelongingsCmt = max(CASE tov.findingabbr
				WHEN 'A_BMH_BelongCmt'
					THEN tov.findingValue
				ELSE ''
				END),
		DNR = max(CASE tov.findingabbr
				WHEN 'A_BMH_DNR'
					THEN tov.findingValue
				ELSE ''
				END),
		IV1DcDt = max(CASE tov.findingabbr
				WHEN 'A_IV1 DC Dt'
					THEN tov.findingValue
				ELSE ''
				END),
		IV2DcDt = max(CASE tov.findingabbr
				WHEN 'A_IV2 DC Dt'
					THEN tov.findingValue
				ELSE ''
				END),
		IV3DcDt = max(CASE tov.findingabbr
				WHEN 'A_IV3 DC Dt'
					THEN tov.findingValue
				ELSE ''
				END),
		IV4DcDt = max(CASE tov.findingabbr
				WHEN 'A_IV4 DC Dt'
					THEN tov.findingValue
				ELSE ''
				END),
		ListCoMorb = max(CASE tov.FindingAbbr
				WHEN 'A_BMH_ListCoMorb'
					Then tov.FindingValue
					ELSE ''
				END),
		PresSoreSite1 = max(CASE tov.FindingAbbr
				WHEN 'A_PresSoreSite1'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite1Other = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_SiteOth1'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite1Laterality = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Later1'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite1Type = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Type1'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite1POA = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_PrOnAdm1'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite1TypeOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_TypOth1'
					THEN tov.FindingValue	
					ELSE ''
				END),
		PresSoreSite1DressingCondition = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DressCon1'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite1DresConOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DreCoOth1'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite2 = MAX(CASE tov.FindingAbbr
				WHEN 'A_PresSoreSite2'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite2Other = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_SiteOth2'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite2Laterality = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Later2'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite2Type = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Type2'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite2POA = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_PrOnAdm2'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite2TypeOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_TypOth2'
					THEN tov.FindingValue	
					ELSE ''
				END),
		PresSoreSite2DressingCondition = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DressCon2'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite2DresConOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DreCoOth2'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite3 = MAX(CASE tov.FindingAbbr
				WHEN 'A_PresSoreSite3'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite3Other = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_SiteOth3'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite3Laterality = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Later3'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite3Type = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Type3'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite3POA = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_PrOnAdm3'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite3TypeOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_TypOth3'
					THEN tov.FindingValue	
					ELSE ''
				END),
		PresSoreSite3DressingCondition = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DressCon3'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite3DresConOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DreCoOth3'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite4 = MAX(CASE tov.FindingAbbr
				WHEN 'A_PresSoreSite4'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite4Other = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_SiteOth4'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite4Laterality = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Later4'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite4Type = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Type4'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite4POA = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_PrOnAdm4'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite4TypeOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_TypOth4'
					THEN tov.FindingValue	
					ELSE ''
				END),
		PresSoreSite4DressingCondition = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DressCon4'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite4DresConOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DreCoOth4'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite5 = MAX(CASE tov.FindingAbbr
				WHEN 'A_PresSoreSite5'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite5Other = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_SiteOth5'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite5Laterality = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Later5'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite5Type = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Type5'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite5POA = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_PrOnAdm5'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite5TypeOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_TypOth5'
					THEN tov.FindingValue	
					ELSE ''
				END),
		PresSoreSite5DressingCondition = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DressCon5'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite5DresConOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DreCoOth5'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite6 = MAX(CASE tov.FindingAbbr
				WHEN 'A_PresSoreSite6'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite6Other = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_SiteOth6'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite6Laterality = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Later6'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite6Type = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Type6'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite6POA = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_PrOnAdm6'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite6TypeOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_TypOth6'
					THEN tov.FindingValue	
					ELSE ''
				END),
		PresSoreSite6DressingCondition = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DressCon6'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite6DresConOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DreCoOth6'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite7 = MAX(CASE tov.FindingAbbr
				WHEN 'A_PresSoreSite7'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite7Other = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_SiteOth7'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite7Laterality = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Later7'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite7Type = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Type7'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite7POA = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_PrOnAdm7'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite7TypeOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_TypOth7'
					THEN tov.FindingValue	
					ELSE ''
				END),
		PresSoreSite7DressingCondition = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DressCon7'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite7DresConOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DreCoOth7'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite8 = MAX(CASE tov.FindingAbbr
				WHEN 'A_PresSoreSite8'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite8Other = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_SiteOth8'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite8Laterality = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Later8'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite8Type = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_Type8'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite8POA = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_PrOnAdm8'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite8TypeOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_TypOth8'
					THEN tov.FindingValue	
					ELSE ''
				END),
		PresSoreSite8DressingCondition = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DressCon8'
					THEN tov.FindingValue
					ELSE ''
				END),
		PresSoreSite8DresConOther = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_DreCoOth8'
					THEN tov.FindingValue
					ELSE ''
				END),
		WeightObtainedDT = MAX(CASE tov.FindingAbbr
				WHEN 'A_WeightObtained'
					THEN tov.CollectedDateTime
					ELSE ''
				END),
		MEWSScore = MAX(CASE tov.FindingAbbr
				WHEN 'A_BMH_MEWSScore'
					THEN tov.FindingValue
					ELSE ''
				END)
	FROM @AssessmentObsValues tov
	GROUP BY tov.PatientOID,
		tov.PatientVisitOID

	INSERT INTO @pivotAssessmentStatus (
		PatientOID,
		PatientVisitOID,
		IsAdmissionAssmentCharted,
		AdmissionAssmtStatus,
		IsAdmissionAssmtComplete,
		IsIPHomeMedListAssmentCharted,
		IPHomeMedListAssmtStatus,
		IsIPHomeMedListAssmtComplete,
		-- vitals
		IsVitalsAssmtCharted,
		VitalsAssmtStatus,
		ISVitalsAssmtComplete,
		VitalsAssmtCollectedDT
		)
	SELECT tas.PatientOID,
		tas.PatientVisitOID,
		IsAdmissionAssmentCharted = max(CASE tas.formusageDisplayName
				WHEN 'Admission'
					THEN 'Y'
				ELSE 'N'
				END),
		AdmissionAssmtStatus = max(CASE tas.formusageDisplayName
				WHEN 'Admission'
					THEN tas.AssessmentStatus
				ELSE ''
				END),
		IsAdmissionAssmtComplete = max(CASE tas.formusageDisplayName
				WHEN 'Admission'
					THEN (
							CASE tas.AssessmentStatus
								WHEN 'Complete'
									THEN 'Y'
								ELSE 'N'
								END
							)
				ELSE 'N'
				END),
		IsIPHomeMedListAssmentCharted = max(CASE tas.formusageDisplayName
				WHEN 'Inpatient Home Medication List'
					THEN 'Y'
				ELSE 'N'
				END),
		IPHomeMedListAssmtStatus = max(CASE tas.formusageDisplayName
				WHEN 'Inpatient Home Medication List'
					THEN tas.AssessmentStatus
				ELSE ''
				END),
		IsIPHomeMedListAssmtComplete = max(CASE tas.formusageDisplayName
				WHEN 'Inpatient Home Medication List'
					THEN (
							CASE tas.AssessmentStatus
								WHEN 'Complete'
									THEN 'Y'
								ELSE 'N'
								END
							)
				ELSE 'N'
				END),
		IsVitalsAssmtCharted = max(CASE tas.FormUsageDisplayName
			WHEN 'Vital Signs'
				THEN 'Y'
			ELSE 'N'
			END),
		VitalsAssmtStatus = MAX(CASE TAS.FormUsageDisplayName
				WHEN 'Vital Signs'
					THEN tas.AssessmentStatus
				ELSE ''
				END),
		ISVitalsAssmtComplete = max(CASE tas.formusageDisplayName
				WHEN 'Vital Signs'
					THEN (
							CASE tas.AssessmentStatus
								WHEN 'Complete'
									THEN 'Y'
								ELSE 'N'
								END
							)
				ELSE 'N'
				END),
		VitalsAssmtCollectedDT = MAX(CASE tas.formusageDisplayName
				WHEN 'Vital Signs'
					THEN tas.CollectedDt
				ELSE NULL
				END)
	FROM @AssessmentStatus tas
	GROUP BY tas.PatientOID,
		tas.PatientVisitOID

	--select * from @pivotAssessmentStatus  
	SELECT tp.PatientOID,
		tp.PatientVisitOID,
		tp.PatientName,
		tp.RoomBed,
		tp.Age,
		tp.VisitStartDateTime,
		tp.BirthDate,
		tp.Sex,
		tp.MRNumber,
		tp.PatientAcctNum,
		tp.AdmittingDr,
		tp.AttendDr,
		tp.ConsultingDr,
		tp.Allergies,
		tp.Weight,
		tp.ChiefComplaint,
		--tp.DNR ,  
		tp.HealthcareProxy,
		tp.HealthcareProxyName,
		tp.LivingWill,
		tp.DNI,
		tp.IsolationIndicator,
		tp.PatientLocationName,
		tp.UnitContactedName,
		tov.LIHNType,
		tov.PatientOnIsolation,
		tov.Observation,
		tov.FallRiskScore,
		tov.FallPrecautions,
		tov.BedAlarmOn,
		tov.Restraints,
		tov.O2Sat,
		tov.Telemetry,
		tov.Pain,
		tov.PainLocation,
		tov.AccuCheck,
		tov.SkinIntegrity,
		tov.WoundType,
		tov.Foley,
		tov.insertionDate,
		tov.CardioPulmonary,
		tov.NeuroOrientedTo,
		tov.RestraintType,
		tov.AdmittedFrom,
		tov.AccPainLevel,
		tov.Temperature,
		tov.Pulse,
		tov.BP,
		tov.Respiration,
		tov.IVSite1,
		tov.IVInsertDt1,
		tov.IVDressChDt1,
		tov.IVtubeChDt1,
		tov.IVSite2,
		tov.IVInsertDt2,
		tov.IVDressChDt2,
		tov.IVtubeChDt2,
		tov.IVSite3,
		tov.IVInsertDt3,
		tov.IVDressChDt3,
		tov.IVtubeChDt3,
		tov.IVSite4,
		tov.IVInsertDt4,
		tov.IVDressChDt4,
		tov.IVtubeChDt4,
		tdm.DietModifier,
		IsAdmissionAssmentCharted = isnull(tas.IsAdmissionAssmentCharted, 'N'),
		AdmissionAssmtStatus = isnull(tas.AdmissionAssmtStatus, ''),
		IsAdmissionAssmtComplete = isnull(tas.IsAdmissionAssmtComplete, 'N'),
		IsIPHomeMedListAssmentCharted = isnull(tas.IsIPHomeMedListAssmentCharted, 'N'),
		IPHomeMedListAssmtStatus = isnull(tas.IPHomeMedListAssmtStatus, ''),
		IsIPHomeMedListAssmtComplete = isnull(tas.IsIPHomeMedListAssmtComplete, 'N'),
		IsVitalsAssmtCharted = isnull(tas.IsVitalsAssmtCharted, 'N') ,
		VitalsAssmtStatus = isnull(tas.VitalsAssmtStatus, '') ,
		ISVitalsAssmtComplete = isnull(tas.ISVitalsAssmtComplete, 'N') ,
		VitalsAssmtCollecteDT = isnull(tas.VitalsAssmtCollectedDT, NULL),
		tov.Oxygen,
		tov.O2Per,
		tov.O2LPM,
		tov.NIHScaleScore,
		tov.NIHScaleScoreCollectedDt,
		tov.TrachTube,
		tov.TubeDrain,
		tov.ATD1Location,
		tov.TubeDrain2,
		tov.ATD2Location,
		tov.IVType1,
		tov.IVType2,
		tov.IVType3,
		tov.IVType4,
		tov.TobaccoUse,
		tov.WDL,
		tov.MorseFallRisk,
		tov.Pneumovax,
		PneuImmunizationDt = ISNULL(tov.PneuImmunizationDt, '')
		--Case ISNULL(tov.PneuImmunizationDt,'')
		--				WHEN '1900-01-01 00:00:00.000'
		--				THEN ''
		--				ELSE ISNULL(tov.PneuImmunizationDt,'')
		--			END
		,
		tov.Influenza,
		InfluImmunizationDt = ISNULL(tov.InfluImmunizationDt, '')
		--Case ISNULL(tov.InfluImmunizationDt,'')
		--						WHEN '1900-01-01 00:00:00.000'
		--						THEN ''
		--						ELSE ISNULL(tov.PneuImmunizationDt,'')
		--					END
		,
		tov.CardiacRhythm,
		tov.RhythmDesc,
		tov.SkinColor,
		tov.SkinTemp,
		tov.SkinMoisture,
		tov.CapillaryRefill,
		tov.CVEdemaNoted,
		tov.AbnormalPulses,
		tov.RecentFalls,
		tov.VentType,
		tov.VentTube,
		tov.ChestTube1Loc,
		tov.ChestTube2Loc,
		tov.ChestTube3Loc,
		tov.PtMedComp,
		tov.PtMedCompCmt,
		tov.PtAttGrps,
		tov.PtAttGrpsCmt,
		tov.TapBell,
		tov.Affect,
		tov.Behavior,
		tov.Cognitive,
		tov.HrsSlept,
		tov.SleepProb,
		tov.BhvrObsLvl,
		tov.BhvrCmt,
		tov.SpirRcrs,
		tov.FamInvolve,
		tov.SpirConcerns,
		tov.SpirConcernsDesc,
		tov.SpirConcernsCmt,
		tov.LastBMDate,
		tov.BreakfastAmt,
		tov.LunchAmt,
		tov.DinnerAmt,
		tov.PatientBelongings,
		tov.Clothing,
		tov.CreditCard,
		tov.WalletHandbag,
		tov.Jewelry,
		tov.Glasses,
		tov.Contacts,
		tov.Dentures,
		tov.HearingAid,
		tov.Crutches,
		tov.ArtificialEye,
		tov.ArtificialArm,
		tov.ArtificialLeg,
		tov.WheelChair,
		tov.CaneWalker,
		tov.Brace,
		tov.OtherHomeItems,
		tov.ClothingCmt,
		tov.CreditCardCmt,
		tov.WalletHandbagCmt,
		tov.JewelryCmt,
		tov.GlassesCmt,
		tov.ContactsCmt,
		tov.DenturesCmt,
		tov.HearingAidCmt,
		tov.CrutchesCmt,
		tov.ArtificialEyeCmt,
		tov.ArtificialArmCmt,
		tov.ArtificialLegCmt,
		tov.WheelChairCmt,
		tov.CaneWalkerCmt,
		tov.BraceCmt,
		tov.OtherHomeItemsCmt,
		tov.BelongingsCmt,
		tov.DNR,
		tov.IV1DCDt,
		tov.IV2DCDt,
		tov.IV3DCDt,
		tov.IV4DCDt,
		tov.ListCoMorb,
		tov.PresSoreSite1,
		tov.PresSoreSite1Other,
		tov.PresSoreSite1Laterality,
		tov.PresSoreSite1Type,
		tov.PresSoreSite1POA,
		tov.PresSoreSite1TypeOther,
		tov.PresSoreSite1DressingCondition,
		tov.PresSoreSite1DressConOther,
		tov.PresSoreSite2,
		tov.PresSoreSite2Other,
		tov.PresSoreSite2Laterality,
		tov.PresSoreSite2Type,
		tov.PresSoreSite2POA,
		tov.PresSoreSite2TypeOther,
		tov.PresSoreSite2DressingCondition,
		tov.PresSoreSite2DressConOther,
		tov.PresSoreSite3,
		tov.PresSoreSite3Other,
		tov.PresSoreSite3Laterality,
		tov.PresSoreSite3Type,
		tov.PresSoreSite3POA,
		tov.PresSoreSite3TypeOther,
		tov.PresSoreSite3DressingCondition,
		tov.PresSoreSite3DressConOther,
		tov.PresSoreSite4,
		tov.PresSoreSite4Other,
		tov.PresSoreSite4Laterality,
		tov.PresSoreSite4Type,
		tov.PresSoreSite4POA,
		tov.PresSoreSite4TypeOther,
		tov.PresSoreSite4DressingCondition,
		tov.PresSoreSite4DressConOther,
		tov.PresSoreSite5,
		tov.PresSoreSite5Other,
		tov.PresSoreSite5Laterality,
		tov.PresSoreSite5Type,
		tov.PresSoreSite5POA,
		tov.PresSoreSite5TypeOther,
		tov.PresSoreSite5DressingCondition,
		tov.PresSoreSite5DressConOther,
		tov.PresSoreSite6,
		tov.PresSoreSite6Other,
		tov.PresSoreSite6Laterality,
		tov.PresSoreSite6Type,
		tov.PresSoreSite6POA,
		tov.PresSoreSite6TypeOther,
		tov.PresSoreSite6DressingCondition,
		tov.PresSoreSite6DressConOther,
		tov.PresSoreSite7,
		tov.PresSoreSite7Other,
		tov.PresSoreSite7Laterality,
		tov.PresSoreSite7Type,
		tov.PresSoreSite7POA,
		tov.PresSoreSite7TypeOther,
		tov.PresSoreSite7DressingCondition,
		tov.PresSoreSite7DressConOther,
		tov.PresSoreSite8,
		tov.PresSoreSite8Other,
		tov.PresSoreSite8Laterality,
		tov.PresSoreSite8Type,
		tov.PresSoreSite8POA,
		tov.PresSoreSite8TypeOther,
		tov.PresSoreSite8DressingCondition,
		tov.PresSoreSite8DressConOther,
		tov.WeightObtainedDT,
		tov.MEWSScore,
		LDIET.LastDietaryOrder,
		LDIET.LastDietaryOrderEnteredDateTime,
		LTELE.LastTelemetryOrder,
		LTELE.LastTeleOrderEnteredDateTime,
		LPT.LastPTOrder,
		LPT.LastPTOrderEnteredDateTime,
		LACT.LastActivityOrder,
		LACT.LastActivityOrderEnteredDateTime,
		[LastActivityOrder2] = LACT2.LastActivityOrder,
		[LastActivityOrderEnteredDateTime2] = LACT2.LastActivityOrderEnteredDateTime,
		[LastActivityOrder3] = LACT3.LastActivityOrder,
		[LastActivityOrderEnteredDateTime3] = LACT3.LastActivityOrderEnteredDateTime,
		[LastActivityOrder4] = LACT4.LastActivityOrder,
		[LastActivityOrderEnteredDateTime4] = LACT4.LastActivityOrderEnteredDateTime,
		LGLUCOSE.LastGlucoseOrder,
		LGLUCOSE.LastGlucoseOrderEnteredDateTime,
		LNEURO.LastNeuroOrder,
		LNEURO.LastNeuroOrderEnteredDateTime,
		IVORDERS.LastIVOrder,
		IVORDERS.LastIVOrderEnteredDateTime,
		GLUCOSERESULT.LastGlucoseResult,
		GLUCOSERESULT.LastGlucoseResultCreationDateTime,
		BEDREST.LastBedrestOrder,
		BEDREST.LastBedrestOrderEnteredDateTime
	FROM @Patient tp
	LEFT OUTER JOIN @pivotObsValues tov ON tp.PatientOID = tov.PatientOID
		AND tp.PatientVisitOID = tov.PatientVisitOID
	LEFT OUTER JOIN @DietModifier tdm ON tdm.PatientOID = tp.PatientOID
		AND tdm.PatientVisitOID = tp.PatientVisitOID
	LEFT OUTER JOIN @pivotAssessmentStatus tas ON tas.PatientOID = tp.PatientOID
		AND tas.PatientVisitOID = tp.PatientVisitOID
	LEFT OUTER JOIN @LastDietaryOrder AS LDIET ON TP.PatientOID = LDIET.PatientOID
		AND TP.PatientVisitOID = LDIET.PatientVisitOID
	LEFT OUTER JOIN @LastTelemetryOrder AS LTELE ON TP.PatientOID = LTELE.PatientOID
		AND TP.PatientVisitOID = LTELE.PatientVisitOID
	LEFT OUTER JOIN @LastPhysicalTherapyOrder as LPT ON TP.PatientOID = LPT.patientOID
		AND TP.PatientVisitOID = LPT.PatientVisitoid
	LEFT OUTER JOIN @LastGlucoseOrder AS LGLUCOSE ON TP.PatientOID = LGLUCOSE.PatientOID
		AND TP.PatientVisitOID = LGLUCOSE.PatientVisitOID
	LEFT OUTER JOIN @LastNeuroCheckOrder AS LNEURO ON TP.PatientOID = LNEURO.PatientOID
		AND TP.PatientVisitOID = LNEURO.PatientVisitOID
	LEFT OUTER JOIN @LastIVOrder AS IVORDERS ON TP.PatientOID = IVORDERS.PatientOID
		AND TP.PatientVisitOID = IVORDERS.PatientVisitOID
	LEFT OUTER JOIN @LastGlucoseResult AS GLUCOSERESULT ON TP.PatientOID = GLUCOSERESULT.PatientOID
		AND TP.PatientVisitOID = GLUCOSERESULT.PatientVisitOID
	LEFT OUTER JOIN @LastBedrestOrder AS BEDREST ON TP.PatientOID = BEDREST.PatientOID
		AND TP.PatientVisitOID = BEDREST.PatientVisitOID
	LEFT OUTER JOIN @LastActivityOrder AS LACT ON TP.PatientOID = LACT.PatientOID
		AND TP.PatientVisitOID = LACT.patientvisitoid
		AND LACT.OrderNumber = 1
	-- SECOND ORDER
	LEFT OUTER JOIN @LastActivityOrder AS LACT2 ON LACT.PatientOID = LACT2.PatientOID
		AND LACT.PatientVisitOID = LACT2.PatientVisitOID
		AND LACT2.OrderNumber = 2
	-- THIRD ORDER
	LEFT OUTER JOIN @LastActivityOrder AS LACT3 ON LACT.PatientOID = LACT3.PatientOID
		AND LACT.PatientVisitOID = LACT3.PatientVisitOID
		AND LACT3.OrderNumber = 3
	-- Forth Order
	LEFT OUTER JOIN @LastActivityOrder AS LACT4 ON LACT.PatientOID = LACT4.PatientOID
		AND LACT.PatientVisitOID = LACT4.PatientVisitOID
		AND LACT4.OrderNumber = 4
	ORDER BY tp.PatientName
END
