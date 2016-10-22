DECLARE @START_DATE DATE;
DECLARE @END_DATE   DATE;

SET @START_DATE = '2012-01-01';
SET @END_DATE   = '2016-01-01';
---------------------------------------------------------------------------------------------------
DECLARE @HCRA_POP TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN                    VARCHAR(10)
	, [Ref Number]           VARCHAR(12)
	, PT_ID                  VARCHAR(12)
	, [Admit Date]           DATE
	, [Discharge Date]       DATE
	, [Primary Payor]        VARCHAR(4)
	, [Primary Ins Name]     VARCHAR(50)
	, [Pyor Sub-Code]        VARCHAR(5)
	, [Medical Service Code] VARCHAR(3)
	, [Service Code Desc]    VARCHAR(75)
	, [Receivable Type]      VARCHAR(1)
	, [Secondary Ins]        VARCHAR(5)
	, [Secondary Ins Name]   VARCHAR(50)
	, [Third Ins]            VARCHAR(5)
	, [Third Ins Name]       VARCHAR(50)
	, [Fourth Ins]           VARCHAR(5)
	, [Fourth Ins Name]      VARCHAR(50)
);

WITH CTE AS (
	SELECT A.Med_Rec_No
	, A.PtNo_Num                AS [Ref Number]
	, A.Pt_No
	, CAST(A.ADM_DATE AS DATE)  AS [Admit Date]
	, CAST(A.DSCH_DATE AS DATE) AS [Discharge Date]
	, A.Pyr1_Co_Plan_Cd         AS [Primary Payor]
	, CASE
		WHEN A.User_Pyr1_Cat = 'MIS' THEN 'Self Pay'
		ELSE B.pyr_name
	  END                       AS [Primary Ins Name] -- WILL NEED TO COALESE RESULTS FROM @INS_INFO TABLE
	, ''                        AS [Payor Sub-Code]
	, A.hosp_svc                AS [Medical Service Code]
	, D.hosp_svc_name
	, A.Plm_Pt_Acct_Type        AS [Receivable Type]
	, A.Pyr2_Co_Plan_Cd
	, E.pyr_name                AS [Secondary Payor Name]
	, A.Pyr3_Co_Plan_Cd
	, F.pyr_name                AS [Third Payor Name]
	, A.Pyr4_Co_Plan_Cd
	, G.pyr_name                AS [Fourth Payor Name]

	FROM smsdss.BMH_PLM_PtAcct_V         AS A
	LEFT JOIN smsmir.pyr_mstr            AS B
	ON A.Pyr1_Co_Plan_Cd = B.pyr_cd
	LEFT JOIN SMSMIR.pyr_mstr            AS E
	ON A.Pyr2_Co_Plan_Cd = E.pyr_cd
	LEFT JOIN SMSMIR.pyr_mstr            AS F
	ON A.Pyr3_Co_Plan_Cd = F.pyr_cd
	LEFT JOIN smsmir.pyr_mstr            AS G
	ON A.Pyr4_Co_Plan_Cd = G.pyr_cd
	LEFT JOIN smsdss.hosp_svc_dim_v      AS D
	ON A.hosp_svc = D.hosp_svc
		AND A.Regn_Hosp = D.orgz_cd
	
	WHERE a.Dsch_Date >= @START_DATE
	AND a.Dsch_Date < @END_DATE
	AND a.Med_Rec_No IS NOT NULL
	AND a.tot_chg_amt > 0
	AND LEFT(A.PTNO_NUM, 1) != '7'
)
INSERT INTO @HCRA_POP
SELECT * FROM CTE
OPTION(FORCE ORDER);

SELECT A.*
INTO #TEMP_A
FROM @HCRA_POP AS A;

---------------------------------------------------------------------------------------------------
-- GET '5' FIELD INSURANCE INFORMATION FROM SMSDSS.C_INS_USER_FIELDS_V

DECLARE @INS_INFO TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter VARCHAR(12)
	, Pyr_Cd    VARCHAR(5)
	, Ins_Name  VARCHAR(50)
	, Ins_City  VARCHAR(50)
	, Ins_State VARCHAR(50)
);

WITH CTE AS (
	SELECT PT_ID
	, pyr_cd
	, Ins_Name
	, Ins_City
	, Ins_State

	FROM SMSDSS.c_ins_user_fields_v

	WHERE pt_id IN (
		SELECT A.PT_ID
		FROM @HCRA_POP AS A
	)
)

INSERT INTO @INS_INFO
SELECT * FROM CTE

--SELECT * FROM @INS_INFO;
SELECT B.*
INTO #TEMP_B
FROM @INS_INFO AS B;

---------------------------------------------------------------------------------------------------
-- PAYMENTS W PIP VIEW
DECLARE @PIP_PMTS TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, PT_ID VARCHAR(12)
	, PYR_CD VARCHAR(5)
	, TOT_PYMTS_W_PIP MONEY
);

WITH CTE AS (
	SELECT PIP.pt_id
	, PIP.pyr_cd
	, SUM(PIP.tot_pymts_w_pip) AS tot_pymts_w_pip
	
	FROM smsdss.c_tot_pymts_w_pip_plan_lvl_v PIP
	INNER JOIN @HCRA_POP A
	ON A.PT_ID= PIP.pt_id
	
	GROUP BY PIP.pt_id, PIP.pyr_cd
)

INSERT INTO @PIP_PMTS
SELECT * FROM CTE
OPTION(FORCE ORDER);
--SELECT * FROM @PIP_PMTS;
SELECT C.*
INTO #TEMP_C
FROM @PIP_PMTS AS C;

---------------------------------------------------------------------------------------------------
-- GET XFER PAYMENTS
SELECT pt_id
, pay_cd
, cmt.pay_cd_cmt
, SUM(tot_pay_adj_amt) AS sum_tot_pay_adj_amt

INTO #TEMP_D

FROM smsmir.pay

CROSS APPLY (
	SELECT
		CASE
			WHEN pay_cd = '03300605' THEN 'ins_to_ins'
			WHEN pay_cd = '03300704' THEN 'ins_to_pt'
	END AS pay_cd_cmt
) cmt

WHERE pt_id IN (
	SELECT A.PT_ID
	FROM @HCRA_POP AS A
)
AND pay_cd IN (
	'03300605', '03300704'
)

GROUP BY pt_id
, pay_cd
, cmt.pay_cd_cmt
---------------------------------------------------------------------------------------------------
-- GET COPAY CHARGE AMOUNT 03300704
SELECT PT_ID
, pay_cd
--, pay_desc
, SUM(tot_pay_adj_amt) AS positive_copay_amt

INTO #copay_charge_a

FROM smsmir.pay

WHERE pay_cd = '03300704'
AND pay_desc LIKE '%co%ay%'
AND tot_pay_adj_amt > 0

GROUP BY PT_ID, pay_cd  --, pay_desc
---------------------------------------------------------------------------------------------------
-- GET COPAY PAYMENT AMOUNT 03300704
SELECT PT_ID
, pay_cd
--, pay_desc
, SUM(tot_pay_adj_amt) AS negative_copay_amt

INTO #copay_payment_a

FROM smsmir.pay

WHERE pay_cd = '03300704'
AND pay_desc LIKE '%co%ay%'
AND tot_pay_adj_amt < 0

GROUP BY PT_ID, pay_cd  --, pay_desc
---------------------------------------------------------------------------------------------------
-- GET COPAY CHARGE AMOUNT 03300605
SELECT PT_ID
, pay_cd
--, pay_desc
, SUM(tot_pay_adj_amt) AS positive_copay_amt

INTO #copay_charge_b

FROM smsmir.pay

WHERE pay_cd = '03300605'
AND pay_desc like '%co%ay%'
AND tot_pay_adj_amt > 0

GROUP BY PT_ID, pay_cd  --, pay_desc
---------------------------------------------------------------------------------------------------
-- GET COPAY PAYMENT AMOUNT 03300605
SELECT pt_id
, pay_cd
--, pay_desc
, SUM(tot_pay_adj_amt) AS negative_copay_amt

INTO #copay_payment_b

FROM smsmir.pay

WHERE pay_cd = '03300605'
AND pay_desc like '%co%ay%'
AND tot_pay_adj_amt < 0

GROUP BY pt_id, pay_cd  --, pay_desc
---------------------------------------------------------------------------------------------------
-- GET DEDUCTIBLE CHARGE AMOUNT 03300704
SELECT pt_id
, pay_cd
, SUM(tot_pay_adj_amt) AS pos_deductible_amt_a

INTO #deductible_charge_a

FROM smsmir.pay

WHERE pay_cd = '03300704'
AND pay_desc like '%de%du%'
AND tot_pay_adj_amt > 0 

GROUP BY pt_id, pay_cd
---------------------------------------------------------------------------------------------------
-- GET DEDUCTIBLE PAYMENT AMOUNT 03300704
SELECT pt_id
, pay_cd
, SUM(tot_pay_adj_amt) AS neg_deductible_amt_a

INTO #deductible_payment_a

FROM smsmir.pay

WHERE pay_cd = '03300704'
AND pay_desc LIKE '%de%du%'
AND tot_pay_adj_amt < 0 

GROUP BY pt_id, pay_cd
---------------------------------------------------------------------------------------------------
-- GET DEDUCTIBLE CHARGE AMOUNT 03300605 
SELECT pt_id
, pay_cd
, SUM(tot_pay_adj_amt) AS pos_deductible_amt_b

INTO #deductible_charge_b

FROM smsmir.pay

WHERE pay_cd = '03300605'
AND pay_desc like '%de%du%'
AND tot_pay_adj_amt > 0 

GROUP BY pt_id, pay_cd
---------------------------------------------------------------------------------------------------
-- GET DEDUCTIBLE PAYMENT AMOUNT 03300605
SELECT pt_id
, pay_cd
, SUM(tot_pay_adj_amt) AS neg_deductible_amt_b

INTO #deductible_payment_b

FROM smsmir.pay

WHERE pay_cd = '03300605'
AND pay_desc LIKE '%de%du%'
AND tot_pay_adj_amt < 0 

GROUP BY pt_id, pay_cd
---------------------------------------------------------------------------------------------------
-- GET CO-INSURANCE CHARGE AMOUNT 03300605
SELECT pt_id
, pay_cd
, SUM(tot_pay_adj_amt) AS POS_COINS_AMT_A

INTO #COINS_CHARGE_A

FROM smsmir.pay

WHERE pay_cd = '03300605'
AND pay_desc LIKE '%CO%IN%'
AND tot_pay_adj_amt > 0

GROUP BY pt_id, pay_cd
---------------------------------------------------------------------------------------------------
-- GET CO-INSURANCE PAYMENT AMOUNT 03300605
SELECT pt_id
, pay_cd
, SUM(tot_pay_adj_amt) AS NEG_COINS_AMT_A

INTO #COINS_PAY_A

FROM smsmir.pay

WHERE pay_cd = '03300605'
AND pay_desc LIKE '%CO%IN%'
AND tot_pay_adj_amt < 0 

GROUP BY pt_id, pay_cd
---------------------------------------------------------------------------------------------------
-- GET CO-INSURANCE CHARGE AMOUNT 03300704
SELECT pt_id
, pay_cd
, SUM(tot_pay_adj_amt) AS POS_COINS_AMT_B

INTO #COINS_CHARGE_B

FROM smsmir.pay

WHERE pay_cd = '03300704'
AND pay_desc LIKE '%CO$IN$'
AND tot_pay_adj_amt > 0 

GROUP BY pt_id, pay_cd
---------------------------------------------------------------------------------------------------
-- GET CO-INSURANCE PAYMENT AMOUNT 03300704
SELECT pt_id
, pay_cd
, SUM(tot_pay_adj_amt) AS NEG_COINS_AMT_B

INTO #COINS_PAY_B

FROM smsmir.pay

WHERE pay_cd = '03300704'
AND pay_desc LIKE '%CO%IN%'
AND tot_pay_adj_amt < 0

GROUP BY pt_id, pay_cd
---------------------------------------------------------------------------------------------------
-- GET TOTAL PATIENT PAYMENTS AS TOT_PAY_AMT - INS_PAY_AMT
SELECT PT_ID
, (TOT_PAY_AMT - INS_PAY_AMT) AS [tot_pt_pay_amt]

INTO #TEMP_E

FROM smsmir.mir_acct

WHERE pt_id IN (
	SELECT A.PT_ID
	FROM @HCRA_POP AS A
)
---------------------------------------------------------------------------------------------------
SELECT A.[Ref Number]
, A.MRN
, A.[Admit Date]
, A.[Discharge Date]
, 'BMHMC' AS [Payor Code]
, 'Brookhaven Memorial Hospital Medical Center' AS [Payor Description]
, A.[Pyor Sub-Code]
, '' AS [Payor ID]
, '' AS [Payor TIN]
, A.[Primary Payor]
, COALESCE(B.INS_NAME, A.[Primary Ins Name])                      AS [Prin Ins Name]
--, A.[Primary Ins Name]
--, B.Ins_Name
, RTRIM(SUBSTRING(B.Ins_State, 1, CHARINDEX(',', B.Ins_State)-1)) AS [Prin Ins City]
--, B.Ins_City
, SUBSTRING(B.Ins_State, CHARINDEX(',', B.INS_STATE)+1, 2)        AS [Prin Ins State]
, C.TOT_PYMTS_W_PIP                                               AS [Prin Ins PIP Pmts]
, A.[Secondary Ins]
, COALESCE(D.INS_NAME, A.[SECONDARY INS NAME])                    AS [Secondary Ins Name]
--, A.[Secondary Ins Name]
--, D.Ins_Name
, RTRIM(SUBSTRING(D.Ins_State, 1, CHARINDEX(',', D.INS_STATE)-1)) AS [Secondary Ins City]
--, D.Ins_City
, SUBSTRING(D.Ins_State, CHARINDEX(',', D.INS_STATE)+1, 2)        AS [Secondary Ins State]
, E.TOT_PYMTS_W_PIP                                               AS [Secondary Ins PIP Pmts]
, A.[Third Ins]
, COALESCE(F.INS_NAME, A.[THIRD INS NAME])                        AS [Third Ins Name]
--, A.[Third Ins Name]
, RTRIM(SUBSTRING(F.Ins_State, 1, CHARINDEX(',', F.Ins_State)-1)) AS [Third Ins City]
, SUBSTRING(F.INS_STATE, CHARINDEX(',', F.INS_STATE)+1, 2)        AS [Third Ins State]
, G.TOT_PYMTS_W_PIP                                               AS [Third Ins PIP Pmts]
, A.[Fourth Ins]
, COALESCE(H.INS_NAME, A.[Fourth Ins Name])                       AS [Fourth Ins Name]
, RTRIM(SUBSTRING(H.INS_STATE, 1, CHARINDEX(',', H.INS_STATE)-1)) AS [Fourth Ins City]
, SUBSTRING(H.INS_STATE, CHARINDEX(',', H.INS_STATE)+1, 2)        AS [Fourth Ins State]
, I.TOT_PYMTS_W_PIP                                               AS [Fourth Ins PIP Pmts]
, COPAY_CHARGE_A.positive_copay_amt                               as pos_copay_amt_a_704
, COPAY_PAY_A.negative_copay_amt                                  as neg_copay_amt_a_704
, XFER_PMTS_B.sum_tot_pay_adj_amt                                 AS [Ins to Pt 704]  --'03300704'
, COPAY_CHARGE_B.positive_copay_amt                               as pos_copay_amt_b_605
, COPAY_PAY_B.negative_copay_amt                                  as neg_copay_amt_b_605
, XFER_PMTS.sum_tot_pay_adj_amt                                   AS [Ins to Ins 605] --'03300605'
, deduc_chg_a.pos_deductible_amt_a                                as pos_deduc_amt_a_704
, deduc_pmt_a.neg_deductible_amt_a                                as neg_deduc_amt_a_704
, deduc_chg_b.pos_deductible_amt_b                                as pos_deduc_amt_b_605
, deduc_pmt_b.neg_deductible_amt_b                                as neg_deduc_amt_b_605
, COINS_CHG_A.POS_COINS_AMT_A                                     AS POS_COINS_AMT_A_605
, COINS_PAY_A.NEG_COINS_AMT_A                                     AS NEG_COINS_AMT_A_605
, COINS_CHG_B.POS_COINS_AMT_B                                     AS POS_COINS_AMT_B_704
, COINS_PAY_B.NEG_COINS_AMT_B                                     AS NEG_COINS_AMT_B_704
, PT_PMTS.tot_pt_pay_amt

FROM #TEMP_A                    AS A
-- GET PRIMARY INSURANCE DEMOGRAPHICS
LEFT JOIN #TEMP_B               AS B
ON A.PT_ID = B.Encounter
	AND A.[Primary Payor] = B.Pyr_Cd
-- GET PRIMARY INSURANCE PIP PAYMENTS
LEFT JOIN #TEMP_C               AS C
ON A.PT_ID = C.PT_ID
	AND A.[Primary Payor] = C.PYR_CD
-- GET SECONDARY INS DEMOGRAPHICS
LEFT JOIN #TEMP_B               AS D
ON A.PT_ID = D.Encounter
	AND A.[Secondary Ins] = D.Pyr_Cd
-- GET SECONDARY INSURANCE PIP PAYMENTS
LEFT JOIN #TEMP_C               AS E
ON A.PT_ID = E.PT_ID
	AND A.[Secondary Ins] = E.PYR_CD
-- GET THIRD INSURANCE DEMOGRAPHICS
LEFT JOIN #TEMP_B               AS F
ON A.PT_ID = F.Encounter
	AND A.[Third Ins] = F.Pyr_Cd
-- GET THRID INSURANCE PIP PAYMENTS
LEFT JOIN #TEMP_C               AS G
ON A.PT_ID = G.PT_ID
	AND A.[Third Ins] = G.PYR_CD
-- GET FOURTH INSURANCE DEMOGRAPHICS
LEFT JOIN #TEMP_B               AS H
ON A.PT_ID = H.Encounter
	AND A.[Fourth Ins] = F.Pyr_Cd
-- GET FOURTH INSURANCE PIP PAYMENTS
LEFT JOIN #TEMP_C               AS I
ON A.PT_ID = I.PT_ID
	AND A.[Fourth Ins] = G.PYR_CD

-- GET XFER PAYMENTS (WE HOPE THIS GOES TO ZERO (0) - INS TO INS
LEFT JOIN #TEMP_D               AS XFER_PMTS
ON A.PT_ID = XFER_PMTS.pt_id
	AND XFER_PMTS.pay_cd = '03300605'
-- GET TOT COPAY CHARGE 03300605
LEFT JOIN #copay_charge_b       AS COPAY_CHARGE_B
ON A.PT_ID = COPAY_CHARGE_B.pt_id
-- GET TOTAL COPAY PAYMENTS 03300605
LEFT JOIN #copay_payment_b      AS COPAY_PAY_B
ON A.PT_ID = COPAY_PAY_B.pt_id

-- GET XFER PAYMENTS (WE HOPE THIS GOES TO ZERO (0) - INS TO PT
LEFT JOIN #TEMP_D               AS XFER_PMTS_B
ON A.PT_ID = XFER_PMTS_B.pt_id
	AND XFER_PMTS_B.pay_cd = '03300704'
-- GET TOTAL COPAY CHARGE 03300704
LEFT JOIN #copay_charge_a       AS COPAY_CHARGE_A
ON A.PT_ID = COPAY_CHARGE_A.pt_id
-- GET TOTAL COPAY PAYMENTS 03300704
LEFT JOIN #copay_payment_a      AS COPAY_PAY_A
ON A.PT_ID = COPAY_PAY_A.pt_id
-- GET TOTAL PATIENT PAYMENTS

LEFT JOIN #TEMP_E               AS PT_PMTS
ON A.PT_ID = PT_PMTS.pt_id

-- GET DEDUCTIBLE INFORMATION CHARGE 03300704
LEFT JOIN #deductible_charge_a  AS deduc_chg_a
ON A.pt_id = deduc_chg_a.pt_id
-- GET DEDUCTIBLE INFORMATION PAYMENT 03300704
LEFT JOIN #deductible_payment_a AS deduc_pmt_a
ON A.pt_id = deduc_pmt_a.pt_id
-- GET DEDUCTIBLE INFORMATION CHARGE 03300605
LEFT JOIN #deductible_charge_b  AS deduc_chg_b
ON A.pt_id = deduc_chg_b.pt_id
-- GET DEDUCTIBLE INFORMATION PAYMENT 03300605
LEFT JOIN #deductible_payment_b AS deduc_pmt_b
ON A.pt_id = deduc_pmt_b.pt_id

-- GET CO-INSURANCE INFORMATION CHARGE 03300605
LEFT JOIN #COINS_CHARGE_A       AS COINS_CHG_A
ON A.PT_ID = COINS_CHG_A.PT_ID
-- GET CO-INSURANCE INFORMATION PAYMENT 03300605
LEFT JOIN #COINS_PAY_A          AS COINS_PAY_A
ON A.PT_ID = COINS_PAY_A.pt_id
-- GET CO-INSURANCE INFORMATION CHARGE 03300704
LEFT JOIN #COINS_CHARGE_B       AS COINS_CHG_B
ON A.PT_ID = COINS_CHG_B.PT_ID
-- GET CO-INSURANCE INFORMATION PAYMENT 03300704
LEFT JOIN #COINS_PAY_B          AS COINS_PAY_B
ON A.PT_ID = COINS_PAY_B.PT_ID

---------------------------------------------------------------------------------------------------
--DROP TABLE #TEMP_A, #TEMP_B, #TEMP_C, #TEMP_D, #TEMP_E, #copay_charge_a, #copay_payment_a;
--DROP TABLE #copay_charge_b, #copay_payment_b, #deductible_charge_a, #deductible_charge_b;
--DROP TABLE #deductible_charge_b, #deductible_payment_b, #COINS_CHARGE_A, #COINS_PAY_A;
--DROP TABLE #COINS_PAY_B, #COINS_CHARGE_B;
--SELECT * FROM #TEMP_A AS A WHERE A.[Ref Number] = ''
--SELECT * FROM #TEMP_B AS B WHERE B.Encounter = ''
--SELECT * FROM #TEMP_C AS C WHERE C.PT_ID = ''
