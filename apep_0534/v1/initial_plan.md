# Initial Research Plan: Green Patent Examiner Leniency IV

## Research Question

Does granting a green technology patent causally increase or decrease follow-on clean energy innovation? The intellectual property regime governing clean energy is one of the most contested questions in climate economics: patents incentivize private R&D but may block technology diffusion needed for the energy transition. We resolve this debate using quasi-random assignment of patent applications to USPTO examiners of varying leniency.

## Identification Strategy

**Examiner leniency IV (UJIVE estimator per Chyn, Frandsen & Leslie 2024)**

Within each USPTO art unit, patent applications are quasi-randomly assigned to examiners. Examiners differ substantially in their propensity to grant patents. We construct a leave-one-out examiner leniency measure within art-unit × application-year cells.

- **Endogenous variable:** Patent grant decision (grant = 1, deny/abandon = 0)
- **Instrument:** Leave-one-out examiner grant rate within art-unit × year
- **Key assumption:** Conditional on art-unit × year FE, examiner assignment is orthogonal to application quality
- **Exclusion restriction:** Examiner affects downstream innovation outcomes only through the grant/deny decision

## Expected Effects and Mechanisms

**Hypothesis 1 (Incentive channel):** Patent protection incentivizes follow-on R&D by ensuring appropriability → positive effect on follow-on innovation.

**Hypothesis 2 (Blocking channel):** Patent protection creates freedom-to-operate barriers for competitors → negative effect on third-party innovation, positive on own-firm innovation.

**Hypothesis 3 (Disclosure channel):** Patent publication reveals technical knowledge → positive effect on follow-on innovation by others, especially in distant locations.

The net effect is ambiguous ex ante. If H1+H3 > H2, patents promote cumulative innovation. If H2 > H1+H3, patents hinder it.

## Primary Specification

**Structural equation:**
Y_i = alpha + beta * GRANT_i + X_i'gamma + delta_{at} + epsilon_i

where:
- Y_i = follow-on Y02 applications by other inventors in same CPC subclass within 5 years
- GRANT_i = indicator for whether application i was granted
- X_i = application characteristics (number of claims, backward citations, applicant type)
- delta_{at} = art-unit × application-year fixed effects
- GRANT_i instrumented by leave-one-out examiner leniency Z_i

**UJIVE estimator** handles many-instrument bias from >2,000 examiners.

## Primary Outcomes (ordered by proximity to treatment)

1. **Follow-on Y02 patent applications** by other inventors in same CPC subclass (3/5/10 year windows)
2. **Geographic diffusion breadth** — number of distinct MSAs where follow-on inventors are located
3. **Assignee continuation** — subsequent Y02 filings by the same applicant firm
4. **Technology scope** — follow-on filings in related but distinct Y02 subclasses

## Secondary/Robustness Outcomes

- Forward citations (robustness only — mechanically affected by grant)
- State-level renewable energy deployment (appendix only — too far downstream)

## Data Sources

| Source | Content | Access |
|--------|---------|--------|
| PatentsView g_patent | Grant dates, patent IDs | S3 bulk download (confirmed) |
| PatentsView g_examiner | Examiner name, art unit per grant | S3 bulk download (confirmed) |
| PatentsView g_cpc_current | CPC classifications including Y02 | S3 bulk download (confirmed) |
| PatentsView g_us_patent_citation | Forward/backward citations | S3 bulk download (confirmed) |
| PatentsView g_application | Application filing dates | S3 bulk download (confirmed) |
| PatentsView g_inventor | Inventor name, location | S3 bulk download (confirmed) |
| USPTO PatEx | Full application universe incl. denials | USPTO bulk data (attempt) |
| EIA Electricity | State renewable generation | API (confirmed, DEMO_KEY) |

## Sample

- Y02-classified patent applications filed 2001-2018 (allowing 5-year follow-on window through 2023)
- ~150,000-250,000 Y02 applications
- ~2,000-3,000 examiners in green-technology art units
- Estimated first-stage F > 100 (Farre-Mensa et al. 2020)

## Planned Robustness Checks

1. **Balance test:** Application observables (filing year, claims, backward cites, applicant type) should not predict examiner leniency within art-unit × year
2. **Placebo outcomes:** Non-Y02 follow-on applications (should show no effect of Y02 grant)
3. **Heterogeneity by:** Technology class (solar, wind, transport, carbon capture), applicant type (individual, firm, university), time period
4. **Alternative instruments:** Prosecution time, claim narrowing ratio as additional examiner measures
5. **UJIVE vs. JIVE vs. 2SLS:** Compare estimators to assess many-instrument bias
6. **HonestDiD-style sensitivity:** Relaxation of exclusion restriction (direct effect of examiner on follow-on)
7. **Citation-window robustness:** 3, 5, 7, 10 year follow-on windows

## Method Notes: Examiner IV Design

**Key validity requirements:**
1. Random assignment within art unit (verified by balance tests on application observables)
2. Exclusion restriction: examiner affects outcomes only through grant decision
3. Monotonicity: more lenient examiner → weakly more likely to grant (testable)
4. Relevance: F > 10 (targeting F > 100 with UJIVE)

**Standard diagnostics:**
- First-stage F-statistic (Kleibergen-Paap)
- Balance test (regress application characteristics on instrument)
- Monotonicity test (non-crossing rates across examiner percentiles)

**R packages:** `fixest` for IV/2SLS, custom UJIVE implementation following Chyn et al. (2024), `data.table` for large-file processing.

**Key papers:**
- Sampat & Williams (2019, AER) — Gene patents, examiner IV
- Farre-Mensa, Hegde & Ljungqvist (2020) — Startup patent examiner IV
- Galasso & Schankerman (2015, AER) — Patent thickets and innovation
- Chyn, Frandsen & Leslie (2024) — UJIVE estimator for many-instrument settings
- Lemley & Sampat (2012) — Random examiner assignment documentation
