USE [SMSPHDSSS0X0];
GO

--SET THE OPTIONS TO SUPPORT INDEXED VIEWS.
SET NUMERIC_ROUNDABORT OFF;
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT,
	QUOTED_IDENTIFIER, ANSI_NULLS ON;
GO

--CREATE VIEW WITH SCHEMA BINDING
IF OBJECT_ID('smsdss.c_ins_bal_amt_v', 'view') IS NOT NULL
DROP VIEW smsdss.c_ins_bal_amt_v;
GO

CREATE VIEW [smsdss].[c_INS_BAL_AMT_v]
WITH SCHEMABINDING
AS

SELECT A.PK
, A.pt_id
, A.unit_seq_no
, A.cr_rating
, A.vst_end_date
, A.fc
, A.hosp_svc
, A.Age_In_Days
, A.tot_chg_amt
, A.tot_enc_bal_amt
, A.pt_bal_amt
, A.Ins_Bal_Amt
, A.tot_pay_amt
, A.pt_pay_amt
, B.pyr_cd AS [Self_Pay_CD] 
, B.ins_bal_amt AS [Self_Pay]
, C.pyr_cd AS [Ins1]
, C.ins_bal_amt AS [Ins1_Bal]
, d.pyr_cd AS [Ins2]
, d.Ins_Bal_Amt AS [Ins2_Bal]
, e.pyr_cd AS [Ins3]
, e.Ins_Bal_Amt AS [Ins3_Bal]
, f.pyr_cd AS [Ins4]
, f.Ins_Bal_Amt AS [Ins4_Bal]
, A.RunDate

FROM smsdss.c_ins_bal_amt AS A
-- GET SELF PAY
LEFT JOIN smsdss.c_ins_bal_amt AS B
ON A.PT_ID = B.PT_ID
	AND A.UNIT_SEQ_NO = B.UNIT_SEQ_NO
	AND B.PYR_SEQ_NO = 0
	AND A.RunDate = B.RunDate
-- GET INS1
LEFT JOIN smsdss.c_ins_bal_amt AS C
ON A.PT_ID = C.PT_ID
	AND A.UNIT_SEQ_NO = C.UNIT_SEQ_NO
	AND C.PYR_SEQ_NO = 1
	AND A.RunDate = C.RunDate
-- GET INS2
LEFT JOIN smsdss.c_ins_bal_amt AS D
ON A.PT_ID = D.PT_ID
	AND A.UNIT_SEQ_NO = D.UNIT_SEQ_NO
	AND D.PYR_SEQ_NO = 2
	AND A.RunDate = D.RunDate
-- GET INS3
LEFT JOIN smsdss.c_ins_bal_amt AS E
ON A.PT_ID = E.PT_ID
	AND A.UNIT_SEQ_NO = E.UNIT_SEQ_NO
	AND E.PYR_SEQ_NO = 3
	AND A.RunDate = E.RunDate
-- GET INS4
LEFT JOIN smsdss.c_ins_bal_amt AS F
ON A.PT_ID = F.PT_ID
	AND A.UNIT_SEQ_NO = F.UNIT_SEQ_NO
	AND F.PYR_SEQ_NO = 4
	AND A.RunDate = F.RunDate

WHERE A.RN = 1
AND A.RunDate = (SELECT MAX(A.RUNDATE) FROM smsdss.c_ins_bal_amt AS A);

GO
