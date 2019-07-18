declare @ThisDate datetime;
set @ThisDate = getdate(); 

/*
--http://www.sqlservercentral.com/blogs/lynnpettis/2009/03/25/some-common-date-routines/
*/ 

select dateadd(dd, datediff(dd, 0, @ThisDate), 0)     -- Beginning of this day
select dateadd(dd, datediff(dd, 0, @ThisDate) + 1, 0) -- Beginning of next day
select dateadd(dd, datediff(dd, 0, @ThisDate) - 1, 0) -- Beginning of previous day
select dateadd(wk, datediff(wk, 0, @ThisDate), 0)     -- Beginning of this week (Monday)
select dateadd(wk, datediff(wk, 0, @ThisDate) + 1, 0) -- Beginning of next week (Monday)
select dateadd(wk, datediff(wk, 0, @ThisDate) - 1, 0) -- Beginning of previous week (Monday)
select dateadd(mm, datediff(mm, 0, @ThisDate), 0)     -- Beginning of this month
select dateadd(mm, datediff(mm, 0, @ThisDate) + 1, 0) -- Beginning of next month
select dateadd(mm, datediff(mm, 0, @ThisDate) - 1, 0) -- Beginning of previous month
select dateadd(qq, datediff(qq, 0, @ThisDate), 0)     -- Beginning of this quarter (Calendar)
select dateadd(qq, datediff(qq, 0, @ThisDate) + 1, 0) -- Beginning of next quarter (Calendar)
select dateadd(qq, datediff(qq, 0, @ThisDate) - 1, 0) -- Beginning of previous quarter (Calendar)
select dateadd(yy, datediff(yy, 0, @ThisDate), 0)     -- Beginning of this year
select dateadd(yy, datediff(yy, 0, @ThisDate) + 1, 0) -- Beginning of next year
select dateadd(yy, datediff(yy, 0, @ThisDate) - 1, 0) -- Beginning of previous year