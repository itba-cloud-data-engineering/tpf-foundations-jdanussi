-- Total de casos confirmados en el año
select 
        '2022' as year
    ,   count(*) as total_cases
from covid19_case 
where clasification = 'Confirmado'
;