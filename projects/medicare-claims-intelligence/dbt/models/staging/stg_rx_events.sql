-- One row per Part D prescription drug event.
select
    PDE_ID                                        as pde_id,
    DESYNPUF_ID                                   as member_id,
    {{ yyyymmdd('SRVC_DT') }}                     as service_date,
    cast(DAYS_SUPLY_NUM as double)                as days_supply,
    cast(PTNT_PAY_AMT as double)                  as patient_pay_amount,
    cast(TOT_RX_CST_AMT as double)                as total_rx_cost
from {{ raw_csv('DE1_0_2008_to_2010_Prescription_Drug_Events_Sample_1.csv') }}
