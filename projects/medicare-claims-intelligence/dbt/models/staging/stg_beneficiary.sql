-- One row per member per year. Chronic-condition flags are coded 1 = yes, 2 = no in the raw files.
{% set years = [2008, 2009, 2010] %}
{% set conditions = ['ALZHDMTA', 'CHF', 'CHRNKIDN', 'CNCR', 'COPD', 'DEPRESSN', 'DIABETES', 'ISCHMCHT', 'OSTEOPRS', 'RA_OA', 'STRKETIA'] %}

{% for y in years %}
select
    DESYNPUF_ID                                   as member_id,
    {{ y }}                                       as year,
    {{ yyyymmdd('BENE_BIRTH_DT') }}               as birth_date,
    {{ yyyymmdd('BENE_DEATH_DT') }}               as death_date,
    cast(BENE_SEX_IDENT_CD as integer)            as sex_code,
    cast(BENE_RACE_CD as integer)                 as race_code,
    BENE_ESRD_IND = 'Y'                           as has_esrd,
    SP_STATE_CODE                                 as state_code,
    cast(BENE_HI_CVRAGE_TOT_MONS as integer)      as part_a_months,
    cast(BENE_SMI_CVRAGE_TOT_MONS as integer)     as part_b_months,
    cast(BENE_HMO_CVRAGE_TOT_MONS as integer)     as hmo_months,
    cast(PLAN_CVRG_MOS_NUM as integer)            as part_d_months,
    {% for c in conditions %}
    SP_{{ c }} = '1'                              as cc_{{ c | lower }},
    {% endfor %}
    cast(MEDREIMB_IP as double)                   as medicare_paid_ip,
    cast(MEDREIMB_OP as double)                   as medicare_paid_op,
    cast(MEDREIMB_CAR as double)                  as medicare_paid_car,
    cast(BENRES_IP as double) + cast(BENRES_OP as double) + cast(BENRES_CAR as double) as member_responsibility,
    cast(MEDREIMB_IP as double) + cast(MEDREIMB_OP as double) + cast(MEDREIMB_CAR as double) as medicare_paid_total
from {{ raw_csv('DE1_0_' ~ y ~ '_Beneficiary_Summary_File_Sample_1.csv') }}
{% if not loop.last %}union all{% endif %}
{% endfor %}
