-- Casos confirmados por semana para los últimos 2 meses
select 
		a.registration_week 
	,   to_char(a.total_cases, '999,999,999') as total_cases 
	,	to_char(((a.total_cases - a.previous_total_cases)::numeric / a.previous_total_cases ) * 100
	, 'fm000D00 %') as "%_change"
from (
with total_by_week as (
select 	
		to_char(date_trunc('week', registration_date::timestamp), 'YYYY-MM-DD') as registration_week
    ,   count(*) as total_cases
from covid19_case
where 
    clasification = 'Confirmado'
    and to_char(date_trunc('month', registration_date), 'MM') in 
    (select distinct (to_char(date_trunc('month', registration_date::timestamp), 'MM')) as u_month 
from covid19_case order by u_month desc limit 2)
group by registration_week
order by registration_week asc
)
select
	registration_week, 
	total_cases,
	(lag(total_cases, 1, total_cases) over (  order by registration_week)) as previous_total_cases
from total_by_week) a
