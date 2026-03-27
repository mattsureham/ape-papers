# Research Plan: Conversion Therapy Bans and Adolescent Mental Health

## Research Question

Do state laws banning conversion therapy for minors reduce adolescent mental health distress? Specifically, does the staggered adoption of SOGIECE (Sexual Orientation and Gender Identity Change Efforts) bans across 24 U.S. states improve mental health outcomes for LGBTQ+ youth relative to heterosexual peers?

## Identification Strategy

**Primary design:** Staggered difference-in-differences using Callaway & Sant'Anna (2021), exploiting the variation in timing of conversion therapy ban adoption across states (2012–2023).

**Triple-difference extension:** LGB-identified youth vs. heterosexual youth × treated vs. control states × pre vs. post. The ban should primarily benefit LGB youth; heterosexual students serve as a within-state placebo group, absorbing state-level confounders (e.g., political shifts, other LGBTQ+ legislation).

**Treatment variable:** Binary indicator equal to 1 if the state had enacted a conversion therapy ban effective before the YRBSS survey year.

**Comparison group:** States that never enacted conversion therapy bans during the sample period (not-yet-treated also used in CS estimator).

## Expected Effects and Mechanisms

**Primary hypothesis:** Conversion therapy bans reduce mental health distress among LGB youth through:
1. **Direct protection:** Fewer minors subjected to harmful therapeutic practices
2. **Signaling/destigmatization:** Legislative recognition that conversion therapy is harmful may reduce ambient stigma
3. **Professional norm-setting:** Licensed practitioners shift away from harmful practices

**Expected direction:** Negative effects on suicide attempts, persistent sadness, and substance use (i.e., bans improve outcomes). Effects should be concentrated among LGB-identified youth.

**Possible null:** If conversion therapy prevalence is already low, bans may have no population-level detectable effect (a "thin pipeline" null — informative because it bounds the reach of legislative protection).

## Primary Specification

$$Y_{ist} = \alpha_s + \gamma_t + \beta \cdot Ban_{st} + X_{ist}'\delta + \varepsilon_{ist}$$

Where:
- $Y_{ist}$: Mental health outcome for student $i$ in state $s$, survey year $t$
- $Ban_{st}$: 1 if state $s$ has an effective conversion therapy ban in year $t$
- $\alpha_s, \gamma_t$: State and year fixed effects
- $X_{ist}$: Individual controls (age, sex, race/ethnicity)

**DDD specification:**
$$Y_{ist} = \alpha_{sg} + \gamma_{tg} + \lambda_{st} + \beta_{DDD} \cdot Ban_{st} \times LGB_i + \varepsilon_{ist}$$

Where $g$ indexes sexual orientation group, absorbing state × group and year × group variation.

**Inference:** Cluster at state level. Wild cluster bootstrap for robustness given ~50 state clusters. Randomization inference as additional check.

## Outcomes (from YRBSS)

1. **Suicide attempt** (past 12 months) — primary
2. **Persistent sadness/hopelessness** (≥2 weeks) — primary
3. **Seriously considered suicide** — secondary
4. **Made a suicide plan** — secondary
5. **Current substance use** (alcohol, marijuana) — mechanism/secondary

## Data Source and Fetch Strategy

1. **YRBSS SADC (State-level):** CDC public microdata files for 2015, 2017, 2019, 2021, 2023. ASCII/SAS transport files with state identifiers. ~100,000+ students per wave. Download from CDC website.

2. **Treatment timing:** Hand-coded from Movement Advancement Project (MAP) and LawAtlas data. 24 states + DC with effective dates.

3. **State controls:** Political composition (governor party, state legislature), other LGBTQ+ protections (anti-discrimination laws, same-sex marriage timing), Medicaid expansion status.

## Design Parameters

- **Treated units:** 24 states + DC
- **Survey waves:** 5 biennial waves (2015–2023)
- **Pre-periods:** Varies by state adoption (CA: 1–2 pre-periods; late adopters: 4–5)
- **Sample:** ~500,000+ pooled observations across all waves
- **Key subgroup:** LGB-identified youth (~10–15% of sample in recent waves)

## Key Risks

1. **Limited pre-treatment waves:** YRBSS with sexual identity questions starts ~2015; early adopters (CA 2012, NJ 2013) have ≤1 pre-period. May need to drop earliest adopters or use balanced panel of later adopters.
2. **State YRBSS participation varies:** Not all states participate in all waves. Need to verify state coverage across waves.
3. **Concurrent LGBTQ+ policies:** Same-sex marriage (Obergefell 2015), state anti-discrimination laws may confound. DDD mitigates this (these affect all youth, not just LGB youth differentially).
