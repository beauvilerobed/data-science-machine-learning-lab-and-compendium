-- Daily claim volume and Medicare paid amount by setting, with exposure for per-1,000 rates.
with days as (
    select cast(range as date) as claim_date
    from range(date '2008-01-01', date '2011-01-01', interval 1 day)
),
op as (
    select claim_from_date as claim_date, count(*) as op_claims, sum(paid_amount) as op_paid
    from {{ ref('stg_outpatient_claims') }}
    group by 1
),
ip as (
    select claim_from_date as claim_date, count(*) as ip_claims, sum(paid_amount) as ip_paid
    from {{ ref('stg_inpatient_claims') }}
    group by 1
)
select
    d.claim_date,
    coalesce(op.op_claims, 0)                     as op_claims,
    coalesce(op.op_paid, 0)                       as op_paid,
    coalesce(ip.ip_claims, 0)                     as ip_claims,
    coalesce(ip.ip_paid, 0)                       as ip_paid,
    mif.members_in_force,
    1000.0 * coalesce(op.op_claims, 0) / mif.members_in_force as op_claims_per_1000
from days d
left join op  on op.claim_date = d.claim_date
left join ip  on ip.claim_date = d.claim_date
join {{ ref('mart_members_in_force') }} mif
  on mif.month_start = date_trunc('month', d.claim_date)
