# Reply to Reviewers

## Reviewer 1 (GPT-5.2): MAJOR REVISION

### 1. Exposure/traffic volume confounding
> "The outcome is collisions, not risk per mile. If the policy changes driving patterns... collisions could fall even if per-mile risk is unchanged."

**Response:** We acknowledge this limitation explicitly in the revised Limitations section (now limitation #1). We note that the null effect on 40+ mph roads argues against large-scale route diversion but cannot definitively rule out exposure changes without traffic count data at the PFA-month level. The STATS19 data do not include traffic volumes.

### 2. Property identification not credible
> "Wales vs England is far too coarse for housing markets... Wales-specific policies, migration, housing cycles could drive the result."

**Response:** We agree. The revised paper adds a quarterly property event study (Figure 5) that reveals pre-trends in Welsh prices beginning approximately two years before implementation. We have substantially revised the property interpretation throughout: the abstract, introduction, results, cost-benefit discussion, and conclusion now describe the property result as "suggestive" rather than causal. We note that a more credible design (within-Wales intensity variation, border spatial DiD) is needed for future work.

### 3. Wild cluster bootstrap
> "Report wild cluster bootstrap p-values."

**Response:** We add a discussion of MacKinnon, Nielsen & Webb (2023), who show that wild cluster bootstrap can be severely oversized when the number of treated clusters is below 5. With only 4 treated Welsh PFAs, randomization inference is the more appropriate exact test, and we explain this choice in the Inference subsection.

### 4. Partial reversals / treatment intensity
> "Split the post period, or incorporate intensity measures."

**Response:** Added. We now report an early vs. late post-period split: early (Sep 2023-Feb 2024, before reversals) yields -0.209 (p=0.001) and late (Mar-Dec 2024) yields -0.237 (p=0.082). No evidence of treatment fade-out.

### 5. Elevate Poisson / ln(y+1) concern
> "ln(y+1) can be misleading with low counts."

**Response:** The Poisson QMLE result (-0.201, p=0.015) is already reported and closely matches the log-linear estimate. We note the concordance explicitly in the robustness discussion.

### 6. Report casualties (persons) not just collisions
> "Welfare relevance is casualties, not collisions."

**Response:** STATS19 supports casualty-level analysis but would require substantial additional data processing for this revision. The collision-level results are the standard in the UK road safety literature. We acknowledge this as a direction for future work.

### 7. Spillover handling
> "Border spillovers can bias estimates."

**Response:** The existing "Border PFAs only" specification (Table 3 Col 3) restricts to border English PFAs, where spillovers are most likely. The similar estimate (-0.226) suggests spillovers are not driving the result. We add a Scottish placebo caveat noting the N=1 limitation.

---

## Reviewer 2 (Grok-4.1-Fast): MINOR REVISION

### 1. Quantify reversal intensity
> "Estimate % roads reverted post-March 2024."

**Response:** Exact reversal data by local authority are not publicly available at the road-segment level. We address this with the early/late post-period split, which shows no fade-out. We discuss this limitation explicitly.

### 2. Scottish placebo N=1
> "Acknowledge N=1 limits power."

**Response:** Added explicit footnote noting that Police Scotland is a single PFA, limiting the power of this test.

### 3. Cite Roth (2022), Wong-Zimmerman (2023)
> "State-of-art small-N/power in DiD/RI."

**Response:** Added Roth (2022) on pretest power and MacKinnon, Nielsen & Webb (2023) on cluster-robust inference. Wong-Zimmerman (2023) is a working paper focused on staggered settings that is less directly relevant to our non-staggered design.

### 4. Property event study
> "Add quarterly leads/lags."

**Response:** Added (Figure 5). The event study reveals pre-trends that we discuss honestly.

---

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

### 1. Property event study
> "Vital to see when the price jump occurs."

**Response:** Added (Figure 5). The pattern shows pre-trends beginning around the legislation date (July 2022), which we discuss transparently.

### 2. Per-capita specification
> "Report collisions per 100,000 population."

**Response:** ONS mid-year population estimates by PFA are not readily available at the monthly frequency needed. The log specification already normalizes for PFA size (proportional effects), and the Poisson model provides a rate-like interpretation. We note per-capita analysis as a valuable extension.

### 3. Border analysis at finer geography
> "LSOA-level near the border would strengthen the claim."

**Response:** STATS19 provides collision coordinates, but LSOA-level panel construction would require geocoding all collision records to LSOAs and handling boundary changes — beyond the scope of this revision. We note this as promising future work.

### 4. Reversal heterogeneity / treatment fade-out
> "Test for treatment fade-out in later months."

**Response:** Added early/late post-period split showing no fade-out (-0.209 early, -0.237 late).

---

## Exhibit Improvements (from Exhibit Review)
- Moved RI histogram (Figure 3) to Appendix
- Removed redundant severity coefficient plot (Figure 4)
- Added property event study figure (new Figure 5)
- Added Observations row to Table 3
- Added Clusters (districts) to Table 4

## Prose Improvements (from Prose Review)
- Deleted roadmap paragraph from Introduction
- Improved KSI result narration (active voice, human stakes)
- Tightened transitions throughout
