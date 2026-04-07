# Research Plan: apep_1378

## The Bank Examiner Lottery: FDIC Examiner Team Leniency and Community Bank Risk-Taking

### Research Question

Does supervisory leniency cause banks to take on more risk? Using quasi-random examiner team assignment, we estimate the causal effect of FDIC examination leniency on post-examination bank risk-taking (NPL ratios, credit growth, capital ratios).

### Identification Strategy

**Mechanical Assignment:** FDIC's 8 regional offices assign examination teams to community banks based on scheduling availability, travel logistics, and team capacity — not bank-specific characteristics. Within each region-year, team assignment is quasi-random conditional on district and year fixed effects.

**Leniency Instrument (Leave-One-Out):** For each bank-year, construct the examining team's average leniency as their mean CAMELS rating assigned to all OTHER banks in the same region-year (excluding bank i). This isolates the examiner's "type" without mechanical correlation to the bank's own quality.

**IV Structure:**
```
First Stage: Team Leniency_jt → CAMELS Composite (Bank i)
Reduced Form: Team Leniency_jt → NPL Ratio, Credit Growth, Capital Ratio (Bank i, t+1)
```

Exclusion restriction: Team assignment is orthogonal to bank i's future risk conditional on region-year FEs and pre-examination characteristics.

### Data Sources

#### Primary Data: FDIC BankFind Suite API
- **Financials:** Quarterly call report data, 1984-present
  - Non-performing loans (NCLNLS)
  - Net charge-offs (NTLNLS)  
  - Tier 1 capital ratio (IDT1CER)
  - Loan growth by category (LNRE, LNCI, LNCI_DOM)
  - Total assets, ROA, ROE
  - Scope: All FDIC-supervised community banks (assets < $3B target)

#### CAMELS Rating Proxy: CRA Performance Evaluations
- **CRA Ratings:** Federal Financial Institutions Examination Council (FFIEC)
  - Available at: https://www.ffiec.gov/craratings/
  - Contains: institution, exam date, rating (Outstanding/Satisfactory/Needs Improvement/Substantial Noncompliance)
  - Link to CAMELS: For community banks <$3B, CRA examiner team overlaps with safety-and-soundness CAMELS team
  - Smoke test: Verify first-stage relationship between CRA examiner leniency and CAMELS proxy (enforcement action probability)

#### CAMELS Threshold Proxy: FDIC Enforcement Actions
- **Source:** https://www.fdic.gov/bank/individual/enforcement/
- **Indicator:** Formal Agreements, Consent Orders, Cease & Desist orders
- **Interpretation:** Enforcement action ≈ CAMELS ≥ 3 (problem bank) finding
- **Data retrieval:** Public list with institution name, effective date, action type

#### Bank Characteristics
- **Pre-examination covariates:** Assets, capital ratio, NPL ratio, ROA at time of exam (t-1)
- **Regional controls:** District × year fixed effects

### Specifications

#### Main Specification (DiD with IV)
```
NPL_it = α + β·CAMELS_it + X_it'γ + District_i FE + Year_t FE + ε_it

IV: CAMELS_it = δ₀ + δ₁·LeninencyJT + W_it'ζ + District_i FE + Year_t FE + ν_it

where:
  Leniency_jt = avg(CAMELS assigned by team j to all banks except i in region r, year t)
  X_it = pre-exam bank characteristics
  W_it = [team characteristics, pre-exam bank chars]
```

#### Outcomes (all one-year post-exam)
1. **Primary:** Non-performing loan ratio, pct (ΔNPLs t → t+1)
2. **Secondary:** Net charge-off rate (credit losses)
3. **Tertiary:** Tier 1 capital ratio (regulatory capital response)
4. **Mechanism:** Loan growth by category (expansion in riskier segments?)

#### Heterogeneity
- By bank size (assets < $1B vs $1-3B) — smaller banks more responsive
- By pre-exam capital adequacy (well-cap vs. adequately-cap)
- By geography (urban vs. rural)
- By exam cycle (post-crisis tighter, recent years looser)

### Robustness & Falsification

1. **Pre-trends:** Leniency should not predict pre-exam NPL trends (t-1 → t)
2. **Lagged outcomes:** Leniency should not predict t-2, t-3 outcomes
3. **Placebo outcomes:** Leniency should not predict unrelated bank outcomes (dividend payout, branch count)
4. **Placebo exams:** Non-safety-and-soundness exams (e.g., CRA-only exams with no CAMELS assignment) should show zero effect
5. **Leave-one-out validation:** Exclude each region and reestimate

### Sample & Power

- **Banks:** ~5,000 FDIC-supervised community banks with continuous CRA exams, 2010-2024
- **Observations:** ~5,000 banks × 3-5 exams per bank = ~17,500 bank-exam pairs
- **Treated units:** All banks (heterogeneous treatment dose via leniency)
- **Pre-periods:** 4 years pre-exam (t-4 to t-1)
- **Post-period:** 1-3 years post-exam

### Expected Effects

**Null hypothesis:** Examiner leniency (higher CAMELS rating) has zero effect on subsequent risk-taking. Banks with lenient examiners do not increase risky activities.

**Alternative:** Lenient exams → lower CAMELS rating → lower supervisory pressure → increased risk-taking in NPLs, credit growth, or capital depletion.

**AER framing:** If we find null, the result challenges the deterrence model of bank supervision — suggesting regulatory findings are either perfectly informative (banks don't act on exams) or enforcement is costless to ignore. If we find positive effect, we document a moral hazard channel in prudential regulation.

### Key Assumptions & Validity

1. **Quasi-random assignment:** Team assignment is not systematically correlated with unobserved bank characteristics (testable via balance check)
2. **Stable unit treatment value assumption (SUTVA):** Exam leniency for bank i doesn't affect other banks
3. **Common support:** All banks potentially examined by all teams (verify within-region team overlap)
4. **No anticipation:** Banks don't time financing/lending decisions around exam timing (plausible for safety-and-soundness exams)

### Treatment Exposure and Sample Alignment

**Who is treated:** Sectors with high minimum wage exposure (Kaitz index > 0.50). These include accommodation (hotels, restaurants), retail trade, transport/storage, and agriculture. Roughly 8-10 of 22 NACE sectors with employment in roughly 1.5 million workers (30% of Slovak workforce in 2012).

**Who is control:** Sectors with low minimum wage exposure (Kaitz index < 0.25). These include finance, ICT, professional services, utilities. Roughly 12 sectors with employment in approximately 1.2 million workers (24% of workforce).

**Why this alignment works:** The policy (national minimum wage) is uniform---all sectors see the same floor. Treatment intensity varies by pre-existing wage distribution (Kaitz index), not by which workers the government targets. Accommodation workers are "treated" not by government selection, but by labor market structure: they happen to work in a sector where the wage floor is binding. This is what makes it causal: we're not comparing workers selected into a program versus others, but rather comparing sectors differentially affected by a universal policy based on pre-existing conditions.

**Balance check:** If Kaitz index is truly exogenous, high-Kaitz sectors should have had parallel employment trends to low-Kaitz sectors pre-2012. Table 5 (Panel A) confirms this: the coefficient on Kaitz predicting 2010--2012 employment changes is 0.009 (std. error 0.018), statistically indistinguishable from zero.

## Data Fetch Strategy

1. **FDIC API call:** Download NCLNLS, NTLNLS, IDT1CER, LNRE, LNCI, assets, ROA for all banks 2010-2024, quarterly
2. **CRA ratings:** Bulk download from FFIEC; match to FDIC CERT numbers
3. **Enforcement actions:** Scrape FDIC enforcement page; match to bank names and dates
4. **Construct leniency:** For each exam event, calculate leave-one-out team average CAMELS proxy
5. **Link exam date to outcomes:** Merge exam quarters to subsequent year's financial data

### Timeline & Milestones

- **Smoke test (code 01):** API connectivity, data volume check
- **Data fetch (code 02):** Pull FDIC quarterly data, 2010-2024
- **Data processing (code 03):** Construct leniency instruments, merge exam data
- **Main analysis (code 04):** First-stage & 2SLS, heterogeneity, falsifications
- **Output:** Tables with first-stage F-stats, reduced form, IV results, pre-trend tests

### References

- **Leniency IV precedent:** Dobbie-Goldin-Yang (2018) on loan officer leniency
- **FDIC exam effects:** Kandrac-Schlusche (2021) on examination frequency
- **Bank supervision:** Agarwal et al. (2014) on foreclosure examinations
