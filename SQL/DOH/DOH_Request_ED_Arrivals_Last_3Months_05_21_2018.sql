SELECT A.MR#
, A.Account
, A.Patient
, A.Arrival
, A.TimeLeftED
, B.Pt_Age
, B.Pt_Zip_Cd
, C.addr_line1
, C.Pt_Addr_Line2
, C.Pt_Addr_City
, B.Pyr1_Co_Plan_Cd
, D.pyr_name
, A.Diagnosis
, A.Disposition

FROM smsdss.c_Wellsoft_Rpt_tbl AS A
LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS B
ON A.Account = B.PtNo_Num
LEFT OUTER JOIN smsdss.c_patient_demos_v AS C
ON B.Pt_No = C.pt_id
	AND B.from_file_ind = C.from_file_ind
LEFT OUTER JOIN smsdss.pyr_dim_v AS D
ON B.Pyr1_Co_Plan_Cd = D.pyr_cd
	AND B.Regn_Hosp = D.orgz_cd

WHERE A.Arrival >= '2018-02-01'
AND A.Arrival < '2018-05-01'

OPTION(FORCE ORDER)

GO
;