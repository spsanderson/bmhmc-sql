-- THIS QUERY PULLS TOGETHER ON A USER SPECIFIED DATE RANGE THE LOS OF A PATIENT
-- THE DRG LOS BENCH AS SPECIFIED BY MS-DRG AND CALCULATES THE DIFFERENCE OF THE 
-- DRG BENCH LOS MINUS THE ACTUAL LOS --> (DRG LOS BENCH) - (ACTUAL LOS)
-- THIS INFORMATION WAS ASKED FOR BY DR. ALCASABAS, IT ONLY INCLUDES A LIST OF
-- DOCTORS WHO ARE EITHER INTERNAL MED, FAMILY MED, HOSPITALIST OR SURGEON
--#####################################################################

DECLARE @STARTDATE DATETIME
DECLARE @ENDATE DATETIME

SET @STARTDATE = '2013-04-01'
SET @ENDATE = '2013-04-30'

SELECT DISTINCT vr.pt_id AS 'PT ID' 
, pv.pract_rpt_name AS 'PHYSICIAN'
, pv.spclty_desc AS 'SPECIALTY'
, pv.med_staff_dept AS 'MED STAFF'
, vr.rpt_name AS 'PT NAME'
, vr.len_of_stay AS 'LOS'
, vr.drg_std_days_stay AS 'DRG LOS BENCH'
, (vr.len_of_stay - vr.drg_std_days_stay) AS 'LOS - DRG BENCH'
, DATEPART(MM,vr.adm_date) AS 'ADM MONTH'
, DATEPART(YY, VR.adm_date) AS 'ADM YEAR'
, DATEPART(MM, VR.DSCH_DATE) AS 'DISC MONTH'
, DATEPART(YY, VR.DSCH_DATE) AS 'DISC YEAR'

FROM smsmir.vst_rpt vr
LEFT OUTER JOIN smsmir.pyr_plan pp
ON vr.pt_id = pp.pt_id
JOIN smsdss.pract_dim_v pv
ON vr.adm_pract_no = pv.src_pract_no

WHERE vr.adm_dtime BETWEEN @STARTDATE AND @ENDATE
AND vr.vst_type_cd = 'I'
AND pv.spclty_desc != 'NO DESCRIPTION'
AND vr.drg_std_days_stay IS NOT NULL
AND pv.pract_rpt_name != '?'
AND pv.orgz_cd = 's0x0'
AND pv.med_staff_dept IN (
'INTERNAL MEDICINE',
'FAMILY PRACTICE',
'SURGERY'
)
ORDER BY pv.pract_rpt_name

--#####################################################################
-- END REPORT.
-- NAME: SANDERSON, STEVEN
-- DEPT: PERFORMANCE IMPROVEMENT
-- DATE: MAY 20 2013
-- FOR : DR ALCASABAS