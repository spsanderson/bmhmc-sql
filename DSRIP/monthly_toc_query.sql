declare @start date;
declare @end date;

set @start = '2017-07-01';
set @end = '2017-08-01';

-- get the count of unique mrn's that were admitted to the hospital
-- during the date range
select count(distinct(med_rec_no)) as [# unique medicaid pt admits]

from smsdss.BMH_PLM_PtAcct_V

where User_Pyr1_Cat in ('www', 'iii')
and tot_chg_amt > 0
and Plm_Pt_Acct_Type = 'i'
and LEFT(ptno_num, 4) != '1999'
and LEFT(ptno_num, 1) != '2'
and Adm_Date >= @start
and Adm_Date < @end
;

-----------------------------------------------------------------------------------------------------
-- get a count of the unique mrn's that readmitted for the month
select a.Med_Rec_No
, a.PtNo_Num
, case
	when ra.[READMIT] IS not null
		then 1
		else 0
  end as [ra_flag]

into #temp1

from smsdss.BMH_PLM_PtAcct_V as a
left join smsdss.vReadmits as ra
on a.PtNo_Num = ra.[INDEX]
	and ra.[INTERIM] < 31

where a.User_Pyr1_Cat in ('www', 'iii')
and a.tot_chg_amt > 0
and a.Plm_Pt_Acct_Type = 'i'
and LEFT(a.PtNo_Num, 4) != '1999'
and LEFT(a.PtNo_Num, 1) != '2'
and a.Adm_Date >= @start
and a.Adm_Date < @end

order by a.Med_Rec_No, a.Adm_Date
;

select count(distinct(a.Med_Rec_No)) as [# unique caid mrn readmitted]
from #temp1 as a
where a.ra_flag = 1
drop table #temp1
;
---------------------------------------------------------------------------------------------------
-- this will get the mrn's that are needed to see how many people are available for manual tracking 
-- for the TOC service for the month.
-- We use the first 6 months of the year to get the population of interest.
select a.med_rec_no
, A.ptno_num
, a.Adm_Date
, case
	when LEFT(a.ptno_num, 1) = '1'
		then 1
		else 0
  end as [ip_flag]
, case	
	when LEFT(a.ptno_num, 1) = '8'
		then 1
		else 0
  end as [ed_flag]
, case
	when ra.[READMIT] IS not null
		then 1
		else 0
  end as [ra_flag]

into #tempa -- this table is used to get a flag of ed and ip visit 1/0

from smsdss.BMH_PLM_PtAcct_V as a
left join smsdss.vReadmits as ra
on a.PtNo_Num = ra.[INDEX]
	and ra.[INTERIM] < 31

where a.User_Pyr1_Cat in ('www', 'iii')
and a.tot_chg_amt > 0
and LEFT(a.PtNo_Num, 4) != '1999'
and LEFT(a.PtNo_Num, 1) != '2'
and LEFT(a.ptno_num, 1) in ('1', '8')
and a.Adm_Date >= '2017-01-01'
and a.Adm_Date <'2017-07-01'

order by a.Med_Rec_No, a.Adm_Date;

-----

select a.med_rec_no
, sum(ed_flag) as [ed_count]
, sum(ra_flag) as [ra_count]

into #tempb  -- this table gets a sum of ed visits and readmit counts per mrn for the previous table #temp1

from #tempa as a

group by a.med_rec_no;

-----
-- this gives us the mrns that meet the criteria of n >= 3 ED Visits AND n >=1 Readmits for the year
select distinct(a.Med_Rec_No) 

into #tempc

from #tempa as a
left join #tempb as b
on a.Med_Rec_No = b.med_rec_no

where B.ed_count >= 3
and B.ra_count > 0;

-- from here use #temp2 to get the amount of patients that meet the criteria
-- that came in for the month of July
-- now that the mrn's that meet criteria are in #temp3 we can use the below to get 
-- a count of unique mrn per month for column 2 for july forward
select count(distinct(med_rec_no)) as [# unique caid eligible for TOC]
from smsdss.BMH_PLM_PtAcct_V
where Med_Rec_No in (
	select distinct(zzz.med_rec_no)
	from #tempc as zzz
)
and Adm_Date >= @start
and Adm_Date < @end
and tot_chg_amt > 0
and LEFT(ptno_num, 1) in ('1')
and LEFT(ptno_num, 4) != '1999'
and Plm_Pt_Acct_Type = 'i'
and User_Pyr1_Cat in ('www', 'iii')

drop table #tempa
drop table #tempb
drop table #tempc 
;