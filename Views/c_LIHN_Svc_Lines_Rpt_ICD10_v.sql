USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_LIHN_Svc_Lines_Rpt_ICD10_v]    Script Date: 3/22/2016 8:53:45 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [smsdss].[c_LIHN_Svc_Lines_Rpt_ICD10_v]
AS

SELECT     
a.pt_id
, b.vst_end_dtime AS Dsch_Date
, DATEDIFF(dd, b.vst_start_dtime, b.vst_end_dtime) AS LOS
, b.prim_pract_no AS Atn_Dr_No
, c.pract_rpt_name AS Atn_Dr_Name
, a.drg_no
, a.drg_schm
, a.drg_name
, a.Diag01
, a.Diagnosis
, a.Proc01
, a.[Procedure]
, a.Shock_Ind
, a.Intermed_Coronary_Synd_Ind
, CASE 
	WHEN a.drg_no IN ('896', '897')
		AND D.CC_Code = 'DX_660'
		THEN 'Alcohol Abuse'

	WHEN a.drg_no IN ('231', '232', '233', '234', '235', '236')
		THEN 'CABG'

	WHEN a.drg_no IN ('34', '35', '36', '37', '38', '39')
		AND p.CC_Code IN ('PX_51', 'PX_59')
		THEN 'Carotid Endarterectomy'

	WHEN a.drg_no IN ('602', '603')
		AND d.CC_Code IN ('DX_197')
		THEN 'Cellulitis'

	WHEN --a.drg_no IN ('286', '287', '313')
		-- edited 3/22/2016 sps due to new LIHN guidelines
		a.drg_no IN ('313')
		AND d.CC_Code IN ('DX_102')
		THEN 'Chest Pain'

	WHEN a.drg_no IN ('291', '292', '293')
		AND d.CC_Code IN ('DX_108', 'DX_99')
		THEN 'CHF'

	WHEN a.drg_no IN ('190', '191', '192')
		AND d.CC_Code IN ('DX_127', 'DX_128')
		THEN 'COPD'

	WHEN a.drg_no IN ('765', '766')
		THEN 'C-Section'

	WHEN a.drg_no IN ('61', '62', '63', '64', '65', '66')
		THEN 'CVA'

	WHEN a.drg_no IN ('619', '620', '621')
		AND p.CC_Code IN ('PX_74')
		THEN 'Bariatric Surgery for Obesity'

	WHEN a.drg_no IN ('377',' 378', '379')
		THEN 'GI Hemorrhage'

	WHEN a.drg_no IN ('739', '740', '741', '742', '743')
		AND p.CC_Code IN ('PX_124')
		THEN 'Hysterectomy'

	WHEN a.drg_no IN ('469', '470')
		AND p.CC_Code IN ('PX_152', 'PX_153')
		-- Exclusions
		AND d.CC_Code NOT IN ('DX_237', 'DX_238', 'DX_230', 'DX_229'
		, 'DX_226', 'DX_225', 'DX_231', 'DX_207')
		THEN 'Joint Replacement'

	WHEN a.drg_no IN ('417', '418', '419')
		THEN 'Laparoscopic Cholecystectomy'

	WHEN a.drg_no IN ('582', '583', '584', '585')
		AND p.CC_Code IN ('PX_167')
		THEN 'Mastectomy'

	WHEN a.drg_no IN ('280', '281', '282', '283', '284', '285')
		THEN 'MI'

	WHEN a.drg_no IN ('795')
		AND d.CC_Code IN ('DX_218')
		THEN 'Normal Newborn'

	WHEN a.drg_no IN ('193', '194', '195')
		THEN 'Pneumonia'

	WHEN a.drg_no IN ('881', '885')
		AND d.CC_Code IN ('DX_657')
		THEN 'Major Depression/Bipolar Affective Disorders'

	WHEN a.drg_no IN ('885')
		AND d.CC_Code IN ('DX_659')
		THEN 'Schizophrenia'

	WHEN a.drg_no IN ('246', '247', '248', '249', '250', '251')
		AND p.CC_Code IN ('PX_45')
		THEN 'PTCA'

	WHEN a.drg_no IN ('945', '946')
		THEN 'Rehab'

	WHEN a.drg_no IN ('312')
		THEN 'Syncope'

	WHEN a.drg_no IN ('67', '68', '69')
		THEN 'TIA'

	WHEN a.drg_no IN ('774', '775')
		THEN 'Vaginal Delivery'

	WHEN a.drg_no IN ('216', '217', '218', '219', '220', '221', 
		'266', '267')
		THEN 'Valve Procedure'
		
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
		THEN 'Surgical' 
	ELSE 'Medical' 
	
END AS LIHN_Svc_Line
, a.icd_cd_schm
, a.proc_cd_schm

FROM smsdss.c_LIHN_Svc_Lines_1_ICD10_v      AS a 
LEFT OUTER JOIN smsmir.mir_vst				AS b 
ON a.pt_id = b.pt_id 
LEFT OUTER JOIN smsmir.mir_pract_mstr		AS c 
ON b.prim_pract_no = c.pract_no 
	AND c.src_sys_id = '#PASS0X0'
LEFT OUTER JOIN smsdss.c_AHRQ_Dx_CC_Maps    AS d
ON a.Diag01 = d.ICDCode
	AND a.icd_cd_schm = RIGHT(d.ICD_Ver_Flag, 1)
	AND a.icd_cd_schm = '0'
LEFT OUTER JOIN smsdss.c_AHRQ_Px_CC_Maps    AS p
ON a.Proc01 = p.ICDCode
	AND a.proc_cd_schm = RIGHT(p.ICD_Ver_Flag, 1)
	AND a.proc_cd_schm = '0'
	
WHERE a.drg_schm IN ('MC11', 'MC12', 'MC13', 'MC14', 'MC15', 'MCT4')


GO


