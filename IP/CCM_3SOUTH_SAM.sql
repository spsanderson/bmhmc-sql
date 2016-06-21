-- Patients that are on 3 South with a Continuous Cardiac Monitor on
-- No date range specified
--*********************************************************************************

-- Columns Selection the prefix of CV means the column comes from the CV3.ClientVisit Table
-- the prefix of O means the folumn comes from the CV3Order table
SELECT CV.AdmitDtm AS 'ADMIT DATE', CV.CurrentLocation AS 'LOCATION', CV.ClientDisplayName AS 'PT NAME',
CV.VisitIDCode AS 'ENC. NUM', CV.TypeCode AS 'TYPE', O.Name AS 'ORDER NAME',
O.Active AS 'ACTIVE ORDER'

-- The main table being used: 
FROM CV3ClientVisit CV

JOIN CV3Order O
ON CV.GUID = O.ClientVisitGUID

-- Filters
WHERE Name LIKE '%CONTINUOUS CARDIAC MONITOR%'
AND CV.CurrentLocation LIKE '%3 SOUTH%'

--*********************************************************************************
-- End Report
-- Sanderson, Steven 1.2.12