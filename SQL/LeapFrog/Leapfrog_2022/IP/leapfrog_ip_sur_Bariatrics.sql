-- Bariatric
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
LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV ON SPROC.PT_ID = PAV.Pt_No
	AND SPROC.unit_seq_no = PAV.unit_seq_no
	AND SPROC.from_file_ind = PAV.from_file_ind
CROSS APPLY (
	SELECT CASE 
			WHEN SPROC.proc_cd IN ('0D16079', '0D1607A', '0D1607B', '0D160Z9', '0D160ZA', '0D160ZB', '0D16479', '0D1647A', '0D1647B', '0D164Z9', '0D164ZA', '0D164ZB', '0DB60Z3', '0DB60ZZ', '0DB63Z3', '0DB63ZZ', '0DB64Z3', '0DB64ZZ')
				THEN 'Bariatric_Surgery'
			END AS [Surg_Type]
	) [Surgery]
WHERE SPROC.proc_cd IN (
		-- BARIATRIC SURGERY
		'0D16079', '0D1607A', '0D1607B', '0D160Z9', '0D160ZA', '0D160ZB', '0D16479', '0D1647A', '0D1647B', '0D164Z9', '0D164ZA', '0D164ZB', '0DB60Z3', '0DB60ZZ', '0DB63Z3', '0DB63ZZ', '0DB64Z3', '0DB64ZZ'
		)
	AND SPROC.pt_id IN (
		SELECT DISTINCT (pt_id)
		FROM smsmir.dx_grp
		WHERE dx_cd IN ('E66.01', 'E66.09', 'E66.8', 'Z68.35', 'Z68.36', 'Z68.37', 'Z68.38', 'Z68.39', 'Z68.41', 'Z68.42', 'Z68.43', 'Z68.44', 'Z68.45')
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
