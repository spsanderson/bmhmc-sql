-- THIS QUERY PULLS TOGETHER ON A USER SPECIFIED DATE RANGE THE LOS OF A PATIENT
-- THE DRG LOS BENCH AS SPECIFIED BY MS-DRG AND CALCULATES THE DIFFERENCE OF THE 
-- DRG BENCH LOS MINUS THE ACTUAL LOS --> (DRG LOS BENCH) - (ACTUAL LOS)
-- THIS INFORMATION WAS ASKED FOR BY DR. ALCASABAS, IT ONLY INCLUDES A LIST OF
-- DOCTORS WHO ARE EITHER INTERNAL MED, FAMILY MED, HOSPITALIST OR SURGEON
--#####################################################################

DECLARE @STARTDATE DATETIME
DECLARE @ENDATE DATETIME

SET @STARTDATE = '2016-11-01'
SET @ENDATE = '2016-12-01'

SELECT DISTINCT pv.pract_rpt_name AS 'PHYSICIAN'
, pv.med_staff_dept AS 'MED STAFF'
, COUNT(DISTINCT vr.pt_id) AS '# PTS' 
, ROUND(AVG(vr.len_of_stay), 2) AS 'AVG LOS'
, ROUND(AVG(elos.performance), 2) as 'elos'

FROM smsmir.vst_rpt vr
JOIN smsdss.pract_dim_v pv
ON vr.adm_pract_no = pv.src_pract_no
join smsdss.c_elos_bench_data as elos
on vr.pt_id = elos.Encounter

WHERE vr.adm_dtime >= @STARTDATE 
AND vr.adm_dtime < @ENDATE
AND vr.vst_type_cd = 'I'
AND pv.spclty_desc != 'NO DESCRIPTION'
AND pv.spclty_desc NOT LIKE 'HOSPITALIST%'
AND vr.drg_std_days_stay IS NOT NULL
AND pv.pract_rpt_name != '?'
AND pv.orgz_cd = 's0x0'
AND pv.med_staff_dept IN (
	'Internal Medicine/Pediatrics',
	'Internal Medicine',
	'Pediatrics',
	'Family Practice'
)
GROUP BY pv.pract_rpt_name, pv.med_staff_dept, pv.spclty_desc
ORDER BY pv.med_staff_dept

--#####################################################################
-- END REPORT.
-- NAME: SANDERSON, STEVEN
-- DEPT: PERFORMANCE IMPROVEMENT
-- DATE: MAY 20 2013
-- FOR : DR ALCASABAS, PHYLLIS HARTMANN