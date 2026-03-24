# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-03-24T14:36:30.832798

---

 **Review: "Notarize This: Remote Online Notarization Laws and New Business Formation"**

### 1. Idea Fidelity

The paper pursues the core empirical strategy outlined in the manifest—exploiting staggered state adoption of Remote Online Notarization (RON) laws using Callaway-Sant'Anna estimation on Census BFS data. However, it omits a key element promised in the original design: **heterogeneity analysis by pre-RON notarization stringency** (e.g., baseline notary density, rural population share, or prior geographic access costs). This test is essential for validating the paper's mechanism claim. Without showing that the null is concentrated in states where notarization was already convenient, the paper cannot distinguish between "notarization is never a constraint" and "notarization is not a constraint in the average state, but binds in specific contexts." The manifest also suggested a placebo comparison between corporate filings (notarization-intensive) and sole proprietorship EINs (less notarized); while the paper examines Corporate BA separately, it does not explicitly contrast these margins as a difference-in-differences placebo test.

### 2. Summary

Using monthly state-level Business Formation Statistics from 2004–2019, this paper estimates the effect of Remote Online Notarization laws on new business applications via a Callaway-Sant'Anna staggered difference-in-differences design. The author finds precisely estimated null effects across all business types, including corporate applications where notarization requirements bind most tightly, and argues that in-person notarization is not a meaningful friction for US entrepreneurship.

### 3. Essential Points

**Omitted heterogeneity by baseline notarization costs.** The manifest specified testing whether RON effects vary with pre-treatment notary availability (e.g., rural states with fewer notaries per capita). This cross-sectional variation is crucial: if RON eliminates travel costs, the treatment effect should be larger where travel costs were highest. By aggregating to a single ATT, the paper risks averaging positive effects in high-friction states against zero or negative effects in low-friction states, masking economically meaningful heterogeneity. You must include this interaction—plot event studies split by baseline notary density or commute time to notary services.

**Supply-side implementation lags.** The paper codes treatment at the statutory effective date (e.g., July 2012 for Virginia), but RON requires notaries to obtain digital certificates, platforms to achieve scale, and legal frameworks for interstate recognition. If RON volume was negligible in early post-treatment months, the null reflects supply constraints rather than unimportance of notarization. You need to verify the "first stage": administrative data from Virginia's Secretary of State or platform providers (Notarize.com, DocuSign) showing when RON volumes actually increased. If uptake was gradual, extend the post-period to 24–36 months and test for delayed effects.

**Power limitations and confidence interval interpretation.** While the paper claims to rule out effects larger than 2.8%, this assumes the SE of 0.020 is correct and that 2.8% is economically irrelevant. With 51 clusters and high serial correlation in monthly state-level data, cluster-robust SEs may be anti-conservative (Cameron & Miller 2015). More importantly, a 2% increase in business formation represents roughly 90,000 additional EIN applications annually—economically meaningful even if statistically excluded at 95%. You should (i) report wild cluster bootstrap p-values given the small number of treated clusters, (ii) use randomization inference to assess whether the null is unusual given the empirical distribution of staggered adoptions, and (iii) clarify that you are powered to detect "large" effects (5%+) but not modest ones (1–2%) that would still justify digitization policy.

### 4. Suggestions

**Sharpen the mechanism test.** The paper treats Corporate BA as the most intensive margin, but LLCs (captured in general BA) also require notarized operating agreements in many states. A cleaner test compares states where articles of incorporation *require* notarization versus states where they do not—exploiting variation in corporate law stringency as a moderator. If the null persists even in states with mandatory notarization, the constraint truly binds. Also, contrast EIN applications for corporations (CBA) against sole proprietorships using a triple-difference: the gap between corporate and non-corporate applications should widen in treated states if RON eases incorporation costs. Currently, the negative point estimate for CBA (-0.067) is concerning and underexplored—does it reflect substitution toward LLCs once notarization is digitized?

**Address the federalism mismatch.** The BFS tracks federal EIN applications, while RON affects state document filing. Many firms obtain EINs online instantly without ever visiting a notary (e.g., sole props using SSNs). You should acknowledge that the proxy is imperfect and conduct a falsification test using *existing* firm expansions (EINs for new establishments by existing firms), which should be unaffected by RON but face similar macro shocks. If RON affects new firms but not existing firm expansions, the proxy is validated; if both move similarly, the BFS outcome captures confounding trends.

**Stratify by treatment cohort quality.** The 2019 cohort comprises 12 states—over half the treatment group—raising concerns about "clumping" and anticipation or concurrent economic shocks. The leave-one-cohort-out robustness check is helpful, but you should also plot the pre-trend test separately for the 2019 cohort: were these states experiencing differential trends in 2018 (e.g., booming economies adopting RON to handle volume)? If the 2019 cohort shows pre-treatment drift, the parallel trends assumption fails for the largest treatment group.

**Explore cross-border notarization.** Some RON laws (e.g., Virginia's) allow out-of-state notaries to serve clients remotely. This creates "treatment contamination" where control states have access to RON via treated-state notaries, biasing the ATT toward zero. You should identify states that explicitly prohibited cross-border
