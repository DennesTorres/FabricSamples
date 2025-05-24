--high start time with classification
with qry as
(select distributed_statement_id, submit_time,start_time,status, DATEDIFF(s,submit_time,start_time) diff
 from queryinsights.exec_requests_history
where start_time > '2025-03-03 11:21' and start_time < '2025-03-03 13:00'
and command not like 'EXEC sys.sp_set_session_context%'),
qry2 as (SELECT
case
     when diff >=120 then 'two minutes or more'
     when diff >= 60 and diff < 120 then '1 minute or more'
     when diff >=30 and diff < 60 then '30 seconds or more'
     when diff <30 and diff >= 10 then 'less than 30 seconds'
     when diff < 10 and diff >= 5 then 'less than 10 secons'
     when diff < 5 and diff >=2 then 'less than 5 seconds'
     when diff < 2 and diff >=1 then 'less than 2 seconds'
     when diff <  1 then 'less than 1 second'
end as timetaken
from qry ),
qry3 as (
select timetaken,count(*) totalqueries
from qry2
group by timetaken)
select timetaken, totalqueries, (CAST(totalqueries AS REAL) / (SUM(totalqueries) OVER ())) * 100 as percentage
from qry3
order by totalqueries desc