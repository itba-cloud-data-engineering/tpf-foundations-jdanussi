-- Casos confirmados en el último mes agrupados por Localidad
select 
        max(to_char(date_trunc('month', registration_date), 'YYYY-MM')) as last_registration_month
    ,   s.state_name
    ,   count(*) as total_cases
    ,   round(count(*) / SUM(count(*)) over () * 100, 2) as percent
from covid19_case c
inner join state s 
on c.residence_state_id = s.state_id
where clasification = 'Confirmado'
group by s.state_name
order by total_cases desc
;
