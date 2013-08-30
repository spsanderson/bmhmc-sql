SELECT dsch_date
, vst_id
, dsch_disp
, ward_cd
, DATEPART(MONTH, dsch_date) AS [MONTH]
, DATEPART(YEAR, dsch_date) AS [YEAR]

FROM smsmir.vst_rpt
WHERE dsch_date = '2013-08-26'
ORDER BY dsch_date ASC