SELECT [SURVEY DESIGNATOR] = 'AS0101'
, [CLIENT ID] = '725'
, [LAST NAME] = ISNULL(A.pt_last_name, '')
, [MIDDLE INITIAL] = ''
, [FIRST NAME] = ISNULL(A.pt_first_name , '')
, [ADDRESS 1] = ISNULL(B.addr_line1, '')
, [ADDRESS 2] = ISNULL(B.addr_line2, '')
, [CITY] = ISNULL(B.addr_line2, '')
, [STATE] = ISNULL(B.addr_line3, '')
, [ZIP CODE] = ISNULL(PLM.Pt_Zip_Cd, '')
, [TELEPHONE NUMBER] = ISNULL(A.pt_rpt_phone_no, '')
, [GENDER] = ISNULL(SEX.PT_SEX , '')
, [DATE OF BIRTH] = REPLACE(CONVERT(VARCHAR(10), PLM.Pt_Birthdate, 101), '/','')
, [LANGUAGE] = ISNULL(LANG.LANG, '')
, [MEDICAL RECORD NUMBER] = PLM.Med_Rec_No
, [UNIQUE ID] = PLM.PtNo_Num
, [ATTENDING PHYSICIAN NPI] = ISNULL(E.npi_no, '')
, CASE
       WHEN RIGHT(ISNULL(upper(e.pract_rpt_name), ''),1) = 'x'
       THEN SUBSTRING(e.pract_rpt_name, 1, CHARINDEX('X',E.PRACT_RPT_NAME, 1)-1)
       ELSE ISNULL(UPPER(E.pract_rpt_name), '')
  END AS [ATTENDING PHYSICIAN NAME]
, [ADMISSION SOURCE] = ISNULL(ADM_SRC.ADM_SRC, '')
, [ADMIT DATE] = REPLACE(CONVERT(VARCHAR(10), PLM.Adm_Date, 101), '/', '')
, [PATIENT DISCHARGE STATUS] = ISNULL(DSCH_DISP.DSCH_DISP, '')
, [UNIT] = ISNULL(A.ward_cd, '')
--, [PATIENT EMAIL] = ISNULL(D.UserDataText, '')
, [SPECIALTY] = ISNULL(E.spclty_desc, '')
--, [ER_ADMIT] = ISNULL(PLM.ED_Adm, ''
, [E.O.R INDICATOR] = '$'

INTO #TEMP_A

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
                     WHEN PLM.dsch_disp IN ('AHR','AHF', 'HR', 'HF', ' HR', ' HF') THEN '01'
                     WHEN PLM.dsch_disp IN ('ATW', 'TW', ' TW') THEN '06'
                     WHEN PLM.dsch_disp IN ('AMA', 'MA', ' MA') THEN '07'
                     WHEN PLM.dsch_disp IN ('ATE', 'ATL', 'TE', 'TL', ' TE', ' TL') THEN '03'
                     WHEN PLM.dsch_disp IN ('ATH', 'TH', ' TH') THEN '02'
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

WHERE PLM.Dsch_Date >= '2017-10-01'
AND PLM.DSCH_DATE < '2017-11-01'
--WHERE PLM.DSCH_DATE = CAST(GETDATE()-1 AS DATE)
AND PLM.Plm_Pt_Acct_Type = 'O'
AND PLM.tot_chg_amt > 0
AND PLM.Pt_No IN (
       SELECT DISTINCT(ZZZ.Pt_No)
       FROM smsdss.BMH_PLM_PtAcct_Clasf_Proc_V_New AS ZZZ
       WHERE (
			ZZZ.ClasfCd BETWEEN '10021' AND '69990' 
			OR
			ZZZ.clasfCd IN (
				'G0104','G0105','G0121','G0260'
			)
       )
)

OPTION(FORCE ORDER);

-----

SELECT *

INTO #TEMP_B

FROM (
       SELECT pt_id
       , proc_cd
       , proc_cd_prio

       FROM smsmir.sproc AS A
       
       WHERE A.proc_cd_prio IN (
		'01','02','03','04','05','06'
        )
        AND (
			(
				(
					proc_cd_modf1 != '73'
                    AND
                    proc_cd_modf1 != '74'
				)
				OR
				proc_cd_modf1 IS NULL
            )
			AND (
                (
					proc_cd_modf2 != '73'
                    AND
                    proc_cd_modf2 != '74'
				)
				OR
				proc_cd_modf2 IS NULL
			)
            AND (
				(
					proc_cd_modf3 != '73'
                    AND
                    proc_cd_modf3 != '74'
				)
				OR
				proc_cd_modf3 IS NULL
			)
		)
) A

PIVOT (
       MAX(PROC_CD)
       FOR PROC_CD_PRIO IN ("01","02", "03", "04", "05", "06")
) PVT

WHERE SUBSTRING(PT_ID, 5, 8) IN (
	SELECT ZZZ.[UNIQUE ID]
    FROM #TEMP_A AS ZZZ
	)
;

-----

SELECT A.[SURVEY DESIGNATOR]
, A.[CLIENT ID]
, A.[LAST NAME]
, A.[MIDDLE INITIAL]
, A.[FIRST NAME]
, A.[ADDRESS 1]
, A.[ADDRESS 2]
, A.[CITY]
, A.[STATE]
, A.[ZIP CODE]
, A.[TELEPHONE NUMBER]
, A.GENDER
, A.[DATE OF BIRTH]
, A.[LANGUAGE]
, A.[MEDICAL RECORD NUMBER]
, A.[UNIQUE ID]
, A.[ATTENDING PHYSICIAN NPI]
, A.[ATTENDING PHYSICIAN NAME]
, A.[ADMISSION SOURCE]
, A.[ADMIT DATE]
, A.[PATIENT DISCHARGE STATUS]
, A.UNIT
, A.SPECIALTY
--, A.[PATIENT EMAIL]
--, A.ER_ADMIT
, [Procdure Code 1] = B.[01]
, [Procdure Code 2] = B.[02]
, [Procdure Code 3] = B.[03]
, [Procdure Code 4] = B.[04]
, [Procdure Code 5] = B.[05]
, [Procdure Code 6] = B.[06]
, [Deceased Flag] = CASE WHEN A.[PATIENT DISCHARGE STATUS] = '20' THEN 'Y' ELSE 'N' END
, [No Publicity Flag] = 'N'
, [State Regulation Flag] = 'N'
, [Transferred/Admitted to IP] = 'N'
, A.[E.O.R INDICATOR]

FROM #TEMP_A AS A
LEFT OUTER JOIN #TEMP_B    AS B
ON A.[UNIQUE ID] = SUBSTRING(pt_id, 5, 8)

--where A.[UNIQUE ID] in (
--	''
--)
WHERE B.[01] IS NOT NULL

DROP TABLE #TEMP_A, #TEMP_B
