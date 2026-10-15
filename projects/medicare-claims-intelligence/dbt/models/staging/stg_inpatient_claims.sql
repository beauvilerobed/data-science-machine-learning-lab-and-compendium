-- One row per inpatient claim segment.
select
    CLM_ID || '-' || SEGMENT                      as claim_key,
    CLM_ID                                        as claim_id,
    cast(SEGMENT as integer)                      as segment,
    DESYNPUF_ID                                   as member_id,
    {{ yyyymmdd('CLM_FROM_DT') }}                 as claim_from_date,
    {{ yyyymmdd('CLM_THRU_DT') }}                 as claim_thru_date,
    {{ yyyymmdd('CLM_ADMSN_DT') }}                as admission_date,
    PRVDR_NUM                                     as facility_id,
    nullif(AT_PHYSN_NPI, '')                      as attending_npi,
    cast(CLM_PMT_AMT as double)                   as paid_amount,
    cast(NCH_BENE_IP_DDCTBL_AMT as double)        as deductible_amount,
    try_cast(CLM_UTLZTN_DAY_CNT as integer)       as utilization_days,
    nullif(CLM_DRG_CD, '')                        as drg_code,
    nullif(ICD9_DGNS_CD_1, '')                    as primary_dx,
    {{ count_filled('ICD9_DGNS_CD', 10) }}        as n_diagnoses
from {{ raw_csv('DE1_0_2008_to_2010_Inpatient_Claims_Sample_1.csv') }}
