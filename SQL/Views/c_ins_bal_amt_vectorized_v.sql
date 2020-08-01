USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_ins_bal_amt_vectorized_v]    Script Date: 7/31/2020 10:28:49 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





ALTER VIEW [smsdss].[c_ins_bal_amt_vectorized_v]
AS
SELECT DISTINCT A.[pt_id],
	A.[unit_seq_no],
	A.from_file_ind,
	A.[fc],
	A.credit_rating,
	A.[hosp_svc],
	A.pyr_cd,
	A.pyr_cd_DESC,
	UPPER(A.pyr_group) AS [pyr_group2],
	CASE 
		WHEN B.carrier IS NULL
			AND LEFT(a.pyr_cd, 1) = 'A'
			THEN 'MEDICARE'
		WHEN A.pyr_cd = '*'
			THEN 'SELF PAY'
		WHEN b.Carrier IS NULL
			THEN pyr_group2
		ELSE b.Carrier
		END AS ins_carrier,
	a.pyr_seq_no,
	a.ins_cd_bal AS [ins_bal_amt],
	CASE 
		WHEN LEFT(PT_ID, 5) = '00001'
			THEN 'IP'
		ELSE 'OP'
		END AS [IP_OP],
	A.[Age_In_Days],
	CASE 
		WHEN AGE_IN_DAYS < 31
			THEN '0-30'
		WHEN AGE_IN_DAYS BETWEEN 31
				AND 60
			THEN '31-60'
		WHEN AGE_IN_DAYS BETWEEN 61
				AND 90
			THEN '61-90'
		WHEN AGE_IN_DAYS BETWEEN 91
				AND 120
			THEN '91-120'
		WHEN AGE_IN_DAYS BETWEEN 121
				AND 180
			THEN '121-180'
		WHEN AGE_IN_DAYS BETWEEN 181
				AND 365
			THEN '181-365'
		ELSE '366+'
		END AS [Age_Group],
	CASE 
		WHEN AGE_IN_DAYS < 31
			THEN 'A'
		WHEN AGE_IN_DAYS BETWEEN 31
				AND 60
			THEN 'B'
		WHEN AGE_IN_DAYS BETWEEN 61
				AND 90
			THEN 'C'
		WHEN AGE_IN_DAYS BETWEEN 91
				AND 120
			THEN 'D'
		WHEN AGE_IN_DAYS BETWEEN 121
				AND 180
			THEN 'E'
		WHEN AGE_IN_DAYS BETWEEN 181
				AND 365
			THEN 'F'
		ELSE 'G'
		END AS [Age_Group_Flag],
	[Unitized_Flag] = CASE WHEN LEFT(a.PT_ID, 5) = '00007' THEN 1 ELSE 0 END,
	A.[RunDate],
	A.[RunDateTime]
FROM SMSDSS.c_ins_cd_bal_tbl AS A
LEFT OUTER JOIN SMSDSS.c_ins_plan_cd_w_carrier AS B ON A.pyr_cd = B.plan_cd
LEFT OUTER JOIN SMSDSS.PYR_DIM_V AS C ON A.pyr_cd = C.pyr_cd
	AND C.orgz_cd = 'S0X0'
WHERE RunDate = (
		SELECT MAX(RunDate)
		FROM SMSDSS.c_ins_cd_bal_tbl
		)





GO


