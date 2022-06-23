-- Casos confirmados en el último mes agrupados por Sexo
select 
        max(to_char(date_trunc('month', registration_date::timestamp), 'YYYY-MM')) as last_registration_month
    ,   case 
            when gender_id = 'F' then 'Female'
            when gender_id = 'M' then 'Male'
        else 'no_data'
        end as gender
    ,   to_char(count(*), '999,999,999') as total_cases
    ,   to_char(count(*) / SUM(count(*)) over () * 100, 'fm00D00 %') as "%_total_cases"
from covid19_case 
where clasification = 'Confirmado'
group by gender
order by total_cases desc
;