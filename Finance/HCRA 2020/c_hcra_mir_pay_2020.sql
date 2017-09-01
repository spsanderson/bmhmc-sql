/*
=======================================================================
Get all of the payment data for the 2020 HCRA audit.                  |
                                                                      |
***** N O T E *****                                                   |
Update all PIP codes before running                                   |
                                                                      |
=======================================================================
*/

IF OBJECT_ID('SMSDSS.C_HCRA_MIR_PAY_2020', 'U') IS NOT NULL
	DROP TABLE smsdss.C_HCRA_MIR_PAY_2020

CREATE TABLE smsdss.c_HCRA_mir_pay_2020 (
 PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
, PT_ID             VARCHAR(12)
, pay_cd            VARCHAR(15)
, pay_cd_name       VARCHAR(250)
, pay_entry_date    DATE
, pay_seq_no        INT
, tot_pay_adj_amt   MONEY
, orgz_cd           VARCHAR(10)
, pay_desc          VARCHAR(200)
, hosp_svc          VARCHAR(10)
, pyr_cd            VARCHAR(5)
, pt_id_start_dtime DATETIME
, pip_flag          VARCHAR(7)
);

INSERT INTO smsdss.c_HCRA_mir_pay_2020

SELECT *
FROM (
	SELECT a.pt_id
	, a.pay_cd
	, b.pay_cd_name
	, a.pay_entry_date
	, a.pay_seq_no
	, a.tot_pay_adj_amt
	, a.orgz_cd
	, a.pay_desc
	, a.hosp_svc
	, a.pyr_cd
	, a.pt_id_start_dtime
	, CASE
		WHEN (
			a.pay_cd BETWEEN '09600000' AND '09699999'
			OR a.pay_cd BETWEEN '00990000' AND '00999999'
			OR a.pay_cd BETWEEN '09900000' AND '09999999'
		)
		THEN 'NON-PIP'
		ELSE 'PIP'
	  END AS [pip_flag]

	FROM smsmir.pay AS A
	LEFT JOIN smsdss.PAY_CD_DIM_V as b
	on A.pay_cd = b.pay_cd

	WHERE (a.pay_cd BETWEEN '09600000' AND '09699999'
	OR a.pay_cd BETWEEN '00990000' AND '00999999'
	OR a.pay_cd BETWEEN '09900000' AND '09999999'
	OR a.pay_cd IN (
		'00980300','00980409','00980508','00980607','00980656','00980706',
		'00980755','00980805','00980813','00980821','09800095','09800277',
		'09800301','09800400','09800459','09800509','09800558','09800608',
		'09800707','09800715','09800806','09800814','09800905','09800913',
		'09800921','09800939','09800947','09800962','09800970','09800988',
		'09800996','09801002','09801010','09801028','09801036','09801044',
		'09801051','09801069','09801077','09801085','09801093','09801101',
		'09801119'
		)
	)
	-- GET RID OF TEST PATIENTS AND UNITIZED ACCOUNTS
	AND LEFT(a.pt_id, 5) NOT IN ('00007', '00000')
	-- CHANGE FROM PAY_DATE TO PAY_ENTRY_DATE WHICH REC'S TO BANK
	AND a.pay_entry_date >= '2016-01-01'
	AND a.pay_entry_date < '2019-01-01'
	AND a.tot_pay_adj_amt != '0'
) A;