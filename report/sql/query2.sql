-- Casos confirmados por semana para los últimos 2 meses
select 
        to_char(date_trunc('week', registration_date), 'YYYY-MM-DD') as registration_week
    ,   count(*) as total_cases
from covid19_case
where to_char(date_trunc('month', registration_date), 'MM') in 
(select distinct (to_char(date_trunc('month', registration_date), 'MM')) as u_month 
from covid19_case order by u_month desc limit 2)
group by registration_week
order by registration_week asc
;