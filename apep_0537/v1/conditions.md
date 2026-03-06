# Conditional Requirements

**Generated:** 2026-03-06T11:50:23.036480
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

---

## Generative AI as Seniority-Biased Technological Change: Evidence from SEC Filings and Occupational Employment Data

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: validating 10-K GenAI mentions against real adoption

**Status:** [x] RESOLVED

**Response:**

10-K GenAI mentions are validated as adoption proxies through three strategies:
1. **Internal validation:** Cross-reference 10-K mentions with 8-K/earnings call filings for the same firms. Firms that mention GenAI in 10-Ks AND discuss specific implementation details (hiring AI roles, deploying tools, reporting cost savings) are "validated adopters." Firms that only mention AI as a risk factor are "AI-aware" but not treated.
2. **External validation:** Eisfeldt, Schubert, and Zhang (2023, NBER w31222) showed that 10-K AI mentions predict differential stock returns and correlate with actual workforce exposure. Their "AMH" portfolio earned abnormal returns, confirming information content.
3. **Robustness:** We construct THREE alternative treatment measures: (a) any GenAI mention, (b) mentions in "business description" sections only (excludes risk-factor boilerplate), (c) count of GenAI-related terms (continuous intensity). If results hold across all three, AI-washing in one margin doesn't drive the finding.

**Evidence:** EDGAR EFTS API confirmed: 0→2→90→770→1266 10-K filings with GenAI terms from 2021-2025. The explosive growth in 2024 (770) vs 2022 (2) creates variation that precedes mere hype — firms that disclosed in 2023 are early adopters, not followers.

---

### Condition 2: explicitly addressing OEWS timing/smoothing

**Status:** [x] RESOLVED

**Response:**

Gemini correctly identified that OEWS uses a 3-year rolling sample methodology. This is a genuine limitation for sharp event-study designs. Our mitigation strategy:

1. **Primary analysis uses QCEW, not OEWS, for the time-series component.** QCEW provides quarterly industry × county employment counts with no rolling-sample smoothing. This gives us 32+ quarterly pre-periods (2015Q1-2022Q4) and 8+ post-periods (2023Q1-2024Q4). The event study is clean.
2. **OEWS is used only for occupation-level heterogeneity analysis.** OEWS provides the occupation × industry × state structure needed to classify jobs by seniority (via O*NET Job Zones) and AI exposure (via AIOE scores). We use OEWS cross-sections (2019, 2022, 2024) to measure changes in occupational composition — shares of entry-level vs. senior occupations within industries. The rolling sample biases these toward zero (attenuation), making our estimates conservative.
3. **CPS monthly microdata supplement the event study.** CPS basic monthly files provide industry × age × education employment counts at monthly frequency. Young worker (age <30) vs. prime-age (30-54) employment ratios within industry track the seniority dimension at high frequency.

This three-dataset design addresses Gemini's concern directly: QCEW handles timing, OEWS handles occupation structure, CPS handles worker characteristics.

**Evidence:** QCEW API confirmed working (quarterly CSV files). CPS microdata available through Census API for basic cross-tabulations by industry × age.

---

### Condition 3: building strong opponent-killer placebos

**Status:** [x] RESOLVED

**Response:**

Four placebo tests designed to kill the main alternative stories:

1. **Healthcare placebo:** Healthcare industries (NAICS 62) had massive GenAI discussion but primarily for clinical documentation — entry-level healthcare workers (CNAs, medical assistants) face labor shortages, not displacement. If GenAI adoption reduces entry-level employment, it should NOT appear in healthcare, where demand exceeds supply regardless of AI.
2. **Pre-ChatGPT placebo:** Run the same specification with a "placebo treatment" at 2020Q1 or 2019Q1. If results appear for the pre-ChatGPT placebo, the design is picking up secular trends, not GenAI.
3. **Senior-occupation placebo:** Within high-GenAI-adoption industries, senior occupations (Job Zones 4-5) should show flat or positive employment growth. If senior employment also declines, the mechanism is industry contraction, not seniority-biased displacement.
4. **Manual/physical occupation placebo:** Occupations with high physical task content and low AI exposure (construction, maintenance, transportation) within the same industries should be unaffected. These workers share the same employers but have zero GenAI exposure.

**Evidence:** O*NET task content scores (work activities, work context) allow clean separation of AI-exposed vs. manual occupations within the same industry codes.

---

### Condition 4: negative controls

**Status:** [x] RESOLVED

**Response:**

Addressed jointly with Condition 3 above. Additionally:

1. **Pre-existing automation exposure control:** Industries with high pre-2023 robotics/automation adoption (manufacturing) already experienced entry-level displacement. If our GenAI measure picks up pre-existing automation trends, the effect should be concentrated in already-automated industries. We test this by interacting GenAI adoption with pre-existing automation intensity (Acemoglu-Restrepo measures).
2. **Interest rate / tech correction control:** The 2022-2023 tech correction is the strongest confounder (Gemini's point). We directly control for industry-level equity returns, IPO activity, and VC funding as proxies for the tech cycle. We also run the specification excluding NAICS 51 (Information) and 54 (Professional Services) to show effects are not driven solely by the "tech recession."

**Evidence:** FRED API confirmed working for industry-level economic controls.

---

### Condition (from GPT-5.4 B): addressing OEWS rolling-sample limitations

**Status:** [x] RESOLVED

**Response:** See Condition 2 above — same issue, same resolution. QCEW is the primary data source for time-series variation; OEWS is used only for occupation-level structure.

---

### Condition (from GPT-5.4 B): validating 10-K mentions as actual adoption

**Status:** [x] RESOLVED

**Response:** See Condition 1 above.

---

### Condition (from GPT-5.4 B): adding strong within-industry placebo tests

**Status:** [x] RESOLVED

**Response:** See Condition 3 above — placebos 3 and 4 are explicitly within-industry tests (senior occupations and manual/physical occupations within the same industry).

---

### Condition (from GPT-5.4 B): sensitivity to public-firm coverage

**Status:** [x] RESOLVED

**Response:**

SEC 10-K filings cover only publicly traded firms (~4,000 10-K filers). This is a coverage limitation. Mitigations:

1. **Industry-level aggregation resolves the coverage concern.** We measure GenAI adoption at the 4-digit NAICS level (share of public filers mentioning GenAI). Public firms are industry leaders whose adoption decisions signal industry-wide technology diffusion. If GenAI adoption is seniority-biased, the effect should appear in industry-level employment even if driven initially by large public firms.
2. **Robustness with alternative adoption measures.** We construct a second treatment using the Felten-Raj-Seamans AIOE scores (occupation-level AI exposure, no firm-level data needed). If both the firm-disclosure measure and the task-exposure measure yield similar seniority-biased effects, the finding is robust to the public-firm selection issue.
3. **QCEW covers all firms, including private.** Since our employment outcomes come from QCEW (which covers 95% of all U.S. jobs including private firms), we are measuring economy-wide employment responses, not just public-firm responses. The treatment comes from public firms; the outcomes come from the universe.

**Evidence:** SEC EDGAR CIK count: thousands of 10-K filers per year. QCEW covers 10.5M+ establishments.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
