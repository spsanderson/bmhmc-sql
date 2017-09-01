SET ANSI_NULLS OFF
Go 

declare @startdate datetime   
declare @enddate datetime 
   
set @startdate= '9/1/2012'      
set   @enddate= '10/1/2012'

DECLARE @table1 TABLE(Patient_Name varchar(80), MRN varchar(13), arrival_1 datetime, departure_1 datetime, attending_physician_1stencounter varchar(80), diagnosis_of_firstencounter varchar(300), encounter_1 varchar(15), outcomelocation_1 varchar(50) )
DECLARE @table2 TABLE(name varchar(80), mrn varchar(13), arrival_2 datetime, departure_2 datetime, diagnosis_of_2ndencounter varchar(300), outcomelocation_2 varchar(50), encounter_2 varchar(15),  attending_physician_2ndencounter varchar(80) )

insert into @table1
SELECT 
s_patient_full_name,
s_MRN,
dt_arrival,
dt_departure,
s_attending_phys,
s_diagnosis,
s_visit_ident,
s_outcome_location

FROM
(
select dt_arrival, dt_departure, s_attending_phys, s_diagnosis, s_patient_full_name, s_visit_ident, s_MRN, s_outcome_location
from dbo.JTM_GENERIC_LIST_V
where dt_arrival between @startdate and @enddate 
and s_MRN in (
select s_MRN from (
select s_MRN, count(s_MRN) as occurrences
from dbo.JTM_GENERIC_LIST_V

where dt_arrival between @startdate and @enddate
group by s_MRN
having (count(s_MRN) >1)) a) ) b order by s_patient_full_name, dt_arrival
-------------------------------------------------------------------------------
insert into @table2
SELECT 
s_patient_full_name,
s_MRN,
dt_arrival,
dt_departure,
s_diagnosis,
s_outcome_location,
s_visit_ident,
s_attending_phys

FROM
(
select dt_arrival, dt_departure, s_attending_phys, s_diagnosis, s_patient_full_name, s_visit_ident, s_MRN, s_outcome_location
from dbo.JTM_GENERIC_LIST_V
where dt_arrival between @startdate and @enddate 
and s_MRN in (
select s_MRN from (
select s_MRN, count(s_MRN) as occurrences
from dbo.JTM_GENERIC_LIST_V

where dt_arrival between @startdate and @enddate
group by s_MRN
having (count(s_MRN) >1)) a) ) c order by s_patient_full_name, dt_arrival
--------------------------------------------------------------------------------------
SELECT 
      datediff(hh,t1.departure_1,t2.arrival_2) as hours_between_encounters,
      t1.Patient_Name,
      t1.MRN,
      t1.arrival_1,
      t1.encounter_1,
      t1.diagnosis_of_firstencounter,
      t1.attending_physician_1stencounter,
      t1.departure_1,          
      t1.outcomelocation_1,
                  t2.encounter_2 , 
                  t2.arrival_2,
                  t2.diagnosis_of_2ndencounter,
                  t2.attending_physician_2ndencounter,
                  t2.outcomelocation_2 
                 
From @table1 t1
join @table2 t2
on t1.mrn =t2.mrn
where t1.mrn =t2.mrn 
and t1.departure_1< t2.arrival_2
and t2.arrival_2 = (
                    select min(temp.arrival_2)
                    From @table2 temp
                    where t1.mrn=temp.mrn
                    and t1.departure_1< temp.arrival_2
                    )
and  datediff(hh,t1.departure_1,t2.arrival_2)<=72
