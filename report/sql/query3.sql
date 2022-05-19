-- Casos confirmados en el último mes agrupados por Sexo
select 
        max(to_char(date_trunc('month', registration_date), 'YYYY-MM')) as last_registration_month
    ,   case 
            when gender_id = 'F' then 'Female'
            when gender_id = 'M' then 'Male'
        else 'No data'
        end as gender
    ,   count(*) as total_cases
from covid19_case 
where clasification = 'Confirmado'
group by gender
order by total_cases desc
;