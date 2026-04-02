# Research Plan: The Enforcement Credibility Ratchet

## Research Question

Does supranational tax enforcement credibly alter multinational corporate tax payments? The European Commission's 2016 Apple state aid ruling (EUR 13B recovery order), the 2020 General Court annulment, and the 2024 CJEU reinstatement create a unique on-off-on enforcement credibility sequence that reveals whether enforcement signals permanently shift tax behavior or merely cause transient responses.

## Identification Strategy

**Primary: Synthetic Control Method (SCM)**

Ireland is the treated unit. Donor pool: all other EU member states (up to 26). Outcome: quarterly corporate tax revenue as share of GDP. The SCM constructs a weighted combination of control countries that best matches Ireland's pre-2016 tax trajectory. Post-2016 divergence between actual and synthetic Ireland estimates the effect of the enforcement shock.

Permutation inference (in-space placebos): apply the same SCM procedure to each donor country in turn, constructing "placebo" gaps. Ireland's gap must be extreme relative to the placebo distribution to be statistically significant.

**Secondary: Triple-Event Interrupted Time Series**

Structural break tests at each event date (2016-Q3, 2020-Q3, 2024-Q3) within the SCM gap series. The on-off-on pattern is the key test: if the gap widens after 2016, narrows after 2020, and widens again after 2024, this is consistent with enforcement credibility driving tax behavior.

**Mechanism: Within-Ireland Sector DiD**

If data permits, compare NACE J (Information & Communication — Apple's sector) to NACE C (Manufacturing) or other sectors. Differential response in Apple-exposed sectors strengthens the causal interpretation.

## Expected Effects

- **2016 ruling:** Increase in Irish corporate tax / GDP relative to synthetic Ireland (enforcement credibility shock)
- **2020 annulment:** Partial reversal or flattening (enforcement credibility reduced — but confounded by COVID)
- **2024 reinstatement:** Renewed increase (enforcement credibility restored)

The "ratchet" hypothesis: if multinational restructuring is costly to reverse, the 2016 shock may permanently elevate Irish corporate tax receipts even through the annulment period. A null on the 2020 event combined with positive effects for 2016 and 2024 would support the irreversibility interpretation.

## Primary Specification

SCM with:
- Outcome: Corporate tax revenue / GDP (quarterly)
- Treated: Ireland, from 2016-Q3
- Donors: EU member states with complete quarterly data
- Predictors: pre-2016 corporate tax/GDP levels, GDP growth, trade openness, FDI stock
- Inference: permutation-based p-value (ratio of MSPE post/pre)

## Data Sources

1. **Eurostat GOV_10Q_GGNFA:** Quarterly government revenue by category (taxes on income/wealth) for all EU states, 2000-present
2. **Eurostat NAMQ_10_GDP:** Quarterly GDP for normalization
3. **CSO Ireland GFQ01:** Quarterly government finance statistics with detailed tax categories (103 quarters)
4. **Eurostat NAMQ_10_A10:** Quarterly GDP by NACE sector (for sector DiD mechanism test)

## Exposure Alignment

The treatment-eligible population is the Irish exchequer: Ireland is the sole directly treated unit because Apple's state aid ruling required Ireland to recover EUR 13 billion. Other EU states are exposed only indirectly (through enforcement credibility signals). The affected population for fiscal outcomes is Ireland's general government sector. The income tax outcome (D51) captures taxes on all income — personal and corporate — so the exposure is broader than the Apple-specific mechanism. The sector DiD narrows exposure to NACE J (Information and Communications), which is Apple's primary sector.

## Key Risks

1. **N=1 problem:** Ireland is the only treated unit. SCM with permutation inference is the standard approach, but power is limited. Mitigation: long pre-period (64 quarters), multiple post-treatment events.
2. **COVID confound on 2020 event:** The annulment coincides with COVID. Mitigation: focus interpretation on 2016 and 2024 events; COVID affected all EU states similarly.
3. **Concurrent reforms:** Ireland raised its headline rate from 12.5% to 15% (2024); OECD Pillar Two. Mitigation: these affect all low-tax jurisdictions, captured by synthetic control.
4. **"Leprechaun economics":** Ireland's GDP is inflated by MNC activity. Mitigation: robustness check with alternative denominators.
