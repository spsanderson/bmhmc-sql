-- Report for Loarrain Farrel. Requesting the count of ambulance arrivals by
-- ambulance company, on a month by month basis
--*********************************************************************************

-- Column Selction
SELECT s_ARRIVAL_METHOD,DATEPART(year,dt_ARRIVAL)as 'Year', 
DATEPART(month,dt_ARRIVAL) as 'Month', count(s_VISIT_IDENT)as '# Arrivals' 

-- Database Used: Medhost
FROM dbo.JTM_GENERIC_LIST_V 

-- Filters
WHERE rtrim(s_ARRIVAL_METHOD) not in ('Other','Police',
'Private Auto','Unknown','Walk-In','Carried','Wheelchair') 
AND s_ARRIVAL_METHOD IS NOT NULL  
AND datepart(year,dt_ARRIVAL) IN ('2013')
AND datepart(month,dt_ARRIVAL) IN ('3')
GROUP BY s_ARRIVAL_METHOD,datepart(year,dt_ARRIVAL),datepart(month,dt_ARRIVAL)   
ORDER BY datepart(year,dt_ARRIVAL),datepart(month,dt_ARRIVAL),s_ARRIVAL_METHOD

--*********************************************************************************
-- End Report
-- Sanderson, Steven 12.13.12
