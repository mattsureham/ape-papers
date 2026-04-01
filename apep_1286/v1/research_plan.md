# Research Plan: The Eligibility Trap

## Research Question

Does tightening patent eligibility standards disproportionately push small entities out of the patent system? I exploit the June 2014 *Alice Corp v. CLS Bank* Supreme Court decision, which massively increased §101 (abstract idea) rejections for software/business-method art units while leaving other technology classes largely unaffected.

## Identification Strategy

**Continuous-treatment DiD within Technology Center 36.** Treatment intensity = art unit's change in §101 rejection share from pre-Alice (2012Q1–2014Q2) to post-Alice (2014Q3–2016Q4). The 71 art units in TC 36 experienced heterogeneous Alice exposure: 24 "high-shock" units saw >20pp increases in §101 rejections (financial data processing, e-commerce), while 41 "low-shock" units saw <5pp changes (database structures, static data presentation).

Key identifying assumption: absent Alice, high-shock and low-shock art units within TC 36 would have followed parallel abandonment trends. Testable with 10 pre-treatment quarters.

## Expected Effects and Mechanisms

1. **Main effect:** Higher §101 rejection intensity → higher application abandonment rates
2. **Distributional effect:** Small entities (independent inventors, small firms, universities) are more sensitive to rejection costs than large entities (corporate patent portfolios with dedicated prosecution teams)
3. **Mechanism:** Small entities face higher per-application opportunity costs of responding to §101 rejections (which require doctrinal arguments about abstractness, not just prior-art amendments)

## Primary Specification

$$Y_{a,t} = \alpha_a + \gamma_t + \beta \cdot (AliceShock_a \times Post_t) + \varepsilon_{a,t}$$

Where:
- $Y_{a,t}$ = abandonment rate in art unit $a$, quarter $t$
- $AliceShock_a$ = continuous measure of art unit's §101 rejection intensity increase
- $Post_t$ = indicator for quarters after June 2014
- Art unit and quarter fixed effects absorb level differences and common trends

Heterogeneous effects by entity type (small vs large) via triple-difference or split samples.

## Robustness

1. Cross-TC placebo: TC 17 (chemistry) experienced no Alice shock
2. §103 (obviousness) rejection placebo: should not spike differentially at Alice
3. Event study with quarterly leads/lags
4. Examiner-level Alice compliance as instrument for art-unit shock

## Data Source and Fetch Strategy

**BigQuery (confirmed accessible, free tier):**
- `patents-public-data.uspto_oce_pair.application_data` — 9.8M applications: disposal_type, small_entity_indicator, examiner_id, uspc_class, filing_date
- `patents-public-data.uspto_oce_office_actions.office_actions` — 4.4M office actions with rejection basis codes (§101, §102, §103)

**Construction:**
1. Query office actions for all TC 36 applications (2012–2016), flag §101 rejections
2. Compute art-unit × quarter §101 rejection share
3. Query application-level outcomes (abandoned, issued, pending) by entity type
4. Collapse to art-unit × quarter × entity-type panel

**Sample:** ~83,000 resolved applications in TC 36, 2012–2016.
