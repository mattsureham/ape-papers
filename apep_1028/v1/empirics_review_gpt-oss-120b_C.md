# V1 Empirics Check — openai/gpt-oss-120b (Variant C)

**Model:** openai/gpt-oss-120b
**Variant:** C
**Date:** 2026-03-26T23:34:30.092688

---

**1. Idea Fidelity**

The manuscript follows the original research plan closely. It exploits the staggered rollout of Right‑to‑Counsel (RTC) laws across 39 Continuums of Care (CoCs) from 2017‑2023, uses the Callaway‑Sant’Anna (CS) staggered DiD estimator, and measures outcomes with HUD Point‑in‑Time (PIT) homeless counts. The data sources (HUD PIT, Eviction‑Lab, ACS) and the policy‐relevant question (“does RTC reduce community‑level homelessness?”) are all present.  

The only noticeable deviation from the manifest is the decision to treat state‑wide adoptions as equivalent to city‑level adoptions and to assign the earlier adoption date when a city and its state adopt in the same year. This is reasonable, but the paper does not discuss any sensitivity checks that separate pure city‑level from pure state‑level treatment effects—a point that the original idea hinted would be important given the large size differences between treated and control CoCs.  

Overall, the paper stays true to the proposed design and research question.

---

**2. Summary**

The paper investigates whether the expansion of RTC laws—intended to curb evictions and, ultimately, homelessness—has any measurable impact on the stock of homelessness at the metropolitan (CoC) level. Using a staggered DiD framework across 39 treated and 333 never‑treated CoCs (2007‑2024), the authors find a modest negative ATT (‑0.14 log points, ≈13 % reduction) in the full sample, but extensive diagnostics show that this estimate is driven by post‑COVID, state‑wide adoptions that were adopted in the midst of rising homelessness. When the analysis is restricted to the pre‑COVID city‑level cohorts or to size‑matched controls, the effect vanishes (ATT ≈ 0, insignificant). The paper therefore concludes that RTC does not generate detectable community‑level reductions in homelessness, highlighting a selection bias problem in staggered DiD settings.

---

**3. Essential Points**

1. **Pre‑trend and Selection Concerns Remain Unresolved for the Full Sample**  
   The event‑study shows a statistically significant positive pre‑trend at \(t‑3\) (0.164, p < 0.01) for the full set of treated CoCs, indicating that those jurisdictions were already on a rising homelessness trajectory before adopting RTC. While the authors correctly flag this as a problem, the paper continues to present the baseline ATT as a “main result.” In an AER‑Insights style paper, the primary estimate should be the one that survives the most credible identification checks. Presenting the baseline estimate alongside a disclaimer creates confusion about what the authors actually claim to have identified.

2. **Treatment Definition and Heterogeneity are Insufficiently Explored**  
   The manuscript aggregates very different policies (city‑level pilot programs vs. statewide statutes) and very different CoC sizes (NYC > 50 k homeless vs. rural CoCs with < 500). Yet the analysis treats them as a single “treated” group, only offering a single size‑matched robustness check. This masks potentially important heterogeneity: state‑wide RTC may affect eviction processes differently (e.g., broader eligibility, different funding structures) and could have distinct spill‑over effects on shelter capacity. A more detailed exploration of heterogeneity (city vs. state, early vs. late adopters, large vs. small CoCs) is needed to substantiate the claim that “RTC does not reduce homelessness” rather than “the average of a heterogeneous set of policies shows no effect.”

3. **Standard Errors and Clustering May be Inadequate**  
   All SEs are clustered at the CoC level, but the treatment varies at the city or state level, which may be nested within CoCs. Moreover, the number of treated clusters (39) is relatively small, raising concerns about the reliability of conventional cluster‑robust SEs (Cameron, Gelbach, Miller 2008). The paper does not report any alternative inference (e.g., wild cluster bootstrap, randomization inference, or the “cluster‑robust variance estimator with bias correction” of Imbens & Kolesár). Given that the key result hinges on a modest ATT with a SE that is itself a substantial fraction of the point estimate, more robust inference is essential.

---

**4. Suggestions**

Below are concrete recommendations that, if addressed, will substantially improve the credibility, clarity, and policy relevance of the paper. They are organized by theme; implementation of most of them should be straightforward given the existing dataset.

---

### A. Refine the Identification Strategy

| Recommendation | Rationale | Implementation |
|----------------|-----------|----------------|
| **Focus the “main” estimate on the most credible subsample** (pre‑COVID city‑level adopters) | The event‑study pre‑trend problem invalidates the full‑sample ATT as a causal estimate. Presenting a null estimate that survives strict checks is more honest and aligns with the AER‑Insights ethos of “the truth about the effect.” | Re‑write Section 3–4 so that Table 1 (baseline) is replaced by a table that reports the ATT for the clean subsample only, with the full‑sample estimate relegated to an “exploratory” appendix. |
| **Explicitly test for parallel trends using a formal pre‑trend test** | Visual inspection is useful, but a statistical test (e.g., joint F‑test of pre‑trend coefficients) strengthens the argument. | Add a footnote or appendix reporting the joint test statistic and p‑value for the pre‑trend coefficients for each cohort. |
| **Use “not‑yet‑treated” CoCs as additional controls** | The paper already includes a column with not‑yet‑treated controls, but the discussion does not explain why this is a better counterfactual. | Present a brief theoretical justification (the “staggered adoption” approach of CS) and show that the ATT estimated with not‑yet‑treated controls is statistically indistinguishable from the baseline, reinforcing the robustness of the null. |
| **Incorporate an event‑study with leads and lags anchored on the actual adoption year for each CoC, but also report “placebo” event windows offset by 2‑3 years** | The current placebo (shift = ‑3) is shown, but the magnitude (0.07) is not discussed. Demonstrating that leads are statistically indistinguishable from zero (or that they are *positive* as a sign of selection) helps readers understand the direction of the bias. | Add a figure (or table) showing leads up to ‑5 years and lags up to +5 years, with confidence bands, for both the full sample and the clean subsample. |

---

### B. Disaggregate Treatment Effects

| Recommendation | Rationale | Implementation |
|----------------|-----------|----------------|
| **Separate city‑level pilots from statewide statutes** | The mechanisms (eligibility thresholds, funding levels, court capacity) differ; aggregating may dilute heterogenous effects. | Create two treatment indicators (city‑RTC, state‑RTC) and estimate ATTs for each. Present results in a table (e.g., “City‑RTC ATT = ‑0.03, SE = 0.05; State‑RTC ATT = ‑0.20, SE = 0.07”). |
| **Interact treatment with CoC size (or baseline homelessness level)** | Larger metros may experience different dynamics (e.g., economies of scale in shelter provision). | Include an interaction term “RTC × log(pre‑treatment homeless)” and report the marginal effect at low, medium, and high baseline levels. |
| **Explore heterogeneity by shelter capacity** | If the pipeline from eviction to homelessness is constrained by shelter bed availability, the effect of RTC may be larger where capacity is tight. | Merge HUD HIC data on shelter beds, construct a “capacity gap” measure, and estimate ATT conditional on high vs. low gap. |
| **Check whether the effect differs for “families” vs. “individuals”** | The paper already reports a family outcome, but a formal heterogeneity test (e.g., Wald test for equality of ATTs) would be valuable. | Add a table comparing ATTs across outcome categories with a joint test. |

---

### C. Strengthen Inference

| Recommendation | Rationale | Implementation |
|----------------|-----------|----------------|
| **Use wild‑cluster bootstrap SEs (or the “cluster‑robust bootstrap” of Cameron, Gelbach, Miller)** | With only 39 treated clusters, conventional cluster‑robust SEs can be downward‑biased. | Re‑estimate the main ATT using `boottest` (Stata) or `wildclusterboot` (R) and report both the conventional and bootstrap SEs. |
| **Report the effective number of clusters (M) and the cluster‑adjusted degrees of freedom** | Transparency about inference quality helps reviewers assess reliability. | Add a footnote stating “M = 39 treated clusters, 333 control clusters; df = M‑1 = 38.” |
| **Consider a permutation/randomization test** | Under the null of no effect, randomly reassign adoption years (preserving the staggered structure) and recompute ATTs; this yields a non‑parametric p‑value. | Run 1,000 permutations, report the distribution of ATT under the null, and compare the observed ATT to this distribution. |
| **Present confidence intervals for effect sizes in “percentage point” terms** | The log‑point estimate is less intuitive for policymakers. Convert the ATT to a percent change in homeless counts (e.g., `exp(ATT) - 1`). | Add a line in Table 1: “% change in total homeless = –13 % (95 % CI –22 % to –2 %).” Do this for both the full‑sample and the clean subsample. |

---

### D. Expand the Mechanism Discussion

| Recommendation | Rationale | Implementation |
|----------------|-----------|----------------|
| **Link RTC to eviction filing rates directly in the same panel** | The paper mentions Eviction‑Lab filing rates but never shows a first‑stage regression. Demonstrating that RTC actually reduces eviction filings in the treated CoCs (even modestly) would solidify the causal chain. | Estimate a DiD of “log eviction filings” on RTC using the same CS framework; present the ATT and discuss why a modest first‑stage may translate into a negligible second‑stage effect on homelessness. |
| **Quantify the “pipeline” probability** (eviction → homelessness) using external micro‑data (e.g., Survey of Income and Program Participation, or the “Eviction Lab” longitudinal data). | If the pipeline is truly thin (e.g., 3‑5 % of evictions lead to homelessness), the expected impact on the homeless stock is tiny, which would reconcile the null result. | Cite a recent study that estimates the eviction‑to‑homelessness conversion rate, compute the implied maximum reduction in the homeless stock given the observed eviction reduction, and compare to the estimated ATT. |
| **Address possible displacement effects** (e.g., landlords switching to “cash‑for‑keys” or “non‑renewal” strategies). | These mechanisms could offset any reduction in formal evictions, weakening the policy’s impact on homelessness. | Include a brief literature review and, if possible, an empirical test (e.g., examine changes in “non‑renewal” filings or “cash‑for‑keys” payments in the Eviction Lab data). |
| **Discuss shelter capacity constraints** | Even if RTC prevents some evictions, the shelter system may already be saturated, limiting the observable reduction in PIT counts. | Use HUD HIC data to construct a “saturation index” and interact it with the RTC indicator to see if effects appear in under‑capacity CoCs. |

---

### E. Presentation and Clarity

| Recommendation | Rationale | Implementation |
|----------------|-----------|----------------|
| **Re‑order tables for readability** | Table 1 mixes ATTs, TWFE, and descriptive statistics, making it hard to locate the primary result. | Split into three tables: (i) descriptive balance, (ii) main CS ATT (clean subsample), (iii) robustness checks. |
| **Add a concise “policy implication” box** | Decision‑makers need a clear take‑away (e.g., “RTC may improve court outcomes but should not be justified on homelessness reduction alone”). | Insert a short boxed paragraph after the Discussion section. |
| **Provide a visual summary of adoption timing** | A timeline figure of city and state adoptions helps readers see the staggered nature of the policy. | Include a Gantt‑style chart (e.g., Figure 1) showing adoption year per CoC. |
| **Clarify the log transformation** | The manuscript reports “log($Y+1$)”. Mention that the ATT is interpreted as a *percent* change and provide the back‑transformation. | Add a footnote in the data section and in tables. |
| **Check typographical consistency** (e.g., “pre‑COVID” vs. “pre‑COVID”). | Improves professionalism. | Run a quick proofreading pass. |

---

### F. Minor Technical Corrections

1. **Balance Panel Definition** – The text says “balanced panel requires at least 16 of 18 years”, yet Table 1 lists 372 CoCs. Verify that the 39 treated CoCs truly satisfy the balance condition; if some treated CoCs have fewer pre‑treatment observations, report that explicitly.  
2. **Standard Errors in Table SDE** – The standardized effect size column does not include a confidence interval; adding one would aid interpretation.  
3. **Citation Consistency** – Ensure all in‑text citations have corresponding entries in the bibliography (e.g., “seron2001” appears in the intro but not in the reference list).  
4. **Software Reproducibility** – Provide a brief appendix describing the R/Stata packages used (`did`, `csdid`), version numbers, and a link to the replication repository.  

---

### G. Overall Assessment

The paper tackles a high‑policy relevance question with a novel macro‑level dataset and an appropriate modern DiD estimator. Its most valuable contribution is the “negative lesson”: without careful handling of staggered adoption and pre‑trend selection, one could mistakenly infer a sizeable homelessness reduction from RTC. However, to make the claim robust and useful for policymakers, the manuscript must:

* Center its causal claim on the subsample where parallel trends are credible.  
* Provide richer heterogeneity analysis to avoid conflating disparate policies.  
* Adopt inference methods suited to a small number of treated clusters.  

Addressing the points above will transform the manuscript from an exploratory “what‑if” piece into a definitive, policy‑relevant assessment of RTC’s macro impact. The effort required is modest relative to the data already assembled, and the resulting paper would be an excellent fit for the AER‑Insights format.
