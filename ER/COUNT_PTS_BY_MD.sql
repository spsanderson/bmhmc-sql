-- This is a start for a working RVU report
--*********************************************************************************

-- Column Selection
SELECT DISTINCT s_ATTENDING_PHYS_LAST AS 'MD', COUNT(s_ATTENDING_PHYS_LAST)AS '# PT Seen'
    
-- Database USED: MEDHOST
FROM dbo.JTM_GENERIC_LIST_V

-- Filters
WHERE dt_arrival between '3/1/2013' and '4/1/2013'
	  GROUP BY s_ATTENDING_PHYS_LAST
	  ORDER BY COUNT(s_ATTENDING_PHYS_LAST)DESC

--*********************************************************************************
-- END REPORT
-- Sanderson, Steven 1.9.13
