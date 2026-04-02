# V1 Empirics Check — google/gemini-3-flash-preview (Variant A)

**Model:** google/gemini-3-flash-preview
**Variant:** A
**Date:** 2026-04-02T16:49:55.027086

---

This review evaluates the paper **"Upzoned but Unbuilt? State Single-Family Zoning Preemption and the Missing Middle Gap"** following the AER: Insights format.

### 1. Idea Fidelity
The paper aligns closely with the original idea manifest. It successfully utilizes the Census Building Permits Survey (BPS) at the county level, employs a staggered DiD (Callaway-Sant’Anna and TWFE), and incorporates the suggested placebo (5+ unit permits). 
*   **Deviation:** The paper adds a "Montana exclusion" test and an "Urban vs. Rural" split which were suggested in the manifest's mechanism section but executes them with more skepticism toward the Montana data than originally envisioned. 
*   **Missing Element:** The original idea suggested using FHFA HPI (housing price level) as a heterogeneity factor. This is missing from the current draft and would have strengthened the "Unprofitable vs. Illegal" argument in the discussion.

### 2. Summary
The paper evaluates the impact of state-level single-family zoning preemption on "missing middle" (2–4 unit) housing construction across four US states. Using a staggered DiD design, it finds a null effect in the pooled sample but identifies a significant 2.6 percentage point increase in Oregon. The author attributes this divergence to an "implementation gap," where Oregon’s prescriptive state-level mandates and enforcement mechanisms succeeded while other states' more permissive frameworks were thwarted by local regulatory friction.

### 3. Essential Points
1.  **Unit of Analysis and Policy Mismatch:** The policy (e.g., Oregon HB 2001 or Montana SB 382) applies specifically to cities/municipalities above certain population thresholds (10k, 25k, 5k). However, the analysis uses **county-level** data. Many counties contain both large cities (treated) and unincorporated areas/small towns (untreated). This creates significant measurement error and attenuation bias. The author must either move to place-level BPS data or include a "treatment intensity" measure (e.g., share of county population living in affected municipalities).
2.  **The Montana "Pre-trend" Issue:** The paper notes a $p=0.007$ rejection of parallel trends, largely driven by Montana. If the pre-trends are violated, the DiD estimates for the pooled model and the Montana specific model are biased. Given the small number of treated units (4 states), a single state with a "funky" pre-trend can invalidate the entire pooled result. The author needs to more rigorously address this, perhaps using synthetic control for the individual state estimates.
3.  **Permit Lag and Sample Period:** The "Post" period for Montana (2023) and even late-2022 adopters is extremely short for a construction-based outcome. Given the time required for a builder to learn local code, acquire land, design a duplex, and file a permit, a 2024 cutoff for a 2023 law (Montana) almost guarantees a null result. The conclusion that the law was "ineffective" in Montana or Maine is premature without more post-treatment years or a monthly-level analysis.

### 4. Suggestions
*   **Switch to Monthly Data:** The BPS provides monthly CSVs. Using monthly data would allow for much finer-grained event studies and help disentangle the "anticipation effects" mentioned in Section 4.4. It would also help isolate the "interest rate shock" of late 2022 more cleanly than annual data.
*   **Place-Level BPS:** I strongly recommend using the BPS Place-level data instead of County-level. This would allow the author to match the population thresholds in the state laws (e.g., only looking at Oregon cities >10k) and provide a much cleaner treatment/control contrast within the same state.
*   **Control for Economic Factors:** The paper mentions interest rates and construction costs in the discussion but does not control for them. Including the FHFA House Price Index (as suggested in the manifest) or local unemployment/wage data as covariates would help separate the "implementation gap" from general economic cooling in the West.
*   **Clarification on "Missing Middle" definition:** The Census BPS "3-4 unit" category is a stock variable for the building. Some "missing middle" reforms might encourage two duplexes on one lot (which would show up as two "2-unit" entries) or ADUs. Note that the BPS often misses ADUs if they are permitted as "additions" rather than new structures. A brief discussion on what types of missing middle are *not* captured by BPS would add rigor.
*   **Mechanism: Substitution vs. Expansion:** To strengthen the "YIMBY model" discussion, explicitly test if the MM units are replacing single-family homes (negative coefficient on 1-unit log permits) or adding to the total (positive coefficient on total permits). Table 2 hints at a decline in 1-unit permits; the author should emphasize whether this is a "land-use swap" or just a general market downturn.
*   **The "Washington" Placebo:** The paper excludes Washington because it hasn't reached the compliance date. This is actually a perfect setup for a "Placebo State" test. Show that Washington (where the law is passed but not yet in effect) shows zero effect, which would support the "compliance deadline" mechanism argued for Oregon.
*   **Standardized Effect Sizes (Table 5):** The classification of 2.6 pp as "Large" is technically correct relative to the baseline, but in terms of absolute housing units, it's quite small. Framing this as "necessary but not sufficient" (as you do in the conclusion) is excellent; perhaps add a back-of-the-envelope calculation on how many years of this growth would be needed to close the state's estimated housing gap.
*   **Table 3 Construction:** In Table 3, the $N$ for each state-specific regression is listed as ~30,000, which implies you are using 2,900+ control counties for every single state. While standard, it might be more robust to use "Neighbor-state" controls to account for regional construction cycles (e.g., using Idaho as a control for Montana/Oregon).
