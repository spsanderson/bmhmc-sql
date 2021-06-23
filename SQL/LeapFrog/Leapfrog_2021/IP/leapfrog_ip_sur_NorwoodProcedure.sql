-- Norwood Procedure
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
LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV
ON SPROC.PT_ID = PAV.Pt_No
	AND SPROC.unit_seq_no = PAV.unit_seq_no
	AND SPROC.from_file_ind = PAV.from_file_ind

CROSS APPLY (
	SELECT
		CASE
			WHEN SPROC.proc_cd IN (
			'02UX07Z','02UX0JZ','02UX0KZ'
			)
		        THEN 'Arch_Repair'
            WHEN SPROC.PROC_CD IN (
            '021K08P','021K08Q','021K08R','021K09P','021K09Q',
            '021K09R','021K0AP','021K0AQ','021K0AR','021K0JP',
            '021K0JQ','021K0JR','021K0KP','021K0KQ','021K0KR',
            '021Q08A','021Q08B','021Q08D','021Q09A','021Q09B',
            '021Q09D','021Q0AA','021Q0AB','021Q0AD','021Q0JA',
            '021Q0JB','021Q0JD','021Q0KA','021Q0KB','021Q0KD',
            '021V0ZP','021V0ZQ','021V0ZR'
            )
                THEN 'Shunt_Repair'
        END AS [Surg_Type]
) [Surgery]

WHERE SPROC.proc_cd IN (
	-- Arch Repair
    '02UX07Z','02UX0JZ','02UX0KZ'
)
AND SPROC.pt_id IN (
    -- Shunt
	SELECT DISTINCT ZZZ.PT_ID
	FROM smsmir.sproc AS ZZZ
	WHERE ZZZ.PROC_CD IN (
    '021K08P','021K08Q','021K08R','021K09P','021K09Q',
    '021K09R','021K0AP','021K0AQ','021K0AR','021K0JP',
    '021K0JQ','021K0JR','021K0KP','021K0KQ','021K0KR',
    '021Q08A','021Q08B','021Q08D','021Q09A','021Q09B',
    '021Q09D','021Q0AA','021Q0AB','021Q0AD','021Q0JA',
    '021Q0JB','021Q0JD','021Q0KA','021Q0KB','021Q0KD',
    '021V0ZP','021V0ZQ','021V0ZR'
	)
)
AND SPROC.proc_eff_date >= '2020-01-01'
AND SPROC.proc_eff_date < '2021-01-01'
AND PAV.Pt_Age < 18
AND PAV.tot_chg_amt > 0
AND LEFT(PAV.PTNO_NUM, 1) != '2'

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
