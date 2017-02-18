SELECT a.bill_no AS [Encounter]
, a.patient_type
, c.Atn_Dr_No
, b.cerm_rvwr_id
, b.cerm_rvw_status_desc
, b.cerm_review_type
, D.Appeal_Date
, D.appl_dollars_appealed
, D.s_cpm_Dollars_not_appealed	
, D.appl_dollars_recovered
, b.cerm_rvw_date
, c.vst_start_dtime
, datediff(hour, c.vst_start_dtime, b.cerm_rvw_date) as [hours to admit review]

FROM [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.visit_view                   AS a
LEFT OUTER JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[CTC_UM_CERM] AS b
ON a.visit_id = b._fk_visit  
LEFT OUTER MERGE JOIN smsdss.BMH_PLM_PtAcct_V                         AS c
ON a.bill_no = c.PtNo_Num
LEFT OUTER MERGE JOIN SMSDSS.c_Softmed_Denials_Detail_v               AS D
ON A.BILL_NO = SUBSTRING(D.bill_no, 5,8) COLLATE SQL_Latin1_General_CP1_CI_AS

WHERE C.Dsch_Date >= '2015-01-01'
AND C.Dsch_Date < '2016-01-01'
AND (
	b.cerm_review_type = 'Admission'
	or
	b.cerm_review_type is null
)
and b.cerm_rvwr_id is not null
AND C.tot_chg_amt > 0
AND LEFT(C.PTNO_NUM, 4) != '1999'
AND A.patient_type = 'I'