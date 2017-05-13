-- Column Selection
SELECT * 

-- Database Used: SAM Replica
FROM CV3ClientVisitLocation cvl
JOIN CV3Location l
ON cvl.LocationGUID=l.GUID
JOIN CV3ClientVisit cv
ON cvl.ClientVisitGUID=cv.GUID

-- Filters Used
WHERE l.Name LIKE 'Telemetry-310%'
AND cvl.CreatedWhen BETWEEN '12/1/12' AND '1/31/13'
ORDER BY cvl.CreatedWhen
