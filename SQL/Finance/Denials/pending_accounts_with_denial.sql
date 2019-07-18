DECLARE @SD DATETIME;
DECLARE @ED DATETIME;

SET @SD = '2014-01-01';
SET @ED = '2016-12-01';

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
-- Outpatients
DECLARE @OutPatient TABLE (
       PK INT IDENTITY(1, 1)         PRIMARY KEY
       , BILL_NO                     INT
       , LAST_NAME                   VARCHAR(MAX)
       , FIRST_NAME                  VARCHAR(MAX)
       , PENDING                     INT
       , APPL_DOLLARS_APPEALED       VARCHAR(MAX)
       , appl_dollars_recovered      VARCHAR(MAX)
       , pyr_cd                      VARCHAR(MAX)
       , pyr_seq_no                  VARCHAR(MAX)
       , pyr_name                    VARCHAR(MAX)
       , RN                          INT
)

INSERT INTO @OutPatient
SELECT O.*
FROM (
       SELECT bill_no
       , last_name
       , first_name
       , Pending
       , appl_dollars_appealed
       , appl_dollars_recovered
       , pyr_cd
       , pyr_seq_no
       , pyr_name
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
       , LAST_NAME                   VARCHAR(MAX)
       , FIRST_NAME                  VARCHAR(MAX)
       , PENDING                     INT
       , APPL_DOLLARS_APPEALED       VARCHAR(MAX)
       , appl_dollars_recovered      VARCHAR(MAX)
       , pyr_cd                      VARCHAR(MAX)
       , pyr_seq_no                  VARCHAR(MAX)
       , pyr_name                    VARCHAR(MAX)
)

INSERT INTO @TmpDenialsTbl
SELECT I.*
FROM (
       SELECT bill_no
       , last_name
       , first_name
       , Pending
       , appl_dollars_appealed
       , appl_dollars_recovered
       , pyr_cd
       , pyr_seq_no
       , pyr_name

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
, a.LAST_NAME
, a.FIRST_NAME
, a.PENDING
, a.APPL_DOLLARS_APPEALED
, a.appl_dollars_recovered
, a.pyr_cd
, a.pyr_seq_no
, a.pyr_name

FROM @TmpDenialsTbl                     AS A
LEFT OUTER JOIN @InpatientDenials       AS B
ON A.bill_no = B.pt_id
-- get discharge unit
LEFT OUTER JOIN SMSMIR.VST_RPT          AS VST
ON A.BILL_NO = SUBSTRING(VST.PT_ID, 5, 8)

WHERE A.PENDING = 1

-- Union the results of the outpatients -------------------------------
UNION

SELECT O.BILL_NO
, O.LAST_NAME
, O.FIRST_NAME
, O.PENDING
, O.APPL_DOLLARS_APPEALED
, O.appl_dollars_recovered
, O.pyr_cd
, O.pyr_seq_no
, O.pyr_name

FROM @OutPatient                        AS O
LEFT OUTER JOIN @OUTPATIENT_DENIALS     AS OD
ON O.BILL_NO = OD.bill_no
LEFT OUTER JOIN SMSMIR.vst_rpt          AS VST
ON O.BILL_NO = SUBSTRING(VST.PT_ID, 5, 8)

WHERE O.RN = 1
AND O.PENDING = 1
