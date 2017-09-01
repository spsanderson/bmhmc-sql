-- COLUMN SELECTION
SELECT 
REPLACE(UPPER(B.pract_rpt_name), ' X','')   AS [PHYS NAME]
, A.PtNo_Num
, A.Med_Rec_No
, SVC_LN.CONDITION                          AS [CONDITION]
, A.Pt_Age
, A.Days_Stay
, A.vst_start_dtime
, (
   CAST(DATEPART(YEAR, A.Dsch_Date) 
   AS VARCHAR(5)) 
   + '-' 
   + CAST(DATEPART(QUARTER, A.Dsch_Date)
   AS VARCHAR(5))
   )                                        AS [YYYYqN]
, DATEPART(HOUR, A.vst_start_dtime)         AS [ARRIVAL HR]
, A.vst_end_dtime
, DATEPART(HOUR, A.vst_end_dtime)           AS [DISCHARGE HR]
, A.Pt_Sex
, SUBSTRING(A.Pt_Zip_Cd, 1, 5)              AS [ZIP CODE]
, DISCH_B.[DISPO GROUP]
, DISCH.DISPO


-- TABLE(S)
FROM smsdss.BMH_PLM_PtAcct_V         A
INNER MERGE JOIN smsdss.pract_dim_v  B
ON A.Atn_Dr_No = B.src_pract_no

-- CROSS APPLY CASE STATEMENTS
CROSS APPLY (
	SELECT
		CASE
			WHEN drg_no IN (61, 62, 63, 64, 65, 66)
				THEN 'CVA'                       -- LIHN SVC DEF
			WHEN drg_no IN (190, 191, 192)
				THEN 'COPD'                      -- LIHN SVC DEF
			WHEN drg_no IN (193, 194, 195)
				THEN 'PNEUMONIA'                 -- LIHN SVC DEF
			WHEN drg_no IN (870, 871, 872)
				THEN 'SEPTICEMIA'                -- PEPPER RPT DEF
			WHEN drg_no IN (637, 638, 639)
				THEN 'DIABETES'                  -- CMS ICD-10-CM MS-DRGv28 DEF
			WHEN drg_no IN (682, 683, 684)
				THEN 'RENAL FAILURE'             -- CMS ICD-10-CM MS-DRGv28 DEF
	END AS [CONDITION]
) SVC_LN

CROSS APPLY (
	SELECT
		CASE
			WHEN dsch_disp = 'AHB'
				THEN 'Drug/Alcohol Rehab Non-Hospital Facility'
			WHEN dsch_disp = 'AHI'
				THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
			WHEN dsch_disp = 'AHR'
				THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
			WHEN dsch_disp = 'AMA'
				THEN 'Left Against Medical Advice, Elopement'
			WHEN dsch_disp = 'ATB'
				THEN 'Correctional Institution'
			WHEN dsch_disp = 'ATE'
				THEN 'SNF -Sub Acute'
			WHEN dsch_disp = 'ATF'
				THEN 'Specialty Hospital ( i.e Sloan, Schneiders)'
			WHEN dsch_disp = 'ATH'
				THEN 'Hospital - Med/Surg (i.e Stony Brook)'
			WHEN dsch_disp = 'ATL'
				THEN 'SNF - Long Term'
			WHEN dsch_disp = 'ATN'
				THEN 'Hospital - VA'
			WHEN dsch_disp = 'ATP'
				THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
			WHEN dsch_disp = 'ATT'
				THEN 'Hospice at Home, Adult Home, Assisted Living'
			WHEN dsch_disp = 'ATW'
				THEN 'Home, Adult Home, Assisted Living with Homecare'
			WHEN dsch_disp = 'ATX'
				THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
			WHEN dsch_disp IN ('ATX', 'C1A', 'C1N', 'C1Z', 'C2A', 'C2N',
							   'C2Z', 'C3A', 'C3N', 'C3Z', 'C4A', 'C4N', 
							   'C4Z', 'C7A', 'C7N', 'C7Z', 'C8A', 'C8N', 
							   'C8Z', 'D1A', 'D1N', 'D1Z', 'D2A', 'D2N', 
							   'D2Z', 'D3A', 'D3N', 'D3Z', 'D4A', 'D4N', 
							   'D4Z', 'D7A', 'D7N', 'D7Z', 'D8A', 'D8N', 
							   'D8Z'
							   )
				THEN 'DEATH'
	END AS [DISPO]
) DISCH

CROSS APPLY (
	SELECT
		CASE
			WHEN dsch_disp IN (
			'ATB', 'AHB', 'ATF' 
			)
				THEN 'OTHER'
			WHEN dsch_disp IN (
			'AHI', 'ATT'
			)
				THEN 'HOSPICE'
			WHEN dsch_disp IN (
			'ATX', 'C1A', 'C1N', 'C1Z', 'C2A', 'C2N',
			'C2Z', 'C3A', 'C3N', 'C3Z', 'C4A', 'C4N', 
			'C4Z', 'C7A', 'C7N', 'C7Z', 'C8A', 'C8N', 
			'C8Z', 'D1A', 'D1N', 'D1Z', 'D2A', 'D2N', 
			'D2Z', 'D3A', 'D3N', 'D3Z', 'D4A', 'D4N', 
			'D4Z', 'D7A', 'D7N', 'D7Z', 'D8A', 'D8N', 
			'D8Z'
			)
				THEN 'DEATH'
			WHEN dsch_disp 	IN (
			'AHR', 'ATW'
			)
				THEN 'HOME'
			WHEN dsch_disp IN (
			'ATH', 'ATN', 'ATX'
			)
				THEN 'HOSPITAL'
			WHEN dsch_disp = 'AMA' THEN dsch_disp
			WHEN dsch_disp IN (
			'ATE', 'ATL'
			)
				THEN 'SNF'
	END AS [DISPO GROUP]
) DISCH_B

-- FILTERS
WHERE drg_no IN (
61, 62, 63, 64, 65, 66, 190, 191, 192, 193, 194, 195,
870, 871, 872, 637, 638, 639, 682, 683, 684
)
AND Dsch_Date >= '2010-01-01'
AND B.orgz_cd = 'S0X0'
AND B.src_spclty_cd = 'HOSIM'