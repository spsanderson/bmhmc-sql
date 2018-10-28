/*
--------------------------------------------------------------------------------

File : daily_obv_discharges.sql

Parameters : 
	NONE
--------------------------------------------------------------------------------
Purpose: Daily observation discharges

Tables: 
	smsdss.c_obv_Comb_1
	
Views:
	smsdss.c_patient_demos_v
	smsdss.bmh_plm_ptacct_v
	smsmir.hl7_p
    smsdss.pyr_dim_v
	smsdss.pract_dim_v
	
Functions: None
	
Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle
	
Revision History: 
Date		Version		Description
----		----		----
2018-10-02	v1			Initial Creation
2018-10-03	v2			Add Payor Group and PCP ID, and Name if in pract_dim_v
2018-10-05	v3			Interface updated to pass through provider ID and Name
						into smsmir.hl7_pt
						Update query to get provider name from id number if 
						it exists in pract_dim_v, else pull free text name 
						provided
						Use answer provided here:
						https://stackoverflow.com/questions/52666175/t-sql-left-outer-join-select-top-1-max?noredirect=1#comment92262684_52666175
--------------------------------------------------------------------------------
*/

SELECT PLM.MED_REC_NO                        AS [MRN]
, OBV.PT_ID                                  AS [Encounter]
, CONVERT(VARCHAR, OBV.OBV_STRT_DTIME, 120)  AS [Obs_Start_DTime]
, CONVERT(VARCHAR, obv.dsch_strt_dtime, 120) AS [Obs_End_DTime]
, DATEDIFF(
	HOUR
	, OBV.OBV_STRT_DTIME
	, OBV.DSCH_STRT_DTIME
  )                                          AS [Hrs_In_Obs]
, OBV.ADM_DX
, PT_DEMOS.RPT_NAME                          AS [Pt_Name]
, CAST(PT_DEMOS.PT_DOB AS date)              AS [Pt_DOB]
, PT_DEMOS.GENDER_CD                         AS [Pt_Gender]
, PT_DEMOS.MARITAL_STS_DESC                  AS [Pt_Marital_Sts]
, PT_DEMOS.ADDR_LINE1
, PT_DEMOS.PT_ADDR_LINE2
, PT_DEMOS.PT_ADDR_CITY
, PT_DEMOS.PT_ADDR_STATE
, PT_DEMOS.PT_ADDR_ZIP
, PT_DEMOS.PT_PHONE_NO
, LEFT(HL7.prim_care_prov_name_id, 6)        AS [PCP_ID]
, CASE
	WHEN LEFT(HL7.prim_care_prov_name_id, 6) = '999000'
		THEN 'PT HAS NO PCP'
	WHEN LEFT(HL7.prim_care_prov_name_id, 6) = '999003'
		THEN 'DID NOT WANT TO PROVIDE'
	WHEN LEFT(HL7.PRIM_CARE_PROV_NAME_ID, 6) = '777777'
		THEN RTRIM(LTRIM(SUBSTRING(HL7.PRIM_CARE_PROV_NAME_ID, 7, LEN(HL7.prim_care_prov_name_id))))
		ELSE MD.pract_rpt_name
  END AS [MD_NAME_TEST]
, PDV.pyr_group2

FROM [smsdss].[c_obv_Comb_1]                 AS OBV
LEFT OUTER JOIN [SMSDSS].[C_PATIENT_DEMOS_V] AS PT_DEMOS
ON OBV.PT_ID = SUBSTRING(PT_DEMOS.PT_ID, 5, 8)
LEFT OUTER JOIN [SMSDSS].[BMH_PLM_PTACCT_V]  AS PLM
ON OBV.PT_ID = PLM.PTNO_NUM
LEFT OUTER JOIN smsmir.hl7_pt                AS HL7
ON OBV.PT_ID = HL7.PT_ID
LEFT OUTER JOIN smsdss.pyr_dim_v             AS PDV
ON PLM.Pyr1_Co_Plan_Cd = PDV.pyr_cd
	AND PLM.Regn_Hosp = PDV.orgz_cd
OUTER APPLY (
	SELECT TOP 1 ZZZ.src_pract_no
	, ZZZ.pract_rpt_name
	FROM smsdss.pract_dim_v AS ZZZ
	WHERE LEFT(HL7.PRIM_CARE_PROV_NAME_ID, 6) = ZZZ.SRC_PRACT_NO
	ORDER BY ZZZ.orgz_cd
)                                            AS MD

WHERE OBV.DSCH_STRT_DTIME >= DATEADD(DAY, DATEDIFF(DAY, 0, CAST(GETDATE() AS date)) - 1, 0)
AND PLM.Dsch_Date IS NOT NULL

OPTION(FORCE ORDER)
;