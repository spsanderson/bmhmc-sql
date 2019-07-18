-- Lung_Resection
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
				'0BBC0ZZ','0BBC3ZZ','0BBC4ZZ','0BBD0ZZ','0BBD3ZZ',
				'0BBD4ZZ','0BBF0ZZ','0BBF3ZZ','0BBF4ZZ','0BBG0ZZ',
				'0BBG3ZZ','0BBG4ZZ','0BBH0ZZ','0BBH3ZZ','0BBH4ZZ',
				'0BBJ0ZZ','0BBJ3ZZ','0BBJ4ZZ','0BBK0ZZ','0BBK3ZZ',
				'0BBK4ZZ','0BBL0ZZ','0BBL3ZZ','0BBL4ZZ','0BBL7ZZ',
				'0BTC0ZZ','0BTC4ZZ','0BTD0ZZ','0BTD4ZZ','0BTF0ZZ',
				'0BTF4ZZ','0BTG0ZZ','0BTG4ZZ','0BTH0ZZ','0BTH4ZZ',
				'0BTJ0ZZ','0BTJ4ZZ','0BTK0ZZ','0BTK4ZZ','0BTL0ZZ',
				'0BTL4ZZ'
			)
		THEN 'Lung_Resection'
	END AS [Surg_Type]
) [Surgery]

WHERE SPROC.proc_cd IN (
	-- LUNG RESECTION
	'0BBC0ZZ','0BBC3ZZ','0BBC4ZZ','0BBD0ZZ','0BBD3ZZ',
	'0BBD4ZZ','0BBF0ZZ','0BBF3ZZ','0BBF4ZZ','0BBG0ZZ',
	'0BBG3ZZ','0BBG4ZZ','0BBH0ZZ','0BBH3ZZ','0BBH4ZZ',
	'0BBJ0ZZ','0BBJ3ZZ','0BBJ4ZZ','0BBK0ZZ','0BBK3ZZ',
	'0BBK4ZZ','0BBL0ZZ','0BBL3ZZ','0BBL4ZZ','0BBL7ZZ',
	'0BTC0ZZ','0BTC4ZZ','0BTD0ZZ','0BTD4ZZ','0BTF0ZZ',
	'0BTF4ZZ','0BTG0ZZ','0BTG4ZZ','0BTH0ZZ','0BTH4ZZ',
	'0BTJ0ZZ','0BTJ4ZZ','0BTK0ZZ','0BTK4ZZ','0BTL0ZZ',
	'0BTL4ZZ'
)
AND SPROC.pt_id IN (
	SELECT distinct(pt_id)
	FROM smsmir.dx_grp
	WHERE dx_cd IN (
		'C34.00','C34.01','C34.02','C34.10','C34.11',
		'C34.12','C34.2','C34.30','C34.31','C34.32',
		'C34.80','C34.81','C34.82','C34.90','C34.91',
		'C34.92'
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
