WITH CTE AS (
SELECT *
, RN = ROW_NUMBER() OVER(PARTITION BY PYR_CD ORDER BY LAST_BILLED DESC)

FROM smsdss.c_bl_drg_schm_by_pyr_cd_v
)

SELECT *
, CASE
	WHEN bl_drg_schm LIKE '%MC%' THEN 'MS-DRG'
	WHEN bl_drg_schm LIKE '%ANY%' THEN 'APR-DRG'
	WHEN bl_drg_schm LIKE 'NY%' THEN 'AP-DRG'
	ELSE ''
  END AS DRG_SCHEME
FROM CTE AS A
WHERE A.RN = 1