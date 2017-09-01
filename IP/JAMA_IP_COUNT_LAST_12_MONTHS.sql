-- GETS THE ENCOUNTER # OF IP ADMITS FOR A 12 MONTH PERIOD. 
--*****************************************************************************************
-- VARIABLE DECLARATION
DECLARE @STARTDATE DATETIME
DECLARE @ENDDATE DATETIME

-- INITIALIZE VARIABLES
SET @STARTDATE = '6/1/12';
SET @ENDDATE = '1/1/13';

-- COLUMN SELECTION
SELECT DISTINCT CV.IDCode AS 'MRN', COUNT(CV.IDCODE) AS 'COUNT OF IP VISITS'

FROM CV3ClientVisit CV

WHERE CV.AdmitDtm BETWEEN @STARTDATE AND @ENDDATE
AND CV.TypeCode LIKE '%INPATIENT'

GROUP BY CV.IDCode
ORDER BY COUNT(CV.IDCode) DESC
--*****************************************************************************************
-- SANDERSON, STEVEN MEDICAL AFFAIRS
-- 3.29.13 EXT 4901