DECLARE @table1 TABLE (
	pk INT IDENTITY(1, 1) PRIMARY KEY
	, med_rec_no          CHAR(6)
	, encounter           CHAR(8)
	, pt_no               CHAR(12)
	, adm_date            DATE
	, dsch_date           DATE
	, los                 INT
	, user_pyr_cat        CHAR(3)
	, ins1                VARCHAR(3)
	, ins2                VARCHAR(3)
	, ins3                VARCHAR(3)
	, ins4                VARCHAR(4)
);

WITH cte1 AS (
	SELECT a.Med_Rec_No
	, a.PtNo_Num
	, a.Pt_No
	, a.Adm_Date
	, a.Dsch_Date
	, a.Days_Stay
	, a.User_Pyr1_Cat
	, a.Pyr1_Co_Plan_Cd
	, a.Pyr2_Co_Plan_Cd
	, a.Pyr3_Co_Plan_Cd
	, a.Pyr4_Co_Plan_Cd
	
	FROM smsdss.BMH_PLM_PtAcct_V AS a

	WHERE a.Dsch_Date >= '2016-01-01'
	AND a.Dsch_Date < '2016-07-01'
	AND a.hosp_svc = 'psy'
	AND a.tot_chg_amt > 0
)

INSERT INTO @table1
SELECT * FROM cte1

--SELECT * FROM @table1
---------------------------------------------------------------------------------------------------

SELECT pt_id
, pyr_seq_no
, pyr_cd
, bl_drg_schm
, pol_no
, reimb_amt
, tot_adj_amt
, tot_amt_due
, tot_cov_chg_amt
, tot_ded_amt
, tot_pay_amt
, tot_pol_cov_amt
, last_pay_amt
, last_pay_dtime
, subscr_ins_grp_name

FROM smsmir.pyr_plan AS a

WHERE (
	a.pt_id IN (
		SELECT zzz.pt_no
		FROM @table1 AS zzz
	)
	AND a.pyr_seq_no = 1
	AND a.tot_pay_amt < 0
	AND LEFT(a.pyr_cd, 1) = 'I'
)
OR a.pt_id IN (
	SELECT zzz.pt_no
		
	FROM @table1 AS zzz
	LEFT JOIN smsmir.pyr_plan AS ppp
	ON zzz.pt_no = ppp.pt_id
		
	WHERE (
		ppp.pyr_seq_no = 1
		AND ppp.tot_pay_amt = 0
		AND LEFT(ppp.pyr_cd, 1) != 'I'
	)
	AND (
		--------
		(
			ppp.pyr_seq_no = 2
			AND LEFT(ppp.pyr_cd, 1) = 'I'
		)
		OR
		(
			ppp.pyr_seq_no = 3
			AND LEFT(ppp.pyr_cd, 1) = 'I'
		)
		OR
		(
			ppp.pyr_seq_no = 4
			AND LEFT(ppp.pyr_cd, 1) = 'I'
		)
		---------
	)
)
AND pyr_seq_no != 0