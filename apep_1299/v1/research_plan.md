# Research Plan: The Deportation Dividend

## Research Question

Does US immigration enforcement causally affect origin-country remittance inflows? When immigration judges grant asylum to nationals of country *c*, do those individuals' earnings generate measurable remittance flows back to *c*? Conversely, when judges deport, do origin countries lose a remittance lifeline?

## Identification Strategy

**Immigration Judge Leniency IV** (Kling 2006; Dobbie & Song 2015).

US immigration courts (EOIR) quasi-randomly assign cases to judges within each court. Judges exhibit enormous leniency variation: within the same courthouse, grant rates range from ~2% to ~97% (TRAC 2024; GAO 2008, 2017). This assignment is conditionally random — judge identity is determined by court scheduling, not by the characteristics of the respondent or their origin country's economic conditions.

**Construction:**
1. For each judge *j*, compute leave-nationality-out grant rate: the judge's grant rate across all cases *except* those involving nationality *c*.
2. For each origin country *c* in year *t*, compute the average leave-nationality-out leniency of judges hearing cases involving nationals of *c*.
3. This instruments for the nationality-specific grant rate (or removal rate) from US immigration courts.

**Exclusion restriction:** Conditional on court-by-year effects absorbed into the aggregation, a judge's personal leniency toward (say) Guatemalan cases is determined by their general dispositional tendencies, not by Guatemala's economic trajectory.

**First stage:** Within-court grant rate disparity of ~56 percentage points (median across courts) implies a very strong first stage, even after aggregation to nationality-year level.

## Expected Effects and Mechanisms

**Primary hypothesis:** Higher asylum grant rates for nationality *c* → higher remittance inflows to country *c*. Granted asylees gain work authorization, enter formal employment, and can remit through legal channels.

**Magnitude prior:** If marginal asylees earn ~$25K/year and remit ~10-15% (consistent with Mexican immigrant literature), each 1,000 additional grants should generate ~$2.5-3.75M in additional annual remittances. With ~50K-100K cases per major origin country annually, plausible first-stage shifts of 5-10pp in grant rates could move aggregate remittances measurably.

**Mechanisms:**
1. *Labor market channel:* Granted asylees work legally → higher earnings → higher remittances
2. *Formal channel access:* Legal status enables bank-based remittance (lower fees, higher volumes)
3. *Duration channel:* Grants allow long-term US residence; deportees' remittance capacity ends

## Primary Specification

**Two-stage least squares (2SLS):**

**First stage:**
GrantRate_{ct} = α_c + γ_t + δ × Leniency_{ct} + X_{ct}β + ε_{ct}

**Second stage:**
log(Remittances_{ct}) = α_c + γ_t + β × GrantRate_{ct} + X_{ct}δ + ε_{ct}

where:
- *c* = origin country, *t* = year
- Leniency_{ct} = average leave-nationality-out judge leniency for country *c* cases in year *t*
- GrantRate_{ct} = share of cases involving nationality *c* granted relief in year *t*
- Remittances_{ct} = World Bank bilateral remittance inflows to country *c* from US in year *t*
- X_{ct} = origin-country GDP growth, natural disasters, conflict intensity, total cases filed

**Clustering:** Origin country (20-50 clusters). Report wild cluster bootstrap given moderate cluster count.

**Sample:** ~20-30 major origin countries × 15 years (2006-2020) = 300-450 country-year observations.

## Data Sources

1. **EOIR Case Data** (DOJ FOIA Library): Case-level records with judge ID, nationality, decision, hearing location. 4.26 GB ZIP, monthly updates. URL: `https://fileshare.eoir.justice.gov/EOIR%20Case%20Data.zip`

2. **World Bank Bilateral Remittance Matrix** (KNOMAD): US-to-country bilateral remittance flows, annual. URL: `https://www.knomad.org/data/remittances`

3. **World Bank WDI API**: Country-level remittance inflows (BX.TRF.PWKR.CD.DT), GDP growth, school enrollment. URL: `https://api.worldbank.org/v2/`

4. **EM-DAT** or GDELT: Natural disaster and conflict controls.

## Robustness and Placebos

1. **Pre-adjudication placebo:** Judge leniency in year *t* should not predict remittances in year *t-2*
2. **Industry placebos:** Leniency should not predict origin-country FDI inflows (different channel)
3. **Leave-one-country-out:** Sequentially exclude each major origin country
4. **Alternative clustering:** Two-way (country + year), Conley spatial HAC
5. **Reduced-form:** Direct regression of remittances on judge leniency (bypassing 2SLS)
6. **Medicaid expansion heterogeneity:** Grants in expansion states → better health → higher earnings → more remittances?

## Key Risks

1. **Small cluster count:** 20-50 origin countries. Mitigate with wild cluster bootstrap.
2. **EOIR data processing:** 4.26 GB requires efficient parsing. Use data.table in R.
3. **Bilateral remittance data gaps:** World Bank bilateral matrix has missing values. May need to use aggregate inflows as fallback.
4. **Measurement:** Informal remittances (hawala, cash) are unmeasured. IV identifies effects on formal remittances only — state this as a limitation (and a conservative bias).
