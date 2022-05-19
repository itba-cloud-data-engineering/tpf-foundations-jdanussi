-- Casos confirmados por mes
select 
        to_char(date_trunc('month', registration_date), 'YYYY-MM') as registration_month
    ,   count(*) as total_cases
from covid19_case 
group by registration_month
order by registration_month asc
;
