DECLARE @start DATE;
DECLARE @end DATE;

SET @start = '2022-01-01';
SET @end = '2022-10-01';

DROP TABLE

IF EXISTS #unique_mrns;
	CREATE TABLE #unique_mrns (med_rec_no VARCHAR(6))

INSERT INTO #unique_mrns (med_rec_no)
SELECT a.Med_Rec_No
FROM smsdss.BMH_PLM_PtAcct_V AS a
WHERE a.tot_chg_amt > 0
	AND left(a.ptno_num, 1) != '2'
	AND left(a.ptno_num, 4) != '1999'
	AND (
		(
			a.Plm_Pt_Acct_Type = 'i'
			AND a.Dsch_Date >= @start
			AND a.Dsch_Date < @end
			)
		OR (
			a.Plm_Pt_Acct_Type != 'i'
			AND a.Adm_Date >= @start
			AND a.Adm_Date < @end
			)
		)
	AND EXISTS (
		SELECT 1
		FROM smsmir.actv AS zzz
		WHERE zzz.pt_id = pt_no
			AND zzz.unit_seq_no = a.unit_seq_no
			AND zzz.actv_cd BETWEEN '05400000'
				AND '05499999'
		)
	AND left(a.dsch_disp, 1) NOT IN ('c', 'd')
GROUP BY a.Med_Rec_No;

SELECT a.med_rec_no,
	[distinct_mrn_flag] = CASE 
		WHEN row_number() OVER (
				PARTITION BY a.med_rec_no ORDER BY b.adm_date
				) = 1
			THEN 1
		ELSE 0
		END,
	b.PtNo_Num,
	cast(b.Adm_Date AS DATE) AS [Adm_Date],
	cast(b.Dsch_Date AS DATE) AS [Dsch_Date],
	b.Pt_Name,
	b.hosp_svc,
	upper(c.hosp_svc_name) AS [hosp_svc_name],
	D.pyr_group2
FROM #unique_mrns AS a
LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS b ON a.med_rec_no = b.Med_Rec_No
LEFT JOIN smsdss.hosp_svc_dim_v AS c ON b.hosp_svc = c.src_hosp_svc
	AND b.Regn_Hosp = c.orgz_cd
LEFT JOIN smsdss.pyr_dim_v AS D ON B.Pyr1_Co_Plan_Cd = D.src_pyr_cd
	AND B.Regn_Hosp = D.orgz_cd
WHERE NOT EXISTS (
		SELECT 1
		FROM smsdss.BMH_PLM_PtAcct_V AS zzz
		WHERE zzz.Med_Rec_No = a.med_rec_no
			AND zzz.hosp_svc IN ('dia', 'dms')
		)
	AND NOT EXISTS (
		SELECT 1
		FROM smsdss.BMH_PLM_PtAcct_V AS zzz
		WHERE zzz.Med_Rec_No = a.med_rec_no
			AND left(zzz.dsch_disp, 1) IN ('c', 'd')
		)
	--and left(b.dsch_disp, 1) not in ('c','d')
	AND b.tot_chg_amt > 0
	AND left(b.ptno_num, 1) != '2'
	AND left(b.ptno_num, 4) != '1999'
	AND (
		(
			b.Plm_Pt_Acct_Type = 'i'
			AND b.Dsch_Date >= @start
			AND b.Dsch_Date < @end
			)
		OR (
			b.Plm_Pt_Acct_Type != 'i'
			AND b.Adm_Date >= @start
			AND b.Dsch_Date < @end
			)
		);
