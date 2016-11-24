select LIHN_Service_Line
, round(avg(los), 2) as alos
, round(avg(performance), 2) as elos

from smsdss.c_elos_bench_data

where Dsch_Date >= '2016-10-01'

group by LIHN_Service_Line;