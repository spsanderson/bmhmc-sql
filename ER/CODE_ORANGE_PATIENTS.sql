-- Report run for Joanne Lauten. Data requested by NYSDOH for all code orange patients
-- for the time frame of January 1, 2012 - December 31, 2012
--************************************************************************************

-- Column Selection
SELECT 
S_PATIENT_FULL_NAME AS 'PATIENT NAME', S_VISIT_IDENT AS 'ENCOUNTER #',
dt_ARRIVAL AS 'PT ARRIVAL', dt_MED_SCREEN AS 'MEDICAL SCREEN TIME',
S_DIAGNOSIS AS 'ED DISCHARGE DX'

-- DATABASE USED: MEDHOST
FROM DBO.JTM_GENERIC_LIST_V

-- FILTERS
WHERE dt_ARRIVAL BETWEEN '01/01/2013' AND '04/01/2013'
AND (
S_DIAGNOSIS LIKE '%STROKE%'
OR S_DIAGNOSIS LIKE 'TIA %'
OR S_DIAGNOSIS LIKE '% TIA'
OR s_DIAGNOSIS LIKE '%TRANSIENT ISCHEMIC ATTACK%'
OR s_DIAGNOSIS LIKE '% CVA'
OR s_DIAGNOSIS LIKE 'CVA %'
)
ORDER BY dt_ARRIVAL ASC

--************************************************************************************
-- REPORT RUN 2.25.2013
-- STEVEN SANDERSON MEDICAL AFFAIRS