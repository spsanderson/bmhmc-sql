SELECT [SURVEY DESIGNATOR] = 'IN0101P'
, [CLIENT ID] = '725'
, [LAST NAME] = A.pt_last_name
, [MIDDLE INITIAL] = ''
, [FIRST NAME] = A.pt_first_name 
, [ADDRESS 1] = B.addr_line1
, [CITY] = B.addr_line2
, [STATE] = B.addr_line3
, [ZIP CODE] = PLM.Pt_Zip_Cd
, [TELEPHONE NUMBER] = A.pt_rpt_phone_no
, [MS-DRG] = PLM.drg_no
, [GENDER] = SEX.PT_SEX 
, [DATE OF BIRTH] = REPLACE(CONVERT(VARCHAR(10), PLM.Pt_Birthdate, 101), '/','')
, [LANGUAGE] = LANG.LANG
, [MEDICAL RECORD NUMBER] = PLM.Med_Rec_No
, [UNIQUE ID] = PLM.PtNo_Num
, [ADMISSION SOURCE] = ADM_SRC.ADM_SRC
, [ADMIT DATE] = REPLACE(CONVERT(VARCHAR(10), PLM.Adm_Date, 101), '/', '')
, [DISCHARGE DATE] = REPLACE(CONVERT(VARCHAR(10), PLM.Dsch_Date, 101), '/', '')
, [PATIENT DISCHARGE STATUS] = DSCH_DISP.DSCH_DISP
, [UNIT] = A.ward_cd
, [PATIENT EMAIL] = D.UserDataText
, [ATTENDING PHYSICIAN NPI] = E.npi_no
, [ATTENDING PHYSICIAN NAME] = E.pract_rpt_name
, [SPECIALTY] = E.med_staff_dept
, [ER_ADMIT] = PLM.ED_Adm
, [E.O.R INDICATOR] = '$'

FROM smsdss.BMH_PLM_PtAcct_V             AS PLM
INNER JOIN smsmir.vst_rpt                AS A
ON PLM.Pt_No = A.pt_id
LEFT JOIN smsmir.pers_addr               AS B
ON A.pt_id = B.pt_id
	AND B.pers_type = 'PT'
LEFT MERGE JOIN smsdss.BMH_UserTwoFact_V AS C
ON PLM.PtNo_Num = C.PtNo_Num
	AND C.UserDataKey = '98'
LEFT MERGE JOIN smsdss.BMH_UserTwoFact_V AS D
ON PLM.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '631'
LEFT MERGE JOIN smsdss.pract_dim_v       AS E
ON PLM.Atn_Dr_No = E.src_pract_no
	AND E.orgz_cd = 'S0X0'

CROSS APPLY (
	SELECT
		CASE
			WHEN PLM.Pt_Sex = 'M' THEN '1'
			WHEN PLM.Pt_Sex = 'F' THEN '2'
			ELSE 'M'
	END AS PT_SEX
) SEX

CROSS APPLY (
	SELECT
		CASE
			WHEN PLM.Adm_Source IN ('EO', 'RP', 'TA') THEN '1'
			WHEN PLM.Adm_Source = 'TE' THEN '5'
			WHEN PLM.Adm_Source = 'RM' THEN '3'
			WHEN PLM.Adm_Source IN ('TH', 'TO') THEN '4'
			WHEN PLM.Adm_Source = 'OP' THEN '2'
			WHEN PLM.Adm_Source = 'TB' THEN '8'
			WHEN PLM.Adm_Source = 'TV' THEN 'D'
			WHEN PLM.Adm_Source = 'AS' THEN 'E'
			WHEN PLM.Adm_Source = 'HS' THEN 'F'
			ELSE 'M'
	END AS ADM_SRC
) ADM_SRC

CROSS APPLY (
	SELECT
		CASE
			WHEN PLM.dsch_disp IN ('AHR','AHF', 'HR', 'HF') THEN '01'
			WHEN PLM.dsch_disp IN ('ATW', 'TW') THEN '06'
			WHEN PLM.dsch_disp IN ('AMA', 'MA') THEN '07'
			WHEN PLM.dsch_disp IN ('ATE', 'ATL', 'TE', 'TL') THEN '03'
			WHEN PLM.dsch_disp IN ('ATH', 'TH') THEN '02'
			WHEN PLM.dsch_disp IN ('ATV', 'ATO', 'AMN', 'ATF') THEN '05'
			WHEN PLM.dsch_disp IN ('ATR', 'ATI') THEN '04'
			WHEN PLM.dsch_disp IN ('ATT', 'AHI') THEN '50'
			WHEN PLM.dsch_disp IN ('ATP', 'AOU', 'AHB') THEN '65'
			WHEN PLM.dsch_disp IN ('ATM', 'ATX') THEN '62'
			WHEN PLM.dsch_disp IN ('ATB') THEN '21'
			WHEN PLM.dsch_disp IN ('ATN') THEN '43'
			WHEN LEFT(PLM.dsch_disp, 1) IN ('C', 'D') THEN '20'
			ELSE 'M'
	END AS DSCH_DISP
) DSCH_DISP

CROSS APPLY (
	SELECT
		CASE
			WHEN C.UserDataText = 'ENGLISH' THEN '0'
			WHEN C.UserDataText = 'SPANISH' THEN '1'
			WHEN C.UserDataText = 'RUSSIAN' THEN '3'
			WHEN C.UserDataText = 'ITALIAN' THEN '5'
			WHEN C.UserDataText = 'POLISH'  THEN '6'
			WHEN C.UserDataText = 'CHINESE' THEN '10'
			ELSE ''
	END AS LANG
) LANG

--WHERE PLM.Dsch_Date >= '2016-03-01'
--AND PLM.DSCH_DATE < '2016-04-01'
WHERE PLM.DSCH_DATE = CAST(GETDATE()-1 AS DATE)
AND PLM.Plm_Pt_Acct_Type = 'I'
AND PLM.tot_chg_amt > 0
AND LEFT(PLM.PTNO_NUM, 4) != '1999'
AND PLM.PtNo_Num < '20000000'
AND LEFT(PLM.dsch_disp, 1) NOT IN ('C', 'D')
AND PLM.Adm_Source NOT IN ('NE', 'NB')

OPTION(FORCE ORDER);