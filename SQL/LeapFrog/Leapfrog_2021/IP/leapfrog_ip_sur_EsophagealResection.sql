-- Esophageal_Resection
SELECT SPROC.pt_id
, CAST(SPROC.proc_eff_date AS date) AS [proc_eff_date]
, DATEPART(YEAR, SPROC.proc_eff_date) AS [Svc_Yr]
, DATEPART(MONTH, SPROC.proc_eff_date) AS [Svc_Mo]
, SPROC.proc_cd
, SPROC_DESC.clasf_desc
, SPROC.proc_cd_prio
, SPROC.resp_pty_cd
, UPPER(PDV.pract_rpt_name) AS [Provider_Name]
, Surgery.Surg_Type
, [RN] = ROW_NUMBER() OVER(PARTITION BY SPROC.PT_ID ORDER BY SPROC.PT_ID, SPROC.PROC_CD_PRIO)

INTO #TEMPA

FROM smsmir.sproc AS SPROC
LEFT OUTER JOIN smsdss.proc_dim_v AS SPROC_DESC
ON SPROC.proc_cd = SPROC_DESC.proc_cd
AND SPROC.proc_cd_schm = SPROC_DESC.proc_cd_schm
LEFT OUTER JOIN smsdss.pract_dim_v AS PDV
ON SPROC.resp_pty_cd = PDV.src_pract_no
AND SPROC.orgz_cd = PDV.orgz_cd
LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV
ON SPROC.PT_ID = PAV.PT_NO
	AND SPROC.unit_seq_no = PAV.unit_seq_no
	AND SPROC.from_file_ind = PAV.from_file_ind

CROSS APPLY (
	SELECT
		CASE
			WHEN SPROC.proc_cd IN (
				'0DB10ZZ','0DB13ZZ','0DB20ZZ','0DB23ZZ','0DB30ZZ',
				'0DB33ZZ','0DB50ZZ','0DB53ZZ','0DT10ZZ','0DT14ZZ',
				'0DT20ZZ','0DT24ZZ','0DT30ZZ','0DT34ZZ','0DT50ZZ',
				'0DT54ZZ','0DT60ZZ','0DT64ZZ',
				'0D11074','0D11076',
				'0D11079','0D1107A','0D1107B','0D110J4','0D110J6',
				'0D110J9','0D110JA','0D110JB','0D110K4','0D110K6',
				'0D110K9','0D110KA','0D110KB','0D110Z4','0D110Z6',
				'0D110Z9','0D110ZA','0D110ZB','0D113J4','0D11474',
				'0D11476','0D11479','0D1147A','0D1147B','0D114J4',
				'0D114J6','0D114J9','0D114JA','0D114JB','0D114K4',
				'0D114K6','0D114K9','0D114KA','0D114KB','0D114Z4',
				'0D114Z6','0D114Z9','0D114ZA','0D114ZB','0D11874',
				'0D11876','0D11879','0D1187A','0D1187B','0D118J4',
				'0D118J6','0D118J9','0D118JA','0D118JB','0D118K4',
				'0D118K6','0D118K9','0D118KA','0D118KB','0D118Z4',
				'0D118Z6','0D118Z9','0D118ZA','0D118ZB','0D12074',
				'0D12076','0D12079','0D1207A','0D1207B','0D120J4',
				'0D120J6','0D120J9','0D120JA','0D120JB','0D120K4',
				'0D120K6','0D120K9','0D120KA','0D120KB','0D120Z4',
				'0D120Z6','0D120Z9','0D120ZA','0D120ZB','0D123J4',
				'0D12474','0D12476','0D12479','0D1247A','0D1247B',
				'0D124J4','0D124J6','0D124J9','0D124JA','0D124JB',
				'0D124K4','0D124K6','0D124K9','0D124KA','0D124KB',
				'0D124Z4','0D124Z6','0D124Z9','0D124ZA','0D124ZB',
				'0D12874','0D12876','0D12879','0D1287A','0D1287B',
				'0D128J4','0D128J6','0D128J9','0D128JA','0D128JB',
				'0D128K4','0D128K6','0D128K9','0D128KA','0D128KB',
				'0D128Z4','0D128Z6','0D128Z9','0D128ZA','0D128ZB',
				'0D13074','0D13076','0D13079','0D1307A','0D1307B',
				'0D130J4','0D130J6','0D130J9','0D130JA','0D130JB',
				'0D130K4','0D130K6','0D130K9','0D130KA','0D130KB',
				'0D130Z4','0D130Z6','0D130Z9','0D130ZA','0D130ZB',
				'0D133J4','0D13474','0D13476','0D13479','0D1347A',
				'0D1347B','0D134J4','0D134J6','0D134J9','0D134JA',
				'0D134JB','0D134K4','0D134K6','0D134K9','0D134KA',
				'0D134KB','0D134Z4','0D134Z6','0D134Z9','0D134ZA',
				'0D134ZB','0D13874','0D13876','0D13879','0D1387A',
				'0D1387B','0D138J4','0D138J6','0D138J9','0D138JA',
				'0D138JB','0D138K4','0D138K6','0D138K9','0D138KA',
				'0D138KB','0D138Z4','0D138Z6','0D138Z9','0D138ZA',
				'0D138ZB','0D15074','0D15076','0D15079','0D1507A',
				'0D1507B','0D150J4','0D150J6','0D150J9','0D150JA',
				'0D150JB','0D150K4','0D150K6','0D150K9','0D150KA',
				'0D150KB','0D150Z4','0D150Z6','0D150Z9','0D150ZA',
				'0D150ZB','0D153J4','0D15474','0D15476','0D15479',
				'0D1547A','0D1547B','0D154J4','0D154J6','0D154J9',
				'0D154JA','0D154JB','0D154K4','0D154K6','0D154K9',
				'0D154KA','0D154KB','0D154Z4','0D154Z6','0D154Z9',
				'0D154ZA','0D154ZB','0D15874','0D15876','0D15879',
				'0D1587A','0D1587B','0D158J4','0D158J6','0D158J9',
				'0D158JA','0D158JB','0D158K4','0D158K6','0D158K9',
				'0D158KA','0D158KB','0D158Z4','0D158Z6','0D158Z9',
				'0D158ZA','0D158ZB','0DB10ZZ','0DB13ZZ','0DB17ZZ',
				'0DB27ZZ','0DB37ZZ','0DB57ZZ','0DT17ZZ','0DT18ZZ',
				'0DT27ZZ','0DT28ZZ','0DT37ZZ','0DT38ZZ','0DT57ZZ',
				'0DT58ZZ','0DX80Z5','0DX60Z5','0DX64Z5','0DX84Z5',
				'0DXE0Z5','0DXE4Z5','0DT67ZZ','0DT68ZZ'
				)
		THEN 'Esophageal_Resection'
	END AS [Surg_Type]
) [Surgery]

WHERE SPROC.proc_cd IN (
	-- ESOPHAGEAL RESECTION
	'0DB10ZZ','0DB13ZZ','0DB20ZZ','0DB23ZZ','0DB30ZZ',
	'0DB33ZZ','0DB50ZZ','0DB53ZZ','0DT10ZZ','0DT14ZZ',
	'0DT20ZZ','0DT24ZZ','0DT30ZZ','0DT34ZZ','0DT50ZZ',
	'0DT54ZZ','0DT60ZZ','0DT64ZZ','0D11074','0D11076',
	'0D11079','0D1107A','0D1107B','0D110J4','0D110J6',
	'0D110J9','0D110JA','0D110JB','0D110K4','0D110K6',
	'0D110K9','0D110KA','0D110KB','0D110Z4','0D110Z6',
	'0D110Z9','0D110ZA','0D110ZB','0D113J4','0D11474',
	'0D11476','0D11479','0D1147A','0D1147B','0D114J4',
	'0D114J6','0D114J9','0D114JA','0D114JB','0D114K4',
	'0D114K6','0D114K9','0D114KA','0D114KB','0D114Z4',
	'0D114Z6','0D114Z9','0D114ZA','0D114ZB','0D11874',
	'0D11876','0D11879','0D1187A','0D1187B','0D118J4',
	'0D118J6','0D118J9','0D118JA','0D118JB','0D118K4',
	'0D118K6','0D118K9','0D118KA','0D118KB','0D118Z4',
	'0D118Z6','0D118Z9','0D118ZA','0D118ZB','0D12074',
	'0D12076','0D12079','0D1207A','0D1207B','0D120J4',
	'0D120J6','0D120J9','0D120JA','0D120JB','0D120K4',
	'0D120K6','0D120K9','0D120KA','0D120KB','0D120Z4',
	'0D120Z6','0D120Z9','0D120ZA','0D120ZB','0D123J4',
	'0D12474','0D12476','0D12479','0D1247A','0D1247B',
	'0D124J4','0D124J6','0D124J9','0D124JA','0D124JB',
	'0D124K4','0D124K6','0D124K9','0D124KA','0D124KB',
	'0D124Z4','0D124Z6','0D124Z9','0D124ZA','0D124ZB',
	'0D12874','0D12876','0D12879','0D1287A','0D1287B',
	'0D128J4','0D128J6','0D128J9','0D128JA','0D128JB',
	'0D128K4','0D128K6','0D128K9','0D128KA','0D128KB',
	'0D128Z4','0D128Z6','0D128Z9','0D128ZA','0D128ZB',
	'0D13074','0D13076','0D13079','0D1307A','0D1307B',
	'0D130J4','0D130J6','0D130J9','0D130JA','0D130JB',
	'0D130K4','0D130K6','0D130K9','0D130KA','0D130KB',
	'0D130Z4','0D130Z6','0D130Z9','0D130ZA','0D130ZB',
	'0D133J4','0D13474','0D13476','0D13479','0D1347A',
	'0D1347B','0D134J4','0D134J6','0D134J9','0D134JA',
	'0D134JB','0D134K4','0D134K6','0D134K9','0D134KA',
	'0D134KB','0D134Z4','0D134Z6','0D134Z9','0D134ZA',
	'0D134ZB','0D13874','0D13876','0D13879','0D1387A',
	'0D1387B','0D138J4','0D138J6','0D138J9','0D138JA',
	'0D138JB','0D138K4','0D138K6','0D138K9','0D138KA',
	'0D138KB','0D138Z4','0D138Z6','0D138Z9','0D138ZA',
	'0D138ZB','0D15074','0D15076','0D15079','0D1507A',
	'0D1507B','0D150J4','0D150J6','0D150J9','0D150JA',
	'0D150JB','0D150K4','0D150K6','0D150K9','0D150KA',
	'0D150KB','0D150Z4','0D150Z6','0D150Z9','0D150ZA',
	'0D150ZB','0D153J4','0D15474','0D15476','0D15479',
	'0D1547A','0D1547B','0D154J4','0D154J6','0D154J9',
	'0D154JA','0D154JB','0D154K4','0D154K6','0D154K9',
	'0D154KA','0D154KB','0D154Z4','0D154Z6','0D154Z9',
	'0D154ZA','0D154ZB','0D15874','0D15876','0D15879',
	'0D1587A','0D1587B','0D158J4','0D158J6','0D158J9',
	'0D158JA','0D158JB','0D158K4','0D158K6','0D158K9',
	'0D158KA','0D158KB','0D158Z4','0D158Z6','0D158Z9',
	'0D158ZA','0D158ZB','0DB10ZZ','0DB13ZZ','0DB17ZZ',
	'0DB27ZZ','0DB37ZZ','0DB57ZZ','0DT17ZZ','0DT18ZZ',
	'0DT27ZZ','0DT28ZZ','0DT37ZZ','0DT38ZZ','0DT57ZZ',
	'0DT58ZZ','0DX80Z5','0DX60Z5','0DX64Z5','0DX84Z5',
	'0DXE0Z5','0DXE4Z5','0DT67ZZ','0DT68ZZ'
)
AND SPROC.pt_id IN (
	SELECT distinct(pt_id)
	FROM smsmir.dx_grp
	WHERE dx_cd IN (
		'C15.3','C15.4','C15.5','C15.8','C15.9','C16.0','D00.1'
	)
	AND LEFT(dx_cd_type, 2) = 'DF'
)
AND SPROC.proc_eff_date >= '2020-01-01'
AND SPROC.proc_eff_date < '2021-01-01'
AND PAV.Pt_Age >= 18
AND PAV.tot_chg_amt > 0
AND LEFT(PAV.PTNO_NUM, 1) != '2'

ORDER BY Surgery.Surg_Type
, PDV.pract_rpt_name
, SPROC.pt_id
, SPROC.proc_cd_prio

GO
;

SELECT A.pt_id
, A.proc_eff_date
, A.Svc_Yr
, A.Svc_Mo
, A.proc_cd
, A.clasf_desc
, A.proc_cd_prio
, A.resp_pty_cd
, A.Provider_Name
, A.Surg_Type

FROM #TEMPA AS A

WHERE A.RN = 1

GO
;

DROP TABLE #TEMPA
GO
;
