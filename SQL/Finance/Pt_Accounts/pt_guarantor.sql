SELECT a.pt_id,
	a.acct_hist_cmnt,
	a.cmnt_cre_dtime,
	CASE 
		WHEN LEFT(a.acct_hist_cmnt, 12) = 'pt name addr'
			THEN 'pt_name_addr'
		WHEN LEFT(a.acct_hist_cmnt, 14) = 'guar name addr'
			THEN 'guar_name_addr'
		END AS [pt_guar_flag]
INTO #test
FROM smsmir.acct_hist AS a
--where a.pt_id = ''
WHERE (
		LEFT(a.acct_hist_cmnt, 12) = 'pt name addr'
		OR LEFT(a.acct_hist_cmnt, 14) = 'guar name addr'
		)
	AND substring(pt_id, 5, 8) IN (
		SELECT DISTINCT (pt_id)
		FROM smsmir.hl7_vst AS vst
		WHERE vst.adm_date >= '2018-10-01'
			AND vst.adm_date < '2018-11-01'
		);

SELECT a.pt_id,
	a.acct_hist_cmnt,
	a.pt_guar_flag,
	a.cmnt_cre_dtime,
	rn = ROW_NUMBER() OVER (
		PARTITION BY pt_id,
		pt_guar_flag ORDER BY pt_id,
			cmnt_cre_dtime
		)
INTO #test2
FROM #test AS a;

SELECT DISTINCT (A.pt_id)
INTO #test3
FROM #test2 AS a
LEFT OUTER JOIN #test2 AS b ON a.pt_id = b.pt_id
	AND a.rn = b.rn + 1
	AND DATEDIFF(hour, a.cmnt_cre_dtime, b.cmnt_cre_dtime) > = 24
WHERE a.rn > 1;

SELECT DISTINCT (a.pt_id),
	b.UserDataText
FROM #test3 AS a
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V AS b ON a.pt_id = b.PtNo_Num
INNER JOIN smsdss.BMH_UserTwoField_Dim_V AS c ON b.UserDataKey = c.UserTwoKey
	AND c.UserDataCd IN ('2INADMBY', '2ERFRGBY', '2ERREGBY', '2OPPREBY', '2OPREGBY');

DROP TABLE #test,
	#test2,
	#test3;
