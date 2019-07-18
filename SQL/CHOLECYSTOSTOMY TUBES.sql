SELECT A.pt_id
, C.rpt_name AS Patient
, C.med_rec_no
, C.birth_dtime
, A.proc_cd
, B.clasf_desc
, A.proc_eff_dtime
, A.resp_pty_cd
, D.pract_rpt_name AS Performing
, E.prim_pyr_cd
, F.pyr_name
, G.Atn_Dr_No
, H.pract_rpt_name AS Attending

FROM smsmir.mir_sproc				        A
	LEFT OUTER JOIN smsmir.mir_clasf_mstr   B
	ON A.proc_cd = B.clasf_cd
	LEFT OUTER JOIN smsmir.mir_pt           C
	ON A.pt_id = C.pt_id 
	LEFT OUTER JOIN smsmir.mir_pract_mstr   D
	ON A.resp_pty_cd = D.pract_no 
		AND A.src_sys_id = D.src_Sys_id
	LEFT OUTER JOIN smsmir.mir_acct         E
	ON A.pt_id = E.pt_id 
		AND A.unit_seq_no = E.unit_Seq_no
	LEFT OUTER JOIN smsmir.mir_pyr_mstr     F
	ON E.prim_pyr_cd = F.pyr_cd
	LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V G
	ON A.pt_id = G.Pt_No
	LEFT OUTER JOIN smsmir.mir_pract_mstr   H
	ON G.Atn_Dr_No = H.pract_no

WHERE A.proc_cd='51.01'
AND A.pt_id BETWEEN '000010000000' AND '000099999999'
AND H.iss_orgz_cd = 'S0X0'

ORDER BY A.proc_eff_dtime ASC

/*--------------------------------------------------------------------*/

DECLARE @T1 TABLE (
	[VISIT ID]      VARCHAR(255)
	, [ORDERING DR]    VARCHAR(255)
	, [SVC DESC]  VARCHAR(255)
)

INSERT INTO @T1
SELECT
A.episode_no
, A.pty_name
, A.svc_desc

FROM (
	SELECT episode_no
	, svc_desc
	, pty_name

	FROM smsmir.sr_ord
	WHERE episode_no IN (
		'12043824', '12291282', '12492914', '12522967', '12542296', '12695318',
		'12682381', '12964623', '13062526', '13075502', '13110036', '13100284',
		'13114038', '13132287', '13192265', '13196514', '13221601', '13274808',
		'13344023', '13372297', '13399373', '13433941', '13508114', '13554209',
		'13564422', '13580741', '13585179' ,'13725510', '13743653', '13750997',
		'13757844', '13771803', '13771803', '13832282', '13839568', '13867015',
		'13871868', '13883848', '13892591', '13955307', '13964259', '13984489',
		'14050736', '14053276', '14053789', '14058705', '14078422', '14095947',
		'14094080', '14086573', '14121016', '14144802', '14146872', '14154975',
		'14158091', '14160485'
		)
		AND SVC_DESC LIKE '%CT GUIDED%'
)A

--SELECT * 
--FROM @T1
--ORDER BY [SVC DESC]

-----------------------------------------------------------------------

DECLARE @T2 TABLE (
	[VISIT ID2]        VARCHAR(255)
	, [PATIENT]       VARCHAR(255)
	, [MRN]           VARCHAR(255)
	, [BIRTH DAY]     DATE
	, [PROC CODE]     VARCHAR(255)
	, [DESCRIPTION]   VARCHAR(255)
	, [PROC TIME]     DATETIME
	, [RESP PTY CD]   VARCHAR(255)
	, [PERFORMING]    VARCHAR(255)
	, [PRIM PYR CD]   VARCHAR(255)
	, [PRIM PYR NAME] VARCHAR(255)
	, [ATTN MD CD]    VARCHAR(255)
	, [ATTENDING MD]  VARCHAR(255)
)

INSERT INTO @T2
SELECT
A.pt_id
, A.Patient
, A.med_rec_no
, A.birth_dtime
, A.proc_cd
, A.clasf_desc
, A.proc_eff_dtime
, A.resp_pty_cd
, A.Performing
, A.prim_pyr_cd
, A.pyr_name
, A.Atn_Dr_No
, A.Attending

FROM(
	SELECT SUBSTRING(A.pt_id, PATINDEX('%[^0]%', A.PT_ID),8) AS pt_id
	, C.rpt_name AS Patient
	, C.med_rec_no
	, C.birth_dtime
	, A.proc_cd
	, B.clasf_desc
	, A.proc_eff_dtime
	, A.resp_pty_cd
	, D.pract_rpt_name AS Performing
	, E.prim_pyr_cd
	, F.pyr_name
	, G.Atn_Dr_No
	, H.pract_rpt_name AS Attending

	FROM smsmir.mir_sproc				        A
		LEFT OUTER JOIN smsmir.mir_clasf_mstr   B
		ON A.proc_cd = B.clasf_cd
		LEFT OUTER JOIN smsmir.mir_pt           C
		ON A.pt_id = C.pt_id 
		LEFT OUTER JOIN smsmir.mir_pract_mstr   D
		ON A.resp_pty_cd = D.pract_no 
			AND A.src_sys_id = D.src_Sys_id
		LEFT OUTER JOIN smsmir.mir_acct         E
		ON A.pt_id = E.pt_id 
			AND A.unit_seq_no = E.unit_Seq_no
		LEFT OUTER JOIN smsmir.mir_pyr_mstr     F
		ON E.prim_pyr_cd = F.pyr_cd
		LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V G
		ON A.pt_id = G.Pt_No
		LEFT OUTER JOIN smsmir.mir_pract_mstr   H
		ON G.Atn_Dr_No = H.pract_no

	WHERE A.proc_cd='51.01'
	AND A.pt_id BETWEEN '000010000000' AND '000099999999'
	AND H.iss_orgz_cd = 'S0X0'
)A

--SELECT *
--FROM @T2
--ORDER BY [PROC TIME] ASC

-----------------------------------------------------------------------

;WITH CTE AS (
	SELECT T1.[VISIT ID]
	, T2.MRN
	, T2.PATIENT
	, T1.[ORDERING DR]
	, T1.[SVC DESC]
	, T2.[ATTENDING MD]
	, T2.PERFORMING
	, T2.[BIRTH DAY]
	, T2.DESCRIPTION
	, T2.[PRIM PYR NAME]
	, ROW_NUMBER() OVER (PARTITION BY T1.[VISIT ID]
						ORDER BY T1.[VISIT ID]
						) RN

	FROM @T1 T1
	LEFT MERGE JOIN @T2 T2
	ON T1.[VISIT ID] = T2.[VISIT ID2]
)

SELECT *
FROM CTE
WHERE CTE.RN = 1