-- Monthly exposure base: members covered and alive at the start of each month.
-- DE-SynPUF is a closed 2008 cohort (no new enrollees), so this shrinks every month.
with months as (
    select cast(range as date) as month_start
    from range(date '2008-01-01', date '2011-01-01', interval 1 month)
)
select
    m.month_start,
    count(*)                                      as members_in_force
from months m
join {{ ref('stg_beneficiary') }} b
  on b.year = year(m.month_start)
 and (b.part_a_months > 0 or b.part_b_months > 0)
 and (b.death_date is null or b.death_date >= m.month_start)
group by 1
