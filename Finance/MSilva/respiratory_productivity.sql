DECLARE @TODAY DATE;
DECLARE @START DATE;
DECLARE @END   DATE;

SET @TODAY = CAST(GETDATE() AS date);
SET @START = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY) - 17, 0);
SET @END   = DATEADD(DAY, DATEDIFF(DAY, 0, @TODAY) - 4, 0);

SELECT a.actv_cd
, b.actv_name
, a.gl_key
, c.actv_cost_ctr
, c.actv_cost_ctr_name
, SUM(actv_tot_qty) AS [Tot_Qty]

FROM smsmir.actv AS a 
LEFT JOIN smsmir.actv_mstr AS b
ON a.actv_cd=b.actv_cd
LEFT JOIN smsdss.c_glkey_cstctr_xref AS c
ON a.gl_key=c.gl_key

WHERE a.actv_date BETWEEN @START AND @END 
AND a.actv_cd NOT IN (
	'00400572','00401760','00400945','00403642',
	'00403170','00400788','00400838','00400671'
)
AND c.actv_cost_ctr = '7381'

GROUP BY a.actv_cd
, b.actv_name
, a.gl_key
, c.actv_cost_ctr
, c.actv_cost_ctr_name

ORDER BY a.actv_cd, a.gl_key
