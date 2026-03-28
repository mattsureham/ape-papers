# Revision Plan: apep_0727 v2 — "Too Small by Design"

## Context

**Parent:** apep_0727 v1 (Rating: 24.0, μ=29.5)
**Title:** "Too Small by Design: Bunching Evidence on Germany's Solar Capacity Trap"
**Mode:** New V2 revision from published V1

The V1 documents a 281:1 bunching ratio at Germany's 10 kWp solar threshold — one of the largest in applied economics. But it stops at the fact. Three strategic reviewers and both V1 empirics reviewers independently converge: the paper needs (1) the 2021 threshold reversal test, (2) mechanism evidence on the installer channel, and (3) a general lesson beyond "huge bunching in German solar."

**Co-author agreement:** Claude and Codex converged on this paper after three rounds of deliberation. Codex initially preferred apep_0501 (Swiss mergers), but switched after MaStR data availability was verified (Bundesnetzagentur bulk download: 2.8 GB XML, daily updates; Zenodo pre-processed CSVs).

---

## Hard Stage Gate: Smoke Test Before Full V2

**Do NOT open a full V2 workspace until three raw facts are confirmed in the MaStR data:**

1. Strong 10 kWp bunching in 2014-2020 (replicates V1 finding)
2. Clear attenuation of 10 kWp bunching in 2021-2022
3. Visible emergence of bunching at 30 kWp in 2021-2022

**If any of these fail:** Stop and reassess. The entire V2 case rests on the reversal. A failed smoke test means we pivot to apep_0501 (fallback) or reframe 0727 as a persistence story.

**Operationally:** Download MaStR data → clean → plot raw 0.1 kWp densities in four periods → visual inspection → go/no-go decision. This should take < 1 hour.

---

## Period Definitions (Verify Exact Legal Dates First)

Before defaulting to calendar-year bins, verify the statutory effective dates:

| Reform | Statute | Effective Date | Scope |
|--------|---------|---------------|-------|
| EEG 2014 | BGBl. I S. 1066 | August 1, 2014 | Self-consumption surcharge on systems ≥10 kWp |
| EEG 2021 | BGBl. I S. 3138 | January 1, 2021 | Threshold raised to 30 kWp for full exemption |
| EEG 2023 | BGBl. I S. 1234 | ~July 2022 / Jan 2023 | Surcharge abolished for systems ≤30 kWp |

Build event windows from statutory dates. Calendar-year bins are a clean simplification only if the mid-year reforms don't contaminate the annual estimates. For 2014 specifically, consider splitting H1 vs H2 or dropping 2014 as a transition year.

**Working periods (pending verification):**
- Pre-policy: 2008-2013
- EEG 2014 surcharge: H2 2014 – 2020
- EEG 2021 threshold shift: 2021 – mid-2022
- EEG 2023 abolition: mid-2022 – 2025

---

## Main Sample and Placebo

**Main sample: Rooftop systems only** (Gebäudesolaranlage / `Lage` = rooftop). The surcharge and self-consumption logic bite on rooftop residential systems. Do not mix with commercial or ground-mount installations in the main estimand.

**Placebo: Ground-mount systems** (Freiflächenanlage). Different incentive structure (no self-consumption motive). Bunching at 10 kWp should be absent. Report separately as a formal placebo test.

---

## Priority-Ordered Steps

### Step 1: Data Rescue (CRITICAL — first hour)

**Source:** Zenodo pre-processed CSVs (fastest) or direct MaStR XML from Bundesnetzagentur.

**Required fields:** Nettonennleistung (capacity), Inbetriebnahmedatum (date), Lage (installation type), AnzahlSolarModule (module count), Bundesland + Gemeinde (location), Betreiber info (if in extended tables).

**After fetch:** Run smoke test immediately. Plot raw densities. Go/no-go.

### Step 2: Core Analysis — The Three-Break Identification

Make the 2012 kink vs 2014 notch vs 2021 reversal the **central identification exercise**, not just background:

**2a. Pre-2012 baseline:** No policy threshold at 10 kWp. Should show minimal bunching (round-number effects only). This is the true counterfactual.

**2b. 2012 FIT kink:** The EEG 2012 introduced a modest feed-in tariff tier at 10 kWp (kink, not notch). Moderate bunching expected (ratio ~10-28 from V1 annual estimates). This establishes the kink response.

**2c. 2014 surcharge notch:** The EEG 2014 surcharge creates a notch (dominated region). Explosive bunching (ratio ~80-136). The jump from kink-level (~28 in 2013) to notch-level (~80+ in 2014) is the main causal identification: same threshold, same agents, but the incentive changed from a kink to a notch.

**2d. 2021 threshold migration:** If bunching at 10 kWp attenuates and appears at 30 kWp, the paper has within-design validation. The complete causal arc: no threshold → kink → notch → reversal.

**2e. 2023 abolition:** Bunching at both 10 and 30 should attenuate/disappear. Triple validation.

### Step 3: Mechanism Evidence (Tiered)

**Tier 1 (decisive):**
- Threshold migration from 10→30 kWp (from Step 2)
- Module count evidence: show discrete panel removal at the threshold margin

**Tier 2 (strong):**
- Rooftop vs ground-mount placebo (from main sample definition)
- 2012 kink vs 2014 notch decomposition (from Step 2)

**Tier 3 (suggestive — appendix or secondary):**
- Municipality-level operator density as installer-competition proxy
- Do NOT call this "installer proof" — it is market-organization evidence

### Step 4: Welfare (Disciplined)

- Formal Kleven-Waseem counterfactual distribution → dominated region → total foregone capacity in MW
- Convert to foregone GWh/year at German insolation
- **Do NOT lead with CO2** unless the mapping is clean and the paper is already credible on quantity distortion. Main welfare object: "capacity left on rooftops"
- Bootstrap uncertainty on the foregone MW estimate

### Step 5: Rewrite Paper

**Reframe around the general proposition:**
> When do policy thresholds generate near-complete avoidance? When the decision-maker is a repeat optimizer, the technology is modular, and the stake exceeds the adjustment cost by an order of magnitude.

**Section structure:**
1. Introduction — 281:1 hook → general lesson → preview reversal
2. Institutional Background — EEG 2012/2014/2021/2023 reforms; the installer channel
3. Data — MaStR universe (2008-2025), rooftop main sample, ground-mount placebo
4. Empirical Strategy — Kleven-Waseem, difference-in-bunching, three-break identification
5. Results — 10 kWp bunching (four-period), 30 kWp emergence, annual event study
6. Mechanisms — Module counts, installation type placebo, kink vs notch decomposition
7. Welfare — Foregone MW, GWh, counterfactual distribution
8. Discussion — General lessons for threshold-based policy design
9. Conclusion

**Figures (up to 10 main text):**
1. **Money Figure A:** Local density around 10 kWp (8-12 kWp window), four periods overlaid
2. **Money Figure B:** Local density around 30 kWp (28-32 kWp window), pre/post 2021
3. Annual bunching ratio time series at 10 kWp (2008-2025) with vertical break lines
4. Annual bunching ratio at 30 kWp (2019-2025)
5. Counterfactual vs observed density with shaded excess mass
6. Module count distribution near the threshold
7. Rooftop vs ground-mount density at 10 kWp
8. State-level bunching ratio forest plot or map

**Main-text tables (5-6, not 9):**
- Tab 1: Summary statistics by period
- Tab 2: Main bunching estimates (10 kWp, four periods + 30 kWp post-2021)
- Tab 3: Annual bunching time series (compact)
- Tab 4: Mechanism evidence (module counts, installation type, kink vs notch)
- Tab 5: Robustness (polynomial degree, exclusion window, placebo thresholds)
- SDE appendix table

**Appendix tables:** State heterogeneity, operator density heterogeneity, welfare sensitivity, additional robustness

### Step 6: Review Pipeline

Per `revise_and_publish.py`:
- Internal review (both co-authors) → 3+ substance loops, 2+ craft loops
- Pre-mortem (3-5 most likely attacks)
- Advisor review → Exhibit review → Prose review
- Late literature audit
- Referee review → Reply to reviewers
- Publish with `--parent apep_0727`

---

## Code Structure (V2)

```
code/
  00_packages.R          # Add: ggplot2, sf, scales, viridis
  01_fetch_data.py       # Rewrite: MaStR bulk download (Zenodo CSV or XML)
  01_fetch_data.R        # Validate fetched data, verify fields
  02_clean_data.R        # 4 periods, installation type filter, module count
  03_main_analysis.R     # 4-period bunching at 10 kWp + 30 kWp threshold
  04_robustness.R        # Ground-mount placebo, module count, kink vs notch
  05_figures.R           # All V2 figures
  06_tables.R            # All V2 tables including SDE
```

---

## Kill-Shot Concerns

| Risk | Mitigation |
|------|-----------|
| MaStR download fails | Zenodo CSV as fallback; open-mastr as backup |
| 10 kWp bunching persists post-2021 | Interesting finding itself; reframe as persistence |
| No 30 kWp bunching (EEG 2023 abolished quickly) | Check 2021-2022 window; note short treatment |
| Betreiber data too coarse | Downgrade to appendix; rely on reversal + module count |
| Ground-mount sample too small | Report N; note limitation; other mechanisms carry |
| Smoke test fails on any of 3 criteria | Pivot to apep_0501 (fallback) |

---

## Verification

1. All R scripts run end-to-end without error
2. `pdflatex` compiles clean
3. Page count ≥ 25
4. All numbers in text match generated table files (single-source-of-truth rule)
5. Density figures render correctly
6. `revise_and_publish.py` passes all preflight checks
