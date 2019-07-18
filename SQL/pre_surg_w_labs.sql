SELECT pt_no
, pt_type
, adm_date
, MONTH(adm_Date) as 'Svc_Mo'
, YEAR(adm_Date) as 'Svc_Yr'

FROM smsdss.BMH_PLM_PtAcct_V 

WHERE Adm_Date BETWEEN '01/01/2015' AND '08/31/2016'
AND pt_type IN ('D','G')
AND Pt_No IN (
	SELECT DISTINCT(Pt_No)
	FROM smsmir.mir_actv a 
	left outer join smsdss.BMH_PLM_PtAcct_V b
	On a.pt_id = b.Pt_No 
	AND a.actv_dtime<b.adm_Date

	WHERE LEFT(actv_cd,3)='004'
	and a.pt_type in ('D','G')
)

UNION

SELECT pt_no
, pt_type
, adm_Date
, MONTH(adm_Date) as 'Svc_Mo'
, YEAR(adm_date) as 'Svc_Yr'

FROM smsdss.bmh_plm_ptAcct_v

WHERE adm_date BETWEEN '01/01/2015' AND '08/31/2016'
and pt_type = 'T'
AND pt_no IN (
	SELECT DISTINCT(pt_no)
	FROM smsmir.mir_actv
	WHERE LEFT(actv_Cd,3)='004'
)


---------------------------------------------------------------------------------------------------

with cte as (
select a.Med_Rec_No
, a.PtNo_Num
, a.Plm_Pt_Acct_Type
, c.pt_type_desc
, a.Plm_Pt_Sub_Type
, sub_type_desc = b.pt_sts_desc
, a.hosp_svc
, a.pt_type
, a.Adm_Date
, rn = ROW_NUMBER() over(partition by a.med_rec_no order by a.adm_date)

from smsdss.BMH_PLM_PtAcct_V AS a
left join smsdss.pt_sts_cd_dim_v as b
on a.Plm_Pt_Sub_Type = b.pt_sts_cd
	and b.orgz_cd = 's0x0'
left join smsdss.pt_type_dim_v as c
on a.pt_type = c.pt_type
	and c.orgz_cd = 's0x0'

where (
	(
		a.hosp_svc = 'pro'
		and a.pt_type = 't'
	)
	or a.pt_type in ('d', 'g')
)
and Adm_Date >= '2015-01-01'
and Adm_Date < '2016-09-01' 
and tot_chg_amt > 0
)

select c1.Med_Rec_No AS Med_Rec_No
, c1.rn AS RN_1
, c2.rn AS RN_2
, c1.PtNo_Num AS Encounter_1
, c1.hosp_svc AS Hosp_Svc_1
, c1.pt_type_desc AS Pt_Type_1
, c1.sub_type_desc AS Pt_Sub_Type_1
, cast(c1.Adm_Date as date) as adm_date_1
, c2.PtNo_Num as Encounter_2
, c2.pt_type_desc AS Pt_Type_2
, c2.sub_type_desc AS Pt_Sub_Type_2 
, cast(c2.Adm_Date as date) as adm_date_2

into #tbl_1

from cte as c1
left join cte as c2
on c1.Med_Rec_No = c2.Med_Rec_No
	and c1.Adm_Date != c2.Adm_Date
	and (
		c1.rn % 2 != 0
		or
		c1.rn = 1
	)
	and (
		c2.rn % 2 = 0
	)

where not (
	c1.rn is not null
	and 
	c2.rn is null 
)
or (
	c1.rn = 1
	and
	c2.rn is null
)

order by c1.Med_Rec_No, c1.Adm_Date

option(force order);
---------------------------------------------------------------------------------------------------
-- trouble shoot
--select * from #tbl_1;
---------------------------------------------------------------------------------------------------
drop table #tbl_1;