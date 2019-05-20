--SELECT distinct(A.pt_id)
--, nurs_sta
SELECT A.nurs_sta
, COUNT(DISTINCT(a.pt_id)) AS pt_count

FROM smsdss.dly_cen_occ_fct_v AS A

WHERE A.nurs_sta IN (
	'MICU','SICU','CCU'
)
AND A.pt_id IN (
	SELECT XXX.PT_NO
	FROM smsdss.BMH_PLM_PtAcct_V AS XXX
	WHERE XXX.Adm_Date >= '2017-01-01'
	AND XXX.Adm_Date < '2018-01-01'
	AND XXX.tot_chg_amt > 0
	AND LEFT(XXX.PtNo_Num, 1) != '2'
	AND LEFT(XXX.PTNO_NUM, 4) != '1999'
)

GROUP BY A.nurs_sta

GO
;