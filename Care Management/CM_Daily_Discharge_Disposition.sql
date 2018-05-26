DECLARE @START    DATETIME;
DECLARE @END      DATETIME;
DECLARE @ThisDate DATETIME;
	
SET @ThisDate = GETDATE(); -- Today
SET @START    = DATEADD(wk, DATEDIFF(wk, 7, @ThisDate), -1); -- Last Sunday
SET @END      = DATEADD(WK, DATEDIFF(WK, 0, @ThisDate), -1); -- This past Sunday

SELECT MRN
, PtNo_Num
, Dsch_Unit
, Form_Collected_By
, Anticipated_Discharge_Flag
, List_Provided_Flag
, PT_and_Fam_Notified_Flag
, GroupHome_Flag
, Form_Done

INTO #TEMPA

FROM smsdss.c_CM_Daily_DschDisp_RptRecords_tbl

WHERE PtNo_Num IN (
	SELECT PtNo_Num
	FROM smsdss.c_CM_Daily_DschDisp_Records_tbl
	WHERE Dsch_DTime >= @START
	AND Dsch_DTime < @END
)
;

SELECT A.Med_Rec_No
, A.PtNo_Num
, B.ward_cd
, ISNULL(C.Form_Collected_By, 'N/C') AS [Form_Collected_By]
, ISNULL(C.Anticipated_Discharge_Flag, 0) AS [Anticipated_Discharge_Flag]
, ISNULL(C.List_Provided_Flag, 0) AS [List_Provided_Flag]
, ISNULL(C.PT_and_Fam_Notified_Flag, 0) AS [PT_and_Fam_Notified_Flag]
, ISNULL(C.GroupHome_Flag, 0) AS [GroupHome_Flag]
, ISNULL(C.Form_Done, 0) AS [Form_Done]

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsmir.vst_rpt AS B
ON A.PT_NO = B.PT_ID
	AND A.UNIT_SEQ_NO = B.UNIT_SEQ_NO
	AND A.FROM_FILE_IND	= B.FROM_FILE_IND
LEFT OUTER JOIN #TEMPA AS C
ON A.Med_Rec_No = C.MRN
	AND A.PtNo_Num = A.PtNo_Num

WHERE A.Dsch_Date >= @START
AND A.Dsch_Date < @END
AND A.Plm_Pt_Acct_Type = 'I'
AND LEFT(A.PTNO_NUM, 1) != '2'
AND LEFT(A.PTNO_NUM, 4) != '1999'
AND A.tot_chg_amt > 0
AND (
	C.Form_Done != 1
	OR
	C.Form_Done IS NULL
)

ORDER BY C.Form_Done
;

DROP TABLE #TEMPA
;