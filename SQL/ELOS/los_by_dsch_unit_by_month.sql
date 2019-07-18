-- VARIABLE DECLARATION
DECLARE @YEAR INT;

-- VARIABLE INITIALIZATION
SET @YEAR = DATEPART(year, getdate());

-- COLUMN SELECTION
SELECT ward_cd AS [Nurse Station]
, ISNULL(ROUND(P.[1], 2), 0) AS 'Jan'
, ISNULL(ROUND(P.[2], 2), 0) AS 'Feb'
, ISNULL(ROUND(P.[3], 2), 0) AS 'Mar'
, ISNULL(ROUND(P.[4], 2), 0) AS 'Apr'
, ISNULL(ROUND(P.[5], 2), 0) AS 'May'
, ISNULL(ROUND(P.[6], 2), 0) AS 'Jun'
, ISNULL(ROUND(P.[7], 2), 0) AS 'Jul'
, ISNULL(ROUND(P.[8], 2), 0) AS 'Aug'
, ISNULL(ROUND(P.[9], 2), 0) AS 'Sep'
, ISNULL(ROUND(P.[10], 2), 0) AS 'Oct'
, ISNULL(ROUND(P.[11], 2), 0) AS 'Nov'
, ISNULL(ROUND(P.[12], 2), 0) AS 'Dec'

FROM (
	SELECT WARD_CD
	, len_of_stay
	, DATEPART(MONTH, vst_end_date) [Discharge Month]

	FROM smsmir.VST

	WHERE DATEPART(YEAR, vst_end_date) = @YEAR
	AND LEFT(PT_ID, 5) = '00001'
	AND pt_id IN (
		SELECT PT_NO
		FROM smsdss.BMH_PLM_PtAcct_V
		WHERE tot_chg_amt > 0
	)
) A

PIVOT (
	AVG(LEN_OF_STAY)
	FOR [Discharge Month] IN (
		"1","2","3","4","5","6","7","8","9","10","11","12"
	)
)P

where ward_cd is not null

order by ward_cd