/*
***********************************************************************
File: woundcare_in_fms_not_in_daily_batch.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_wound_care_daily_batch
	smsdss.BMH_PLM_PtAcct_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Find accounts that are registered/in FMS under WCC/WCH but are not
	in the smsdss.c_wound_care_daily_batch table

Revision History:
Date		Version		Description
----		----		----
2018-11-16	v1			Initial Creation
2018-11-16	v2			Add hosp_svc column
2018-11-26	v3			Add from_file_ind != '0H'
2018-11-30	v4			Fix age bucket to prevent auto-format in excel
2018-12-24	v5			Add A.prin_dx_cd IS NULL
2019-01-21	v6			Add Location to ORDER BY
2019-09-10	v7			Swap Location and Primary_Ins_Cd columns
***********************************************************************
*/

SELECT A.PtNo_Num             AS [Encounter]
, A.Pt_Name                   AS [Pt_Name]
, UPPER(B.pract_rpt_name)     AS [Attending_Provider]
, A.Med_Rec_No                AS [Med Rec No]
, CAST(A.Adm_Date AS date)    AS [Visit Date]
, DATEDIFF(DAY
	, A.Adm_Date
	, CAST(GETDATE() AS date)
	)                         AS [Days]
, [Age] = CASE
	WHEN DATEDIFF(DAY, A.Adm_Date, CAST(GETDATE() AS date)) > 90
		THEN '> 90'
	WHEN DATEDIFF(DAY, A.Adm_Date, CAST(GETDATE() AS date)) BETWEEN 61 AND 90
		THEN '61 to 90'
	WHEN DATEDIFF(DAY, A.Adm_Date, CAST(GETDATE() AS date)) BETWEEN 31 AND 60
		THEN '31 to 60'
	WHEN DATEDIFF(DAY, A.Adm_Date, CAST(GETDATE() AS date)) BETWEEN 7 AND 30
		THEN '7 to 30'
		ELSE '< 7'
  END
, A.hosp_svc                  AS [Location]
, A.Pyr1_Co_Plan_Cd           AS [Primary_Ins_Cd]

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsdss.pract_dim_v AS B
ON A.Atn_Dr_No = B.src_pract_no
	AND A.Regn_Hosp = B.orgz_cd

WHERE A.PtNo_Num NOT IN (
	SELECT ZZZ.[Account Number]
	from smsdss.c_wound_care_daily_batch AS ZZZ
)
AND A.hosp_svc IN ('WCC', 'WCH')
AND A.Adm_Date >= '2018-07-01'
AND A.from_file_ind != '0H'
AND A.prin_dx_cd IS NULL

ORDER BY Location, DATEDIFF(DAY, A.Adm_Date, CAST(GETDATE() AS date)) DESC
;