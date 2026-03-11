# Reply to Reviewers — Round 1

## Internal Review (review_cc_1.md)

### Issue 1: RI permutation count inconsistency (500 vs 1000)
**Response:** Fixed. Updated all references from "500" to "1,000" to match the code.

### Issue 2: Pre-trend concern for RTEP data
**Response:** Added discussion in Limitations section acknowledging that (a) RTEP data are partially model-based, introducing potential measurement error, and (b) pre-trend tests under a uniform-price subsidy are partly mechanical.

### Issue 3: Abstract framing
**Response:** The abstract already leads with the cereal result as the headline. The petrol gradient is appropriately qualified as "in shorter windows." No change needed.

### Issue 4: Distance discrepancy (1,400 vs 1,160 km)
**Response:** Fixed. Changed "1,400 kilometers" to "over 1,100 kilometers as the crow flies" for consistency with the Haversine measure.

### Issue 5: Welfare calculation
**Response:** Added back-of-envelope calculation in Discussion using Maiduguri (1,160 km) as consistent example: ~123% more cereal price inflation, ~₦18,000/month additional food expenditure.

---

## External Reviews (Stage C)

### Reviewer 1 (GPT-5.4 R1) — Reject and Resubmit

**1. Food identification not credible enough**
Response: Added (a) cereal-specific event study (Figure 8) showing no systematic pre-trends, (b) commodity-by-month FE robustness (coefficient virtually unchanged at 0.067 vs 0.070), and (c) softened language throughout to frame food results as "reduced-form geographic differentials" rather than structural pass-through. We agree that the food specification is a reduced form, not a causal chain from fuel to food, and now state this explicitly.

**2. 14 clusters too few for CRVE**
Response: Added Conley spatial HAC standard errors (200km cutoff). Cereal result remains significant (β/SE_Conley ≈ 3.2). We acknowledge that RI and Conley are supplements, not replacements, for proper finite-sample inference.

**3. Cereal magnitude 7x petrol gradient**
Response: Added new Discussion subsection "Reconciling Petrol and Cereal Magnitudes" explaining supply chain amplification, non-coincident transport routes, and the possibility that the food coefficient captures additional geographic heterogeneity.

**4. RTEP model-based data**
Response: Already acknowledged in Limitations. The food price results (from directly observed WFP data) are the paper's primary contribution.

**5. Protein not a clean placebo**
Response: Changed "built-in placebo" language to "contrast groups that probe the mechanism."

**6. Commodity-by-month FE for food**
Response: Added. All-food β = 0.0043, Cereals β = 0.0674 — virtually unchanged from baseline.

### Reviewer 2 (GPT-5.4 R2) — Reject and Resubmit

**1-5:** Largely overlap with R1. See responses above. Key additions: food event study, Conley SEs, commodity-by-month FE, softened causal language, magnitude reconciliation.

**6. RTEP validation against NBS**
Response: NBS provides state-level averages, not market-level data. A direct validation is not possible at the same granularity. We note this limitation.

**7. Triple-difference with diesel**
Response: Interesting suggestion for future work. Diesel was already deregulated, so a simple DDD is conceptually unclear (both fuels experienced the same macro shocks, but PMS had the discrete regime change).

### Reviewer 3 (Gemini-3-Flash) — Minor Revision

**1. RTEP model-based concern**
Response: Addressed in Limitations and by emphasizing WFP food results as primary.

**2. Cereal vs. Roots/Tubers contrast**
Response: Added Roots/Tubers column (Table 3, Col 6) and explicit discussion of production geography.

**3. Road distance robustness**
Response: No routing data available. Noted that Haversine-road correlation >0.9 for our sample.
