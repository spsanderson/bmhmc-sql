DECLARE @SD DATETIME;
DECLARE @ED DATETIME;

SET @SD = '2015-01-01';
SET @ED = CONVERT(DATE,GETDATE());

SELECT SUBSTRING(acct_no, PATINDEX('%[^0]%', acct_no),9) AS [VISIT ID]
, vst_med_rec_no
, prin_dx_cd
, dsch_disp
, X.[DSC DESC]
, ward_cd
, DATEPART(MONTH, dsch_date) AS [MONTH]
, DATEPART(YEAR, dsch_date) AS [YEAR]

FROM smsmir.vst_rpt

CROSS APPLY (
	SELECT
		CASE
			WHEN DSCH_DISP = 'ATF' THEN 'Specialty Hospital (i.e Sloan, Schneiders)'
			WHEN DSCH_DISP = 'ATH' THEN 'Hospital - Med/Surg (i.e Stony Brook)'
			WHEN dsch_disp = 'ATN' THEN 'Hospital - VA'
		END AS [DSC DESC]
	) X

WHERE dsch_date >= @SD
AND dsch_date < @ED
AND ward_cd IS NOT NULL
AND dsch_disp IN (
	'ATF'
	,'ATH'
	, 'ATN'
)

ORDER BY dsch_date ASC
