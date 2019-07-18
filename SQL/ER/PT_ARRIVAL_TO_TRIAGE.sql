-- Times patients arrive and their respective triage time
--*********************************************************************************

-- Column Selection
SELECT s_VISIT_IDENT AS 'Encounter', dt_ARRIVAL AS 'PT Arrival',
AHP_TRIAGE_DATETIME AS 'Triage Time', DATEDIFF(MI,DT_ARRIVAL,AHP_TRIAGE_DATETIME) AS
'ARR TO TRIAGE TIME MINUTES'
    
-- Database USED: MEDHOST
FROM dbo.JTM_GENERIC_LIST_V

-- Filters
WHERE dt_ARRIVAL BETWEEN '1/1/13' AND '4/1/13'
AND AHP_TRIAGE_DATETIME IS NOT NULL

--*********************************************************************************
-- END REPORT
-- Sanderson, Steven 1.9.13