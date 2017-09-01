select pt_id
, cast(pay_dtime as date) as pay_date
, pay_cd
, tot_pay_adj_amt
, fc
, rn = ROW_NUMBER() over(partition by pt_id order by pay_dtime desc)

into #temp

from smsmir.pay

where pt_id in (
	select zzz.pt_id
	from smsdss.c_mjrf_fc9 as zzz --custom table
);
-------------------------------------------------
select pt_id
, pay_date
, pay_cd
, tot_pay_adj_amt
, fc
into #tempb
from #temp as a
where a.rn = 1;
-------------------------------------------------
declare @fc9_pmts table (
	pk int not null identity(1, 1) primary key
	, pt_id varchar(12)
	, pay_date date
	, pay_cd varchar(12)
	, tot_pay_adj_amt money
	, fc varchar(3)
);

insert into @fc9_pmts
select a.*
from (
	select a.*
	from #tempb as a

	union

	select pay.pt_id
	, cast(pay.pay_dtime as date) as pay_date
	, pay.pay_cd
	, pay.tot_pay_adj_amt
	, pay.fc
	from smsmir.pay as pay
	where pay.pt_id in (
		select zzz.pt_id
		from #tempb as zzz
		where pay.pay_dtime > zzz.pay_date
	)
) a

select *
, rn = ROW_NUMBER() over(partition by pt_id order by pay_date desc)
into #tempc
from @fc9_pmts;
-------------------------------------------------
select a.*
, b.cr_rating
, cr.cr
, b.fc
, b.pt_bal_amt
from #tempc as a
left join smsmir.acct as b
on a.pt_id = b.pt_id

cross apply (
	select
		case
			when b.cr_rating = 'L' then '100% Insured'
			when b.cr_rating = 'M' then '90% Insured'
			when b.cr_rating = 'N' then '80% Insured'
			when b.cr_rating = 'O' then '70% Insured'
			when b.cr_rating = 'P' then '45% Insured'
			when b.cr_rating = 'Q' then '10% Insured'
			when b.cr_rating = 'K' then 'Does Not Qualify'
			when b.cr_rating = 'E' then '100% Uninsured'
			when b.cr_rating = 'F' then '90% Uninsured'
			when b.cr_rating = 'G' then '80% Uninsured'
			when b.cr_rating = 'H' then '45% Uninsured'
			when b.cr_rating = 'I' then '25% Uninsured'
			when b.cr_rating = 'J' then '10% Uninsured'
		end as cr
) cr

where a.pt_id in (
	select zzz.pt_id
	from #tempc as zzz
	where zzz.rn = 1
)

union

select '' as pk
, pt_id
, NULL as pay_date
, '' as pay_cd
, '' as tot_pay_adj_amt
, '' as fc_prev
, '' as rn
, cr_rating
, cr.cr
, fc
, pt_bal_amt

from smsmir.acct

cross apply (
	select
		case
			when cr_rating = 'L' then '100% Insured'
			when cr_rating = 'M' then '90% Insured'
			when cr_rating = 'N' then '80% Insured'
			when cr_rating = 'O' then '70% Insured'
			when cr_rating = 'P' then '45% Insured'
			when cr_rating = 'Q' then '10% Insured'
			when cr_rating = 'K' then 'Does Not Qualify'
			when cr_rating = 'E' then '100% Uninsured'
			when cr_rating = 'F' then '90% Uninsured'
			when cr_rating = 'G' then '80% Uninsured'
			when cr_rating = 'H' then '45% Uninsured'
			when cr_rating = 'I' then '25% Uninsured'
			when cr_rating = 'J' then '10% Uninsured'
		end as cr
) cr

where pt_id not in (
	select zzz.pt_id
	from #tempc as zzz
)
and pt_id in (
	select zzz.pt_id
	from smsdss.c_mjrf_fc9 as zzz
)
-------------------------------------------------
drop table #temp;
drop table #tempb;
drop table #tempc;
