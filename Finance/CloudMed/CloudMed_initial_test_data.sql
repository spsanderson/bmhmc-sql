/*
***********************************************************************
File: CloudMed_initial_test_data.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
	smsdss.dx_cd_dim_v
	smsdss.proc_dim_v
	smsmir.sproc
	smsmir.dxgrp
	smsdss.pyr_dim_v
	smsdss.drg_dim_v
	Customer.Custom_DRG

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Gather initial data for Revint/Cloudmed initial data set

Revision History:
Date		Version		Description
----		----		----
2019-02-27	v1			Initial Creation
***********************************************************************
*/

SELECT PAV.PtNo_Num
, CAST(PAV.ADM_DATE AS date) AS [ADM_DATE]
, CAST(PAV.DSCH_DATE AS DATE) AS [DSCH_DATE]
, CAST(PAV.Last_Billed AS date) AS [BILL_DATE]
, PAV.drg_no AS [DRG]
, DRG.drg_name_modf
, CASE
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HB' THEN 'Drug/Alcohol Rehab Non-Hospital Facility'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HI' THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'MA' THEN 'Left Against Medical Advice, Elopement'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TB' THEN 'Correctional Institution'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TE' THEN 'SNF -Sub Acute'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TF' THEN 'Specialty Hospital ( i.e Sloan, Schneiders)'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TH' THEN 'Hospital - Med/Surg (i.e Stony Brook)'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TL' THEN 'SNF - Long Term'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TN' THEN 'Hospital - VA'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TP' THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TT' THEN 'Hospice at Home, Adult Home, Assisted Living'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TW' THEN 'Home, Adult Home, Assisted Living with Homecare'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TX' THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = '1A' THEN 'Postoperative Death, Autopsy'
	WHEN LEFT(PAV.dsch_disp, 1) IN ('C', 'D') THEN 'Mortality'
  END AS [DISPOSITION]
, SOIROM.SEVERITY_OF_ILLNESS
, SOIROM.RISK_OF_MORTALITY
, SPROC.PROC_CD_1
, P1.clasf_desc AS [PROC_CD_1_DESC]
, SPROC.PROC_CD_2
, P2.clasf_desc AS [PROC_CD_2_DESC]
, SPROC.PROC_CD_3
, P3.clasf_desc AS [PROC_CD_3_DESC]
, SPROC.PROC_CD_4
, P4.clasf_desc AS [PROC_CD_4_DESC]
, SPROC.PROC_CD_5
, P5.clasf_desc AS [PROC_CD_5_DESC]
, SPROC.PROC_CD_6
, P6.clasf_desc AS [PROC_CD_6_DESC]
, SPROC.PROC_CD_7
, P7.clasf_desc AS [PROC_CD_7_DESC]
, SPROC.PROC_CD_8
, P8.clasf_desc AS [PROC_CD_8_DESC]
, SPROC.PROC_CD_9
, P9.clasf_desc AS [PROC_CD_9_DESC]
, SPROC.PROC_CD_10
, P10.clasf_desc AS [PROC_CD_10_DESC]
, SPROC.PROC_CD_11
, P11.clasf_desc AS [PROC_CD_11_DESC]
, SPROC.PROC_CD_12
, P12.clasf_desc AS [PROC_CD_12_DESC]
, SPROC.PROC_CD_13
, P13.clasf_desc AS [PROC_CD_13_DESC]
, SPROC.PROC_CD_14
, P14.clasf_desc AS [PROC_CD_14_DESC]
, SPROC.PROC_CD_15
, P15.clasf_desc AS [PROC_CD_15_DESC]
, SPROC.PROC_CD_16
, P16.clasf_desc AS [PROC_CD_16_DESC]
, SPROC.PROC_CD_17
, P17.clasf_desc AS [PROC_CD_17_DESC]
, SPROC.PROC_CD_18
, P18.clasf_desc AS [PROC_CD_18_DESC]
, SPROC.PROC_CD_19
, P19.clasf_desc AS [PROC_CD_19_DESC]
, SPROC.PROC_CD_20
, P20.clasf_desc AS [PROC_CD_20_DESC]
, SPROC.PROC_CD_21
, P21.clasf_desc AS [PROC_CD_21_DESC]
, SPROC.PROC_CD_22
, P22.clasf_desc AS [PROC_CD_22_DESC]
, SPROC.PROC_CD_23
, P23.clasf_desc AS [PROC_CD_23_DESC]
, SPROC.PROC_CD_24
, P24.clasf_desc AS [PROC_CD_24_DESC]
, SPROC.PROC_CD_25
, P25.clasf_desc AS [PROC_CD_25_DESC]
, SPROC.PROC_CD_26
, P26.clasf_desc AS [PROC_CD_26_DESC]
, SPROC.PROC_CD_27
, P27.clasf_desc AS [PROC_CD_27_DESC]
, SPROC.PROC_CD_28
, P28.clasf_desc AS [PROC_CD_28_DESC]
, SPROC.PROC_CD_29
, P29.clasf_desc AS [PROC_CD_29_DESC]
, SPROC.PROC_CD_30
, P30.clasf_desc AS [PROC_CD_30_DESC]
, 'DX_CD_PRIO_1' AS [DX_CD_PRIORITY_1]
, DXGRP.DX_CD_1
, DX1.clasf_desc AS [DX_CD_1_DESC]
, 'DX_CD_PRIO_2' AS [DX_CD_PRIORITY_2]
, DXGRP.DX_CD_2
, DX2.clasf_desc AS [DX_CD_2_DESC]
, 'DX_CD_PRIO_3' AS [DX_CD_PRIORITY_3]
, DXGRP.DX_CD_3
, DX3.clasf_desc AS [DX_CD_3_DESC]
, 'DX_CD_PRIO_4' AS [DX_CD_PRIORITY_4]
, DXGRP.DX_CD_4
, DX4.clasf_desc AS [DX_CD_4_DESC]
, 'DX_CD_PRIO_5' AS [DX_CD_PRIORITY_5]
, DXGRP.DX_CD_5
, DX5.clasf_desc AS [DX_CD_5_DESC]
, 'DX_CD_PRIO_6' AS [DX_CD_PRIORITY_6]
, DXGRP.DX_CD_6
, DX6.clasf_desc AS [DX_CD_6_DESC]
, 'DX_CD_PRIO_7' AS [DX_CD_PRIORITY_7]
, DXGRP.DX_CD_7
, DX7.clasf_desc AS [DX_CD_7_DESC]
, 'DX_CD_PRIO_8' AS [DX_CD_PRIORITY_8]
, DXGRP.DX_CD_8
, DX8.clasf_desc AS [DX_CD_8_DESC]
, 'DX_CD_PRIO_9' AS [DX_CD_PRIORITY_9]
, DXGRP.DX_CD_9
, DX9.clasf_desc AS [DX_CD_9_DESC]
, 'DX_CD_PRIO_10' AS [DX_CD_PRIORITY_10]
, DXGRP.DX_CD_10
, DX10.clasf_desc AS [DX_CD_10_DESC]
, 'DX_CD_PRIO_11' AS [DX_CD_PRIORITY_11]
, DXGRP.DX_CD_11
, DX11.clasf_desc AS [DX_CD_11_DESC]
, 'DX_CD_PRIO_12' AS [DX_CD_PRIORITY_12]
, DXGRP.DX_CD_12
, DX12.clasf_desc AS [DX_CD_12_DESC]
, 'DX_CD_PRIO_13' AS [DX_CD_PRIORITY_13]
, DXGRP.DX_CD_13
, DX13.clasf_desc AS [DX_CD_13_DESC]
, 'DX_CD_PRIO_14' AS [DX_CD_PRIORITY_14]
, DXGRP.DX_CD_14
, DX14.clasf_desc AS [DX_CD_14_DESC]
, 'DX_CD_PRIO_15' AS [DX_CD_PRIORITY_15]
, DXGRP.DX_CD_15
, DX15.clasf_desc AS [DX_CD_15_DESC]
, 'DX_CD_PRIO_16' AS [DX_CD_PRIORITY_16]
, DXGRP.DX_CD_16
, DX16.clasf_desc AS [DX_CD_16_DESC]
, 'DX_CD_PRIO_17' AS [DX_CD_PRIORITY_17]
, DXGRP.DX_CD_17
, DX17.clasf_desc AS [DX_CD_17_DESC]
, 'DX_CD_PRIO_18' AS [DX_CD_PRIORITY_18]
, DXGRP.DX_CD_18
, DX18.clasf_desc AS [DX_CD_18_DESC]
, 'DX_CD_PRIO_19' AS [DX_CD_PRIORITY_19]
, DXGRP.DX_CD_19
, DX19.clasf_desc AS [DX_CD_19_DESC]
, 'DX_CD_PRIO_20' AS [DX_CD_PRIORITY_20]
, DXGRP.DX_CD_20
, DX20.clasf_desc AS [DX_CD_20_DESC]
, 'DX_CD_PRIO_21' AS [DX_CD_PRIORITY_21]
, DXGRP.DX_CD_21
, DX21.clasf_desc AS [DX_CD_21_DESC]
, 'DX_CD_PRIO_22' AS [DX_CD_PRIORITY_22]
, DXGRP.DX_CD_22
, DX22.clasf_desc AS [DX_CD_22_DESC]
, 'DX_CD_PRIO_23' AS [DX_CD_PRIORITY_23]
, DXGRP.DX_CD_23
, DX23.clasf_desc AS [DX_CD_23_DESC]
, 'DX_CD_PRIO_24' AS [DX_CD_PRIORITY_24]
, DXGRP.DX_CD_24
, DX24.clasf_desc AS [DX_CD_24_DESC]
, 'DX_CD_PRIO_25' AS [DX_CD_PRIORITY_25]
, DXGRP.DX_CD_25
, DX25.clasf_desc AS [DX_CD_25_DESC]
, 'DX_CD_PRIO_26' AS [DX_CD_PRIORITY_26]
, DXGRP.DX_CD_26
, DX26.clasf_desc AS [DX_CD_26_DESC]
, 'DX_CD_PRIO_27' AS [DX_CD_PRIORITY_27]
, DXGRP.DX_CD_27
, DX27.clasf_desc AS [DX_CD_27_DESC]
, 'DX_CD_PRIO_28' AS [DX_CD_PRIORITY_28]
, DXGRP.DX_CD_28
, DX28.clasf_desc AS [DX_CD_28_DESC]
, 'DX_CD_PRIO_29' AS [DX_CD_PRIORITY_29]
, DXGRP.DX_CD_29
, DX29.clasf_desc AS [DX_CD_29_DESC]
, 'DX_CD_PRIO_30' AS [DX_CD_PRIORITY_30]
, DXGRP.DX_CD_30
, DX30.clasf_desc AS [DX_CD_30_DESC]
, PDM.pyr_name

FROM smsdss.BMH_PLM_PtAcct_V AS PAV
LEFT OUTER JOIN smsdss.pyr_dim_v AS PDM
ON PAV.Pyr1_Co_Plan_Cd = PDM.pyr_cd
	AND PAV.Regn_Hosp = PDM.orgz_cd
LEFT OUTER JOIN smsdss.drg_dim_v AS DRG
ON PAV.drg_no = DRG.drg_no
	AND DRG.drg_vers = 'MS-V25'
LEFT OUTER JOIN Customer.Custom_DRG AS SOIROM
ON PAV.PtNo_Num = SOIROM.PATIENT#
LEFT OUTER JOIN (
	SELECT PVT.pt_id
	, PVT.[01] AS [PROC_CD_1]
	, PVT.[02] AS [PROC_CD_2]
	, PVT.[03] AS [PROC_CD_3]
	, PVT.[04] AS [PROC_CD_4]
	, PVT.[05] AS [PROC_CD_5]
	, PVT.[06] AS [PROC_CD_6]
	, PVT.[07] AS [PROC_CD_7]
	, PVT.[08] AS [PROC_CD_8]
	, PVT.[09] AS [PROC_CD_9]
	, PVT.[10] AS [PROC_CD_10]
	, PVT.[11] AS [PROC_CD_11]
	, PVT.[12] AS [PROC_CD_12]
	, PVT.[13] AS [PROC_CD_13]
	, PVT.[14] AS [PROC_CD_14]
	, PVT.[15] AS [PROC_CD_15]
	, PVT.[16] AS [PROC_CD_16]
	, PVT.[17] AS [PROC_CD_17]
	, PVT.[18] AS [PROC_CD_18]
	, PVT.[19] AS [PROC_CD_19]
	, PVT.[20] AS [PROC_CD_20]
	, PVT.[21] AS [PROC_CD_21]
	, PVT.[22] AS [PROC_CD_22]
	, PVT.[23] AS [PROC_CD_23]
	, PVT.[24] AS [PROC_CD_24]
	, PVT.[25] AS [PROC_CD_25]
	, PVT.[26] AS [PROC_CD_26]
	, PVT.[27] AS [PROC_CD_27]
	, PVT.[28] AS [PROC_CD_28]
	, PVT.[29] AS [PROC_CD_29]
	, PVT.[30] AS [PROC_CD_30]


	FROM (
		SELECT pt_id
		, proc_cd
		, proc_cd_prio

		FROM smsmir.sproc

		WHERE proc_cd_type != 'C'
		AND LEFT(PT_ID, 5) = '00001'
		AND proc_cd_prio <= 30
	) AS A

	PIVOT(
		MAX(PROC_CD)
		FOR PROC_CD_PRIO IN (
			"01","02","03","04","05","06","07","08","09","10",
			"11","12","13","14","15","16","17","18","19","20",
			"21","22","23","24","25","26","27","28","29","30"
		)
	) AS PVT
) AS SPROC
ON PAV.Pt_No = SPROC.pt_id
LEFT OUTER JOIN smsdss.proc_dim_v AS P1
ON SPROC.PROC_CD_1 = P1.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P2
ON SPROC.PROC_CD_2 = P2.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P3
ON SPROC.PROC_CD_3 = P3.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P4
ON SPROC.PROC_CD_4 = P4.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P5
ON SPROC.PROC_CD_5 = P5.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P6
ON SPROC.PROC_CD_6 = P6.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P7
ON SPROC.PROC_CD_7 = P7.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P8
ON SPROC.PROC_CD_8 = P8.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P9
ON SPROC.PROC_CD_9 = P9.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P10
ON SPROC.PROC_CD_10 = P10.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P11
ON SPROC.PROC_CD_11 = P11.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P12
ON SPROC.PROC_CD_12 = P12.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P13
ON SPROC.PROC_CD_13 = P13.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P14
ON SPROC.PROC_CD_14 = P14.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P15
ON SPROC.PROC_CD_15 = P15.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P16
ON SPROC.PROC_CD_16 = P16.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P17
ON SPROC.PROC_CD_17 = P17.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P18
ON SPROC.PROC_CD_18 = P18.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P19
ON SPROC.PROC_CD_19 = P19.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P20
ON SPROC.PROC_CD_20 = P20.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P21
ON SPROC.PROC_CD_21 = P21.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P22
ON SPROC.PROC_CD_22 = P22.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P23
ON SPROC.PROC_CD_23 = P23.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P24
ON SPROC.PROC_CD_24 = P24.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P25
ON SPROC.PROC_CD_25 = P25.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P26
ON SPROC.PROC_CD_26 = P26.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P27
ON SPROC.PROC_CD_27 = P27.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P28
ON SPROC.PROC_CD_28 = P28.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P29
ON SPROC.PROC_CD_29 = P29.proc_cd
LEFT OUTER JOIN smsdss.proc_dim_v AS P30
ON SPROC.PROC_CD_30 = P30.proc_cd
LEFT OUTER JOIN (
	SELECT PVT.pt_id
	, PVT.[01] AS [DX_CD_1]
	, PVT.[02] AS [DX_CD_2]
	, PVT.[03] AS [DX_CD_3]
	, PVT.[04] AS [DX_CD_4]
	, PVT.[05] AS [DX_CD_5]
	, PVT.[06] AS [DX_CD_6]
	, PVT.[07] AS [DX_CD_7]
	, PVT.[08] AS [DX_CD_8]
	, PVT.[09] AS [DX_CD_9]
	, PVT.[10] AS [DX_CD_10]
	, PVT.[11] AS [DX_CD_11]
	, PVT.[12] AS [DX_CD_12]
	, PVT.[13] AS [DX_CD_13]
	, PVT.[14] AS [DX_CD_14]
	, PVT.[15] AS [DX_CD_15]
	, PVT.[16] AS [DX_CD_16]
	, PVT.[17] AS [DX_CD_17]
	, PVT.[18] AS [DX_CD_18]
	, PVT.[19] AS [DX_CD_19]
	, PVT.[20] AS [DX_CD_20]
	, PVT.[21] AS [DX_CD_21]
	, PVT.[22] AS [DX_CD_22]
	, PVT.[23] AS [DX_CD_23]
	, PVT.[24] AS [DX_CD_24]
	, PVT.[25] AS [DX_CD_25]
	, PVT.[26] AS [DX_CD_26]
	, PVT.[27] AS [DX_CD_27]
	, PVT.[28] AS [DX_CD_28]
	, PVT.[29] AS [DX_CD_29]
	, PVT.[30] AS [DX_CD_30]

	FROM (
		SELECT A.pt_id
		, A.dx_cd
		, A.dx_cd_prio

		FROM smsmir.dx_grp AS A
		
		WHERE LEFT(dx_cd_type, 2) = 'DF'
		AND dx_cd_prio <= 30

	) AS A

	PIVOT(
		MAX(A.DX_CD)
		FOR DX_CD_PRIO IN (
			"01","02","03","04","05","06","07","08","09","10",
			"11","12","13","14","15","16","17","18","19","20",
			"21","22","23","24","25","26","27","28","29","30"
		)
	) AS PVT
) AS DXGRP
ON PAV.PT_NO = DXGRP.pt_id
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX1
ON DXGRP.DX_CD_1 = DX1.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX2
ON DXGRP.DX_CD_2 = DX2.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX3
ON DXGRP.DX_CD_3 = DX3.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX4
ON DXGRP.DX_CD_4 = DX4.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX5
ON DXGRP.DX_CD_5 = DX5.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX6
ON DXGRP.DX_CD_6 = DX6.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX7
ON DXGRP.DX_CD_7 = DX7.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX8
ON DXGRP.DX_CD_8 = DX8.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX9
ON DXGRP.DX_CD_9 = DX9.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX10
ON DXGRP.DX_CD_10 = DX10.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX11
ON DXGRP.DX_CD_11 = DX11.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX12
ON DXGRP.DX_CD_12 = DX12.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX13
ON DXGRP.DX_CD_13 = DX13.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX14
ON DXGRP.DX_CD_14 = DX14.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX15
ON DXGRP.DX_CD_15 = DX15.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX16
ON DXGRP.DX_CD_16 = DX16.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX17
ON DXGRP.DX_CD_17 = DX17.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX18
ON DXGRP.DX_CD_18 = DX18.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX19
ON DXGRP.DX_CD_19 = DX19.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX20
ON DXGRP.DX_CD_20 = DX20.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX21
ON DXGRP.DX_CD_21 = DX21.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX22
ON DXGRP.DX_CD_22 = DX22.clasf_desc
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX23
ON DXGRP.DX_CD_23 = DX23.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX24
ON DXGRP.DX_CD_24 = DX24.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX25
ON DXGRP.DX_CD_25 = DX25.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX26
ON DXGRP.DX_CD_26 = DX26.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX27
ON DXGRP.DX_CD_27 = DX27.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX28
ON DXGRP.DX_CD_28 = DX28.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX29
ON DXGRP.DX_CD_29 = DX29.dx_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX30
ON DXGRP.DX_CD_30 = DX30.dx_cd

WHERE PAV.User_Pyr1_Cat IN (
	'AAA','EEE','ZZZ'
)
AND PAV.tot_chg_amt > 0
AND PAV.Plm_Pt_Acct_Type = 'I'
AND LEFT(PAV.PTNO_NUM, 1) != '2'
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.Dsch_Date >= '2019-01-01'
AND PAV.Dsch_Date < '2019-02-01'
--AND PAV.Pt_No = '0000'
