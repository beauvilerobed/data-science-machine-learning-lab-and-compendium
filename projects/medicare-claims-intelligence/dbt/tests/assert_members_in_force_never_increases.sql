-- Closed cohort: members in force can only fall within a year (deaths) and should never jump up.
-- Year boundaries are excluded because each year's file is re-issued.
with m as (
    select month_start, members_in_force,
           lag(members_in_force) over (order by month_start) as prev
    from {{ ref('mart_members_in_force') }}
)
select * from m
where prev is not null and month(month_start) <> 1 and members_in_force > prev
