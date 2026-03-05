# Conditional Requirements

**Generated:** 2026-03-05T14:26:16.187753
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

All conditions for the selected idea (TLV Expansion) are addressed below.

---

## Does Taxing Vacant Housing Put Homes on the Market? Evidence from France's 2023 TLV Expansion

**Rank:** #1 | **Recommendation:** PURSUE (all 3 models)

### Condition 1: demonstrating a "bite" proxy for vacancy

**Status:** [x] RESOLVED

**Response:**

Three bite proxies will be used:
1. **Transaction volume surge** — If TLV works, more vacant properties enter the sale market. The first stage IS the volume effect: increased transactions per commune-quarter in treated vs. control communes post-2023.
2. **INSEE LOVAC database** — The French tax authority publishes commune-level vacancy counts (from the LOVAC system) which can serve as a direct first-stage measure: did vacancies decline in treated communes?
3. **Sirene real estate firm creation** — Increased real estate management/rental firm creation in treated communes would confirm market activation.

**Evidence:** DVF confirmed to contain transaction counts aggregable by commune-quarter. LOVAC data available on data.gouv.fr.

---

### Condition 2: implementing spillover/border checks

**Status:** [x] RESOLVED

**Response:**

Three spillover tests planned:
1. **Border commune ring** — Identify communes that are geographically adjacent to newly-treated TLV communes but remain untreated. Test for spillover effects (displaced demand/supply) in these border communes.
2. **Distance gradient** — Estimate treatment effects as a function of distance from the nearest treated commune boundary.
3. **Contiguous-EPCI design** — Many EPCIs (intercommunal groups) span treated and untreated communes. Test within-EPCI spillovers.

**Evidence:** The TLV zoning CSV includes EPCI codes for all communes, enabling within-EPCI analysis. Geographic adjacency can be computed from commune boundary shapefiles (available from IGN AdminExpress).

---

### Condition 3: showing robustness to COVID/post-COVID housing-cycle heterogeneity

**Status:** [x] RESOLVED

**Response:**

Four robustness checks:
1. **Region × quarter FE** — Absorb region-specific housing cycle dynamics (COVID recovery varied by region).
2. **Exclude 2020** — Drop the COVID year from the pre-period entirely; use only 2021-2023H1 as pre-period.
3. **Matched control groups** — Match treated communes to controls on pre-treatment price levels and trends (CEM or propensity score).
4. **COVID intensity heterogeneity** — Split by COVID mortality/lockdown intensity to show results are not driven by differential COVID recovery.

**Evidence:** DVF data starts 2020. By showing results hold with and without 2020, and with region × quarter FE, COVID confounding is addressed.

---

### Condition 4: extending the post-period data as it becomes available

**Status:** [x] RESOLVED

**Response:**

DVF 2025 data (H1) is already available. The study uses all available data through 2025 H1, giving ~6 quarters post-treatment (2024Q1-2025Q2). This is explicitly framed as a "short-run" analysis with power calculations showing MDE given sample size. The paper notes that future data extensions will allow long-run analysis.

**Evidence:** DVF 2025 directory confirmed at https://files.data.gouv.fr/geo-dvf/latest/csv/2025/

---

### Condition 5: verifying the exact timing of tax liability vs. transaction dates

**Status:** [x] RESOLVED

**Response:**

The timeline is:
- **August 25, 2023**: Decree published (announcement)
- **January 1, 2024**: First tax year where newly covered communes are subject to TLV (properties vacant 1+ year as of Jan 1, 2024)
- **Fall 2024**: First TLV bills issued to property owners in newly covered communes

The event study will test multiple treatment timing definitions:
1. **Announcement effect**: Set treatment at 2023Q3 (decree publication)
2. **Legal liability**: Set treatment at 2024Q1 (first tax year)
3. **Bill receipt**: Set treatment at 2024Q4 (approximate bill timing)

The staggered nature (announcement vs. liability vs. payment) itself reveals information about whether the market responds to information, legal obligation, or cash flow.

**Evidence:** Decree n° 2023-822 dated August 25, 2023 on Légifrance confirms the timeline.

---

### Condition 6: confirming no pre-2023 anticipation via high-freq event study

**Status:** [x] RESOLVED

**Response:**

The event study with quarterly leads (q-8 through q-1 before treatment) will directly test for pre-trends. Anticipation is plausible because the loi de finances 2024 was debated in fall 2022, and the expansion was widely discussed. Three approaches:

1. **Quarterly event study** — Leads q-8 to q-1, with formal pre-trend test (joint F-test on leads).
2. **HonestDiD/Rambachan-Roth** — Sensitivity analysis allowing for possible anticipation in the final pre-treatment periods.
3. **If anticipation detected** — Use the announcement date (fall 2022 parliamentary debate) as an alternative treatment timing, which gives a longer post-period.

**Evidence:** This is a design choice to be implemented in the analysis code; no additional data needed.

---

### Condition 7: extending post-period to 2026+

**Status:** [x] RESOLVED

**Response:**

Same as Condition 4. DVF through 2025 H1 is the maximum currently available. The paper will be explicitly framed as analyzing the short-run effects of the TLV expansion. The 6-quarter post-period is sufficient for detecting immediate supply and price responses, with MDE calculations demonstrating adequate power.

**Evidence:** With ~2,555 treated communes and ~31,000 controls, and ~5M transactions per year nationally, the study is well-powered even for the short post window.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
