SELECT a.PtNo_Num
, a.UserDataText
, b.UserDataCd

FROM smsdss.BMH_UserTwoField_Fact AS A
LEFT OUTER JOIN smsdss.BMH_UserTwoField_Dim_V AS B
ON a.UserDataKey = b.UserTwoKey

WHERE a.PtNo_Num IN (

)
AND b.UserDataCd = '2ADMDIAG'