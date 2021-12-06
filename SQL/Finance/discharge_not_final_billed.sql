/*
***********************************************************************
File: discharge_not_final_billed.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_pa_coded_unbilled_rpt_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get account listing of those that are discharged and unbilled

Revision History:
Date		Version		Description
----		----		----
2021-12-02	v1			Initial Creation
***********************************************************************
*/

SELECT [ip_op_flag] = CASE 
		WHEN left(pt_id, 5) = '00001'
			THEN 'inpatient'
		ELSE 'outpatient'
		END,
	*
FROM [smsdss].[c_pa_coded_unbilled_rpt_v]
WHERE (
		left(pt_id, 5) != '00001'
		OR (
			left(pt_id, 5) = '00001'
			AND dsch_dtime IS NOT NULL
			)
		)
