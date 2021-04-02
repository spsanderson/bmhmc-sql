USE [Soarian_Clin_Tst_1]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
***********************************************************************
File: ORE_0040_SPS_TEST.sql

Input Parameters:
	@pvcStartDate
    @pvcEndDate

Tables/Views:   
    HInvestigationResult  
    HPatient   
    HPatientVisit    
    HPerson

Creates Table:
	None

Functions:
    None 

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get HEP C data when test is abnormal

Revision History:
Date		Version		Description
----		----		----
2021-03-31	v1			Initial Creation
***********************************************************************
*/

-- Create a new stored procedure called 'ORE_0040_HEP_C' in schema 'dbo'
-- Create the stored procedure in the specified schema
CREATE PROCEDURE dbo.ORE_0040_HEP_C @pvcStartDate DATE,
	@pvcEndDate DATE
AS
-- body of the stored procedure
SELECT HIR.Patient_oid,
	HIR.PatientVisit_oid,
	PV.PatientAccountID,
	HIR.CreationTime,
	HIR.ObservationDateTime,
	HIR.ResultValue,
	HIR.AbnormalFlag,
	PV.LatestBedName,
	PV.PatientLocationName,
	[BirthDate] = convert(VARCHAR(10), per.BirthDate, 101)
FROM HInvestigationResult AS HIR
LEFT JOIN HPatientVisit AS PV ON HIR.Patient_oid = PV.Patient_oid
	AND HIR.PatientVisit_oid = PV.StartingVisitOID
LEFT JOIN HPatient AS PT ON PV.Patient_oid = PT.ObjectID
LEFT JOIN HPerson AS PER ON PT.ObjectID = PER.ObjectID
WHERE HIR.AbnormalFlag = 'A'
	AND HIR.FindingAbbreviation = '00402065'
	AND HIR.CreationTime >= @pvcStartDate
	AND HIR.CreationTime < @pvcEndDate
	AND PV.IsDeleted = 0
GO

-- example to execute the stored procedure we just created
--EXECUTE dbo.ORE_0040_HEP_C 1 /*value_for_param1*/, 2 /*value_for_param2*/
--GO
