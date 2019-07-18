SELECT B.Med_Rec_No
, A.pt_id
, B.PtNo_Num
, B.Adm_Date
, B.Pt_Age
, B.prin_dx_cd
, C.alt_clasf_desc

FROM smsmir.dx_grp AS A
INNER JOIN smsdss.BMH_PLM_PtAcct_V AS B
ON A.pt_id = B.Pt_No
	AND A.unit_seq_no = B.unit_seq_no
	AND A.from_file_ind = B.from_file_ind
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS C
ON A.dx_cd = C.dx_cd
	AND A.dx_cd_schm = C.dx_cd_schm

WHERE B.Adm_Date >= '2016-01-01'
AND B.Adm_Date < '2018-01-01'
AND (
	LEFT(A.dx_cd,6) LIKE 'T74.21%'
	OR
	LEFT(A.dx_cd, 6) LIKE 'T74.22%'
	OR
	LEFT(A.dx_cd, 6) LIKE 'T76.21%'
	OR
	LEFT(A.dx_cd, 6) LIKE 'T76.22%'
)
AND LEFT(A.DX_CD_TYPE, 2) = 'DF'

;