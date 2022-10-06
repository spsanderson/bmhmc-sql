SELECT a.PtNo_Num
, b.UserDataText
FROM smsdss.BMH_PLM_PtAcct_V as a
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V as b
ON a.PtNo_Num = b.PtNo_Num
INNER join smsdss.BMH_UserTwoField_Dim_V as c
ON b.UserDataKey = c.UserTwoKey
AND c.UserDataCd IN (
	'2INADMBY'
	, '2ERFRGBY'
	, '2ERREGBY'
	, '2OPPREBY'
	, '2OPREGBY'
)
WHERE tot_chg_amt > 0
AND LEFT(A.PtNo_Num, 1) != '2'
AND LEFT(A.PtNo_Num, 4) != '1999'
AND Adm_Date >= '2018-10-01'
AND Adm_Date < '2018-11-01'