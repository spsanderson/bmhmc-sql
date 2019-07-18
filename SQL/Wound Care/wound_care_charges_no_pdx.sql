DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = '2018-01-01';
SET @END   = '2018-07-01';
SELECT A.Med_Rec_No
, A.PtNo_Num
, A.Adm_Date
, A.tot_chg_amt
, A.tot_pay_amt
, A.Tot_Amt_Due

FROM smsdss.BMH_PLM_PtAcct_V AS A

WHERE A.hosp_svc IN (
	'WCC', 'WCH'
)
AND A.Pt_No IN (
	SELECT DISTINCT(ZZZ.PT_ID)
	FROM smsmir.actv AS ZZZ
	WHERE LEFT(ACTV_CD, 3) = '025'
)
AND A.Adm_Date >= @START
AND A.Adm_Date < @END
AND A.prin_dx_cd IS NULL
AND A.tot_chg_amt > 0
;