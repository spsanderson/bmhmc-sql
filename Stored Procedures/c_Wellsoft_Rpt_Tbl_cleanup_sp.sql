SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Steven Sanderson
-- Create date: 12/4/2015
-- Description:	Clean up results from smsdss.c_Wellsoft_Rpt_Tbl_sp
-- and insert results into smsdss.c_Wellsoft_Rpt_tbl
-- =============================================
CREATE PROCEDURE smsdss.c_Wellsoft_Rpt_Tbl_cleanup_sp 
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF OBJECT_ID('smsdss.c_Wellsoft_Rpt_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_Wellsoft_Rpt_tbl;

	SELECT ROW_NUMBER() OVER(ORDER BY ARRIVAL) ID
	, Patient
	, CAST(dbo.c_udf_AlphaNumericChars(Account) AS INT)                    AS [Account] 
	, CAST(dbo.c_udf_AlphaNumericChars(MR#) AS INT)                        AS [MR#]
	, Diagnosis
	, ICD9
	, TransferEMTALAFormsCmpltd
	, Disposition
	, AdmittingDxTranscribed
	, AxisIPrimaryDx
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AgeDOB), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AgeDOB), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AgeDOB), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AgeDOB), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AgeDOB), 11, 2) + ':00',
	  120)                                                                 AS [AgeDOB]
	, sex
	, age
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(EDRecordSentToEDM), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(EDRecordSentToEDM), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(EDRecordSentToEDM), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(EDRecordSentToEDM), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(EDRecordSentToEDM), 11, 2) + ':00',
	  120)                                                                 AS [EDRecordSentToEDM]
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(TimeRNSignature), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(TimeRNSignature), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(TimeRNSignature), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(TimeRNSignature), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(TimeRNSignature), 11, 2) + ':00',
	  120)                                                                 AS [TimeRNSignature]
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(timemdsignature), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(timemdsignature), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(timemdsignature), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(timemdsignature), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(timemdsignature), 11, 2) + ':00',
	  120)                                                                 AS [TimeMDsignature]
	, RNSgntr
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Triage_End), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Triage_End), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Triage_End), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Triage_End), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Triage_End), 11, 2) + ':00',
	  120)                                                                 AS [Triage_End]
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Triage_Start), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Triage_Start), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Triage_Start), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Triage_Start), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Triage_Start), 11, 2) + ':00',
	  120)                                                                 AS [Triage_Start]
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AddedToADMissionsTrack), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AddedToADMissionsTrack), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AddedToADMissionsTrack), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AddedToADMissionsTrack), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AddedToADMissionsTrack), 11, 2) + ':00',
	  120)                                                                 AS [AddedToADMissionsTrack]
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Admit_Cnrfm_String), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Admit_Cnrfm_String), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Admit_Cnrfm_String), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Admit_Cnrfm_String), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Admit_Cnrfm_String), 11, 2) + ':00',
	  120)                                                                 AS [Admit_Confirm]
	, AdmittingMD
	, AreaOfCare
	, ED_MD
	, EDMDID
	, Specialty
	, AccessProceduresED
	, MDSgntr
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Arrival), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Arrival), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Arrival), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Arrival), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(Arrival), 11, 2) + ':00',
	  120)                                                                 AS [Arrival]
	, ChiefComplaint
	, ReferMD
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(StatusAdmit), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(StatusAdmit), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(StatusAdmit), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(StatusAdmit), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(StatusAdmit), 11, 2) + ':00',
	  120)                                                                 AS [Decision To Admit]
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AdmitOrdersDT), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AdmitOrdersDT), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AdmitOrdersDT), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AdmitOrdersDT), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(AdmitOrdersDT), 11, 2) + ':00',
	  120)                                                                 AS [AdmitOrdersDT]
	, CONVERT(VARCHAR,
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(TimeLeftED), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(TimeLeftED), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(TimeLeftED), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(TimeLeftED), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(TimeLeftED), 11, 2) + ':00',
	  120)                                                                 AS [TimeLeftED]
	  
	INTO smsdss.c_Wellsoft_Rpt_tbl

	FROM smsdss.c_Wellsoft_Rpt_tbl_tmp

	WHERE LEN(Arrival) = 12
	AND LEN(Account) = 8

END
GO