USE [Soarian_Clin_Tst_1]
GO

/****** Object:  StoredProcedure [dbo].[ORE_BMH_CPOE_Signed_Unsigned_EDR_V2]    Script Date: 5/8/2019 9:37:36 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
      
File: ORE_CPOE_Signed_Unsigned_EDRPrc.sql          
       
Input Tables: HPatientVisit          
  HHealthCareUnit          
  HPreferenceValue          
  HOrderStatus          
  HOrder          
  HServiceDetail          
   HMedOrder          
   HOrderSuppInfo          
   HPatient          
   HPerson          
   HOrderTransitionRecord          
   HBedTransfer          

Views:          
            
            
Functions:          
   .dbo.fn_ORE_GetExternalPatientID           
   .dbo.fn_ORE_GetPatientAge          
   .dbo.Fn_ORE_GetPatientAllergies          
   .dbo.fn_ORE_GetPhysicianName          
   .dbo.fn_ORE_VisitAllergiesCheck          
   .dbo.fn_ORE_GetEnterprisename          
   .dbo.fn_GetStrParmTable           

Purpose:  This procedure will retrieve Unsigned Orders  at Discharge for patients.           
          The report can be run from CSP,JS and OPR usages.           
            
Input  Parameters:
    @VisitObjectID as Visit OID           
    @EntityID varchar(10)          
          
Revision History:          
          
Date        Author          Description          
----        ------          --------------------------------------------------------
05-08-19    ssanderson      Initial Creation to duplicate to crystal sp for reporting

Example Run:
    Exec ORE_BMH_CPOE_Signed_Unsigned_EDR_V2_test '134053','2'

*/
ALTER PROCEDURE [dbo].[ORE_BMH_CPOE_Signed_Unsigned_EDR_V2] @VisitObjectID VARCHAR(20) = NULL,
	@EntityID VARCHAR(10)
AS
SET NOCOUNT ON

BEGIN
	DECLARE @iEntityOID INT,
		@iUserOID INT,
		@iPatientOID INT,
		@iVisitOID INT,
		@vchOrderOID VARCHAR(2000),
		@vchEnterpriseName VARCHAR(75),
		@vchEntityName VARCHAR(75),
		@iVerbalOrderLevel INT,
    @iRecCount INTEGER,
    @vchCoSignUsers VARCHAR(2000),
		@vchSignedBy VARCHAR(184),
		@vchStaff VARCHAR(184),
		@vchcosigndate DATETIME,
		@cosigndate DATETIME,
		@iCoSignUserLevel INT
	
    ---Table to Store Selected OrderOIDs          
	DECLARE @tblOrdersOID TABLE (OrderOID INT)
	
    ---Table to Store Selected patient visits           
	DECLARE @tblPatientVisitDetails TABLE (
		PatientVisit_OID INT,
		Patient_OID INT,
		VisitEndDateTime DATETIME
		)
	
    ---Table to Store NonMedOrderStatus          
	DECLARE @tblNonMedOrdStatCode TABLE (OrderStatusCode SMALLINT)

	--Table to Store MedOrderStatusCodes          
	DECLARE @tblMedOrdStatCode TABLE (OrderStatusCode SMALLINT)

	--Table to Store MedOrderStatus          
	DECLARE @tblMedOrderStatus TABLE (OrderStatus VARCHAR(30))

	--Table to store cosigned users          
	DECLARE @tblCoSignUsers TABLE (
		OrderOID INT,
		SignedBy VARCHAR(184),
		CoSignedUsers VARCHAR(2000),
		signeddate DATETIME
		)
        
	--Table to store PatientDetails for the Patient header in the report          
	DECLARE @tblPatientDetails TABLE (
		FirstName VARCHAR(30),
		MiddleName VARCHAR(30),
		LastName VARCHAR(92),
		Title VARCHAR(64),
		BirthDate DATETIME,
		PatientAccountID VARCHAR(20),
		InternalPatientID VARCHAR(20),
		MRNumber VARCHAR(30),
		Age VARCHAR(10),
		Sex VARCHAR(8),
		AttnDr VARCHAR(184),
		AdmtDr VARCHAR(184),
		DschDr VARCHAR(184),
		Allergies VARCHAR(1000),
		PrimaryWrkDxDsch VARCHAR(2000),
		PrimWrkDxAdmt VARCHAR(2000),
		DisChgVstStartDT DATETIME,
		DisChgVstEndDT DATETIME,
		DisChgVisitStatus TINYINT,
		DisChgVisitTypeCode VARCHAR(30),
		DisChgRoomBed VARCHAR(75),
		DisChgLocationName VARCHAR(75),
		TypeCode INT,
		DischargeTypeCode VARCHAR(64),
		DscChgVisit_OID INT,
		DscChgVisitID VARCHAR(30),
		DscChgVstCatg VARCHAR(64),
		DscChgUnitName VARCHAR(75),
		DscChgVstLoc VARCHAR(64),
		DscChgEntName VARCHAR(75),
		DscChgEntAbb VARCHAR(10),
		DscChgUnit_OID INT,
		DscChgRefInst_OID INT,
		DscChgPtLocation_OID INT,
		PatientClass_OID INT,
		DscChgEnt_OID INT,
		DischargeFormID INT,
		DischargeTo VARCHAR(64),
		AdmissionType VARCHAR(64),
		ReasonforDischarge VARCHAR(64),
		StartingVisitOID INT,
		PatientStatusCode VARCHAR(255),
		Patient_OID INT,
		EnterpriseName VARCHAR(75),
		UserOID INT,
		EntityName VARCHAR(75),
		AltVisitID VARCHAR(20),
		DscUnitContacted VARCHAR(75)
		)

	--Check incoming parameter @VisitObjectID          
	IF isnumeric(@VisitObjectID) = 1
		SET @iVisitOID = cast(@VisitObjectID AS INT)
	ELSE
		SET @iVisitOID = - 1

	SELECT @vchEntityName = HealthcareUnitName
	FROM hhealthcareunit
	WHERE ObjectID = @EntityID

	--Enterprise information          
	SET @vchEnterpriseName = isnull(.dbo.fn_ORE_GetEnterprisename(), '')

	--NonMedication Orders statuses          
	INSERT INTO @tblNonMedOrdStatCode
	VALUES (1)

	INSERT INTO @tblNonMedOrdStatCode
	VALUES (2)

	INSERT INTO @tblNonMedOrdStatCode
	VALUES (3)

	INSERT INTO @tblNonMedOrdStatCode
	VALUES (4)

	INSERT INTO @tblNonMedOrdStatCode
	VALUES (5)

	INSERT INTO @tblNonMedOrdStatCode
	VALUES (6)

	INSERT INTO @tblNonMedOrdStatCode
	VALUES (8)

	INSERT INTO @tblNonMedOrdStatCode
	VALUES (9)

	INSERT INTO @tblNonMedOrdStatCode
	VALUES (10)

	--Medication Orders statuses          
	INSERT INTO @tblMedOrdStatCode
	VALUES (0)

	INSERT INTO @tblMedOrdStatCode
	VALUES (1)

	INSERT INTO @tblMedOrdStatCode
	VALUES (2)

	INSERT INTO @tblMedOrdStatCode
	VALUES (3)

	INSERT INTO @tblMedOrdStatCode
	VALUES (4)

	INSERT INTO @tblMedOrdStatCode
	VALUES (5)

	INSERT INTO @tblMedOrdStatCode
	VALUES (6)

	--INSERT INTO @tblMedOrdStatCode Values(8)          
	INSERT INTO @tblMedOrdStatCode
	VALUES (9)

	INSERT INTO @tblMedOrdStatCode
	VALUES (10)

	INSERT INTO @tblMedOrdStatCode
	VALUES (11)

	BEGIN
		--INSERT into @tblPatientDetails         
		SELECT FirstName = IsNull(HPatient.FirstName, ''),
			MiddleName = IsNull(HPatient.MiddleName, ''),
			--  LastName                 = IsNull(HPatient.LastName, ''),          
			LastName = CASE ISNULL(HPatient.GenerationQualifier, '')
				WHEN ''
					THEN HPatient.LastName
				ELSE HPatient.LastName + ' ' + HPatient.GenerationQualifier
				END,
			Title = IsNull(HPatient.Title, ''),
			BirthDate = HPerson.BirthDate,
			PatientAccountID = IsNull(HPatientVisit.PatientAccountID, ''),
			InternalPatientID = IsNull(HPatient.InternalPatientID, ''),
			MRNumber = IsNull(.dbo.fn_ORE_GetExternalPatientID(HPatientVisit.Patient_OID, IsNull(HPatientVisit.Entity_OID, @iEntityOID)), ''),
			Age = (.dbo.fn_ORE_GetPatientAge(HPerson.BirthDate, GetDate())),
			Sex = Cast(CASE HPerson.Sex
					WHEN 0
						THEN 'M'
					WHEN 1
						THEN 'F'
					WHEN 2
						THEN 'O'
					WHEN 3
						THEN 'U'
					WHEN 4
						THEN 'A'
					WHEN 5
						THEN 'N'
					ELSE ''
					END AS VARCHAR(8)),
			AttnDr = IsNull(.dbo.fn_ORE_GetPhysicianName(HPatientVisit.ObjectID, 0, 6), ''),
			AdmtDr = IsNull(.dbo.fn_ORE_GetPhysicianName(HPatientVisit.ObjectID, 4, 6), ''),
			DschDr = IsNull(.dbo.fn_ORE_GetPhysicianName(HPatientVisit.ObjectID, 6, 6), ''),
			Allergies = IsNull(dbo.Fn_ORE_GetPatientAllergies(HPatientVisit.Patient_OID), IsNull(.dbo.fn_ORE_VisitAllergiesCheck(HPatientVisit.Patient_OID, HPatientVisit.ObjectID), '')),
			PrimaryWrkDxDsch = IsNull(.dbo.fn_ORE_GetPatientDiagnosis(HPatientVisit.ObjectID, 3, 0, 1), ''),
			PrimWrkDxAdmt = IsNull(.dbo.fn_ORE_GetPatientDiagnosis(HPatientVisit.ObjectID, 1, 0, 1), ''),
			DisChgVstStartDT = HPatientVisit.VisitStartDateTime,
			DisChgVstEndDT = HPatientVisit.VisitEndDateTime,
			DisChgVisitStatus = HPatientVisit.VisitStatus,
			DisChgVisitTypeCode = IsNull(HPatientVisit.VisitTypeCode, ''),
			DisChgRoomBed = IsNull(HBedTransfer.FromBedName, ''),
			DisChgLocationName = IsNull(HHealthCareunit.HealthcareUnitName, ''),
			TypeCode = HPatientVisit.TypeCode,
			DischargeTypeCode = IsNull(HPatientVisit.DischargeTypeCode, ''),
			DscChgVisit_OID = HPatientVisit.ObjectID,
			DscChgVisitID = IsNull(HPatientVisit.VisitID, ''),
			DscChgVstCatg = IsNull(HPatientVisit.VisitCategory, ''),
			DscChgUnitName = IsNull(HPatientVisit.UnitContactedName, ''),
			DscChgVstLoc = IsNull(HPatientVisit.VisitLocation, ''),
			DscChgEntName = IsNull(HPatientVisit.EntityName, ''),
			DscChgEntAbb = IsNull(HPatientVisit.EntityAbb, ''),
			DscChgUnit_OID = HPatientVisit.UnitContacted_oid,
			DscUnitContacted = IsNull(HPatientVisit.UnitContactedName, ''),
			DscChgRefInst_OID = HPatientVisit.ReferringInstitution_oid,
			DscChgPtLocation_OID = IsNull(HBedTransfer.FromLocation_OID, 0),
			PatientClass_OID = HPatientVisit.PatientClass_oid,
			DscChgEnt_OID = HPatientVisit.Entity_oid,
			DischargeFormID = HPatientVisit.DischargeFormID,
			DischargeTo = IsNull(HPatientVisit.DischargeTo, ''),
			AdmissionType = IsNull(HPatientVisit.AdmissionType, ''),
			ReasonforDischarge = IsNull(HPatientVisit.ReasonforDischarge, ''),
			StartingVisitOID = HPatientVisit.StartingVisitOID,
			PatientStatusCode = IsNull(HPatientVisit.PatientStatusCode, ''),
			Patient_OID = HPatientVisit.Patient_OID,
			EnterpriseName = @vchEnterpriseName,
			UserOID = @iUserOID,
			EntityName = @vchEntityName,
			AltvisitID = IsNull(HPatientVisit.AlternateVisitID, '')
		INTO #tblPatientDetails
		FROM HPatientVisit WITH (NOLOCK)
		INNER JOIN HPatient WITH (NOLOCK) ON HPatient.ObjectID = HPatientVisit.Patient_OID
			AND HPatient.iSDeleted = 0
		INNER JOIN HPerson WITH (NOLOCK) ON HPerson.ObjectID = HPatient.ObjectID
			AND HPerson.IsDeleted = 0
		LEFT OUTER JOIN HBedTransfer WITH (NOLOCK) ON HBedTransfer.PatientVisit_OID = HPatientVisit.ObjectID
			--  AND HBedTransfer.FromDate=(select max(HBedTransfer.FromDate) from HBedTransfer           
			--  where HBedTransfer.PatientVisit_OID=@iVisitOID)             
			AND HBedTransfer.toDate = HPatientVisit.visitenddatetime
		LEFT OUTER JOIN HHealthCareunit WITH (NOLOCK) ON HHealthCareunit.ObjectID = HBedTransfer.FromLocation_OID
		WHERE HPatientVisit.ObjectID = @iVisitOID
			AND HPatientVisit.IsDeleted = 0

		INSERT INTO @tblPatientVisitDetails
		SELECT DscChgVisit_OID,
			Patient_OID,
			DisChgVstEndDT
		FROM #tblPatientDetails
			--select * from @tblPatientVisitDetails
			--select distinct           
	END

	BEGIN
		SELECT DISTINCT OrderOID = HO.ObjectID,
			OrderID = HO.OrderID,
			OrderName = HO.OrderName,
			OrderDescAsWritten = HO.OrderDescAsWritten,
			OrderStatusCode = CASE HO.OrderStatusCode
				WHEN 1
					THEN 'Inactive'
				WHEN 2
					THEN 'Active'
				WHEN 3
					THEN 'In Progress'
				WHEN 4
					THEN 'Complete'
				WHEN 5
					THEN 'Suspend'
				WHEN 6
					THEN 'Cancel'
				WHEN 8
					THEN 'Discontinue'
				WHEN 9
					THEN 'Draft'
				WHEN 10
					THEN 'Pending Activation'
				END,
			StatusEnteredDateTime = HO.StatusEnteredDateTime,
			OrderStatusModifier = HO.OrderStatusModifier,
			OrderStatusModifierCode = HO.OrderStatusModifierCode,
			OrderAbbreviation = HO.OrderAbbreviation,
			OrderTypeAbbr = HO.OrderTypeAbbr,
			OrderSubTypeAbbr = HO.OrderSubTypeAbbr,
			RequestorUnitAbbr = HO.RequestorUnitAbbr,
			ProviderUnitAbbr = HO.ProviderUnitAbbr,
			RequestedBy = HO.RequestedBy,
			ProvidedBy = HO.ProvidedBy,
			EnteredBy = HO.EnteredBy,
			EnteredBy_FirstName = IsNull(HName.FirstName, ''),
			EnteredBy_MiddleName = IsNull(HName.MiddleName, ''),
			EnteredBy_LastName = IsNull(HName.LastName, ''),
			EnteredBy_Title = IsNull(HName.Title, ''),
			EnteredDateTime = HO.EnteredDateTime,
			StartDateTime = HO.StartDateTime,
			StopDateTime = HO.StopDateTime,
			AcknowledgeRequired = HO.AcknowledgeRequired,
			DuplicateOverriden = HO.DuplicateOverriden,
			OrderFunctionCode = HO.OrderFunctionCode,
			--  ToBeCosignedBy  = HO.ToBeCosignedBy,          
			ToBeCosignedBy = ' ',
			IsCoSigned = HO.IsCoSigned,
			AdditionalSignReqd = HO.AdditionalSignReqd,
			SignedNumber = HO.SignedNumber,
			OrderHistoryGroupID = HO.OrderHistoryGroupID,
			ActSignNo = HO.ActSignNo,
			Patient_oid = HO.Patient_oid,
			PatientVisit_oid = HO.PatientVisit_oid,
			IsAcknowledged = HO.IsAcknowledged,
			OrderTypeCode = HO.OrderTypeCode,
			OrderTypeIdentifier = HO.OrderTypeIdentifier,
			IVMethodTypeCode = HO.IVMethodTypeCode,
			OrdModifierAbbr = HO.OrdModifierAbbr,
			OrderSetID = HO.OrderSetID,
			OrderSetAbbrv = HO.OrderSetAbbrv,
			CommonDefName = HO.CommonDefName,
			OrderReasons_oid = HO.OrderReasons_oid,
			OrderSubTypeCode = HO.OrderSubTypeCode,
			Requestedby_oid = HO.Requestedby_oid,
			SupervisedBy_StaffOID = HO.SupervisedBy_StaffOID,
			SupervisedByStaff = HO.SupervisedByStaff,
			LevelofSigForActive = CASE HO.OrderTypeIdentifier --Min active level sign reqd          
				WHEN 'DG'
					THEN HSD.LevelofSignatureForActive
				WHEN 'MD'
					THEN HMO.ActivateLevelRequired
				END,
			NumberofSignature = CASE HO.OrderTypeIdentifier
				WHEN 'DG'
					THEN CASE HSD.CoSignatureRequired --Total signs reqd            
							WHEN 0
								THEN 1 -- this will be a verbal order          
							WHEN 1
								THEN HSD.NumberofSignature
							END
				WHEN 'MD'
					THEN CASE HMO.CoSignRequired --Total signs reqd            
							WHEN 0
								THEN 1 -- this will be a verbal order          
							WHEN 1
								THEN HMO.NbrOfSignatures
							END
				END,
			LevelofSignature = CASE HO.OrderTypeIdentifier --Level of Signature reqd          
				WHEN 'DG'
					THEN CASE HSD.CoSignatureRequired
							WHEN 0
								THEN CASE IsNull(HSI.VerbalOrderIndicator, 0)
										WHEN 0
											THEN 0
										WHEN 1
											THEN isnull(EntityPref.PreferenceValue, isnull(EnterprisePref.PreferenceValue, 0)) -- this will be a verbal order level          
										END
							WHEN 1
								THEN HSD.LevelofSignature --Total cosigns reqd          
							END
				WHEN 'MD'
					THEN CASE HMO.CoSignRequired
							WHEN 0
								THEN CASE IsNull(HSI.VerbalOrderIndicator, 0)
										WHEN 0
											THEN 0
										WHEN 1
											THEN isnull(EntityPref.PreferenceValue, isnull(EnterprisePref.PreferenceValue, 0)) -- this will be a verbal order level          
										END
							WHEN 1
								THEN HMO.CoSignLevelRequired --Total cosigns reqd          
							END
				END,
			NoOfCosignsReqd = CASE HO.OrderTypeIdentifier --Total signs reqd          
				WHEN 'DG'
					THEN CASE HSD.CoSignatureRequired
							WHEN 0
								THEN 1 -- this will be a verbal order,only 1 will be reqd          
									--A case that arises here when an order with Cosign level defined is ordered.After ordering the cosignlevel definiton is removed for the service.          
									--In this case HSD.CoSignatureRequired will be zero and one addtl sign is reqd          
							WHEN 1
								THEN CASE -- No of cosigns remaining          
										WHEN (cast(isnull(HSD.NumberofSignature, 0) AS INT) - cast(isnull(HO.SignedNumber, 0) AS INT)) <= 0
											THEN 1
										ELSE (cast(isnull(HSD.NumberofSignature, 0) AS INT) - cast(isnull(HO.SignedNumber, 0) AS INT))
										END
							END
				WHEN 'MD'
					THEN CASE HMO.CoSignRequired
							WHEN 0
								THEN 1 -- this will be a verbal order,only 1 will be reqd          
							WHEN 1
								THEN CASE -- No of cosigns remaining          
										WHEN (cast(isnull(HMO.NbrOfSignatures, 0) AS INT) - cast(isNull(HMO.CoSignedNumber, 0) AS INT)) <= 0
											THEN 1
										ELSE (cast(isnull(HMO.NbrOfSignatures, 0) AS INT) - cast(isNull(HMO.CoSignedNumber, 0) AS INT))
										END
							END
				END,
			VerbalOrderIndicator = IsNull(HSI.VerbalOrderIndicator, 0),
			/* CASE HO.OrderTypeIdentifier           
      WHEN 'DG' THEN          
       IsNull(HSI.VerbalOrderIndicator,0)          
      WHEN 'MD' THEN          
       IsNull(HMO.VerbalIndicator,0)          
      END,    */
			VerbalOrderReason = HSI.OrderSourceModifierName, -- HSI.VerbalOrderReason,          
			HSI.OrderSourceAbbr, --(DK) Added to print          
			--Med Orders          
			MedObjectID = HMO.ObjectID,
			MedRecordId = HMO.RecordId,
			MedValidFrom = HMO.ValidFrom,
			MedValidTo = HMO.ValidTo,
			MedInternalID = HMO.InternalID,
			MedExternalID = HMO.ExternalID,
			MedOrderAsWritten = HMO.OrderAsWritten,
			MedOrderStatus = CASE HMO.MedOrderStatus
				WHEN 0
					THEN 'Draft'
				WHEN 1
					THEN 'Inactive'
				WHEN 2
					THEN 'Active'
				WHEN 3
					THEN 'Suspended From Inactive'
				WHEN 4
					THEN 'Suspended From Active'
				WHEN 5
					THEN 'Suspended From Progress'
				WHEN 6
					THEN 'In Progress'
				WHEN 8
					THEN 'Cancel'
				WHEN 9
					THEN 'Discontinue'
				WHEN 10
					THEN 'Complete'
				WHEN 11
					THEN 'Pending Activation'
				END,
			MedMedOrderType = HMO.MedOrderType,
			MedStartDateTime = HMO.StartDateTime,
			MedStopDateTime = HMO.StopDateTime,
			MedDuration = HMO.Duration,
			MedDischargeIndicator = HMO.DischargeIndicator,
			MedPRNIndicator = HMO.PRNIndicator,
			MedCoSignLevelRequired = HMO.CoSignLevelRequired,
			MedPerformedByPatient = HMO.PerformedByPatient,
			MedRequestedBy_oid = HMO.RequestedBy_oid,
			MedSignedBy_oid = HMO.SignedBy_oid,
			MedEnteredBy_oid = HMO.EnteredBy_oid,
			MedPatient_oid = HMO.Patient_oid,
			MedPatientVisit_oid = HMO.PatientVisit_oid,
			MedMedOrderSet_oid = HMO.MedOrderSet_oid,
			MedRequestorUnit_oid = HMO.RequestorUnit_oid,
			MedProviderUnit_oid = HMO.ProviderUnit_oid,
			MedNbrOfSignatures = HMO.NbrOfSignatures,
			MedPRNCondition = HMO.PRNCondition,
			MedIsCoSigned = HMO.IsCoSigned,
			MedCoSignRequired = HMO.CoSignRequired,
			MedActSignedNumber = HMO.ActSignedNumber,
			MedCoSignedNumber = HMO.CoSignedNumber,
			MedActvLvlReqd = HMO.ActivateLevelRequired,
			MedPriorityString = HMO.PriorityString,
			MedPriorityCode = HMO.PriorityCode,
			MedIsFromOrderSet = HMO.IsCreatedFromOrderSet,
			MedOriginalOrderID = HMO.OriginalOrderID,
			MedOrderHistGroupID = HMO.OrderHistoryGroupID,
			MedMedFunctionCode = HMO.MedFunctionCode,
			MedMedOrderStatus = HMO.MedOrderStatus,
			MedMedOrderStDateTime = HMO.MedOrderStatusDateTime,
			MedMedOrderStModifier = HMO.MedOrderStatusModifier,
			MedVerbalIndicator = HMO.VerbalIndicator,
			MedSrvReqBy_StName = HMO.ServiceRequestedBy_StaffName,
			MedSrvReqHCU_HCUAbbr = HMO.ServiceRequestorHCU_HCUAbbrev,
			--HPatientVisit   (OrderVisit Details)          
			VisitStartDateTime = HPV.VisitStartDateTime,
			VisitEndDateTime = HPV.VisitEndDateTime,
			VisitStatus = HPV.VisitStatus,
			VisitTypeCode = IsNull(HPV.VisitTypeCode, ''),
			VisitCategory = IsNull(HPV.VisitCategory, ''),
			NonMedCosignReqd = HSD.CoSignatureRequired,
			NonMedSignForAct = HSD.LevelofSignatureForActive,
			NonMedNoOfSign = HSD.NumberofSignature,
			NonMedLevelOfSign = HSD.LevelofSignature,
			NonMedSignedNo = HO.SignedNumber,
			--(DK) added signedby          
			SignedBy = (
				SELECT TOP 1 HTR2.FunctionByStaff
				FROM HOrderTransitionRecord HTR2
				WHERE HTR2.Order_OID = HO.Objectid
				ORDER BY CreationTime ASC
				),
			TargetCosigner1StaffName = HSI.TargetCosigner1StaffName --(DK) Added field          
			,
			OrderSourceModifierName = CASE 
				WHEN ho.OrderTypeAbbr = 'Medication/IV'
					THEN HMSI.OrderSourceModifierName
				ELSE HSI.OrderSourceModifierName
				END
			--Added Anita  
			,
			DiscontinueReason = CASE 
				WHEN ho.OrderTypeAbbr = 'Medication/IV'
					THEN Hmoh.Reason
				ELSE ISNULL(HOTR.ReasonForRevision, '')
				END --Commented on 29-DEC-2011   
			-- , DiscontinuedBy= case when ho.OrderTypeAbbr='Medication/IV' then HMOH.RevisedBy else ISNULL(HOTR.RequestedBy,'')  end  
			,
			DiscontinuedBy = ISNULL(HOTR.RequestedBy, '')
			-- , DiscontinuedDateTime=case when ho.OrderTypeAbbr='Medication/IV' then HMOH.ValidFrom else ISNULL(HOTR.ChangedDateTime,'')   end        
			,
			DiscontinuedDateTime = ISNULL(HOTR.ChangedDateTime, '')
			--Added Anita    
			,
			ReasonForRejection = '' --ISNULL(HOTR.ReasonForRevision,'')    --Commented on 29-DEC-2011  
			,
			ReasonforRequest = HSI.ReasonforRequest,
			ReasonForDiscontinue = HSI.ReasonForDiscontinue,
			CreationTime = ISNULL(HO.CreationTime, '')
			-- add revised by sps 4-1-2019 
			,
			RevisedBy = ho.RevisedBy
		-- end edit 
		INTO #UnsignedOrders
		FROM HOrder HO WITH (NOLOCK)
		INNER JOIN HServiceDetail HSD WITH (NOLOCK) ON HO.ServiceDetail_OID = HSD.ObjectId
		LEFT OUTER JOIN HMedOrder HMO WITH (NOLOCK) ON HO.ObjectID = HMO.InternalID
		LEFT OUTER JOIN HOrderSuppInfo HSI WITH (NOLOCK) ON HO.OrderSuppInfo_OID = HSI.ObjectID
		--Vinutha - Added to get Order source modifier for Med Orders  
		LEFT OUTER JOIN HMedOrderSuppInfo HMSI WITH (NOLOCK) ON HMO.Objectid = HMSI.MedOrderOID
		--Vinutha - Added to get Order source modifier for Med Orders  
		INNER JOIN HPatientVisit HPV WITH (NOLOCK) ON HO.PatientVisit_OID = HPV.ObjectID
			AND HO.Patient_oid = HPV.Patient_oid
		INNER JOIN @tblPatientVisitDetails PtDtls ON HO.Patient_OID = PtDtls.Patient_OID
			AND HO.PatientVisit_OID = PtDtls.PatientVisit_OID
		LEFT OUTER JOIN HPreferenceValue EntityPref WITH (NOLOCK) ON EntityPref.EntityId = HPV.Entity_OID
			AND EntityPref.PreferenceID = 1091
		LEFT OUTER JOIN HPreferenceValue EnterprisePref WITH (NOLOCK) ON EnterprisePref.EntityType = 1
			AND EnterprisePref.PreferenceID = 1091
		LEFT OUTER JOIN HSUser HSUser WITH (NOLOCK) ON HO.EnteredBy = HSUser.UserName
			AND HSUser.Person_OID IS NOT NULL
			AND HSUser.LastLogonTime IS NOT NULL
			AND HSUser.IsDeleted = 0
		LEFT OUTER JOIN HName HName WITH (NOLOCK) ON HSUser.Person_oid = HName.Person_oid
			AND (
				HName.EndDateOfValidity IS NULL
				OR HName.EndDateOfValidity = '1899-12-30 00:00:00'
				)
		--Added to get Discontinued datetime, and discontinued by details  
		LEFT OUTER JOIN HOrderTransitionRecord HOTR WITH (NOLOCK) -- Non Med orders  
			ON HO.ObjectID = HOTR.Order_oid
			AND HOTR.OrderFunctionCode = '5'
		LEFT OUTER JOIN HMedorderH HMOH WITH (NOLOCK) -- Med  orders   
			ON HO.ObjectID = HMOH.InternalID
			AND HMOH.MedFunctionCode = '2'
		--Added to get Discontinued datetime, and discontinued by details  
		-- WHERE   HO.IsCosigned=0 and HO.AdditionalSignReqd=1 AND          
		WHERE (
				(
					HO.OrderTypeIdentifier = 'DG'
					AND HO.OrderStatusCode IN (
						SELECT OrderStatusCode
						FROM @tblNonMedOrdStatCode
						)
					)
				OR (
					HO.OrderTypeIdentifier = 'MD'
					AND HMO.MedOrderStatus IN (
						SELECT OrderStatusCode
						FROM @tblMedOrdStatCode
						)
					)
				)
			--(DK) only capture Verbal and written orders          
			-- AND HSI.OrderSourceAbbr in ('VERB','WRTN')          
			--  AND HSI.VerbalOrderIndicator=1 --DK Only select verbal orders          
			--  AND HO.IsExpired=0          
	END

	--select '#UnsignedOrders',* from  #UnsignedOrders    
	--select * from #UnsignedOrders  where Orderoid='21968257'
	--cursor for OrderOIDs           
	DECLARE OrdersOID CURSOR
	FOR
	SELECT DISTINCT OrderOID
	FROM #UnsignedOrders

	OPEN OrdersOID

	FETCH NEXT
	FROM OrdersOID
	INTO @vchOrderOID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @vchCoSignUsers = ''
		SET @vchSignedBy = ''
		SET @vchcosigndate = NULL
		SET @vchSignedBy = (
				SELECT TOP 1 HTR.FunctionByStaff
				FROM HOrderTransitionRecord HTR WITH (NOLOCK)
				WHERE HTR.Order_OID = @vchOrderOID
				ORDER BY CreationTime ASC
				)

		--cursor for users who signed the orderoid          
		DECLARE CoSignUsers CURSOR
		FOR
		SELECT HTR.FunctionByStaff,
			HTR.ChangedDateTime
		FROM HOrderTransitionRecord HTR WITH (NOLOCK)
		WHERE HTR.Order_OID = @vchOrderOID
			AND HTR.OrderFunctionCode = 3
		ORDER BY ChangedDateTime ASC

		OPEN CoSignUsers

		FETCH NEXT
		FROM CoSignUsers
		INTO @vchStaff,
			@cosigndate

		--  Fetch Next FROM CoSignUsers into @vchStaff,@iCoSignUserLevel           
		WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN
				IF @vchCoSignUsers = ''
				BEGIN
					SET @vchCoSignUsers = @vchStaff
					SET @vchcosigndate = @cosigndate
				END
				ELSE
				BEGIN
					SET @vchCoSignUsers = @vchCoSignUsers + ',' + @vchStaff
						--     SET @vchCoSignUsers= @vchCoSignUsers + @vchStaff + '('+ @iCoSignUserLevel + '),'            
				END
			END

			FETCH NEXT
			FROM CoSignUsers
			INTO @vchStaff,
				@cosigndate
				--   Fetch Next FROM CoSignUsers into @vchStaff,@iCoSignUserLevel           
		END

		CLOSE CoSignUsers

		DEALLOCATE CoSignUsers

		INSERT INTO @tblCoSignUsers
		VALUES (
			@vchOrderOID,
			@vchSignedBy,
			@vchCoSignUsers,
			@vchcosigndate
			)

		FETCH NEXT
		FROM OrdersOID
		INTO @vchOrderOID
	END

	CLOSE OrdersOID

	DEALLOCATE OrdersOID

	--select * from @tblCoSignUsers  where Orderoid='21968257'
	-- 29-DEC-2011, Uncommented raise error condition  
	SET @iRecCount = (
			SELECT count(*)
			FROM #tblPatientDetails A
			INNER JOIN #UnsignedOrders B ON A.Patient_OID = B.Patient_OID
			INNER JOIN @tblCoSignUsers C ON B.OrderOID = C.OrderOID
			-- WHERE (A.DisChgVisitTypeCode NOT IN ('EOP'))          
			--   Or (A.DscUnitContacted = 'Observation'))
			WHERE (
					(
						A.DscUnitContacted IN ('Observation', 'Emergency OR')
						AND A.DisChgVisitTypeCode = 'EOP'
						)
					OR A.DisChgVisitTypeCode <> 'EOP'
					)
			)

	IF @iRecCount = 0
	BEGIN
		RAISERROR (
				'OMSErrorNo=[5150], OMSErrorDesc=[No Records Found].',
				16,
				1
				)

		RETURN
	END

	-- 29-DEC-2011, Uncommented raise error condition     
	--Select all           
	SELECT DISTINCT A.*,
		B.*,
		C.SignedBy,
		C.CoSignedUsers,
		C.signeddate
	FROM #tblPatientDetails A
	INNER JOIN #UnsignedOrders B ON A.Patient_OID = B.Patient_OID
	INNER JOIN @tblCoSignUsers C ON B.OrderOID = C.OrderOID
	--WHERE (A.DisChgVisitTypeCode NOT IN ('EOP')         
	-- Or (A.DscUnitContacted = 'Observation'))
	WHERE (
			(
				A.DscUnitContacted IN ('Observation', 'Emergency OR')
				AND A.DisChgVisitTypeCode = 'EOP'
				)
			OR A.DisChgVisitTypeCode <> 'EOP'
			)
END
	/*
1. Everything that is NOT EOP
2. See All Observations
3. See Observations that are also EOP
*/
