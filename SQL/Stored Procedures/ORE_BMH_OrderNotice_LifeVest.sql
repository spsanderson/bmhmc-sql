ALTER PROC [dbo].[ORE_BMH_OrderNotice_LifeVest]      
(  
@PatientId int = NULL,      
@PatientVisitId int = NULL      
)      
AS      
      
  SELECT ho.Patient_oid,   
  ho.PatientVisit_oid,  
  ho.ObjectID ,  
  ho.SessionID,  
  ho.CreationTime,  
  Rank1 = DENSE_RANK() OVER (
	PARTITION BY ho.Patient_OID
	, ho.PatientVisit_OID 
	ORDER BY ho.CreationTime DESC
	, ho.SessionID
)  
    
INTO #tmpHOrderDetails    
    
FROM HOrder ho WITH(NOLOCK)  
Inner join HServiceDetail HSD with(nolock)      
ON HSD.ObjectID = ho .ServiceDetail_oid      
Inner Join Hservice HS with(nolock)      
ON HS.ObjectID = HSD.Service_oid              
	AND HS.Abbreviation IN ('07099989','07099971')  

WHERE ho.Patient_oid = @PatientId   
AND ho.PatientVisit_oid = @PatientVisitId  
  
/*  
Select HOrder.OrderName,t.* from #tmpHOrderDetails t  
Inner join HOrder with(nolock)  
on HOrder.ObjectID = t.ObjectID  
and HOrder.SessionId = t.sessionID  
*/  
        
DELETE FROM #tmpHOrderDetails WHERE Rank1 > 1  
  
      
SELECT  Distinct    
  PatientName = CASE ISNULL(pt.GenerationQualifier, '')      
				WHEN ''      
					THEN pt.LastName + ', ' + pt.FirstName + ' '      
					+ ISNULL(SUBSTRING(pt.MiddleName, 1, 1), ' ')      
					ELSE pt.LastName + ' ' + pt.GenerationQualifier + ', '      
					+ pt.FirstName + ' ' + ISNULL(SUBSTRING(pt.MiddleName, 1, 1),' ')
				END      
  , StartDateTime = HOrder.StartDateTime      
  , EnteredBy = ISNULL(HOrder.EnteredBy, '')      
  , EnteredDateTime = HOrder.EnteredDateTime      
  , VisitStartDateTime = HPatientVisit.VisitStartDateTime      
  , VisitEndDateTime = HPatientVisit.VisitEndDateTime      
  , Bed = HPatientVisit.LatestBedName      
  , Allergies = ISNULL(dbo.Fn_ORE_GetPatientAllergies(pt.ObjectID),      
	ISNULL(.dbo.fn_ORE_VisitAllergiesCheck(pt.ObjectID, HPatientVisit.ObjectID), '')
	)      
  , MRNumber = ISNULL(.dbo.fn_ORE_GetExternalPatientID(pt.ObjectID,      
		ISNULL(HPatientVisit.entity_oid, 2)),
		'')      
  , BirthDate = CONVERT(VARCHAR(10), per.BirthDate, 101)     
  , Sex = CAST(CASE per.Sex      
				WHEN 0 THEN 'M'      
				WHEN 1 THEN 'F'      
				ELSE ' '      
			END AS CHAR(6))      
  , Age = ( .dbo.fn_ORE_GetPatientAge(per.BirthDate, GETDATE()) )                                               
  , NurseStation = HPatientVisit.PatientLocationName      
  , PatientAccountID = HPatientVisit.PatientAccountID      
  , AttendingPhysician = ISNULL(HOrderSuppInfo.AttendingPhysician, '')      
  , AdmittingPhysician = ISNULL(HOrderSuppInfo.AdmittingPhysician, '')      
  , OrderingPhysician = HName.LastName + CASE WHEN HName.FirstName = '' THEN ''   -- RequestedBy      
            WHEN HName.LastName = '' THEN ''      
            ELSE ', '      
             END + HName.FirstName + CASE WHEN HName.MiddleName = '' THEN ''      
     ELSE ' ' + SUBSTRING(HName.MiddleName, 1, 1)      
                   END
  , RequestedBy = ISNULL(HOrder.RequestedBy, '')				         
  , OrderName = ISNULL(HOrder.OrderName, '')     
  , CreationTime = HOrder.CreationTime    
  , EnteralFeedType = ISNULL(HOrderSuppInfoExt.EnteralFeedType, '')      
  , DietaryAmount = ISNULL(HOrderSuppInfoExt.DietaryAmount, '')      
  , DietaryRoute = ISNULL(HOrderSuppInfoExt.DietaryRoute, '')      
  , EnteralFeedGoalRate = ISNULL(HOrderSuppInfoExt.EnteralFeedGoalRate, '')      
  , Instruction = ISNULL(HOrderSuppInfo.Instruction, '')      
  , ReasonForRevision = ISNULL(HOrderSuppInfo.ReasonForRevision, '')      
  , ReasonForRequest = ISNULL(HOrderSuppInfo.ReasonForRequest, '')  
  , ConditionalInformation = ISNULL(HOrderSuppInfoExt.ConditionalInformation, '')      
  , UserDefinedString48 = ISNULL(HExtendedOrder.UserDefinedString48, '')      
  , UserDefinedNumeric11 = ISNULL(HExtendedOrder.UserDefinedNumeric11, '')      
  , UserDefinedNumeric12 = ISNULL(HExtendedOrder.UserDefinedNumeric12, '') 
  , UserDefinedNumeric13 = ISNULL(HExtendedOrder.UserDefinedNumeric13, '')     
  , UserDefinedDateTime2 = HExtendedOrder.UserDefinedDateTime2      
  , UserDefinedString37 = ISNULL(HExtendedOrder.UserDefinedString37, '')      
  , Priority = ISNULL(HOrder.Priority, '')      
    
    FROM    HOrder HOrder WITH ( NOLOCK )     
    INNER JOIN #tmpHOrderDetails t1   
    ON t1.Patient_OID = HOrder.Patient_oid   
		AND t1.PatientVisit_OID= HOrder.PatientVisit_oid     
		AND HOrder.ObjectID  = t1.ObjectID     
	INNER JOIN HPatientVisit HPatientVisit ( NOLOCK )      
    ON HOrder.PatientVisit_oid = HPatientVisit.ObjectId      
        AND HOrder.Patient_oid = HPatientVisit.Patient_oid      
		AND HPatientVisit.patient_oid = @PatientId    
		AND HPatientVisit.ObjectID = @PatientVisitId    
	INNER JOIN HPatient pt WITH ( NOLOCK )      
    ON pt.ObjectID = HPatientVisit.Patient_OID      
	INNER JOIN HPerson per WITH ( NOLOCK )      
    ON pt.ObjectID = per.ObjectID        
	Inner join HServiceDetail HSD with(nolock)    
	ON HSD.ObjectID = HOrder.ServiceDetail_oid    
	Inner Join Hservice HS with(nolock)    
	ON HS.ObjectID = HSD.Service_oid            
		AND HS.Abbreviation IN ('07099989','07099971')    
		--AND HS.ServiceName like ('%Enteral Feeding%')                     
	LEFT OUTER JOIN HOrderSuppInfo HOrderSuppInfo WITH ( NOLOCK )      
    ON HOrder.OrderSuppInfo_oid = HOrderSuppInfo.ObjectID      
	LEFT OUTER JOIN HOrderSuppInfoExt HOrderSuppInfoExt WITH ( NOLOCK )      
    ON HOrder.OrderSuppInfoExt_oid = HOrderSuppInfoExt.ObjectID      
	LEFT OUTER JOIN HExtendedOrder HExtendedOrder WITH ( NOLOCK )      
    ON HOrder.ExtendedOrder_oid = HExtendedOrder.ObjectID      
	LEFT OUTER JOIN HRecurrenceInstance HRecurrenceInstance WITH ( NOLOCK )      
    ON HOrder.RecurrencePattern_oid = HRecurrenceInstance.ObjectID      
		AND HRecurrenceInstance.IsDeleted = 0      
	LEFT OUTER JOIN HOccurrenceOrder HOccurrenceOrder WITH ( NOLOCK )      
    ON HOrder.ObjectID = HOccurrenceOrder.Order_oid      
	LEFT OUTER JOIN HSUser HSUser WITH ( NOLOCK )      
    ON HOrder.RequestedBy = HSUser.UserName      
		AND HOrder.Requestedby_oid = HSUser.ObjectID      
	LEFT OUTER JOIN HName HName WITH ( NOLOCK )      
    ON HSUser.Person_oid = HName.Person_oid      
		AND (
			HName.EndDateOfValidity IS NULL      
            OR HName.EndDateOfValidity = '1899-12-30 00:00:00'
		)      

	Order by CreationTime DESC, PatientName      
