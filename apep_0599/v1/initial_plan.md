# Initial Research Plan: Denmark's 2013 Disability Pension Reform

## Research Question

Did Denmark's 2013 reform — which virtually barred disability pension awards for persons under 40 while expanding subsidized flex jobs — shift the disabled into genuine employment, or merely relabel them across welfare programs?

## Identification Strategy

**Triple-difference (DDD):** Age group (treatment intensity) × Municipality (baseline disability prevalence) × Time (pre/post January 1, 2013).

- **High intensity:** Ages 25–39 (virtually barred from disability pension)
- **Moderate intensity:** Ages 40–49 (resource scheme delay imposed)
- **Low intensity (control):** Ages 50–59 (largely unaffected)

The reform hit younger groups harder by design (statutory age threshold at 40). This age-graded treatment intensity is the core identifying variation. Municipalities with higher baseline disability prevalence were more exposed to the reform's bite, providing the second difference. The third difference is time (before vs. after 2013Q1).

## Expected Effects and Mechanisms

**First-order:** Disability pension receipt should decline sharply for ages 25–39 relative to 50–59 after 2013.

**Substitution channels (the key question):**
1. **Genuine employment:** If the reform successfully activated work capacity, we should see increases in employment and income for the treatment group.
2. **Flex job absorption:** Some of the decline in disability pension should map onto flex job increases (the intended policy channel).
3. **Welfare relabeling:** If work capacity didn't improve, we should see increases in cash benefits (kontanthjælp), sickness benefits, or resource scheme participation — merely shuffling people across program categories.
4. **Income effects:** If genuine employment, municipal-level average income for 30–39 year-olds should increase. If relabeling, income should be flat or decline.

**Hypothesis:** Based on international evidence (Norwegian reform studies suggest gatekeeping shifts to other benefits), we expect substantial substitution toward other welfare programs, with limited employment gains. But Denmark's simultaneous flex job expansion creates a unique "push-pull" design absent in other countries.

## Primary Specification

$$Y_{amt} = \alpha + \beta_1 (\text{Young}_a \times \text{Post}_t) + \beta_2 (\text{Young}_a \times \text{Post}_t \times \text{HighBase}_m) + \gamma_a + \delta_m + \lambda_t + \mu_{am} + \nu_{at} + \phi_{mt} + \varepsilon_{amt}$$

Where:
- $Y_{amt}$: Outcome (disability pension rate, flex job rate, employment rate, etc.) for age group $a$, municipality $m$, quarter $t$
- $\text{Young}_a$: Indicator for ages 25–39 (vs. 50–59)
- $\text{Post}_t$: Indicator for $t \geq$ 2013Q1
- $\text{HighBase}_m$: Above-median baseline disability prevalence (2007–2012 average)
- Full set of two-way fixed effects: age × municipality, age × time, municipality × time

The DDD coefficient $\beta_2$ identifies the differential reform effect in high-exposure municipalities for young vs. old, net of any age-specific national trends and municipality-specific time trends.

**Simpler DD specification (main):**
$$Y_{at} = \alpha + \beta (\text{Young}_a \times \text{Post}_t) + \gamma_a + \lambda_t + \varepsilon_{at}$$

National-level age-group DiD, exploiting only the age × time variation.

## Planned Robustness Checks

1. **Event study:** Quarterly dynamic treatment effects, 2007Q1–2024Q4, to verify parallel pre-trends
2. **Dose-response:** Compare high-intensity (25–39), moderate (40–49), and control (50–59) — effects should be monotonically ordered
3. **Leave-one-municipality-out:** Verify no single municipality drives results
4. **Placebo timing:** Move the reform date to 2010 or 2011 — should find no effect
5. **Sex heterogeneity:** Women have higher disability pension take-up; effects may be gendered
6. **Randomization inference:** Permute treatment assignment across age groups
7. **Alternative age bandwidths:** Narrow to 30–39 vs. 50–54 for tighter comparison

## Exposure Alignment

- **Who is actually treated?** Working-age individuals who would have applied for (and potentially received) disability pension absent the reform. The reform restricts access for those under 40.
- **Primary estimand population:** Ages 25–39 in municipalities with non-trivial disability pension caseloads
- **Placebo/control population:** Ages 50–59 (largely unaffected by the reform)
- **Design:** Triple-difference (age × municipality × time) with simpler DD (age × time) as the baseline

## Power Assessment

- **Pre-treatment periods:** 24 quarters (2007Q1–2012Q4)
- **Treated clusters:** ~98 municipalities × 3 age groups (25–29, 30–34, 35–39)
- **Post-treatment periods:** 48+ quarters (2013Q1–2024Q4)
- **Outcome variation:** Disability pension stock: 5,000–40,000 by age group; 33% decline in under-40 treatment group is a massive first-stage
- **Assessment:** Very well-powered. The 33% decline in disability pension stock for under-40s is enormous. Even with conservative clustering at the municipality level (98 clusters), power is not a concern.

## Data Sources

1. **AUK01:** Public benefits by municipality, benefit type, sex, age, quarter (2007Q1–2025Q3) — primary outcome data
2. **RAS301:** Employed persons by municipality, industry, socioeconomic status, age — employment outcome
3. **INDKP111:** Personal income by municipality, sex, age, income type (1992–2024) — income outcome
4. **AUK02:** Full-time equivalent public benefit recipients — robustness

All accessed via Statistics Denmark StatBank API (https://api.statbank.dk/v1/). No API key required.
