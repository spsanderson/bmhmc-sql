SELECT A.PtNo_Num
, A.[BMH Discharge DateTime]
, DATEPART(MONTH, A.[BMH Discharge DateTime]) AS DISCH_MONTH
, DATEPART(YEAR, A.[BMH Discharge DateTime]) AS DISCH_YEAR
, A.[Home Care MR/EPI]
, A.[Start of Care Date]
, A.[NTUC Date]
, A.[NTUC Reason]
, B.[READMIT]
, B.[READMIT SOURCE DESC]
, B.[READMIT DATE]
, B.[INTERIM]

FROM smsdss.c_Home_Care_Rpt_Tbl AS A
LEFT MERGE JOIN smsdss.vReadmits AS B
ON A.PtNo_Num = B.[INDEX]
	AND B.[INTERIM] > 0
	AND B.[INTERIM] < 31
	AND B.[READMIT SOURCE DESC] != 'Scheduled Admission'

WHERE A.[BMH Discharge DateTime] >= ''
AND A.[BMH Discharge DateTime] < ''
	
ORDER BY A.[BMH Discharge DateTime]