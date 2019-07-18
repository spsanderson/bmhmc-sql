SELECT d.doc_author
, d.doc_name
, dv.cre_dtime
, d.doc_obj_id
, a.SectionConceptId
, a.LeafConceptId
, (
       coalesce(
              a.formattedvalue
              , a.textvalue
              , CONVERT(nvarchar(max), a.datetimeValue, 121)
              , cast(a.numericvalue as nvarchar(max)),''
              ) + ' ' 
                + coalesce(a.majoruomdisplayname, a.minoruomdisplayname, '')
       ) as Value
, pav.Med_Rec_No
, d.episode_no
, pav.pt_name
, pav.Adm_Date
, pav.Dsch_Date
, A.DdcPath_OID
, A.DdcDocTemplateContent_OID

INTO #TEMPA

FROM smsmir.mir_sr_ddc_doc_vers as dv
INNER JOIN smsmir.mir_sr_ddc_doc as d
ON d.doc_obj_id=dv.doc_obj_id 
INNER JOIN smsmir.mir_sc_ddcanswer as a 
ON a.DdcDoc_OID=dv.doc_obj_id
INNER JOIN smsdss.BMH_PLM_PtAcct_V as pav
on d.episode_no = pav.ptno_num

WHERE A.DdcDoc_OID IN (
       SELECT DOC_ID
       FROM smsdss.purged_documents_doc_oid_list
)
;

SELECT A.*
, cast(replace(c.conceptinstanceid, '_', '') as bigint) as [conceptinstanceid]
, C.DISPLAYNAME AS [LEAF_NAME]

INTO #TEMPB

FROM #tempa AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcConceptInstanceDef] AS C WITH(NOLOCK)
ON C.DDCPATH_OID = A.DdcPath_OID
       AND A.DdcDocTemplateContent_OID = C.DDCDOCTEMPLATECONTENT_OID
;

SELECT A.*
, DSD.DISPLAYNAME AS [SECTION_NAME]

INTO #TEMPC

FROM #TEMPB AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcDocTemplateContent] AS TC WITH(NOLOCK)
ON tc.DdcDocTemplateContent_OID = a.DdcDocTemplateContent_OID 
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcDocSectionDef] AS DSD WITH(NOLOCK)
ON dsd.ConceptId = a.SectionConceptId 
       AND dsd.DdcDocTemplateDef_OID = tc.DdcDocTemplateDef_OID
;

SELECT A.*

INTO smsdss.purged_pdoc_rundate_06072019

FROM #TEMPC AS A

ORDER BY A.doc_author
, A.episode_no
, A.cre_dtime DESC
, A.doc_name
, A.conceptinstanceid
;

DROP TABLE #TEMPA
DROP TABLE #TEMPB
DROP TABLE #TEMPC