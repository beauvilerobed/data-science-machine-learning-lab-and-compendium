-- One row per member per year: demographics, chronic conditions, utilization, and cost.
with ip as (
    select member_id, year(claim_from_date) as year,
           count(distinct claim_id) as ip_admits, sum(utilization_days) as ip_days
    from {{ ref('stg_inpatient_claims') }} group by 1, 2
),
op as (
    select member_id, year(claim_from_date) as year,
           count(*) as op_visits, count(distinct attending_npi) as op_distinct_physicians
    from {{ ref('stg_outpatient_claims') }} group by 1, 2
),
rx as (
    select member_id, year(service_date) as year,
           count(*) as rx_fills, sum(total_rx_cost) as rx_cost, sum(days_supply) as rx_days_supply
    from {{ ref('stg_rx_events') }} group by 1, 2
)
select
    b.member_id,
    b.year,
    b.year - year(b.birth_date)                                 as age,
    b.sex_code,
    b.race_code,
    b.has_esrd,
    b.state_code,
    b.part_a_months, b.part_b_months, b.hmo_months, b.part_d_months,
    b.cc_alzhdmta, b.cc_chf, b.cc_chrnkidn, b.cc_cncr, b.cc_copd, b.cc_depressn,
    b.cc_diabetes, b.cc_ischmcht, b.cc_osteoprs, b.cc_ra_oa, b.cc_strketia,
    (b.cc_alzhdmta::int + b.cc_chf::int + b.cc_chrnkidn::int + b.cc_cncr::int + b.cc_copd::int
     + b.cc_depressn::int + b.cc_diabetes::int + b.cc_ischmcht::int + b.cc_osteoprs::int
     + b.cc_ra_oa::int + b.cc_strketia::int)                    as n_chronic_conditions,
    coalesce(ip.ip_admits, 0)                                   as ip_admits,
    coalesce(ip.ip_days, 0)                                     as ip_days,
    coalesce(op.op_visits, 0)                                   as op_visits,
    coalesce(op.op_distinct_physicians, 0)                      as op_distinct_physicians,
    coalesce(rx.rx_fills, 0)                                    as rx_fills,
    coalesce(rx.rx_cost, 0)                                     as rx_cost,
    coalesce(rx.rx_days_supply, 0)                              as rx_days_supply,
    b.medicare_paid_ip, b.medicare_paid_op, b.medicare_paid_car,
    b.medicare_paid_total,
    b.member_responsibility,
    b.death_date
from {{ ref('stg_beneficiary') }} b
left join ip on ip.member_id = b.member_id and ip.year = b.year
left join op on op.member_id = b.member_id and op.year = b.year
left join rx on rx.member_id = b.member_id and rx.year = b.year
