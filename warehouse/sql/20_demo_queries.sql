-- 1) KPI snapshot for dashboard cards
select
    (select metric_value from mart.kpi_yield_summary where metric_name = 'total_declared_kg') as total_declared_kg,
    (select metric_value from mart.kpi_yield_summary where metric_name = 'total_after_handclean_kg') as total_after_handclean_kg,
    (select metric_value from mart.kpi_yield_summary where metric_name = 'avg_yield_overall_pct') as avg_yield_pct,
    coalesce((select sum(active_count) from mart.kpi_alerts_summary), 0) as active_alerts;

-- 2) WIP by pipeline status
select status, batch_count
from mart.kpi_wip_by_status
order by batch_count desc, status;

-- 3) Yield quality by source (C1/C2/C3)
select
    source_type,
    count(*) as lots,
    round(avg(current_yield_pct), 2) as avg_yield_pct,
    round(avg(d1_loss_pct), 2) as avg_d1_loss_pct
from mart.fact_batch_snapshot
group by source_type
order by source_type;

-- 4) Alerts trend for control center (last 14 days)
select
    date_trunc('day', created_at) as day,
    severity,
    count(*) as alerts
from mart.fact_alert_event
where created_at >= now() - interval '14 days'
group by 1, 2
order by 1 desc, 2;

-- 5) Batch event timeline (simulated warehouse value)
select
    batch_id,
    event_time,
    event_type,
    status_from,
    status_to,
    payload
from mart.fact_batch_event
where batch_id = 'NFN-202'
order by event_time desc, event_id desc;

-- 6) Bottleneck view: aging by current status
select
    status,
    count(*) as lots,
    round(avg(extract(epoch from (now() - coalesce(action_timestamp, created_at))) / 3600), 2) as avg_hours_in_stage
from mart.fact_batch_snapshot
group by status
order by avg_hours_in_stage desc nulls last;

