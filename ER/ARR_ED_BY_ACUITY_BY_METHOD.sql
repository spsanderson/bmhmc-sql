-- ARRIVAL TO ED BY ACUITY AND METHOD
-- 
--*********************************************************************************

SELECT (N_ARR_TO_IN_BED - N_ARR_TO_TRIAGE) AS 'TRIAGE TO BED TIME', s_ARRIVAL_METHOD AS 'ARRIVAL METHOD',
S_FIRST_ACUITY AS 'TRIAGE ACUITY LEVEL'

FROM DBO.JTM_GENERIC_LIST_V

WHERE DT_ARRIVAL BETWEEN '1/1/12' AND '1/1/2013'
AND S_FIRST_ACUITY IS NOT NULL
AND S_ARRIVAL_METHOD IS NOT NULL
--AND (N_ARR_TO_IN_BED - N_ARR_TO_TRIAGE) < 0
ORDER BY (N_ARR_TO_IN_BED - N_ARR_TO_TRIAGE) DESC

--*********************************************************************************
-- End Report
-- Sanderson, Steven 1.31.12