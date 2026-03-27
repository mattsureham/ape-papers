# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-27T16:35:28.489772

---

 **Referee Report**

**Manuscript:** "The Scarlet Score: Information Disclosure as Irreversible Regulation in For-Profit Higher Education"

**Recommendation:** Revise and resubmit

---

### 1. Idea Fidelity

The paper successfully pursues the core idea outlined in the manifest: exploiting the sequence of the January 2017 Gainful Employment (GE) score publication and the subsequent Trump administration rollback to separate reputational from regulatory effects. The authors correctly match GE Debt-to-Earnings rates to IPEDS completions at the program level and implement a two-stage difference-in-differences (DiD) design comparing failing versus passing programs. However, the paper deviates from the proposed identification strategy in two consequential ways. First, the manifest emphasized using the **June 2017 enforcement pause** to cleanly separate the publication shock (January 2017) from the rollback, potentially via a triple-difference or dynamic specification; instead, the paper treats all of 2017 as "post-publication" and 2018+ as "post-rollback," conflating the two shocks given that IPEDS academic-year data likely straddles the June 2017 pause. Second, the promised regression-discontinuity (RD) analysis exploiting the 12% threshold is absent, despite the manifest highlighting this as a "particularly clean" design complement. The paper also does not implement the suggested triple-difference (fail × post × minority share) to identify compositional shifts, instead running separate level regressions on minority completions.

---

### 2. Summary

This paper exploits the unusual two-shock structure of the Gainful Employment rule—a public quality disclosure in January 2017 followed by an enforcement pause six months later—to demonstrate that failing programs experienced persistent declines in credential completions (17–35 percent) that deepened rather than reversed after regulatory enforcement was removed. Using program-level panel data from 2012–2021, the authors find that the "scarlet score" disproportionately reduced Black and minority completions in the post-rollback period, establishing that information disclosure can function as an irreversible regulatory tool even absent sanctions.

---

### 3. Essential Points

**A. Temporal conflation of treatment shocks undermines the core identification strategy.**  
The paper’s two-stage decomposition treats 2017 as the "post-publication" period and 2018+ as the "post-rollback" period (Table 2). However, the enforcement pause was announced in **June 2017**, and IPEDS Completions data typically cover academic years (e.g., July–June or September–August). Consequently, the 2017 academic year almost certainly contains both the January publication shock and the June pause, meaning the $\beta_1$ coefficient captures a mixture of reputational and regulatory effects, while $\beta_2$ captures the evolution after the threat was already removed. This conflation invalidates the paper’s claim to separate "reputational vs. regulatory" channels using the annual data structure. The authors must either: (i) obtain semester-level enrollment data (IPEDS EFFY 12-month unduplicated headcount) to isolate the January–June 2017 window, or (ii) use a continuous treatment intensity (distance from threshold) interacted with time, as originally proposed in the manifest. Without addressing this timing issue, the interpretation of $\beta_2$ as isolating "persistent reputational damage" is not credible.

**B. The claim that the "scarlet score deepens" lacks statistical substantiation.**  
The abstract and text interpret the more negative post-rollback coefficient (relative to post-publication) as evidence that reputational damage compounds over time. However, this conflates a **level shift** with a **trend break**. The event study description (Section 5.2) notes monotonically widening gaps, but the coefficients are not reported in the tables, nor do the authors formally test for dynamic treatment effects (e.g., testing $\delta_k = \delta_{k-1}$ for $k \geq 2$). The pattern could simply reflect mean reversion from pre-treatment spikes, selective attrition of high-performing programs, or a permanent level shift in 2017 that accumulates linearly. The authors must present the full event study estimates and formally distinguish between a one-time level shift versus an accelerating decline (e.g., via a test for trend interaction post-2018).

**C. Discrepant magnitudes between within-institution and main specifications require reconciliation.**  
The within-institution specification (Table 2, Column 3) yields a cumulative effect of –77 completions, nearly double the main specification’s –33 completions, despite absorbing institution-year fixed effects. This divergence suggests strong selection bias in the between-institution comparison or divergent trends across single-program versus multi-program institutions. Moreover, the racial composition analysis (Table 3) lacks a formal triple-difference specification; the finding that minority completions decline "post-rollback" could reflect aggregate sectoral declines rather than compositional shifts within failing programs. The authors must explain why within-institution effects are larger (e.g., do multi-program schools disproportionately cut failing programs?) and implement the triple-difference (fail × post × pre-treatment minority share) to credibly identify whether the scarlet score altered program demographics.

---

### 4. Suggestions

**1. Implement the RD design near the 12% threshold.**  
The manifest proposed using the continuous D/E rate for "RD-style local linear estimates." This is critical for validating the DiD results, as programs just above/below the 12% threshold are likely comparable on unobservables. I recommend estimating an RD with a bandwidth of 1–2 percentage points around the cutoff, using the interaction of D/E rate with post-2017 indicators to test whether the discontinuity in completions widens after publication. This would bolster the claim that the "fail" label itself drives the results, not underlying program quality correlated with debt levels far from the threshold.

**2. Use IPEDS 12-month enrollment (EFFY) for higher-frequency identification.**  
To resolve the timing conflation in Essential Point A, leverage the `effy` table mentioned in the manifest, which reports 12-month unduplicated headcounts. If month-by-month enrollment is unavailable, use the "fall enrollment" (EF) survey to construct a 2016–2017 academic year indicator that splits at the January 2017 publication, and a 2017–2018 indicator that begins after the June 2017 pause. This would allow a cleaner separation of the two shocks.

**3. Formalize the racial composition mechanism.**  
Instead of separate regressions for minority completions, estimate a triple-difference: 
$$Y_{pjt} = \alpha_{pj} + \gamma_t + \sum_{\tau} \delta_\tau (\text{Fail}_p \times \mathbf{1}[t=\tau] \times \text{MinorityShare}_p) + \varepsilon_{pjt}$$
This tests whether programs with higher pre-treatment minority shares experienced disproportionate compositional shifts, distinguishing between absolute declines (all students leave) versus relative
