DECLARE @STARTDATE DATETIME;
DECLARE @ENDATE    DATETIME;
SET @STARTDATE =   '2014-07-01';
SET @ENDATE =      '2014-08-01';

SELECT pv.med_staff_dept                     AS [MED STAFF DEPT]
, COUNT(PV.MED_STAFF_DEPT)                   AS [# PTS]
, AVG(vr.len_of_stay)                        AS [ALOS DEPT]
, AVG(VR.drg_std_days_stay)                  AS [ALOS BENCH]
, AVG(VR.LEN_OF_STAY - VR.DRG_STD_DAYS_STAY) AS [AVG OPP]

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

GROUP BY PV.MED_STAFF_DEPT
UNION ALL

SELECT 'TOTAL'
, COUNT(PV.MED_STAFF_DEPT)
, AVG(vr.len_of_stay)
, AVG(VR.drg_std_days_stay)
, AVG(VR.LEN_OF_STAY - VR.DRG_STD_DAYS_STAY)

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