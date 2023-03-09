-- Carotid Endarterctomy
SELECT SPROC.pt_id,
	CAST(SPROC.proc_eff_date AS DATE) AS [proc_eff_date],
	DATEPART(YEAR, SPROC.proc_eff_date) AS [Svc_Yr],
	DATEPART(MONTH, SPROC.proc_eff_date) AS [Svc_Mo],
	SPROC.proc_cd,
	SPROC_DESC.clasf_desc,
	SPROC.proc_cd_prio,
	SPROC.resp_pty_cd,
	UPPER(PDV.pract_rpt_name) AS [Provider_Name],
	Surgery.Surg_Type,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY SPROC.PT_ID ORDER BY SPROC.PT_ID,
			SPROC.PROC_CD_PRIO
		)
INTO #TEMPA
FROM smsmir.sproc AS SPROC
LEFT OUTER JOIN smsdss.proc_dim_v AS SPROC_DESC ON SPROC.proc_cd = SPROC_DESC.proc_cd
	AND SPROC.proc_cd_schm = SPROC_DESC.proc_cd_schm
LEFT OUTER JOIN smsdss.pract_dim_v AS PDV ON SPROC.resp_pty_cd = PDV.src_pract_no
	AND SPROC.orgz_cd = PDV.orgz_cd
LEFT OUTER JOIN SMSDSS.BMH_PLM_PTACCT_V AS PAV
ON SPROC.PT_ID = PAV.PT_NO
	
CROSS APPLY (
	SELECT CASE 
			WHEN SPROC.proc_cd IN ('03CH0ZZ', '03CJ0ZZ', '03CK0ZZ', '03CL0ZZ', '03CM0ZZ', '03CN0ZZ')
				THEN 'Carotid_Endarterectomy'
			END AS [Surg_Type]
	) [Surgery]
WHERE SPROC.proc_cd IN (
		-- CAROTID ENDARTERECTOMY
		'03CH0ZZ', '03CJ0ZZ', '03CK0ZZ', '03CL0ZZ', '03CM0ZZ', '03CN0ZZ'
		)
	AND SPROC.pt_id IN (
		SELECT DISTINCT (pt_id)
		FROM smsmir.dx_grp
		WHERE dx_cd IN ('I63.031', 'I63.032', 'I63.033', 'I63.039', 'I63.131', 'I63.132', 'I63.133', 'I63.139', 'I63.231', 'I63.232', 'I63.233', 'I63.239', 'I65.21', 'I65.22', 'I65.23', 'I65.29', 'I65.8', 'I65.9')
			AND LEFT(dx_cd_type, 2) = 'DF'
		)
	AND SPROC.proc_eff_date >= '2021-01-01'
	AND SPROC.proc_eff_date < '2022-01-01'
	AND PAV.Pt_Age >= 18
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
ORDER BY Surgery.Surg_Type,
	PDV.pract_rpt_name,
	SPROC.pt_id,
	SPROC.proc_cd_prio
GO

;

SELECT A.pt_id,
	A.proc_eff_date,
	A.Svc_Yr,
	A.Svc_Mo,
	A.proc_cd,
	A.clasf_desc,
	A.proc_cd_prio,
	A.resp_pty_cd,
	A.Provider_Name,
	A.Surg_Type
FROM #TEMPA AS A
WHERE A.RN = 1
GO

;

DROP TABLE #TEMPA
GO

;
