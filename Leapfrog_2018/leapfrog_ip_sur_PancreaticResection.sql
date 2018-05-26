-- Pancreatic_Resection
SELECT SPROC.pt_id
, CAST(SPROC.proc_eff_date AS date) AS [proc_eff_date]
, DATEPART(YEAR, SPROC.proc_eff_date) AS [Svc_Yr]
, DATEPART(MONTH, SPROC.proc_eff_date) AS [Svc_Mo]
, SPROC.proc_cd
, SPROC_DESC.clasf_desc
, SPROC.proc_cd_prio
, SPROC.resp_pty_cd
, UPPER(PDV.pract_rpt_name) AS [Provider_Name]
, Surgery.Surg_Type
, [RN] = ROW_NUMBER() OVER(PARTITION BY SPROC.PT_ID ORDER BY SPROC.PT_ID, SPROC.PROC_CD_PRIO)

INTO #TEMPA

FROM smsmir.sproc AS SPROC
LEFT OUTER JOIN smsdss.proc_dim_v AS SPROC_DESC
ON SPROC.proc_cd = SPROC_DESC.proc_cd
AND SPROC.proc_cd_schm = SPROC_DESC.proc_cd_schm
LEFT OUTER JOIN smsdss.pract_dim_v AS PDV
ON SPROC.resp_pty_cd = PDV.src_pract_no
AND SPROC.orgz_cd = PDV.orgz_cd

CROSS APPLY (
	SELECT
		CASE
			WHEN SPROC.proc_cd IN (
				'0DB90ZZ','0DB93ZZ','0DB94ZZ','0DT90ZZ','0DT94ZZ',
				'0FBG0ZZ','0FBG3ZZ','0FBG4ZZ','0FTG0ZZ','0FTG4ZZ',
				'0DB97ZZ','0DB98ZZ','0DT97ZZ','0DT98ZZ'
			)
		THEN 'Pancreatic_Resection'
	END AS [Surg_Type]
) [Surgery]

WHERE SPROC.proc_cd IN (
	-- PANCREATIC RESECTION for cancer
	'0DB90ZZ','0DB93ZZ','0DB94ZZ','0DT90ZZ','0DT94ZZ',
	'0FBG0ZZ','0FBG3ZZ','0FBG4ZZ','0FTG0ZZ','0FTG4ZZ',
	'0DB97ZZ','0DB98ZZ','0DT97ZZ','0DT98ZZ'
)
AND SPROC.pt_id IN (
	SELECT distinct(pt_id)
	FROM smsmir.dx_grp
	WHERE dx_cd IN (
		'C17.0','C24.0','C24.1','C24.8','C24.9','C25.0',
		'C25.1','C25.3','C25.4','C25.7','C25.8','C25.9'
	)
	AND LEFT(dx_cd_type, 2) = 'DF'
)
AND SPROC.proc_eff_date >= '2016-01-01'
AND SPROC.proc_eff_date < '2018-01-01'

ORDER BY Surgery.Surg_Type
, PDV.pract_rpt_name
, SPROC.pt_id
, SPROC.proc_cd_prio

GO
;

SELECT A.pt_id
, A.proc_eff_date
, A.Svc_Yr
, A.Svc_Mo
, A.proc_cd
, A.clasf_desc
, A.proc_cd_prio
, A.resp_pty_cd
, A.Provider_Name
, A.Surg_Type

FROM #TEMPA AS A

WHERE A.RN = 1

GO
;

DROP TABLE #TEMPA
GO
;
