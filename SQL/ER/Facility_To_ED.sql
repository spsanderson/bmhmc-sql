SELECT A.MR#
, A.Account
, A.Patient
, A.AgeDOB
, A.Arrival
, C.Dsch_Date
, C.Days_Stay
, B.UserDataText AS [Facility Line 1]
, D.UserDataText AS [Facility Line 2]
, E.UserDataText AS [Facility Line 3]

FROM smsdss.c_Wellsoft_Rpt_tbl           AS A
LEFT MERGE JOIN SMSDSS.BMH_UserTwoFact_V AS B
ON A.Account = B.PtNo_Num
	AND B.UserDataKey = 25
LEFT MERGE JOIN SMSDSS.BMH_UserTwoFact_V AS D
ON B.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = 26
LEFT MERGE JOIN SMSDSS.BMH_UserTwoFact_V AS E
ON B.PtNo_Num = E.PtNo_Num
	AND E.UserDataKey = 27
LEFT MERGE JOIN SMSDSS.BMH_PLM_PTACCT_V  AS C
ON A.Account = C.PtNo_Num

--WHERE B.UserDataKey IN (25, 26)
WHERE A.Arrival >= '2015-12-06'
AND A.Arrival < '2015-12-13'
AND (
	b.UserDataText NOT LIKE '%homeless%'
	AND b.UserDataText NOT LIKE '%No primary%'
	)

ORDER BY [Facility Line 1]
, A.MR#
, A.Account