-- Negative payments are claim adjustments/reversals. A few are normal; a jump means a feed problem.
-- Fails (warns) when more than 0.5% of outpatient claims are negative.
{{ config(severity = 'warn') }}
select share_negative
from (
    select avg(case when paid_amount < 0 then 1.0 else 0.0 end) as share_negative
    from {{ ref('stg_outpatient_claims') }}
)
where share_negative > 0.005
