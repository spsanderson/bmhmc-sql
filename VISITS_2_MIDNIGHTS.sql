SELECT PtNo_Num
, Med_Rec_No                                AS MRN
, vst_start_dtime                           AS [ADMIT DTIME]
, DATEPART(hour, vst_start_dtime)           AS [ADMIT HOUR]
, 24-DATEPART(HOUR, VST_START_DTIME)        AS [HRS 2 MIDNIGHT]
, 24+(24-DATEPART(HOUR, VST_START_DTIME))   AS [HRS 2 SECOND MIDNIGHT]
, Dsch_DTime                                AS [DISC DTIME]
, DATEDIFF(HOUR,vst_start_dtime,Dsch_DTime) AS [HOURS HERE]

FROM smsdss.BMH_PLM_PtAcct_V
WHERE Dsch_Date BETWEEN '2014-01-01' AND '2014-10-31'
AND Plm_Pt_Acct_Type = 'I'
AND DATEDIFF(HOUR,vst_start_dtime,Dsch_DTime) <= (24+(24-DATEPART(HOUR, VST_START_DTIME)))