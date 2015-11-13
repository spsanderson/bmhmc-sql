CREATE TABLE smsdss.c_Wellsoft_Rpt_tbl
(
[PK] INT IDENTITY(1, 1) PRIMARY KEY
, [Account]             VARCHAR(38)
, [MRN#]                VARCHAR(38)
, [Patient]             VARCHAR(56)
, [ED_MD]               VARCHAR(56)
, [Triage_Start]        VARCHAR(25)
)

--

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================
-- Author:		Steven Sanderson
-- Create date: 11/10/2015
-- Description:	To create an indexed table for reporting Wellsoft Data
-- ====================================================================

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DROP TABLE smsdss.c_Wellsoft_Rpt_tbl;

    -- Insert statements for procedure here
	--CREATE TABLE smsdss.c_Wellsoft_Rpt_tbl
	--(
	--	[PK] INT IDENTITY(1, 1) PRIMARY KEY
	--	, [Account]             VARCHAR(38)
	--	, [MRN#]                VARCHAR(38)
	--	, [Patient]             VARCHAR(56)
	--	, [ED_MD]               VARCHAR(56)
	--	, [Triage_Start]        VARCHAR(25)
	--)

	SELECT Patient
	,Account
	,MR#
	,Diagnosis
	,ICD9
	,TransferEMTALAFormsCmpltd
	,Disposition
	,AdmittingDxTranscribed
	,AxisIPrimaryDx
	,AgeDOB
	,sex
	,age
	,EDRecordSentToEDM
	,TimeRNSignature
	,timemdsignature
	,RNSgntr
	,TriageByNameEntered as [Triage_End]
	,TriageStartTime as [Triage_Start]
	,AddedToAdmissionsTrack
	,StatusAdmitConfirmed
	,SUBSTRING(statusadmitconfirmed,1,4)+'-'+SUBSTRING(statusadmitconfirmed,7,2)+'-'+SUBSTRING(statusadmitconfirmed,1,4)+' '+SUBSTRING(statusadmitconfirmed,9,2)+':'+SUBSTRING(statusadmitconfirmed,11,2)+':00.000' as 'Admit_Cnrfm_String'
	,AdmittingMD
	,AreaOfCare
	,EDMD AS [ED_MD]
	,EDMDID
	,Specialty
	,AccessProceduresED
	,MDSgntr
	,Arrival
	,ArrivalED
	,ChiefComplaint
	,TransferringFacility
	,ReferMD
	,PrivateName

	INTO smsdss.c_Wellsoft_Rpt_tbl
	
	FROM [BMH-EDIS-CL]..[WELLUSER].[Patient_Chart] a 
	LEFT OUTER JOIN [BMH-EDIS-CL]..[WELLUSER].[Patient_Diagnoses] b
	ON a.Master_Rec_Id=b.Master_Rec_Id 
		AND a.Slave_Rec_Id=b.Slave_Rec_Id

	WHERE [TriageStartTime] > '201200000000'
END