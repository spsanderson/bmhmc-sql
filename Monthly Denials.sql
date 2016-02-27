DECLARE @SD DATETIME;
DECLARE @ED DATETIME;

SET @SD = '2013-01-01';
SET @ED = '2016-01-01';

DECLARE @InpatientDenials TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, pt_id               INT
	, bill_no             INT
	, denials             FLOAT
)

INSERT INTO @InpatientDenials
SELECT a.pt_id
, a.bill_no
, a.denials_woffs

FROM (
	SELECT CAST(pt_id AS INT) AS pt_id
	, CAST(bill_no AS INT)    AS bill_no
	, SUM(tot_pay_adj_amt)    AS denials_woffs

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
-- OUTPATIENT DENIALS WRITEOFFS
DECLARE @OUTPATIENT_DENIALS TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, pt_id               INT
	, bill_no             INT
	, denials             FLOAT
)

INSERT INTO @OUTPATIENT_DENIALS
SELECT B.*
FROM (
	SELECT CAST(pt_id AS INT) AS pt_id
	, CAST(bill_no AS INT)    AS bill_no
	, SUM(tot_pay_adj_amt)    AS Outpatient_Denials

	FROM smsmir.mir_pay
	JOIN smsdss.c_Softmed_Denials_Detail_v
	ON smsmir.mir_pay.pt_id = smsdss.c_Softmed_Denials_Detail_v.bill_no

	WHERE patient_type IN ('E', 'O')
	AND admission_date >= @SD
	AND admission_date < @ED
	AND LEFT(smsmir.mir_pay.pay_cd, 4) = '0974'

	GROUP BY pt_id
	, bill_no
) B

-- SELECT * FROM @OUTPATIENT_DENIALS
-----------------------------------------------------------------------
DECLARE @USERTBL TABLE (
	LOGIN_ID    VARCHAR(MAX)
	, END_DTIME DATETIME
	, USERNAME  VARCHAR(MAX)
	, RN        INT
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
SELECT D.*
FROM (
	SELECT CAST(ACCOUNT AS INT) ACCOUNT
	, ED_MD
	
	FROM SMSDSS.c_Wellsoft_Rpt_tbl
) D

--SELECT * FROM @EDTBL

-----------------------------------------------------------------------
-- GET THE DRG NUMBER FOR THE CASE
DECLARE @DRG TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, ENCOUNTER INT
	, DRG       VARCHAR(3)
	, DRG_NAME  VARCHAR(MAX)
)

INSERT INTO @DRG
SELECT DRG.*
FROM (
	SELECT PLM.PtNo_Num
	, PLM.drg_no
	, DRGV.std_drg_name_modf

	FROM SMSDSS.BMH_PLM_PTACCT_V PLM
	LEFT OUTER JOIN SMSDSS.drg_dim_v AS DRGV
	ON PLM.drg_no = DRGV.drg_no

	WHERE Dsch_Date >= @SD
	AND Dsch_Date < @ED
	AND DRGV.drg_vers = 'MS-V25'
) DRG

-----------------------------------------------------------------------
-- Outpatients
DECLARE @OutPatient TABLE (
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
	-- Add Admit Year and Month SPS 2/16/2016
	, Adm_Yr                      VARCHAR(2)
	, Adm_Month                   VARCHAR(2)
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
	, RN                          INT
)

INSERT INTO @OutPatient
SELECT O.*
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
	-- Add Admit Year and Month SPS 2/16/2016
	, YEAR(admission_Date) as Adm_Yr
	, MONTH(admission_date) as Adm_Month
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
	, RN = ROW_NUMBER() OVER(PARTITION BY BILL_NO ORDER BY ADMISSION_DATE)

	FROM smsdss.c_Softmed_Denials_Detail_v
	
	WHERE patient_type IN ('E', 'O')
	AND admission_date >= @SD
	AND admission_date < @ED

) O

-----------------------------------------------------------------------
DECLARE @TmpDenialsTbl TABLE (
	PK INT IDENTITY(1, 1)         PRIMARY KEY
	, BILL_NO                     INT
	, VISIT_ATTEND_PHYS           VARCHAR(MAX)
	, ATTEND_DR                   VARCHAR(MAX)
	, ATTEND_DR_NO                VARCHAR(MAX)
	, ATTEND_SPCLTY               VARCHAR(MAX)
	, ADM_DR_NO                   VARCHAR(MAX)
	, ADM_DR                      VARCHAR(MAX)
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
	-- Add Admit Year and Month SPS 2/16/2016
	, Adm_Yr                      VARCHAR(2)
	, Adm_Month                   VARCHAR(2)
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
SELECT I.*
FROM (
	SELECT bill_no
	, visit_attend_phys
	, Attend_Dr
	, attend_dr_no
	, Attend_Spclty
	-- add Admitting Phys
	, Adm_Dr_No
	, C.pract_rpt_name
	-- end edit
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
	-- Add Admit Year and Month SPS 2/16/2016
	, YEAR(admission_date) as Adm_Yr
	, MONTH(admission_date) as Adm_Month
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
	LEFT OUTER JOIN smsdss.BMH_PLM_PTACCT_V
	ON smsdss.c_Softmed_Denials_Detail_v.bill_no = smsdss.BMH_PLM_PtAcct_V.PtNo_Num
	-- get Admitting Phys
	LEFT OUTER JOIN SMSDSS.pract_dim_v AS C
	ON SMSDSS.BMH_PLM_PtAcct_V.Adm_Dr_No = C.src_pract_no
		AND C.orgz_cd = 'S0X0'

	WHERE patient_type = 'I'
	AND discharged >= @SD
	AND discharged < @ED
	AND Adm_Source NOT IN ('RA', 'RP', 'TH', 'TV')
) I

--SELECT * FROM @TmpDenialsTbl
-----------------------------------------------------------------------
SELECT a.BILL_NO as tmbptbl_bill_no
, a.VISIT_ATTEND_PHYS
, a.ATTEND_DR
, a.ATTEND_DR_NO
, a.ATTEND_SPCLTY
, A.ADM_DR_NO
, A.ADM_DR
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
-- Add Admit Year and Month SPS 2/16/2016
, a.Adm_Yr
, a.Adm_Month
, a.discharged
, a.Dsch_Yr
, a.Dsch_Mo
, a.pyr_cd
, a.pyr_seq_no
, a.pyr_name
, a.Appeal_Date
, YEAR(a.appeal_date) AS [Appeal_Year]
, a.Adm_Dx
, B.denials
, a.cerm_rvwr_id
, D.username
, D.RN
, DRG.DRG
, DRG.DRG_NAME

FROM @TmpDenialsTbl                     AS A
LEFT OUTER JOIN @InpatientDenials       AS B
ON A.bill_no = B.pt_id
LEFT OUTER JOIN @EDTBL                  AS C
ON A.bill_no = C.Account
LEFT OUTER JOIN @USERTBL                AS D
ON A.CERM_RVWR_ID = D.login_id
	AND D.RN = 1
-- add drg no SPS 2/16/2016
LEFT OUTER JOIN @DRG                    AS DRG
ON A.BILL_NO = DRG.ENCOUNTER

-- Union the results of the outpatients -------------------------------
UNION

SELECT O.BILL_NO
, O.VISIT_ATTEND_PHYS
, O.ATTEND_DR
, O.ATTEND_DR_NO
, O.ATTEND_SPCLTY
, ''
, ''
, EDO.ED_MD
, O.LAST_NAME
, O.FIRST_NAME
, O.RVW_DATE
, O.PATIENT_TYPE
, O.INITIAL_DENIAL
, O.APPL_TYPE
, O.APPL_STATUS
, O.PENDING
, O.FINALIZED
, O.APPL_DOLLARS_APPEALED
, O.[1st_Lvl_Appealed_Ind]
, O.[2nd_Lvl_Appealed_Ind]
, O.s_cpm_Dollars_not_appealed
, O.No_Appeal
, O.appl_dollars_recovered
, O.[1st_Lvl_Recovery]
, O.DRA_Lvl_Recovery
, O.s_qm_subseq_appeal
, O.External_Appeal
, O.s_qm_subseq_appeal_date
, O.assoc_prvdr
, O.Denial_Dr
, O.Denial_Dr_No
, O.BMH_Specialty
, O.Denial_Spclty
, O.s_rvw_dnl_rsn
, O.v_financial_cls
, O.length_of_stay
, O.Short_Stay_Indicator
, O.Long_Stay_Indicator
, O.Short_Stay_Appeal_Indicator
, O.Long_Stay_Appeal_Indicator
, O.visit_admit_diag
, O.admit_diag_Description
, O.admission_date
-- Add Admit Year and Month SPS 2/16/2016
, O.Adm_Yr
, O.Adm_Month
, O.discharged
, O.Dsch_Yr
, O.Dsch_Mo
, O.pyr_cd
, O.pyr_seq_no
, O.pyr_name
, O.Appeal_Date
, YEAR(O.appeal_date) AS [Appeal_Year]
, O.Adm_Dx
, OD.denials
, O.cerm_rvwr_id
, ''
, ''
, DRG.DRG
, DRG.DRG_NAME

FROM @OutPatient                        AS O
LEFT OUTER JOIN @EDTBL                  AS EDO
ON O.BILL_NO = EDO.ACCOUNT
LEFT OUTER JOIN @OUTPATIENT_DENIALS     AS OD
ON O.BILL_NO = OD.bill_no
-- add drg no SPS 2/16/2016
LEFT OUTER JOIN @DRG                    AS DRG
ON O.BILL_NO = DRG.ENCOUNTER

WHERE O.RN = 1
