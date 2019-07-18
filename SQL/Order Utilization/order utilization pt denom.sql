SELECT A.PtNo_Num
, A.Atn_Dr_No
, C.pract_rpt_name
, CASE 
	WHEN D.Disposition IN (
		'LWBS'   -- Left Without Being Seen
		, 'LABS' -- Left After Being Seen by MD but before Discharge
		, 'AMA'  -- Left Against Medical Advice
	)
		THEN 1
		ELSE 0
  END AS [ED Walkout]
, CASE
	WHEN D.Account IS NOT NULL
	AND D.Disposition != 'Admit'
	AND LEFT(D.Account, 1) = '1'
		THEN 1
		ELSE 0
  END AS [ED_Admit_but_Left]
, CASE
	WHEN B.PT_ID IS NOT NULL
	AND LEFT(B.PT_ID, 1) = '1'
		THEN 1
		ELSE 0
  END AS [Observation_Xfr]
, CASE
	WHEN D.Account IS NOT NULL 
		AND D.Disposition = 'Admit'
		THEN 1
		ELSE 0
  END AS [ED_Admit]
, DATEPART(YEAR, A.Adm_Date)                 AS [Arrival_Year]
, DATEDIFF(HOUR, D.Arrival, A.vst_end_dtime) AS [Hours_At_Hosp]
, D.Disposition                              AS [ED_Dispo]
, A.dsch_disp                                AS [Coded_Dispo]

INTO #ip_case_count_a

FROM smsdss.bmh_plm_ptacct_v              AS A
LEFT OUTER JOIN smsdss.c_obv_Comb_1       AS B
ON A.PtNo_Num = B.pt_id
LEFT OUTER JOIN smsdss.pract_dim_v        AS C
ON A.Atn_Dr_No = C.src_pract_no
	AND C.orgz_cd = 'S0X0'
LEFT OUTER JOIN smsdss.c_Wellsoft_Rpt_tbl AS D
ON A.PtNo_Num = D.Account

--WHERE A.PtNo_Num = '14244396'
--WHERE A.PTNO_NUM = '14192462'
WHERE A.Adm_Date >= '2013-01-01'
AND A.Adm_Date < '2016-01-01'
AND A.tot_chg_amt > 0
AND A.Plm_Pt_Acct_Type = 'I'

-----------------------------------------------------------------------

SELECT *
, CASE
	WHEN (
	(
		AA.[ED Walkout] = 0
		AND
		AA.ED_Admit_but_Left = 0
	)
		AND 
	(
		AA.Observation_Xfr = 1
		OR
		AA.ED_Admit = 1
	)
)
		THEN 1
		ELSE 0
  END AS [True_Admit]


FROM #ip_case_count_a AA

DROP TABLE #ip_case_count_a