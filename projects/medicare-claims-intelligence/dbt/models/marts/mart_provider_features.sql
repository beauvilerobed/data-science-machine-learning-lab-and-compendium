-- Billing-behavior profile per attending physician (outpatient, 2008-2010), the unit of FWA review.
with claims as (
    select
        *,
        count(*) over (partition by attending_npi, member_id, claim_from_date) as same_day_claims
    from {{ ref('stg_outpatient_claims') }}
    where attending_npi is not null
      and claim_from_date between date '2008-01-01' and date '2010-12-31'
),
global_cut as (
    select quantile_cont(paid_amount, 0.95) as p95_paid from claims
)
select
    attending_npi,
    count(*)                                                    as n_claims,
    count(distinct member_id)                                   as n_members,
    count(*) / count(distinct member_id)                        as claims_per_member,
    sum(paid_amount)                                            as total_paid,
    avg(paid_amount)                                            as mean_paid,
    quantile_cont(paid_amount, 0.5)                             as median_paid,
    avg(case when paid_amount > g.p95_paid then 1 else 0 end)   as share_high_paid,
    avg(case when paid_amount <= 0 then 1 else 0 end)           as share_zero_paid,
    avg(n_hcpcs_codes)                                          as mean_hcpcs_codes,
    avg(n_diagnoses)                                            as mean_diagnoses,
    avg(case when dayofweek(claim_from_date) in (0, 6) then 1 else 0 end) as share_weekend,
    avg(case when same_day_claims > 1 then 1 else 0 end)        as share_same_day_repeat,
    count(distinct facility_id)                                 as n_facilities,
    count(distinct claim_from_date)                             as active_days,
    count(*) / count(distinct claim_from_date)                  as claims_per_active_day
from claims, global_cut g
group by attending_npi
having count(*) >= {{ var('min_provider_claims') }}
