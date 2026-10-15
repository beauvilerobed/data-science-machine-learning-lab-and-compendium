-- Claims should fall inside the 2008-2010 coverage window. Warn with the offending count.
{{ config(severity = 'warn') }}
select count(*) as n_outside_window
from {{ ref('stg_outpatient_claims') }}
where claim_from_date < date '2008-01-01' or claim_from_date > date '2010-12-31'
having count(*) > 0
