SELECT a.bill_no AS [Encounter]
, a.patient_type
, c.Atn_Dr_No
, b.cerm_rvwr_id
, b.cerm_rvw_status_desc
, b.cerm_review_type
, b.cerm_rvw_date
, c.vst_start_dtime
, datediff(hour, c.vst_start_dtime, b.cerm_rvw_date) as [hours to admit review]
, DATEPART(HOUR, C.VST_START_DTIME)

FROM [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.visit_view                   AS a
LEFT OUTER JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[CTC_UM_CERM] AS b
ON a.visit_id = b._fk_visit  
LEFT OUTER MERGE JOIN smsdss.BMH_PLM_PtAcct_V                         AS c
ON a.bill_no = c.PtNo_Num

WHERE C.Adm_Date >= '2017-02-01'
AND C.Adm_Date < '2017-03-01'
AND (
       b.cerm_review_type = 'Admission'
       or
       b.cerm_review_type is null
)
and b.cerm_rvwr_id in (
       'BH9266', 'BHA009', 'BH1453', 'BHB228'
)
AND C.tot_chg_amt > 0
AND LEFT(C.PTNO_NUM, 4) != '1999'
AND A.patient_type = 'I'
-- Only admits between 7a and 11pm
--AND DATEPART(HOUR, C.VST_START_DTIME) BETWEEN 7 AND 23

OPTION(FORCE ORDER);
