# Medicare Claims Intelligence

A dbt claims warehouse, an ILI forecast, provider fraud/waste/abuse (FWA) detection, and a high-cost risk model, built on public CMS Medicare claims and CDC surveillance data.

**Notebook:** [`medicare_claims_intelligence.ipynb`](medicare_claims_intelligence.ipynb)

## Data

| Source | Use |
|---|---|
| [CMS 2008-2010 Medicare DE-SynPUF, Sample 1](https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files/cms-2008-2010-data-entrepreneurs-synthetic-public-use-file-de-synpuf/de10-sample-1): 116K beneficiaries, 790K outpatient and 66K inpatient claims, 5.5M Part D events | claims warehouse, FWA, risk model |
| [CDC ILINet](https://www.cdc.gov/fluview/) via the [Delphi Epidata API](https://cmu-delphi.github.io/delphi-epidata/): weekly national outpatient influenza-like-illness visits, 2010-2026 | forecasting |

DE-SynPUF is synthetic and is not representative of real Medicare populations. It has the same layout as CMS research files, so the pipeline transfers. The DE-SynPUF codebook and user manual are in `data/docs/`.

## Results

| Question | Result |
|---|---|
| **Data quality:** 26 dbt tests | Found 11,253 outpatient claims with no service date, and a cohort artifact: utilization falls about 70% during 2010 while membership falls about 5%. |
| **Forecasting:** weekly %ILI, 1-4 weeks ahead, 35-origin rolling backtest (Oct 2023 - Jun 2026) | Harmonic regression with ARIMA errors: **MASE 0.62** vs 1.06 for seasonal naive. 80% intervals cover 88%. |
| **FWA:** rank 4,516 providers; 90 injected upcoding, phantom-billing and duplicate-billing schemes | Max-rank ensemble of robust z, MCD Mahalanobis and Isolation Forest: **81% precision at review capacity** (random: 2%). |
| **Risk:** next-year top-5% cost, trained 2008 to 2009, tested out of time on 2009 to 2010 | XGBoost reaches **21.0% of next year's high-cost members** in the top-5% outreach list, vs 14.4% for the prior-year-cost baseline (+46%). SHAP explains the drivers, and MLflow tracks and registers the model. |

## Project layout

```
dbt/                                 dbt-duckdb project: 4 staging models, 5 marts, 26 data tests
  models/staging/                    typed, keyed views over the raw CMS CSVs
  models/marts/                      members in force, daily claims, provider features, member-year, risk dataset
  tests/                             singular data-quality tests (coverage window, negative payments, cohort size)
medicare_claims_intelligence.ipynb   the analysis: data quality, forecasting, FWA, risk model
scripts/download_data.py             fetches all public data
```

## Run it

```bash
python -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python scripts/download_data.py                      # about 1 GB of CMS files + CDC
.venv/bin/dbt build --project-dir dbt --profiles-dir dbt       # builds data/warehouse.duckdb, runs the tests
.venv/bin/jupyter lab medicare_claims_intelligence.ipynb
.venv/bin/mlflow ui --backend-store-uri sqlite:///mlflow.db    # tracked runs and the registered model
```
