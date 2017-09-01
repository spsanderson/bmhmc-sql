-- Get initial SHFFT population
---------------------------------------------------------------------------------------------------
SELECT PLM.Med_Rec_No
, PLM.PtNo_Num
, '0' AS RA_FLAG
, CAST(PLM.Adm_Date AS date) AS ADM_DATE
, CAST(PLM.DSCH_DATE AS date) AS DSCH_DATE
, DATEPART(YEAR, PLM.ADM_DATE) AS ADM_YR
, DATEPART(MONTH, PLM.ADM_DATE) AS ADM_MO
, DATEPART(YEAR, PLM.Dsch_Date) AS DSCH_YR
, DATEPART(MONTH, PLM.Dsch_Date) AS DSCH_MO
, PLM.Days_Stay
, PLM.drg_no
, PLM.drg_cost_weight
, PLM.drg_outl_ind
, DOI.drg_outl_ind_desc
, PLM.dsch_disp
, CASE
	WHEN LEFT(PLM.DSCH_DISP, 1) IN ('C', 'D')
		THEN 1
		ELSE 0
  END AS MORTALITY_FLAG
, PLM.User_Pyr1_Cat
, CAST(PLM.tot_chg_amt AS money) AS TOT_CHG_AMT
, CAST(PIP.tot_pymts_w_pip AS money) AS TOT_PIP_PMTS
, CAST(PLM.Tot_Amt_Due AS money) AS TOT_AMT_DUE
, CAST((-PIP.tot_pymts_w_pip + PLM.Tot_Amt_Due) AS money) AS NET_REV

INTO #TEMPA

FROM smsdss.BMH_PLM_PtAcct_V AS PLM
LEFT JOIN smsdss.c_tot_pymts_w_pip_v AS PIP
ON PLM.Pt_No = PIP.pt_id
LEFT JOIN smsdss.drg_outl_ind_dim_v AS DOI
ON PLM.drg_outl_ind = DOI.drg_outl_ind
	AND PLM.Regn_Hosp = DOI.orgz_cd

WHERE PLM.drg_no IN (
	-- The following MS-DRGs can initiate SHFFT episodes on or after 
	-- July 1, 2017
	'480', -- Hip and Femur Procedures Except Major Joint W Mcc
	'481', -- Hip and Femur Procedures Except Major Joint W CC
	'482'  -- Hip and Femur Procedures Except Major Joint W/O Cc/Mcc
)
AND PLM.User_Pyr1_Cat IN (
	-- Only Medicare FFS Patients
	'AAA', 'ZZZ'
)
AND PLM.Dsch_Date >= '2015-01-01'
AND PLM.Dsch_Date < '2017-07-01'
;
---------------------------------------------------------------------------------------------------

SELECT RA.*
, PLM.drg_no
, RA_EXC.RA_EXC

INTO #TEMPB

FROM smsdss.vReadmits AS RA
LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS PLM
ON RA.[READMIT] = PLM.PtNo_Num
	AND RA.MRN = PLM.Med_Rec_No

CROSS APPLY (
	SELECT
		CASE
			WHEN PLM.drg_no = '1' THEN 1
			WHEN PLM.drg_no = '2' THEN 1
			WHEN PLM.drg_no = '5' THEN 1
			WHEN PLM.drg_no = '6' THEN 1
			WHEN PLM.drg_no = '7' THEN 1
			WHEN PLM.drg_no = '8' THEN 1
			WHEN PLM.drg_no = '9' THEN 1
			WHEN PLM.drg_no = '10' THEN 1
			WHEN PLM.drg_no = '11' THEN 1
			WHEN PLM.drg_no = '12' THEN 1
			WHEN PLM.drg_no = '13' THEN 1
			WHEN PLM.drg_no = '14' THEN 1
			WHEN PLM.drg_no = '15' THEN 1
			WHEN PLM.drg_no = '16' THEN 1
			WHEN PLM.drg_no = '17' THEN 1
			WHEN PLM.drg_no = '20' THEN 1
			WHEN PLM.drg_no = '21' THEN 1
			WHEN PLM.drg_no = '22' THEN 1
			WHEN PLM.drg_no = '23' THEN 1
			WHEN PLM.drg_no = '24' THEN 1
			WHEN PLM.drg_no = '25' THEN 1
			WHEN PLM.drg_no = '26' THEN 1
			WHEN PLM.drg_no = '27' THEN 1
			WHEN PLM.drg_no = '28' THEN 1
			WHEN PLM.drg_no = '29' THEN 1
			WHEN PLM.drg_no = '30' THEN 1
			WHEN PLM.drg_no = '31' THEN 1
			WHEN PLM.drg_no = '32' THEN 1
			WHEN PLM.drg_no = '33' THEN 1
			WHEN PLM.drg_no = '37' THEN 1
			WHEN PLM.drg_no = '38' THEN 1
			WHEN PLM.drg_no = '39' THEN 1
			WHEN PLM.drg_no = '40' THEN 1
			WHEN PLM.drg_no = '41' THEN 1
			WHEN PLM.drg_no = '42' THEN 1
			WHEN PLM.drg_no = '52' THEN 1
			WHEN PLM.drg_no = '53' THEN 1
			WHEN PLM.drg_no = '54' THEN 1
			WHEN PLM.drg_no = '55' THEN 1
			WHEN PLM.drg_no = '82' THEN 1
			WHEN PLM.drg_no = '83' THEN 1
			WHEN PLM.drg_no = '84' THEN 1
			WHEN PLM.drg_no = '85' THEN 1
			WHEN PLM.drg_no = '86' THEN 1
			WHEN PLM.drg_no = '87' THEN 1
			WHEN PLM.drg_no = '88' THEN 1
			WHEN PLM.drg_no = '89' THEN 1
			WHEN PLM.drg_no = '90' THEN 1
			WHEN PLM.drg_no = '113' THEN 1
			WHEN PLM.drg_no = '114' THEN 1
			WHEN PLM.drg_no = '115' THEN 1
			WHEN PLM.drg_no = '116' THEN 1
			WHEN PLM.drg_no = '117' THEN 1
			WHEN PLM.drg_no = '129' THEN 1
			WHEN PLM.drg_no = '130' THEN 1
			WHEN PLM.drg_no = '131' THEN 1
			WHEN PLM.drg_no = '132' THEN 1
			WHEN PLM.drg_no = '133' THEN 1
			WHEN PLM.drg_no = '134' THEN 1
			WHEN PLM.drg_no = '135' THEN 1
			WHEN PLM.drg_no = '136' THEN 1
			WHEN PLM.drg_no = '137' THEN 1
			WHEN PLM.drg_no = '138' THEN 1
			WHEN PLM.drg_no = '139' THEN 1
			WHEN PLM.drg_no = '146' THEN 1
			WHEN PLM.drg_no = '147' THEN 1
			WHEN PLM.drg_no = '148' THEN 1
			WHEN PLM.drg_no = '163' THEN 1
			WHEN PLM.drg_no = '164' THEN 1
			WHEN PLM.drg_no = '165' THEN 1
			WHEN PLM.drg_no = '180' THEN 1
			WHEN PLM.drg_no = '181' THEN 1
			WHEN PLM.drg_no = '182' THEN 1
			WHEN PLM.drg_no = '183' THEN 1
			WHEN PLM.drg_no = '184' THEN 1
			WHEN PLM.drg_no = '185' THEN 1
			WHEN PLM.drg_no = '216' THEN 1
			WHEN PLM.drg_no = '217' THEN 1
			WHEN PLM.drg_no = '218' THEN 1
			WHEN PLM.drg_no = '219' THEN 1
			WHEN PLM.drg_no = '220' THEN 1
			WHEN PLM.drg_no = '221' THEN 1
			WHEN PLM.drg_no = '222' THEN 1
			WHEN PLM.drg_no = '223' THEN 1
			WHEN PLM.drg_no = '224' THEN 1
			WHEN PLM.drg_no = '225' THEN 1
			WHEN PLM.drg_no = '226' THEN 1
			WHEN PLM.drg_no = '227' THEN 1
			WHEN PLM.drg_no = '228' THEN 1
			WHEN PLM.drg_no = '229' THEN 1
			WHEN PLM.drg_no = '230' THEN 1
			WHEN PLM.drg_no = '237' THEN 1
			WHEN PLM.drg_no = '238' THEN 1
			WHEN PLM.drg_no = '242' THEN 1
			WHEN PLM.drg_no = '243' THEN 1
			WHEN PLM.drg_no = '244' THEN 1
			WHEN PLM.drg_no = '245' THEN 1
			WHEN PLM.drg_no = '258' THEN 1
			WHEN PLM.drg_no = '259' THEN 1
			WHEN PLM.drg_no = '260' THEN 1
			WHEN PLM.drg_no = '261' THEN 1
			WHEN PLM.drg_no = '262' THEN 1
			WHEN PLM.drg_no = '263' THEN 1
			WHEN PLM.drg_no = '264' THEN 1
			WHEN PLM.drg_no = '265' THEN 1
			WHEN PLM.drg_no = '266' THEN 1
			WHEN PLM.drg_no = '267' THEN 1
			WHEN PLM.drg_no = '268' THEN 1
			WHEN PLM.drg_no = '269' THEN 1
			WHEN PLM.drg_no = '270' THEN 1
			WHEN PLM.drg_no = '271' THEN 1
			WHEN PLM.drg_no = '272' THEN 1
			WHEN PLM.drg_no = '326' THEN 1
			WHEN PLM.drg_no = '327' THEN 1
			WHEN PLM.drg_no = '328' THEN 1
			WHEN PLM.drg_no = '329' THEN 1
			WHEN PLM.drg_no = '330' THEN 1
			WHEN PLM.drg_no = '331' THEN 1
			WHEN PLM.drg_no = '332' THEN 1
			WHEN PLM.drg_no = '333' THEN 1
			WHEN PLM.drg_no = '334' THEN 1
			WHEN PLM.drg_no = '335' THEN 1
			WHEN PLM.drg_no = '336' THEN 1
			WHEN PLM.drg_no = '337' THEN 1
			WHEN PLM.drg_no = '338' THEN 1
			WHEN PLM.drg_no = '339' THEN 1
			WHEN PLM.drg_no = '340' THEN 1
			WHEN PLM.drg_no = '341' THEN 1
			WHEN PLM.drg_no = '342' THEN 1
			WHEN PLM.drg_no = '343' THEN 1
			WHEN PLM.drg_no = '344' THEN 1
			WHEN PLM.drg_no = '345' THEN 1
			WHEN PLM.drg_no = '346' THEN 1
			WHEN PLM.drg_no = '347' THEN 1
			WHEN PLM.drg_no = '348' THEN 1
			WHEN PLM.drg_no = '349' THEN 1
			WHEN PLM.drg_no = '350' THEN 1
			WHEN PLM.drg_no = '351' THEN 1
			WHEN PLM.drg_no = '352' THEN 1
			WHEN PLM.drg_no = '353' THEN 1
			WHEN PLM.drg_no = '354' THEN 1
			WHEN PLM.drg_no = '355' THEN 1
			WHEN PLM.drg_no = '374' THEN 1
			WHEN PLM.drg_no = '375' THEN 1
			WHEN PLM.drg_no = '376' THEN 1
			WHEN PLM.drg_no = '405' THEN 1
			WHEN PLM.drg_no = '406' THEN 1
			WHEN PLM.drg_no = '407' THEN 1
			WHEN PLM.drg_no = '408' THEN 1
			WHEN PLM.drg_no = '409' THEN 1
			WHEN PLM.drg_no = '410' THEN 1
			WHEN PLM.drg_no = '411' THEN 1
			WHEN PLM.drg_no = '412' THEN 1
			WHEN PLM.drg_no = '413' THEN 1
			WHEN PLM.drg_no = '414' THEN 1
			WHEN PLM.drg_no = '415' THEN 1
			WHEN PLM.drg_no = '416' THEN 1
			WHEN PLM.drg_no = '417' THEN 1
			WHEN PLM.drg_no = '418' THEN 1
			WHEN PLM.drg_no = '419' THEN 1
			WHEN PLM.drg_no = '420' THEN 1
			WHEN PLM.drg_no = '421' THEN 1
			WHEN PLM.drg_no = '422' THEN 1
			WHEN PLM.drg_no = '423' THEN 1
			WHEN PLM.drg_no = '424' THEN 1
			WHEN PLM.drg_no = '425' THEN 1
			WHEN PLM.drg_no = '435' THEN 1
			WHEN PLM.drg_no = '436' THEN 1
			WHEN PLM.drg_no = '437' THEN 1
			WHEN PLM.drg_no = '453' THEN 1
			WHEN PLM.drg_no = '454' THEN 1
			WHEN PLM.drg_no = '455' THEN 1
			WHEN PLM.drg_no = '456' THEN 1
			WHEN PLM.drg_no = '457' THEN 1
			WHEN PLM.drg_no = '458' THEN 1
			WHEN PLM.drg_no = '459' THEN 1
			WHEN PLM.drg_no = '460' THEN 1
			WHEN PLM.drg_no = '471' THEN 1
			WHEN PLM.drg_no = '472' THEN 1
			WHEN PLM.drg_no = '473' THEN 1
			WHEN PLM.drg_no = '490' THEN 1
			WHEN PLM.drg_no = '491' THEN 1
			WHEN PLM.drg_no = '506' THEN 1
			WHEN PLM.drg_no = '507' THEN 1
			WHEN PLM.drg_no = '508' THEN 1
			WHEN PLM.drg_no = '510' THEN 1
			WHEN PLM.drg_no = '511' THEN 1
			WHEN PLM.drg_no = '512' THEN 1
			WHEN PLM.drg_no = '513' THEN 1
			WHEN PLM.drg_no = '514' THEN 1
			WHEN PLM.drg_no = '518' THEN 1
			WHEN PLM.drg_no = '519' THEN 1
			WHEN PLM.drg_no = '520' THEN 1
			WHEN PLM.drg_no = '542' THEN 1
			WHEN PLM.drg_no = '543' THEN 1
			WHEN PLM.drg_no = '544' THEN 1
			WHEN PLM.drg_no = '582' THEN 1
			WHEN PLM.drg_no = '583' THEN 1
			WHEN PLM.drg_no = '584' THEN 1
			WHEN PLM.drg_no = '585' THEN 1
			WHEN PLM.drg_no = '597' THEN 1
			WHEN PLM.drg_no = '598' THEN 1
			WHEN PLM.drg_no = '599' THEN 1
			WHEN PLM.drg_no = '604' THEN 1
			WHEN PLM.drg_no = '605' THEN 1
			WHEN PLM.drg_no = '614' THEN 1
			WHEN PLM.drg_no = '615' THEN 1
			WHEN PLM.drg_no = '619' THEN 1
			WHEN PLM.drg_no = '620' THEN 1
			WHEN PLM.drg_no = '621' THEN 1
			WHEN PLM.drg_no = '625' THEN 1
			WHEN PLM.drg_no = '626' THEN 1
			WHEN PLM.drg_no = '627' THEN 1
			WHEN PLM.drg_no = '652' THEN 1
			WHEN PLM.drg_no = '653' THEN 1
			WHEN PLM.drg_no = '654' THEN 1
			WHEN PLM.drg_no = '655' THEN 1
			WHEN PLM.drg_no = '656' THEN 1
			WHEN PLM.drg_no = '657' THEN 1
			WHEN PLM.drg_no = '658' THEN 1
			WHEN PLM.drg_no = '659' THEN 1
			WHEN PLM.drg_no = '660' THEN 1
			WHEN PLM.drg_no = '661' THEN 1
			WHEN PLM.drg_no = '662' THEN 1
			WHEN PLM.drg_no = '663' THEN 1
			WHEN PLM.drg_no = '664' THEN 1
			WHEN PLM.drg_no = '665' THEN 1
			WHEN PLM.drg_no = '666' THEN 1
			WHEN PLM.drg_no = '667' THEN 1
			WHEN PLM.drg_no = '668' THEN 1
			WHEN PLM.drg_no = '669' THEN 1
			WHEN PLM.drg_no = '670' THEN 1
			WHEN PLM.drg_no = '671' THEN 1
			WHEN PLM.drg_no = '672' THEN 1
			WHEN PLM.drg_no = '686' THEN 1
			WHEN PLM.drg_no = '687' THEN 1
			WHEN PLM.drg_no = '688' THEN 1
			WHEN PLM.drg_no = '707' THEN 1
			WHEN PLM.drg_no = '708' THEN 1
			WHEN PLM.drg_no = '709' THEN 1
			WHEN PLM.drg_no = '710' THEN 1
			WHEN PLM.drg_no = '711' THEN 1
			WHEN PLM.drg_no = '712' THEN 1
			WHEN PLM.drg_no = '713' THEN 1
			WHEN PLM.drg_no = '714' THEN 1
			WHEN PLM.drg_no = '715' THEN 1
			WHEN PLM.drg_no = '716' THEN 1
			WHEN PLM.drg_no = '717' THEN 1
			WHEN PLM.drg_no = '718' THEN 1
			WHEN PLM.drg_no = '722' THEN 1
			WHEN PLM.drg_no = '723' THEN 1
			WHEN PLM.drg_no = '724' THEN 1
			WHEN PLM.drg_no = '734' THEN 1
			WHEN PLM.drg_no = '735' THEN 1
			WHEN PLM.drg_no = '736' THEN 1
			WHEN PLM.drg_no = '737' THEN 1
			WHEN PLM.drg_no = '738' THEN 1
			WHEN PLM.drg_no = '739' THEN 1
			WHEN PLM.drg_no = '740' THEN 1
			WHEN PLM.drg_no = '741' THEN 1
			WHEN PLM.drg_no = '742' THEN 1
			WHEN PLM.drg_no = '743' THEN 1
			WHEN PLM.drg_no = '744' THEN 1
			WHEN PLM.drg_no = '745' THEN 1
			WHEN PLM.drg_no = '746' THEN 1
			WHEN PLM.drg_no = '747' THEN 1
			WHEN PLM.drg_no = '748' THEN 1
			WHEN PLM.drg_no = '749' THEN 1
			WHEN PLM.drg_no = '750' THEN 1
			WHEN PLM.drg_no = '754' THEN 1
			WHEN PLM.drg_no = '755' THEN 1
			WHEN PLM.drg_no = '756' THEN 1
			WHEN PLM.drg_no = '765' THEN 1
			WHEN PLM.drg_no = '766' THEN 1
			WHEN PLM.drg_no = '767' THEN 1
			WHEN PLM.drg_no = '768' THEN 1
			WHEN PLM.drg_no = '769' THEN 1
			WHEN PLM.drg_no = '770' THEN 1
			WHEN PLM.drg_no = '799' THEN 1
			WHEN PLM.drg_no = '800' THEN 1
			WHEN PLM.drg_no = '801' THEN 1
			WHEN PLM.drg_no = '814' THEN 1
			WHEN PLM.drg_no = '815' THEN 1
			WHEN PLM.drg_no = '816' THEN 1
			WHEN PLM.drg_no = '820' THEN 1
			WHEN PLM.drg_no = '821' THEN 1
			WHEN PLM.drg_no = '822' THEN 1
			WHEN PLM.drg_no = '823' THEN 1
			WHEN PLM.drg_no = '824' THEN 1
			WHEN PLM.drg_no = '825' THEN 1
			WHEN PLM.drg_no = '826' THEN 1
			WHEN PLM.drg_no = '827' THEN 1
			WHEN PLM.drg_no = '828' THEN 1
			WHEN PLM.drg_no = '829' THEN 1
			WHEN PLM.drg_no = '830' THEN 1
			WHEN PLM.drg_no = '834' THEN 1
			WHEN PLM.drg_no = '835' THEN 1
			WHEN PLM.drg_no = '836' THEN 1
			WHEN PLM.drg_no = '837' THEN 1
			WHEN PLM.drg_no = '838' THEN 1
			WHEN PLM.drg_no = '839' THEN 1
			WHEN PLM.drg_no = '840' THEN 1
			WHEN PLM.drg_no = '841' THEN 1
			WHEN PLM.drg_no = '842' THEN 1
			WHEN PLM.drg_no = '843' THEN 1
			WHEN PLM.drg_no = '844' THEN 1
			WHEN PLM.drg_no = '845' THEN 1
			WHEN PLM.drg_no = '846' THEN 1
			WHEN PLM.drg_no = '847' THEN 1
			WHEN PLM.drg_no = '848' THEN 1
			WHEN PLM.drg_no = '849' THEN 1
			WHEN PLM.drg_no = '876' THEN 1
			WHEN PLM.drg_no = '906' THEN 1
			WHEN PLM.drg_no = '913' THEN 1
			WHEN PLM.drg_no = '914' THEN 1
			WHEN PLM.drg_no = '927' THEN 1
			WHEN PLM.drg_no = '928' THEN 1
			WHEN PLM.drg_no = '929' THEN 1
			WHEN PLM.drg_no = '933' THEN 1
			WHEN PLM.drg_no = '934' THEN 1
			WHEN PLM.drg_no = '935' THEN 1
			WHEN PLM.drg_no = '955' THEN 1
			WHEN PLM.drg_no = '956' THEN 1
			WHEN PLM.drg_no = '957' THEN 1
			WHEN PLM.drg_no = '958' THEN 1
			WHEN PLM.drg_no = '959' THEN 1
			WHEN PLM.drg_no = '963' THEN 1
			WHEN PLM.drg_no = '964' THEN 1
			WHEN PLM.drg_no = '965' THEN 1
			WHEN PLM.drg_no = '969' THEN 1
			WHEN PLM.drg_no = '970' THEN 1
			WHEN PLM.drg_no = '984' THEN 1
			WHEN PLM.drg_no = '985' THEN 1
			WHEN PLM.drg_no = '986' THEN 1
			ELSE 0
		END AS RA_EXC
) RA_EXC
WHERE RA.[INDEX] IN (
	SELECT ZZZ.PtNo_Num
	FROM #TEMPA AS ZZZ
)
AND RA.[INTERIM] < 31
;

---------------------------------------------------------------------------------------------------
-- Get non-excluded readmissions
---------------------------------------------------------------------------------------------------
SELECT PLM.Med_Rec_No
, PLM.PtNo_Num
, '1' AS RA_FLAG
, CAST(PLM.Adm_Date AS date) AS ADM_DATE
, CAST(PLM.DSCH_DATE AS date) AS DSCH_DATE
, DATEPART(YEAR, PLM.ADM_DATE) AS ADM_YR
, DATEPART(MONTH, PLM.ADM_DATE) AS ADM_MO
, DATEPART(YEAR, PLM.Dsch_Date) AS DSCH_YR
, DATEPART(MONTH, PLM.Dsch_Date) AS DSCH_MO
, PLM.Days_Stay
, PLM.drg_no
, PLM.drg_cost_weight
, PLM.drg_outl_ind
, DOI.drg_outl_ind_desc
, PLM.dsch_disp
, CASE
	WHEN LEFT(PLM.DSCH_DISP, 1) IN ('C', 'D')
		THEN 1
		ELSE 0
  END AS MORTALITY_FLAG
, PLM.User_Pyr1_Cat
, CAST(PLM.tot_chg_amt AS money) AS TOT_CHG_AMT
, CAST(PIP.tot_pymts_w_pip AS money) AS TOT_PIP_PMTS
, CAST(PLM.Tot_Amt_Due AS money) AS TOT_AMT_DUE
, CAST((-PIP.tot_pymts_w_pip + PLM.Tot_Amt_Due) AS money) AS NET_REV

INTO #TEMPC

FROM smsdss.BMH_PLM_PtAcct_V AS PLM
LEFT JOIN smsdss.c_tot_pymts_w_pip_v AS PIP
ON PLM.Pt_No = PIP.pt_id
LEFT JOIN smsdss.drg_outl_ind_dim_v AS DOI
ON PLM.drg_outl_ind = DOI.drg_outl_ind
	AND PLM.Regn_Hosp = DOI.orgz_cd

WHERE PLM.PtNo_Num IN (
	SELECT RA.[READMIT]
	FROM #TEMPB AS RA
	WHERE RA.RA_EXC != 1 -- KICK OUT READMISSIONS THAT ARE EXCLUDED
)
;
---------------------------------------------------------------------------------------------------
SELECT A.*

--INTO #TEMPD

FROM (
	SELECT A.*
	FROM #TEMPA AS A

	UNION ALL
	
	SELECT C.*
	FROM #TEMPC AS C
) AS A

ORDER BY A.Med_Rec_No
, A.ADM_DATE
;

---------------------------------------------------------------------------------------------------

--DROP TABLE #TEMPA;
--DROP TABLE #TEMPB;
--DROP TABLE #TEMPC;