SELECT  
DISTINCT A1.pt_id AS [VISIT ID]
, A2.pt_id        AS [ID CHECK]
, A1.nurs_sta     AS [NURS STATION]
, A3.pt_st_addr   AS [STREET ADDRESS]

FROM smsdss.dly_cen_occ_fct_v A1
JOIN smsdss.vst_fct_v         A2
ON a1.pt_id = a2.pt_id
JOIN smsdss.pt_fct_v          A3
ON a2.pt_key = a3.pt_key

WHERE a1.nurs_sta = ''        -- ENTER NURSING STATATION
AND cen_date >= ''            -- ENTER START DATE
AND cen_date < ''             -- ENTER END DATE
AND A3.pt_st_addr LIKE '%%'   -- ENTER STREET ADDRESS