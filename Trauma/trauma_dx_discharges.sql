DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = '2017-04-01';
SET @END   = '2018-04-01';

SELECT DX.pt_id
, DX.unit_seq_no
, DX.dx_cd_prio
, DX.dx_cd
, LEFT(DX.dx_cd, 3) AS [Dx_Cd_Prefix]
, CASE
	WHEN LEFT(DX.DX_CD, 3) NOT IN (
		'S00','S10','S20','S30','S40','S50','S60','S70','S80','S90'
	)
		THEN 1
		ELSE 0
  END AS [Outside_S_0_Range]
, CASE
	WHEN LEFT(DX.DX_CD, 3) IN (
		'S00','S10','S20','S30','S40','S50','S60','S70','S80','S90'
	)
		THEN 1
		ELSE 0
  END AS [Inside_S_0_Range]
, Dx_Code_Desc.alt_clasf_desc
, DX.dx_cd_schm
, DX.dx_cd_type
, DX.dx_eff_date
, DX.from_file_ind
, PAV.Atn_Dr_No
, Attending.pract_rpt_name AS [Attending]
, PAV.Adm_Dr_No
, Admitting.pract_rpt_name AS [Admitting]
, PAV.ED_Adm
, TRAUMA_TYPE.Type_Of_Trauma
, AREA.Trauma_Area
, CASE
	WHEN LEFT(PAV.PtNo_Num, 1) = '1'
		THEN 'I'
	WHEN LEFT(PAV.PTNO_NUM, 1) = '8'
		THEN 'E'
		ELSE 'O'
  END AS [Pt_Acct_Type]
, CASE
	WHEN PAV.Adm_Source IN ('RA', 'RP')
		THEN 1
		ELSE 0
  END AS [Direct_Admit_Flag]
, PAV.User_Pyr1_Cat
, CASE
	WHEN PAV.User_Pyr1_Cat IN (
		'AAA', 'EEE', 'ZZZ'
	)
		THEN 'MEDICARE'
	WHEN PAV.User_Pyr1_Cat IN (
		'BBB', 'JJJ', 'KKK'
	)
		THEN 'HMO/PPO'
	WHEN PAV.User_Pyr1_Cat IN (
		'CCC', 'NNN'
	)
		THEN 'OTHER'
	WHEN PAV.User_Pyr1_Cat IN (
		'III', 'WWW'
	)
		THEN 'MEDICAID'
	WHEN PAV.User_Pyr1_Cat IN (
		'MIS'
	)
		THEN 'INDIGENT/UNCOMPENSATED'
	WHEN PAV.User_Pyr1_Cat = 'XXX'
		THEN 'COMMERCIAL'
  END AS [PAYER_GROUPING]
, CASE
	WHEN (
		PAV.Atn_Dr_No IN (
			'019398','019372','019356','019380','008698','013813','017772','018671','013326','017772','019703','010108'
		)
		OR
		PAV.Adm_Dr_No IN (
			'019398','019372','019356','019380','008698','013813','017772','018671','013326','017772','019703','010108'
		)
	)
		THEN 1
		ELSE 0
  END AS [Admit_Attend_Trauma_Svc]
, CASE
	WHEN PAV.Adm_Dr_No IN (
			'019398','019372','019356','019380','008698','013813','017772','018671','013326','017772','019703','010108'
		)
		THEN 1
		ELSE 0
  END AS [Admit_To_Trauma_Svc]
, PAV.dsch_disp
, CASE
	WHEN PAV.dsch_disp IN ('ATH', 'TH', ' TH')
		THEN 1
		ELSE 0
  END AS [Xfer_Flag]
, CASE
	WHEN LEFT(PAV.DSCH_DISP, 1) IN ('C', 'D')
		THEN 1
		ELSE 0
  END AS [Mortality_Flag]

, [RN] = ROW_NUMBER() OVER(
	PARTITION BY DX.PT_ID
	ORDER BY DX.PT_ID, DX.DX_CD_PRIO
)

FROM smsmir.dx_grp AS DX
LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS PAV
ON DX.PT_ID = PAV.PT_NO
	AND DX.from_file_ind = PAV.from_file_ind
LEFT OUTER JOIN smsdss.pract_dim_v AS Attending
ON PAV.Atn_Dr_No = Attending.src_pract_no
	AND PAV.Regn_Hosp = Attending.orgz_cd
LEFT OUTER JOIN smsdss.pract_dim_v AS Admitting
ON PAV.Adm_Dr_No = Admitting.src_pract_no
	AND PAV.Regn_Hosp = Admitting.orgz_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS Dx_Code_Desc
ON DX.dx_cd = Dx_Code_Desc.dx_cd

CROSS APPLY (
	SELECT
		CASE
			WHEN LEFT(DX.DX_CD, 2) = 'S0' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 2) = 'S1' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 2) = 'S2' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 2) = 'S3' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 2) = 'S4' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 2) = 'S5' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 2) = 'S6' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 2) = 'S7' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 2) = 'S8' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 2) = 'S9' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 3) = 'T07' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 3) = 'T14' THEN 'INJURY'
			WHEN LEFT(DX.DX_CD, 3) = 'T20' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 3) = 'T21' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 3) = 'T22' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 3) = 'T23' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 3) = 'T24' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 3) = 'T25' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 3) = 'T26' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 3) = 'T27' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 3) = 'T28' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 3) = 'T30' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 3) = 'T31' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 3) = 'T32' THEN 'BURN-CORROSION'
			WHEN LEFT(DX.DX_CD, 5) = 'T79.A' THEN 'TCS'
		END AS [Type_Of_Trauma]
) [TRAUMA_TYPE]

CROSS APPLY (
	SELECT
		CASE
			WHEN LEFT(DX.DX_CD, 2) = 'S0' THEN 'HEAD'
			WHEN LEFT(DX.DX_CD, 2) = 'S1' THEN 'NECK'
			WHEN LEFT(DX.DX_CD, 2) = 'S2' THEN 'THORAX'
			WHEN LEFT(DX.DX_CD, 2) = 'S3' THEN 'ABDOMEN, LOWER BACK, PELVIS, EXTERNAL GENITALS'
			WHEN LEFT(DX.DX_CD, 2) = 'S4' THEN 'SHOULDER, UPPER ARM'
			WHEN LEFT(DX.DX_CD, 2) = 'S5' THEN 'ELBOW, FOREARM'
			WHEN LEFT(DX.DX_CD, 2) = 'S6' THEN 'WRIST, HAND, FINGERS'
			WHEN LEFT(DX.DX_CD, 2) = 'S7' THEN 'HIP, THIGH'
			WHEN LEFT(DX.DX_CD, 2) = 'S8' THEN 'KNEE, LOWER LEG'
			WHEN LEFT(DX.DX_CD, 2) = 'S9' THEN 'ANKLE, FOOT, TOES'
			WHEN LEFT(DX.DX_CD, 3) = 'T07' THEN 'MULITPLE INJURIES'
			WHEN LEFT(DX.DX_CD, 3) = 'T14' THEN 'UNSPECIFIED BODY REGION'
			WHEN LEFT(DX.DX_CD, 3) = 'T20' THEN 'HEAD, FACE, NECK'
			WHEN LEFT(DX.DX_CD, 3) = 'T21' THEN 'TRUNK'
			WHEN LEFT(DX.DX_CD, 3) = 'T22' THEN 'SHOULDER, UPPER LIMB, EXCEPT WRIST AND HAND'
			WHEN LEFT(DX.DX_CD, 3) = 'T23' THEN 'WRIST, HAND, FINGERS'
			WHEN LEFT(DX.DX_CD, 3) = 'T24' THEN 'LOWER LIMB, EXCEPT ANKEL, FOOT'
			WHEN LEFT(DX.DX_CD, 3) = 'T25' THEN 'ANKLE, FOOT, TOES'
			WHEN LEFT(DX.DX_CD, 3) = 'T26' THEN 'CONFINED TO EYE AND ADNEXA'
			WHEN LEFT(DX.DX_CD, 3) = 'T27' THEN 'RESPIRATORY TRACT'
			WHEN LEFT(DX.DX_CD, 3) = 'T28' THEN 'OTHER INTERNAL ORGANS'
			WHEN LEFT(DX.DX_CD, 3) = 'T30' THEN 'BODY REGION UNSPECIFIED'
			WHEN LEFT(DX.DX_CD, 3) = 'T31' THEN 'CLASSIFIED BY EXTENT OF BODY SURFACE INVOLVED'
			WHEN LEFT(DX.DX_CD, 3) = 'T32' THEN 'CLASSIFIED BY EXTENT OF BODY SURFACE INVOLVED'
			WHEN LEFT(DX.DX_CD, 5) = 'T79.A' THEN 'NON-BILLABLE/NON-SPECIFIC CODE TRAUMATIC COMPARTMENT SYNDROME'
		END AS [Trauma_Area]
) [AREA]

--WHERE (
--	Admitting.src_pract_no IN (
--		SELECT ID FROM @Trauma_MD
--	)
--	OR
--	Attending.src_pract_no IN (
--		SELECT ID FROM @Trauma_MD
--	)
--)
WHERE Adm_Date >= @START
AND Adm_Date < @END
AND LEFT(DX.dx_cd_type, 2) = 'DF'
AND (
	LEFT(DX.dx_cd, 2) IN (
		'S0','S1','S2','S3','S4','S5','S6','S7','S8','S9'
	)
	OR
	LEFT(Dx.dx_cd, 3) IN (
		'T07','T14','T20','T21','T22','T23','T24',
		'T25','T26','T27','T28','T30','T31','T32'
	)
	OR
	LEFT(DX.dx_cd, 5) = 'T79.A'
)
ORDER BY DX.pt_id
, DX.dx_cd_prio
;