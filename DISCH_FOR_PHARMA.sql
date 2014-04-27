SELECT dsch_date
, acct_no
, vst_med_rec_no
, dsch_disp
, ward_cd
, DATEPART(MONTH, dsch_date) AS [MONTH]
, DATEPART(YEAR, dsch_date) AS [YEAR]

FROM smsmir.vst_rpt
WHERE dsch_date = '2014-04-17'
AND ward_cd IS NOT NULL
ORDER BY dsch_date ASC
