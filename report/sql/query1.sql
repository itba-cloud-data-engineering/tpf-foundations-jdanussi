-- Total de casos confirmados en el año
select 
        '2022' as year
    ,   to_char(count(*), '999,999,999') as total_cases
from covid19_case 
where clasification = 'Confirmado'
;