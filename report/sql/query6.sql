-- Casos confirmados en el último mes agrupados por Localidad
select 
        max(to_char(date_trunc('month', registration_date::timestamp), 'YYYY-MM')) as last_registration_month
    ,   s.state_name
    ,   to_char(count(*), '999,999,999') as total_cases
    ,   to_char(count(*) / SUM(count(*)) over () * 100, 'fm00D00 %') as "%_total_cases"
from covid19_case c
inner join state s 
on c.residence_state_id = s.state_id
where clasification = 'Confirmado'
group by s.state_name
order by total_cases desc
;
