DECLARE @START    DATETIME;
DECLARE @END      DATETIME;
DECLARE @ThisDate DATETIME;
	
SET @ThisDate = GETDATE(); -- Today
SET @START    = dateadd(wk, datediff(wk, 7, @ThisDate), -1); -- Last Sunday
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

FROM smsdss.c_CM_Daily_DschDisp_RptRecords_tbl

WHERE PtNo_Num IN (
	SELECT PtNo_Num
	FROM smsdss.c_CM_Daily_DschDisp_Records_tbl
	WHERE Dsch_DTime >= @START
	AND Dsch_DTime < @END
)
;