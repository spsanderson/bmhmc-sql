USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_LIHN_Svc_Lines_Rpt_ICD10_v]    Script Date: 11/17/2015 2:51:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [smsdss].[c_LIHN_Svc_Lines_Rpt_ICD10_v]
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
	WHEN a.drg_no IN ('34', '35', '36', '37', '38', '39') 
		THEN 'Carotid Endarterectomy' 
		
	WHEN a.drg_no IN ('61', '62', '63', '64', '65', '66') 
        THEN 'CVA' 
		
	WHEN a.drg_no IN ('67', '68', '69') 
		THEN 'TIA' 
		
	WHEN a.drg_no IN ('190', '191', '192') 
		THEN 'COPD' 
		
	WHEN a.drg_no IN ('193', '194', '195') 
        THEN 'Pneumonia' 
		
	WHEN a.drg_no IN ('216', '217', '218', '219', '220', '221', '266'
					, '267') 
		THEN 'Valve Procedures' 
		
	WHEN a.drg_no IN ('231', '232', '233') 
		AND (NOT 
				(Diag01 IN ('I2542','I2609','I309','I020','I308','I300',
				            'I010'
							)
				) 
			)
		OR (
		a.drg_no IN ('234', '235', '236')
		AND Diag01 NOT IN (
			'S2699XA',	 'S2699XA',	'I2542',	'S2609XA',	'R0789',
			'S2691XA',	 'R0789',	'I240',		'S26021A',	'R0781',
			'S2690XA',	 'R0781',	'I209',		'S26020A',	'R072',
			'S2619XA',	 'R071',	'I020',		'S2601XA',	'R071',
			'S2612XA',	 'N280',	'I011',		'S2600XA',	'I7779',
			'S2611XA',	 'I2542',	'I010',		'S26002A',	'I7773',
			'S2610XA',	 'I209',	'I2609',	'R079',		'I7772',
			'I7771',	 'I744',	'I7102',	'I512',		'I330',
			'I76',		 'I7411',	'I7101',	'I511',		'I312',
			'I749',		 'I7410',	'I7100',	'I469',		'I309',
			'I748',		 'I7409',	'I670',		'I400',		'I308',
			'I745',		 'I7103',	'I663',		'I38',		'I300',
			'I339'
			)
		AND (Diag01 NOT BETWEEN 'T80' AND 'T88.9')
		)
		THEN 'CABG' 
		
	WHEN a.drg_no IN ('250', '251', '249', '247', '248', '246') 
		AND Proc01 IN ('02704DZ', '02714DZ', '02724DZ', '02734DZ', '027044Z', 
						'027144DZ', '027244Z', '027344Z'
					) 
		THEN 'PTCA' 
		
	WHEN a.drg_no IN ('280', '281', '282', '283', '284', '285') 
		AND (Diag01 IN ('I2109', 'I2119', 'I2111', 'I2129', 'I2129', 'I222',
			'I213', 'I213', 'I2109', 'I2119', 'I2102', 'I2121', 'I2101', 
			'I2121', 'I2111', 'I214'
				)
			)
		THEN 'MI' 
		
	WHEN a.drg_no IN ('291', '292', '293') 
		AND Shock_Ind IS NULL 
		THEN 'CHF' 
		
	WHEN a.drg_no IN ('313') 
		OR (a.drg_no IN ('287') 
			AND Diag01 IN ('R079', 'R0789', 'R0789', 'I209', 'R0789', 'R071', 'R0781', 'R072', 'R0789', 
			'R079', 'R072', 'R071', 'R079', 'R000', 'R002', 'I25110', 'I2510')
			) 
		THEN 'Chest Pain' 
		
	WHEN a.drg_no IN ('377', '378', '379') 
        THEN 'GI Hemorrhage'
		
	WHEN a.drg_no IN ('469', '470') 
		AND Proc01 IN ('0SR9019','0SR901A','0SR901Z',
					   '0SR9029','0SR902A','0SR902Z',
					   '0SR9039','0SR903A','0SR903Z',
					   '0SRB019','0SRB01A','0SRB01Z',
					   '0SRB029','0SRB02A','0SRB02Z',
					   '0SRB039','0SRB03A','0SRB03Z',
					   '0SRB049','0SRB04A','0SRB04Z',
					   '0SRB0J9','0SRB0JA','0SRB0JZ',
					   '0SRA009','0SRA000','0SRA00Z',
					   '0SRA019','0SRA01A','0SRA01Z',
					   '0SRA039','0SRA03A','0SRA03Z',
					   '0SRA0J9','0SRA0JA','0SRA0JZ',
					   '0SRE009','0SRE00A','0SRE00Z',
					   '0SRE019','0SRE01A','0SRE01Z',
					   '0SRE039','0SRE03A','0SRE03Z',
					   '0SRE0J9','0SRE0JA','0SRE0JZ',
					   '0SRR019','0SRR01A','0SRR01Z',
					   '0SRR039','0SRR03A','0SRR03Z',
					   '0SRR0J9','0SRR0JA','0SRR0JZ',
					   '0SRS019','0SRS01A','0SRS01Z',
					   '0SRS039','0SRS03A','0SRS03Z',
					   '0SRS0J9','OSRSOJA','0SRS0JZ',
					   '0SRC0JZ','0SRD0JZ'
					   ) 
		AND (NOT 
				(Diag01 
					IN ('M84651A','M84653','S8200XA','S8200XB','M84652A'
					)
				AND Diag01 BETWEEN 'S72001A' AND 'S7292XA' 
				)
			) 
		THEN 'Joint Replacement' 
		
	WHEN a.drg_no IN ('739', '740', '741', '742', '743') 
		AND LEFT(Proc01, 3) IN ('683', '684', '685', '689') 
		THEN 'Hysterectomy' 
		
	WHEN a.drg_no IN ('765', '766') 
		THEN 'C-Section' 
		
	WHEN a.drg_no IN ('774', '775') 
        THEN 'Vaginal Delivery' 
		
	WHEN a.drg_no IN ('795') 
		THEN 'Normal Newborn' 
		
	WHEN a.drg_no IN ('417', '418', '419') 
        THEN 'Laparoscopic Cholecystectomy' 
		
	WHEN a.drg_no IN ('945', '946') 
		THEN 'Rehab' 
		
	WHEN a.drg_no IN ('312') 
		THEN 'Syncope' 
		
	WHEN a.drg_no IN ('881') 
		OR (
			a.drg_no IN ('885') 
			AND Diag01 IN (
				'F329','F320','F321','F322','F324','F325',
				'F339','F330','F331','F332','F3341','F3340'
						)
			) 
		THEN 'Psychoses-Major Depression' 
		
	WHEN a.drg_no IN ('885') 
		AND Diag01 IN ('F309','F3011','F3012','F3013','F3173','F3174',
						'F319','F3111','F3112','F3113','F3173','F3174',
						'F319','F3131','F3132','F314','F3175','F3176',
						'F3160','F3161','F3162','F3163','F3177','F3178',
						'F319','F319','F309','F329','F3189','F39', 'F3181',
						'F3130'
					) 
		THEN 'Psychoses/Bipolar Affective Disorders'
		
	WHEN a.drg_no IN ('885') 
		AND (
			Diag01 IN ('F2089','F302','F323','F333','F312','F315',
			'F3164','F22','F29','F24','F28', 'F250', 'F200'
				) 
			) 
		THEN 'Psychoses/Schizophrenia' 
		
	WHEN (a.drg_no IN ('286', '302', '303', '311') 
		AND Intermed_Coronary_Synd_Ind BETWEEN '0000100000000' AND '000099999999'
		) 
		THEN 'Acute Coronary Syndrome'

	WHEN a.drg_no IN ('287') 
		AND Intermed_Coronary_Synd_Ind BETWEEN '000010000000' AND '000099999999' 
		AND Diag01 NOT IN ('R079', 'R0789', 'R0789', 'I209', 'R0789', 'R071', 'R0781', 'R072', 'R0789', 
			'R079', 'R072', 'R071', 'R079', 'R000', 'R002', 'I25110', 'I2510'
						) 
        THEN 'Acute Coronary Syndrome'

	WHEN a.drg_no IN ('582', '583', '584', '585') 
		AND Proc01 IN (
			'0HBT0ZX','0HBT3ZX','0HBT7ZX','0HBT8ZX','0HBTXZX','0HBU0ZX',
			'0HBU3ZX','0HBU7ZX','0HBU8ZX','0HBUXZX','0HBV0ZX','0HBV3ZX',
			'0HBV7ZX','0HBV8ZX','0HBVXZX','0HBT0ZZ','0HBT3ZZ','0HBT7ZZ',
			'0HBT8ZZ','0HBTXZZ','0HBU0ZZ','0HBU3ZZ','0HBU7ZZ','0HBU8ZZ',
			'0HBUXZZ','0HBV0ZZ','0HBV3ZZ','0HBV7ZZ','0HBV8ZZ','0HBVXZZ',
			'0HTT0ZZ','0HTU0ZZ','0HTV0ZZ','0HUT07Z','0HUT37Z','0HUT77Z',
			'0HUT87Z','0HUTX7Z','0HUT0JZ','0HUT3JZ','0HUT7JZ','0HUT8JZ',
			'0HUTXJZ','0HUT0KZ','0HUT3KZ','0HUT7KZ','0HUT8KZ','0HUTXKZ',
			'0HUU07Z','0HUU37Z','0HUU77Z','0HUU87Z','0HUUX7Z','0HUU0JZ',
			'0HUU3JZ','0HUU7JZ','0HUU8JZ','0HUUXJZ','0HUU0KZ','0HUU3KZ',
			'0HUU7KZ','0HUU8KZ','0HUUXKZ','0HUV07Z','0HUV37Z','0HUV77Z',
			'0HUV87Z','0HUVX7Z','0HUV0JZ','0HUV3JZ','0HUV7JZ','0HUV8JZ',
			'0HUVXJZ','0HUV0KZ','0HUV3KZ','0HUV7KZ','0HUV8KZ','0HUVXKZ'
		) 
		THEN 'Mastectomy'
	
	WHEN a.drg_no IN ('896', '897') 
		AND Diag01 IN ('F10231','F1096','F1097','F10951','F10129',
						'F10950','F10239','F10288','F10129','F1020',
						'F10229','F1021','F10129','F1020','F10229',
						'F1020','F10129','F10229','F10129','F1020',
						'F1010'
					) 
		THEN 'Alcohol Abuse' 
	
	WHEN a.drg_no IN ('619', '620', '621') 
		AND (
			Proc01 BETWEEN '0D11074' AND '0D1L3ZH'
			OR Proc01 BETWEEN 'ODB60Z3' AND '0DB68ZZ'
			OR Proc01 BETWEEN '0DT60ZZ' AND '0DT68ZZ'
		)
         THEN 'Gastric By-pass' 
 
	WHEN a.drg_no IN ('602', '603') 
		AND (Diag01 IN (
			'L02511','L02512','L02519','L03011','L03012','L03.019',
			'L02611','L02612','L02619','L03031','L03032','L03039'
			) 
			OR Diag01 BETWEEN 'L0241' AND 'L089'
			OR Diag01 BETWEEN 'L03111' AND 'L03112'
		)
		THEN 'Cellulitis' 
		
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
	
WHERE a.drg_schm IN ('MC11', 'MC12', 'MC13', 'MC14', 'MC15', 'MCT4')

GO