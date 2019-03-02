USE [Soarian_Clin_Tst_1]
GO
/****** Object:  StoredProcedure [dbo].[ORE_BMH_0010_S2_v1]    Script Date: 1/24/2019 2:56:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Test Run
EXECUTE DBO.ORE_BMH_0010_S2_v1 @pvchPatientOID = '2133705'
, @pvcFormUsageName = 'Physician Discharge Instructions'
, @pvcDisplayOption = '5'
, @pvcStartDate = ''
, @pvcEndDate = ''
, @pvchVisitOID = '152774'
, @pchAssmtStatus = '3'
, @pchHours = ''
, @pchPatientSelector = '2'
, @pchReportUsage = '1'
, @pchDateSort = '1'
, @pchShowNullFindings = '1'
*/

/*
-------------------------------------------------------------------------------  
File:    ORE_0010_S2Prc.sql  

Input  Parameters:   
	@pvchPatientOID AS PatientOID used to identify patient which the report should be run for.  
    @pvcFormUsageName AS Form Usage Name, used selected specific form usage   
    @pvcDisplayOption AS Used to filter the results that display based on dates
		0 = Get results for current day (Observation date of current day)  
		1 = Get Results for last 24 hours based AS of run date/time  
		2 = Get Results for Date Range   
		3 = Get last 6 most recent notes  
		4 = Get last 12 most recent notes  
		5 = Get All Notes  

	@pvcStartDate AS Starting date AS compared to Observatione Date  
	@pvcEndDate AS Ending date AS compared to Observation Date.  
	@pvchVisitOID AS Visit OID Of patient displayed in UI  
	@pchAssmtStatus AS assessment status
		1 = in-progress
		3 = completed
		4 = erroneous
		5 = draft  
	@pchHours AS Number of Hours to SELECT Assessments on   
	@pchPatientSelector AS For OPR/JS - Used to indicate how to pull patients for report  
		1 = By Patient Location  
		2 = By Collected Date   
		3 = By Discharge Date        
	@pchReportUsage AS Used to indicate how the report IS being run  
		1 = Context Senstive (CSP) Patient Context  
		2 = Operational Reporting (OPR)  
		3 = Job Scheduler (JS)  
	@pchDateSort AS Sort Order of Assessments collected DateTime   
		0 = Reverse Chronolgical Order    
		1 = Chronological Order
	@pchShowNullFindings AS Show/Suppress Findings with No values in ther report.  
		0 = Hide/Suppress             
		1 = Show   

Purpose:  This procedure will retrieve fields needed to print the Chapter Assessment Section   
          of the Assessment Report  
               
    
Tables:   
	HAssessment  
	HAssessmentCategory  
	HName  
	HObservation_Category  
	HObservation  
	HSUser  
	HObsExtraInfo

Functions:   
	fn_GetStrParmTable  

Views:   
	None
  
Functions:   
	None

Revision History:  
   
Date        Author            	Description  
----        ------            	----------- 
2019-01-25	Sanderson, Steven	Add Field ObsTextVal from HObsExtraInfo

-------------------------------------------------------------------------------  
*/
   
ALTER PROCEDURE [dbo].[Ore_bmh_0010_s2_v1_steve_test] 
  --ALTER  PROCEDURE [dbo].[ORE_BMH_0010_S2_v1]  
  @pvchPatientOID      VARCHAR(20) = NULL, 
  @pvcFormUsageName    VARCHAR(2000) = NULL, 
  @pvcDisplayOption    CHAR(1) = '1', 
  @pvcStartDate        VARCHAR(20) = NULL, 
  @pvcEndDate          VARCHAR(20) = NULL, 
  @pvchVisitOID        VARCHAR(20) = NULL, 
  @pchAssmtStatus      VARCHAR(20) = NULL, 
  @pchHours            CHAR(3) = NULL, 
  @pchPatientSelector  CHAR(1) = NULL, 
  @pchReportUsage      CHAR(2) = NULL, 
  @pchDateSort         CHAR(1) ='0', 
  @pchShowNullFindings CHAR(1) ='0' 
AS 
    --*************************************************************************************************   
    -- Variables declaration for Vitals Sign Report --   
    --*************************************************************************************************   
    DECLARE @FormUsageName   VARCHAR(255), 
            @FindingName     VARCHAR(64), 
            @iPatientOID     INT, 
            @iVisitOID       INT, 
            @FindingAbbrName VARCHAR(16), 
            @dStartDate      DATETIME, 
            @dEndDate        DATETIME, 
            @dtDschDtFrom    DATETIME, 
            @dtDschDtTo      DATETIME, 
            @iRecCount       INT, 
            @vcFormUsageName CHAR(3), 
            @iHours          INT, 
            @ChapterName     VARCHAR(255) 
    --*************************************************************************************************   
    -- Temp Tables declaration for Assessments Report --   
    --*************************************************************************************************   
    -- temp table to hold vitals info    
    --declare @tmpAssessment table    
    DECLARE @tmpAssessment TABLE 
      ( 
         Patientoid                INT, 
         Patientvisitoid           INT, 
         Formusagename             VARCHAR(100), 
         Chaptername               VARCHAR(100), 
         Findingname               VARCHAR(64), 
         Findingabbrname           VARCHAR(16), 
         Collecteddatetime         SMALLDATETIME, 
         Scheduleddttm             SMALLDATETIME, 
         Creationtime              DATETIME, 
         Entereddatetime           SMALLDATETIME, 
         Obsvalue                  TEXT, 
         Unitofmeasure             VARCHAR(20), 
         Specialprocessingtypecode SMALLINT, 
         Abncrtindicator           VARCHAR(20), 
         Collectedbylastname       VARCHAR(60), 
         Collectedbyfirstname      VARCHAR(30), 
         Collectedbyminame         VARCHAR(30), 
         Collectedbytitle          VARCHAR(64), 
         Collectedabbrname         VARCHAR(92), 
         Assessmentstatus          VARCHAR(35), 
         Chaptersortorder          INTEGER, 
         Findingsortorder          INTEGER, 
         Recordsfound              INT, 
         Assessmentid              INT, 
         Assessmentoid             INT, 
         Observationoid            INT, 
         Clinicalnote              TEXT, 
         Formoid                   INT 
      ) 
    --Table to hold parsed form usage names from incoming @pvcFormUsageName parameter   
    DECLARE @tblFormUsageName TABLE 
      ( 
         Formusagename VARCHAR(100) 
      ) 
    --Table to hold parsed order status' from incoming @pchAssmtStatus parameter   
    DECLARE @tblAssmntStatus TABLE 
      ( 
         Assmntstatus INT 
      ) 
    --Table to hold Qualified Assessment IDs'   
    DECLARE @AssessmentIDs TABLE 
      ( 
         Patientoid      INTEGER, 
         Patientvisitoid INTEGER, 
         Assessmentid    INTEGER, 
         Collecteddt     SMALLDATETIME 
      ) 

    --***********************************************************************************************   
    -- Parameter Checking / validation    
    --***********************************************************************************************   
    -- Allow only the Location option for now.   
    IF ( @pchReportUsage = '2' ) 
        OR ( @pchReportUsage = '3' ) 
      SET @pchPatientSelector = '1' 

    -- convert incoming parameter to numeric   
    IF Isnumeric(@pvchPatientOID) = 1 
      SET @iPatientOID = Cast(@pvchPatientOID AS INT) 
    ELSE 
      SET @iPatientOID = -1 

    IF Isnumeric(@pvchVisitOID) = 1 
      SET @iVisitOID = Cast(@pvchVisitOID AS INT) 
    ELSE 
      SET @iVisitOID = -1 

    IF ( ( @pvcDisplayOption IS NULL ) 
          OR ( @pvcDisplayOption = '' ) ) 
      SET @pvcDisplayOption = '1' 

    -- Set the Result Display option -    
    -- 0 = Get results for current day (Observation date of current day)   
    -- 1 = Get Results for last 24 hours based as of run date/time   
    -- 2 = Get Results for Date Range    
    -- 3 = Get last 6 most recent notes   
    -- 4 = Get last 12 most recent notes   
    -- 5 = Get All Notes   
    -- 6 = # of hours   
    -- 7 = Yesterday   
    IF Isnumeric(@pchHours) = 1 
      SET @iHours = Cast(@pchHours AS INT) 
    ELSE 
      SET @iHours = 0 

    -- if not display option sent assume '3'   
    IF @pvcDisplayOption IS NULL 
        OR @pvcDisplayOption = '' 
      SET @pvcDisplayOption = '1' 

    IF @pvcDisplayOption = '0' -- Retreive results for current day only   
      BEGIN 
          SET @dStartDate = Cast(CONVERT(VARCHAR(10), Getdate(), 101) 
                                 + ' 00:00:00' AS DATETIME) 
          SET @dEndDate = Cast(CONVERT(VARCHAR(20), Getdate()) AS DATETIME) 
      END 

    IF @pvcDisplayOption = '1' 
      -- Retreive results for last 24 hours based on current day   
      BEGIN 
          SET @dStartDate = Cast(CONVERT(VARCHAR(20), Getdate() - 1) AS DATETIME 
                            ) 
          SET @dEndDate = Cast(CONVERT(VARCHAR(20), Getdate()) AS DATETIME) 
      END 

    IF @pvcDisplayOption = '2' -- Retreive results using supplied date range   
      BEGIN 
          -- Check for valid start date    
          IF Isdate(@pvcStartDate) = 1 
            IF Len(@pvcStartDate) < 12 
              SET @dStartDate = Cast(CONVERT(VARCHAR(10), @pvcStartDate, 101) 
                                     + ' 00:00:00' AS DATETIME) 
            ELSE 
              SET @dStartDate = Cast(@pvcStartDate AS DATETIME) 
          ELSE 
            SET @dStartDate = Cast(CONVERT(VARCHAR(10), Getdate(), 101) 
                                   + ' 00:00:00' AS DATETIME) 

          -- Check for valid through date    
          IF Isdate(@pvcEndDate) = 1 
            IF Len(@pvcEndDate) < 12 
              SET @dEndDate = Cast(CONVERT(VARCHAR(10), @pvcEndDate, 101) 
                                   + ' 23:59:59' AS DATETIME) 
            ELSE 
              SET @dEndDate = Cast(@pvcEndDate AS DATETIME) 
          ELSE 
            SET @dEndDate = Cast(CONVERT(VARCHAR(10), Getdate(), 101) 
                                 + ' 23:59:59' AS DATETIME) 
      END 

    IF @pvcDisplayOption = '6' -- Retrieve results based on hours      
      BEGIN 
          SET @dStartDate =Cast(CONVERT(VARCHAR(20), Dateadd(hour, ( 
                                                     @iHours * -1 ), 
                                                     Getdate()))AS DATETIME 
                           ) 
          SET @dEndDate = Cast(CONVERT(VARCHAR(20), Getdate()) AS DATETIME) 
      END 

    IF @pvcDisplayOption = '7' -- Retreive results for yesterday   
      BEGIN 
          SET @dStartDate = Cast(CONVERT(VARCHAR(10), Getdate()-1, 101) 
                                 + ' 00:00:00' AS DATETIME) 
          SET @dEndDate = Cast(CONVERT(VARCHAR(10), Getdate()-1, 101) 
                               + ' 23:59:59' AS DATETIME) 
      END 

    --mxn Start Validation   
    IF @pvcDisplayOption = '2' 
      BEGIN 
          IF ( @dStartDate > @dEndDate ) 
            BEGIN 
                RAISERROR ( 
      'OMSErrorNo=[65601], OMSErrorDesc=[End Date less than Start date]', 
      16, 
      1) 
            END 
      END 

    -- parse formusage name parameters   
    -- and parse into to the form usage table   
    IF ( @pvcFormUsageName IS NOT NULL ) 
       AND ( @pvcFormUsageName NOT LIKE 'All%' ) 
      BEGIN 
          INSERT INTO @tblFormUsageName 
                      (Formusagename) 
          SELECT * 
          FROM   Fn_getstrparmtable(@pvcFormUsageName) 
      END 
    ELSE 
      BEGIN 
          INSERT INTO @tblFormUsageName 
                      (Formusagename) 
          SELECT FU.Displayname 
          FROM   DCB_FORMUSAGE FU 
          WHERE  FU.Formtype = 6 
                 AND FU.Deletedind = 0 
      END 

    -- Parse incoming Assessment Status Types parameter   
    -- and parse into to the Assessment Status table   
    IF ( @pchAssmtStatus IS NOT NULL ) 
      BEGIN 
          INSERT INTO @tblAssmntStatus 
                      (Assmntstatus) 
          SELECT * 
          FROM   Fn_getstrparmtable(@pchAssmtStatus) 
      END 

    --************************************************************************************************************   
    --  Begin Main Procedure   
    --************************************************************************************************************   
    -- Get OID based CSP Usage --   
    IF ( @pchReportUsage = '1' ) -- CSP Usage    
      BEGIN 
          IF ( @pvcDisplayOption = '0' ) 
              OR ( @pvcDisplayOption = '1' ) 
              OR ( @pvcDisplayOption = '2' ) 
              OR ( @pvcDisplayOption = '5' ) 
              OR ( @pvcDisplayOption = '6' ) 
              OR ( @pvcDisplayOption = '7' ) 
            BEGIN 
                -- get assessmentID   
                INSERT INTO @AssessmentIDs 
                SELECT PatientOID = HA.Patient_oid, 
                       0, 
                       AssessmentID = HA.Assessmentid, 
                       CollectedDT = HA.Collecteddt 
                FROM   HASSESSMENT HA WITH(nolock) 
                       INNER JOIN @tblAssmntStatus O1 
                               ON O1.Assmntstatus = HA.Assessmentstatuscode 
                       INNER JOIN @tblFormUsageName T1 
                               ON T1.Formusagename = HA.Formusagedisplayname 
                WHERE  ( ( HA.Collecteddt BETWEEN @dStartDate AND @dEndDate ) 
                          OR ( @pvcDisplayOption = '5' ) ) 
                       -- 5 = all occurrences --    
                       AND HA.Enddt IS NULL 
                       AND HA.Patient_oid = @iPatientOID 
                       AND HA.Formtypeid = 6 -- Columnar Assessments only   
            END 
          ELSE IF ( @pvcDisplayOption = '3' ) 
            -- CSP Usage get / last 6 occurrences --    
            BEGIN 
                -- get last 6 assessments    
                INSERT INTO @AssessmentIDs 
                SELECT TOP 6 PatientOID = HA.Patient_oid, 
                             0, 
                             AssessmentID = HA.Assessmentid, 
                             CollectedDT = HA.Collecteddt 
                FROM   HASSESSMENT HA WITH(nolock) 
                       INNER JOIN @tblAssmntStatus O1 
                               ON O1.Assmntstatus = HA.Assessmentstatuscode 
                       INNER JOIN @tblFormUsageName T1 
                               ON T1.Formusagename = HA.Formusagedisplayname 
                WHERE  HA.Enddt IS NULL 
                       AND HA.Patient_oid = @iPatientOID 
                       AND HA.Formtypeid = 6 -- Columnar Assessments only   
                ORDER  BY HA.Collecteddt DESC 
            END 
          ELSE IF ( @pvcDisplayOption = '4' ) 
            -- CSP Usage get /  get last 12 occurrences --    
            BEGIN 
                -- get last 12 assessments    
                INSERT INTO @AssessmentIDs 
                SELECT TOP 12 PatientOID = HA.Patient_oid, 
                              0, 
                              AssessmentID = HA.Assessmentid, 
                              CollectedDT = HA.Collecteddt 
                FROM   HASSESSMENT HA WITH(nolock) 
                       INNER JOIN @tblAssmntStatus O1 
                               ON O1.Assmntstatus = HA.Assessmentstatuscode 
                       INNER JOIN @tblFormUsageName T1 
                               ON T1.Formusagename = HA.Formusagedisplayname 
                WHERE  HA.Enddt IS NULL 
                       AND HA.Patient_oid = @iPatientOID 
                       AND HA.Formtypeid = 6 -- Columnar Assessments only   
                ORDER  BY HA.Collecteddt DESC 
            END 
      END -- End of If (@pchReportUsage = '1') -- CSP Usage    
    -- Get OIDS for Non-CSP Usage    
    IF ( @pchReportUsage = '2' ) 
        OR ( @pchReportUsage = '3' ) -- OPR / JS Usage   
      BEGIN 
          IF @pchPatientSelector = '1' -- Fetch patients by location   
            BEGIN 
                -- get assessmentID   
                INSERT INTO @AssessmentIDs 
                SELECT PatientOID = HA.Patient_oid, 
                       PatientVisitOID = HA.Patientvisit_oid, 
                       AssessmentID = HA.Assessmentid, 
                       CollectedDT = HA.Collecteddt 
                FROM   HASSESSMENT HA WITH(nolock) 
                       INNER JOIN HPATIENTVISIT PV 
                               ON HA.Patientvisit_oid = PV.Objectid 
                                  AND PV.Isdeleted = 0 
                       INNER JOIN @tblAssmntStatus O1 
                               ON O1.Assmntstatus = HA.Assessmentstatuscode 
                       INNER JOIN @tblFormUsageName T1 
                               ON T1.Formusagename = HA.Formusagedisplayname 
                WHERE  ( ( HA.Collecteddt BETWEEN @dStartDate AND @dEndDate ) 
                          OR ( @pvcDisplayOption = '5' ) ) 
                       -- 5 = all occurrences --    
                       AND HA.Enddt IS NULL 
                       AND HA.Patient_oid = @iPatientOID 
                       AND HA.Patientvisit_oid = @iVisitOID 
                       AND HA.Formtypeid = 6 -- Columnar Assessments only   
            END 
          ELSE IF @pchPatientSelector = '2' 
            -- Fetch patients by collected date time   
            BEGIN 
                -- get assessmentID   
                INSERT INTO @AssessmentIDs 
                SELECT PatientOID = HA.Patient_oid, 
                       PatientVisitOID = 0, 
                       AssessmentID = HA.Assessmentid, 
                       CollectedDT = HA.Collecteddt 
                FROM   HASSESSMENT HA WITH(nolock) 
                       INNER JOIN @tblAssmntStatus O1 
                               ON O1.Assmntstatus = HA.Assessmentstatuscode 
                       INNER JOIN @tblFormUsageName T1 
                               ON T1.Formusagename = HA.Formusagedisplayname 
                WHERE  HA.Collecteddt BETWEEN @dStartDate AND @dEndDate 
                       AND HA.Enddt IS NULL 
                       AND HA.Patient_oid = @iPatientOID 
                       AND HA.Formtypeid = 6 -- Columnar Assessments only   
            END 
          ELSE IF @pchPatientSelector = '3' 
            -- Fetch patients by discharge date time   
            BEGIN 
                -- get assessmentID   
                INSERT INTO @AssessmentIDs 
                SELECT PatientOID = HA.Patient_oid, 
                       PatientVisitOID = HA.Patientvisit_oid, 
                       AssessmentID = HA.Assessmentid, 
                       CollectedDT = HA.Collecteddt 
                FROM   HASSESSMENT HA WITH(nolock) 
                       INNER JOIN HPATIENTVISIT PV 
                               ON HA.Patientvisit_oid = PV.Objectid 
                                  AND PV.Isdeleted = 0 
                       INNER JOIN @tblAssmntStatus O1 
                               ON O1.Assmntstatus = HA.Assessmentstatuscode 
                       INNER JOIN @tblFormUsageName T1 
                               ON T1.Formusagename = HA.Formusagedisplayname 
                WHERE  HA.Enddt IS NULL 
                       AND HA.Patient_oid = @iPatientOID 
                       AND HA.Patientvisit_oid = @iVisitOID 
                       AND HA.Formtypeid = 6 -- Columnar Assessments only   
            END 
      END 
    -- end of IF (@pchReportUsage = '2') or (@pchReportUsage = '3') -- OPR / JS Usage   
    -- Fetch Records --     
    IF ( @pchShowNullFindings = '1' ) 
      BEGIN 
          INSERT INTO @tmpAssessment 
                      (Patientoid, 
                       Patientvisitoid, 
                       Formusagename, 
                       Chaptername, 
                       Findingname, 
                       Findingabbrname, 
                       Collecteddatetime, 
                       Scheduleddttm, 
                       Creationtime, 
                       Entereddatetime, 
                       Obsvalue, 
                       Unitofmeasure, 
                       Specialprocessingtypecode, 
                       Abncrtindicator, 
                       Collectedbylastname, 
                       Collectedbyfirstname, 
                       Collectedbyminame, 
                       Collectedbytitle, 
                       Collectedabbrname, 
                       Assessmentstatus, 
                       Chaptersortorder, 
                       Findingsortorder, 
                       Recordsfound, 
                       Assessmentid, 
                       Assessmentoid, 
                       Observationoid, 
                       Clinicalnote, 
                       Formoid) 
          SELECT Patientoid = HA.Patient_oid, 
                 PatientVisitoid = HA.Patientvisit_oid, 
                 FormUsageName = Isnull(HA.Formusagedisplayname, ''), 
                 ChapterName = 
                 Isnull(HAC.Formusagedisplayname, HA.Formusagedisplayname), 
                 FindingName = Isnull(HO.Findingname, HAFE.Displayname), 
                 FindingAbbrName = Isnull(HO.Findingabbr, HAFE.NAME), 
                 CollectedDateTime = HA.Collecteddt, 
                 ScheduleDttm = HA.Scheduleddt, 
                 CreationTime = HA.Creationtime, 
                 EnteredDateTime = HA.Entereddt, 
                 OBSValue = CASE 
                              WHEN Isnull(HO.Value, '') = '' THEN 
                                CASE 
                                  WHEN HO.Processingtypecode = 3 
                                        OR HO.Processingtypecode = 4 THEN 
                                    CASE 
                                      WHEN ( ( Charindex('/', HO.Internalvalue) 
                                               > 1 
                                             ) 
                                             AND ( Charindex('/', 
                                                   HO.Internalvalue) 
                                                   < 
                                                 Len(HO.Internalvalue) ) ) 
                                    THEN 
                                      HO.Internalvalue 
                                      ELSE Ltrim( 
                                    Replace(HO.Internalvalue, '/', '')) 
                                    END 
                                  ELSE 
                                    CASE 
                                      WHEN HO.Findingdatatype = 9 
                                           AND HO.Internalvalue <> '' 
                                           AND ( Isnumeric(HO.Internalvalue) = 1 
                                                  OR Isdate(HO.Internalvalue) = 
                                                     1 ) 
                                    THEN 
                                        CASE 
                                          WHEN ( 
                                      Charindex(':', HO.Internalvalue) = 
                                      3 
                                               ) 
                                        THEN 
                                          LEFT(HO.Value, 5) 
                                          WHEN Len(HO.Internalvalue) = 8 
                                               AND Isdate(HO.Internalvalue) = 1 
                                        THEN 
                                          Substring(HO.Internalvalue, 1, 4) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 5, 2) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 7, 2) 
                                          WHEN Len(HO.Internalvalue) > 8 
                                               AND Isdate(HO.Internalvalue) = 1 
                                        THEN 
                                          Substring(HO.Internalvalue, 1, 4) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 5, 2) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 7, 2) + 
                                          ' ' 
                                          + Substring(HO.Internalvalue, 10, 8) 
                                          WHEN Len(HO.Internalvalue) > 8 
                                               AND Isnumeric (HO.Internalvalue) 
                                                   = 1 
                                        THEN 
                                          Substring(HO.Internalvalue, 1, 4) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 5, 2) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 7, 2) + 
                                          ' ' 
                                          + Substring(HO.Internalvalue, 9, 2) + 
                                          ':' 
                                          + 
                                          + Substring(HO.Internalvalue, 11, 2) + 
                                          ':' 
                                          + 
                                          + Substring(HO.Internalvalue, 13, 2) 
                                          ELSE Isnull(Replace(HO.Internalvalue, 
                                                      Char 
                                                      ( 
                                                      30), 
                                                      ', '), 
                                               '') 
                                        END 
                                      ELSE HO.Internalvalue 
                                    END 
                                END 
                              ELSE 
                                CASE 
                                  WHEN HO.Processingtypecode = 3 
                                        OR HO.Processingtypecode = 4 THEN 
                                    CASE 
                                      WHEN ( ( Charindex('/', HO.Value) > 1 ) 
                                             AND ( Charindex('/', HO.Value) < 
                                                   Len(HO.Value) ) ) 
                                    THEN 
                                      HO.Value 
                                      ELSE Ltrim(Replace(HO.Value, '/', '')) 
                                    END 
                                  ELSE 
                                    CASE 
                                      WHEN HO.Findingdatatype = 9 
                                           AND HO.Value <> '' 
                                           AND ( Isnumeric(HO.Value) = 1 
                                                  OR Isdate(HO.Value) = 1 ) THEN 
                                        CASE 
                                          WHEN ( Charindex(':', HO.Value) = 3 ) 
                                        THEN 
                                          LEFT(HO.Value, 5) 
                                          WHEN Len(HO.Value) = 8 
                                               AND Isdate(HO.Value) = 1 THEN 
                                          Substring(HO.Value, 1, 4) + '-' 
                                          + Substring(HO.Value, 5, 2) + '-' 
                                          + Substring(HO.Value, 7, 2) 
                                          WHEN Len(HO.Value) > 8 
                                               AND Isdate(HO.Value) = 1 THEN 
                                          Substring(HO.Value, 1, 4) + '-' 
                                          + Substring(HO.Value, 5, 2) + '-' 
                                          + Substring(HO.Value, 7, 2) + ' ' 
                                          + Substring(HO.Value, 10, 8) 
                                          WHEN Len(HO.Value) > 8 
                                               AND Isnumeric (HO.Value) = 1 THEN 
                                          Substring(HO.Value, 1, 4) + '-' 
                                          + Substring(HO.Value, 5, 2) + '-' 
                                          + Substring(HO.Value, 7, 2) + ' ' 
                                          + Substring(HO.Value, 9, 2) + ':' + 
                                          + Substring(HO.Value, 11, 2 ) + ':' + 
                                          + Substring(HO.Value, 13, 2) 
                                          ELSE Isnull(Replace(HO.Value, Char(30) 
                                                      , 
                                                      ', ' 
                                                      ), 
                                               '') 
                                        END 
                                      ELSE Replace(HO.Value, Char(30), ', ') 
                                    END 
                                END 
                            END, 
                 UnitOfMeasure = Isnull(HO.Uom, ''), 
                 SpecialProcessingTypeCode = Isnull(HO.Processingtypecode, ''), 
                 AbnCrtIndicator = Isnull(HO.Abncrtindicator, ''), 
                 CollectedByLastName = Isnull(NM.Lastname, ''), 
                 CollectedByFirstName = Isnull(NM.Firstname, ''), 
                 CollectedByMIName = Isnull(NM.Middlename, ''), 
                 CollectedByTitle = Isnull(NM.Title, ''), 
                 CollectedAbbrName = Isnull(HA.Userabbrname, ''), 
                 AssessmentStatus = Isnull(HA.Assessmentstatus, ''), 
                 ChapterSequence = Isnull(HAC.Sequencenumber, 9999), 
                 DisplaySequence = Isnull(HAFE.Taborder, 9999), 
                 RecordsFound = 0, 
                 Assessmentid = HA.Assessmentid, 
                 Assessmentoid = HA.Objectid, 
                 Observationoid = HO.Objectid, 
                 ClinicalNote = CN.Notetext, 
                 formoid = HA.Form_oid 
          FROM   @AssessmentIDs A1 
                 INNER JOIN HASSESSMENT HA WITH(nolock) 
                         ON A1.Assessmentid = HA.Assessmentid 
                 INNER JOIN HASSESSMENTCATEGORY HAC WITH(nolock) 
                         ON HA.Assessmentid = HAC.Assessmentid 
                            AND HAC.Categorystatus NOT IN ( 0, 3 ) 
                            AND HAC.Islatest = 1 
                 INNER JOIN HASSESSMENTFORMELEMENT HAFE WITH(nolock) 
                         ON HAC.Form_oid = HAFE.Formid 
                            AND HAC.Formversion = HAFE.Formversion 
                 LEFT OUTER JOIN HOBSERVATION HO WITH(nolock) 
                              ON A1.Assessmentid = HO.Assessmentid 
                                 AND HA.Patient_oid = HO.Patient_oid 
                                 AND HO.Findingabbr = HAFE.NAME 
                                 AND HO.Finding_oid = HAFE.Oid 
                                 AND HO.Enddt IS NULL 
                                 AND HO.Observationstatus LIKE 'A%' 
                                 AND HO.Findingname NOT IN ( 
                 'HPatient_AdvancedDirective', 
                 'HPatient_AlertMessage', 
                 'HPatient_DiagnosisCode', 
                                       'HPatient_DiagnosisDescription', 
                                     'HPatient_IsolationIndicator', 
                 'HPatient_PrimaryLanguage', 'HPatient_Religion' 
                                                               , 
                 'HPatient_Sex' ) 
                 LEFT OUTER JOIN HSUSER HSU WITH(nolock) 
                              ON HSU.Objectid = HA.User_oid 
                 LEFT OUTER JOIN HNAME NM 
                              ON NM.Person_oid = HSU.Person_oid 
                                 AND ( Enddateofvalidity IS NULL 
                                        OR Enddateofvalidity = 
                                           '1899-12-30 00:00:00' 
                                     ) 
                 LEFT OUTER JOIN HCLINICALNOTE CN WITH(nolock) 
                              ON HA.Assessmentid = CN.Linkobjectid 
                                 AND HA.Patient_oid = CN.Patientid 
                                 AND CN.Enddt IS NULL 
                                 AND CN.Notestatus <> 0 
                                 AND CN.Entereddt = (SELECT Max(CN2.Entereddt) 
                                                     FROM 
                                     HCLINICALNOTE CN2 WITH( 
                                     nolock) 
                                                     WHERE 
                                     CN.Patientid = CN2.Patientid 
                                     AND CN.Linkobjectid = 
                                         CN2.Linkobjectid) 
          WHERE  HA.Patient_oid = @iPatientOID 
                 AND HA.Enddt IS NULL 
      --and hac.IsLatest = 1   
      END 
    ELSE 
      BEGIN 
          INSERT INTO @tmpAssessment 
                      (Patientoid, 
                       Patientvisitoid, 
                       Formusagename, 
                       Chaptername, 
                       Findingname, 
                       Findingabbrname, 
                       Collecteddatetime, 
                       Scheduleddttm, 
                       Creationtime, 
                       Entereddatetime, 
                       Obsvalue, 
                       Unitofmeasure, 
                       Specialprocessingtypecode, 
                       Abncrtindicator, 
                       Collectedbylastname, 
                       Collectedbyfirstname, 
                       Collectedbyminame, 
                       Collectedbytitle, 
                       Collectedabbrname, 
                       Assessmentstatus, 
                       Chaptersortorder, 
                       Findingsortorder, 
                       Recordsfound, 
                       Assessmentid, 
                       Assessmentoid, 
                       Observationoid, 
                       Clinicalnote, 
                       Formoid) 
          SELECT Patientoid = HA.Patient_oid, 
                 PatientVisitoid = HA.Patientvisit_oid, 
                 FormUsageName = Isnull(HA.Formusagedisplayname, ''), 
                 ChapterName = 
                 Isnull(HAC.Formusagedisplayname, HA.Formusagedisplayname), 
                 FindingName = Isnull(HO.Findingname, ''), 
                 FindingAbbrName = Isnull(HO.Findingabbr, ''), 
                 CollectedDateTime = HA.Collecteddt, 
                 ScheduleDttm = HA.Scheduleddt, 
                 CreationTime = HA.Creationtime, 
                 EnteredDateTime = HA.Entereddt, 
                 OBSValue = CASE 
                              WHEN Isnull(HO.Value, '') = '' THEN 
                                CASE 
                                  WHEN HO.Processingtypecode = 3 
                                        OR HO.Processingtypecode = 4 THEN 
                                    CASE 
                                      WHEN ( ( Charindex('/', HO.Internalvalue) 
                                               > 1 
                                             ) 
                                             AND ( Charindex('/', 
                                                   HO.Internalvalue) 
                                                   < 
                                                 Len(HO.Internalvalue) ) ) 
                                    THEN 
                                      HO.Internalvalue 
                                      ELSE Ltrim( 
                                    Replace(HO.Internalvalue, '/', '')) 
                                    END 
                                  ELSE 
                                    CASE 
                                      WHEN HO.Findingdatatype = 9 
                                           AND HO.Internalvalue <> '' 
                                           AND ( Isnumeric(HO.Internalvalue) = 1 
                                                  OR Isdate(HO.Internalvalue) = 
                                                     1 ) 
                                    THEN 
                                        CASE 
                                          WHEN ( 
                                      Charindex(':', HO.Internalvalue) = 
                                      3 
                                               ) 
                                        THEN 
                                          LEFT(HO.Value, 5) 
                                          WHEN Len(HO.Internalvalue) = 8 
                                               AND Isdate(HO.Internalvalue) = 1 
                                        THEN 
                                          Substring(HO.Internalvalue, 1, 4) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 5, 2) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 7, 2) 
                                          WHEN Len(HO.Internalvalue) > 8 
                                               AND Isdate(HO.Internalvalue) = 1 
                                        THEN 
                                          Substring(HO.Internalvalue, 1, 4) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 5, 2) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 7, 2) + 
                                          ' ' 
                                          + Substring(HO.Internalvalue, 10, 8) 
                                          WHEN Len(HO.Internalvalue) > 8 
                                               AND Isnumeric (HO.Internalvalue) 
                                                   = 1 
                                        THEN 
                                          Substring(HO.Internalvalue, 1, 4) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 5, 2) + 
                                          '-' 
                                          + Substring(HO.Internalvalue, 7, 2) + 
                                          ' ' 
                                          + Substring(HO.Internalvalue, 9, 2) + 
                                          ':' 
                                          + 
                                          + Substring(HO.Internalvalue, 11, 2) + 
                                          ':' 
                                          + 
                                          + Substring(HO.Internalvalue, 13, 2) 
                                          ELSE Isnull(Replace(HO.Internalvalue, 
                                                      Char 
                                                      ( 
                                                      30), 
                                                      ', '), 
                                               '') 
                                        END 
                                      ELSE HO.Internalvalue 
                                    END 
                                END 
                              ELSE 
                                CASE 
                                  WHEN HO.Processingtypecode = 3 
                                        OR HO.Processingtypecode = 4 THEN 
                                    CASE 
                                      WHEN ( ( Charindex('/', HO.Value) > 1 ) 
                                             AND ( Charindex('/', HO.Value) < 
                                                   Len(HO.Value) ) ) 
                                    THEN 
                                      HO.Value 
                                      ELSE Ltrim(Replace(HO.Value, '/', '')) 
                                    END 
                                  ELSE 
                                    CASE 
                                      WHEN HO.Findingdatatype = 9 
                                           AND HO.Value <> '' 
                                           AND ( Isnumeric(HO.Value) = 1 
                                                  OR Isdate(HO.Value) = 1 ) THEN 
                                        CASE 
                                          WHEN ( Charindex(':', HO.Value) = 3 ) 
                                        THEN 
                                          LEFT(HO.Value, 5) 
                                          WHEN Len(HO.Value) = 8 
                                               AND Isdate(HO.Value) = 1 THEN 
                                          Substring(HO.Value, 1, 4) + '-' 
                                          + Substring(HO.Value, 5, 2) + '-' 
                                          + Substring(HO.Value, 7, 2) 
                                          WHEN Len(HO.Value) > 8 
                                               AND Isdate(HO.Value) = 1 THEN 
                                          Substring(HO.Value, 1, 4) + '-' 
                                          + Substring(HO.Value, 5, 2) + '-' 
                                          + Substring(HO.Value, 7, 2) + ' ' 
                                          + Substring(HO.Value, 10, 8) 
                                          WHEN Len(HO.Value) > 8 
                                               AND Isnumeric (HO.Value) = 1 THEN 
                                          Substring(HO.Value, 1, 4) + '-' 
                                          + Substring(HO.Value, 5, 2) + '-' 
                                          + Substring(HO.Value, 7, 2) + ' ' 
                                          + Substring(HO.Value, 9, 2) + ':' + 
                                          + Substring(HO.Value, 11, 2 ) + ':' + 
                                          + Substring(HO.Value, 13, 2) 
                                          ELSE Isnull(Replace(HO.Value, Char(30) 
                                                      , 
                                                      ', ' 
                                                      ), 
                                               '') 
                                        END 
                                      ELSE Replace(HO.Value, Char(30), ', ') 
                                    END 
                                END 
                            END, 
                 UnitOfMeasure = Isnull(HO.Uom, ''), 
                 SpecialProcessingTypeCode = Isnull(HO.Processingtypecode, ''), 
                 AbnCrtIndicator = Isnull(HO.Abncrtindicator, ''), 
                 CollectedByLastName = Isnull(NM.Lastname, ''), 
                 CollectedByFirstName = Isnull(NM.Firstname, ''), 
                 CollectedByMIName = Isnull(NM.Middlename, ''), 
                 CollectedByTitle = Isnull(NM.Title, ''), 
                 CollectedAbbrName = Isnull(HA.Userabbrname, ''), 
                 AssessmentStatus = Isnull(HA.Assessmentstatus, ''), 
                 ChapterSequence = Isnull(HAC.Sequencenumber, 9999), 
                 DisplaySequence = Isnull(HAFE.Taborder, 9999), 
                 RecordsFound = 0, 
                 Assessmentid = HA.Assessmentid, 
                 Assessmentoid = HA.Objectid, 
                 Observationoid = HO.Objectid, 
                 ClinicalNote = CN.Notetext, 
                 formoid = HA.Form_oid 
          FROM   @AssessmentIDs A1 
                 INNER JOIN HASSESSMENT HA WITH(nolock) 
                         ON A1.Assessmentid = HA.Assessmentid 
                 INNER JOIN HASSESSMENTCATEGORY HAC WITH(nolock) 
                         ON HA.Assessmentid = HAC.Assessmentid 
                            AND HAC.Categorystatus NOT IN ( 0, 3 ) 
                            AND HAC.Islatest = 1 
                 INNER JOIN HASSESSMENTFORMELEMENT HAFE WITH(nolock) 
                         ON HAC.Form_oid = HAFE.Formid 
                            AND HAC.Formversion = HAFE.Formversion 
                 INNER JOIN HOBSERVATION HO WITH(nolock) 
                         ON A1.Assessmentid = HO.Assessmentid 
                            AND HA.Patient_oid = HO.Patient_oid 
                            AND HO.Findingabbr = HAFE.NAME 
                            AND HO.Finding_oid = HAFE.Oid 
                            AND HO.Enddt IS NULL 
                            AND HO.Observationstatus = 'AV' 
                 LEFT OUTER JOIN HSUSER HSU WITH(nolock) 
                              ON HSU.Objectid = HA.User_oid 
                 LEFT OUTER JOIN HNAME NM 
                              ON NM.Person_oid = HSU.Person_oid 
                                 AND ( Enddateofvalidity IS NULL 
                                        OR Enddateofvalidity = 
                                           '1899-12-30 00:00:00' 
                                     ) 
                 LEFT OUTER JOIN HCLINICALNOTE CN WITH(nolock) 
                              ON HA.Assessmentid = CN.Linkobjectid 
                                 AND HA.Patient_oid = CN.Patientid 
                                 AND CN.Enddt IS NULL 
                                 AND CN.Notestatus <> 0 
                                 AND CN.Entereddt = (SELECT Max(CN2.Entereddt) 
                                                     FROM 
                                     HCLINICALNOTE CN2 WITH( 
                                     nolock) 
                                                     WHERE 
                                     CN.Patientid = CN2.Patientid 
                                     AND CN.Linkobjectid = 
                                         CN2.Linkobjectid) 
          WHERE  HA.Patient_oid = @iPatientOID 
                 AND HA.Enddt IS NULL 
                 --and hac.IsLatest = 1   
                 AND HO.Findingname NOT IN ( 
                         'HPatient_AdvancedDirective', 'HPatient_AlertMessage', 
                         'HPatient_DiagnosisCode', 
                                               'HPatient_DiagnosisDescription', 
                                             'HPatient_IsolationIndicator', 
                         'HPatient_PrimaryLanguage', 'HPatient_Religion' 
                                                                       , 
                         'HPatient_Sex' ) 
      END 

    --Remove the Acutity Chapter from the Med Surge Shift Assessment   
    --This request was specified by Megan Sibly   
    DELETE FROM @tmpAssessment 
    WHERE  Formusagename = 'Med Surg Shift Assessment' 
           AND Chaptername = 'Patient Acuity' 

	/*
	Get ObsTextVal from HObsExtraInfo
	*/
	DECLARE @ObsTextVal TABLE (
		Patient_OID INT
		, PatientVisit_OID INT
		, FormUsageDisplayName VARCHAR(MAX)
		, ObsTextVal VARCHAR(MAX)
	)

	INSERT INTO @ObsTextVal

	SELECT HA.Patient_oid
	, HA.PatientVisit_oid
	, HA.FormUsageDisplayName
	, HOE.ObsTextVal

	FROM HAssessment AS HA
	INNER JOIN HObservation AS HO
	ON HA.AssessmentID = HA.AssessmentID
		AND HA.Patient_oid = HO.Patient_oid
	INNER JOIN HObsExtraInfo AS HOE
	ON HO.ObservationID = HOE.Observation_oid
		AND HOE.EndDT IS NULL

	WHERE ha.Patient_oid = @pvchPatientOID
	AND ha.PatientVisit_oid = @pvchVisitOID
	AND hoe.ObsTextVal IS NOT NULL
	AND ha.FormUsageDisplayName = @pvcFormUsageName

    --****************************************************************************************************   
    -- Final Select   
    --****************************************************************************************************   
    SET @iRecCount = (SELECT Count(*) 
                      FROM   @tmpAssessment) 

    IF @iRecCount > 0 
      BEGIN 
          UPDATE @tmpAssessment 
          SET    Recordsfound = @iRecCount 
      END 

    -- Return final record set     
    IF @iRecCount > 0 
      BEGIN 
          IF @pchDateSort = '1' 
            SELECT Patientoid, 
                   Patientvisitoid, 
                   Formusagename, 
                   Chaptername, 
                   Findingname, 
                   Findingabbrname, 
                   Collecteddatetime, 
                   Scheduleddttm, 
                   Creationtime, 
                   Entereddatetime, 
                   Obsvalue, 
                   Unitofmeasure, 
                   Specialprocessingtypecode, 
                   Abncrtindicator, 
                   Collectedbylastname, 
                   Collectedbyfirstname, 
                   Collectedbyminame, 
                   Collectedbytitle, 
                   Collectedabbrname, 
                   Assessmentstatus, 
                   Chaptersortorder, 
                   Findingsortorder, 
                   Recordsfound, 
                   Assessmentid, 
                   Assessmentoid, 
                   Observationoid, 
                   Clinicalnote,
				   OBST.ObsTextVal

            FROM   @tmpAssessment V1
			LEFT OUTER JOIN @ObsTextVal AS OBST
			ON V1.Patientoid = OBST.Patient_OID
			AND V1.Patientvisitoid = OBST.PatientVisit_OID
			 
            ORDER  BY V1.Patientoid, 
                      V1.Patientvisitoid, 
                      V1.Collecteddatetime ASC, 
                      V1.Formusagename, 
                      V1.Chaptersortorder, 
                      V1.Findingsortorder ASC, 
                      V1.Findingabbrname 
          ELSE 
            SELECT Patientoid, 
                   Patientvisitoid, 
                   Formusagename, 
                   Chaptername, 
                   Findingname, 
                   Findingabbrname, 
                   Collecteddatetime, 
                   Scheduleddttm, 
                   Creationtime, 
                   Entereddatetime, 
                   Obsvalue, 
                   Unitofmeasure, 
                   Specialprocessingtypecode, 
                   Abncrtindicator, 
                   Collectedbylastname, 
                   Collectedbyfirstname, 
                   Collectedbyminame, 
                   Collectedbytitle, 
                   Collectedabbrname, 
                   Assessmentstatus, 
                   Chaptersortorder, 
                   Findingsortorder, 
                   Recordsfound, 
                   Assessmentid, 
                   Assessmentoid, 
                   Observationoid, 
                   Clinicalnote,
				   OBST.ObsTextVal

            FROM   @tmpAssessment V1
			LEFT OUTER JOIN @ObsTextVal AS OBST
			ON V1.Patientoid = OBST.Patient_OID
			AND V1.Patientvisitoid = OBST.PatientVisit_OID 

            ORDER  BY V1.Patientoid, 
                      V1.Patientvisitoid DESC, 
                      V1.Collecteddatetime DESC, 
                      V1.Formusagename, 
                      V1.Chaptersortorder, 
                      V1.Findingsortorder ASC, 
                      V1.Findingabbrname 
      END 
    ELSE --RecCount = 0    
      BEGIN 
          -- fill table with dummy data    
          INSERT INTO @tmpAssessment 
                      (Patientoid, 
                       Patientvisitoid, 
                       Formusagename, 
                       Chaptername, 
                       Findingname, 
                       Findingabbrname, 
                       Collecteddatetime, 
                       Scheduleddttm, 
                       Creationtime, 
                       Entereddatetime, 
                       Obsvalue, 
                       Unitofmeasure, 
                       Specialprocessingtypecode, 
                       Abncrtindicator, 
                       Collectedbylastname, 
                       Collectedbyfirstname, 
                       Collectedbyminame, 
                       Collectedbytitle, 
                       Collectedabbrname, 
                       Assessmentstatus, 
                       Chaptersortorder, 
                       Findingsortorder, 
                       Recordsfound, 
                       Assessmentid, 
                       Assessmentoid, 
                       Observationoid, 
                       Clinicalnote,
                       Formoid) 

          SELECT Patientoid =-1, 
                 PatientVisitoid = -1, 
                 FormUsageName = '', 
                 ChapterName = '', 
                 FindingName = '', 
                 FindingAbbrName = '', 
                 CollectedDateTime = NULL, 
                 ScheduleDttm = NULL, 
                 CreationTime = NULL, 
                 EnteredDateTime = NULL, 
                 OBSValue = '', 
                 UnitOfMeasure = '', 
                 SpecialProcessingTypeCode = '', 
                 AbnCrtIndicator = '', 
                 CollectedByLastName = '', 
                 CollectedByFirstName = '', 
                 CollectedByMIName = '', 
                 CollectedByTitle = '', 
                 CollectedAbbrName = '', 
                 AssessmentStatus = '', 
                 ChapterSortOrder = 0, 
                 FindingSortOrder = 0, 
                 RecordsFound = 0, 
                 Assessmentid = -1, 
                 Assessmentoid = -1, 
                 Observationoid = -1, 
                 ClinicalNote = '', 
                 formoid = -1

          -- return record set    
          SELECT Patientoid, 
                 Patientvisitoid, 
                 Formusagename, 
                 Chaptername, 
                 Findingname, 
                 Findingabbrname, 
                 Collecteddatetime, 
                 Scheduleddttm, 
                 Creationtime, 
                 Entereddatetime, 
                 Obsvalue, 
                 Unitofmeasure, 
                 Specialprocessingtypecode, 
                 Abncrtindicator, 
                 Collectedbylastname, 
                 Collectedbyfirstname, 
                 Collectedbyminame, 
                 Collectedbytitle, 
                 Collectedabbrname, 
                 Assessmentstatus, 
                 Chaptersortorder, 
                 Findingsortorder, 
                 Recordsfound, 
                 Assessmentid, 
                 Assessmentoid, 
                 Observationoid, 
                 Clinicalnote 

          FROM   @tmpAssessment V1 


          ORDER  BY V1.Patientoid, 
                    V1.Patientvisitoid, 
                    V1.Collecteddatetime DESC, 
                    V1.Formusagename, 
                    V1.Chaptersortorder, 
                    V1.Findingsortorder ASC, 
                    V1.Findingabbrname 
      END   