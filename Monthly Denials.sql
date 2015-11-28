DECLARE @sd DATETIME;
DECLARE @ed DATETIME;

SET @sd = '2013-01-01';
SET @ed = '2015-10-01';

DECLARE @denials_write_offs TABLE (
	pk INT IDENTITY(1, 1) PRIMARY KEY
	, pt_id               INT
	, bill_no             INT
	, denials             FLOAT
)
INSERT INTO @denials_write_offs
SELECT a.pt_id
, a.bill_no
, a.denials_woffs

FROM (
	SELECT CAST(pt_id AS INT) pt_id
	, CAST(bill_no AS INT) bill_no
	, SUM(tot_pay_adj_amt) AS denials_woffs

	FROM smsmir.mir_pay
	JOIN smsdss.c_Softmed_Denials_Detail_v 
	ON smsmir.mir_pay.pt_id = smsdss.c_Softmed_Denials_Detail_v.bill_no

	WHERE discharged >= @sd
	AND discharged < @ed
	AND LEFT(smsmir.mir_pay.pay_cd, 4) = '0974'

	GROUP BY pt_id
	, bill_no
) A

--SELECT * FROM @denials_write_offs
-----------------------------------------------------------------------
DECLARE @USERTBL TABLE (
	LOGIN_ID    VARCHAR(MAX)
	, END_DTIME DATETIME
	, USERNAME  VARCHAR(MAX)
	, RN INT
)

INSERT INTO @USERTBL
SELECT  C.*
FROM (
	SELECT LOGIN_ID
	, END_DTIME
	, username
	, RN =ROW_NUMBER() OVER(PARTITION BY LOGIN_ID ORDER BY END_DTIME DESC)

	FROM SMSMIR.mir_user_mstr
) C

-----------------------------------------------------------------------
DECLARE @EDTBL TABLE (
	ACCOUNT INT
	, ED_MD VARCHAR(MAX)
)

INSERT INTO @EDTBL
SELECT Z.*
FROM (
	SELECT CAST(ACCOUNT AS INT) ACCOUNT
	, ED_MD
	
	FROM SMSDSS.c_Wellsoft_Rpt_tbl
) Z

--SELECT * FROM @EDTBL
-----------------------------------------------------------------------
DECLARE @TmpDenialsTbl TABLE (
	PK INT IDENTITY(1, 1)         PRIMARY KEY
	, BILL_NO                     INT
	, VISIT_ATTEND_PHYS           VARCHAR(MAX)
	, ATTEND_DR                   VARCHAR(MAX)
	, ATTEND_DR_NO                VARCHAR(MAX)
	, ATTEND_SPCLTY               VARCHAR(MAX)
	, LAST_NAME                   VARCHAR(MAX)
	, FIRST_NAME                  VARCHAR(MAX)
	, RVW_DATE                    DATETIME
	, PATIENT_TYPE                VARCHAR(2)
	, INITIAL_DENIAL              VARCHAR(2)
	, APPL_TYPE                   VARCHAR(3)
	, APPL_STATUS                 VARCHAR(5)
	, PENDING                     INT
	, FINALIZED                   INT
	, APPL_DOLLARS_APPEALED       VARCHAR(MAX)
	, [1st_Lvl_Appealed_Ind]      VARCHAR(MAX)
	, [2nd_Lvl_Appealed_Ind]      VARCHAR(MAX)
	, s_cpm_Dollars_not_appealed  VARCHAR(MAX)
	, No_Appeal                   VARCHAR(MAX)
	, appl_dollars_recovered      VARCHAR(MAX)
	, [1st_Lvl_Recovery]          VARCHAR(MAX)
	, DRA_Lvl_Recovery            VARCHAR(MAX)
	, s_qm_subseq_appeal          VARCHAR(MAX)
	, External_Appeal             VARCHAR(MAX)
	, s_qm_subseq_appeal_date     VARCHAR(MAX)
	, assoc_prvdr                 VARCHAR(MAX)
	, Denial_Dr                   VARCHAR(MAX)
	, Denial_Dr_No                VARCHAR(MAX)
	, BMH_Specialty               VARCHAR(MAX)
	, Denial_Spclty               VARCHAR(MAX)
	, s_rvw_dnl_rsn               VARCHAR(MAX)
	, v_financial_cls             VARCHAR(MAX)
	, length_of_stay              VARCHAR(MAX)
	, Short_Stay_Indicator        VARCHAR(MAX)
	, Long_Stay_Indicator         VARCHAR(MAX)
	, Short_Stay_Appeal_Indicator VARCHAR(MAX)
	, Long_Stay_Appeal_Indicator  VARCHAR(MAX)
	, visit_admit_diag            VARCHAR(MAX)
	, admit_diag_Description      VARCHAR(MAX)
	, admission_date              VARCHAR(MAX)
	, discharged                  VARCHAR(MAX)
	, Dsch_Yr                     VARCHAR(MAX)
	, Dsch_Mo                     VARCHAR(MAX)
	, pyr_cd                      VARCHAR(MAX)
	, pyr_seq_no                  VARCHAR(MAX)
	, pyr_name                    VARCHAR(MAX)
	, Appeal_Date                 VARCHAR(MAX)
	, [Appeal_Yr]                 VARCHAR(MAX)
	, Adm_Dx                      VARCHAR(MAX)
	, cerm_rvwr_id                VARCHAR(MAX)
)

INSERT INTO @TmpDenialsTbl
SELECT *
FROM (
	SELECT bill_no
	, visit_attend_phys
	, Attend_Dr
	, attend_dr_no
	, Attend_Spclty
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
	, cerm_rvwr_id

	FROM smsdss.c_Softmed_Denials_Detail_v
) B

--SELECT * FROM @TmpDenialsTbl
-----------------------------------------------------------------------

SELECT a.BILL_NO as tmbptbl_bill_no
, d.bill_no as denials_bill_no
, c.Account as wellsfoft_bill_no
, a.VISIT_ATTEND_PHYS
, a.ATTEND_DR
, a.ATTEND_DR_NO
, a.ATTEND_SPCLTY
, c.ED_MD
, a.LAST_NAME
, a.FIRST_NAME
, a.RVW_DATE
, a.PATIENT_TYPE
, a.INITIAL_DENIAL
, a.APPL_TYPE
, a.APPL_STATUS
, a.PENDING
, a.FINALIZED
, a.APPL_DOLLARS_APPEALED
, a.[1st_Lvl_Appealed_Ind]
, a.[2nd_Lvl_Appealed_Ind]
, a.s_cpm_Dollars_not_appealed
, a.No_Appeal
, a.appl_dollars_recovered
, a.[1st_Lvl_Recovery]
, a.DRA_Lvl_Recovery
, a.s_qm_subseq_appeal
, a.External_Appeal
, a.s_qm_subseq_appeal_date
, a.assoc_prvdr
, a.Denial_Dr
, a.Denial_Dr_No
, a.BMH_Specialty
, a.Denial_Spclty
, a.s_rvw_dnl_rsn
, a.v_financial_cls
, a.length_of_stay
, a.Short_Stay_Indicator
, a.Long_Stay_Indicator
, a.Short_Stay_Appeal_Indicator
, a.Long_Stay_Appeal_Indicator
, a.visit_admit_diag
, a.admit_diag_Description
, a.admission_date
, a.discharged
, a.Dsch_Yr
, a.Dsch_Mo
, a.pyr_cd
, a.pyr_seq_no
, a.pyr_name
, a.Appeal_Date
, YEAR(a.appeal_date) AS [Appeal_Year]
, a.Adm_Dx
, d.denials
, a.cerm_rvwr_id
, F.username
, F.RN

FROM @TmpDenialsTbl                       A
LEFT OUTER JOIN @denials_write_offs       D
ON A.bill_no = d.pt_id
LEFT OUTER JOIN @EDTBL                    C
ON A.bill_no = C.Account
LEFT OUTER JOIN @USERTBL                  F
ON A.CERM_RVWR_ID = F.login_id
	AND F.RN = 1

WHERE (
		(
	A.patient_type = 'I' 
	AND A.discharged >= @SD
	AND A.discharged < @ED
		)
	OR
	   (
	A.patient_type IN ('E','O') 
	AND A.discharged >= @SD 
	AND A.discharged < @ED
		)
	)
