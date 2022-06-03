-- Total HIP
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
			WHEN SPROC.proc_cd IN ('0SR9019', '0SR901A', '0SR901Z', '0SR9029', '0SR902A ', '0SR902Z', '0SR9039', '0SR903A', '0SR903Z', '0SR9049', '0SR904A', '0SR904Z', '0SR90J9 ', '0SR90JA', '0SR90JZ', '0SRA009', '0SRA00A', '0SRA00Z', '0SRA019', '0SRA01A', '0SRA01Z', '0SRA039', '0SRA03A', '0SRA03Z', '0SRA0J9', '0SRA0JA', '0SRA0JZ', '0SRB019', '0SRB01A', '0SRB01Z', '0SRB029 ', '0SRB02A', '0SRB02Z', '0SRB039', '0SRB03A', '0SRB03Z', '0SRB049', '0SRB04A', '0SRB04Z', '0SRB0J9', '0SRB0JA ', '0SRB0JZ', '0SRE009', '0SRE00A', '0SRE00Z', '0SRE019', '0SRE01A', '0SRE01Z', '0SRE039', '0SRE03A', '0SRE03Z', '0SRE0J9', '0SRE0JA', '0SRE0JZ', '0SR9069', '0SR906A', '0SR906Z', '0SRB069', '0SRB06A', '0SRB06Z')
				THEN 'Total_Hip_Replacement'
			END AS [Surg_Type]
	) [Surgery]
WHERE SPROC.proc_cd IN (
		-- Total Hip surgery
		'0SR9019', '0SR901A', '0SR901Z', '0SR9029', '0SR902A ', '0SR902Z', '0SR9039', '0SR903A', '0SR903Z', '0SR9049', '0SR904A', '0SR904Z', '0SR90J9 ', '0SR90JA', '0SR90JZ', '0SRA009', '0SRA00A', '0SRA00Z', '0SRA019', '0SRA01A', '0SRA01Z', '0SRA039', '0SRA03A', '0SRA03Z', '0SRA0J9', '0SRA0JA', '0SRA0JZ', '0SRB019', '0SRB01A', '0SRB01Z', '0SRB029 ', '0SRB02A', '0SRB02Z', '0SRB039', '0SRB03A', '0SRB03Z', '0SRB049', '0SRB04A', '0SRB04Z', '0SRB0J9', '0SRB0JA ', '0SRB0JZ', '0SRE009', '0SRE00A', '0SRE00Z', '0SRE019', '0SRE01A', '0SRE01Z', '0SRE039', '0SRE03A', '0SRE03Z', '0SRE0J9', '0SRE0JA', '0SRE0JZ', '0SR9069', '0SR906A', '0SR906Z', '0SRB069', '0SRB06A', '0SRB06Z'
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
