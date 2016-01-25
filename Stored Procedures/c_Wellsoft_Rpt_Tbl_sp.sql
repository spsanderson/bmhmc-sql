SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Steven Sanderson
-- Create date: 11-19-2015
-- Description:	Create a reportable wellsoft table bound to smsdss schema
-- =============================================
CREATE PROCEDURE smsdss.c_Wellsoft_Rpt_Tbl_sp
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('smsdss.c_Wellsoft_Rpt_tbl_tmp', 'U') IS NOT NULL
		DROP TABLE smsdss.c_Wellsoft_Rpt_tbl_tmp;

	SELECT Patient
	, Account
	, MR#
	, Diagnosis
	, ICD9
	, TransferEMTALAFormsCmpltd
	, Disposition
	, AdmittingDxTranscribed
	, AxisIPrimaryDx
	, AgeDOB
	, sex
	, age
	, EDRecordSentToEDM
	, TimeRNSignature
	, timemdsignature
	, RNSgntr
	, TriageByNameEntered  AS [Triage_End]
	, TriageStartTime      AS [Triage_Start]
	, AddedToAdmissionsTrack
	, StatusAdmitConfirmed AS [Admit_Cnrfm_String]
	, AdmittingMD
	, AreaOfCare
	, EDMD                 AS [ED_MD]
	, EDMDID
	, Specialty
	, AccessProceduresED
	, MDSgntr
	, Arrival
	, ArrivalED
	, ChiefComplaint
	, TransferringFacility
	, ReferMD
	, PrivateName
	, StatusAdmit 
	, AdmitOrdersDT
	, TimeLeftED
	
	INTO smsdss.c_Wellsoft_Rpt_tbl_tmp
	
	FROM [BMH-EDIS-CL]..[WELLUSER].[Patient_Chart] a 
	LEFT OUTER JOIN [BMH-EDIS-CL]..[WELLUSER].[Patient_Diagnoses] b
	ON a.Master_Rec_Id=b.Master_Rec_Id 
		AND a.Slave_Rec_Id=b.Slave_Rec_Id

	WHERE Account != '1234567890'

END
GO
