/*
***********************************************************************
File: IP_Providers_Per_Pt.sql

Input Parameters:
	None

Tables/Views:
	smsmir.sproc
    smsdss.BMH_PLM_PtAcct_V
	smsdss.c_patient_demos_v
	smsdss.pyr_dim_v
	smsdss.dx_cd_dim_v
	smsmir.hl7_pt
	smsdss.proc_dim_v
	smsdss.pract_dim_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get a list of all providers on a case that are not the attending or admitting.
	This will work for coded patients.

Revision History:
Date		Version		Description
----		----		----
2018-11-13	v1			Initial Creation
***********************************************************************
*/

SELECT PLM.Med_Rec_No
, PLM.Pt_No
, CAST(PLM.ADM_DATE AS DATE) AS [ADM_DATE]
, CAST(PLM.Dsch_Date AS date) AS [DSCH_DATE]
, PLM.prin_dx_cd
, DX_CD.alt_clasf_desc
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
  END AS [PCP_NAME]
, PYR.pyr_group2
, SPROC.proc_cd
, CASE
	WHEN SPROC.proc_cd = 'CONSULT'
		THEN 'CONSULT'
		ELSE PRDV.alt_clasf_desc
  END AS [Proc_Name]
, SPROC.resp_pty_cd              AS [Resp_Provider_ID]
, UPPER(PROC_PTY.pract_rpt_name) AS [Resp_Provider_Name]
, [CONSULT_FLAG] = CASE WHEN SPROC.proc_cd = 'CONSULT' THEN 1 ELSE 0 END
, [PROCEDURE_FLAG] = CASE WHEN SPROC.PROC_CD != 'CONSULT' THEN 1 ELSE 0 END
, [RN] = ROW_NUMBER() OVER(
	PARTITION BY SPROC.PT_ID
	, SPROC.RESP_PTY_CD
	ORDER BY SPROC.PT_ID
	, SPROC.RESP_PTY_CD
)

INTO #TEMP_A

FROM smsmir.sproc AS SPROC
INNER JOIN smsdss.BMH_PLM_PtAcct_V AS PLM
ON SPROC.pt_id = PLM.Pt_No
	AND SPROC.orgz_cd = PLM.Regn_Hosp
	AND SPROC.unit_seq_no = PLM.unit_seq_no
	AND SPROC.from_file_ind = PLM.from_file_ind
LEFT OUTER JOIN smsdss.c_patient_demos_v AS PT_DEMOS
ON SPROC.pt_id = PT_DEMOS.pt_id
	AND SPROC.from_file_ind = PT_DEMOS.from_file_ind
LEFT OUTER JOIN smsdss.pyr_dim_v AS PYR
ON PLM.Pyr1_Co_Plan_Cd = PYR.pyr_cd
	AND PLM.Regn_Hosp = PYR.orgz_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DX_CD
ON PLM.prin_dx_cd = DX_CD.dx_cd
	AND PLM.prin_dx_cd_schm = DX_CD.dx_cd_schm
LEFT OUTER JOIN smsmir.hl7_pt AS HL7
ON SUBSTRING(SPROC.pt_id, 5, 8) = HL7.pt_id
LEFT OUTER JOIN smsdss.proc_dim_v AS PRDV
ON SPROC.proc_cd = PRDV.proc_cd
LEFT OUTER JOIN smsdss.pract_dim_v AS PROC_PTY
ON SPROC.resp_pty_cd = PROC_PTY.src_pract_no
	AND SPROC.orgz_cd = PROC_PTY.orgz_cd
OUTER APPLY (
	SELECT TOP 1 ZZZ.src_pract_no
	, ZZZ.pract_rpt_name
	FROM smsdss.pract_dim_v AS ZZZ
	WHERE LEFT(HL7.PRIM_CARE_PROV_NAME_ID, 6) = ZZZ.SRC_PRACT_NO
	ORDER BY ZZZ.orgz_cd
)  AS MD

WHERE SPROC.pt_id = '000014676084'
;

SELECT A.Med_Rec_No
, A.Pt_No
, A.ADM_DATE
, A.DSCH_DATE
, A.prin_dx_cd
, A.alt_clasf_desc AS [DX_NAME]
, A.Pt_Name
, A.Pt_DOB
, A.Pt_Gender
, A.Pt_Marital_Sts
, A.addr_line1
, A.Pt_Addr_Line2
, A.Pt_Addr_City
, A.Pt_Addr_State
, A.Pt_Addr_Zip
, A.Pt_Phone_No
, A.PCP_ID
, A.PCP_NAME
, A.pyr_group2 AS [Fin_Class]
, A.proc_cd
, A.Proc_Name
, A.Resp_Provider_ID
, A.Resp_Provider_Name
, A.CONSULT_FLAG
, A.[PROCEDURE_FLAG]

FROM #TEMP_A AS A
WHERE RN = 1
ORDER BY A.Pt_No
, [CONSULT_FLAG] DESC
;

DROP TABLE #TEMP_A
; 

--WHERE PLM.Dsch_Date >= DATEADD(DAY, DATEDIFF(DAY, 0, CAST(GETDATE() AS date)) - 14, 0)
--AND PLM.Dsch_Date IS NOT NULL