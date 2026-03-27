# Research Plan: The Lottery Channel — How Diversity Visa Eligibility Shapes Immigrant Selection

## Research Question

When countries lose Diversity Visa (DV) lottery eligibility by crossing the 50,000 family/employment-based immigration threshold, how does the skill composition of their immigrant flow to the United States change? Specifically, does removing lottery access — the primary pathway for immigrants without family or employer sponsors — shift the education and earnings distribution of new arrivals downward?

## Identification Strategy

**Difference-in-differences** exploiting staggered country-level DV eligibility changes.

- **Treatment:** Countries losing DV eligibility (e.g., Nigeria ~DV-2015, Bangladesh ~DV-2013) when their trailing 5-year family+employment admissions exceed 50,000.
- **Control:** Persistently eligible countries from similar regions (Ghana, Kenya, Ethiopia, Cameroon for the Africa comparison; Nepal, Sri Lanka for Asia).
- **Key assumption:** The 50,000 threshold is determined by non-DV immigration categories (family reunification, employment-based), which are plausibly exogenous to DV-specific selection patterns.
- **Estimand:** Change in education composition (% college-educated) and earnings of newly arriving immigrants from treated vs. control countries, before vs. after eligibility loss.

## Expected Effects and Mechanisms

The DV lottery has an education floor (high school diploma or 2 years qualifying work) but is otherwise random. When this channel closes:
1. **Positive selection weakens:** DV winners are drawn from a broad applicant pool; without it, remaining channels (family, employment) are more constrained. Family-sponsored immigrants have lower average education than DV lottery winners.
2. **Volume drops:** Total immigrant flow from the country falls as the lottery channel (~3,000-5,000/year for large countries) disappears.
3. **Earnings gap:** If DV immigrants had higher human capital than family-sponsored immigrants from the same origin, removing the lottery reduces average entry earnings.

**Named phenomenon:** "The Lottery Channel" — the DV lottery serves as a hidden positive selection mechanism for immigrants from eligible countries.

## Primary Specification

```
Y_{ct} = α + β × PostIneligible_{ct} + γ_c + δ_t + ε_{ct}
```

Where:
- Y_{ct}: share of newly arrived immigrants from country c in year t with college education (or mean log wages)
- PostIneligible_{ct}: indicator = 1 after country c loses DV eligibility
- γ_c: country fixed effects
- δ_t: year fixed effects
- Standard errors clustered at country level

**Callaway-Sant'Anna** for heterogeneous treatment timing across countries.

## Data Sources

1. **DHS Yearbook Table 10** (2000-2024): Country-by-class-of-admission LPR counts. Provides DV admissions, family-sponsored, and employment-based counts by country.
2. **ACS PUMS via Census API** (2005-2023): Individual-level data on foreign-born population with place of birth (POBP), year of entry (YOEP), education (SCHL), wages (WAGP), occupation (OCCP).
3. **State Department DV statistics**: Annual DV entrants by country, eligibility lists by fiscal year.

## Fetch Strategy

1. Download DHS Yearbook Table 10 PDFs/Excel files for FY2000-FY2024 from DHS.gov
2. Query Census ACS PUMS API for foreign-born respondents (NATIVITY=2) with POBP codes for treated and control countries, years 2005-2023
3. Compile State Department DV eligibility lists to identify exact eligibility switch years

## Robustness

- Event study plots (leads/lags around eligibility loss)
- Placebo: countries that remained eligible throughout
- Alternative controls: region-matched vs. income-matched donor pools
- Dose-response: countries with larger DV shares pre-treatment should show larger effects
- Permutation inference (given small number of treated countries)

## Exposure Alignment

The treatment (loss of DV eligibility) operates at the country-of-origin level and affects all nationals of that country who might apply for the DV lottery. The outcome is measured at the country-year level using ACS data on immigrants from that origin country residing in the U.S. The treatment and outcome align at the country level: when Nigeria loses eligibility, the composition of Nigerian immigrants in ACS changes. The key margin is the flow of new arrivals — recent entrants (within 5 years per YOEP) are more directly affected than the existing stock, which dilutes the signal. We present both stock and flow results.

## Key Risks

- Small number of treated countries (8-12) → use randomization inference
- ACS sample sizes for individual origin countries may be thin → aggregate to treatment/control groups
- Compositional changes in non-DV categories could confound (unlikely to coincide with threshold crossing)
