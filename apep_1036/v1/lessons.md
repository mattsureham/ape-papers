## Discovery
- **Idea selected:** idea_0479 — France's NRP tax office closures and RN voting
- **Data source:** INSEE BPE (evolution + geolocated 2021/2024) + data.gouv.fr elections (consolidated Parquet)
- **Key risk:** Non-parallel pre-trends between closure and retained communes

## Execution
- **What worked:** BPE evolution dataset gave clean 2019/2024 endpoints; combining with BPE 2021 allowed two-cohort staggered design (143 early, 892 late); election Parquet was comprehensive (27.5M rows, 56 election-rounds)
- **What didn't:** BPE 2018 from data.gouv.fr used different column names and equipment codes; commune code formats differed between BPE (5-digit) and election data (code_commune already contains full INSEE code, not just within-département); CS-DiD initially dropped retained communes due to integer overflow when `did` package converted gvar=0 to Inf
- **Key finding:** TWFE gives 2.1 pp (significant) but CS-DiD gives 0.3 pp (null). The divergence is driven by pre-existing differential trends — closure communes were already on steeper RN trajectories. This is the paper's central contribution.
- **Review feedback adopted:** Added balance discussion (early vs late closure pre-treatment comparability), power analysis (MDE ~1pp, 95% CI rules out effects >1pp), and benchmarking against trade-shock/austerity literature to strengthen the null interpretation
