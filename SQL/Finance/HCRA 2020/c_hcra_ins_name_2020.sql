CREATE TABLE smsdss.c_HCRA_ins_name_2020 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, PT_ID VARCHAR(12)
	, PtNo_Num VARCHAR(8)
	, pt_id_start_dtime DATETIME
	, pyr_cd VARCHAR(4)
	, ins_name varchar(100)
)

INSERT INTO smsdss.c_HCRA_ins_name_2020

SELECT A.pt_id
, A.PtNo_Num
, A.pt_id_start_dtime
, A.pyr_cd
, A.ins_name
FROM (
	SELECT A.pt_id
	, SUBSTRING(A.ACCT_NO, 5, 8) AS PtNo_Num
	, A.pt_id_start_dtime
	, A.pyr_cd
	, d.pyr_name
	, d.pyr_group2 as ins_type
	, a.subscr_ins_grp_name
	, b.user_text AS ins_name
	, c.Pt_Name
	, case
		when ltrim(rtrim(substring(a.subscr_ins_grp_name,1,4))) = ltrim(rtrim(SUBSTRING(c.Pt_Name,1,4)))
			then '1'
			else '0'
	  end as insName_ptName_test
	, rn = row_number() over(
							partition by a.pt_id
								, a.acct_no
								, a.pt_id_start_dtime
								, a.pyr_cd
								, a.subscr_ins_grp_name
								, b.user_text
							order by a.pt_id
								, a.acct_no
								, a.pt_id_start_dtime
								, a.pyr_cd
								, a.subscr_ins_grp_name
								, b.user_text
						)

	FROM SMSMIR.PYR_PLAN as a--_USER AS A
	left join smsmir.pyr_plan_user as b
	on a.pt_id = b.pt_id
		and a.from_file_ind = b.from_file_ind
		and b.user_comp_id = '5c49name'
		and a.pyr_cd = b.pyr_cd
	left join smsdss.BMH_PLM_PtAcct_V as c
	on a.pt_id = c.pt_no
		and a.unit_seq_no = c.unit_seq_no
	left join smsdss.pyr_dim_v as d
		on a.pyr_cd = d.pyr_cd
		and d.orgz_cd = 's0x0'
	
	WHERE --A.user_comp_id = '5C49NAME'
	a.pyr_cd != '*'
	and A.pt_id IN (
		SELECT A.PT_ID
		FROM SMSDSS.c_HCRA_unique_pt_id_2020 AS A
	)
		and A.pyr_cd in (
		'x36', 'e36', 'i09', 'k20', 'j36',
		'c05', 'c10', 'c30',
		'n09', 'n100', 'n30'
	)

	order by a.pyr_cd

) A
WHERE A.rn = 1;