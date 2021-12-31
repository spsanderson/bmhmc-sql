/*
***********************************************************************
File: c_consults_v.sql

Input Parameters:
	None

Tables/Views:
	None

Creates Table:
	smsdss.c_performed_consults_v

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Create a view for consults done in pdoc

Revision History:
Date		Version		Description
----		----		----
2021-12-06	v1			Initial Creation
***********************************************************************
*/

USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [smsdss].[c_performed_consults_v]
AS
SELECT a.[episode_no],
	b.Pt_Name,
	[doc_author],
	[doc_name],
	a.doc_obj_id,
	c.doc_sts,
	'PDoc' AS [consult_type],
	c.coll_dtime AS [start_dtime],
	c.sign_dtime AS [signed_dtime]
FROM [SMSPHDSSS0X0].[smsmir].[ddc_doc] AS a
JOIN smsdss.BMH_PLM_PtAcct_V b ON episode_no = PtNo_Num
LEFT OUTER JOIN [smsmir].[ddc_doc_vers] AS c ON a.doc_obj_id = c.doc_obj_id
WHERE (doc_name LIKE '%consult%')
	AND doc_sts = 'FINAL'
	AND parent_doc_obj_id IS NULL -- ELIMINATES ADDENDUMS
	--order by a.cre_date

UNION ALL

SELECT b.PatientAccountID AS [episode_no],
	c.rpt_name,
	a.ResultValue AS [doc_author],
	a.FindingAbbreviation AS [doc_name],
	NULL AS [doc_obj_id],
	'FINAL' AS [doc_sts],
	'Manual' AS [consult_type],
	NULL AS [start_dtime],
	a.ResultDateTime AS [signed_dtime]
FROM smsmir.sc_InvestigationResult AS a -- lnk back to sc_PatientVisit
LEFT OUTER JOIN smsmir.sc_PatientVisit AS b ON a.PatientVisit_oid = b.ObjectID
	AND a.Patient_oid = b.Patient_oid
LEFT OUTER JOIN smsmir.pt AS c ON cast(b.PatientAccountID AS INT) = cast(substring(c.pt_id, 5, 8) AS INT)
WHERE FindingAbbreviation = 'mq_consult'
	AND b.PatientAccountID IS NOT NULL
