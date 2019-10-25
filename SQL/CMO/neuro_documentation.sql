/*
***********************************************************************
File: neuro_documentation.sql

Input Parameters:
	None

Tables/Views:
	smsmir.mir_sr_ddc_doc_vers as dv
    smsmir.mir_sr_ddc_doc as d
    smsmir.mir_sc_ddcanswer as a 
    smsmir.mir_sc_StaffIdentifiers as si
    SMSDSS.pract_dim_v AS PDV
    smsdss.BMH_PLM_PtAcct_V as pav
    [SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcConceptInstanceDef]
    [SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcDocTemplateContent]
    [SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcDocSectionDef]

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get documentation events for Neurosurgery

Revision History:
Date		Version		Description
----		----		----
2019-10-09	v1			Initial Creation
***********************************************************************
*/

SELECT d.doc_author,
	d.doc_name,
	dv.cre_dtime,
	d.doc_obj_id,
	a.SectionConceptId,
	a.LeafConceptId,
	(coalesce(a.formattedvalue, a.textvalue, CONVERT(NVARCHAR(max), a.datetimeValue, 121), cast(a.numericvalue AS NVARCHAR(max)), '') + ' ' + coalesce(a.majoruomdisplayname, a.minoruomdisplayname, '')) AS Value,
	pav.Med_Rec_No,
	d.episode_no,
	pav.pt_name,
	pav.Adm_Date,
	pav.Dsch_Date,
	A.DdcPath_OID,
	A.DdcDocTemplateContent_OID
	--, si.Value
	,
	PDV.src_pract_no,
	PDV.pract_rpt_name,
	PDV.spclty_cd,
	D.parent_doc_obj_id
INTO #TEMPA
FROM smsmir.mir_sr_ddc_doc_vers AS dv
INNER JOIN smsmir.mir_sr_ddc_doc AS d ON d.doc_obj_id = dv.doc_obj_id
INNER JOIN smsmir.mir_sc_ddcanswer AS a ON a.DdcDoc_OID = dv.doc_obj_id
INNER JOIN smsmir.mir_sc_StaffIdentifiers AS si ON d.staff_obj_id = si.Staff_oid
	AND si.[Type] = 'msi'
INNER JOIN SMSDSS.pract_dim_v AS PDV ON SI.Value = PDV.src_pract_no
	AND PDV.orgz_cd = 'S0X0'
INNER JOIN smsdss.BMH_PLM_PtAcct_V AS pav ON d.episode_no = pav.ptno_num
WHERE PDV.spclty_cd = 'NSGSG'
	AND dv.cre_dtime >= '2019-01-01';

SELECT A.*,
	cast(replace(c.conceptinstanceid, '_', '') AS BIGINT) AS [conceptinstanceid],
	C.DISPLAYNAME AS [LEAF_NAME]
INTO #TEMPB
FROM #tempa AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcConceptInstanceDef] AS C WITH (NOLOCK) ON C.DDCPATH_OID = A.DdcPath_OID
	AND A.DdcDocTemplateContent_OID = C.DDCDOCTEMPLATECONTENT_OID;

SELECT A.*,
	DSD.DISPLAYNAME AS [SECTION_NAME]
INTO #TEMPC
FROM #TEMPB AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcDocTemplateContent] AS TC WITH (NOLOCK) ON tc.DdcDocTemplateContent_OID = a.DdcDocTemplateContent_OID
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcDocSectionDef] AS DSD WITH (NOLOCK) ON dsd.ConceptId = a.SectionConceptId
	AND dsd.DdcDocTemplateDef_OID = tc.DdcDocTemplateDef_OID;

SELECT A.doc_author,
	A.src_pract_no,
	A.Med_Rec_No,
	A.episode_no,
	A.Pt_Name,
	CAST(A.Adm_Date AS DATE) AS [Adm_Date],
	CAST(A.Dsch_Date AS DATE) AS [Dsch_Date],
	A.doc_name,
	A.SECTION_NAME,
	A.cre_dtime,
	a.parent_doc_obj_id,
	a.doc_obj_id,
	DATEPART(MONTH, A.cre_dtime) AS [Create_Month],
	DATEPART(HOUR, A.cre_dtime) AS [Create_Hour],
	CASE 
		WHEN DATEPART(HOUR, A.cre_dtime) >= 7
			AND DATEPART(HOUR, A.cre_dtime) < 19
			THEN 0
		ELSE 1
		END AS [Overnight_Flag],
	[Doc_Num] = ROW_NUMBER() OVER (
		PARTITION BY A.DOC_OBJ_ID ORDER BY A.DOC_OBJ_ID,
			A.CRE_DTIME
		),
	[Doc_Event] = ROW_NUMBER() OVER (
		PARTITION BY A.DOC_OBJ_ID,
		A.CRE_DTIME ORDER BY A.DOC_OBJ_ID,
			A.CRE_DTIME
		)
INTO #TEMPD
FROM #TEMPC AS A
ORDER BY A.doc_author,
	A.Adm_Date,
	A.cre_dtime,
	A.doc_name,
	A.conceptinstanceid;

SELECT *
FROM #TEMPD
WHERE DOC_EVENT = 1;

DROP TABLE #TEMPA

DROP TABLE #TEMPB

DROP TABLE #TEMPC

DROP TABLE #TEMPD
