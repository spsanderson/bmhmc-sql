USE [Soarian_Clin_Tst_1]
GO
/****** Object:  StoredProcedure [dbo].[ORE_BHMC_IntegumentaryReport_SubReport_PressureInjury]    Script Date: 9/18/2018 12:17:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
/* 
Inpatient Integumentary Report
    
---------------------------------------------------------------------
      
File:     ORE_BHMC_IntegumentaryReport.sql      
      
Input  Parameters:     
	@pchReportUsage as Used to indicate how the report is being run    
        1 = Context Senstive (CSP) Patient Context    
        2 = Operational Reporting (OPR)    
        3 = Job Scheduler (JS) 
------------------------------------------------------------------------------      
Purpose:  Inpatient Integumentary Report    
        
Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle
		
Tables:
	HPatientVisit
	HAssessment
	HPatient
	HPerson
	HObservation
	
Views:       
      
Functions:
	fn_GetStrParmTable(@pvcLocation)
	fn_GetIntegumentaryReport_SubReport()
      
Revision History:      
       
Date		Version		Description      
----		-------		-----------  
31-AUG-11	v1			Excluding patients who have no assessments charted - handling 'NO RECORDS'    
26-AUG-11	v2			Updated SP to pick up latest collected date among multiple findings    
18-AUG-11	v3			Updated SP to pick up latest finding from across assessments  
23-JUN-11	v4			Updating SP   
21-Jun-11	v5			Customizing the report for nurse station  
12-May-11	v6			Customized as per new requirement.   
23-Mar-11	v7     		New Stored procedure    
2018-09-18	v8			Add Admit Date
						Clean up code to make readable, it was a horrendous
						mess, how anyone followed it is beyond me
------------------------------------------------------------------------------     
*/ 

--EXEC [ORE_BHMC_IntegumentaryReport_SubReport] '94178183'  
--EXEC [ORE_BHMC_IntegumentaryReport_SubReport_test2] '94178183'  
--EXEC [ORE_BHMC_IntegumentaryReport_SubReport_Test2] '30001176'  
--EXEC [ORE_BHMC_IntegumentaryReport_SubReport_Test4] '30001176'  
--EXEC [ORE_BHMC_IntegumentaryReport_SubReport_test4] '3NOR,2CAD,2EAS,2MAI,2NOR,2PED,2SOU,2WST'  

ALTER PROCEDURE [dbo].[ORE_BHMC_IntegumentaryReport_SubReport_PressureInjury_TEST]
--ALTER PROCEDURE [dbo].[ORE_BHMC_IntegumentaryReport_SubReport_PressureInjury]
  @pvcLocation   VARCHAR(20) = NULL    
AS   
  
SET NOCOUNT ON  
  
DECLARE @iPatientOID INT
, @iPatientVisitOID INT
, @FormUsageDisplayName VARCHAR(100)
, @iRecordsCount INT
, @iEntityOID INT
  
SELECT @FormUsageDisplayName = 'Integumentary'    
  
CREATE TABLE #tempLocation(
	tblLocation VARCHAR(1000)
)
  
  
-- VALIDATE INCOMING LOCATION PARAMETER  
IF (
	(@pvcLocation IS NULL)
	OR
	(@pvcLocation = '')
)

BEGIN
	RAISERROR ( 'OMSErrorNo=[65601], OMSErrorDesc=[No location has been selected].', 16,1 )               
	RETURN
END
 
ELSE BEGIN
	INSERT INTO #tempLocation (
		tblLocation
	)  
    SELECT * 
	FROM fn_GetStrParmTable(@pvcLocation)  
END;

Declare @dateFrom as datetime;
Declare @dateTo as Datetime;

Set @dateFrom = (Select GETDATE()-1);
Set @dateTo = (select GETDATE());

CREATE TABLE #patientinfo(   
  iPatientOID       INT,  
  iPatientVisitOID  INT,  
  iEntityOID        INT,  
  PatientAccountID  VARCHAR(1000),  
  ident             INT IDENTITY(1,1)  
  )  
  
INSERT INTO #patientinfo

SELECT DISTINCT iPatientOID = pv.Patient_OID
, iPatientVisitOID = pv.objectID
, iEntityOID = pv.Entity_oid
, PatientAccountID = pv.PatientAccountID

FROM HPatientVisit pv WITH(NOLOCK)  
INNER JOIN HAssessment ha WITH(NOLOCK)  
ON ha.Patient_oid = pv.Patient_oid  
	AND ha.PatientVisit_oid = pv.ObjectID  
INNER JOIN #tempLocation t1  
ON t1.tblLocation = pv.PatientLocationName   

WHERE ha.FormUsageDisplayName = @FormUsageDisplayName  
AND ha.EndDT IS NULL  
AND ha.CollectedDT BETWEEN @dateFrom AND @dateTo  

CREATE TABLE #tmpPressureUlcerWound (
	CollectedDt    DATETIME
	, DisplayName  VARCHAR(300)
	, FindingAbbr  VARCHAR(100)
	, Value        VARCHAR(MAX)
	, PageNumber   INT
	, RowNumber    INT
	, ColumnNumber INT
)

CREATE Table #Final (
	RecordsCount           INT
	, PatientName          VARCHAR(500)
	, MRN                  VARCHAR(100)
	, Location             VARCHAR(200)
	, Room_Bed             VARCHAR(100)
	, CollectedDateTime    DATETIME
	, DishcargeDateTime    DATETIME
	, VisitStartDateTime   DATETIME
	, DischargeDisposition VARCHAR(1000)
	, PatientAccountID     VARCHAR(1000)
	, PageNumber           INT
	, RowNumber            INT
	, CollectedDT	       DATETIME
	, CollectedDT1         DATETIME
	, CollectedDt2         DATETIME
	, CollectedDt3         DATETIME
	, CollectedDt4         DATETIME
	, CollectedDt5         DATETIME
	, DisplayName1         VARCHAR(300)
	, DisplayName2         VARCHAR(300)
	, DisplayName3         VARCHAR(300)
	, DisplayName4         VARCHAR(300)
	, DisplayName5         VARCHAR(300)
	, FindingAbbr1         VARCHAR(100)
	, FindingAbbr2         VARCHAR(100)
	, FindingAbbr3         VARCHAR(100)
	, FindingAbbr4         VARCHAR(100)
	, FindingAbbr5         VARCHAR(100)
	, Value1               VARCHAR(MAX)
	, Value2               VARCHAR(MAX)
	, Value3               VARCHAR(MAX)
	, Value4               VARCHAR(MAX)
	, Value5               VARCHAR(MAX)
)  
  
DECLARE @PatientName    VARCHAR(500)
, @PatientAcctNum       VARCHAR(100)
, @MRNumber             VARCHAR(100)
, @Location             VARCHAR(200)
, @RoomBed              VARCHAR(100)
, @VisitStartDateTime   DATETIME
, @VisitEndDateTime     DATETIME
, @dtCollectedDt        DATETIME
, @DischargeDisposition VARCHAR(1000)  
, @iAssessmentID        INT 
, @count                INT

SET @count = (SELECT COUNT(*) FROM #patientinfo)

WHILE (@count>=1)  
BEGIN
	SELECT @iPatientOID = pv.Patient_OID
	, @iPatientVisitOID = pv.objectID
	, @iEntityOID = pv.Entity_oid

	FROM HPatientVisit pv WITH(NOLOCK)

	WHERE pv.PatientAccountID IN (Select TOP 1 PatientAccountID FROM #patientinfo WHERE ident = @count)  
    
	-- Get patient info for the report      
    -- Select Patient info into the Patient table             
    SELECT  @PatientName = 
		CASE ISNULL(pt.GenerationQualifier, '')
			WHEN ''
				THEN pt.LastName + ', ' + pt.FirstName + ' ' + ISNULL(SUBSTRING(pt.MiddleName, 1, 1),' ')
				ELSE pt.LastName + ' ' + pt.GenerationQualifier + ', ' + pt.FirstName + ' ' + ISNULL(SUBSTRING(pt.MiddleName, 1, 1), ' ')
        END    
    , @PatientAcctNum = isnull(pv.PatientAccountID, '')    
    , @MRNumber = isnull(.dbo.fn_ORE_GetExternalPatientID(pt.ObjectID, isnull(pv.entity_oid, @iEntityOID)),  '')      
    , @Location = isnull(pv.PatientLocationName, '')    
    , @RoomBed = isnull(pv.LatestBedName, '')   
    , @VisitStartDateTime = pv.VisitStartDateTime    
    , @VisitEndDateTime = pv.VisitEndDateTime     
    , @DischargeDisposition = ISNULL(pv.DischargeDisposition,'')                        
    
	FROM HPatient AS pt WITH(NOLOCK)
    INNER JOIN HPatientVisit AS pv WITH (NOLOCK)
    ON pt.ObjectID = pv.Patient_OID    
		and pv.ObjectID = @iPatientVisitOID  
    INNER JOIN HAssessment AS ha WITH(NOLOCK)
	ON ha.Patient_oid = pv.Patient_oid
		AND ha.PatientVisit_oid = pv.ObjectID    
	INNER JOIN HPerson AS per WITH(NOLOCK)
	ON pt.ObjectID = per.ObjectID

	WHERE Pt.ObjectID = @iPatientOID
	AND ha.CollectedDT BETWEEN @dateFrom and @dateTo
	
	INSERT INTO #tmpPressureUlcerWound

	SELECT ''
	, * 
	FROM fn_GetIntegumentaryReport_SubReport() 
	
	ORDER BY pagenumber
	, rownumber
	, ColumnNumber

	SELECT ha.AssessmentID
	, ha.CollectedDt
	, ho.FindingAbbr
	, ho.FindingName
	, ho.Value
	, Rank1 = RANK() OVER(
		PARTITION BY ha.Patient_OID
		, ha.PatientVisit_oid
		, ho.FindingAbbr
		
		ORDER BY ha.CollectedDT DESC
		, ha.AssessmentID DESC
	)
		
	INTO #tmpObservationDetails

	FROM HAssessment AS ha WITH(NOLOCK)
	INNER JOIN HObservation ho WITH(NOLOCK)
	ON ha.AssessmentID = ho.AssessmentID
		AND ha.Patient_oid = ho.Patient_oid

	WHERE ha.Patient_oid = @iPatientOID
	AND ha.PatientVisit_oid = @iPatientVisitOID  
	AND ha.FormUsageDisplayName = @FormUsageDisplayName
	AND ha.EndDT IS NULL
	AND ho.EndDT  IS NULL
	AND ho.ObservationStatus like 'A%'
	AND ho.Value <> ''
	AND ha.CollectedDT BETWEEN @dateFrom and @dateTo

	ORDER BY ha.CollectedDT DESC

	DELETE FROM #tmpObservationDetails WHERE Rank1 > 1

	UPDATE t1
		SET t1.CollectedDT = ISNULL(t2.CollectedDT,NULL)
		, t1.Value = ISNULL(t2.Value,'')

		FROM #tmpPressureUlcerWound AS t1
		LEFT OUTER JOIN #tmpObservationDetails AS t2
		ON t1.FindingAbbr = t2.FindingAbbr

	SELECT @iRecordsCount = COUNT(*) FROM #tmpPressureUlcerWound WHERE Value <> ''

	SELECT DISTINCT CollectedDt
	, Rank1 = DENSE_RANK() OVER (PARTITION BY '' ORDER BY CollectedDT DESC)

	INTO #tmpTopCollectedDt

	FROM #tmpPressureUlcerWound

	WHERE CollectedDt IS NOT NULL

	ORDER BY CollectedDt DESC

	-- GET THE LATEST ASSESSMENT DATE AMONG MULTIPLE COLLECTED DATES
	SELECT @dtCollectedDt = CollectedDt FROM #tmpTopCollectedDt WHERE Rank1 = 1 AND @iRecordsCount > 0
  
	INSERT INTO #Final
	
	SELECT RecordsCount = @iRecordsCount
	, PatientName = @PatientName
	, MRN = @MRNumber
	, Location = @Location
	, Room_Bed = @RoomBed
	, CollectedDateTime = --MAX(CollectedDT),  
          MAX(CASE Columnnumber   
            WHEN 1 THEN CollectedDT   
            WHEN 2 THEN CollectedDT  
            WHEN 3 THEN CollectedDT  
            WHEN 4 THEN CollectedDT  
            WHEN 5 THEN CollectedDT  
          ELSE NULL END
		)
	, DishcargeDateTime = @VisitEndDateTime
	, DischargeDisposition = @DischargeDisposition
	, PatientAccountID = @PatientAcctNum
	, PageNumber
	, RowNumber
	, CollectedDt = @dtCollectedDt
	, CollectedDt1 = MAX(CASE Columnnumber WHEN 1 THEN CollectedDT ELSE NULL END)
	, CollectedDt2 = MAX(CASE Columnnumber WHEN 2 THEN CollectedDT ELSE NULL END)
	, CollectedDt3 = MAX(CASE Columnnumber WHEN 3 THEN CollectedDT ELSE NULL END)
	, CollectedDt4 = MAX(CASE Columnnumber WHEN 4 THEN CollectedDT ELSE NULL END)
	, CollectedDt5 = MAX(CASE Columnnumber WHEN 5 THEN CollectedDT ELSE NULL END)
	, DisplayName1 = MAX(CASE Columnnumber WHEN 1 THEN DisplayName ELSE '' END)
	, DisplayName2 = MAX(CASE Columnnumber WHEN 2 THEN DisplayName ELSE '' END)
	, DisplayName3 = MAX(CASE Columnnumber WHEN 3 THEN DisplayName ELSE '' END)
	, DisplayName4 = MAX(CASE Columnnumber WHEN 4 THEN DisplayName ELSE '' END)
	, DisplayName5 = MAX(CASE Columnnumber WHEN 5 THEN DisplayName ELSE '' END)
	, FindingAbbr1 = MAX(CASE Columnnumber WHEN 1 THEN FindingAbbr ELSE '' END)
	, FindingAbbr2 = MAX(CASE Columnnumber WHEN 2 THEN FindingAbbr ELSE '' END)
	, FindingAbbr3 = MAX(CASE Columnnumber WHEN 3 THEN FindingAbbr ELSE '' END)
	, FindingAbbr4 = MAX(CASE Columnnumber WHEN 4 THEN FindingAbbr ELSE '' END)
	, FindingAbbr5 = MAX(CASE Columnnumber WHEN 5 THEN FindingAbbr ELSE '' END)
	, Value1 = MAX(CASE Columnnumber WHEN 1 THEN Value ELSE '' END )
	, Value2 = MAX(CASE Columnnumber WHEN 2 THEN Value ELSE '' END )
	, Value3 = MAX(CASE Columnnumber WHEN 3 THEN Value ELSE '' END )
	, Value4 = MAX(CASE Columnnumber WHEN 4 THEN Value ELSE '' END )
	, Value5 = MAX(CASE Columnnumber WHEN 5 THEN Value ELSE '' END )

	FROM #tmpPressureUlcerWound

	GROUP BY PageNumber
	, RowNumber

	ORDER BY PageNumber
	, RowNumber
  
	Delete from #tmpPressureUlcerWound  
	Drop table #tmpObservationDetails  
	DROP TABLE #tmpTopCollectedDt
	SELECT @dtCollectedDt = NULL
	--DROP TABLE #tmpAssessmentDetails  
  
	Set @count = @count-1  

END  
/*  
Create table #temp_mrn (mrn int,ident int identity(1,1))  
insert into #temp_mrn  
select distinct mrn from #Final  
  
Declare @mrn int  
Set @MRN = (select COUNT(*) from #temp_mrn)  
  
Declare @CollectedDt datetime  
  
  
Update t1   
Set t1.CollectedDateTime = ''   
FROM #Final t1  
where t1.CollectedDateTime IS NULL   
  
While(@mrn = 0)  
BEGIN   
print @mrn  
Set @CollectedDt =  (Select top 1 t1.CollectedDateTime  
     FROM #Final t1   
     where t1.MRN = (select mrn from #temp_mrn where ident = @mrn)  
     Order by t1.CollectedDateTime desc)  

Update t1   
Set t1.CollectedDateTime = @CollectedDt      
FROM #Final t1   
where t1.MRN = (Select top 1 mrn from #temp_mrn where ident = @mrn)  
  
--Select top 1 mrn into #temp1 from #temp_mrn where ident = @mrn  
  
Set @mrn = @mrn-1  
END  
  
--Select * from #temp1  
  
Select * from #Final t1   
where t1.MRN = 865425   
  */
SELECT *
, RecCnt = @iRecordsCount 

FROM #Final 

WHERE RecordsCount > 0
AND Value4 = 'Pressure injury'

--Where (Value1 <>''  
-- AND Value2 <>''  
-- AND Value3 <>''   
-- AND Value4 <>''  
-- AND Value5 <>''  
-- )  
  