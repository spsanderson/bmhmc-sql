-- GETS THE ENCOUNTER # OF IP ADMITS FOR A 12 MONTH PERIOD. 
--*****************************************************************************************
-- VARIABLE DECLARATION
SET ANSI_NULLS OFF
GO

DECLARE @STARTDATE DATETIME
DECLARE @ENDDATE DATETIME

-- INITIALIZE VARIABLES
SET @STARTDATE = '6/1/12';
SET @ENDDATE = '1/1/13';

DECLARE @IPT TABLE (ENCOUNTER VARCHAR(20), COUNT_IP VARCHAR(3))
INSERT INTO @IPT
SELECT
CV.IDCODE,
COUNT(CV.IDCODE)

FROM CV3ClientVisit CV

WHERE CV.AdmitDtm BETWEEN @STARTDATE AND @ENDDATE
AND CV.TypeCode LIKE '%INPATIENT'

GROUP BY CV.IDCode
ORDER BY COUNT(CV.IDCode) DESC

-- COLUMN SELECTION
SELECT DISTINCT ENCOUNTER, COUNT(ENCOUNTER) AS 'COUNT OF IP VISITS'
FROM @IPT
GROUP BY ENCOUNTER

--*****************************************************************************************
-- SANDERSON, STEVEN MEDICAL AFFAIRS
-- 3.29.13 EXT 4901