DECLARE @sd DATETIME;
DECLARE @ed DATETIME;

SET @sd = '2014-01-01';
SET @ed = '2015-09-01';

DECLARE @denials_write_offs TABLE (
	pk INT IDENTITY(1, 1) PRIMARY KEY
	, pt_id               VARCHAR(MAX)
	, bill_no             VARCHAR(MAX)
	, denials             FLOAT
)
INSERT INTO @denials_write_offs
SELECT a.pt_id
, a.bill_no
, a.denials_woffs

FROM (
	SELECT pt_id
	, bill_no
	, SUM(tot_pay_adj_amt) AS denials_woffs

	FROM smsmir.mir_pay
	JOIN smsdss.c_Softmed_Denials_Detail_v 
	ON smsmir.mir_pay.pt_id = smsdss.c_Softmed_Denials_Detail_v.bill_no

	WHERE discharged >= @sd
	AND discharged < @ed
	AND LEFT(smsmir.mir_pay.pay_cd, 4) = '0974'

	GROUP BY pt_id
	, bill_no
) a

--SELECT * FROM @denials_write_offs
----------------------------------------------------------------------------------
SELECT *
INTO TmpTbl
FROM smsdss.c_Softmed_Denials_Detail_v;

ALTER TABLE TmpTbl
ADD PK INT IDENTITY(1,1) PRIMARY KEY;

SELECT visit_attend_phys
, Attend_Dr
, attend_dr_no
, Attend_Spclty
, CAST(TmpTbl.bill_no AS INT) AS bill_no
, last_name
, first_name
, rvw_date
, patient_type
, Initial_Denial
, appl_type
, appl_status
, Pending
, Finalized
, appl_dollars_appealed
, [1st_Lvl_Appealed_Ind]
, [2nd_Lvl_Appealed_Ind]
, s_cpm_Dollars_not_appealed
, No_Appeal
, appl_dollars_recovered
, [1st_Lvl_Recovery]
, DRA_Lvl_Recovery
, s_qm_subseq_appeal
, External_Appeal
, s_qm_subseq_appeal_date
, assoc_prvdr
, Denial_Dr
, Denial_Dr_No
, BMH_Specialty
, Denial_Spclty
, s_rvw_dnl_rsn
, v_financial_cls
, length_of_stay
, Short_Stay_Indicator
, Long_Stay_Indicator
, Short_Stay_Appeal_Indicator
, Long_Stay_Appeal_Indicator
, visit_admit_diag
, admit_diag_Description
, admission_date
, discharged
, Dsch_Yr
, Dsch_Mo
, pyr_cd
, pyr_seq_no
, pyr_name
, Appeal_Date
, YEAR(appeal_Date) AS [Appeal_Yr]
, Adm_Dx
, d.denials

FROM TmpTbl
LEFT OUTER JOIN @denials_write_offs d
ON TmpTbl.bill_no = d.pt_id

WHERE (
	TmpTbl.patient_type = 'I' 
	AND TmpTbl.discharged >= @SD
	AND TmpTbl.discharged < @ED
	)
OR (
	TmpTbl.patient_type IN ('E','O') 
	AND TmpTbl.admission_date >= @SD 
	AND TmpTbl.admission_date < @ED
	)

GROUP BY visit_attend_phys
, Attend_Dr
, attend_dr_no
, Attend_Spclty
, TmpTbl.bill_no
, last_name
, first_name
, rvw_date
, patient_type
, Initial_Denial
, appl_type
, appl_status
, Pending
, Finalized
, appl_dollars_appealed
, [1st_Lvl_Appealed_Ind]
, [2nd_Lvl_Appealed_Ind]
, s_cpm_Dollars_not_appealed
, No_Appeal
, appl_dollars_recovered
, [1st_Lvl_Recovery]
, DRA_Lvl_Recovery
, s_qm_subseq_appeal
, External_Appeal
, s_qm_subseq_appeal_date
, assoc_prvdr
, Denial_Dr
, Denial_Dr_No
, BMH_Specialty
, Denial_Spclty
, s_rvw_dnl_rsn
, v_financial_cls
, length_of_stay
, Short_Stay_Indicator
, Long_Stay_Indicator
, Short_Stay_Appeal_Indicator
, Long_Stay_Appeal_Indicator
, visit_admit_diag
, admit_diag_Description
, admission_date
, discharged
, Dsch_Yr
, Dsch_Mo
, pyr_cd
, pyr_seq_no
, pyr_name
, Appeal_Date
, YEAR(Appeal_Date)
, Adm_Dx
, d.denials
;

-- Drop the temp TABLE
DROP TABLE TmpTbl;