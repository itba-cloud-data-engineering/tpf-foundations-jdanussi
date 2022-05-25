-- Casos confirmados por mes
select 
        to_char(date_trunc('month', registration_date::timestamp), 'YYYY-MM') as registration_month
    ,   to_char(count(*), '999,999,999') as total_cases
    ,   to_char(count(*) / SUM(count(*)) over () * 100, 'fm00D00 %')  as "%_total_cases"
from covid19_case
where clasification = 'Confirmado' 
group by registration_month
order by registration_month asc
;
