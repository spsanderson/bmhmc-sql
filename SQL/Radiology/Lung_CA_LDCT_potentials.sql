/*
File: Lung_CA_LDCT_potentials.sql

Input Parameters:
	None

Tables/Views:
	smsdss.BMH_PLM_PtAcct_V
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
	smsmir.trn_sr_obsv
	smsdss.dly_cen_occ_fct_v
	smsdss.rm_bed_mstr_v
	smsmir.hl7_msg_hdr
	smsmir.hl7_ins
	smsdss.pract_dim_v
	smsdss.pyr_dim_v
	
Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

LDCT - Low Dose CT for lung cancer screening

Basic elements needed:
	1. Name
	2. Age
	3. Phone Number
	4. Smoking Status
	5. Current Room Number
	6. Discharge data/time

Criteria:
	1. Age 55 - 77
	2. Smoking Status
		a. Tobacco smoking history of at least 30 pack years (one pack-year = 1 pack per day for one year, 
			1 pack = 20 cigarettes)
	3. Current smoker OR quit within 15 years

Revision History:
Date		Version		Description
----		----		----
2018-06-11	v1			Initial Creation
2018-10-25	v2			Change age range to 55 - 79
2018-11-05	v3			Add:
							Attending (Name and ID)
							Insurance (Code and Name)
							Phone
*/
-- GET INPATIENTS IN AGE RANGE
DECLARE @START DATE;
DECLARE @MINAGE INT;
DECLARE @MAXAGE INT;

SET @START = (GETDATE() - 1);
SET @MINAGE = 55;
SET @MAXAGE = 79;
-----
SELECT PtNo_Num
, Pt_Name
, Pt_Age
, Adm_Date
, Dsch_Date

INTO #TEMPA

FROM smsdss.BMH_PLM_PtAcct_V

WHERE LEFT(PTNO_NUM, 1) IN ('1')
AND LEFT(PTNO_NUM, 4) != '1999'
AND Pt_Age BETWEEN @MINAGE AND @MAXAGE
AND ADM_Date >= @START
AND Dsch_Date IS NULL

-- GET ED TREAT AND RELEASE PATIENTS IN AGE RANGE
SELECT Account
, Patient
, DATEDIFF(YEAR, AgeDOB, ARRIVAL) AS [Pt_Age]
, Arrival AS [Adm_Date]
, TimeLeftED AS [Dsch_Date]

INTO #TEMPB

--FROM smsdss.c_Wellsoft_Rpt_tbl
-- Change to well soft report server linked object
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]

WHERE DATEDIFF(YEAR, AgeDOB, ARRIVAL) BETWEEN @MINAGE AND @MAXAGE
AND CAST(ARRIVAL AS date) = CAST(GETDATE() - 1 AS date)
AND LEFT(TimeLeftED, 1) != '-'
AND LEFT(Account, 1) = '8'

-- GET INPATIENT ASSESSMENT FORM
SELECT A.episode_no
, A.obsv_cd
, A.obsv_cd_name
, A.dsply_val

INTO #TEMPC

FROM (
	SELECT episode_no
	, obsv_cd
	, obsv_cd_name
	, dsply_val

	FROM smsmir.trn_sr_obsv

	WHERE form_usage = 'admission'
	AND obsv_cd IN (
		--'A_BMH_BHToCesRef',
		--'A_BMH_CurrentUse',
		--'A_BMH_OtherTobac',
		--'A_BMH_TobacUse',
		--'A_BMH_TobLastUse',
		--'A_BMH_TobSurvey',
		--'A_BMH_TobUseInPa',
		--'A_TobaccoFreq',
		--'A_TobUsCesCnsPrf',
		--'A_TobUseScrnPerf',
		--'CA_Tobacco',
		--'A_BMH_Advise',
		'A_Tobacco?'
	)
	AND episode_no IN (
			SELECT PTNO_NUM
			FROM #TEMPA
	)

	UNION
	-- GET ED TOBACCO USE
	SELECT Account
	, '' AS [obsv_cd]
	, '' AS [obsv_cd_name]
	, TobaccoUse

	--FROM smsdss.c_Wellsoft_Rpt_tbl
	-- Change to well soft report server linked object
	FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]

	WHERE Account IN (
		SELECT Account
		FROM #TEMPB
	)
) A

-- PUT TEMPA AND B TOGETHER VIA UNION
SELECT A.PtNo_Num
, A.Pt_Name
, A.Pt_Age
, A.Adm_Date
, A.Dsch_Date

INTO #TEMPD

FROM (
	SELECT *
	FROM #TEMPA
	UNION
	SELECT *
	FROM #TEMPB
) A

-- GET LAST KNOWN WARD AND ROOM LOCATION FOR IP
SELECT SUBSTRING(DLY_CEN.pt_id, 5, 8) AS PT_ID
, DLY_CEN.nurs_sta
, RM_MSTR.rm_no
, DLY_CEN.cen_date
, [RN] = ROW_NUMBER() OVER(PARTITION BY DLY_CEN.PT_ID ORDER BY DLY_CEN.CEN_DATE DESC)

INTO #ROOMS

FROM smsdss.dly_cen_occ_fct_v AS DLY_CEN
LEFT OUTER JOIN smsdss.rm_bed_mstr_v AS RM_MSTR
ON DLY_CEN.rm_bed_key = RM_MSTR.id_col
	AND DLY_CEN.orgz_cd = RM_MSTR.orgz_cd

WHERE SUBSTRING(DLY_CEN.PT_ID, 5, 8) IN (
	SELECT ZZZ.PtNo_Num
	FROM #TEMPD AS ZZZ
)
ORDER BY DLY_CEN.pt_id
, DLY_CEN.cen_date

GO
;

SELECT pt_id
, nurs_sta
, rm_no
, CAST(cen_date AS date) AS CEN_DATE

INTO #LASTROOM

FROM #ROOMS
--WHERE CAST(cen_date AS date) = CAST(GETDATE() - 1 AS date)
WHERE RN = 1
GO
;

-- Attending, Insurance, Phone
SELECT MSG_HDR.pt_id
, INS.ins_plan_no
, PYR.pyr_name
, PYR.pyr_group2
, PT.pt_phone_area_city_cd
, PT.pt_phone_no
, PLM.PtNo_Num
, COALESCE(PLM.ATN_DR_NO, VST.atn_pract_no) AS Atn_Dr_No
, COALESCE(PDV.pract_rpt_name, PDV2.PRACT_RPT_NAME) AS pract_rpt_name

INTO #INS_PHONE_ATN

FROM smsmir.hl7_msg_hdr                 AS MSG_HDR
INNER JOIN smsmir.hl7_pt                AS PT
ON MSG_HDR.pt_id = PT.pt_id
	AND MSG_HDR.msg_cntrl_id = PT.last_msg_cntrl_id
INNER JOIN smsmir.hl7_ins               AS INS
ON MSG_HDR.msg_cntrl_id = INS.last_msg_cntrl_id
	AND MSG_HDR.pt_id = INS.pt_id
INNER JOIN smsmir.hl7_vst               AS VST
ON MSG_HDR.PT_ID = VST.PT_ID
	AND MSG_HDR.msg_cntrl_id = VST.last_msg_cntrl_id
LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS PLM
ON MSG_HDR.pt_id = PLM.Pt_No
LEFT OUTER JOIN smsdss.pract_dim_v      AS PDV
ON PLM.Atn_Dr_No = PDV.src_pract_no
	AND PLM.Regn_Hosp = PDV.orgz_cd
LEFT OUTER JOIN smsdss.pyr_dim_v        AS PYR
ON INS.ins_plan_no = PYR.pyr_cd
	AND PYR.orgz_cd = 'S0X0'
LEFT OUTER JOIN smsdss.pract_dim_v      AS PDV2
ON VST.atn_pract_no = PDV2.src_pract_no
	AND PDV2.orgz_cd = 'S0X0'

WHERE INS.ins_plan_prio_no = 1
AND MSG_HDR.pt_id IN (
	SELECT PTNO_NUM
	FROM #TEMPD
)

-- GET IP ADMISSION FORM DISPLAY VALUE FOR SMOKING STATUS
SELECT A.PtNo_Num   AS [Encounter]
, A.Pt_Name
, A.Pt_Age
, CAST(A.Adm_Date AS date) AS [Adm_Date]
, A.Dsch_Date
, B.dsply_val       AS [Stated_Smoking_Status]
, C.nurs_sta        AS [Last_Nurse_Station]
, C.rm_no           AS [Last_Room_No]
, D.Atn_Dr_No       AS [Attending_ID]
, D.pract_rpt_name  AS [Attending_Name]
, D.ins_plan_no     AS [Primiary_Ins_Cd]
, D.pyr_name        AS [Primiary_Ins_Name]
, D.pyr_group2      AS [Ins_Fin_Class]
, CAST(D.pt_phone_area_city_cd AS varchar) + CAST(D.Pt_Phone_No AS varchar) AS [PT_Phone]

FROM #TEMPD AS A
LEFT OUTER JOIN #TEMPC AS B
ON A.PtNo_Num = B.episode_no
LEFT OUTER JOIN #LASTROOM AS C
ON A.PtNo_Num = C.PT_ID
LEFT OUTER JOIN #INS_PHONE_ATN AS D
ON A.PtNo_Num = D.pt_id

WHERE B.dsply_val IS NOT NULL

ORDER BY A.PtNo_Num

GO
;

--DROP TEMP TABLES
DROP TABLE #TEMPA;
DROP TABLE #TEMPB;
DROP TABLE #TEMPC;
DROP TABLE #TEMPD;
DROP TABLE #ROOMS;
DROP TABLE #LASTROOM;
DROP TABLE #INS_PHONE_ATN;