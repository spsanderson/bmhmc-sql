/*
***********************************************************************

File: nyu_adt_BeddedPatients_delta_discharges.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_adt_bedded_tbl

Creates Table:
	None
	
Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get patient visit data

Revision History:
Date		Version		Description
----		----		----
2022-10-31  v1          Initial Creation-
***********************************************************************
*/

drop table if exists #temp_discharges;

select a.PAT_LAST_NM,
	a.PAT_FIRST_NM,
	a.LICH_ACCT_NUMBER,
	a.CUR_UNIT,
	a.CUR_BED,
	a.LICH_MRN,
	a.DOB,
	a.[SERVICE],
	b.visitenddatetime,
    b.dischargedisposition
into #temp_discharges
from smsdss.c_adt_bedded_tbl as a
left join [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit as b on cast(a.lich_acct_number as varchar) = cast(b.patientaccountid as varchar)
where exists (
	select 1
	from [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit as zzz
	where cast(a.lich_acct_number as varchar) = cast(zzz.PatientAccountID as varchar)
	and zzz.VisitEndDateTime IS NOT NULL
);

select *
from #temp_discharges;

delete cb
from smsdss.c_adt_bedded_tbl as cb
inner join #temp_discharges as cd on cb.lich_acct_number = cd.lich_acct_number;

--select *
--from smsdss.c_adt_bedded_tbl
--where lich_acct_number = '90192006';