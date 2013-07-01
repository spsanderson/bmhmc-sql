DECLARE @STARTDATE DATETIME
DECLARE @ENDATE DATETIME

SET @STARTDATE = '2013-05-01'
SET @ENDATE = '2013-05-31'

SELECT DISTINCT pv.pract_rpt_name AS 'PHYSICIAN'
, COUNT(distinct vr.pt_id) AS '# PTS' 
--, pv.spclty_desc AS 'SPECIALTY'
, pv.med_staff_dept AS 'MED STAFF'
, AVG(vr.len_of_stay) AS 'LOS'
, AVG(vr.drg_std_days_stay) AS 'DRG LOS BENCH'
, AVG(vr.len_of_stay - vr.drg_std_days_stay) AS 'LOS - DRG BENCH'

FROM smsmir.vst_rpt vr
LEFT OUTER JOIN smsmir.pyr_plan pp
ON vr.pt_id = pp.pt_id
JOIN smsdss.pract_dim_v pv
ON vr.adm_pract_no = pv.src_pract_no

WHERE vr.adm_dtime BETWEEN @STARTDATE AND @ENDATE
AND vr.vst_type_cd = 'I'
AND pv.spclty_desc != 'NO DESCRIPTION'
--AND pv.spclty_desc NOT LIKE 'HOSPITALIST%'
AND vr.drg_std_days_stay IS NOT NULL
AND pv.pract_rpt_name != '?'
AND pv.orgz_cd = 's0x0'
AND pv.med_staff_dept IN (
'INTERNAL MEDICINE',
'FAMILY PRACTICE',
'SURGERY'
)
GROUP BY pv.pract_rpt_name, pv.med_staff_dept
ORDER BY pv.med_staff_dept, AVG(vr.len_of_stay - vr.drg_std_days_stay)DESC