-- THIS QUERY PULLS TOGETHER ON A USER SPECIFIED DATE RANGE THE LOS OF A PATIENT
-- THE DRG LOS BENCH AS SPECIFIED BY MS-DRG AND CALCULATES THE DIFFERENCE OF THE 
-- DRG BENCH LOS MINUS THE ACTUAL LOS --> (DRG LOS BENCH) - (ACTUAL LOS)
-- THIS INFORMATION WAS ASKED FOR BY DR. ALCASABAS, IT ONLY INCLUDES A LIST OF
-- DOCTORS WHO ARE EITHER INTERNAL MED, FAMILY MED, HOSPITALIST OR SURGEON
--#####################################################################

DECLARE @STARTDATE DATETIME
DECLARE @ENDATE DATETIME

SET @STARTDATE = '2013-12-01'
SET @ENDATE = '2013-12-31'

SELECT DISTINCT pv.pract_rpt_name AS 'PHYSICIAN'
, pv.med_staff_dept AS 'MED STAFF'
, COUNT(DISTINCT vr.pt_id) AS '# PTS' 
, AVG(vr.len_of_stay) AS 'AVG LOS'
, AVG(vr.drg_std_days_stay) AS 'AVG DRG LOS BENCH'
, AVG(vr.len_of_stay - vr.drg_std_days_stay) AS 'AVG(LOS - DRG BENCH)'

FROM smsmir.vst_rpt vr
JOIN smsdss.pract_dim_v pv
ON vr.adm_pract_no = pv.src_pract_no

WHERE vr.adm_dtime BETWEEN @STARTDATE AND @ENDATE
AND vr.vst_type_cd = 'I'
AND pv.spclty_desc != 'NO DESCRIPTION'
AND pv.spclty_desc NOT LIKE 'HOSPITALIST%'
AND vr.drg_std_days_stay IS NOT NULL
AND pv.pract_rpt_name != '?'
AND pv.orgz_cd = 's0x0'
AND pv.med_staff_dept IN (
'INTERNAL MEDICINE',
'FAMILY PRACTICE',
'SURGERY'
)
GROUP BY pv.pract_rpt_name, pv.med_staff_dept, pv.spclty_desc
ORDER BY pv.med_staff_dept, AVG(vr.len_of_stay - vr.drg_std_days_stay)DESC

--#####################################################################
-- END REPORT.
-- NAME: SANDERSON, STEVEN
-- DEPT: PERFORMANCE IMPROVEMENT
-- DATE: MAY 20 2013
-- FOR : DR ALCASABAS, PHYLLIS HARTMANN