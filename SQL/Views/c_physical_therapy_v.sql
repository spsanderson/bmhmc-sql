/*
***********************************************************************
File: c_physical_therapy_v.sql

Input Parameters:
	None

Tables/Views:
	smsmir.mir_sr_ord
    smsmir.mir_sr_vst_pms
    smsmir.mir_sc_Assessment

Creates Table:
	smsdss.c_physical_therapy_v

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get all physical therapy orders where the form collection date
    is greater than the order date. The forms used in this are:
    1. Physical Therapy Initial Asmt
    2. Physical Therapy Re-evaluation
    3. PT Flowsheet

Revision History:
Date		Version		Description
----		----		----
2021-12-07	v1			Initial Creation
2021-12-13	v2			Add AssessmentStatus = 'COMPLETE'
***********************************************************************
*/

USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW smsdss.c_physical_therapy_v
AS
SELECT a.[episode_no],
	[ord_no],
	[pty_name] AS 'Ordering Provider',
	[ent_dtime] AS 'Order Entered',
	CollectedDT,
	[str_dtime],
	last_cng_dtime,
	vst_start_dtime AS 'Admit Dt',
	[vst_end_dtime] AS 'Discharge Dt',
	[ord_qty],
	CASE 
		WHEN [ord_sts] = 27
			THEN 'Complete'
		WHEN ord_sts = 34
			THEN 'Discontinued'
		ELSE ord_sts
		END AS 'Order Status',
	[desc_as_written],
	[FormUsage] AS 'Assessment',
	[AssessmentID],
	datediff(minute, ent_dtime, collecteddt) AS [order_entry_to_collected_minutes],
	datediff(hour, ent_dtime, collecteddt) AS [order_entry_to_collected_hours]
FROM [SMSPHDSSS0X0].[smsmir].[mir_sr_ord] AS a
LEFT OUTER JOIN [smsmir].[mir_sr_vst_pms] AS b ON b.episode_no = a.episode_no
LEFT OUTER JOIN [smsmir].[mir_sc_Assessment] AS C ON c.PatientVisit_oid = b.vst_no
WHERE (desc_as_written LIKE 'physical Therapy%')
	AND (
		c.FormUsage IN ('Physical Therapy Initial Asmt', 'Physical Therapy Re-evaluation', 'PT Flowsheet')
		AND c.CollectedDT > a.ent_dtime -- make this like transfusion query on platelets and hg
		)
	AND a.ord_sts = 27
	AND c.AssessmentStatus = 'Complete'
