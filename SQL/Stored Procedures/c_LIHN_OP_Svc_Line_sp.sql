USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_LIHN_OP_Svc_Line_sp.sql

Input Parameters:
	None

Tables/Views:
	Start Here

Creates Table:
	smsdss.c_LIHN_OP_Svc_Line_Tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Create a table for outpatient LIHN service line assignments

Revision History:
Date		Version		Description
----		----		----
2018-11-13	v1			Initial Creation
2018-11-16	v2			Add General Outpatient line
***********************************************************************
*/

ALTER PROCEDURE [smsdss].[c_LIHN_OP_Svc_Line_sp]
AS
--CREATE PROCEDURE [smsdss].[c_LIHN_OP_Svc_Line_sp]
--AS

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

IF NOT EXISTS (
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name = 'c_LIHN_OP_Svc_Line_Tbl' AND xtype = 'U'
)

BEGIN
	
	CREATE TABLE smsdss.c_LIHN_OP_Svc_Line_Tbl (
		Encounter VARCHAR(12) NOT NULL
		, prin_proc_cd_schme VARCHAR(10)
		, LIHN_Svc_Line VARCHAR(200)
	)

	/*
		Bariatric Surgery for Obesity Outpatient
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'Bariatric Surgery for Obesity Outpatient' AS [SVC_LINE]

	INTO #BSOO

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'4468','4495','43770','43770'
	)
	AND VST.vst_type_cd != 'I'

	/*
		Cardiac Catheterization
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'Cardiac Catheterization' AS [SVC_LINE]

	INTO #CC

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'3721','3722','3723',
		'36013','93451','93452','93456','93457',
		'93458','93549','93460','93461','93462',
		'93560','93531','93532','93533'
	)
	AND VST.vst_type_cd != 'I'

	/*
		Cataract Removal
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'Cataract Removal' AS [SVC_LINE]

	INTO #CR

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'1311','1319','132','133','1341',
		'1342','1343','1351','1359','1364',
		'1365','1366',
		'66820','66821','66830','66840','66850',
		'66852','66920','66930','66940','66982',
		'66983','66984'
	)
	AND VST.vst_type_cd != 'I'

	/*
		Colonoscopy/Endoscopy
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'Colonoscopy/Endoscopy' AS [SVC_LINE]

	INTO #CE

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'4513','4514','4516','4523','4524',
		'4525','4542','4543',
		'43235','43236','43237','43238','43239',
		'43240','43241','43242','43257','43259',
		'44100','44360','44361','44370','44377',
		'44378','44379','44385','44386','45317',
		'45320','45330','45331','45332','45333',
		'45334','45335','45338','45339','45341',
		'45342','45345','45378','45379','45380',
		'45381','45382','45383','45384','45385',
		'45391','45392','G0104','G0105','G0121',
		'S0601'
	)
	AND VST.vst_type_cd != 'I'

	/*
		Laparoscopic Cholecystectomy
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'Laparoscopic Cholecystectomy' AS [SVC_LINE]

	INTO #LC

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'5123','5124',
		'47562','47563','47564'
	)
	AND VST.vst_type_cd != 'I'

	/*
		PTCA Outpatient
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'PTCA Outpatient' AS [SVC_LINE]

	INTO #PTCAOP

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'0066',
		'92920','92924','92928','92933','92937',
		'92941','92943','C9600','C9602','C9604',
		'C9606','C9607'
	)
	AND VST.vst_type_cd != 'I'

	/*
		General Outpatient
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'General Outpatient' AS [SVC_LINE]

	INTO #GOP

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.pt_id NOT IN (
		SELECT A.pt_id
		FROM #BSOO AS A
	)
	AND SPROC.pt_id NOT IN (
		SELECT B.PT_ID
		FROM #CC AS B
	)
	AND SPROC.pt_id NOT IN (
		SELECT C.PT_ID
		FROM #CE AS C
	)
	AND SPROC.pt_id NOT IN (
		SELECT D.PT_ID
		FROM #CR AS D
	)
	AND SPROC.pt_id NOT IN (
		SELECT E.PT_ID
		FROM #LC AS E
	)
	AND SPROC.pt_id NOT IN (
		SELECT F.PT_ID
		FROM #PTCAOP AS F
	)
	AND VST.vst_type_cd != 'I'

	/*
		Union all tables and take distinct records, account
		cannot have more than one line assignment
	*/

	SELECT DISTINCT(OPLINE.pt_id) AS PT_ID
	, OPLINE.proc_cd_schm AS PROC_CD_SCHM
	, OPLINE.SVC_LINE AS SVC_LINE
	, [RN] = ROW_NUMBER() OVER(PARTITION BY OPLINE.PT_ID ORDER BY OPLINE.PT_ID)
	
	INTO #TEMP_REC_A
	
	FROM (
		SELECT *
		FROM #BSOO AS A

		UNION

		SELECT *
		FROM #CC

		UNION

		SELECT *
		FROM #CE

		UNION

		SELECT *
		FROM #CR

		UNION

		SELECT *
		FROM #LC

		UNION

		SELECT *
		FROM #PTCAOP

		UNION

		SELECT *
		FROM #GOP
	) AS OPLINE
	;

	INSERT INTO smsdss.c_LIHN_OP_Svc_Line_Tbl
	
	SELECT A.PT_ID
	, A.PROC_CD_SCHM
	, A.SVC_LINE
	
	FROM #TEMP_REC_A AS A
	
	WHERE A.RN = 1
	;
	DROP TABLE #BSOO, #CC, #CE, #CR, #LC, #PTCAOP, #TEMP_REC_A
	;

END

ELSE BEGIN

	/*
		Bariatric Surgery for Obesity Outpatient
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'Bariatric Surgery for Obesity Outpatient' AS [SVC_LINE]

	INTO #BSOO2

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'4468','4495','43770','43770'
	)
	AND VST.vst_type_cd != 'I'

	/*
		Cardiac Catheterization
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'Cardiac Catheterization' AS [SVC_LINE]

	INTO #CC2

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'3721','3722','3723',
		'36013','93451','93452','93456','93457',
		'93458','93549','93460','93461','93462',
		'93560','93531','93532','93533'
	)
	AND VST.vst_type_cd != 'I'

	/*
		Cataract Removal
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'Cataract Removal' AS [SVC_LINE]

	INTO #CR2

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'1311','1319','132','133','1341',
		'1342','1343','1351','1359','1364',
		'1365','1366',
		'66820','66821','66830','66840','66850',
		'66852','66920','66930','66940','66982',
		'66983','66984'
	)
	AND VST.vst_type_cd != 'I'

	/*
		Colonoscopy/Endoscopy
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'Colonoscopy/Endoscopy' AS [SVC_LINE]

	INTO #CE2

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'4513','4514','4516','4523','4524',
		'4525','4542','4543',
		'43235','43236','43237','43238','43239',
		'43240','43241','43242','43257','43259',
		'44100','44360','44361','44370','44377',
		'44378','44379','44385','44386','45317',
		'45320','45330','45331','45332','45333',
		'45334','45335','45338','45339','45341',
		'45342','45345','45378','45379','45380',
		'45381','45382','45383','45384','45385',
		'45391','45392','G0104','G0105','G0121',
		'S0601'
	)
	AND VST.vst_type_cd != 'I'

	/*
		Laparoscopic Cholecystectomy
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'Laparoscopic Cholecystectomy' AS [SVC_LINE]

	INTO #LC2

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'5123','5124',
		'47562','47563','47564'
	)
	AND VST.vst_type_cd != 'I'

	/*
		PTCA Outpatient
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'PTCA Outpatient' AS [SVC_LINE]

	INTO #PTCAOP2

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.proc_cd IN (
		'0066',
		'92920','92924','92928','92933','92937',
		'92941','92943','C9600','C9602','C9604',
		'C9606','C9607'
	)
	AND VST.vst_type_cd != 'I'

	
	/*
		General Outpatient
	*/
	SELECT DISTINCT(SPROC.pt_id)
	, SPROC.proc_cd_schm
	, 'General Outpatient' AS [SVC_LINE]

	INTO #GOP2

	FROM smsmir.sproc AS SPROC
	LEFT OUTER JOIN smsmir.vst AS VST
	ON SPROC.PT_ID = VST.PT_ID
		AND SPROC.UNIT_SEQ_NO = VST.unit_seq_no
		AND SPROC.from_file_ind = VST.from_file_ind

	WHERE SPROC.pt_id NOT IN (
		SELECT A.pt_id
		FROM #BSOO2 AS A
	)
	AND SPROC.pt_id NOT IN (
		SELECT B.PT_ID
		FROM #CC2 AS B
	)
	AND SPROC.pt_id NOT IN (
		SELECT C.PT_ID
		FROM #CE2 AS C
	)
	AND SPROC.pt_id NOT IN (
		SELECT D.PT_ID
		FROM #CR2 AS D
	)
	AND SPROC.pt_id NOT IN (
		SELECT E.PT_ID
		FROM #LC2 AS E
	)
	AND SPROC.pt_id NOT IN (
		SELECT F.PT_ID
		FROM #PTCAOP2 AS F
	)
	AND VST.vst_type_cd != 'I'

	/*
		Union all tables and take distinct records, account
		cannot have more than one line assignment
	*/

	SELECT DISTINCT(OPLINE.pt_id) AS PT_ID
	, OPLINE.proc_cd_schm AS PROC_CD_SCHM
	, OPLINE.SVC_LINE AS SVC_LINE
	, [RN] = ROW_NUMBER() OVER(PARTITION BY OPLINE.PT_ID ORDER BY OPLINE.PT_ID)

	INTO #TEMP_REC_B

	FROM (
		SELECT *
		FROM #BSOO2 AS A

		UNION

		SELECT *
		FROM #CC2

		UNION

		SELECT *
		FROM #CE2

		UNION

		SELECT *
		FROM #CR2

		UNION

		SELECT *
		FROM #LC2

		UNION

		SELECT *
		FROM #PTCAOP2

		UNION
		
		SELECT *
		FROM #GOP2
	) AS OPLINE
	WHERE OPLINE.pt_id NOT IN (
		SELECT DISTINCT(pt_id)
		FROM smsdss.c_LIHN_OP_Svc_Line_Tbl
	)
	;

	INSERT INTO smsdss.c_LIHN_OP_Svc_Line_Tbl

	SELECT B.PT_ID
	, B.PROC_CD_SCHM
	, B.SVC_LINE

	FROM #TEMP_REC_B AS B

	WHERE B.RN = 1
	;

	DROP TABLE #BSOO2, #CC2, #CE2, #CR2, #LC2, #PTCAOP2, #TEMP_REC_B
	;

END