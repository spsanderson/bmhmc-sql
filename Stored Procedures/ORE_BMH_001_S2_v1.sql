USE [Soarian_Clin_Tst_1]
GO
/****** Object:  StoredProcedure [dbo].[ORE_BMH_0010_S2_v1]    Script Date: 1/24/2019 2:56:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


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
	@PatientSelector AS For OPR/JS - Used to indicate how to pull patients for report  
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
09-Sep-09   Matt Heilman       	Added code to remove Patient Acuity chapter FROM final select.  
30-May-08   Chris Jolly       	Charm 175156 - Fix issue with the WHERE the Chapter Sequence AND the Tab Order have been switch  
26-Feb-08   chris jolly       	Charm  166390  fix to address findings being saved to internvalue column  
04-Feb-08   Chris Jolly       	Charm 161028 - Sparse Data Model - Additional change to pull findingname FROM  
                                HAssessmentformelement table WHEN showing NULL findings  
01-Feb-08   Chris Jolly       	Charm 163189 - Fix Issue with Revised Clinical notes not printing on assessment report  
18-Dec-07   Rajeev            	charm 161028 - modify procedure to include new assessment tables.  
08-Nov-07   chris jolly      	charm 158679 - bug fix to address chapters/findings repeating for a given collected date/time.  
                               	also applied additional performance improvements.  
29-Oct-07   Chris Jolly       	charm 15125  -- Peformance Improvements  
25-Oct-07   Ken Hanke         	Charm 157551 - Removing temp tables to eliminate performance issues.  
15-Jun-07   chris jolly       	charm 150366 - Fix issue with bad column name   
05-Apr-07   chris jolly       	charm 146276 -- Bug fix to correct issue with incorrect chapter names displaying  
01-Feb-06   Shilpa B          	Charm - HCIS_00141528 - Change hard coded time part to 23:58:59 to 23:59:59  
17-Jan-07   Chris Jolly       	Enhancement -- Check for findingdatatype of finding AND IF DateTime datatype, format finding value INTO  
                               	datetime format.  
19-Sep-06   Tharik            	@pchDateSort parameter added for displaying assessment collectiondate in chronological 
								OR reverse chronological order  
								@pchShowNullFindings parameter added to include/exclude Null findings in the report                
14-Aug-06   Chris Jolly       	Increase size of formusage AND collectedbyabbrname  
08-Aug-06   Chris Jolly       	Add code to process Yesterday AND # of hours logic  
05-Aug-06   chris jolly       	Add Assessment Clinical Notes to SP  
02-Aug-06   chris jolly       	Fix to correct issue WHEN running report by collected date AND getting grouping by visit oid.   
19-Jul-06   Chris Jolly     	Add Cross patient support  
16-May-06   Chris Jolly 	    New Procedure -- Will fetch only page style assessments - FormTypeID = 6  
-------------------------------------------------------------------------------  
*/
   
ALTER  PROCEDURE [dbo].[ORE_BMH_0010_S2_v1]
	@pvchPatientOID      VARCHAR(20) = NULL,       
    @pvcFormUsageName    VARCHAR(2000) = NULL,  
    @pvcDisplayOption    CHAR(1) = '1',  
    @pvcStartDate        VARCHAR(20) = Null,  
    @pvcEndDate          VARCHAR(20) = Null,  
    @pvchVisitOID        VARCHAR(20) = NULL,   
    @pchAssmtStatus      VARCHAR(20) = NULL,  
    @pchHours            CHAR(3) = NULL,  
    @pchPatientSelector  CHAR(1) = NULL,  
    @pchReportUsage      CHAR(2) = NULL,  
	@pchDateSort         CHAR(1) = '0',  
	@pchShowNullFindings CHAR(1) = '0'  
  
AS 
  
--*************************************************************************************************  
-- Variables declaration for Vitals Sign Report --  
--*************************************************************************************************  
  
DECLARE
	@FormUsageName   VARCHAR(255),     
    @FindingName     VARCHAR(64),    
    @iPatientOID     int,    
    @iVisitOID       int,  
    @FindingAbbrName VARCHAR(16),  
	@dStartDate      DATETIME,  
	@dEndDate        DATETIME,  
    @dtDschDtFrom    datetime,  
    @dtDschDtTo      datetime,          
	@iRecCount       int,
    @vcFormUsageName CHAR(3),  
    @iHours          int,  
    @ChapterName     VARCHAR(255)  
  
--*************************************************************************************************  
-- Temp Tables declaration for Assessments Report --  
--*************************************************************************************************  
  
-- temp table to hold vitals info   
--declare @tmpAssessment table   
  
Declare @tmpAssessment table (  
	Patientoid                  int,  
    PatientVisitoid             int,  
    FormUsageName               VARCHAR(100),   
    ChapterName                 VARCHAR(100),         
    FindingName                 VARCHAR(64),  
    FindingAbbrName             VARCHAR(16),  
    CollectedDateTime           smalldatetime,
	ScheduledDttm               smalldatetime,  
    CreationTime                datetime,  
    EnteredDateTime             smalldatetime,  
    OBSValue                    text,      
    UnitOfMeasure               VARCHAR(20),  
    SpecialProcessingTypeCode   smallint,         
    AbnCrtIndicator             VARCHAR(20),              
    CollectedByLastName         VARCHAR(60),  
    CollectedByFirstName        VARCHAR(30),  
    CollectedByMIName           VARCHAR(30),  
    CollectedByTitle            VARCHAR(64),  
    CollectedAbbrName           VARCHAR(92),  
    AssessmentStatus            VARCHAR(35),  
    ChapterSortOrder            integer,  
    FindingSortOrder            integer,       
    RecordsFound                int,    
    Assessmentid                int,  
    Assessmentoid               int,  
    Observationoid              int,  
    ClinicalNote                text,  
    formoid                     int  
)
  
--Table to hold parsed form usage names FROM incoming @pvcFormUsageName parameter  
declare @tblFormUsageName table (
	FormUsageName VARCHAR(100)  
)  
  
--Table to hold parsed order status' FROM incoming @pchAssmtStatus parameter  
declare @tblAssmntStatus table (  
	AssmntStatus int
)   
  
--Table to hold Qualified Assessment IDs'  
DECLARE @AssessmentIDs table (
	PatientOID        integer,  
    PatientVisitOID   integer,  
    AssessmentID      integer,  
    CollectedDT       smalldatetime  
)  
--***********************************************************************************************  
-- Parameter Checking / validation   
--***********************************************************************************************  
  
-- Allow only the Location option for now.  
IF (@pchReportUsage = '2') OR (@pchReportUsage = '3')
	Set @pchPatientSelector = '1'  
  
-- CONVERT incoming parameter to numeric  
IF isnumeric(@pvchPatientOID) = 1
	SET @iPatientOID = CAST(@pvchPatientOID AS int)  
ELSE
	SET @iPatientOID = -1  
  
IF isnumeric(@pvchVisitOID) = 1
	SET @iVisitOID = CAST(@pvchVisitOID AS int)
ELSE
	SET @iVisitOID = -1  
  
IF(
	(@pvcDisplayOption IS NULL)
	OR
	(@pvcDisplayOption = '')
)
	SET @pvcDisplayOption = '1'  
    
-- Set the Result Display option -   
-- 0 = Get results for current day (Observation date of current day)  
-- 1 = Get Results for last 24 hours based AS of run date/time  
-- 2 = Get Results for Date Range   
-- 3 = Get last 6 most recent notes  
-- 4 = Get last 12 most recent notes  
-- 5 = Get All Notes  
-- 6 = # of hours  
-- 7 = Yesterday  
  
IF IsNumeric(@pchHours) = 1
	SET @iHours = CAST(@pchHours AS int)
ELSE
	SET @iHours = 0   
  
  
-- IF not display option sent assume '3'  
IF @pvcDisplayOption IS NULL OR @pvcDisplayOption = ''
	SET @pvcDisplayOption = '1'  
    
IF @pvcDisplayOption  = '0' -- Retreive results for current day only  
	BEGIN
		SET @dStartDate = CAST(CONVERT(VARCHAR(10), getdate(), 101) + ' 00:00:00' AS datetime)
		SET @dEndDate = CAST(CONVERT(VARCHAR(20),getdate())  AS datetime)
	END
	
IF @pvcDisplayOption  = '1' -- Retreive results for last 24 hours based on current day  
   BEGIN   
    SET @dStartDate = CAST(CONVERT(VARCHAR(20), getdate()-1)  AS datetime)     
    SET @dEndDate = CAST(CONVERT(VARCHAR(20),getdate())   AS datetime)  
   END   

IF @pvcDisplayOption  = '2' -- Retreive results using supplied date range  
   BEGIN
		-- Check for valid start date
		IF ISDATE(@pvcStartDate) = 1
			IF LEN(@pvcStartDate) < 12  
				SET @dStartDate = CAST(CONVERT(VARCHAR(10), @pvcStartDate, 101) + ' 00:00:00' AS datetime)
			ELSE
				SET @dStartDate = CAST(@pvcStartDate AS datetime)
		ELSE
			SET @dStartDate = CAST(CONVERT(VARCHAR(10), getdate(), 101) + ' 00:00:00' AS datetime)  
   
		 -- Check for valid through date   
		IF ISDATE(@pvcEndDate) = 1
			IF LEN(@pvcEndDate) < 12
				SET @dEndDate = CAST(CONVERT(VARCHAR(10), @pvcEndDate, 101) + ' 23:59:59' AS datetime)  
			ELSE  
				SET @dEndDate = CAST(@pvcEndDate AS datetime)  
		ELSE
			SET @dEndDate = CAST(CONVERT(VARCHAR(10),getdate(), 101) + ' 23:59:59' AS datetime)  
	END  
  
IF @pvcDisplayOption = '6' -- Retrieve results based on hours
	BEGIN
		SET @dStartDate =CAST(CONVERT(VARCHAR(20),DateAdd(hour,(@iHours * -1),Getdate()))AS datetime)      
		SET @dEndDate = CAST(CONVERT(VARCHAR(20), getdate()) AS datetime)    
	END    
  
IF @pvcDisplayOption  = '7' -- Retreive results for yesterday
	BEGIN
		SET @dStartDate = CAST(CONVERT(VARCHAR(10), getdate()-1 ,101) + ' 00:00:00' AS datetime)     
		SET @dEndDate = CAST(CONVERT(VARCHAR(10),getdate()-1, 101)  + ' 23:59:59' AS datetime)  
	END   
  
 --mxn Start Validation  
  
IF @pvcDisplayOption = '2'
	BEGIN
		IF (@dStartDate > @dEndDate )
			BEGIN
				RAISERROR ('OMSErrorNo=[65601], OMSErrorDesc=[End Date less than Start date]', 16, 1)
			END
	END   
  
-- parse formusage name parameters  
-- AND parse INTO to the form usage table  
IF (@pvcFormUsageName IS not NULL) AND (@pvcFormUsageName not Like 'All%')  
	BEGIN
		INSERT INTO @tblFormUsageName (
			FormUsageName  
		)   
		SELECT  *  
		FROM fn_GetStrParmTable(@pvcFormUsageName)  	
	END  
ELSE   
	BEGIN
		INSERT INTO @tblFormUsageName (
			FormUsageName  
		)   
		SELECT fu.DisplayName 
		FROM DCB_FormUsage fu   
		WHERE fu.FormType = 6  
        AND fu.DeletedInd = 0  
  
	End
  
  
-- Parse incoming Assessment Status Types parameter  
-- AND parse INTO to the Assessment Status table  
IF (@pchAssmtStatus IS NOT NULL)
	BEGIN
		INSERT INTO @tblAssmntStatus (
			AssmntStatus
		)   
		SELECT  *  
		FROM fn_GetStrParmTable(@pchAssmtStatus)  
	END  
  
--************************************************************************************************************  
--  BEGIN Main Procedure  
--************************************************************************************************************  
-- Get OID based CSP Usage --  
If (@pchReportUsage = '1') -- CSP Usage
	BEGIN
		IF (@pvcDisplayOption = '0') 
		OR (@pvcDisplayOption = '1') 
		OR (@pvcDisplayOption = '2') 
		OR (@pvcDisplayOption = '5')
		OR (@pvcDisplayOption = '6') 
		OR (@pvcDisplayOption = '7')
			BEGIN   
				-- get assessmentID
				INSERT INTO @AssessmentIDs
				
				SELECT PatientOID = ha.Patient_OID
				, 0
				, AssessmentID = ha.AssessmentID
				, CollectedDT = ha.CollectedDT
				
				FROM HAssessment AS ha WITH(nolock)
				INNER JOIN @tblAssmntStatus AS o1   
				ON o1.AssmntStatus  = ha.AssessmentStatusCode
				INNER JOIN @tblFormUsageName AS t1
				ON t1.FormUsageName = ha.FormUsageDisplayName
				
				WHERE (
					(ha.CollectedDT BETWEEN @dStartDate AND @dEndDate)
					OR 
					(@pvcDisplayOption = '5')
				) -- 5 = all occurrences -- 
				AND ha.EndDt IS NULL
				AND ha.Patient_OID = @iPatientOID  
				AND ha.FormTypeID = 6 -- Columnar Assessments only  
   
			END  
		ELSE
			IF (@pvcDisplayOption = '3') -- CSP Usage get / last 6 occurrences --
				BEGIN
					-- get last 6 assessments
					INSERT INTO @AssessmentIDs
					
					SELECT top 6 PatientOID = ha.Patient_OID
					, 0
					, AssessmentID = ha.AssessmentID
					, CollectedDT = ha.CollectedDT
					
					FROM HAssessment AS ha with(nolock)
					INNER JOIN @tblAssmntStatus AS o1
					ON o1.AssmntStatus  = ha.AssessmentStatusCode
					INNER JOIN @tblFormUsageName AS t1
					ON t1.FormUsageName = ha.FormUsageDisplayName
					
					WHERE ha.EndDt IS NULL
					AND ha.Patient_OID = @iPatientOID
					AND ha.FormTypeID = 6 -- Columnar Assessments only
					
					ORDER BY ha.CollectedDT DESC
				END
		ELSE
			IF (@pvcDisplayOption = '4') -- CSP Usage get /  get last 12 occurrences --
				BEGIN
					-- get last 12 assessments
					INSERT INTO @AssessmentIDs
					
					SELECT top 12 PatientOID = ha.Patient_OID
					, 0
					, AssessmentID = ha.AssessmentID
					, CollectedDT = ha.CollectedDT
					
					FROM HAssessment AS ha WITH(nolock)
					INNER JOIN @tblAssmntStatus AS o1
					ON o1.AssmntStatus  = ha.AssessmentStatusCode
					INNER JOIN @tblFormUsageName t1
					ON t1.FormUsageName = ha.FormUsageDisplayName
					
					WHERE ha.EndDt IS NULL
					AND ha.Patient_OID = @iPatientOID
					AND ha.FormTypeID = 6 -- Columnar Assessments only
					
					ORDER BY ha.CollectedDT DESC
			END
		END -- End of If (@pchReportUsage = '1') -- CSP Usage   
  
-- Get OIDS for Non-CSP Usage   
	If (@pchReportUsage = '2') OR (@pchReportUsage = '3') -- OPR / JS Usage
		BEGIN
			IF @pchPatientSelector = '1' -- Fetch patients by location
				BEGIN
					-- get assessmentID
					INSERT INTO @AssessmentIDs
					SELECT PatientOID = ha.Patient_OID
					, PatientVisitOID = ha.PatientVisit_OID
					, AssessmentID = ha.AssessmentID
					, CollectedDT = ha.CollectedDT
					
					FROM HAssessment AS ha with(nolock)
					INNER JOIN HPatientVisit AS pv
					ON ha.PatientVisit_OID = pv.objectid
						AND pv.isdeleted = 0
					INNER JOIN @tblAssmntStatus AS o1
					ON o1.AssmntStatus  = ha.AssessmentStatusCode
					INNER JOIN @tblFormUsageName t1
					ON t1.FormUsageName = ha.FormUsageDisplayName
					
					WHERE (
						(ha.CollectedDT BETWEEN @dStartDate AND @dEndDate)
						OR
						(@pvcDisplayOption = '5')
					) -- 5 = all occurrences --
					AND ha.EndDt IS NULL
					AND ha.Patient_OID = @iPatientOID
					AND ha.PatientVisit_OID = @iVisitOID
					AND ha.FormTypeID = 6 -- Columnar Assessments only
				END
			ELSE
				IF @pchPatientSelector = '2' -- Fetch patients by collected date time
					BEGIN
						-- get assessmentID
						INSERT INTO @AssessmentIDs
						
						SELECT PatientOID = ha.Patient_OID
						, PatientVisitOID = 0
						, AssessmentID = ha.AssessmentID
						, CollectedDT = ha.CollectedDT
						
						FROM HAssessment AS ha WITH(nolock)
						INNER JOIN @tblAssmntStatus AS o1
						ON o1.AssmntStatus  = ha.AssessmentStatusCode
						INNER JOIN @tblFormUsageName AS t1
						ON t1.FormUsageName = ha.FormUsageDisplayName
						
						WHERE ha.CollectedDT BETWEEN @dStartDate AND @dEndDate
						AND ha.EndDt IS NULL
						AND ha.Patient_OID = @iPatientOID
						AND ha.FormTypeID = 6 -- Columnar Assessments only
					END
				ELSE
					IF @pchPatientSelector = '3' -- Fetch patients by discharge date time
						BEGIN
							-- get assessmentID
							INSERT INTO @AssessmentIDs
							
							SELECT PatientOID = ha.Patient_OID
							, PatientVisitOID = ha.PatientVisit_OID
							, AssessmentID = ha.AssessmentID
							, CollectedDT = ha.CollectedDT
							
							FROM HAssessment AS ha with(nolock)
							INNER JOIN HPatientVisit AS pv
							ON ha.PatientVisit_OID = pv.objectid
								AND pv.isdeleted = 0
							INNER JOIN @tblAssmntStatus AS o1
							ON o1.AssmntStatus  = ha.AssessmentStatusCode
							INNER JOIN @tblFormUsageName AS t1
							ON t1.FormUsageName = ha.FormUsageDisplayName
							
							WHERE ha.EndDt IS NUL
							AND ha.Patient_OID = @iPatientOID
							AND ha.PatientVisit_OID = @iVisitOID
							AND ha.FormTypeID = 6 -- Columnar Assessments only
						END
					END -- END of IF (@pchReportUsage = '2') OR (@pchReportUsage = '3') -- OPR / JS Usage
					-- Fetch Records --
					IF (@pchShowNullFindings = '1')
						BEGIN
							INSERT INTO @tmpAssessment (
								Patientoid
								, PatientVisitoid
								, FormUsageName
								, ChapterName
								, findingName
								, FindingAbbrName
								, CollectedDateTime
								, ScheduledDttm
								, CreationTime
								, EnteredDateTime
								, OBSValue
								, UnitOfMeasure
								, SpecialProcessingTypeCode
								, AbnCrtIndicator
								, CollectedByLastName
								, CollectedByFirstName
								, CollectedByMIName
								, CollectedByTitle
								, CollectedAbbrName
								, AssessmentStatus
								, ChapterSortOrder
								, FindingSortOrder
								, RecordsFound
								, Assessmentid
								, Assessmentoid
								, Observationoid
								, ClinicalNote
								, formoid
							)
							
							SELECT Patientoid = ha.Patient_oid
							, PatientVisitoid = ha.PatientVisit_oid
							, FormUsageName = ISNULL(ha.FormUsageDisplayName,'')
							, ChapterName = ISNULL(hac.FormUsageDisplayName,ha.FormUsageDisplayName)
							, FindingName = ISNULL(ho.FindingName,hafe.displayName)
							, FindingAbbrName = ISNULL(ho.FindingAbbr,hafe.Name)
							, CollectedDateTime = ha.CollectedDT
							, ScheduleDttm = ha.ScheduledDT
							, CreationTime = ha.CreationTime
							, EnteredDateTime = ha.EnteredDT
							, OBSValue = CASE 
								WHEN ISNULL(ho.Value, '') = '' 
									THEN CASE
										WHEN (ho.ProcessingTypeCode = 3) OR (ho.ProcessingTypeCode = 4)
											THEN
												CASE
													WHEN (
														(CHARINDEX('/', ho.InternalValue) > 1)
														AND (CHARINDEX('/', ho.InternalValue) < LEN(ho.InternalValue))
													) 
														THEN ho.InternalValue
														ELSE LTRIM(REPLACE(ho.InternalValue,'/',''))
												END
											ELSE
												CASE
													WHEN ho.findingdatatype = 9 
													AND ho.Internalvalue <> '' 
													AND ((ISNUMERIC(ho.Internalvalue) = 1 OR ISDATE(ho.Internalvalue) = 1)) 
														THEN 
															CASE
																WHEN (charindex(':',ho.Internalvalue) =  3) 
																	THEN LEFT(ho.value,5)
																WHEN LEN(ho.Internalvalue) = 8 
																AND ISDATE(ho.Internalvalue) = 1 
																	THEN SUBSTRING(ho.Internalvalue,1,4) + 
																		'-' +  
																		SUBSTRING(ho.Internalvalue,5,2) + 
																		'-' +  
																		SUBSTRING(ho.Internalval)
																WHEN LEN(ho.Internalvalue) > 8 
																AND ISDATE(ho.Internalvalue) = 1 
																	THEN SUBSTRING(ho.Internalvalue,1,4) + 
																		'-' + 
																		SUBSTRING(ho.Internalvalue,5,2) +
																		'-' + 
																		SUBSTRING(ho.Internalvalue,7,2) + 
																		' ' + 
																		SUBSTRING(ho.Internalvalue,10,8)
																WHEN LEN(ho.Internalvalue) > 8 
																AND ISNUMERIC(ho.Internalvalue) = 1 
																	THEN SUBSTRING(ho.Internalvalue,1,4) + 
																	'-' + 
																	SUBSTRING(ho.Internalvalue,5,2) + 
																	'-' + 
																	SUBSTRING(ho.Internalvalue,7,2) + 
																	' ' + 
																	SUBSTRING(ho.Internalvalue,9,2) + 
																	':' + +
																	SUBSTRING(ho.Internalvalue,11,2) + 
																	':' + +
																	SUBSTRING(ho.Internalvalue,13,2)   
																	ELSE ISNULL(REPLACE(ho.InternalValue, CHAR(30), ', '),'')
															END
														ELSE HO.InternalValue
												END
										END
									ELSE
										CASE
											WHEN (
												ho.ProcessingTypeCode = 3 
												OR 
												ho.ProcessingTypeCode = 4
											)
												THEN 
													CASE
														WHEN (
															(CHARINDEX('/', ho.Value) > 1)  
															AND (CHARINDEX('/', ho.Value) < LEN(ho.Value))
														)
															THEN ho.Value
															ELSE LTRIM(REPLACE(ho.Value,'/',''))
													END
												ELSE
													CASE
														WHEN ho.findingdatatype = 9 
														AND ho.value <> '' 
														AND (isnumeric(ho.value) = 1 OR ISDATE(ho.value) = 1) 
															THEN
																CASE
																	WHEN (charindex(':',ho.value) =  3) 
																		THEN LEFT(ho.value,5) 
																	WHEN LEN(ho.value) = 8 
																	AND ISDATE(ho.value) = 1 
																		THEN SUBSTRING(ho.value,1,4) + 
																		'-' +  
																		SUBSTRING(ho.value,5,2) + 
																		'-' +  
																		SUBSTRING(ho.value,7,2)
																	WHEN LEN(ho.value) > 8 
																	AND ISDATE(ho.value) = 1 
																		THEN SUBSTRING(ho.value,1,4) + 
																		'-' + 
																		SUBSTRING(ho.value,5,2) + 
																		'-' +  
																		SUBSTRING(ho.value,7,2) + 
																		' ' + 
																		SUBSTRING(ho.value,10,8)
																	WHEN LEN(ho.value) > 8 
																	AND ISNUMERIC(ho.value) = 1 
																		THEN  SUBSTRING(ho.value,1,4) + 
																		'-' + 
																		SUBSTRING(ho.value,5,2) + 
																		'-' +  
																		SUBSTRING(ho.value,7,2)  + 
																		' ' + 
																		SUBSTRING(ho.value,9,2) + 
																		':' + + 
																		SUBSTRING(ho.value,11,2) + 
																		':' + + SUBSTRING(ho.value,13,2)
															ELSE ISNULL(REPLACE(ho.Value, CHAR(30), ', '),'')
													END
												ELSE REPLACE(ho.Value, CHAR(30), ', ')
										END
								END   
							END
							, UnitOfMeasure = ISNULL(ho.UOM,'')
							, SpecialProcessingTypeCode = ISNULL(ho.ProcessingTypeCode,'')
							, AbnCrtIndicator = ISNULL(ho.AbnCrtIndicator,'')
							, CollectedByLastName = IsNull(nm.LastName, '')
							, CollectedByFirstName = IsNull(nm.FirstName, '')
							, CollectedByMIName = IsNull(nm.MiddleName, '')
							, CollectedByTitle = ISNULL(nm.Title,'')
							, CollectedAbbrName = ISNULL(ha.UserAbbrName,'')
							, AssessmentStatus = ISNULL(ha.AssessmentStatus, '')
							, ChapterSequence  = ISNULL(hac.SequenceNumber,9999)
							, DisplaySequence = ISNULL(hafe.TabOrder,9999)
							, RecordsFound = 0
							, Assessmentid = ha.AssessmentID
							, Assessmentoid = ha.ObjectID
							, Observationoid = ho.ObjectID
							, ClinicalNote = cn.NoteText
							, formoid = ha.form_oid
							
							FROM @AssessmentIDs AS a1
							INNER JOIN HAssessment AS ha WITH(NOLOCK
							ON a1.AssessmentID = ha.AssessmentID
							INNER JOIN HAssessmentCategory AS hac WITH(NOLOCK)
							ON ha.AssessmentID = hac.assessmentID
								AND hac.CategoryStatus NOT IN (0, 3)
								AND hac.IsLatest = 1
							INNER JOIN HAssessmentFormElement AS hafe WITH(NOLOCK)
							ON hac.form_oid = hafe.formid
								AND hac.formversion = hafe.formversion
							LEFT OUTER JOIN HObservation AS ho WITH(NOLOCK)
							ON a1.assessmentid = ho.assessmentid
								AND ha.patient_oid = ho.patient_oid
								AND ho.FindingAbbr = hafe.Name
								AND ho.Finding_oid = hafe.OID
								AND ho.EndDt IS NULL
								AND ho.ObservationStatus LIKE 'A%'
								AND ho.FindingName NOT IN (
									'HPatient_AdvancedDirective'
									, 'HPatient_AlertMessage'
									, 'HPatient_DiagnosisCode'
									, 'HPatient_DiagnosisDescription'
									, 'HPatient_IsolationIndicator'
									, 'HPatient_PrimaryLanguage'
									, 'HPatient_Religion'
									, 'HPatient_Sex'
								)
							LEFT OUTER JOIN HSUser AS hsu WITH(NOLOCK)
							ON hsu.ObjectID = ha.User_oid
							LEFT OUTER JOIN HName AS nm
							ON nm.Person_oid = hsu.Person_OID
							AND (
								EndDateOfValidity IS NULL
								OR EndDateOfValidity = '1899-12-30 00:00:00'
							)
							LEFT OUTER JOIN HClinicalNote AS cn WITH(NOLOCK)
							ON ha.Assessmentid = cn.LinkObjectID
								AND ha.Patient_oid = cn.PatientID
								AND cn.EndDT IS NULL
								AND cn.NoteStatus <> 0
								AND cn.EnteredDt = (
									SELECT MAX(cn2.EnteredDt) 
									FROM HClinicalNote AS cn2 WITH(NOLOCK)
									WHERE cn.patientID = cn2.patientID
									AND cn.linkobjectid = cn2.linkobjectid
								)
							
							WHERE  ha.Patient_oid = @iPatientOID
							AND ha.EndDt IS NULL
							--AND hac.IsLatest = 1
					END
					ELSE BEGIN
						INSERT INTO @tmpAssessment (
							Patientoid
							, PatientVisitoid
							, FormUsageName
							, ChapterName
							, FindingName
							, FindingAbbrName
							, CollectedDateTime
							, ScheduledDttm
							, CreationTime
							, EnteredDateTime
							, OBSValue
							, UnitOfMeasure
							, SpecialProcessingTypeCode
							, AbnCrtIndicator
							, CollectedByLastName
							, CollectedByFirstName
							, CollectedByMIName
							, CollectedByTitle
							, CollectedAbbrName
							, AssessmentStatus
							, ChapterSortOrder
							, FindingSortOrder
							, RecordsFound
							, Assessmentid
							, Assessmentoid
							, Observationoid
							, ClinicalNote
							, formoid
						)
						
						SELECT Patientoid = ha.Patient_oid
						, PatientVisitoid = ha.PatientVisit_oid
						, FormUsageName = ISNULL(ha.FormUsageDisplayName,'')
						, ChapterName = ISNULL(hac.FormUsageDisplayName,ha.FormUsageDisplayName)
						, FindingName = ISNULL(ho.FindingName,'')
						, FindingAbbrName = ISNULL(ho.FindingAbbr,'')
						, CollectedDateTime = ha.CollectedDT
						, ScheduleDttm = ha.ScheduledDT
						, CreationTime = ha.CreationTime
						, EnteredDateTime = ha.EnteredDT
						, OBSValue = CASE 
							WHEN ISNULL(ho.Value, '') = ''
								THEN CASE 
									WHEN ho.ProcessingTypeCode = 3 OR ho.ProcessingTypeCode = 4 
										THEN CASE 
											WHEN (
												(CHARINDEX('/', ho.InternalValue) > 1)
												AND (CHARINDEX('/', ho.InternalValue) < LEN(ho.InternalValue))
											)
												THEN ho.InternalValue
												ELSE LTRIM(REPLACE(ho.InternalValue,'/',''))
											END
										ELSE CASE
											WHEN ho.findingdatatype = 9 
											AND ho.Internalvalue <> '' 
											AND (isnumeric(ho.Internalvalue) = 1 OR ISDATE(ho.Internalvalue) = 1) 
												THEN CASE 
													WHEN (charindex(':',ho.Internalvalue) =  3) 
														THEN left(ho.value,5)
                                                    WHEN LEN(ho.Internalvalue) = 8 
													AND ISDATE(ho.Internalvalue) = 1 
														THEN SUBSTRING(ho.Internalvalue,1,4) + 
														'-' + 
														SUBSTRING(ho.Internalvalue,5,2) + 
														'-' +  
														SUBSTRING(ho.Internalvalue,7,2)
													WHEN LEN(ho.Internalvalue) > 8 
													AND ISDATE(ho.Internalvalue) = 1 
														THEN SUBSTRING(ho.Internalvalue,1,4) + 
														'-' + 
														SUBSTRING(ho.Internalvalue,5,2) + 
														'-' + 
														SUBSTRING(ho.Internalvalue,7,2) + 
														' ' + 
														SUBSTRING(ho.Internalvalue,10,8)
													WHEN LEN(ho.Internalvalue) > 8 
													AND ISNUMERIC(ho.Internalvalue) = 1 
														THEN SUBSTRING(ho.Internalvalue,1,4) + 
														'-' + 
														SUBSTRING(ho.Internalvalue,5,2) + 
														'-' + 
														SUBSTRING(ho.Internalvalue,7,2) + 
														' ' + 
														SUBSTRING(ho.Internalvalue,9,2) + 
														':' + + 
														SUBSTRING(ho.Internalvalue,11,2) + 
														':' + + 
														SUBSTRING(ho.Internalvalue,13,2)
														ELSE  ISNULL(REPLACE(ho.InternalValue, CHAR(30), ', '),'')
													END       
												ELSE HO.InternalValue
										END
								END   
							ELSE  CASE 
								WHEN ho.ProcessingTypeCode = 3 OR ho.ProcessingTypeCode = 4 
									THEN CASE 
										WHEN (
											(CHARINDEX('/', ho.Value) > 1)  
											AND (CHARINDEX('/', ho.Value) < LEN(ho.Value))
										) 
											THEN ho.Value  
											ELSE LTRIM(REPLACE(ho.Value,'/',''))
									`	END
								ELSE
									CASE 
										WHEN ho.findingdatatype = 9 
										AND ho.value <> '' 
										AND (isnumeric(ho.value) = 1 OR ISDATE(ho.value) = 1) 
											THEN CASE 
												WHEN (CHARINDEX(':',ho.value) =  3) 
													THEN LEFT(ho.value,5)
												WHEN LEN(ho.value) = 8 
												AND ISDATE(ho.value) = 1 
													THEN SUBSTRING(ho.value,1,4) + 
														'-' +  
														SUBSTRING(ho.value,5,2) + 
														'-' +  
														SUBSTRING(ho.value,7,2)
												WHEN LEN(ho.value) > 8 
												AND ISDATE(ho.value) = 1 
													THEN SUBSTRING(ho.value,1,4) + 
														'-' +
														SUBSTRING(ho.value,5,2) + 
														'-' + 
														SUBSTRING(ho.value,7,2) + 
														' ' + 
														SUBSTRING(ho.value,10,8)
												WHEN LEN(ho.value) > 8 
												AND ISNUMERIC(ho.value) = 1 
													THEN SUBSTRING(ho.value,1,4) + 
														'-' + 
														SUBSTRING(ho.value,5,2) + 
														'-' +  
														SUBSTRING(ho.value,7,2) + 
														' ' + 
														SUBSTRING(ho.value,9,2) + 
														':' + + 
														SUBSTRING(ho.value,11,2) + 
														':' + + 
														SUBSTRING(ho.value,13,2)
													ELSE ISNULL(REPLACE(ho.Value, CHAR(30), ', '),'')
												END
											ELSE REPLACE(ho.Value, CHAR(30), ', ')
									END
							END   
                        END
						, UnitOfMeasure = ISNULL(ho.UOM,'')
						, SpecialProcessingTypeCode = ISNULL(ho.ProcessingTypeCode,'')
						, AbnCrtIndicator = ISNULL(ho.AbnCrtIndicator,'')
						, CollectedByLastName = IsNull(nm.LastName, '')
						, CollectedByFirstName = IsNull(nm.FirstName, '')
						, CollectedByMIName = IsNull(nm.MiddleName, '')
						, CollectedByTitle = ISNULL(nm.Title,'')
						, CollectedAbbrName = ISNULL(ha.UserAbbrName,'')
						, AssessmentStatus = ISNULL(ha.AssessmentStatus, '')
						, ChapterSequence  = ISNULL(hac.SequenceNumber,9999)
						, DisplaySequence = ISNULL(hafe.TabOrder,9999)
						, RecordsFound = 0
						, Assessmentid = ha.AssessmentID
						, Assessmentoid = ha.ObjectID
						, Observationoid = ho.ObjectID
						, ClinicalNote = cn.NoteText
						, formoid = ha.form_oid
						
						FROM @AssessmentIDs AS a1
						INNER JOIN HAssessment AS ha WITH(NOLOCK)
						ON a1.AssessmentID = ha.AssessmentID
						INNER JOIN HAssessmentCategory AS hac WITH(NOLOCK)
						ON ha.AssessmentID = hac.assessmentID
							AND hac.CategoryStatus NOT IN (0, 3)
							AND hac.IsLatest = 1
						INNER JOIN HAssessmentFormElement AS hafe WITH(NOLOCK)
						ON hac.form_oid = hafe.formid
							AND hac.formversion = hafe.formversion
						INNER JOIN HObservation AS ho WITH(NOLOCK)
						ON a1.assessmentid = ho.assessmentid
							AND ha.patient_oid = ho.patient_oid
							AND ho.FindingAbbr = hafe.Name
							AND ho.Finding_oid = hafe.OID
							AND ho.EndDt IS NULL
							AND ho.ObservationStatus ='AV'
						LEFT OUTER JOIN HSUser AS hsu WITH(NOLOCK)
						ON hsu.ObjectID = ha.User_oid
						LEFT OUTER JOIN HName AS nm
						ON nm.Person_oid = hsu.Person_OID
							AND (
								EndDateOfValidity IS NULL 
								OR
								EndDateOfValidity = '1899-12-30 00:00:00'
							)
						LEFT OUTER JOIN HClinicalNote AS cn WITH(NOLOCK)
						ON ha.Assessmentid = cn.LinkObjectID
							AND ha.Patient_oid = cn.PatientID
							AND cn.EndDT IS NULL
							AND cn.NoteStatus <> 0
							AND cn.EnteredDt = (
								SELECT MAX(cn2.EnteredDt)
								FROM HClinicalNote AS cn2 WITH(NOLOCK)
								WHERE cn.patientID = cn2.patientID
								AND cn.linkobjectid = cn2.linkobjectid
							)
						
						WHERE  ha.Patient_oid = @iPatientOID
						AND ha.EndDt IS NULL
						--AND hac.IsLatest = 1
						AND ho.FindingName NOT IN ('
							HPatient_AdvancedDirective'
							, 'HPatient_AlertMessage'
							, 'HPatient_DiagnosisCode'
							, 'HPatient_DiagnosisDescription'
							, 'HPatient_IsolationIndicator'
							, 'HPatient_PrimaryLanguage'
							, 'HPatient_Religion'
							, 'HPatient_Sex'
						)
END  
  
--Remove the Acutity Chapter FROM the Med Surge Shift Assessment  
--This request was specified by Megan Sibly  
DELETE FROM @tmpAssessment  
WHERE FormUsageName = 'Med Surg Shift Assessment'  
AND ChapterName = 'Patient Acuity' 
 
--****************************************************************************************************  
-- Final SELECT  
--****************************************************************************************************  
  
Set @iRecCount = (SELECT count(*) FROM @tmpAssessment)  

If @iRecCount > 0
	BEGIN
		UPDATE @tmpAssessment
		SET RecordsFound = @iRecCount
END  
  
-- Return final record SET    
If @iRecCount > 0
	BEGIN
		IF @pchDateSort ='1'
			SELECT Patientoid
			, PatientVisitoid
			, FormUsageName
			, ChapterName
			, FindingName
			, FindingAbbrName
			, CollectedDateTime
			, ScheduledDttm
			, CreationTime
			, EnteredDateTime
			, OBSValue
			, UnitOfMeasure
			, SpecialProcessingTypeCode
			, AbnCrtIndicator
			, CollectedByLastName
			, CollectedByFirstName
			, CollectedByMIName
			, CollectedByTitle
			, CollectedAbbrName
			, AssessmentStatus
			, ChapterSortOrder
			, FindingSortOrder
			, RecordsFound
			, Assessmentid
			, Assessmentoid
			, Observationoid
			, ClinicalNote
			
			FROM @tmpAssessment AS v1
			
			ORDER BY v1.PatientOID
			, v1.PatientVisitOID
			, v1.CollectedDateTime asc
			, v1.FormUsageName
			, v1.ChapterSortOrder
			, v1.FindingSortOrder asc
			, v1.FindingAbbrName
		
		ELSE
			SELECT Patientoid
			, PatientVisitoid
			, FormUsageName
			, ChapterName
			, FindingName
			, FindingAbbrName
			, CollectedDateTime
			, ScheduledDttm
			, CreationTime
			, EnteredDateTime
			, OBSValue
			, UnitOfMeasure
			, SpecialProcessingTypeCode
			, AbnCrtIndicator
			, CollectedByLastName
			, CollectedByFirstName
			, CollectedByMIName
			, CollectedByTitle
			, CollectedAbbrName
			, AssessmentStatus
			, ChapterSortOrder
			, FindingSortOrder
			, RecordsFound
			, Assessmentid
			, Assessmentoid
			, Observationoid
			, ClinicalNote
			
			FROM @tmpAssessment AS v1
			
			ORDER BY v1.PatientOID
			, v1.PatientVisitOID desc
			, v1.CollectedDateTime desc
			, v1.FormUsageName
			, v1.ChapterSortOrder
			, v1.FindingSortOrder asc
			, v1.FindingAbbrName   
          
         END   
		ELSE --RecCount = 0
			BEGIN
				-- fill table with dummy data
				INSERT INTO @tmpAssessment (
					Patientoid
					PatientVisitoid
					, FormUsageName
					, ChapterName
					, FindingName
					, FindingAbbrName
					, CollectedDateTime
					, ScheduledDttm
					, CreationTime
					, EnteredDateTime
					, OBSValue
					, UnitOfMeasure
					, SpecialProcessingTypeCode
					, AbnCrtIndicator
					, CollectedByLastName
					, CollectedByFirstName
					, CollectedByMIName
					, CollectedByTitle
					, CollectedAbbrName
					, AssessmentStatus
					, ChapterSortOrder
					, FindingSortOrder
					, RecordsFound
					, Assessmentid
					, Assessmentoid
					, Observationoid
					, ClinicalNote
					, formoid  
                )
				
				SELECT Patientoid = -1
				, PatientVisitoid = -1
				, FormUsageName = ''
				, ChapterName = ''
				, FindingName = ''
				, FindingAbbrName = ''
				, CollectedDateTime = NULL
				, ScheduleDttm = NULL
				, CreationTime = NULL
				, EnteredDateTime = NULL
				, OBSValue = ''
				, UnitOfMeasure = ''
				, SpecialProcessingTypeCode = ''
				, AbnCrtIndicator = ''
				, CollectedByLastName = ''
				, CollectedByFirstName = ''
				, CollectedByMIName = ''
				, CollectedByTitle = ''
				, CollectedAbbrName = ''
				, AssessmentStatus = ''
				, ChapterSortOrder = 0
				, FindingSortOrder = 0
				, RecordsFound = 0
				, Assessmentid = -1
				, Assessmentoid = -1
				, Observationoid = -1
				, ClinicalNote = ''
				, formoid = -1
				
				-- return record SET
				SELECT Patientoid
				, PatientVisitoid
				, FormUsageName
				, ChapterName
				, FindingName
				, FindingAbbrName
				, CollectedDateTime
				, ScheduledDttm
				, CreationTime
				, EnteredDateTime
				, OBSValue
				, UnitOfMeasure
				, SpecialProcessingTypeCode
				, AbnCrtIndicator
				, CollectedByLastName
				, CollectedByFirstName
				, CollectedByMIName
				, CollectedByTitle
				, CollectedAbbrName
				, AssessmentStatus
				, ChapterSortOrder
				, FindingSortOrder
				, RecordsFound
				, Assessmentid
				, Assessmentoid
				, Observationoid
				, ClinicalNote
				
				FROM @tmpAssessment AS v1
				
				ORDER BY v1.PatientOID
				, v1.PatientVisitOID
				, v1.CollectedDateTime desc
				, v1.FormUsageName
				, v1.ChapterSortOrder
				, v1.FindingSortOrder asc
				, v1.FindingAbbrName   
       END             
