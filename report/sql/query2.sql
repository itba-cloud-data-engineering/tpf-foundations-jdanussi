-- Casos confirmados por mes
select 
        to_char(date_trunc('month', registration_date), 'YYYY-MM') as registration_month
    ,   to_char(count(*), '999,999,999') as total_cases
    ,   to_char(count(*) / SUM(count(*)) over () * 100, 'fm00D00 %')  as total_cases_percent
from covid19_case
where clasification = 'Confirmado' 
group by registration_month
order by registration_month asc
;
