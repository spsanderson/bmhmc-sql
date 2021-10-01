USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_LIHN_Svc_Line_sp]    Script Date: 10/1/2021 8:36:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [smsdss].[c_LIHN_Svc_Line_sp]
AS

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

/*
Author: Steven P Sanderson II, MPH
Department: Finance, Revenue Cycle

Get the LIHN Service Line for an inpatient discharge

v1	- 2018-06-12	- Initial Creation
v2	- 2018-06-25	- Fix Dx_Cd no match, used REPLACE(C.dx_cd, '.', '') & REPLACE(D.proc_cd, '.', '')
					  Rename table to smsdss.c_LIHN_Svc_Line_Tbl
					  Initial Load of ICD9 done
v3	- 2018-10-17	- Added DRG_SCHM MC18
v4	- 2019-10-01	- Added DRG_SCHM MC19
v5	- 2020-10-01	- Added DRG_SCHM MC20
v6	- 2021-10-01	- Added DRG_SCHM MC21
*/

IF NOT EXISTS (
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name = 'c_LIHN_Svc_Line_Tbl' AND xtype = 'U'
)

BEGIN

	CREATE TABLE smsdss.c_LIHN_Svc_Line_Tbl (
		Encounter VARCHAR(12) NOT NULL
		, prin_dx_cd_schme CHAR(1)
		, LIHN_Svc_Line VARCHAR(300)
	);

	-- GET ICD9
	INSERT INTO smsdss.c_LIHN_Svc_Line_Tbl
	SELECT A.pt_id
	, VST.prin_dx_cd_schm
	, CASE 
	WHEN a.drg_no IN ('896', '897')
		AND DX_CC.CC_Code = 'DX_660'
		THEN 'Alcohol Abuse' -- good

	WHEN a.drg_no IN ('231', '232', '233', '234', '235', '236')
		THEN 'CABG' -- good

	WHEN a.drg_no IN ('34', '35', '36', '37', '38', '39')
		AND PX_CC.CC_Code IN ('PX_51', 'PX_59')
		THEN 'Carotid Endarterectomy' -- good

	WHEN a.drg_no IN ('602', '603')
		AND DX_CC.CC_Code IN ('DX_197')
		THEN 'Cellulitis' -- good

	WHEN --a.drg_no IN ('286', '287', '313')
		-- edited 3/22/2016 sps due to new LIHN guidelines
		a.drg_no IN ('313')
		AND DX_CC.CC_Code IN ('DX_102')
		THEN 'Chest Pain' -- good

	WHEN a.drg_no IN ('291', '292', '293')
		AND DX_CC.CC_Code IN ('DX_108', 'DX_99')
		THEN 'CHF' -- good

	WHEN a.drg_no IN ('190', '191', '192')
		AND DX_CC.CC_Code IN ('DX_127', 'DX_128')
		THEN 'COPD' -- good

	WHEN a.drg_no IN ('765', '766')
		THEN 'C-Section' -- good

	WHEN a.drg_no IN ('61', '62', '63', '64', '65', '66')
		THEN 'CVA' -- good

	WHEN a.drg_no IN ('619', '620', '621')
		AND PX_CC.CC_Code IN ('PX_74')
		THEN 'Bariatric Surgery For Obesity' -- update this

	WHEN a.drg_no IN ('377',' 378', '379')
		THEN 'GI Hemorrhage' -- good

	WHEN a.drg_no IN ('739', '740', '741', '742', '743')
		AND PX_CC.CC_Code IN ('PX_124')
		THEN 'Hysterectomy' -- good

	WHEN a.drg_no IN ('469', '470')
		AND PX_CC.CC_Code IN ('PX_152', 'PX_153')
		-- Exclusions
		AND DX_CC.CC_Code NOT IN ('DX_237', 'DX_238', 'DX_230', 'DX_229'
		, 'DX_226', 'DX_225', 'DX_231', 'DX_207')
		THEN 'Joint Replacement' -- good

	WHEN a.drg_no IN ('417', '418', '419')
		THEN 'Laparoscopic Cholecystectomy' -- good

	WHEN a.drg_no IN ('582', '583', '584', '585')
		AND PX_CC.CC_Code IN ('PX_167')
		THEN 'Mastectomy' -- good

	WHEN a.drg_no IN ('280', '281', '282', '283', '284', '285')
		THEN 'MI' -- good

	WHEN a.drg_no IN ('795')
		AND DX_CC.CC_Code IN ('DX_218')
		THEN 'Normal Newborn' -- good

	WHEN a.drg_no IN ('193', '194', '195')
		THEN 'Pneumonia' -- good

	WHEN a.drg_no IN ('881', '885')
		AND DX_CC.CC_Code IN ('DX_657')
		THEN 'Major Depression/Bipolar Affective Disorders' -- good

	WHEN a.drg_no IN ('885')
		AND DX_CC.CC_Code IN ('DX_659')
		THEN 'Schizophrenia' -- good

	WHEN a.drg_no IN ('246', '247', '248', '249', '250', '251')
		AND PX_CC.CC_Code IN ('PX_45')
		THEN 'PTCA' -- good

	WHEN a.drg_no IN ('945', '946')
		THEN 'Rehab' -- good

	WHEN a.drg_no IN ('312')
		THEN 'Syncope' -- good

	WHEN a.drg_no IN ('67', '68', '69')
		THEN 'TIA' -- good

	WHEN a.drg_no IN ('774', '775')
		THEN 'Vaginal Delivery' -- good

	WHEN a.drg_no IN ('216', '217', '218', '219', '220', '221', 
		'266', '267')
		THEN 'Valve Procedure' -- good
			
	WHEN a.drg_no BETWEEN '1' AND '8' 
		OR a.drg_no BETWEEN '10' AND '14' 
		OR a.drg_no IN ('16', '17') 
		OR a.drg_no BETWEEN '20' AND '42' 
		OR a.drg_no BETWEEN '113' AND '117' 
		OR a.drg_no BETWEEN '129' AND '139' 
		OR a.drg_no BETWEEN '163' AND '168' 
		OR a.drg_no BETWEEN '215' AND '265' 
		OR a.drg_no BETWEEN '326' AND '358' 
		OR a.drg_no BETWEEN '405' AND '425' 
		OR a.drg_no BETWEEN '453' AND '519' 
		OR a.drg_no = '520' 
		OR a.drg_no BETWEEN '570' AND '585' 
		OR a.drg_no BETWEEN '614' AND '630' 
		OR a.drg_no BETWEEN '652' AND '675' 
		OR a.drg_no BETWEEN '707' AND '718' 
		OR a.drg_no BETWEEN '734' AND '750' 
		OR a.drg_no BETWEEN '765' AND '780' 
		OR a.drg_no BETWEEN '782' AND '804' 
		OR a.drg_no BETWEEN '820' AND '830' 
		OR a.drg_no BETWEEN '853' AND '858' 
		OR a.drg_no = '876' 
		OR a.drg_no BETWEEN '901' AND '909' 
		OR a.drg_no BETWEEN '927' AND '929' 
		OR a.drg_no BETWEEN '939' AND '941' 
		OR a.drg_no BETWEEN '955' AND '959' 
		OR a.drg_no BETWEEN '969' AND '970' 
		OR a.drg_no BETWEEN '981' AND '989' 
		THEN 'Surgical' -- good 
	ELSE 'Medical' -- good
		
	END AS LIHN_Svc_Line

	FROM smsmir.mir_drg AS A
	LEFT OUTER JOIN smsmir.mir_drg_mstr AS B
	ON A.drg_no = B.drg_no
		AND LEFT(A.DRG_SCHM, 4) = LEFT(B.DRG_SCHM, 4)
	INNER JOIN smsmir.mir_dx_grp AS C
	ON A.pt_id = C.pt_id
		AND A.unit_seq_no = C.unit_seq_no
		AND A.from_file_ind = C.from_file_ind
		AND C.dx_cd_prio = '01'
		AND LEFT(C.dx_cd_type, 2) = 'DF'
		AND dx_cd_schm = '9'
	LEFT OUTER JOIN smsmir.mir_sproc AS D
	ON A.pt_id = D.pt_id
		AND A.unit_seq_no = D.unit_seq_no
		AND A.from_file_ind = D.from_file_ind
		AND D.proc_cd_prio = '01'
		AND D.proc_cd_type != 'C'
		AND D.proc_cd_schm = '9'
	LEFT OUTER JOIN smsdss.c_AHRQ_Dx_CC_Maps AS DX_CC
	ON REPLACE(C.dx_cd, '.', '') = DX_CC.ICDCode
		AND C.dx_cd_schm = RIGHT(DX_CC.ICD_Ver_Flag, 1)
	LEFT OUTER JOIN smsdss.c_AHRQ_Px_CC_Maps    AS PX_CC
	ON REPLACE(D.proc_cd, '.', '') = PX_CC.ICDCode
		AND D.proc_cd_schm = RIGHT(PX_CC.ICD_Ver_Flag, 1)
	INNER JOIN smsmir.vst AS VST
	ON A.PT_ID = VST.PT_ID
		AND VST.prin_dx_cd_schm = '9'

	WHERE a.drg_type = '1' 
	AND a.drg_schm IN (
		'MC11','MC12','MC13','MC14','MC15',
		'MCT4','MC16','MC17','MC18','MC19',
		'MC20','MC21'
	)
	
	INSERT INTO smsdss.c_LIHN_Svc_Line_Tbl
	-- GET ICD10
	SELECT A.pt_id
	, VST.prin_dx_cd_schm
	, CASE 
	WHEN a.drg_no IN ('896', '897')
		AND DX_CC.CC_Code = 'DX_660'
		THEN 'Alcohol Abuse' -- good

	WHEN a.drg_no IN ('231', '232', '233', '234', '235', '236')
		THEN 'CABG' -- good

	WHEN a.drg_no IN ('34', '35', '36', '37', '38', '39')
		AND PX_CC.CC_Code IN ('PX_51', 'PX_59')
		THEN 'Carotid Endarterectomy' -- good

	WHEN a.drg_no IN ('602', '603')
		AND DX_CC.CC_Code IN ('DX_197')
		THEN 'Cellulitis' -- good

	WHEN --a.drg_no IN ('286', '287', '313')
		-- edited 3/22/2016 sps due to new LIHN guidelines
		a.drg_no IN ('313')
		AND DX_CC.CC_Code IN ('DX_102')
		THEN 'Chest Pain' -- good

	WHEN a.drg_no IN ('291', '292', '293')
		AND DX_CC.CC_Code IN ('DX_108', 'DX_99')
		THEN 'CHF' -- good

	WHEN a.drg_no IN ('190', '191', '192')
		AND DX_CC.CC_Code IN ('DX_127', 'DX_128')
		THEN 'COPD' -- good

	WHEN a.drg_no IN ('765', '766')
		THEN 'C-Section' -- good

	WHEN a.drg_no IN ('61', '62', '63', '64', '65', '66')
		THEN 'CVA' -- good

	WHEN a.drg_no IN ('619', '620', '621')
		AND PX_CC.CC_Code IN ('PX_74')
		THEN 'Bariatric Surgery For Obesity' -- update this

	WHEN a.drg_no IN ('377',' 378', '379')
		THEN 'GI Hemorrhage' -- good

	WHEN a.drg_no IN ('739', '740', '741', '742', '743')
		AND PX_CC.CC_Code IN ('PX_124')
		THEN 'Hysterectomy' -- good

	WHEN a.drg_no IN ('469', '470')
		AND PX_CC.CC_Code IN ('PX_152', 'PX_153')
		-- Exclusions
		AND DX_CC.CC_Code NOT IN ('DX_237', 'DX_238', 'DX_230', 'DX_229'
		, 'DX_226', 'DX_225', 'DX_231', 'DX_207')
		THEN 'Joint Replacement' -- good

	WHEN a.drg_no IN ('417', '418', '419')
		THEN 'Laparoscopic Cholecystectomy' -- good

	WHEN a.drg_no IN ('582', '583', '584', '585')
		AND PX_CC.CC_Code IN ('PX_167')
		THEN 'Mastectomy' -- good

	WHEN a.drg_no IN ('280', '281', '282', '283', '284', '285')
		THEN 'MI' -- good

	WHEN a.drg_no IN ('795')
		AND DX_CC.CC_Code IN ('DX_218')
		THEN 'Normal Newborn' -- good

	WHEN a.drg_no IN ('193', '194', '195')
		THEN 'Pneumonia' -- good

	WHEN a.drg_no IN ('881', '885')
		AND DX_CC.CC_Code IN ('DX_657')
		THEN 'Major Depression/Bipolar Affective Disorders' -- good

	WHEN a.drg_no IN ('885')
		AND DX_CC.CC_Code IN ('DX_659')
		THEN 'Schizophrenia' -- good

	WHEN a.drg_no IN ('246', '247', '248', '249', '250', '251')
		AND PX_CC.CC_Code IN ('PX_45')
		THEN 'PTCA' -- good

	WHEN a.drg_no IN ('945', '946')
		THEN 'Rehab' -- good

	WHEN a.drg_no IN ('312')
		THEN 'Syncope' -- good

	WHEN a.drg_no IN ('67', '68', '69')
		THEN 'TIA' -- good

	WHEN a.drg_no IN ('774', '775')
		THEN 'Vaginal Delivery' -- good

	WHEN a.drg_no IN ('216', '217', '218', '219', '220', '221', 
		'266', '267')
		THEN 'Valve Procedure' -- good
		
	WHEN a.drg_no BETWEEN '1' AND '8' 
		OR a.drg_no BETWEEN '10' AND '14' 
		OR a.drg_no IN ('16', '17') 
		OR a.drg_no BETWEEN '20' AND '42' 
		OR a.drg_no BETWEEN '113' AND '117' 
		OR a.drg_no BETWEEN '129' AND '139' 
		OR a.drg_no BETWEEN '163' AND '168' 
		OR a.drg_no BETWEEN '215' AND '265' 
		OR a.drg_no BETWEEN '326' AND '358' 
		OR a.drg_no BETWEEN '405' AND '425' 
		OR a.drg_no BETWEEN '453' AND '519' 
		OR a.drg_no = '520' 
		OR a.drg_no BETWEEN '570' AND '585' 
		OR a.drg_no BETWEEN '614' AND '630' 
		OR a.drg_no BETWEEN '652' AND '675' 
		OR a.drg_no BETWEEN '707' AND '718' 
		OR a.drg_no BETWEEN '734' AND '750' 
		OR a.drg_no BETWEEN '765' AND '780' 
		OR a.drg_no BETWEEN '782' AND '804' 
		OR a.drg_no BETWEEN '820' AND '830' 
		OR a.drg_no BETWEEN '853' AND '858' 
		OR a.drg_no = '876' 
		OR a.drg_no BETWEEN '901' AND '909' 
		OR a.drg_no BETWEEN '927' AND '929' 
		OR a.drg_no BETWEEN '939' AND '941' 
		OR a.drg_no BETWEEN '955' AND '959' 
		OR a.drg_no BETWEEN '969' AND '970' 
		OR a.drg_no BETWEEN '981' AND '989' 
		THEN 'Surgical' -- good 
	ELSE 'Medical' -- good
	
	END AS LIHN_Svc_Line

	FROM smsmir.mir_drg AS A
	LEFT OUTER JOIN smsmir.mir_drg_mstr AS B
	ON A.drg_no = B.drg_no
		AND LEFT(A.DRG_SCHM, 4) = LEFT(B.DRG_SCHM, 4)
	INNER JOIN smsmir.mir_dx_grp AS C
	ON A.pt_id = C.pt_id
		AND A.unit_seq_no = C.unit_seq_no
		AND A.from_file_ind = C.from_file_ind
		AND C.dx_cd_prio = '01'
		AND LEFT(C.dx_cd_type, 2) = 'DF'
		AND dx_cd_schm = '0'
	LEFT OUTER JOIN smsmir.mir_sproc AS D
	ON A.pt_id = D.pt_id
		AND A.unit_seq_no = D.unit_seq_no
		AND A.from_file_ind = D.from_file_ind
		AND D.proc_cd_prio = '01'
		AND D.proc_cd_type != 'C'
		AND D.proc_cd_schm = '0'
	LEFT OUTER JOIN smsdss.c_AHRQ_Dx_CC_Maps AS DX_CC
	ON REPLACE(C.dx_cd, '.', '') = DX_CC.ICDCode
		AND C.dx_cd_schm = RIGHT(DX_CC.ICD_Ver_Flag, 1)
	LEFT OUTER JOIN smsdss.c_AHRQ_Px_CC_Maps    AS PX_CC
	ON REPLACE(D.proc_cd, '.', '') = PX_CC.ICDCode
		AND D.proc_cd_schm = RIGHT(PX_CC.ICD_Ver_Flag, 1)
	INNER JOIN smsmir.vst AS VST
	ON A.PT_ID = VST.PT_ID
		AND VST.prin_dx_cd_schm = '0'

	WHERE a.drg_type = '1' 
	AND a.drg_schm IN (
		'MC11','MC12','MC13','MC14','MC15',
		'MCT4','MC16','MC17','MC18','MC19',
		'MC20','MC21'
	)
	
END

ELSE BEGIN

	INSERT INTO smsdss.c_LIHN_Svc_Line_Tbl
	-- GET ICD10
	SELECT A.pt_id
	, VST.prin_dx_cd_schm
	, CASE 
	WHEN a.drg_no IN ('896', '897')
		AND DX_CC.CC_Code = 'DX_660'
		THEN 'Alcohol Abuse' -- good

	WHEN a.drg_no IN ('231', '232', '233', '234', '235', '236')
		THEN 'CABG' -- good

	WHEN a.drg_no IN ('34', '35', '36', '37', '38', '39')
		AND PX_CC.CC_Code IN ('PX_51', 'PX_59')
		THEN 'Carotid Endarterectomy' -- good

	WHEN a.drg_no IN ('602', '603')
		AND DX_CC.CC_Code IN ('DX_197')
		THEN 'Cellulitis' -- good

	WHEN --a.drg_no IN ('286', '287', '313')
		-- edited 3/22/2016 sps due to new LIHN guidelines
		a.drg_no IN ('313')
		AND DX_CC.CC_Code IN ('DX_102')
		THEN 'Chest Pain' -- good

	WHEN a.drg_no IN ('291', '292', '293')
		AND DX_CC.CC_Code IN ('DX_108', 'DX_99')
		THEN 'CHF' -- good

	WHEN a.drg_no IN ('190', '191', '192')
		AND DX_CC.CC_Code IN ('DX_127', 'DX_128')
		THEN 'COPD' -- good

	WHEN a.drg_no IN ('765', '766')
		THEN 'C-Section' -- good

	WHEN a.drg_no IN ('61', '62', '63', '64', '65', '66')
		THEN 'CVA' -- good

	WHEN a.drg_no IN ('619', '620', '621')
		AND PX_CC.CC_Code IN ('PX_74')
		THEN 'Bariatric Surgery For Obesity' -- update this

	WHEN a.drg_no IN ('377',' 378', '379')
		THEN 'GI Hemorrhage' -- good

	WHEN a.drg_no IN ('739', '740', '741', '742', '743')
		AND PX_CC.CC_Code IN ('PX_124')
		THEN 'Hysterectomy' -- good

	WHEN a.drg_no IN ('469', '470')
		AND PX_CC.CC_Code IN ('PX_152', 'PX_153')
		-- Exclusions
		AND DX_CC.CC_Code NOT IN ('DX_237', 'DX_238', 'DX_230', 'DX_229'
		, 'DX_226', 'DX_225', 'DX_231', 'DX_207')
		THEN 'Joint Replacement' -- good

	WHEN a.drg_no IN ('417', '418', '419')
		THEN 'Laparoscopic Cholecystectomy' -- good

	WHEN a.drg_no IN ('582', '583', '584', '585')
		AND PX_CC.CC_Code IN ('PX_167')
		THEN 'Mastectomy' -- good

	WHEN a.drg_no IN ('280', '281', '282', '283', '284', '285')
		THEN 'MI' -- good

	WHEN a.drg_no IN ('795')
		AND DX_CC.CC_Code IN ('DX_218')
		THEN 'Normal Newborn' -- good

	WHEN a.drg_no IN ('193', '194', '195')
		THEN 'Pneumonia' -- good

	WHEN a.drg_no IN ('881', '885')
		AND DX_CC.CC_Code IN ('DX_657')
		THEN 'Major Depression/Bipolar Affective Disorders' -- good

	WHEN a.drg_no IN ('885')
		AND DX_CC.CC_Code IN ('DX_659')
		THEN 'Schizophrenia' -- good

	WHEN a.drg_no IN ('246', '247', '248', '249', '250', '251')
		AND PX_CC.CC_Code IN ('PX_45')
		THEN 'PTCA' -- good

	WHEN a.drg_no IN ('945', '946')
		THEN 'Rehab' -- good

	WHEN a.drg_no IN ('312')
		THEN 'Syncope' -- good

	WHEN a.drg_no IN ('67', '68', '69')
		THEN 'TIA' -- good

	WHEN a.drg_no IN ('774', '775')
		THEN 'Vaginal Delivery' -- good

	WHEN a.drg_no IN ('216', '217', '218', '219', '220', '221', 
		'266', '267')
		THEN 'Valve Procedure' -- good
		
	WHEN a.drg_no BETWEEN '1' AND '8' 
		OR a.drg_no BETWEEN '10' AND '14' 
		OR a.drg_no IN ('16', '17') 
		OR a.drg_no BETWEEN '20' AND '42' 
		OR a.drg_no BETWEEN '113' AND '117' 
		OR a.drg_no BETWEEN '129' AND '139' 
		OR a.drg_no BETWEEN '163' AND '168' 
		OR a.drg_no BETWEEN '215' AND '265' 
		OR a.drg_no BETWEEN '326' AND '358' 
		OR a.drg_no BETWEEN '405' AND '425' 
		OR a.drg_no BETWEEN '453' AND '519' 
		OR a.drg_no = '520' 
		OR a.drg_no BETWEEN '570' AND '585' 
		OR a.drg_no BETWEEN '614' AND '630' 
		OR a.drg_no BETWEEN '652' AND '675' 
		OR a.drg_no BETWEEN '707' AND '718' 
		OR a.drg_no BETWEEN '734' AND '750' 
		OR a.drg_no BETWEEN '765' AND '780' 
		OR a.drg_no BETWEEN '782' AND '804' 
		OR a.drg_no BETWEEN '820' AND '830' 
		OR a.drg_no BETWEEN '853' AND '858' 
		OR a.drg_no = '876' 
		OR a.drg_no BETWEEN '901' AND '909' 
		OR a.drg_no BETWEEN '927' AND '929' 
		OR a.drg_no BETWEEN '939' AND '941' 
		OR a.drg_no BETWEEN '955' AND '959' 
		OR a.drg_no BETWEEN '969' AND '970' 
		OR a.drg_no BETWEEN '981' AND '989' 
		THEN 'Surgical' -- good 
	ELSE 'Medical' -- good
	
	END AS LIHN_Svc_Line

	FROM smsmir.mir_drg AS A
	LEFT OUTER JOIN smsmir.mir_drg_mstr AS B
	ON A.drg_no = B.drg_no
		AND LEFT(A.DRG_SCHM, 4) = LEFT(B.DRG_SCHM, 4)
	INNER JOIN smsmir.mir_dx_grp AS C
	ON A.pt_id = C.pt_id
		AND A.unit_seq_no = C.unit_seq_no
		AND A.from_file_ind = C.from_file_ind
		AND C.dx_cd_prio = '01'
		AND LEFT(C.dx_cd_type, 2) = 'DF'
		AND dx_cd_schm = '0'
	LEFT OUTER JOIN smsmir.mir_sproc AS D
	ON A.pt_id = D.pt_id
		AND A.unit_seq_no = D.unit_seq_no
		AND A.from_file_ind = D.from_file_ind
		AND D.proc_cd_prio = '01'
		AND D.proc_cd_type != 'C'
		AND D.proc_cd_schm = '0'
	LEFT OUTER JOIN smsdss.c_AHRQ_Dx_CC_Maps AS DX_CC
	ON REPLACE(C.dx_cd, '.', '') = DX_CC.ICDCode
		AND C.dx_cd_schm = RIGHT(DX_CC.ICD_Ver_Flag, 1)
	LEFT OUTER JOIN smsdss.c_AHRQ_Px_CC_Maps    AS PX_CC
	ON REPLACE(D.proc_cd, '.', '') = PX_CC.ICDCode
		AND D.proc_cd_schm = RIGHT(PX_CC.ICD_Ver_Flag, 1)
	INNER JOIN smsmir.vst AS VST
	ON A.PT_ID = VST.PT_ID
		AND VST.prin_dx_cd_schm = '0'

	WHERE a.drg_type = '1' 
	AND a.drg_schm IN (
		'MC11','MC12','MC13','MC14','MC15',
		'MCT4','MC16','MC17','MC18','MC19',
		'MC20','MC21'
	)
	AND A.PT_ID NOT IN (
		SELECT DISTINCT(ZZZ.Encounter)
		FROM smsdss.c_LIHN_Svc_Line_Tbl AS ZZZ
	)

END
;