DECLARE @S DATE;
DECLARE @E DATE;

SET @S = '2014-01-01';
SET @E = GETDATE();

SELECT episode_no AS VISIT
, ord_no          AS [ORDER #]
, svc_desc        AS [ORDER DESC]
, pty_name        AS [ORDERING PARTY]
, ent_dtime       AS [ENTRY DTIME]
, str_dtime       AS [START DTIME]
, freq_dly        AS FREQUENCY
, stp_dtime       AS [STOP ORDER ON]
, freq_wk         AS [REPEAT]
, ROW_NUMBER() OVER (
				PARTITION BY EPISODE_NO	ORDER BY ORD_NO ASC
				) AS [ORDER COUNT]
, (CASE
	WHEN stp_dtime = '1900-01-01 00:00:00.000'
	THEN 1
	ELSE 0
  END)            AS FLAG

FROM smsmir.sr_ord

WHERE svc_cd = 'PCO_RSTSAFETY'
AND episode_no < '20000000'

ORDER BY episode_no DESC, [ORDER #] ASC