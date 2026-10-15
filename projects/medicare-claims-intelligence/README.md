# Medicare Claims Intelligence

Forecasting, fraud/waste/abuse (FWA) detection, an explainable high-cost risk model, and a guarded RAG assistant, built on public CMS Medicare claims and CDC surveillance data.

**Notebook:** [`medicare_claims_intelligence.ipynb`](medicare_claims_intelligence.ipynb)

## Data

| Source | Use |
|---|---|
| [CMS 2008-2010 Medicare DE-SynPUF, Sample 1](https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files/cms-2008-2010-data-entrepreneurs-synthetic-public-use-file-de-synpuf/de10-sample-1): 116K beneficiaries, 790K outpatient and 66K inpatient claims, 5.5M Part D events | claims warehouse, FWA, risk model |
| [CDC ILINet](https://www.cdc.gov/fluview/) via the [Delphi Epidata API](https://cmu-delphi.github.io/delphi-epidata/): weekly national outpatient influenza-like-illness visits, 2010-2026 | forecasting |
| DE-SynPUF Codebook and User Manual (159 PDF pages) | RAG corpus |

DE-SynPUF is synthetic and is not representative of real Medicare populations. It has the same layout as CMS research files, so the pipeline transfers.

## Results

| Question | Result |
|---|---|
| **Forecasting:** weekly %ILI, 1-4 weeks ahead, 35-origin rolling backtest (Oct 2023 - Jun 2026) | Harmonic regression with ARIMA errors: **MASE 0.62** vs 1.06 for seasonal naive, significantly better at 1-3 weeks (Diebold-Mariano p < 0.05). 80% intervals cover 88%. STL + ETS intervals covered only 48%, a failure the backtest caught. |
| **FWA:** rank 4,516 providers; 90 injected upcoding, phantom-billing and duplicate-billing schemes | Max-rank ensemble of robust z, MCD Mahalanobis and Isolation Forest: **81% precision at review capacity** (random: 2%). Fixing MAD = 0 in the robust z-score took duplicate-billing recall from 0% to 100%. |
| **Risk:** next-year top-5% cost, trained 2008 to 2009, tested out of time on 2009 to 2010 (113K members) | XGBoost reaches **21.0% of next year's high-cost members** in the top-5% outreach list, vs 14.4% for the prior-year-cost baseline (+46%). ROC AUC 0.744, PR AUC 0.178. TreeSHAP matches a brute-force Shapley computation exactly. |
| **RAG:** 14 hand-labeled questions over 157 documentation pages | Hybrid BM25 + TF-IDF (RRF): **recall@3 0.86**, MRR 0.78. The agent's SQL tool blocks identifiers and suppresses counts of 1-10. |
| **Data quality:** 26 dbt tests | Found 11,253 outpatient claims with no service date and a cohort artifact: utilization falls about 70% during 2010 while membership falls about 5%. |

## Project layout

```
dbt/                                 dbt-duckdb project: 4 staging models, 5 marts, 26 data tests
  models/staging/                    typed, keyed views over the raw CMS CSVs
  models/marts/                      members in force, daily claims, provider features, member-year, risk dataset
  tests/                             singular data-quality tests (coverage window, negative payments, cohort size)
medicare_claims_intelligence.ipynb   the analysis: data quality, forecasting, FWA, risk + SHAP, RAG + agent
scripts/download_data.py             fetches all public data
```

## Run it

```bash
python -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python scripts/download_data.py                      # about 1 GB of CMS files + CDC + docs
.venv/bin/dbt build --project-dir dbt --profiles-dir dbt       # builds data/warehouse.duckdb, runs the tests
.venv/bin/jupyter lab medicare_claims_intelligence.ipynb
.venv/bin/mlflow ui --backend-store-uri sqlite:///mlflow.db    # tracked runs and the registered model
```

Optional: set `LLM_BASE_URL` (any OpenAI-compatible endpoint, such as a local Ollama at `http://localhost:11434/v1`) and `LLM_MODEL` to generate answers instead of returning cited extracts.

## Methods at a glance

- **Claims engineering:** composite claim keys (claim + segment), exposure (members in force), per-1,000 rates, chain-ladder IBNR, dbt tests that surfaced 11,253 claims with no service date and an artifact in the closed 2008 cohort, where outpatient volume falls about 70% during 2010 while membership falls about 5%.
- **Forecasting:** dynamic harmonic regression (Fourier + ARIMA errors), STL + ETS, Prophet and a seasonal-naive benchmark. Expanding-window rolling-origin backtest, MASE, 80% interval coverage, Winkler score, Diebold-Mariano test, all logged to MLflow.
- **FWA:** provider billing profiles, robust z-scores (MAD), Minimum Covariance Determinant Mahalanobis distance, Isolation Forest. With no labels, detectors are validated by injecting upcoding, phantom-billing and duplicate-billing schemes and measuring precision and recall at review capacity. Benford's-law check included.
- **Risk model:** prospective top-5%-cost label, out-of-time validation, baselines (prior-year cost) vs logistic regression vs XGBoost, reliability curve, TreeSHAP checked against a brute-force Shapley computation, PSI drift report, MLflow model registry.
- **RAG and agent:** BM25 (implemented from scratch), TF-IDF cosine, reciprocal-rank fusion, a hand-labeled retrieval evaluation (recall@k, MRR, nDCG), and a step-budgeted agent whose SQL tool is read-only, blocks member identifiers and applies CMS small-cell suppression (counts 1-10).
