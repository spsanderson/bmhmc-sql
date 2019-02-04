select LIHN_Service_Line
, round(avg(cast(los as float)), 2) as alos
, round(avg(performance), 2) as elos

from smsdss.c_elos_bench_data

where Dsch_Date >= ''
and Dsch_Date < ''

group by LIHN_Service_Line

order by LIHN_Service_Line;