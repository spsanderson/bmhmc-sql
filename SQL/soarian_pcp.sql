/*****************************************************************************
File: soarian_pcp.sql      

Input  Parameters:  
    @Patient_oid

Tables: 
    HAssessment
	HAssessmentCategory 
	HObservation
    HOrder
	HPatient  
	HPatientVisit
	HPatientIdentifiers

Functions: 
	fn_ORE_GetPhysicianName

Author: Steve P Sanderson II, MPH

Department: Finance, Revenue Cycle
      
Revision History: 
Date		Version		Description
----		----		----
2020-03-02	v1			Initial Creation - ADDED PCP
-------------------------------------------------------------------------------- 
*/

-- Get PCP
DECLARE @PCP_TBL TABLE (
	Patient_OID INTEGER,
	PCP_First VARCHAR(100),
	PCP_Middle VARCHAR(100),
	PCP_Last VARCHAR(100),
	PCP_Title VARCHAR(100)
	)

INSERT INTO @PCP_TBL
SELECT T1.Patient_oid,
	--t1.ObjectID ,
	--t1.InstanceHFCID,
	--t1.RecordID,
	--t1.RelationType,
	t2.FirstName,
	t2.MiddleName,
	t2.LastName,
	t2.Title
FROM HStaffAssociations t1 -- this table holds the current active associations a staff has with a patient. The Relationtype for the PCP = 1. 
INNER JOIN HStaff t3 ON t3.ObjectID = t1.Staff_oid -- HStaffAssociations holds the Staff_oid and needs to be join with the HStaff table. 
INNER JOIN HName t2 ON t3.ObjectID = t2.Person_oid -- The Staff_oid actually equals the Person_oid and is joined with the HName table to get the PCP's current name.
	AND (
		EndDateOfValidity IS NULL
		OR EndDateOfValidity = '1899-12-30 00:00:00'
		) -- If the Staff's name has changed, then they may have multiple entries in this table so we are looking for the 
	-- current name
	AND t1.EndDate IS NULL
WHERE (
		t1.Patient_oid = @HSF_CONTEXT_PATIENTID
		AND t1.RelationType = '1'
		)