USE [Soarian_Clin_Tst_1]
GO
/****** Object:  StoredProcedure [dbo].[ORE_BMH_IsolationIndicator]    Script Date: 3/16/2020 11:28:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 /*
***********************************************************************
File: ORE_BMH_IsolationIndicator.sql

Input Parameters:
	@HSF_CONTEXT_PATIENTID  - Patient ID          
    @VisitOID               - Visit ID    
    @HSF_SESSION_USEROID  - User ID  

Tables/Views:
    HPatient    
    HPatientVisit    
    HPerson    
    HAssessment    
    HAssessmentCategory    
    HAssessmentFormElement    
    HObservation

Creates Table:
	Enter Here

Functions:
	fn_ORE_GetPatientAllergies

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Entere Here

Revision History:
Date		Version		Description
----		----		----
2020-03-16  v1          Add First Initial of First and Last Name of PT
***********************************************************************
*/ 
    
--  exec ORE_BMH_IsolationIndicator '1871946','87215','','Brookhaven Memorial Hospital','','1'  
--  exec ORE_BMH_IsolationIndicator '','','','Brookhaven Memorial Hospital','3NOR','2'  

ALTER PROCEDURE [dbo].[ORE_BMH_IsolationIndicator] @HSF_CONTEXT_PATIENTID VARCHAR(20) = NULL,
	@VisitOID VARCHAR(20) = NULL,
	@HSF_SESSION_USEROID VARCHAR(20) = NULL,
	@Entity VARCHAR(75) = NULL,
	@pvchLocation VARCHAR(2000) = NULL,
	@pchReportUsage VARCHAR(1)
AS
BEGIN
	DECLARE @iPatientOID INT,
		@iVisitOID INT,
		@iUserOID INT,
		@vchReportUserName VARCHAR(184),
		@chLocation CHAR(3)
	DECLARE @tblPatientOID TABLE (
		PatientOID INT,
		VisitOID INT
		)
	DECLARE @tblLocation TABLE (Location VARCHAR(75) PRIMARY KEY (location))
    DECLARE @PatientNameTbl TABLE(
        Patient_OID INT,
        PatientVisit_OID INT,
        FirstName VARCHAR(250),
        MiddleName VARCHAR(250),
        LastName VARCHAR(250)
    )

	IF isnumeric(@HSF_CONTEXT_PATIENTID) = 1
		SET @iPatientOID = cast(@HSF_CONTEXT_PATIENTID AS INT)
	ELSE
		SET @iPatientOID = - 1

	IF isnumeric(@VisitOID) = 1
		SET @iVisitOID = cast(@VisitOID AS INT)
	ELSE
		SET @iVisitOID = - 1

	IF isnumeric(@HSF_SESSION_USEROID) = 1
		SET @iUserOID = cast(@HSF_SESSION_USEROID AS INT)
	ELSE
		SET @iUserOID = - 1

	IF @pchReportUsage = '2'
	BEGIN
		-- Check for valid Location       
		IF (@pvchLocation IS NULL)
			OR (@pvchLocation LIKE 'ALL,%')
			OR (@pvchLocation LIKE 'All,%')
			OR (@pvchLocation = '')
			SET @pvchLocation = 'ALL'

		--Insert Location into @tblLocation      
		--Using function fn_GetStrParmTable      
		IF (@pvchLocation = 'ALL')
		BEGIN
			SET @chLocation = 'ALL'
		END
		ELSE
		BEGIN
			INSERT INTO @tblLocation (Location)
			SELECT *
			FROM fn_GetStrParmTable(@pvchLocation)

			SET @chLocation = ' '
		END
	END

	--Get Name of User requesting the report      
	BEGIN
		SET @vchReportUserName = isnull(dbo.fn_ORE_GetPersonName((
						SELECT Person_OID
						FROM HSUser WITH (NOLOCK)
						WHERE ObjectID = @iUserOID
						), 6), '')
	END

	IF @pchReportUsage = '1'
	BEGIN
		INSERT INTO @tblPatientOID
		SELECT Patient_OID = @iPatientOID,
			VisitOID = @iVisitOID

		SELECT FirstName = isnull(pt.FirstName, ''),
			MiddleName = isnull(pt.MiddleName, ''),
			LastName = isnull(pt.LastName, ''),
			PatientName = CASE ISNULL(pt.GenerationQualifier, '')
				WHEN ''
					THEN pt.LastName + ', ' + pt.FirstName + ' ' + ISNULL(pt.MiddleName, '')
				ELSE pt.LastName + ' ' + pt.GenerationQualifier + ', ' + pt.FirstName + ' ' + ISNULL(pt.MiddleName, '')
				END,
			PatientAcctNum = isnull(pv.PatientAccountID, ''),
			MRNumber = isnull(.dbo.fn_ORE_GetExternalPatientID(pt.ObjectID, pv.entity_oid), ''),
			BirthDate = convert(VARCHAR(10), per.BirthDate, 101),
			Sex = cast(CASE per.Sex
					WHEN 0
						THEN 'M'
					WHEN 1
						THEN 'F'
					ELSE ' '
					END AS CHAR(6)),
			Age = (.dbo.fn_ORE_GetPatientAge(per.BirthDate, getdate())),
			Location = isnull(pv.PatientLocationName, ''),
			RoomBed = isnull(pv.LatestBedName, ''),
			Allergies = Substring(IsNull(dbo.Fn_ORE_GetPatientAllergies(pt.ObjectID), IsNull(.dbo.fn_ORE_VisitAllergiesCheck(pt.ObjectID, pv.ObjectID), '')), 1, 512),
			AttendDr = isnull(.dbo.fn_ORE_GetPhysicianName(pv.ObjectID, 0, 6), ''),
			EntityName = isnull(pv.EntityName, ''),
			IsolationIndicator = ISNULL(pv.IsolationIndicator, ''),
			VisitStartDateTime = pv.VisitStartDateTime,
			VisitEndDateTime = pv.VisitEndDateTime,
			PatientOID = pt.ObjectID,
			PatientVisitOID = pv.ObjectID
		FROM @tblPatientOID tb1
		INNER JOIN HPatient pt WITH (NOLOCK) ON tb1.PatientOID = pt.ObjectID
			AND pt.isdeleted = 0
		INNER JOIN HPatientVisit pv WITH (NOLOCK) ON tb1.VisitOID = pv.ObjectID
			AND pv.entityname = @Entity
			AND isnull(pv.IsolationIndicator, '') <> ''
			AND pv.isdeleted = 0
		INNER JOIN HPerson per WITH (NOLOCK) ON pt.ObjectID = per.ObjectID
		WHERE pv.VisitStatus = 0
	END

	IF @pchReportUsage = '2'
	BEGIN
		SELECT FirstName = isnull(pt.FirstName, ''),
			MiddleName = isnull(pt.MiddleName, ''),
			LastName = isnull(pt.LastName, ''),
			PatientName = CASE ISNULL(pt.GenerationQualifier, '')
				WHEN ''
					THEN pt.LastName + ', ' + pt.FirstName + ' ' + ISNULL(pt.MiddleName, '')
				ELSE pt.LastName + ' ' + pt.GenerationQualifier + ', ' + pt.FirstName + ' ' + ISNULL(pt.MiddleName, '')
				END,
			PatientAcctNum = isnull(pv.PatientAccountID, ''),
			MRNumber = isnull(.dbo.fn_ORE_GetExternalPatientID(pt.ObjectID, pv.entity_oid), ''),
			BirthDate = convert(VARCHAR(10), per.BirthDate, 101),
			Sex = cast(CASE per.Sex
					WHEN 0
						THEN 'M'
					WHEN 1
						THEN 'F'
					ELSE ' '
					END AS CHAR(6)),
			Age = (.dbo.fn_ORE_GetPatientAge(per.BirthDate, getdate())),
			Location = isnull(pv.PatientLocationName, ''),
			RoomBed = isnull(pv.LatestBedName, ''),
			Allergies = Substring(IsNull(dbo.Fn_ORE_GetPatientAllergies(pt.ObjectID), IsNull(.dbo.fn_ORE_VisitAllergiesCheck(pt.ObjectID, pv.ObjectID), '')), 1, 512),
			AttendDr = isnull(.dbo.fn_ORE_GetPhysicianName(pv.ObjectID, 0, 6), ''),
			EntityName = isnull(pv.EntityName, ''),
			VisitStartDateTime = pv.VisitStartDateTime,
			VisitEndDateTime = pv.VisitEndDateTime,
			IsolationIndicator = ISNULL(pv.IsolationIndicator, ''),
			PatientOID = pt.ObjectID,
			PatientVisitOID = pv.ObjectID
		FROM HPatient pt WITH (NOLOCK)
		INNER JOIN HPatientVisit pv WITH (NOLOCK) ON pt.ObjectID = pv.Patient_oid
			AND pv.entityname = @Entity
			AND pv.isdeleted = 0
			AND isnull(pv.IsolationIndicator, '') <> ''
		INNER JOIN HPerson per WITH (NOLOCK) ON pt.ObjectID = per.ObjectID
		WHERE pt.IsDeleted = 0
			AND (
				@chLocation = 'All'
				OR EXISTS (
					SELECT Location
					FROM @tblLocation t1
					WHERE t1.location = pv.PatientLocationName
					)
				)
			AND pv.VisitStatus = 0
	END
END
