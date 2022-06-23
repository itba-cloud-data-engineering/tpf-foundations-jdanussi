-- Casos confirmados en el último mes agrupados por Edad
select 
        max(to_char(date_trunc('month', registration_date::timestamp), 'YYYY-MM')) as last_registration_month
    ,   case 
            when age < 20 then '0<20'
            when age >= 20 and age < 40 then '20-39'
            when age >= 40 and age < 60 then '40-59'
            when age >= 60 and age < 80 then '60-79'
        else '>80'
        end as age_segment
    ,   to_char(count(*), '999,999,999') as total_cases
    ,   to_char(count(*) / SUM(count(*)) over () * 100, 'fm00D00 %') as "%_total_cases"
from covid19_case 
where clasification = 'Confirmado'
group by age_segment
order by age_segment asc
;