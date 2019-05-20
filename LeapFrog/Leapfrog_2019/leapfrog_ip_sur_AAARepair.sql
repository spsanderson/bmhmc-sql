-- AAA_Repair
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
LEFT OUTER JOIN SMSDSS.BMH_PLM_PTACCT_V AS PAV ON SPROC.PT_ID = PAV.PT_NO
	AND SPROC.from_file_ind = PAV.from_file_ind
	AND SPROC.unit_seq_no = PAV.unit_seq_no
CROSS APPLY (
	SELECT CASE 
			WHEN SPROC.proc_cd IN (
					'0410090', '0410091', '0410092', '0410093', '0410094', '0410095', '0410096', 
					'0410097', '0410098', '0410099', '021W08B', '021W08D', '021W08F', '021W08G', 
					'021W08H', '021W08P', '021W08Q', '021W08R', '021W08V', '021W09B', '021W09D', 
					'021W09F', '021W09G', '021W09H', '021W09P', '021W09Q', '021W09R', '021W09V', 
					'021W0AB', '021W0AD', '021W0AF', '021W0AG', '021W0AH', '021W0AP', '021W0AQ', 
					'021W0AR', '021W0AV', '021W0JB', '021W0JD', '021W0JF', '021W0JG', '021W0JH', 
					'021W0JP', '021W0JQ', '021W0JR', '021W0JV', '021W0KB', '021W0KD', '021W0KF', 
					'021W0KG', '021W0KH', '021W0KP', '021W0KQ', '021W0KR', '021W0KV', '021W0ZB', 
					'021W0ZD', '021W0ZP', '021W0ZQ', '021W0ZR', '02BW0ZX', '02BW0ZZ', '02CW0ZZ', 
					'02QW0ZZ', '02RW07Z', '02RW08Z', '02RW0JZ', '02RW0KZ', '02SW0ZZ', '02UW07Z', 
					'02UW08Z', '02UW0JZ', '02UW0KZ', '02VW0ZZ', '041009B', '041009C', '041009D', 
					'041009F', '041009G', '041009H', '041009J', '041009K', '041009Q', '041009R', 
					'04100A0', '04100A1', '04100A2', '04100A3', '04100A4', '04100A5', '04100A6', 
					'04100A7', '04100A8', '04100A9', '04100AB', '04100AC', '04100AD', '04100AF',
					'04100AG', '04100AH', '04100AJ', '04100AK', '04100AQ', '04100AR', '04100J0', 
					'04100J1', '04100J2', '04100J3', '04100J4', '04100J5', '04100J6', '04100J7', 
					'04100J8', '04100J9', '04100JB', '04100JC', '04100JD', '04100JF', '04100JG', 
					'04100JH', '04100JJ', '04100JK', '04100JQ', '04100JR', '04100K0', '04100K1', 
					'04100K2', '04100K3', '04100K4', '04100K5', '04100K6', '04100K7', '04100K8', 
					'04100K9', '04100KB', '04100KC', '04100KD', '04100KF', '04100KG', '04100KH', 
					'04100KJ', '04100KK', '04100KQ', '04100KR', '04100Z0', '04100Z1', '04100Z2', 
					'04100Z3', '04100Z4', '04100Z5', '04100Z6', '04100Z7', '04100Z8', '04100Z9', 
					'04100ZB', '04100ZC', '04100ZD', '04100ZF', '04100ZG', '04100ZH', '04100ZJ', 
					'04100ZK', '04100ZQ', '04100ZR', '041C090', '041C0A0', '041C0J0', '041C0K0', 
					'041C0Z0', '041D090', '041D0A0', '041D0J0', '041D0K0', '041D0Z0', '04B00ZX', 
					'04B00ZZ', '04C00Z6', '04C00ZZ', '04L00ZZ', '04Q00ZZ', '04R007Z', '04R00JZ', 
					'04R00KZ', '04U007Z', '04U00JZ', '04U00KZ'
					)
				THEN 'AAA_Repair'
			END AS [Surg_Type]
	) [Surgery]
WHERE SPROC.proc_cd IN (
		-- AAA REPAIR
		'0410090', '0410091', '0410092', '0410093', '0410094', '0410095', '0410096', 
		'0410097', '0410098', '0410099', '021W08B', '021W08D', '021W08F', '021W08G', 
		'021W08H', '021W08P', '021W08Q', '021W08R', '021W08V', '021W09B', '021W09D', 
		'021W09F', '021W09G', '021W09H', '021W09P', '021W09Q', '021W09R', '021W09V', 
		'021W0AB', '021W0AD', '021W0AF', '021W0AG', '021W0AH', '021W0AP', '021W0AQ', 
		'021W0AR', '021W0AV', '021W0JB', '021W0JD', '021W0JF', '021W0JG', '021W0JH', 
		'021W0JP', '021W0JQ', '021W0JR', '021W0JV', '021W0KB', '021W0KD', '021W0KF', 
		'021W0KG', '021W0KH', '021W0KP', '021W0KQ', '021W0KR', '021W0KV', '021W0ZB', 
		'021W0ZD', '021W0ZP', '021W0ZQ', '021W0ZR', '02BW0ZX', '02BW0ZZ', '02CW0ZZ', 
		'02QW0ZZ', '02RW07Z', '02RW08Z', '02RW0JZ', '02RW0KZ', '02SW0ZZ', '02UW07Z', 
		'02UW08Z', '02UW0JZ', '02UW0KZ', '02VW0ZZ', '041009B', '041009C', '041009D', 
		'041009F', '041009G', '041009H', '041009J', '041009K', '041009Q', '041009R', 
		'04100A0', '04100A1', '04100A2', '04100A3', '04100A4', '04100A5', '04100A6', 
		'04100A7', '04100A8', '04100A9', '04100AB', '04100AC', '04100AD', '04100AF',
		'04100AG', '04100AH', '04100AJ', '04100AK', '04100AQ', '04100AR', '04100J0', 
		'04100J1', '04100J2', '04100J3', '04100J4', '04100J5', '04100J6', '04100J7', 
		'04100J8', '04100J9', '04100JB', '04100JC', '04100JD', '04100JF', '04100JG', 
		'04100JH', '04100JJ', '04100JK', '04100JQ', '04100JR', '04100K0', '04100K1', 
		'04100K2', '04100K3', '04100K4', '04100K5', '04100K6', '04100K7', '04100K8', 
		'04100K9', '04100KB', '04100KC', '04100KD', '04100KF', '04100KG', '04100KH', 
		'04100KJ', '04100KK', '04100KQ', '04100KR', '04100Z0', '04100Z1', '04100Z2', 
		'04100Z3', '04100Z4', '04100Z5', '04100Z6', '04100Z7', '04100Z8', '04100Z9', 
		'04100ZB', '04100ZC', '04100ZD', '04100ZF', '04100ZG', '04100ZH', '04100ZJ', 
		'04100ZK', '04100ZQ', '04100ZR', '041C090', '041C0A0', '041C0J0', '041C0K0', 
		'041C0Z0', '041D090', '041D0A0', '041D0J0', '041D0K0', '041D0Z0', '04B00ZX', 
		'04B00ZZ', '04C00Z6', '04C00ZZ', '04L00ZZ', '04Q00ZZ', '04R007Z', '04R00JZ', 
		'04R00KZ', '04U007Z', '04U00JZ', '04U00KZ'
		)
	AND SPROC.pt_id IN (
		SELECT DISTINCT (pt_id)
		FROM smsmir.dx_grp
		WHERE dx_cd IN ('I71.3', 'I71.4', 'I71.5', 'I71.6', 'I71.8', 'I71.9')
			AND LEFT(dx_cd_type, 2) = 'DF'
		)
	AND SPROC.proc_eff_date >= '2018-01-01'
	AND SPROC.proc_eff_date < '2019-01-01'
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
