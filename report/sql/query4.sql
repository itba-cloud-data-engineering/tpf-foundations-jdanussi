-- Casos confirmados en el último mes agrupados por Edad
select 
        max(to_char(date_trunc('month', registration_date), 'YYYY-MM')) as last_registration_month
    ,   case 
            when age < 20 then '0<20'
            when age >= 20 and age < 40 then '20-39'
            when age >= 40 and age < 60 then '40-59'
            when age >= 60 and age < 80 then '60-79'
        else '>80'
        end as age_segment
    ,   count(*) as total_cases
    ,   round(count(*) / SUM(count(*)) over () * 100, 2) as percent
from covid19_case 
where clasification = 'Confirmado'
group by age_segment
order by age_segment asc
;