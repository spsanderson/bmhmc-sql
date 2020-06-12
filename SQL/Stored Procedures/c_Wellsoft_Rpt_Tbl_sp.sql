USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_Wellsoft_Rpt_Tbl_sp]    Script Date: 5/24/2018 9:56:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* =============================================
Author:		Steven P Sanderson II, MPH
Department: Finance, Revenue Cycle
Create date: 11-19-2015
Description:	Create a reportable wellsoft table bound to smsdss schema
v1	-	2015-11-09	- Initial creation
v2 	-	2018-05-24	- Add TobaccoUse Column to sp
v3	-	2019-02-01	- Fix AdmittingDxTranscribed column due to Application Upgrade
v4	-	2020-04-16	- Add PublicityCodeID, PublicityCodeText and InjuryCode
						Publicity Code ID	Changed to "Did you get tested outside this hospital"
						Publicity Code Text	Changed to "What were the Covid-19 test Results"
						Injury Code	Changed to "Where were you tested for Covid-19"
v5		2020-06-04	- Add AccessRmAssigned column
v6	-	2020-06-05	- Remove schema bindings
=============================================
*/
ALTER PROCEDURE [smsdss].[c_Wellsoft_Rpt_Tbl_sp]
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
	, [AdmittingObvDx] AS [AdmittingDxTranscribed]
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
	, MLPResHistory
	, res_pa_np
	, TriageMLP
	, StatusMLPChart
	, TimeMLPSignature
	, TobaccoUse
	, PublicityCodeID
	, PublicityCodeText
	, InjuryCode
	, AccessRmAssigned
	
	INTO c_Wellsoft_Rpt_tbl_tmp
	
	FROM [BMH-EDIS-CL]..[WELLUSER].[Patient_Chart] a WITH(NOLOCK)
	LEFT OUTER JOIN [BMH-EDIS-CL]..[WELLUSER].[Patient_Diagnoses] b WITH(NOLOCK)
	ON a.Master_Rec_Id=b.Master_Rec_Id 
		AND a.Slave_Rec_Id=b.Slave_Rec_Id

	WHERE Account != '1234567890'

END
