SELECT TOP 20 distributed_statement_id,
              program_name,
              data_scanned_disk_mb,
              data_scanned_memory_mb,
              data_scanned_remote_storage_mb,
              Replace(Replace(command, Char(13), ''), Char(10),'') AS command,
              total_elapsed_time_ms,
              start_time,
              end_time,
              allocated_cpu_time_ms,
              status,
              row_count,
              CASE
                WHEN Isjson(label) = 1 THEN Json_value(label, '$.DatasetId')
                ELSE NULL
              END AS DatasetId,
              CASE
                WHEN Isjson(label) = 1 THEN
                Json_value(label, '$.Sources[0].ReportId')
                ELSE NULL
              END AS ReportId,
              CASE
                WHEN Isjson(label) = 1 THEN
                Json_value(label, '$.Sources[0].VisualId')
                ELSE NULL
              END AS VisualId,
              CASE
                WHEN Isjson(label) = 1 THEN
                Json_value(label, '$.Sources[0].Operation')
                ELSE NULL
              END AS Operation,
              label
FROM   queryinsights.exec_requests_history
WHERE  program_name IN (
              'Core .Net SqlClient Data Provider',
              '.Net SqlClient Data Provider',
                              'Framework Microsoft SqlClient Data Provider',
                              'PowerBIPremium-DirectQuery' )
       AND start_time > '2025-05-11'
       AND command NOT LIKE '%sys.sp_set_session_context%'
       AND status = 'Succeeded'
ORDER  BY total_elapsed_time_ms DESC


select distinct program_name
from queryinsights.exec_requests_history


select distinct               
            CASE
                WHEN Isjson(label) = 1 THEN
                Json_value(label, '$.Sources[0].Operation')
                ELSE NULL
              END AS Operation
from queryinsights.exec_requests_history

