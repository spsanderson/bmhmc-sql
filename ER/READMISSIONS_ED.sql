-- This query GETS READMISSIONS
--
--*****************************************************************************************

SET ANSI_NULLS OFF
GO 

-- DATE VAR DECLARATION AND VAR INITIAL SETTINGS
DECLARE @startdate DATETIME
DECLARE @enddate DATETIME  
SET @startdate = '8/1/2012'      
SET @enddate = '9/1/2012'
--**********************************************

-- TABLE CREATION WHICH WILL BE USED TO COMPARE DATA
DECLARE @table1 TABLE(Patient_Name varchar(80), MRN_1 varchar(13), arrival_1 datetime, 
					 encounter_1 varchar(15), outcomelocation_1 varchar(80))

DECLARE @table2 TABLE(Patient_Name_2 varchar(80), MRN_2 varchar(13), arrival_2 datetime, 
                      encounter_2 varchar(15), outcomelocation_2 varchar(80))
--**********************************************

-- WHAT WILL GET INSERTED INTO TABLE 1
INSERT INTO @table1
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
-- WHAT WILL GET INSERTED INTO TABLE 2
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
      --t1.outcomelocation_1 ,
     
      --        t2.encounter_2 , 
      --        t2.arrival_2,
      --        t2.outcomelocation_2
      --        distinct t1.mrn, count(t1.mrn)
             
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
