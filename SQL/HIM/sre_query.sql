/*
***********************************************************************
File: sre_query.sql

Input Parameters:
	None

Tables/Views:
	FROM SMSMIR.dx_grp AS A
    SMSDSS.dx_cd_dim_v AS B
    SMSDSS.BMH_PLM_PTACCT_V AS C

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Entere Here

Revision History:
Date		Version		Description
----		----		----
2018-06-12	v1			Initial Creation
2018-06-13	v2			Change to UNION ALL for different SRE categories
***********************************************************************
*/

SELECT A.pt_id
, A.dx_cd
, A.dx_cd_type
, A.dx_cd_prio
, B.alt_clasf_desc
, CAST(C.Adm_Date AS DATE) AS [ADM_DATE]
, CAST(C.Dsch_Date AS DATE) AS [DSCH_DATE]
, CASE
	WHEN LEFT(C.dsch_disp, 1) IN ('C','D')
		THEN 'Expired'
		ELSE 'Alive'
  END AS [Disposition_Status]
, 'Surgical_Events' AS [SRE_Type]

FROM SMSMIR.dx_grp AS A
LEFT OUTER JOIN SMSDSS.dx_cd_dim_v AS B
ON A.DX_CD = B.dx_cd
INNER JOIN SMSDSS.BMH_PLM_PTACCT_V AS C
ON A.PT_ID = C.Pt_No
	AND A.unit_seq_no = C.unit_seq_no
	AND A.from_file_ind = C.from_file_ind
	AND A.orgz_cd = C.Regn_Hosp

WHERE(
	-- SURGICAL EVENTS
	A.dx_cd IN (
		'Y65.53','Y65.52','Y65.51'
	)
	OR A.dx_cd IN (
		'Y70.3','Y71.3','Y72.3','Y73.3','Y74.3',
		'Y75.3','Y76.3','Y77.3','Y78.3','Y79.3',
		'Y80.3','Y81.3'
	)
	OR (
		A.DX_CD BETWEEN 'Y70.0' AND 'Y70.8'
		AND LEFT(C.DSCH_DISP, 2) IN ('C', 'D')
		AND SUBSTRING(C.DSCH_DISP,2,1) IN ('2','3','4','5','6')
		AND RIGHT(C.DSCH_DISP, 1) IN ('A','N')
	)
)
AND A.DX_CD_TYPE = 'DFN'
AND DATEPART(YEAR, C.DSCH_DATE) = 2018

UNION ALL

SELECT A.pt_id
, A.dx_cd
, A.dx_cd_type
, A.dx_cd_prio
, B.alt_clasf_desc
, CAST(C.Adm_Date AS DATE) AS [ADM_DATE]
, CAST(C.Dsch_Date AS DATE) AS [DSCH_DATE]
, CASE
	WHEN LEFT(C.dsch_disp, 1) IN ('C','D')
		THEN 'Expired'
		ELSE 'Alive'
  END AS [Disposition_Status]
, 'Product_or_Device_Events' AS [SRE_Type]

FROM SMSMIR.dx_grp AS A
LEFT OUTER JOIN SMSDSS.dx_cd_dim_v AS B
ON A.DX_CD = B.dx_cd
INNER JOIN SMSDSS.BMH_PLM_PTACCT_V AS C
ON A.PT_ID = C.Pt_No
	AND A.unit_seq_no = C.unit_seq_no
	AND A.from_file_ind = C.from_file_ind
	AND A.orgz_cd = C.Regn_Hosp

WHERE(
	-- PRODUCT OR DEVICE EVENTS
	A.DX_CD BETWEEN 'Y62.0' AND 'Y62.9'
	OR A.DX_CD BETWEEN 'Y64.0' AND 'Y64.9'
	OR A.dx_cd IN ('Y65.8')
	OR A.DX_CD BETWEEN 'Y70' AND 'Y82'
	OR (
		A.DX_CD = 'T80.0XXA'
		AND A.dx_cd_type = 'DFN'
	)
)
AND A.DX_CD_TYPE = 'DFN'
AND DATEPART(YEAR, C.DSCH_DATE) = 2018

UNION ALL

SELECT A.pt_id
, A.dx_cd
, A.dx_cd_type
, A.dx_cd_prio
, B.alt_clasf_desc
, CAST(C.Adm_Date AS DATE) AS [ADM_DATE]
, CAST(C.Dsch_Date AS DATE) AS [DSCH_DATE]
, CASE
	WHEN LEFT(C.dsch_disp, 1) IN ('C','D')
		THEN 'Expired'
		ELSE 'Alive'
  END AS [Disposition_Status]
, 'Patient_Protection_Events' AS [SRE_Type]

FROM SMSMIR.dx_grp AS A
LEFT OUTER JOIN SMSDSS.dx_cd_dim_v AS B
ON A.DX_CD = B.dx_cd
INNER JOIN SMSDSS.BMH_PLM_PTACCT_V AS C
ON A.PT_ID = C.Pt_No
	AND A.unit_seq_no = C.unit_seq_no
	AND A.from_file_ind = C.from_file_ind
	AND A.orgz_cd = C.Regn_Hosp

WHERE(
	-- PATIENT PROTECTION EVENTS
	A.dx_cd IN ('R41.9')
	OR (
			A.DX_CD = 'R45.851'
			AND A.dx_cd_type = 'DFN'
		)
)
AND A.DX_CD_TYPE = 'DFN'
AND DATEPART(YEAR, C.DSCH_DATE) = 2018

UNION ALL

SELECT A.pt_id
, A.dx_cd
, A.dx_cd_type
, A.dx_cd_prio
, B.alt_clasf_desc
, CAST(C.Adm_Date AS DATE) AS [ADM_DATE]
, CAST(C.Dsch_Date AS DATE) AS [DSCH_DATE]
, CASE
	WHEN LEFT(C.dsch_disp, 1) IN ('C','D')
		THEN 'Expired'
		ELSE 'Alive'
  END AS [Disposition_Status]
, 'Care_Management_Events' AS [SRE_Type]

FROM SMSMIR.dx_grp AS A
LEFT OUTER JOIN SMSDSS.dx_cd_dim_v AS B
ON A.DX_CD = B.dx_cd
INNER JOIN SMSDSS.BMH_PLM_PTACCT_V AS C
ON A.PT_ID = C.Pt_No
	AND A.unit_seq_no = C.unit_seq_no
	AND A.from_file_ind = C.from_file_ind
	AND A.orgz_cd = C.Regn_Hosp

WHERE(
	-- CARE MANAGEMENT EVENTS
	A.DX_CD BETWEEN 'Y63.0' AND 'Y63.9'
	OR A.DX_CD IN ('Y62.1')
	OR A.DX_CD BETWEEN 'Y63.0' AND 'Y65.1'
	OR (
		A.DX_CD BETWEEN '075.0' AND '075.4'
		AND LEFT(C.DSCH_DISP, 2) IN ('D4','D5','D6','D7','DA','DC','DN')
	)
	OR (
		LEFT(A.DX_CD, 3) IN ('W05','W06','W07','W08')
		AND A.PT_ID IN (
			SELECT ZZZ.PT_ID
			FROM SMSMIR.dx_grp AS ZZZ
			WHERE ZZZ.dx_cd = 'Y92.10'
			OR ZZZ.dx_cd LIKE 'Y92.12%'
			OR ZZZ.DX_CD LIKE 'Y92.23%'
		)
	)
	OR (
		LEFT(A.DX_CD, 4) IN ('W10.2','W10.9')
		AND A.PT_ID IN (
			SELECT ZZZ.PT_ID
			FROM SMSMIR.dx_grp AS ZZZ
			WHERE ZZZ.dx_cd = 'Y92.10'
			OR ZZZ.dx_cd LIKE 'Y92.12%'
			OR ZZZ.DX_CD LIKE 'Y92.23%'
		)
	)
	OR (
		LEFT(A.DX_CD, 6) IN ('W18.30','W17.89')
		AND A.PT_ID IN (
			SELECT ZZZ.PT_ID
			FROM SMSMIR.dx_grp AS ZZZ
			WHERE ZZZ.dx_cd = 'Y92.10'
			OR ZZZ.dx_cd LIKE 'Y92.12%'
			OR ZZZ.DX_CD LIKE 'Y92.23%'
		)
	)
	OR (
		A.DX_CD BETWEEN 'L89.023' AND 'L89.95'
		AND A.dx_cd_type = 'DFN'
	)
)
AND A.DX_CD_TYPE = 'DFN'
AND DATEPART(YEAR, C.DSCH_DATE) = 2018

UNION ALL

SELECT A.pt_id
, A.dx_cd
, A.dx_cd_type
, A.dx_cd_prio
, B.alt_clasf_desc
, CAST(C.Adm_Date AS DATE) AS [ADM_DATE]
, CAST(C.Dsch_Date AS DATE) AS [DSCH_DATE]
, CASE
	WHEN LEFT(C.dsch_disp, 1) IN ('C','D')
		THEN 'Expired'
		ELSE 'Alive'
  END AS [Disposition_Status]
, 'Environmental_Events' AS [SRE_Type]

FROM SMSMIR.dx_grp AS A
LEFT OUTER JOIN SMSDSS.dx_cd_dim_v AS B
ON A.DX_CD = B.dx_cd
INNER JOIN SMSDSS.BMH_PLM_PTACCT_V AS C
ON A.PT_ID = C.Pt_No
	AND A.unit_seq_no = C.unit_seq_no
	AND A.from_file_ind = C.from_file_ind
	AND A.orgz_cd = C.Regn_Hosp

WHERE(
	-- Environmental Events
	(
		LEFT(A.DX_CD, 7) = 'T75.4XX'
		AND RIGHT(A.DX_CD, 1) IN ('A','D','S')
		AND LEFT(C.dsch_disp, 1) IN ('C','D')
		AND A.PT_ID IN (
			SELECT ZZZ.PT_ID
			FROM SMSMIR.dx_grp AS ZZZ
			WHERE ZZZ.dx_cd = 'Y92.10'
			OR ZZZ.dx_cd LIKE 'Y92.12%'
			OR ZZZ.DX_CD LIKE 'Y92.23%'
		)
	)
	OR A.DX_CD IN (
		'Y64.8','Y64.9','Y65.8','Y69'
	)
	OR A.DX_CD LIKE 'Y80%'
	OR (
		A.DX_CD BETWEEN 'X04%' AND 'X19%'
		AND A.PT_ID IN (
			SELECT ZZZ.PT_ID
			FROM SMSMIR.dx_grp AS ZZZ
			WHERE ZZZ.dx_cd = 'Y92.10'
			OR ZZZ.dx_cd LIKE 'Y92.12%'
			OR ZZZ.DX_CD LIKE 'Y92.23%'
		)
	)
	OR (
		A.dx_cd = 'Z78.1'
		AND A.dx_cd_type = 'DF'
		AND A.pt_id IN (
			SELECT ZZZ.pt_id
			FROM smsmir.dx_grp AS ZZZ
			WHERE ZZZ.DX_CD = 'X58'
		)
	)
)
AND A.DX_CD_TYPE = 'DFN'
AND DATEPART(YEAR, C.DSCH_DATE) = 2018

UNION ALL

SELECT A.pt_id
, A.dx_cd
, A.dx_cd_type
, A.dx_cd_prio
, B.alt_clasf_desc
, CAST(C.Adm_Date AS DATE) AS [ADM_DATE]
, CAST(C.Dsch_Date AS DATE) AS [DSCH_DATE]
, CASE
	WHEN LEFT(C.dsch_disp, 1) IN ('C','D')
		THEN 'Expired'
		ELSE 'Alive'
  END AS [Disposition_Status]
, 'Radiologic_Events' AS [SRE_Type]

FROM SMSMIR.dx_grp AS A
LEFT OUTER JOIN SMSDSS.dx_cd_dim_v AS B
ON A.DX_CD = B.dx_cd
INNER JOIN SMSDSS.BMH_PLM_PTACCT_V AS C
ON A.PT_ID = C.Pt_No
	AND A.unit_seq_no = C.unit_seq_no
	AND A.from_file_ind = C.from_file_ind
	AND A.orgz_cd = C.Regn_Hosp

WHERE(
	-- RADIOLOGICAL EVENTS
	A.DX_CD IN (
		'Y78.0','Y78.8','784.2'
	)
)
AND A.DX_CD_TYPE = 'DFN'
AND DATEPART(YEAR, C.DSCH_DATE) = 2018

UNION ALL

SELECT A.pt_id
, A.dx_cd
, A.dx_cd_type
, A.dx_cd_prio
, B.alt_clasf_desc
, CAST(C.Adm_Date AS DATE) AS [ADM_DATE]
, CAST(C.Dsch_Date AS DATE) AS [DSCH_DATE]
, CASE
	WHEN LEFT(C.dsch_disp, 1) IN ('C','D')
		THEN 'Expired'
		ELSE 'Alive'
  END AS [Disposition_Status]
, 'Criminal_Events' AS [SRE_Type]

FROM SMSMIR.dx_grp AS A
LEFT OUTER JOIN SMSDSS.dx_cd_dim_v AS B
ON A.DX_CD = B.dx_cd
INNER JOIN SMSDSS.BMH_PLM_PTACCT_V AS C
ON A.PT_ID = C.Pt_No
	AND A.unit_seq_no = C.unit_seq_no
	AND A.from_file_ind = C.from_file_ind
	AND A.orgz_cd = C.Regn_Hosp

WHERE(
	-- CRIMINAL EVENTS
	(
		A.DX_CD IN (
			'T74.21','T74.22'
		)
		AND A.PT_ID IN (
			SELECT ZZZ.PT_ID
			FROM SMSMIR.dx_grp AS ZZZ
			WHERE ZZZ.dx_cd = 'Y92.10'
			OR ZZZ.dx_cd LIKE 'Y92.12%'
			OR ZZZ.DX_CD LIKE 'Y92.23%'
		)
	)
	OR (
		LEFT(A.dx_cd, 5) BETWEEN 'Y04.0' AND 'Y04.8'
		AND A.PT_ID IN (
			SELECT ZZZ.PT_ID
			FROM SMSMIR.dx_grp AS ZZZ
			WHERE ZZZ.dx_cd = 'Y92.10'
			OR ZZZ.dx_cd LIKE 'Y92.12%'
			OR ZZZ.DX_CD LIKE 'Y92.23%'
		)
	)
	OR (
		LEFT(A.DX_CD, 6) = 'Y07.52'
		AND A.PT_ID IN (
			SELECT ZZZ.PT_ID
			FROM SMSMIR.dx_grp AS ZZZ
			WHERE ZZZ.dx_cd = 'Y92.10'
			OR ZZZ.dx_cd LIKE 'Y92.12%'
			OR ZZZ.DX_CD LIKE 'Y92.23%'
		)
	)
)
AND A.DX_CD_TYPE = 'DFN'
AND DATEPART(YEAR, C.DSCH_DATE) = 2018