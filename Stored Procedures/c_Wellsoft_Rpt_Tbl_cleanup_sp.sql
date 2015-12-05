SET ANSI_NULLS ON
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

    DROP TABLE smsdss.c_Wellsoft_Rpt_tbl;

	SELECT ROW_NUMBER() OVER(ORDER BY ARRIVAL) ID
	, Patient
	, CAST(dbo.c_udf_AlphaNumericChars(Account) AS INT)                 AS [Account]
	, CAST(dbo.c_udf_AlphaNumericChars(MR#) AS INT)                        AS [MR#]
	, Diagnosis
	, ICD9
	, TransferEMTALAFormsCmpltd
	, Disposition
	, AdmittingDxTranscribed
	, AxisIPrimaryDx
	, CAST(dbo.c_udf_AlphaNumericChars(AgeDOB) AS VARCHAR)                 AS [AgeDOB]
	, sex
	, age
	, CAST(dbo.c_udf_AlphaNumericChars(EDRecordSentToEDM) AS VARCHAR)      AS [EDRecordSentToEDM]
	, CAST(dbo.c_udf_AlphaNumericChars(TimeRNSignature) AS VARCHAR)        AS [TimeRNSignature]
	, CAST(dbo.c_udf_AlphaNumericChars(timemdsignature) AS VARCHAR)        AS [timemdsignature]
	, RNSgntr
	, CAST(dbo.c_udf_AlphaNumericChars(Triage_End) AS VARCHAR)             AS [Triage_End]
	, Triage_Start
	, CAST(dbo.c_udf_AlphaNumericChars(AddedToAdmissionsTrack) AS VARCHAR) AS [AddedToADMissionsTrack]
	, CAST(dbo.c_udf_AlphaNumericChars(Admit_Cnrfm_String) AS VARCHAR)     AS [Admit_Confirm]
	, AdmittingMD
	, AreaOfCare
	, ED_MD
	, EDMDID
	, Specialty
	, AccessProceduresED
	, MDSgntr
	, CAST(dbo.c_udf_AlphaNumericChars(Arrival) AS VARCHAR)                AS [Arrival]
	, ChiefComplaint
	, ReferMD
	
	INTO smsdss.c_Wellsoft_Rpt_tbl

	FROM smsdss.c_Wellsoft_Rpt_tbl_tmp

	WHERE LEN(Arrival) < 13
	AND LEN(Account) = 8

END
GO