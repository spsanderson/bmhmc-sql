DECLARE @STARTDATE DATETIME;
DECLARE @ENDATE    DATETIME;
SET @STARTDATE =   '2014-04-01';
SET @ENDATE =      '2014-05-01';

SELECT DISTINCT pv.pract_rpt_name            AS 'PHYSICIAN'
, pv.med_staff_dept                          AS 'MED STAFF'
, COUNT(DISTINCT vr.pt_id)                   AS '# PTS'
, AVG(vr.len_of_stay)                        AS 'MD ALOS'
, AVG(vr.drg_std_days_stay)                  AS 'MD ALOS BENCH'
, AVG(vr.len_of_stay - vr.drg_std_days_stay) AS 'AVG OPP'
, (SELECT
    COUNT(DISTINCT v.PT_ID) 
    FROM smsdss.pract_dim_v p
    JOIN smsmir.vst_rpt v
    ON v.adm_pract_no = p.src_pract_no
    WHERE pv.med_staff_dept = p.med_staff_dept
    AND v.adm_dtime >= @STARTDATE 
    AND v.adm_dtime < @ENDATE
    AND v.vst_type_cd = 'I'
    AND p.spclty_desc != 'NO DESCRIPTION'
    AND p.spclty_desc NOT LIKE 'HOSPITALIST%'
    AND v.drg_std_days_stay IS NOT NULL
    AND p.pract_rpt_name != '?'
    AND p.orgz_cd = 's0x0'
    AND p.med_staff_dept IN (
    'INTERNAL MEDICINE'
    ,'FAMILY PRACTICE'
    ,'SURGERY'
    )
) AS '# PTS For Dept'
, (SELECT
    AVG(V.len_of_stay)
	FROM smsmir.vst_rpt v
	JOIN smsdss.pract_dim_v p
	ON v.adm_pract_no = p.src_pract_no
	WHERE pv.med_staff_dept = p.med_staff_dept
    AND v.adm_dtime >= @STARTDATE 
    AND v.adm_dtime < @ENDATE
    AND v.vst_type_cd = 'I'
    AND p.spclty_desc != 'NO DESCRIPTION'
    AND p.spclty_desc NOT LIKE 'HOSPITALIST%'
    AND v.drg_std_days_stay IS NOT NULL
    AND p.pract_rpt_name != '?'
    AND p.orgz_cd = 's0x0'
    AND p.med_staff_dept IN (
    'INTERNAL MEDICINE',
    'FAMILY PRACTICE',
    'SURGERY'
    )
) AS 'DEPT ALOS'
, (SELECT
	AVG(v.drg_std_days_stay)
	FROM smsmir.vst_rpt v
	JOIN smsdss.pract_dim_v p
	ON v.adm_pract_no = p.src_pract_no
	WHERE pv.med_staff_dept = p.med_staff_dept
    AND v.adm_dtime >= @STARTDATE 
    AND v.adm_dtime < @ENDATE
    AND v.vst_type_cd = 'I'
    AND p.spclty_desc != 'NO DESCRIPTION'
    AND p.spclty_desc NOT LIKE 'HOSPITALIST%'
    AND v.drg_std_days_stay IS NOT NULL
    AND p.pract_rpt_name != '?'
    AND p.orgz_cd = 's0x0'
    AND p.med_staff_dept IN (
    'INTERNAL MEDICINE',
    'FAMILY PRACTICE',
    'SURGERY'
    )
) AS 'DEPT BENCH'
, (SELECT
	AVG(v.len_of_stay - v.drg_std_days_stay)
	FROM smsmir.vst_rpt v
	JOIN smsdss.pract_dim_v p
	ON v.adm_pract_no = p.src_pract_no
	WHERE pv.med_staff_dept = p.med_staff_dept
    AND v.adm_dtime >= @STARTDATE 
    AND v.adm_dtime < @ENDATE
    AND v.vst_type_cd = 'I'
    AND p.spclty_desc != 'NO DESCRIPTION'
    AND p.spclty_desc NOT LIKE 'HOSPITALIST%'
    AND v.drg_std_days_stay IS NOT NULL
    AND p.pract_rpt_name != '?'
    AND p.orgz_cd = 's0x0'
    AND p.med_staff_dept IN (
    'INTERNAL MEDICINE',
    'FAMILY PRACTICE',
    'SURGERY'
    )
) AS 'DEPT OPP'

FROM smsmir.vst_rpt vr
JOIN smsdss.pract_dim_v pv
ON vr.adm_pract_no = pv.src_pract_no

WHERE vr.adm_dtime >= @STARTDATE 
AND vr.adm_dtime < @ENDATE
AND vr.vst_type_cd = 'I'
AND pv.spclty_desc != 'NO DESCRIPTION'
AND pv.spclty_desc NOT LIKE 'HOSPITALIST%'
AND vr.drg_std_days_stay IS NOT NULL
AND pv.pract_rpt_name != '?'
AND pv.orgz_cd = 's0x0'
AND pv.med_staff_dept IN (
'INTERNAL MEDICINE'
,'FAMILY PRACTICE'
,'SURGERY'
)
GROUP BY pv.pract_rpt_name, pv.med_staff_dept, pv.spclty_desc
ORDER BY pv.med_staff_dept, AVG(vr.len_of_stay - vr.drg_std_days_stay)DESC