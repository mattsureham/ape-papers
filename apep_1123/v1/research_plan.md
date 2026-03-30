# Research Plan: The Registration Effect — Transparency Mandates and Selective Reporting in Clinical Trials

## Research Question

Does mandating pre-registration of clinical trial outcomes reduce selective outcome reporting? The FDA Amendments Act of 2007 (FDAAA 801) required Phase 2+ interventional trials to register primary outcomes on ClinicalTrials.gov within 21 days of first enrollment, while explicitly exempting Phase 1 trials. This Phase-based exemption creates a natural control group for a difference-in-differences design.

## Identification Strategy

**DiD with Phase 1 (exempt) as control and Phase 2/3 (mandated) as treatment.**

- **Treatment group:** Phase 2, Phase 3, and Phase 2/3 interventional trials started after September 27, 2007
- **Control group:** Phase 1 trials (explicitly exempt from FDAAA 801)
- **Pre-period:** Trials started 2003-2007 (ClinicalTrials.gov launched February 2000, but coverage thins before 2003)
- **Post-period:** 2008-2015 (before 2017 Final Rule enforcement dose)
- **Second treatment dose:** January 2017 Final Rule (42 CFR Part 11) added civil monetary penalties up to $10,000/day — provides a second event study window

## Expected Effects and Mechanisms

1. **Results reporting rate (primary):** FDAAA 801 should increase the share of completed Phase 2/3 trials that post results within 1 year. Pre-reform, ~20% of trials posted results (Zarin et al. 2011). If the mandate binds, Phase 2/3 reporting should rise differentially.

2. **Time to results posting:** Mandate should reduce days between study completion and results posting for Phase 2/3 relative to Phase 1.

3. **Primary outcome count:** If transparency constrains gaming, trialists may pre-specify fewer, more precise primary outcomes to avoid later accusations of switching. Alternatively, they may specify more outcomes as insurance.

4. **Industry vs. academic heterogeneity:** Industry sponsors face stronger enforcement incentives (FDA oversight of drug approval). Academic trials may respond less.

## Primary Specification

$$Y_{it} = \alpha + \beta \cdot \text{Phase2+}_i \times \text{Post}_t + \gamma \cdot \text{Phase2+}_i + \delta_t + \mathbf{X}_{it}'\theta + \varepsilon_{it}$$

Where:
- $Y_{it}$: results reported (binary), days to reporting, primary outcome count
- $\text{Phase2+}_i$: indicator for Phase 2/3 trial
- $\text{Post}_t$: indicator for start date after September 2007
- $\delta_t$: year fixed effects
- $\mathbf{X}_{it}$: controls for sponsor type, therapeutic area, study design (randomized, blinded), enrollment size

Standard errors clustered by therapeutic area (condition category).

## Data Source and Fetch Strategy

**ClinicalTrials.gov API v2** (https://clinicaltrials.gov/api/v2/studies)
- No API key required
- Returns JSON with pagination (1000 studies per page)
- Filter: `query.term=AREA[StudyType]Interventional`
- Fields needed: NCTId, Phase, StartDate, CompletionDate, ResultsFirstPostDate, OverallStatus, LeadSponsorClass, Conditions, DesignAllocation, DesignMasking, EnrollmentCount, DesignOutcomeMeasures (primary outcome list)

**Fetch plan:**
1. Query all interventional studies with start dates 2000-2017
2. Filter to Phase 1, Phase 2, Phase 3, Phase 2/3
3. Extract primary outcome count from DesignOutcomeMeasures
4. Compute: has_results (binary), days_to_results (CompletionDate → ResultsFirstPostDate)
5. Save as CSV for R analysis

## Tables Planned

1. **Table 1:** Summary statistics by phase and period (pre/post 2007)
2. **Table 2:** Main DiD — results reporting rate
3. **Table 3:** Mechanism — primary outcome count and time to reporting
4. **Table 4:** Heterogeneity by sponsor type (industry vs. academic)
5. **Table F1 (SDE Appendix):** Standardized effect sizes

## Exposure Alignment

The treatment in this DiD design is phase-based classification, which serves as a proxy for FDAAA 801 applicability. The actual mandate applies to "applicable clinical trials" — Phase 2+ interventional studies of FDA-regulated products. Our Phase 2/3 treatment group includes some trials that may not be legally covered (non-FDA-regulated products, non-US trials without FDA nexus), creating attenuation bias. Conversely, the Phase 1 control group is genuinely exempt from the mandate. The exposure alignment is therefore asymmetric: the control group cleanly satisfies the "exempt" criterion, but the treatment group is a noisy measure of mandate exposure. The industry and US-site heterogeneity analysis partially addresses this by isolating trials where mandate exposure is most likely (industry sponsors with FDA oversight, trials with US sites where FDAAA has direct legal force).

## Key Risks

- **Selection into registration:** Pre-2007 registration was voluntary; post-2007 it was mandatory for Phase 2+. This changes the composition of registered trials. Mitigation: restrict to trials that would have been registered under either regime (industry-sponsored, US-based).
- **Anticipation:** Some trials may have anticipated the law. Mitigation: event study to check for pre-trends.
- **Phase 1 not a perfect control:** Phase 1 trials differ systematically (smaller, earlier-stage, different sponsors). Mitigation: control for enrollment, sponsor type, therapeutic area; show parallel pre-trends.
