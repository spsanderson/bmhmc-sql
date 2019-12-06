/*
***********************************************************************
File: oppe_cpoe.sql

Input Parameters:
	None

Tables/Views:
	SMSDSS.c_CPOE_Rpt_Tbl_Rollup_v AS A
	SMSDSS.pract_dim_v             AS PDV

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get CPOE orders for OPPE report

Revision History:
Date		Version		Description
----		----		----
2018-07-13	v1			Initial Creation
***********************************************************************
*/

SELECT A.req_pty_cd
, PDV.pract_rpt_name
, A.Hospitalist_Np_Pa_Flag
, A.Ord_Type_Abbr
, A.Unknown
, A.Telephone
, A.[Per RT Protocol]
, A.Communication
, A.[Specimen Collect]
, A.[Specimen Redraw]
, A.CPOE
, A.[Nursing Order]
, A.Written
, A.[Verbal Order]
, A.ent_date

FROM SMSDSS.c_CPOE_Rpt_Tbl_Rollup_v AS A
INNER JOIN SMSDSS.pract_dim_v AS PDV
ON A.req_pty_cd = PDV.src_pract_no
	AND PDV.orgz_cd = 'S0X0'
WHERE req_pty_cd IN (

)