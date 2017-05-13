-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @START    DATE;
DECLARE @END      DATE;
DECLARE @BNP      VARCHAR(16);
DECLARE @TROP     VARCHAR(16);
DECLARE @LIHNTYPE VARCHAR(50);

SET @START    = '2014-04-01';
--SET @END      = '2014-05-01';
SET @END      = GETDATE();
SET @LIHNTYPE = 'A_LIHN TYPE';
SET @BNP      = '00408500';
SET @TROP     = '00408492';

/*
#######################################################################

THE FIRST QUERY IS GOING TO CALCULATE THE PATIENTS LACE SCORE THAT
WILL BE PULLED IN AT THE FINAL QUERY

#######################################################################
*/
 
DECLARE @T1 TABLE (
	ENCOUNTER_ID          VARCHAR(200)
	, MRN                 VARCHAR(200)
	, [PT AGE]            VARCHAR(200)
	, [PT NAME]           VARCHAR(500)
	, [DAYS STAY]         VARCHAR(200)
	, [LACE DAYS SCORE]   INT
	, [ACUTE ADMIT SCORE] INT
	, ARRIVAL             DATETIME
)

INSERT INTO @T1
SELECT
A.PtNo_Num
, A.MED_REC_NO
, A.PT_AGE
, A.PT_NAME
, A.DAYS_STAY
, A.LACE_DAYS_SCORE
, A.ACUTE_ADMIT_LACE_SCORE
, A.ADM_DATE

FROM
    (SELECT PtNo_Num
	, Med_Rec_No
    , Pt_Age
    , Pt_Name
    , Days_Stay
	, CASE
	    WHEN Days_Stay < 1              THEN 0
        WHEN Days_Stay = 1              THEN 1
        WHEN Days_Stay = 2              THEN 2
        WHEN Days_Stay = 3              THEN 3
        WHEN Days_Stay BETWEEN 4 AND 6  THEN 4
        WHEN Days_Stay BETWEEN 7 AND 13 THEN 5
        WHEN Days_Stay >= 14            THEN 6
      END AS LACE_DAYS_SCORE
	, CASE
	    WHEN PLM_PT_ACCT_TYPE = 'I'     THEN 3
	    ELSE 0
	  END AS ACUTE_ADMIT_LACE_SCORE
	, ADM_DATE
	
	FROM SMSDSS.BMH_PLM_PTACCT_V
	
	WHERE Adm_Date >= @START 
		AND Adm_Date < @END
		AND Plm_Pt_Acct_Type = 'I'
		AND PtNo_Num < '20000000'
)A

--SELECT * FROM @T1

/*
#######################################################################

ER VISITS QUERY: THIS QUERY WILL GET A COUNT OF THE AMOUNT OF TIMES
AN INDIVIDUAL HAS COME TO THE ER BASED UPON THE CURRENT VISIT ID

#######################################################################
*/

DECLARE @CNT TABLE (
	MRN           VARCHAR(100)
	, VISIT_ID    VARCHAR(100)
	, VISIT_DATE  DATETIME
	, VISIT_COUNT INT
)

INSERT INTO @CNT
SELECT
A.MRN
, A.VISIT_ID
, A.VISIT_DATE
, COUNT(B.VISIT_ID) AS VISIT_COUNT

FROM
(
SELECT MED_REC_NO AS MRN
, VST_START_DTIME AS VISIT_DATE
, PtNo_Num        AS VISIT_ID 

FROM smsdss.BMH_PLM_PtAcct_V

WHERE
((
    PLM_PT_ACCT_TYPE = 'I'
    AND ADM_SOURCE NOT IN
        (
        'RP'
        )
    )
OR PT_TYPE = 'E')
AND vst_start_dtime >= @START
AND vst_start_dtime < @END
)A

LEFT JOIN
(
SELECT MED_REC_NO AS MRN
, VST_START_DTIME AS VISIT_DATE
, PtNo_Num AS VISIT_ID
 
FROM smsdss.BMH_PLM_PtAcct_V

WHERE
((
    PLM_PT_ACCT_TYPE = 'I'
    AND ADM_SOURCE NOT IN
        (
        'RP'
        )
    )
OR PT_TYPE = 'E')
AND vst_start_dtime >= @START 
AND vst_start_dtime < @END
)B
ON A.MRN = B.MRN
AND A.VISIT_DATE > B.VISIT_DATE 
AND A.VISIT_DATE-180 < B.VISIT_DATE

GROUP BY A.MRN, A.VISIT_ID, A.VISIT_DATE

--SELECT * FROM @CNT

/*
#######################################################################

CO-MORBIDITY QUERY: THIS ONE QILL GO THROUGH A LIST OF CODES AND
SCORE THE PATIENTS PROSPECTIVE VISIT ACCORDINGLY.

#######################################################################
*/

DECLARE @CM TABLE (
	ENCOUNTER_ID           VARCHAR(200)
	, [MRN CM]             VARCHAR(200)
	, NAME                 VARCHAR(500)
	, [CC GRP ONE SCORE]   VARCHAR(20)
	, [CC GRP TWO SCORE]   VARCHAR(20)
	, [CC GRP THREE SCORE] VARCHAR(20)
	, [CC GRP FOUR SCORE]  VARCHAR(20)
	, [CC GRP FIVE SCORE]  VARCHAR(20)
	, [CC LACE SCORE]      INT
)

INSERT INTO @CM
SELECT
C.PtNo_Num
, C.MED_REC_NO
, C.PT_NAME
, C.PRIN_DX_CD_1
, C.PRIN_DX_CD_2
, C.PRIN_DX_CD_3
, C.PRIN_DX_CD_4
, C.PRIN_DX_CD_5
, CASE
    WHEN (C.PRIN_DX_CD_1 + C.PRIN_DX_CD_2 + 
          C.PRIN_DX_CD_3 + C.PRIN_DX_CD_4 + 
          C.PRIN_DX_CD_5) = 0 THEN 0
    WHEN (C.PRIN_DX_CD_1 + C.PRIN_DX_CD_2 + 
          C.PRIN_DX_CD_3 + C.PRIN_DX_CD_4 + 
          C.PRIN_DX_CD_5) = 1 THEN 1
    WHEN (C.PRIN_DX_CD_1 + C.PRIN_DX_CD_2 + 
          C.PRIN_DX_CD_3 + C.PRIN_DX_CD_4 + 
          C.PRIN_DX_CD_5) = 2 THEN 2
    WHEN (C.PRIN_DX_CD_1 + C.PRIN_DX_CD_2 + 
          C.PRIN_DX_CD_3 + C.PRIN_DX_CD_4 + 
          C.PRIN_DX_CD_5) = 3 THEN 3
    WHEN (C.PRIN_DX_CD_1 + C.PRIN_DX_CD_2 + 
          C.PRIN_DX_CD_3 + C.PRIN_DX_CD_4 + 
          C.PRIN_DX_CD_5) = 4 THEN 4
    WHEN (C.PRIN_DX_CD_1 + C.PRIN_DX_CD_2 + 
          C.PRIN_DX_CD_3 + C.PRIN_DX_CD_4 + 
          C.PRIN_DX_CD_5) = 5 THEN 5
    WHEN (C.PRIN_DX_CD_1 + C.PRIN_DX_CD_2 + 
          C.PRIN_DX_CD_3 + C.PRIN_DX_CD_4 + 
          C.PRIN_DX_CD_5) >= 6 THEN 6
  END AS CC_LACE_SCORE

FROM (
	SELECT DISTINCT PtNo_Num
	, MED_REC_NO
	, PT_NAME
	, CASE
	    WHEN PRIN_DX_CD IN (
		'443.9', '440.20', '440.21', '440.22', '440.23', '440.24',
		'440.29', '440.30', '440.31', '440.32', '440.9', '430', '431',
		'432.0', '432.1', '432.9', '433.00', '433.01', '433.10',
		'433.11', '433.20', '433.21', '433.30', '433.31', '433.80',
		'433.81', '433.90', '433.91', '434.00', '434.01', '434.10',
		'434.11', '434.90', '434.91', '435.0', '435.1', '435.2',
		'435.3', '435.8', '435.9', '436', '437.0', '437.1', '437.2',
		'437.3', '437.4', '437.5', '437.6', '437.7', '437.8', '437.9',
		'438.0', '438.10', '438.11', '438.12', '438.13', '438.14',
		'438.19', '438.20', '438.21', '438.22', '438.30', '438.31',
		'438.32', '438.40', '438.41', '438.42', '438.50', '438.51',
		'438.52', '438.53', '438.6', '438.7', '438.81', '438.82',
		'438.83', '438.84', '438.85', '438.89', '438.9', 'V12.54',
		'249.00', '249.01', '250.00', '250.01', '250.02', '250.03',
		'412', '531.00', '531.01', '531.10', '531.11', '531.20',
		'531.21', '531.30', '531.31', '531.40', '531.41', '531.50',
		'531.51', '531.60', '531.61', '531.70', '531.71', '531.90',
		'531.91', '532.00', '532.01', '532.10', '532.20', '532.21',
		'532.30', '532.31', '532.40', '534.41', '532.50', '532.51',
		'532.60', '532.61', '534.70', '532.71', '532.90', '532.91',
		'533.00', '533.01', '533.10', '533.11', '533.20', '533.21',
		'533.30', '533.31', '533.40', '533.41', '533.50', '533.51',
		'533.60', '533.61', '533.70', '533.71', '533.90', '533.91',
		'534.00', '534.01', '534.10', '534.11', '534.20', '534.21',
		'534.30', '534.31', '534.40', '534.41', '534.50', '534.51',
		'534.60', '534.61', '534.70', '534.71', '534.90', '534.91'
		)
		THEN 1
		ELSE 0
	  END AS PRIN_DX_CD_1
	, CASE
	    WHEN PRIN_DX_CD IN (
		'249.4', '295.5', '249.6', '249.7', '250.4', '250.5', '250.6',
		'250.7', '491.20', '491.21', '491.22', '491.8', '491.9',
		'492.8', '493.20', '493.21', '493.22', '494.0', '494.1', '496',
		'140','140.1','140.3','140.4','140.5','140.6','140.8','140.9',
		'141','141.1','141.2','141.3','141.4','141.5','141.6','141.8',
        '141.9','142','142.1','142.2','142.8','142.9','143','143.1',
		'143.8','143.9','144','144.1','144.8','144.9','145','145.1',
		'145.2','145.3','145.4','145.5','145.6','145.8','145.9','146',
		'146.1','146.2','146.3','146.4','146.5','146.6','146.7','146.8',
		'146.9','147','147.1','147.2','147.3','147.8','147.9','148',
		'148.1','148.2','148.3','148.8','148.9','149','149.1','149.8',
		'149.9','150','150.1','150.2','150.3','150.4','150.5','150.8',
		'150.9','151','151.1','151.2','151.3','151.4','151.5','151.6',
		'151.8','151.9','152','152.1','152.2','152.3','152.8','152.9',
		'153','153.1','153.2','153.3','153.4','153.5','153.6','153.7',
		'153.8','153.9','154','154.1','154.2','154.3','154.8','155',
		'155.1','155.2','156','156.1','156.2','156.8','156.9','157',
		'157.1','157.2','157.3','157.4','157.8','157.9','158','158.8',
		'158.9','159','159.1','159.8','159.9','160','160.1','160.2',
		'160.3','160.4','160.5','160.8','160.9','161','161.1','161.2',
		'161.3','161.8','161.9','162','162.2','162.3','162.4','162.5',
		'162.8','162.9','163','163.1','163.8','163.9','164','164.1',
		'164.2','164.3','164.8','164.9','165','165.8','165.9','170',
		'170.1','170.2','170.3','170.4','170.5','170.6','170.7','170.8',
		'170.9','171','171.2','171.3','171.4','171.5','171.6','171.7',
		'171.8','171.9','172','172.1','172.2','172.3','172.4','172.5',
		'172.6','172.7','172.8','172.9','173','173.01','173.02','173.09',
		'173.1','173.11','173.12','173.19','173.2','173.21','173.22',
		'173.29','173.3','173.31','173.32','173.39','173.4','173.41',
		'173.42','173.49','173.5','173.51','173.52','173.59','173.6',
		'173.61','173.62','173.69','173.7','173.71','173.72','173.79',
		'173.8','173.81','173.82','173.89','173.9','173.91','173.92',
		'173.99','174','174.1','174.2','174.3','174.4','174.5','174.6',
		'174.8','174.9','175','175.9','176','176.1','176.2','176.3',
		'176.4','176.5','176.8','176.9','179','180','180.1','180.8',
		'180.9','181','182','182.1','182.8','183','183.2','183.3',
		'183.4','183.5','183.8','183.9','184','184.1','184.2','184.3',
		'184.4','184.8','184.9','185','186','186.9','187.1','187.2',
		'187.3','187.4','187.5','187.6','187.7','187.8','187.9','188',
		'188.1','188.2','188.3','188.4','188.5','188.6','188.7','188.8',
		'188.9','189','189.1','189.2','189.3','189.4','189.8','189.9',
		'190','190.1','190.2','190.3','190.4','190.5','190.6','190.7',
		'190.8','190.9','191','191.1','191.2','191.3','191.4','191.5',
		'191.6','191.7','191.8','191.9','192','192.1','192.2','192.3',
		'192.8','192.9','193','194','194.1','194.3','194.4','194.5',
		'194.6','194.8','194.9','195','195.1','195.2','195.3','195.4',
		'195.5','195.8','199.1','209.00','209.01','209.02','209.03',
		'209.04','209.05','209.06','209.07','209.08','209.09','209.1',
		'209.11','209.12','209.13','209.14','209.15','209.16','209.17',
		'209.18','209.19','209.2','209.21','209.22','209.23','209.24',
		'209.25','209.26','209.27','209.28','209.29','209.3','209.31',
		'209.32','209.33','209.34','209.35','209.36','230.0','230.1',
		'230.2','230.3','230.4','230.5','230.6','230.7','230.8','230.9',
		'231','231.1','231.2','231.8','231.9','232','232.1','232.2',
		'232.3','232.4','232.5','232.6','232.7','232.8','232.9','233',
		'233.1','233.2','233.3','233.31','233.32','233.39','233.4',
		'233.5','233.6','233.7','233.9','234','571','572.3','573.1',
		'573.2','070.1', '070.3','070.5','070.9','200.00','200.01',
		'200.02','200.03','200.04','200.05','200.06','200.07','200.08',
		'200.1','200.11','200.12','200.13','200.14','200.15','200.16',
		'200.17','200.18','200.2','200.21','200.22','200.23','200.24',
		'200.25','200.26','200.27','200.28','200.3','200.31','200.32',
		'200.33','200.34','200.35','200.36','200.37','200.38','200.4',
		'200.41','200.42','200.43','200.44','200.45','200.46','200.47',
		'200.48','200.5','200.51','200.52','200.53','200.54','200.55',
		'200.56','200.57','200.58','200.6','200.61','200.62','200.63',
		'200.64','200.65','200.66','200.67','200.68','200.7','200.71',
		'200.72','200.73','200.74','200.75','200.76','200.77','200.78',
		'200.8','200.81','200.82','200.83','200.84','200.85','200.86',
		'200.87','200.88','201','201.01','201.02','201.03','201.04',
		'201.05','201.06','201.07','201.08','201.1','201.11','201.12',
		'201.13','201.14','201.15','201.16','201.17','201.18','201.2',
		'201.21','201.22','201.23','201.24','201.25','201.26','201.27',
		'201.28','201.4','201.41','201.42','201.43','201.44','201.45',
		'201.46','201.47','201.48','201.5','201.51','201.52','201.53',
		'201.54','201.55','201.56','201.57','201.58','201.6','201.61',
		'201.62','201.63','201.64','201.65','201.66','201.67','201.68',
		'201.7','201.71','201.72','201.73','201.74','201.75','201.76',
		'201.77','201.78','201.9','201.91','201.92','201.93','201.94',
		'201.95','201.96','201.97','201.98','202.00','202.00','202.01',
		'202.02','202.03','202.04','202.05','202.06','202.07','202.08',
		'202.10','202.11','202.12','202.13','202.14','202.15','202.16',
		'202.17','202.18','202.20','202.21','202.22','202.23','202.24',
		'202.25','202.26','202.27','202.28','202.30','202.31','202.32',
		'202.33','202.34','202.35','202.36','202.37','202.38','202.40',
		'202.41','202.42','202.43','202.44','202.45','202.46','202.47',
		'202.48','202.50','202.51','202.52','202.53','202.54','202.55',
		'202.56','202.57','202.58','202.60','202.61','202.62','202.63',
		'202.64','202.65','202.66','202.67','202.68','202.70','202.71',
		'202.72','202.73','202.74','202.75','202.76','202.77','202.78',
		'202.80','202.81','202.82','202.83','202.84','202.85','202.86',
		'202.87','202.88','202.90','202.91','202.92','203.00','203.01',
		'203.02','204.00','204.01','204.02','204.10','204.11','204.12',
		'204.20','204.21','204.22','204.80','204.81','204.82','204.90',
		'204.91','204.92','205.00','205.01','205.02','205.10','205.11',
		'205.12','205.20','205.21','205.22','205.30','205.31','205.32',
		'205.80','205.81','205.82','205.90','205.91','205.92','206.00',
		'206.01','206.02','206.10','206.11','206.12','206.20','206.21',
		'206.22','206.80','206.81','206.82','206.90','206.91','206.92',
		'207.00','207.01','207.02','207.10','207.11','207.12','207.20',
		'207.21','207.22','207.80','207.81','207.82','208.00','208.01',
		'208.02','208.10','208.11','208.12','208.20','208.21','208.22',
		'208.80','208.81','208.82','208.90','208.91','208.92','398.91',
		'428.0','428.1','428.2','428.21','428.22','428.23','428.3','428.31',
		'428.32','428.33','428.4','428.41','428.42','428.43','209.4',
		'209.5','209.6','210.0','210.1','210.2','210.3','210.4','210.5',
		'210.6','210.7','210.8','210.9','211.0','211.1','211.2','211.3',
		'211.4','211.5','211.6','211.7','211.8','211.9','212.0','212.1',
		'212.2','212.3','212.4','212.5','212.6','212.7','212.8','212.9',
		'213.0','213.1','213.2','213.3','213.4','213.5','213.6','213.7',
		'213.8','213.9','214.0','214.1','214.2','214.3','214.4','214.5',
		'214.6','214.7','214.8','214.9','215.0','215.1','215.2','215.3',
		'215.4','215.5','215.6','215.7','215.8','215.9','216.0','216.1',
		'216.2','216.3','216.4','216.5','216.6','216.7','216.8','216.9',
		'217.0','217.1','217.2','217.3','217.4','217.5','217.6','217.7',
		'217.8','217.9','218.0','218.1','218.2','218.3','218.4','218.5',
		'218.6','218.7','218.8','218.9','219.0','219.1','219.2','219.3',
		'219.4','219.5','219.6','219.7','219.8','219.9','220.0','220.1',
		'220.2','220.3','220.4','220.5','220.6','220.7','220.8','220.9',
		'221.0','221.1','221.2','221.3','221.4','221.5','221.6','221.7',
		'221.8','221.9','222.0','222.1','222.2','222.3','222.4','222.5',
		'222.6','222.7','222.8','222.9','223.0','223.1','223.2','223.3',
		'223.4','223.5','223.6','223.7','223.8','223.9','224.0','224.1',
		'224.2','224.3','224.4','224.5','224.6','224.7','224.8','224.9',
		'225.0','225.1','225.2','225.3','225.4','225.5','225.6','225.7',
		'225.8','225.9','226.0','226.1','226.2','226.3','226.4','226.5',
		'226.6','226.7','226.8','226.9','227.0','227.1','227.2','227.3',
		'227.4','227.5','227.6','227.7','227.8','227.9','228.0','228.1',
		'228.2','228.3','228.4','228.5','228.6','228.7','228.8','228.9',
		'229.0','235.0','235.1','235.2','235.3','235.4','235.5','235.6',
		'235.7','235.8','235.9','236.0','236.1','236.2','236.3','236.4',
		'236.5','236.6','236.7','236.8','236.9','237.0','237.1','237.2',
		'237.3','237.4','237.5','237.6','237.7','237.8','237.9','238.0',
		'238.1','238.2','238.3','238.4','238.5','238.6','238.7','238.8',
		'238.9','239.0','580.0','580.1','580.2','580.3','580.4','580.5',
		'580.6','580.7','580.8','580.9','238.0','238.1','238.2','238.3',
		'238.4','238.5','238.6','238.7','238.8','238.9','239.0','581.0',
		'581.2','581.3','581.4','581.5','581.6','581.7','581.8','581.9',
		'582.0','582.1','582.2','582.3','582.4','582.5','582.6','582.7',
		'582.8','582.9','583.0','583.1','583.2','583.3','583.4','583.5',
		'583.6','583.7','583.8','583.9','584.0','584.1','584.2','584.3',
		'584.4','584.5','584.6','584.7','584.8','584.9','585.3','585.4',
		'585.5','585.6','585.7','585.8','585.9','586.0','558.81', '588.1',
		'590.81'
		)
		THEN 2
		ELSE 0
	END AS PRIN_DX_CD_2
    , CASE
	    WHEN PRIN_DX_CD IN (
		'290','291.2','292.82','294.1','294.2','710','714.0','730'
		)
		THEN 3
		ELSE 0
	  END AS PRIN_DX_CD_3
	, CASE
	    WHEN PRIN_DX_CD IN (
		'570','572.0','572.1','572.2','572.4','573.4','070.0','070.2'
		, '070.4', '070.6', '070.71','42'
		)
		THEN 4
		ELSE 0
	  END AS PRIN_DX_CD_4
	, CASE
	    WHEN PRIN_DX_CD IN (
		'196.0','196.1','196.2','196.3','196.5','196.6','196.8','196.9',
		'197.0','197.1','197.2','197.3','197.4','197.5','197.6','197.7',
		'197.8','198.2','198.3','198.4','198.5','199.1','209.7'
		)
	    THEN 6
		ELSE 0
	  END AS PRIN_DX_CD_5
	  
	  FROM smsdss.BMH_PLM_PtAcct_V
	  
	  WHERE Adm_Date >= @START 
	  AND Adm_Date < @END
)C

GROUP BY C.PtNo_Num
, C.MED_REC_NO
, C.PT_NAME
, C.PRIN_DX_CD_1
, C.PRIN_DX_CD_2
, C.PRIN_DX_CD_3
, C.PRIN_DX_CD_4
, C.PRIN_DX_CD_5
ORDER BY (C.PRIN_DX_CD_1 + C.PRIN_DX_CD_2 + 
          C.PRIN_DX_CD_3 + C.PRIN_DX_CD_4 + 
          C.PRIN_DX_CD_5)

--SELECT * FROM @CM

/*
#######################################################################

PUTTING IT ALL TOGETHER
@LACE_MSTR TABLE DECLARATION

#######################################################################
*/

DECLARE @LACE_MSTR TABLE (
	MRN                     VARCHAR(200)
	,ENCOUNTER              VARCHAR(200)
	, AGE                   VARCHAR(30)
	, NAME                  VARCHAR (500)
	, [LACE DAYS SCORE]     INT
	, [LACE ACUTE IP SCORE] INT
	, [LACE ER SCORE]       INT
	, [LACE COMORBID SCORE] INT
)

INSERT INTO @LACE_MSTR
SELECT
Q1.MRN
, Q1.ENCOUNTER_ID
, Q1.[PT AGE]
, Q1.[PT NAME]
, Q1.[LACE DAYS SCORE]
, Q1.[ACUTE ADMIT SCORE]
, CASE
    WHEN Q1.VISIT_COUNT IS NULL THEN 0
    WHEN Q1.VISIT_COUNT = 1     THEN 1
    WHEN Q1.VISIT_COUNT = 2     THEN 2
    WHEN Q1.VISIT_COUNT = 3     THEN 3
    WHEN Q1.VISIT_COUNT >= 4    THEN 4
    ELSE 0
  END AS [LACE ER SCORE]
, Q1.[CC LACE SCORE]

FROM 
(
	SELECT 
	DISTINCT T1.ENCOUNTER_ID
	, T1.MRN
	, T1.[PT AGE]
	, T1.[PT NAME]
	, T1.[LACE DAYS SCORE]
	, T1.[ACUTE ADMIT SCORE]
	, CNT.VISIT_COUNT
	, CM.[CC LACE SCORE]
		
	FROM
	@T1 T1
		LEFT OUTER JOIN @CNT                  CNT
		ON T1.ENCOUNTER_ID = CNT.VISIT_ID
		JOIN @CM                              CM
		ON CM.ENCOUNTER_ID = T1.ENCOUNTER_ID
)Q1


/*
#######################################################################

END OF LACE SCORE QUERY -- NOW GET DESIRED VISIT ID NUMBERS BY CHIEF
COMPLAINT

#######################################################################
*/

DECLARE @T2 TABLE (
	VISIT         VARCHAR(20)
	, MRN         VARCHAR(20)
	, NAME        VARCHAR(200)
	, ADMIT       DATE
	, DISCHARGE   DATE
	, VISIT_COMP  VARCHAR(500)
)

INSERT INTO @T2
SELECT
A.PtNo_Num
, A.Med_Rec_No
, A.Pt_Name
, A.Adm_Date
, A.Dsch_Date
, A.PatientReasonForSeekingHC

FROM (
	SELECT PAV.PtNo_Num
	, PAV.Med_Rec_No
	, PAV.Pt_Name
	, PAV.Adm_Date
	, PAV.Dsch_Date
	, PV.PatientReasonForSeekingHC 

	FROM smsmir.mir_sc_PatientVisit            PV
		LEFT JOIN smsdss.BMH_PLM_PtAcct_V      PAV
		ON PV.PatientAccountID = PAV.PtNo_Num

	WHERE PAV.Adm_Date >= @START
		AND PAV.Adm_Date < @END
	    AND PAV.PtNo_Num < '20000000' --TEST
		AND PAV.Plm_Pt_Acct_Type = 'I'
		AND PAV.Dsch_Date IS NULL
		AND (
			PV.PatientReasonForSeekingHC LIKE '%CHF%'
			OR PV.PatientReasonForSeekingHC LIKE '%heart failure%'
			)
)A

--SELECT * FROM @T2

/*
#######################################################################

FIRST BNP RESULT

#######################################################################
*/

DECLARE @T3 TABLE (
	VISIT              VARCHAR(20)
	, [BNP ORDER #]    VARCHAR(20)
	, [ORDER NAME]     VARCHAR(100)
	, VALUE            VARCHAR(150)
	, [VALUE DATE]     DATETIME
)

INSERT INTO @T3
SELECT
B.episode_no
, B.ord_seq_no
, B.obsv_cd_ext_name
, B.dsply_val
, B.obsv_cre_dtime

FROM (
	SELECT episode_no
	, ord_seq_no
	, obsv_cd_ext_name
	, dsply_val
	, obsv_cre_dtime
	, ROW_NUMBER() OVER (
		PARTITION BY EPISODE_NO ORDER BY ORD_SEQ_NO ASC
		) AS ROWNUMBER_1
	
	FROM smsmir.sr_obsv
	
	WHERE obsv_cd = @BNP
)B
WHERE ROWNUMBER_1 = 1

--SELECT * FROM @T3

/*
#######################################################################

SECOND BNP RESULT

#######################################################################
*/

DECLARE @T7 TABLE (
	VISIT              VARCHAR(20)
	, [BNP ORDER #]    VARCHAR(20)
	, [ORDER NAME]     VARCHAR(100)
	, VALUE            VARCHAR(150)
	, [VALUE DATE]     DATETIME
)

INSERT INTO @T7
SELECT
B.episode_no
, B.ord_seq_no
, B.obsv_cd_ext_name
, B.dsply_val
, B.obsv_cre_dtime

FROM (
	SELECT episode_no
	, ord_seq_no
	, obsv_cd_ext_name
	, dsply_val
	, obsv_cre_dtime
	, ROW_NUMBER() OVER (
		PARTITION BY EPISODE_NO ORDER BY ORD_SEQ_NO ASC
		) AS ROWNUMBER_2
	
	FROM smsmir.sr_obsv
	
	WHERE obsv_cd = @BNP
)B
WHERE ROWNUMBER_2 = 2

/*
#######################################################################

FIRST TROPONIN TEST RESULT

#######################################################################
*/

DECLARE @T4 TABLE (
	VISIT                 VARCHAR(20)
	, [TROPONIN ORDER #1] VARCHAR(20)
	, [ORDER NAME]        VARCHAR(100)
	, VALUE               VARCHAR(150)
	, [VALUE DATE]        DATETIME
)

INSERT INTO @T4
SELECT
C.episode_no
, C.ord_seq_no
, C.obsv_cd_ext_name
, C.dsply_val
, C.obsv_cre_dtime

FROM (
	SELECT episode_no
	, ord_seq_no
	, obsv_cd_ext_name
	, dsply_val
	, obsv_cre_dtime
	, ROW_NUMBER() OVER (
		PARTITION BY EPISODE_NO ORDER BY ORD_SEQ_NO ASC
		) AS ROWNUMBER_3
	
	FROM smsmir.sr_obsv
	
	WHERE obsv_cd = @TROP
)C
WHERE ROWNUMBER_3 = 1

--SELECT * FROM @T4

/*
#######################################################################

SECOND TROPONIN TEST RESULT

#######################################################################
*/

DECLARE @T5 TABLE (
	VISIT                 VARCHAR(20)
	, [TROPONIN ORDER #2] VARCHAR(20)
	, [ORDER NAME]        VARCHAR(100)
	, VALUE               VARCHAR(150)
	, [VALUE DATE]        DATETIME
)

INSERT INTO @T5
SELECT
D.episode_no
, D.ord_seq_no
, D.obsv_cd_ext_name
, D.dsply_val
, d.obsv_cre_dtime

FROM (
	SELECT episode_no
	, ord_seq_no
	, obsv_cd_ext_name
	, dsply_val
	, obsv_cre_dtime
	, ROW_NUMBER() OVER (
		PARTITION BY EPISODE_NO ORDER BY ORD_SEQ_NO ASC
		) AS ROWNUMBER_4

	FROM smsmir.sr_obsv

	WHERE obsv_cd = @TROP
)D
WHERE ROWNUMBER_4 = 2

/*
#######################################################################

GET THE LAST KNOWN LOCATION OF THE PATIENT

#######################################################################
*/

DECLARE @LOC TABLE (
	VISIT           VARCHAR(20)
	, [LAST LOC]    VARCHAR(10)
	, [CENSUS DATE] DATE
	, ROW           INT
)

INSERT INTO @LOC
SELECT
L.PT_NO
, L.BED_DEF
, L.CEN_DATE
, L.ROWNUM

FROM(
	SELECT pt_no
	, bed_def
	, cen_date
	, ROW_NUMBER() OVER (
		PARTITION BY PT_NO ORDER BY CEN_DATE DESC
		)AS ROWNUM

	FROM smsdss.pms_cen_fct_v
)L
WHERE ROWNUM = 1

--SELECT * FROM @LOC

/*
#######################################################################

GET THE LIHN GUIELINE TYPE OF THE PATIENT

#######################################################################
*/

DECLARE @T6 TABLE (
VISIT         VARCHAR(20)
, [LIHN TYPE] VARCHAR(500)
, RN          INT
)

INSERT INTO @T6
SELECT
E.episode_no
, E.dsply_val
, E.RN

FROM (
	SELECT OBS.episode_no
	, OBS.dsply_val
	, RN = ROW_NUMBER() OVER (PARTITION BY OBS.EPISODE_NO
							  ORDER BY OBS.VAL_MODF ASC)

	FROM smsmir.sr_obsv                   OBS
		JOIN smsdss.BMH_PLM_PtAcct_V      PAV
		ON OBS.episode_no = PAV.PtNo_Num

	WHERE obsv_cd_ext_name = @LIHNTYPE
		AND form_usage = 'Shift Assessment'
		AND Dsch_Date IS NULL
		AND PAV.Plm_Pt_Acct_Type = 'I'
		AND PAV.PtNo_Num < '20000000'
)E
WHERE RN = 1

/*
#######################################################################

GET THE ADMITTING DOCTOR NAME

#######################################################################
*/

DECLARE @ADMDOC TABLE(
[ADMITTING DOCTOR] VARCHAR(50)
, VISIT            VARCHAR(20)
)

INSERT INTO @ADMDOC
SELECT
F.pract_rpt_name
, F.PtNo_Num

FROM (
	SELECT DVF.adm_pract_no
	, PDV.src_pract_no
	, PDV.pract_rpt_name
	, DVF.acct_no
	, PAV.PtNo_Num

	FROM smsdss.dly_vst_fct_v                  DVF -- GET ADMITTING
		JOIN smsdss.pract_dim_v                PDV -- GET ADMITTING NAME
		ON DVF.adm_pract_no = pdv.src_pract_no
		JOIN smsdss.BMH_PLM_PtAcct_V           PAV -- GET ACCT # ON DATE
		ON DVF.acct_no = pav.Pt_No

	WHERE PDV.orgz_cd = 's0x0'
		AND pdv.pract_rpt_name NOT IN ('?', 'Doctor Unassigned'
			, 'TEST DOCTOR X')
		AND PAV.Plm_Pt_Acct_Type = 'I'
		AND PAV.PtNo_Num < '20000000'
		AND PAV.Dsch_Date IS NULL
		AND PAV.dsch_disp IS NULL
		AND PAV.Days_Stay <> 0
)F

/*
#######################################################################

GET THE READMISSION FLAG

#######################################################################
*/
DECLARE @RA TABLE (
	VISIT_ID   VARCHAR(20)
	, FLAG     VARCHAR(20)
)

INSERT INTO @RA
SELECT
G.READMIT
, G.FLAG

FROM (
	SELECT R.READMIT
	, 1 AS FLAG
	
	FROM smsdss.vReadmits R
		
	WHERE R.READMIT < '20000000'
		AND R.[READMIT SOURCE DESC] != 'Scheduled Admission'
		AND R.INTERIM <= 30
)G

/*
#######################################################################

GET THE LATEST DISCHARGE ORDER STATUS

#######################################################################
*/
DECLARE @DISCH TABLE (
VISIT            VARCHAR(20)
, ORD_NO         VARCHAR(20)
, [ORDER DATE]   DATE
, [ORDER TIME]   TIME
, SEQ_NUM        VARCHAR(20)
, [ORDER STATUS] VARCHAR(20)
, ROWNUM         VARCHAR(5)
)

INSERT INTO @DISCH
SELECT
SRC.episode_no
, SRC.ord_no
, SRC.DATE
, SRC.TIME
, SRC.intrn_seq_no
, SRC.[ORDER STATUS]
, SRC.ROWNUM

FROM (
	SELECT SO.episode_no
	, SO.ord_no
	, CAST(SO.ent_dtime AS DATE) AS [DATE]
	, CAST(SO.ent_dtime AS TIME) AS [TIME]
	, SOS.intrn_seq_no
	, X.[ORDER STATUS]
	, ROW_NUMBER() OVER(
						PARTITION BY SO.EPISODE_NO
						ORDER BY SO.ORD_NO DESC
						) AS ROWNUM
	FROM smsmir.sr_ord          SO
	JOIN smsmir.sr_ord_sts_hist SOS
	ON SO.ord_no = SOS.ord_no
	JOIN smsmir.ord_sts_modf_mstr OSM
	ON SOS.hist_sts = OSM.ord_sts_modf_cd
	
	CROSS APPLY (
		SELECT
			CASE
				WHEN OSM.ord_sts = 'ACTIVE'      
				THEN '1 - ACTIVE'
				WHEN OSM.ord_sts = 'IN PROGRESS' 
				THEN '2 - IN PROGRESS'
				WHEN OSM.ord_sts = 'COMPLETE'    
				THEN '3 - COMPLETE'
				WHEN OSM.ord_sts = 'CANCEL'      
				THEN '4 - CANCEL'
				WHEN OSM.ord_sts = 'DISCONTINUE' 
				THEN '5 - DISCONTINUE'
			END AS [ORDER STATUS]
			) X
	
	WHERE SO.svc_desc = 'DISCHARGE TO'
	AND SO.episode_no < '20000000'
)SRC

--SELECT * 
--FROM @DISCH
WHERE ROWNUM = 1

/*
#######################################################################

PULL EVERY THING TOGETHER

#######################################################################
*/

SELECT T2.NAME
, T6.[LIHN TYPE]
, ADMMD.[ADMITTING DOCTOR]                  AS [ADM MD]
, T2.VISIT
--, T2.MRN
, T2.ADMIT
, ISNULL(T3.VALUE, 'None')                  AS [BNP 1]
, ISNULL(T7.VALUE, 'None')                  AS [BNP 2]
, ISNULL(SUBSTRING(T4.VALUE, 1, 6), 'None') AS [TROPONIN 1]
, ISNULL(SUBSTRING(T5.VALUE, 1, 6), 'None') AS [TROPONIN 2]
, ISNULL((LM.[LACE ACUTE IP SCORE] 
        + LM.[LACE COMORBID SCORE]
		+ LM.[LACE DAYS SCORE] 
		+ LM.[LACE ER SCORE]), '')          AS [LACE]
, LOC.[LAST LOC]                            AS [LAST LOC]
, ISNULL(DISCH.[ORDER STATUS], 
		'None')                             AS [DISC ORDER]
, ISNULL(RA.FLAG, 0)                        AS [30DAY RA]

FROM @T2 T2                    -- GETS DESIRED ACCT NO AND MRN
	LEFT JOIN @T3 T3           -- GETS FIRST BNP LAB VAL
	ON T2.VISIT = T3.VISIT
	LEFT JOIN @T7 T7           -- GETS SECOND BNP LAB VAL
	ON T2.VISIT = T7.VISIT
	LEFT JOIN @T4 T4           -- GETS FIRST TROPONIN VAL
	ON T2.VISIT = T4.VISIT
	LEFT JOIN @T5 T5           -- GETS SECOND TROPONIN VAL
	ON T2.VISIT = T5.VISIT
	LEFT JOIN @LOC LOC         -- GET THE LAST KNOWN LOCATION
	ON T2.VISIT = LOC.VISIT    
	LEFT JOIN @LACE_MSTR LM    -- GETS VISIT LACE SCORE
	ON T2.VISIT = LM.ENCOUNTER
	LEFT JOIN @T6 T6           -- GETS LIHN TYPE
	ON T2.VISIT = T6.VISIT
	LEFT JOIN @ADMDOC ADMMD    -- GETS ADMITTING DOCTOR
	ON T2.VISIT = ADMMD.VISIT
	LEFT JOIN @DISCH DISCH     -- GETS LAST STATUS OF LAST DISC ORDER
	ON T2.VISIT = DISCH.VISIT
	LEFT JOIN @RA RA           -- GETTING THE 30 DAY READMIT FLAG
	ON T2.VISIT = RA.VISIT_ID


WHERE ADMMD.[ADMITTING DOCTOR] IS NOT NULL

ORDER BY T6.[LIHN TYPE]
, LOC.[LAST LOC]
, T2.ADMIT ASC