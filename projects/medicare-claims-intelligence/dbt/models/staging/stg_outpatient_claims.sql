-- One row per outpatient claim segment.
select
    CLM_ID || '-' || SEGMENT                      as claim_key,
    CLM_ID                                        as claim_id,
    cast(SEGMENT as integer)                      as segment,
    DESYNPUF_ID                                   as member_id,
    {{ yyyymmdd('CLM_FROM_DT') }}                 as claim_from_date,
    {{ yyyymmdd('CLM_THRU_DT') }}                 as claim_thru_date,
    PRVDR_NUM                                     as facility_id,
    nullif(AT_PHYSN_NPI, '')                      as attending_npi,
    cast(CLM_PMT_AMT as double)                   as paid_amount,
    cast(NCH_PRMRY_PYR_CLM_PD_AMT as double)      as primary_payer_paid,
    cast(NCH_BENE_PTB_DDCTBL_AMT as double)       as deductible_amount,
    cast(NCH_BENE_PTB_COINSRNC_AMT as double)     as coinsurance_amount,
    nullif(ICD9_DGNS_CD_1, '')                    as primary_dx,
    {{ count_filled('ICD9_DGNS_CD', 10) }}        as n_diagnoses,
    {{ count_filled('HCPCS_CD', 45) }}            as n_hcpcs_codes
from {{ raw_csv('DE1_0_2008_to_2010_Outpatient_Claims_Sample_1.csv') }}
