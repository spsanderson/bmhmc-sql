-- Mitral_Valve_Repair
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
LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV ON SPROC.pt_id = PAV.PT_NO
	AND SPROC.from_file_ind = PAV.from_file_ind
CROSS APPLY (
	SELECT CASE 
			WHEN SPROC.proc_cd IN ('027G04Z', '027G0DZ', '027G0ZZ', '02CG0ZZ', '02NG0ZZ', '02QG0ZE', '02QG0ZZ', '02RG07Z', '02RG08Z', '02RG0JZ', '02RG0KZ', '02UG07E', '02UG07Z', '02UG08E', '02UG08Z', '02UG0JE', '02UG0JZ', '02UG0KE', '02UG0KZ', '02VG0ZZ')
				THEN 'Mitral_Valve_Repair'
			END AS [Surg_Type]
	) [Surgery]
WHERE SPROC.proc_cd IN (
		-- MITRAL VALVE REPAIR
		'027G04Z', '027G0DZ', '027G0ZZ', '02CG0ZZ', '02NG0ZZ', '02QG0ZE', '02QG0ZZ', '02RG07Z', '02RG08Z', '02RG0JZ', '02RG0KZ', '02UG07E', '02UG07Z', '02UG08E', '02UG08Z', '02UG0JE', '02UG0JZ', '02UG0KE', '02UG0KZ', '02VG0ZZ'
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
