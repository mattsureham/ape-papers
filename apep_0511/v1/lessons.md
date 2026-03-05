## Discovery
- **Policy chosen:** 340B Drug Pricing Program (DSH threshold at 11.75%) — exploits a validated RDD design from Nikpay et al. (2018 NEJM) but with genuinely novel data (T-MSIS Medicaid claims) and a new mechanism (duplicate discount → payer substitution)
- **Ideas rejected:** MUA/IMU threshold (circularity concern: IMU includes provider-to-population ratio), NP scope of practice border RDD (thin NP density at state borders for T-MSIS codes), GPCI spatial RDD (modest payment differences at boundaries), Medicaid expansion borders (well-studied policy)
- **Data source:** T-MSIS Parquet (local, 2.74 GB) + CMS HCRIS (hospital cost reports for DSH %) + Medicare PUF (cross-payer comparison) + HRSA OPAIS (340B entity list)
- **Key risk:** Manipulation of DSH % near 11.75% threshold documented in 2014-2016 (Bai et al. 2021). Mitigated with donut hole design and McCrary test.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT structural false-positive on placeholders, Grok PASS, Codex PASS, Gemini FAIL on interpretive issues)
- **Top criticism:** The panel specification is not a validated RD estimator — cross-sectional rdrobust is insignificant (p=0.82) while panel achieves p=0.028, raising model dependence concerns (all three referees flagged this)
- **Surprise feedback:** All three referees flagged the Medicaid share non-result as internally inconsistent with the main finding; also the Medicare ZIP-level comparison was viewed as too coarse
- **What changed:** Extensively softened all causal claims to "suggestive evidence"; added crosswalk validation table; added panel binned scatter; expanded limitations discussing power, crosswalk measurement, Medicare proxy limitations, and mechanism identification gaps; explicitly framed panel as "parametric complement" not primary

## Summary
- **Key lesson:** When the thin left tail limits cross-sectional RDD power, be upfront about this rather than leaning on parametric alternatives. Reviewers universally prefer honest imprecision over model-dependent significance.
- **What worked:** Novel T-MSIS data decomposition by payer was genuinely valued by all reviewers. Cross-payer comparisons (even imperfect ones) strengthen causal interpretation.
- **What didn't:** The panel specification was viewed skeptically by all reviewers despite being standard in the applied RDD literature. For future RDD papers with power constraints, consider local randomization inference or threshold-crossing event studies as alternatives.
