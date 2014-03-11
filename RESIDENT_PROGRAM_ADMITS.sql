DECLARE @STARTDATE DATETIME
DECLARE @ENDATE DATETIME

SET @STARTDATE = '2014-01-01'
SET @ENDATE = '2014-01-31'

select distinct pv.pract_rpt_name
, vr.pt_id


FROM smsmir.vst_rpt vr
JOIN smsdss.pract_dim_v pv
ON vr.adm_pract_no = pv.src_pract_no

WHERE vr.adm_dtime BETWEEN @STARTDATE AND @ENDATE
AND pract_rpt_name in (
list of persons
)
group by pv.pract_rpt_name
, vr.pt_id
