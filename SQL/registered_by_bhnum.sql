SELECT DISTINCT(A.PTNO_NUM)
, A.UserDataText
, b.UserDataText
FROM smsdss.BMH_UserTwoFact_V AS A
INNER join smsdss.BMH_UserTwoField_Dim_V as B
ON A.UserDataKey = B.UserTwoKey
	AND B.UserDataCd IN (
		'2INADMBY'
		, '2ERFRGBY'
		, '2ERREGBY'
		, '2OPPREBY'
		, '2OPREGBY'
	)

;