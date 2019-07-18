SELECT B_Episode_No AS [VISIT ID]
, B_Adm_Src_Desc AS [ADMIT SOURCE]
, B_Days_To_Readmit AS [DAYS TO FAILURE]
, B_Days_Stay AS [LOS]
, 1 AS FAILURE

FROM smsdss.c_readmissions_v

WHERE B_Adm_Date BETWEEN '2012-12-01' AND '2014-01-31'
AND B_Adm_Src_Desc != 'Scheduled Admission'
AND B_Episode_No < '20000000'