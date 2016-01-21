DECLARE @start DATE;
DECLARE @end   DATE;

SET @start = '2015-01-01';
SET @end   = '2016-01-01';

SELECT ward_cd
, COUNT(pt_id)                AS Discharge_Count
, ROUND(AVG(len_of_stay), 2)  AS ALOS
--, vst_start_dtime
--, vst_end_dtime

FROM smsmir.mir_vst

WHERE vst_type_cd = 'i'
AND pt_id < '000020000000'
AND LEFT(pt_id, 8) != '00001999'
AND vst_end_dtime >= @start
AND vst_end_dtime <  @end
AND tot_chg_amt > '0'

GROUP BY ward_cd

UNION ALL

SELECT 'Grand Totals'
, COUNT(pt_id)
, ROUND(AVG(len_of_stay), 2)

FROM SMSMIR.mir_vst

WHERE vst_type_cd = 'i'
AND pt_id < '000020000000'
AND LEFT(pt_id, 8) != '00001999'
AND vst_end_dtime >= @start
AND vst_end_dtime <  @end
AND tot_chg_amt > '0'