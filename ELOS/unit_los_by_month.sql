-- VARIABLE DECLARATION
DECLARE @YEAR INT;

-- VARIABLE INITIALIZATION
SET @YEAR = DATEPART(year, getdate());

-- COLUMN SELECTION
SELECT nurs_sta
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
	select nurs_sta
	, DATEPART(month, cen_date) as [month]
	, CAST(SUM(tot_cen) AS float) AS [los]

	from smsdss.dly_cen_occ_fct_v

	where DATEPART(year, cen_date) = @YEAR

	group by nurs_sta
	, DATEPART(MONTH, cen_date)
	, pt_id
) A

PIVOT (
	AVG(LOS)
	FOR [MONTH] IN (
		"1","2","3","4","5","6","7","8","9","10","11","12"
	)
)P