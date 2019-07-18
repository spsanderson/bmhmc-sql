SELECT GEO.Encounter
, GEO.FullAddress
, GEO.lon
, GEO.lat
, LIHN.LIHN_Svc_Line
, APR.SEVERITY_OF_ILLNESS
, APR.RISK_OF_MORTALITY
, APR.DAYSSTAY
, 1 AS [Encounter_Flag]

FROM smsdss.C_GEOCODED_ADDRESS AS GEO
INNER JOIN smsdss.c_LIHN_Svc_Line_Tbl AS LIHN
ON GEO.ENCOUNTER = LIHN.ENCOUNTER
INNER JOIN Customer.Custom_DRG AS APR
ON GEO.ENCOUNTER = APR.PATIENT#