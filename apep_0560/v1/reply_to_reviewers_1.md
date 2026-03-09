# Reply to Reviewers — Round 1

## Reviewer 1 (GPT-5.4 R1): Major Revision

**1. Core heterogeneity relies on only 3 streaming firms.**

We agree this is a structural limitation and have been transparent about it throughout the paper. The leave-one-streaming-firm-out regressions (Section 5.8) show coefficients between -0.66 and -0.95 pp, all directionally consistent, demonstrating the result is not driven by any single control firm. We have added language clarifying that this is a comparison between operators and streaming/royalty firms — a meaningful economic distinction — rather than claiming a fully general causal effect of tailings risk. A richer continuous exposure measure (e.g., TSF count, upstream dam presence) would strengthen identification but requires facility-level data only available post-2020 from the Global Tailings Portal.

**2. Contemporaneous firm classification applied retroactively.**

Acknowledged as limitation. Over 1996-2025, firm characteristics evolve. However, the key treatment variable — whether a firm operates tailings dams vs. is a streaming/royalty company — reflects a fundamental business-model distinction that is highly persistent. WPM, FNV, and RGLD were streaming companies throughout the sample period. We note this persistence in the text and acknowledge that finer characteristics (specific commodity mix) may be less stable.

**3. GISTM interpretation too strong.**

We have softened language throughout. The triple-period specification (Section 5.9) shows a monotonic increase in the tailings penalty: near-zero pre-Brumadinho, larger (but imprecise) post-Brumadinho, significantly negative post-GISTM. We now frame this as "consistent with" rather than "caused by" GISTM, and note that the post-2020 shift could reflect broader ESG attention changes, not GISTM alone.

**4. S&P 500 benchmark for global firms.**

The XME robustness check (Section 5.6) provides a mining-sector benchmark for post-2006 events. Results are consistent: the positive average CAR persists (+0.47%). Local-market benchmarks for all 42 firms across 29 years would be ideal but is beyond the scope of the current study. We note this as an avenue for future work.

**5. Two-way clustering characterization.**

We have corrected the language. We no longer describe two-way clustering as "more conservative" — we report that within-firm correlation across events is positive, which mechanically reduces the two-way SE below the one-way SE. Both sets of SEs are reported.

**6. Event dating precision.**

WISE dates correspond to engineering failure dates, which may differ from first news dates. The [-1,+5] window accommodates 1-2 days of information diffusion. Cross-checking against wire services for all 118 events would be valuable but requires Bloomberg/Factiva access not available. Acknowledged as limitation.

## Reviewer 2 (GPT-5.4 R2): Reject and Resubmit

**1. Three-firm control group.**

Addressed — see reply to R1 point 1. We agree this is the paper's most important limitation and have been transparent about it. The streaming/royalty comparison is economically meaningful (different business models within mining) even if the control group is small.

**2. GISTM not causally identified.**

Addressed — see reply to R1 point 3. Language softened throughout to "consistent with" framing.

**3. Peer sample exclusion of directly exposed firms.**

The responsible firm's stock is not in our peer sample, as our 42-firm panel consists of pre-selected global miners. We have clarified this in the data section. JV partners (e.g., Vale and BHP for Samarco) remain in the sample as peers, which is intentional — the question is whether JV partners suffer additional contagion beyond generic peer effects.

**4. Historical misclassification.**

Addressed — see reply to R1 point 2. The operator/streamer distinction is highly persistent across the full sample period.

**5. Wild cluster bootstrap / permutation inference.**

We have added a within-firm permutation test for the tailings indicator. Event-level aggregation (treated-minus-control spread per event) is reported as complementary evidence. We agree that asymptotic inference is fragile with 3 untreated firms and have calibrated our claims accordingly.

**6. Value-weighted results.**

Added as robustness. Equal-weighted and value-weighted results are directionally consistent.

## Reviewer 3 (Gemini): Minor Revision

**1. Selection into GISTM.**

GISTM is an industry standard, not a firm-level adoption decision in the same way as other voluntary programs. All ICMM members committed to implement it. We acknowledge that firm-level compliance variation would provide richer identification, but compliance data is not publicly available at the required granularity.

**2. Sample representativeness.**

Our 42 firms represent the largest publicly traded miners globally. We have added a note that private and smaller firms are excluded, meaning the measured contagion reflects price discovery in public equity markets, which may be a lower bound on true industry-wide effects.

**3. Continuous severity measure.**

Fatality counts are available for only a subset of events in the WISE database. We use binary severity categories (fatal/non-fatal, major/large release) as the most complete classification available.

**4. Commodity revenue weighting.**

Revenue breakdowns by commodity are not consistently available for all 42 firms across the full sample period. Binary same-commodity coding, while coarse, is the most feasible approach. Acknowledged as limitation.
