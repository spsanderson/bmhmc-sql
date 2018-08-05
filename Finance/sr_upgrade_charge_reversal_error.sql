--DROP TABLE #TEMPA

SELECT SO.episode_no
, SO.ord_no
, SO.ord_obj_id
, SO.ord_sts
, SO.ord_sts_prcs_dtime
, SO.svc_cd
, SO.ent_date
, ACTV.from_file_ind
, ACTV.seq_no
, OSH.signon_id
, OSH.prcs_date AS [HSF_JS_PrcsDate]
, OSH.prcs_dtime AS [HSF_JS_PrcDTime]
, ACTV.actv_cd
, ACTV.chg_tot_amt
, ACTV.actv_tot_qty
, ACTV.actv_entry_dtime

INTO #TEMPA

FROM smsmir.sr_ord AS SO
INNER JOIN smsmir.sr_ord_sts_hist AS OSH
ON SO.episode_no = OSH.episode_no
	AND SO.ord_no = OSH.ord_no
	AND SO.ord_obj_id = OSH.ord_obj_id
	AND SO.ord_sts = OSH.hist_sts
	AND SO.sts_no = OSH.hist_no
LEFT OUTER JOIN smsmir.actv AS ACTV
ON SO.episode_no = SUBSTRING(ACTV.PT_ID, 5, 8)
	AND SO.svc_cd = ACTV.actv_cd

WHERE OSH.prcs_date >= '2018-07-27'
AND SO.ord_sts = '34'
AND OSH.signon_id = 'HSF_JS'
AND OSH.prcs_date = ACTV.actv_entry_dtime
;

SELECT *
FROM #tempa
WHERE LEFT(EPISODE_NO, 1) != '1'
ORDER BY episode_no
, ord_no
, chg_tot_amt DESC