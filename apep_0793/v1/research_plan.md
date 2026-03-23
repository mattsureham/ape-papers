# Research Plan: The Innovation Supply Chain

## Research Question
Does the massive expansion of U.S. STEM (CS/Engineering) degree completions (2009–2022) affect local technology sector employment, firm dynamics, and the within-sector skill premium? We test whether universities function as "innovation supply chains" — whether locally trained STEM graduates create local tech ecosystems or depart for superstar cities.

## Identification Strategy
**Bartik shift-share IV.**
- **Share:** County c's CS+Engineering completions in base year 2009 as a fraction of the national total
- **Shift:** National CS+Engineering completion growth rate (doubled from ~152K to ~332K, 2009–2022)
- **Instrument:** Z_ct = Share_c × Shift_t
- **Estimand:** The average causal response of local tech sector outcomes to an exogenous increase in local STEM labor supply, identified off the Bartik variation

**Exclusion restriction:** Baseline STEM capacity affects local tech employment only through labor supply, not through university R&D spending or amenity effects. We probe this via:
1. Falsification on non-STEM sectors (NAICS 72 Accommodation/Food)
2. Controlling for total university enrollment and R&D expenditures
3. Testing balance on pre-period county characteristics

## Expected Effects and Mechanisms
- **Information sector employment:** Positive — more STEM graduates → more tech workers available locally
- **Firm job gains (entry):** Positive if graduates start firms or attract new establishments
- **Firm job losses (exit):** Ambiguous — competition could increase exits, or agglomeration could reduce them
- **Earnings:** Negative pressure from labor supply increase (demand-supply), offset by agglomeration/productivity gains
- **Skill premium (BA+ share):** Could decrease in high-STEM counties if new graduates compress the premium

## Primary Specification
**Second-stage:**
Y_ct = α + β × (STEM_ct) + X_ct'γ + δ_c + δ_t + ε_ct

**First-stage:**
STEM_ct = π₀ + π₁ × Z_ct + X_ct'π₂ + δ_c + δ_t + ν_ct

Where:
- Y_ct: Information sector outcomes (employment, firm job gains/losses, earnings, BA+ share)
- STEM_ct: County c's CS+Engineering completions in year t
- Z_ct: Bartik instrument (2009 share × national growth)
- X_ct: County-level controls (population, total university enrollment)
- δ_c, δ_t: County and year fixed effects
- Clustering: State level (51 clusters)

## Data Sources
1. **IPEDS:** `az://raw/ipeds/ipeds.duckdb` — CS+Engineering completions by institution, mapped to county FIPS
2. **QWI (sex×age):** `az://derived/qwi/sa/ns/*.parquet` — Employment, hires, separations, firm job gains/losses, earnings by county × NAICS sector × quarter
3. **QWI (sex×education):** `az://derived/qwi/se/ns/*.parquet` — Education-level employment for within-sector skill premium

## Analysis Steps
1. Extract IPEDS CS+Engineering completions by county-year
2. Construct Bartik instrument using 2009 base shares
3. Extract QWI Information sector (NAICS 51) outcomes, annualized from quarterly
4. Merge IPEDS and QWI at county-year level
5. Estimate OLS and 2SLS with county + year FEs
6. First-stage diagnostics (F-stat, partial R², visualization)
7. Falsification: Non-STEM sector (NAICS 72) as placebo
8. Decomposition: Firm entry vs expansion (FrmJbGn/FrmJbLs)
9. Skill premium analysis using education-disaggregated QWI
