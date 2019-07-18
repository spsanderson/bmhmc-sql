-- This query grabs the total count of ED visits for a list of MRNs specified within a
-- 6 month period specified excluding the ED Visit that resulted in an IP Admit in the
-- last month specified, so if someone was admitted in August the ED Visit associated
-- with that IP Admit would not be counted
--
--*****************************************************************************************

SET ANSI_NULLS OFF
Go 




declare @startdate datetime   
declare @enddate datetime    
set @startdate= '8/1/2012'      
set   @enddate= '9/1/2012'

DECLARE @table1 TABLE(Patient_Name varchar(80), MRN varchar(13), arrival_1 datetime, encounter_1 varchar(15), outcomelocation_1 varchar(80))
DECLARE @table2 TABLE(name varchar(80), mrn varchar(13), arrival_2 datetime, encounter_2 varchar(15) ,outcomelocation_2 varchar(80))


insert into @table1
SELECT 
s_patient_full_name,
s_MRN,
dt_arrival,
s_visit_ident,
n_OUTCOME_ID

FROM
(
select dt_arrival, s_patient_full_name, s_visit_ident, s_MRN, n_OUTCOME_ID
from dbo.JTM_GENERIC_LIST_V
) b order by s_patient_full_name

-------------------------------------------------------------------------------
insert into @table2
SELECT 
s_patient_full_name,
s_MRN,
dt_arrival,
s_visit_ident,
n_OUTCOME_ID

FROM
(
select dt_arrival, s_patient_full_name, s_visit_ident, s_MRN,n_OUTCOME_ID
from dbo.JTM_GENERIC_LIST_V
where dt_arrival between @startdate and @enddate 
 ) c order by s_patient_full_name, dt_arrival
--------------------------------------------------------------------------------------
SELECT 
      --datediff(mm,t1.arrival_1,t2.arrival_2) as months,
      --datediff(dd,t1.arrival_1, t2.arrival_2)/30.00 as monthbydays,
      --t1.Patient_Name,
      --t1.MRN,
      --t1.arrival_1,
      --t1.encounter_1,
      --t1. outcomelocation_1 ,
     
      --        t2.encounter_2 , 
      --        t2.arrival_2,
      --        t2. outcomelocation_2
              distinct t1.mrn, count(t1.mrn)
             
From @table1 t1
join @table2 t2
on t1.mrn =t2.mrn


where t1.mrn =t2.mrn 
and t1.arrival_1< t2.arrival_2
and datediff(dd,t1.arrival_1, t2.arrival_2)/30.00 <=6

and t2.arrival_2 = (
                    select max(temp.arrival_2)
                    From @table2 temp
                    where t1.mrn=temp.mrn
                    and t1.arrival_1< temp.arrival_2
                    )
and t2.mrn in (

)

group by t1.mrn
