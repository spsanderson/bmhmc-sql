-- Query to capture CMS patients under the CJR Payment Model
-- Variable declaration and setting
DECLARE @START DATE, @END DATE;
SET @START = '2016-01-01'
SET @END   = '2016-02-01'

/*
=======================================================================
Get the initial population using just final discharge anchor 
MS-DRG's 469 & 470
=======================================================================
*/
DECLARE @InitPop TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter           INT
	, MRN                 INT
	, Pt_Sex              CHAR(1)
	, Age_at_Admit        INT
	, Pt_Name             VARCHAR(50)
	, Admit_DateTime      DATETIME
	, Adm_Yr              INT
	, Adm_Month           INT
	, Disch_DateTime      DATETIME
	, Disch_Yr            INT
	, Disch_Month         INT
	, LOS                 SMALLINT
	, Prin_Dx_CD          VARCHAR(15)
	, Proc_Cd             VARCHAR(15)
	, MS_DRG              CHAR(3)
	, DRG_Cost_Weight     FLOAT
	, Fin_Class           CHAR(1)
	, From_File_Ind       CHAR(2)
	, Ins1                VARCHAR(4)
	, Ins2                VARCHAR(4)
	, Ins3                VARCHAR(4)
	, Ins4                VARCHAR(4)
	, Tot_Chg_Amt         MONEY
	, Tot_Adj_Amt         MONEY
	, Tot_Pay_Amt_w_PIP   MONEY
	, Reimb_Amt           MONEY
	, Tot_Amt_Due         MONEY
	, Dsch_Disp           VARCHAR(3)
	, TwoDigit_DschDisp   VARCHAR(2)
	, Dsch_Disp_Desc      VARCHAR(100)
	, Dsch_UB_Desc        VARCHAR(100)
	, Prin_Dx_Hip_FX      CHAR(1)
);

WITH INITPOP AS (
	SELECT A.PtNo_Num
	, A.Med_Rec_No 
	, A.Pt_Sex 
	, A.Pt_Age 
	, A.Pt_Name 
	, A.vst_start_dtime 
	, DATEPART(YEAR, A.vst_start_dtime)  AS [Adm_Yr] 
	, DATEPART(MONTH, A.vst_start_dtime) AS [Adm_Month] 
	, A.vst_end_dtime 
	, DATEPART(YEAR, A.vst_end_dtime)    AS [Disch_Yr] 
	, DATEPART(MONTH, A.vst_end_dtime)   AS [Disch_Month] 
	, CAST(A.Days_Stay AS smallint)      AS [Days_Stay] 
	, A.prin_dx_cd
	, A.proc_cd 
	, A.drg_no 
	, A.drg_cost_weight 
	, A.fc 
	, A.from_file_ind 
	, A.Pyr1_Co_Plan_Cd 
	, A.Pyr2_Co_Plan_Cd 
	, A.Pyr3_Co_Plan_Cd 
	, A.Pyr4_Co_Plan_Cd 
	, A.tot_chg_amt 
	, A.tot_adj_amt 
	--, A.tot_pay_amt 
	, C.tot_pymts_w_pip
	, A.reimb_amt 
	, A.Tot_Amt_Due 
	, A.dsch_disp
	, SUBSTRING(A.dsch_disp, 2, 2)       AS [TwoDigit_DschDisp]
	, B.dsch_disp_cd_desc
	, CASE
		WHEN A.dsch_disp = 'ATW'
			THEN 'Referred to Homecare'
		WHEN A.dsch_disp = 'ATL'
			THEN 'Transfer to Medicare LTCH'
		WHEN LEFT(A.dsch_disp, 1) IN ('C', 'D')
			THEN 'Mortalilty'
		WHEN A.dsch_disp = 'ATX'
			THEN 'Transferred to inpatient rehabilitation (IRF) within hospital' 
		ELSE B.dsch_ub_desc
		END                              AS [dsch_ub_desc]
	, CASE
		WHEN A.prin_dx_cd IN (
			-- ICD-9 codes
			'820.00', '820.01', '820.02', '820.03', '820.09', '820.10',
			'820.11', '820.12', '820.13', '820.19', '820.20', '820.21',
			'820.22', '820.30', '820.31', '820.32', '820.8' , '820.9',
			-- ICD-10 codes
			'S72.019A', 'S72.023A', 'S72.026A', 'S72.033A', 'S72.036A', 
			'S72.043A', 'S72.046A', 'S72.099A', 'S72.019B', 'S72.019C', 
			'S72.023B', 'S72.023C', 'S72.026B', 'S72.026C', 'S72.033B', 
			'S72.033C', 'S72.036B', 'S72.036C', 'S72.043B', 'S72.043C', 
			'S72.046B', 'S72.046C', 'S72.099B', 'S72.099C', 'S72.109A', 
			'S72.143A', 'S72.146A', 'S72.23XA', 'S72.26XA', 'S72.109B', 
			'S72.109C', 'S72.143B', 'S72.143C', 'S72.146B', 'S72.146C', 
			'S72.23XB', 'S72.23XC', 'S72.26XB', 'S72.26XC', 'S72.009A', 
			'S72.009B', 'S72.009C'
		)
			THEN '1'
			ELSE '0'
	  END                                AS [Hip_Fx]


	FROM smsdss.BMH_PLM_PtAcct_V         AS A
	LEFT JOIN smsdss.dsch_disp_dim_v     AS B
	ON SUBSTRING(A.dsch_disp, 2, 2) = RTRIM(LTRIM(B.dsch_disp))
		AND B.orgz_cd = 'S0X0'
	LEFT JOIN smsdss.c_tot_pymts_w_pip_v AS C
	ON A.PTNO_NUM = C.acct_no
		AND a.pt_id_start_dtime = c.pt_id_start_dtime
		AND A.unit_seq_no = C.unit_seq_no

	WHERE A.drg_no IN ('469', '470') 
	AND A.Plm_Pt_Acct_Type = 'I' 
	AND A.PtNo_Num < '20000000' 
	AND LEFT(A.PtNo_Num, 4) != '1999' 
	AND A.User_Pyr1_Cat = 'AAA'
	AND A.Dsch_Date >= @START
	AND A.Dsch_Date <  @END 
)

INSERT INTO @InitPop
SELECT * FROM INITPOP A

--SELECT * FROM @InitPop

/*
=======================================================================
Is the case a 30 day readmission with a primary MS-DRG that is excluded
=======================================================================
*/
DECLARE @ExcludedReadmits TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Initial_Encounter   INT
	, Readmit_Encounter   INT
	, Readmit_MSDRG       VARCHAR(3)
);

WITH READMIT AS (
	SELECT A.[INDEX]
	, A.[READMIT]
	, B.drg_no
	
	FROM SMSDSS.vReadmits              AS A
	INNER JOIN SMSDSS.BMH_PLM_PTACCT_V AS B
	ON A.[READMIT] = B.PtNo_Num

	WHERE A.[INTERIM] < 31
	AND B.drg_no IN (
		'001', 	'002', 	'005', 	'006', 	'007', 	'008', 	'009', 	'010', 
		'011', 	'012', 	'013', 	'014', 	'015', 	'016', 	'017', 	'020', 
		'021', 	'022', 	'023', 	'024', 	'025', 	'026', 	'027', 	'028', 
		'029',  '030',  '031', 	'032', 	'033', 	'037', 	'038', 	'039', 
		'040', 	'041', 	'042', 	'052', 	'053', 	'054', 	'055', 	'082', 
		'083', 	'084', 	'085', 	'086', 	'087', 	'088', 	'089', 	'090', 
		'113', 	'114', 	'115', 	'116', 	'117', 	'129', 	'130', 	'131', 
		'132', 	'133', 	'134', 	'135', 	'136', 	'137', 	'138', 	'139', 
		'146', 	'147', 	'148', 	'163', 	'164', 	'165', 	'180', 	'181', 
		'182', 	'183', 	'184', 	'185', 	'216', 	'217', 	'218', 	'219', 
		'220', 	'221', 	'222', 	'223', 	'224', 	'225', 	'226', 	'227', 
		'228', 	'229', 	'230', 	'237', 	'238', 	'242', 	'243', 	'244', 
		'245', 	'258', 	'259', 	'260', 	'261', 	'262', 	'263', 	'264', 
		'265', 	'266', 	'267', 	'268', 	'269', 	'270', 	'271', 	'272', 
		'326', 	'327', 	'328', 	'329', 	'330', 	'331', 	'332', 	'333', 
		'334', 	'335', 	'336', 	'337', 	'338', 	'339', 	'340', 	'341', 
		'342', 	'343', 	'344', 	'345', 	'346', 	'347', 	'348', 	'349', 
		'350', 	'351', 	'352', 	'353', 	'354', 	'355', 	'374', 	'375', 
		'376', 	'405', 	'406', 	'407', 	'408', 	'409', 	'410', 	'411', 
		'412', 	'413', 	'414', 	'415', 	'416', 	'417', 	'418', 	'419', 
		'420', 	'421', 	'422', 	'423', 	'424', 	'425', 	'435', 	'436', 
		'437', 	'453', 	'454', 	'455', 	'456', 	'457', 	'458', 	'459', 
		'460', 	'469', 	'470', 	'471', 	'472', 	'473', 	'490', 	'491', 
		'506', 	'507', 	'508', 	'510', 	'511', 	'512', 	'513', 	'514', 
		'518', 	'519', 	'520', 	'542', 	'543', 	'544', 	'582', 	'583', 
		'584', 	'585', 	'597', 	'598', 	'599', 	'604', 	'605', 	'614', 
		'615', 	'619', 	'620', 	'621', 	'625', 	'626', 	'627', 	'652', 
		'653', 	'654', 	'655', 	'656', 	'657', 	'658', 	'659', 	'660', 
		'661', 	'662', 	'663', 	'664', 	'665', 	'666', 	'667', 	'668', 
		'669', 	'670', 	'671', 	'672', 	'686', 	'687', 	'688', 	'707', 
		'708', 	'709', 	'710', 	'711', 	'712', 	'713', 	'714', 	'715', 
		'716', 	'717', 	'718', 	'722', 	'723', 	'724', 	'734', 	'735', 
		'736', 	'737', 	'738', 	'739', 	'740', 	'741', 	'742', 	'743', 
		'744', 	'745', 	'746', 	'747', 	'748', 	'749', 	'750', 	'754', 
		'755', 	'756', 	'765', 	'766', 	'767', 	'768', 	'769', 	'770', 
		'799', 	'800', 	'801', 	'814', 	'815', 	'816', 	'820', 	'821', 
		'822', 	'823', 	'824', 	'825', 	'826', 	'827', 	'828', 	'829', 
		'830', 	'834', 	'835', 	'836', 	'837', 	'838', 	'839', 	'840', 
		'841', 	'842', 	'843', 	'844', 	'845', 	'846', 	'847', 	'848', 
		'849', 	'876', 	'906', 	'913', 	'914',  '927', 	'928', 	'929', 
		'933', 	'934', 	'935', 	'955', 	'956', 	'957', 	'958', 	'959', 
		'963', 	'964', 	'965', 	'969', 	'970', 	'984', 	'985', 	'986'
	)
)

INSERT INTO @ExcludedReadmits
SELECT * FROM READMIT

--SELECT * FROM @ExcludedReadmits

/*
=======================================================================
Does pt have a secondary dx_cd of Hip_Fx
=======================================================================
*/
DECLARE @SecondaryHip_Fx TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter           INT
	, Dx_Code             VARCHAR(15)
	, RN                  INT
);

WITH DxCd AS (
	SELECT pt_id
	, dx_cd
	, ROW_NUMBER() OVER(
		PARTITION BY PT_ID
		ORDER BY DX_CD_PRIO ASC
	) AS RN

	FROM smsmir.mir_dx_grp

	WHERE LEFT(dx_cd_type, 2) = 'DF'
	AND dx_cd IN (
		-- ICD-9 codes
		'820.00', '820.01', '820.02', '820.03', '820.09', '820.10',
		'820.11', '820.12', '820.13', '820.19', '820.20', '820.21',
		'820.22', '820.30', '820.31', '820.32', '820.8' , '820.9',
		-- ICD-10 codes
		'S72.019A', 'S72.023A', 'S72.026A', 'S72.033A', 'S72.036A', 
		'S72.043A', 'S72.046A', 'S72.099A', 'S72.019B', 'S72.019C', 
		'S72.023B', 'S72.023C', 'S72.026B', 'S72.026C', 'S72.033B', 
		'S72.033C', 'S72.036B', 'S72.036C', 'S72.043B', 'S72.043C', 
		'S72.046B', 'S72.046C', 'S72.099B', 'S72.099C', 'S72.109A', 
		'S72.143A', 'S72.146A', 'S72.23XA', 'S72.26XA', 'S72.109B', 
		'S72.109C', 'S72.143B', 'S72.143C', 'S72.146B', 'S72.146C', 
		'S72.23XB', 'S72.23XC', 'S72.26XB', 'S72.26XC', 'S72.009A', 
		'S72.009B', 'S72.009C'
	)
	AND dx_eff_dtime >= @START
	AND dx_cd_prio != '01'
	AND LEN(pt_id) >= 8
)

INSERT INTO @SecondaryHip_Fx
SELECT * FROM DxCd
WHERE RN = 1

--SELECT * FROM @SecondaryHip_Fx

/*
=======================================================================
Pull together Init-Pop and Readmit
=======================================================================
*/
SELECT *

FROM @InitPop                     AS A
LEFT OUTER JOIN @ExcludedReadmits AS B
ON A.Encounter = B.Initial_Encounter
LEFT OUTER JOIN @SecondaryHip_Fx  AS C
ON A.Encounter = C.Encounter