-- Total Knee
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
				'0SRC0J9','0SRC0JA','0SRC0JZ','0SRD0J9','0SRD0JA',
                '0SRD0JZ','0SRT0J9','0SRT0JA','0SRT0JZ','0SRU0J9',
                '0SRU0JA','0SRU0JZ','0SRV0J9','0SRV0JA','0SRV0JZ',
                '0SRW0J9','0SRW0JA','0SRW0JZ','0SRC069','0SRC06A',
                '0SRC06Z','0SRD069','0SRD06A','0SRD06Z'
			)
		THEN 'Total_Knee_Replacement'
	END AS [Surg_Type]
) [Surgery]

WHERE SPROC.proc_cd IN (
	-- Total Knee surgery
    '0SRC0J9','0SRC0JA','0SRC0JZ','0SRD0J9','0SRD0JA',
    '0SRD0JZ','0SRT0J9','0SRT0JA','0SRT0JZ','0SRU0J9',
    '0SRU0JA','0SRU0JZ','0SRV0J9','0SRV0JA','0SRV0JZ',
    '0SRW0J9','0SRW0JA','0SRW0JZ','0SRC069','0SRC06A',
    '0SRC06Z','0SRD069','0SRD06A','0SRD06Z'
)
AND SPROC.proc_eff_date >= '2020-01-01'
AND SPROC.proc_eff_date < '2021-01-01'
AND PAV.Pt_Age >= 18
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