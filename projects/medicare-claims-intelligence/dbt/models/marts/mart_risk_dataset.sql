-- Prospective risk dataset: features from year t, label from year t+1.
-- Label = member lands in the top (1 - high_cost_quantile) of Medicare paid in t+1.
-- Eligible = alive through year t and present in the t+1 file.
with cur as (
    select * from {{ ref('mart_member_year') }}
    where year in (2008, 2009)
      and (death_date is null or year(death_date) > year)
),
nxt as (
    select member_id, year - 1 as year, medicare_paid_total as paid_next_year
    from {{ ref('mart_member_year') }}
    where year in (2009, 2010)
),
joined as (
    select cur.* exclude (death_date), nxt.paid_next_year
    from cur join nxt using (member_id, year)
)
select
    *,
    paid_next_year >= quantile_cont(paid_next_year, {{ var('high_cost_quantile') }}) over (partition by year)
        as is_high_cost_next_year
from joined
