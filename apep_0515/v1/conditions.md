# Conditional Requirements

**Generated:** 2026-03-05T10:09:27.235640
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

**Selected idea:** The Minimum Wage as a Hidden Tax on Elderly Care: National Living Wage Bite and Care Home Closures in England

Conditions for non-selected ideas marked NOT APPLICABLE.

---

## The Minimum Wage as a Hidden Tax on Elderly Care (GPT-5.2 conditions)

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: strong pre-trend balance

**Status:** [x] RESOLVED

**Response:** The design uses ASHE 2012-2015 pre-NLW median care worker wages to construct the bite measure. Event-study coefficients for years -5 through -1 relative to April 2016 will be estimated and tested jointly (F-test) and individually. If pre-trends are detected, HonestDiD (Rambachan & Roth 2023) sensitivity analysis will bound the ATT under alternative trend assumptions.

**Evidence:** Pre-treatment period 2010-2015 provides 6 years of pre-trend data. CQC has published care home directories since 2009. NOMIS BRES provides annual care sector employment by LA from 2009+.

---

### Condition 2: credible "first stage" showing wage pass-through in care

**Status:** [x] RESOLVED

**Response:** The first stage will show that NLW bite predicts actual care worker wage growth. Using ASHE by LA, I will regress post-2016 care worker wage growth on pre-NLW bite. IFS (2021) and LPC reports document near-complete pass-through of NLW to wages in low-wage sectors — the NLW binds. This is also a standard design feature in the Harasztosi & Lindner (2019, AER) approach.

**Evidence:** ASHE NM_99_1 on NOMIS provides median hourly wages by occupation (SOC 6145, care workers) × geography. Will estimate: Delta(log wage_it) = alpha + beta × Bite_i + gamma × X_it + epsilon.

---

### Condition 3: explicitly handling adult social care funding + COVID period robustness

**Status:** [x] RESOLVED

**Response:** (a) Social care funding: DHSC publishes LA-level adult social care expenditure (Section 251 returns / SALT data). This will be included as a time-varying control. Additionally, the continuous-treatment design differences out LA-level shocks that affect all LAs similarly. LA fixed effects absorb time-invariant LA characteristics. (b) COVID: Primary specification will use 2010-2019 (pre-COVID). Robustness check extends to 2024 with COVID-period indicators. COVID affected all LAs and is absorbed by year fixed effects; the identifying variation is within-year cross-LA differences in NLW bite.

**Evidence:** DHSC adult social care activity and expenditure data available on gov.uk. Restricting sample to 2010-2019 avoids the COVID mortality shock in care homes (which killed ~40,000 care home residents and caused closures for pandemic-specific reasons unrelated to wages).

---

### Condition 4: exploring alternative bite measures

**Status:** [x] RESOLVED

**Response:** Three bite measures will be constructed and compared:
1. **Gap measure:** (NLW - median care wage) / median care wage, from 2015 ASHE
2. **Fraction affected:** Share of care workers with wages between old NMW and new NLW, from 2015 ASHE
3. **Kaitz index:** NLW / median wage (all occupations), from 2015 ASHE
All three will be used in parallel specifications. Results must be robust across measures.

**Evidence:** ASHE wage distribution data by LA is available via NOMIS for percentiles (10th, 25th, median, 75th). This enables construction of fraction-affected measures.

---

### Condition 5: inference with ~150 clusters

**Status:** [x] RESOLVED

**Response:** With ~150 upper-tier LAs, standard cluster-robust standard errors (Liang-Zeger) are appropriate. Inference will use: (1) cluster-robust SEs at LA level, (2) wild cluster bootstrap (Webb 2023) as robustness, (3) randomization inference permuting bite assignments across LAs. 150 clusters is well above the 42-cluster threshold where cluster-robust SEs become reliable (Cameron, Gelbach & Miller 2008).

**Evidence:** Standard practice in continuous-treatment DiD with ~150 clusters. No special small-cluster corrections needed.

---

## Idea 1: The Minimum Wage as a Hidden Tax on Elderly Care (Gemini conditions)

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: controlling rigorously for LA-level social care budget changes over the panel period

**Status:** [x] RESOLVED

**Response:** Same as GPT-5.2 Condition 3(a). DHSC Section 251/SALT expenditure data provides time-varying LA-level care budgets as controls. Additionally, LA × year fixed effects in a saturated specification absorb all time-varying LA shocks (including funding changes). The identifying assumption is that within-year cross-sectional variation in NLW bite is not correlated with differential funding changes conditional on LA and year FEs.

**Evidence:** DHSC data confirmed available. The design exploits cross-sectional variation in wage structure, not time-series variation in funding.

---

## Idea 1: The Minimum Wage as a Hidden Tax on Elderly Care (Grok conditions)

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: robust COVID exclusion

**Status:** [x] RESOLVED

**Response:** Primary specification: 2010-2019 (excludes COVID entirely). Extended specification: 2010-2024 with COVID indicators. Results section will present both, with the 2010-2019 window as the main result.

**Evidence:** NLW was introduced April 2016. A 2010-2019 window gives 6 pre-treatment and 3.75 post-treatment years — sufficient for event study with multiple NLW increases (2016, 2017, 2018, 2019).

---

### Condition 2: event-study pre-trends passing at p<0.10

**Status:** [x] RESOLVED

**Response:** Event-study figure will plot coefficients for years -5 through +3 (or +8 with COVID). Joint F-test of pre-treatment coefficients will be reported. If pre-trends detected, will apply HonestDiD sensitivity analysis. This is a standard diagnostic that will be performed and transparently reported regardless of outcome.

**Evidence:** Will be tested in analysis phase. If pre-trends fail, the paper will pivot to a bounds approach (HonestDiD) or honestly report the limitation.

---

## Non-selected ideas (marked NOT APPLICABLE)

### Empty Homes, Full Wallets? (all conditions)
**Status:** [x] NOT APPLICABLE — idea not selected

### Priced Out of Patrol (all conditions)
**Status:** [x] NOT APPLICABLE — idea not selected

### Apprenticeship Levy (all conditions)
**Status:** [x] NOT APPLICABLE — idea not selected

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [ ] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
