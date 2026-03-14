# Research Plan: Office-to-Residential Permitted Development and the Composition of Local Housing Supply in England

## Research Question

Does planning deregulation increase housing supply at the cost of housing quality and composition? We exploit England's 2013 Class J permitted development (PD) rights—which allowed office-to-residential conversion without planning permission—as a large-scale natural experiment.

## Identification Strategy

**Bartik-style continuous-treatment DiD.** Treatment intensity is the pre-existing share of commercial/office floorspace in each Local Authority (LA) as of 2012, before the policy was announced. LAs with more office stock received proportionally more conversion opportunities.

**Primary specification:**

Y_{it} = α_i + δ_t + β(OfficeShare_i × Post_t) + ε_{it}

- Y_{it}: housing supply outcomes (net additions per 1000 pop, composition, prices)
- OfficeShare_i: 2012 office floorspace share by LA (from VOA)
- Post_t: 1 if year ≥ 2013-14
- α_i: LA fixed effects; δ_t: year fixed effects

**Event study:**

Y_{it} = α_i + δ_t + Σ_k β_k(OfficeShare_i × 1{t = k}) + ε_{it}

Pre-trends (2006-2012) validate parallel trends assumption.

**Article 4 triple-difference:** Some London boroughs removed PD rights via Article 4 directions. These "PD-exempt" LAs serve as a placebo:

Y_{it} = α_i + δ_t + β₁(OfficeShare_i × Post_t) + β₂(OfficeShare_i × Post_t × Article4_i) + ε_{it}

β₂ should be negative and close to -β₁ (exempted LAs don't get the PD effect).

## Expected Effects and Mechanisms

1. **Quantity:** High-office-stock LAs should see a larger increase in net housing additions post-2013
2. **Composition:** PD conversions are predominantly flats → higher flat share in new supply
3. **Prices:** Flat prices may decline relative to house prices in high-PD areas (supply effect)
4. **Quality channel:** PD conversions bypass planning quality standards → smaller units, no Section 106 contributions

## Primary Specification

Outcome variables:
- Log net additional dwellings per 1000 population (Table 123)
- PD office-to-residential units as share of total additions (Table 123, from 2015-16)
- Log median flat price (Land Registry or UK HPI)
- Log median house price (Land Registry or UK HPI)

Treatment: VOA office floorspace share (2012), continuous
Post: 2013-14 onward (Class J introduction May 2013)
Unit: Local Authority × year
Pre-period: 2006-07 to 2012-13

## Data Sources

1. **MHCLG Live Table 123** — Net additional dwellings by component and district, 2006-2024. ODS format from GOV.UK. Contains "PD office-to-residential" column from 2015-16.

2. **VOA Non-domestic rating floorspace statistics** — Table RS3, commercial/office floorspace by LA. Pre-treatment measure from 2012.

3. **ONS UK House Price Index** — Median prices by property type (detached, semi, terraced, flat) by LA, monthly from 1995. Via ONS API or data.gov.uk.

4. **ONS mid-year population estimates** — For per-capita normalization.

5. **postcodes.io** — For matching Article 4 boroughs to LA codes if needed.

## Key Risks

- **Bartik exposure may correlate with economic structure:** Office-heavy LAs differ from residential LAs in many ways. The event study pre-trends are critical.
- **Article 4 endogeneity:** London boroughs that opted out may differ systematically. The triple-diff is supportive, not definitive.
- **Table 123 PD column starts 2015-16:** Can only directly observe PD conversions 3 years post-policy. The Bartik design captures the total effect through the office-stock exposure.
