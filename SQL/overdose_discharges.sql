DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = '2018-01-01';
SET @END   = '2018-07-01';

----------

SELECT PAV.Med_Rec_No
, PAV.PtNo_Num
, PAV.Pt_Name
, PAV.Pt_Age
, PAV.Pt_Sex
--, DX.pt_id
, CAST(PAV.Adm_Date AS date) AS [Adm_Date]
, CAST(PAV.Dsch_Date AS date) AS [Dsch_Date]
, CAST(PAV.Days_Stay AS int) AS [Days_Stay]
, CAST(DX.dx_eff_date AS date) AS [Dx_Eff_Date]
, DX.dx_cd
, DX_DESC.clasf_desc
, DX.dx_cd_prio
--, DX.from_file_ind
--, PAV.PT_NAME
--, PAV.PT_AGE
--, PAV.PT_SEX
, PAV.PYR1_CO_PLAN_CD
, PYRV.PYR_NAME
, PYRV.PYR_GROUP2
, PAV.DSCH_DISP
, CASE
	WHEN DX.dx_cd_prio = '01'
		THEN '1'
		ELSE '0'
  END AS [is_prim_dx]
, CASE
	WHEN LEFT(PAV.PTNO_NUM, 1) = '8'
		THEN '1'
		ELSE '0'
  END AS [DISP_FROM_ED]
, CASE
	WHEN LEFT(DX.dx_cd, 1) = 'F'
		THEN '1'
		ELSE '0'
  END AS [Substance_Abuse_CD]
, CASE
	WHEN LEFT(DX.DX_CD, 1) = 'T'
		THEN '1'
		ELSE '0'
  END AS [Overdose]
, PAV.ED_Adm
, CASE
	WHEN PAV.ED_Adm = 1
		THEN 1
	WHEN LEFT(PTNO_NUM, 1) = '8'
		THEN 1
		ELSE 0
  END AS [Presented_To_Ed]
, CASE
	WHEN LEFT(DX.dx_cd, 5) = 'T40.0' THEN 'OPIATE - OPIUM'
	WHEN LEFT(DX.dx_cd, 5) = 'T40.1' THEN 'OPIATE - HEROIN'
	WHEN LEFT(DX.dx_cd, 5) = 'T40.2' THEN 'OPIATE - OTHER OPIOIDS'
	WHEN LEFT(DX.dx_CD, 5) = 'T40.3' THEN 'OPIATE - METHADONE'
	WHEN LEFT(DX.DX_CD, 5) = 'T40.4' THEN 'OTHER SYNTHETIC NARCOTICS'
	WHEN LEFT(DX.dx_CD, 5) = 'T40.5' THEN 'COCAINE'
	WHEN LEFT(DX.DX_CD, 5) = 'T40.6' THEN 'UNSPECIFID NARCOTICS'
	WHEN LEFT(DX.DX_CD, 5) = 'T40.7' THEN 'CANNABIS (DERIVATIVES)'
	WHEN LEFT(DX.DX_CD, 5) = 'T40.8' THEN 'LSD'
	WHEN LEFT(DX.DX_CD, 5) = 'T40.9' THEN 'HALLUCINOGENS'
  END AS [Opiate_Flag]
, CASE
	WHEN LEFT(DX.DX_CD, 6) = 'T40.2X' THEN 'OPIOID OVERDOESE'
	ELSE 'NON-OPIOID OVERDOSE'
  END AS [Opiod_OD_Flag]

FROM smsmir.dx_grp AS DX
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX_DESC
ON DX.dx_cd = DX_DESC.dx_cd
LEFT OUTER JOIN SMSDSS.BMH_PLM_ptaCCT_V AS PAV
ON DX.PT_ID = PAV.PT_NO
AND DX.FROM_FILE_IND = PAV.FROM_FILE_IND
LEFT OUTER JOIN SMSDSS.PYR_DIM_V AS PYRV
ON PAV.PYR1_CO_PLAN_CD = PYRV.SRC_PYR_CD
AND PAV.REGN_HOSP = PYRV.ORGZ_CD

WHERE DX.dx_eff_date >= @START
AND DX.dx_eff_date < @END
AND LEFT(DX.dx_cd_type, 2) = 'DF'
AND LEFT(DX.dx_cd, 5) IN (
	'T40.0', 'T40.1', 'T40.2', 'T40.3','T40.4','T40.5','T40.6','T40.7','T40.8','T40.9'
)
--AND (
--DX.dx_cd BETWEEN 'F10.10' AND 'F19.99'
--OR
--DX.dx_cd BETWEEN 'T36.0X1A' AND 'T50.994A'
--OR
--DX.dx_cd = 'T40.2X1A'
--)

ORDER BY DX.pt_id
, DX.dx_cd_prio

GO
;


