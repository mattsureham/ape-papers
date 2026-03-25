# Research Plan: The Regulatory Ratchet — EO 13771 and Federal Rulemaking

## Research Question
Did EO 13771's "two-for-one" regulatory budget (January 30, 2017) differentially slow protective rulemaking at high-regulatory-intensity agencies, and did Biden's rescission (January 20, 2021) reverse the slowdown symmetrically?

## Identification Strategy
**Design:** Difference-in-differences with continuous treatment intensity.

- **Unit of analysis:** Rulemaking docket (61,501 dockets from Regulations.gov)
- **Treatment intensity:** Agency's pre-2017 share of "Economically Significant" dockets (from priorityCategory field). Agencies with high shares (EPA, OSHA, NHTSA, PHMSA) faced a harder offset constraint under EO 13771 than routine-rulemaking agencies (USCG, FAA).
- **Event dates:** EO 13771 = Jan 30, 2017; Biden EO 13992 rescission = Jan 20, 2021
- **Pre-period:** 2010–2016 (7 years, 14 semesters)
- **Treatment period:** 2017–2020 (4 years)
- **Reversal period:** 2021–2024 (4 years)

**Specification:**
Y_at = α_a + δ_t + β₁(Post2017_t × HighIntensity_a) + β₂(Post2021_t × HighIntensity_a) + ε_at

β₁: Differential effect on high-intensity agencies during EO 13771
β₂: Reversal effect after Biden rescission (ratchet test: β₁ + β₂ ≠ 0 → asymmetric)

## Expected Effects and Mechanisms
1. **Slowdown:** EO 13771 should lengthen NPRM-to-Final-Rule duration at high-intensity agencies (finding two rules to repeal takes time)
2. **Composition shift:** More "Deregulatory" dockets at high-intensity agencies
3. **Ratchet:** Biden rescission may not fully reverse — bureaucratic capacity lost, precedents set, political capital spent on new priorities rather than restarting stalled rules
4. **Mechanism:** The two-for-one offset creates a shadow price on new regulation — agencies respond by (a) slowing existing NPRMs, (b) withdrawing rules, (c) relabeling deregulatory actions

## Primary Specification
- Outcome 1: NPRM-to-Final Rule duration (days)
- Outcome 2: Rule completion probability (binary: NPRM → Final Rule within 4 years)
- Outcome 3: Withdrawal indicator
- SEs clustered at agency level

## Robustness
- Event study with semester-level agency-intensity interactions
- Placebo: use January 20 inauguration date vs. January 30 EO date
- Leave-one-out: exclude EPA (largest agency by far)
- Binary treatment: top-quartile vs bottom-quartile intensity
- Callaway-Sant'Anna not needed (single national treatment date)

## Data Source and Fetch Strategy
1. **Regulations.gov API v4** — fetch all rulemaking dockets + documents
   - Endpoint: `https://api.regulations.gov/v4/dockets` and `https://api.regulations.gov/v4/documents`
   - Fields: docketId, agencyId, postedDate, documentType, priorityCategory, eo13771Designation, withdrawn
   - Pagination: 250 items/page, up to 61,501 dockets and ~150K documents
   - Rate limit: 1,000 requests/hour with API key; no key = 250/hour
   - Strategy: fetch docket-level aggregates first; then documents for NPRM-Final matching

2. **Check for API key:** REGS_GOV key confirmed in .env

3. **Fallback:** If API is too slow, check if bulk downloads exist (regulations.gov/bulkdownload)
