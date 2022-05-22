-- Casos confirmados por mes
select 
        to_char(date_trunc('month', registration_date), 'YYYY-MM') as registration_month
    ,   count(*) as total_cases
    ,	round(count(*) / SUM(count(*)) over () * 100, 2) as percent
from covid19_case
where clasification = 'Confirmado' 
group by registration_month
order by registration_month asc
;
