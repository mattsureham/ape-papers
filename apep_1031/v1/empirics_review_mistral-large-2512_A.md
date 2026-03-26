# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-03-27T00:26:58.239822

---

### 1. **Idea Fidelity**
The paper closely adheres to the original idea manifest. It:
- **Preserves the core research question**: Whether food freedom/cottage food law expansions affect formal food-sector labor markets (NAICS 311 and 722).
- **Uses the specified data and identification strategy**: QWI data with a staggered DiD design, including the proposed triple-diff placebo test (non-food manufacturing).
- **Incorporates key elements**: Heterogeneity by sex, firm entry rates, and earnings—though the manifest’s proposed "female employment shares" analysis is simplified to sex-specific employment effects.
- **Misses minor details**: The manifest mentions 34+ treated states, but the paper uses 23 (7 food freedom + 16 cottage food expansions). The manifest’s "demographic splits (race)" are omitted without explanation.

**Verdict**: The paper faithfully executes the manifest’s vision, with only minor deviations (e.g., fewer treated states, no race heterogeneity).

---

### 2. **Summary**
This paper exploits staggered adoption of food freedom/cottage food laws in 23 U.S. states to test whether deregulating home food production crowds out or complements formal food-sector labor markets. Using QWI data and a two-way fixed effects design, it finds **null effects** on employment, firm entry, and earnings in food manufacturing (NAICS 311) and food services (NAICS 722). The results suggest home and commercial kitchens operate in separate markets, with no detectable displacement or formalization ladder. Robustness checks (Sun–Abraham, wild bootstrap, COVID-era exclusions) confirm the null.

---

### 3. **Essential Points**
The paper is methodologically sound but requires **three critical fixes** to ensure credibility:

#### **1. Clarify the Treatment Definition and Heterogeneity**
- **Issue**: The paper lumps together **food freedom acts** (radical deregulation, e.g., Wyoming) and **cottage food expansions** (incremental, e.g., California). These may have **different effects**—food freedom acts could crowd out formal producers (e.g., perishable goods like dairy), while cottage food expansions might not. The manifest explicitly highlights this distinction ("Wyoming Food Freedom Act: virtually any food, no permit/inspection/limit").
- **Fix**:
  - **Primary specification**: Report results separately for (a) food freedom acts (7 states) and (b) cottage food expansions (16 states). The current "food freedom only" robustness check (Table 4) is insufficient.
  - **Mechanism**: Test whether effects vary by **perishability** (e.g., NAICS 3115 "Dairy" vs. 3118 "Bakeries"). If food freedom acts matter, they should disproportionately affect perishable goods.

#### **2. Strengthen Parallel Trends Evidence**
- **Issue**: The paper lacks a **formal pre-trends test** (e.g., event-study coefficients for leads/lags). While the placebo test (NAICS 31–33) is reassuring, it doesn’t rule out differential trends in food sectors.
- **Fix**:
  - **Add an event-study plot** (e.g., Figure 1) showing coefficients for 8+ pre-treatment quarters and 12+ post-treatment quarters. This is standard in staggered DiD papers (e.g., [Callaway & Sant’Anna 2021](https://www.sciencedirect.com/science/article/pii/S0304407620303948)).
  - **Report joint significance tests** for pre-trends (e.g., F-test that all pre-treatment coefficients = 0).

#### **3. Address Potential Confounding from COVID-19**
- **Issue**: 5 of 23 treated states adopted laws in **2021–2022**, when COVID-19 disrupted food-sector labor markets (e.g., restaurant closures, supply chain shocks). The "pre-COVID cohorts only" robustness check (Table 4) is a good start but doesn’t fully isolate the confound.
- **Fix**:
  - **Exclude 2020–2022 entirely** from the main specification (not just post-2019 cohorts). If results hold, confidence in the null increases.
  - **Interact treatment with COVID-era indicators** to test whether effects differ during the pandemic.

---

### 4. **Suggestions**
#### **A. Improve Conceptual Framework**
1. **Theory of Change**:
   - The paper posits three mechanisms (separate markets, small scale, long lags) but doesn’t **test them empirically**.
   - **Suggestion**: Add a **simple model** (e.g., a supply/demand framework) to clarify how deregulation could affect formal employment. For example:
     - **Crowding out**: If home producers undercut formal firms, employment in NAICS 722 (restaurants) should fall.
     - **Complementarity**: If home producers create demand for inputs (e.g., local flour), NAICS 311 (food manufacturing) could grow.
     - **Formalization ladder**: Firm entry rates should rise in treated states.

2. **Literature Gaps**:
   - The paper cites [Shoag & Veuger (2019)](https://www.aeaweb.org/articles?id=10.1257/pol.20170083) on food truck deregulation but doesn’t **contrast the mechanisms**. Food trucks compete directly with restaurants (NAICS 722), while home kitchens may not. Highlight this distinction.

#### **B. Data and Measurement**
1. **County-Level Analysis**:
   - The paper uses **state-level data**, which may mask local effects (e.g., rural vs. urban). QWI suppresses data for small counties, but a **county-level analysis** (even with missingness) could reveal heterogeneity.
   - **Suggestion**: Report a **county-level robustness check** (e.g., using [Census Bureau’s disclosure avoidance methods](https://www.census.gov/data/developers/data-sets/qwi.html)).

2. **Informal Sector Proxies**:
   - The paper acknowledges it cannot observe informal activity, but **proxies** could help:
     - **Farmers market growth**: Use USDA data on farmers market counts (as in the manifest’s "smoke test").
     - **Self-employment**: Use BLS data on self-employed workers in food sectors.
     - **Google Trends**: Search interest in "cottage food" or "food freedom" by state.

3. **Dynamic Effects**:
   - The paper focuses on **static effects** (ATT), but deregulation may have **dynamic effects** (e.g., formalization lags).
   - **Suggestion**: Add a **dynamic DiD specification** (e.g., [de Chaisemartin & D’Haultfœuille 2020](https://www.sciencedirect.com/science/article/pii/S0304407620303948)) to test whether effects grow over time.

#### **C. Robustness and Inference**
1. **Alternative Estimators**:
   - The paper uses **TWFE and Sun–Abraham**, but other estimators could strengthen robustness:
     - **Callaway & Sant’Anna (2021)**: Group-time ATTs to handle staggered adoption.
     - **Borusyak et al. (2021)**: Imputation-based DiD for efficient estimation.

2. **Placebo Tests**:
   - The **NAICS 31–33 placebo** is excellent, but add:
     - **Synthetic control**: For the first-treated state (Wyoming), construct a synthetic control using pre-2015 data.
     - **Falsification outcomes**: Test effects on unrelated sectors (e.g., NAICS 54 "Professional Services").

3. **Power Analysis**:
   - The paper notes it can rule out effects >±3%, but a **formal power analysis** would help:
     - Simulate minimum detectable effects (MDEs) for key outcomes (e.g., using [R’s `DeclareDesign`](https://declaredesign.org/)).
     - Report whether the design has power to detect **policy-relevant effects** (e.g., 5% employment change).

#### **D. Heterogeneity and Mechanisms**
1. **Geographic Heterogeneity**:
   - Test whether effects differ by:
     - **Rural vs. urban states** (e.g., using USDA’s [rural-urban continuum codes](https://www.ers.usda.gov/data-products/rural-urban-continuum-codes/)).
     - **State income levels** (e.g., median household income).

2. **Product-Level Heterogeneity**:
   - The paper aggregates NAICS 311/722, but effects may vary by **product type**:
     - **Perishable vs. non-perishable**: Food freedom acts (which allow perishables) may affect dairy (NAICS 3115) more than baked goods (NAICS 3118).
     - **Suggestion**: Use **6-digit NAICS codes** (e.g., 311811 "Retail Bakeries") for finer-grained analysis.

3. **Entrepreneurship Channels**:
   - The paper tests firm entry rates but could explore:
     - **Survival rates**: Do new firms in treated states survive longer?
     - **Earnings inequality**: Do earnings at the bottom of the distribution fall (suggesting low-skill entry)?

#### **E. Policy Implications**
1. **Cost-Benefit Analysis**:
   - The paper concludes food freedom laws don’t harm formal employment, but **what about benefits**?
   - **Suggestion**: Add a **back-of-the-envelope calculation** of:
     - **Consumer surplus**: How much do prices fall for homemade goods?
     - **Producer surplus**: How many new home-based businesses are created? (Use USDA farmers market data as a proxy.)

2. **Safety Concerns**:
   - The paper cites **zero foodborne illness outbreaks** in food freedom states, but this is a **descriptive claim**.
   - **Suggestion**: Test whether **food safety incidents** (e.g., CDC outbreak data) rise in treated states.

3. **Generalizability**:
   - The paper focuses on the U.S., but **cottage food laws exist globally** (e.g., EU, Canada).
   - **Suggestion**: Discuss whether the results generalize to other contexts (e.g., developing countries with larger informal sectors).

#### **F. Presentation and Clarity**
1. **Figures**:
   - **Event-study plot**: As noted in Essential Points, this is critical for parallel trends.
   - **Map of treated states**: A simple map (e.g., using `geofacet`) would help readers visualize adoption.

2. **Tables**:
   - **Standardize effect sizes**: The appendix (Table A1) reports standardized effects, but these should be **in the main text** (e.g., as a column in Table 2).
   - **Confidence intervals**: Report 95% CIs alongside p-values (e.g., in Table 2).

3. **Writing**:
   - **Clarify the null**: The abstract says "no significant effect," but the discussion suggests **mild complementarity** (2.3% employment increase). Emphasize that the **point estimate is imprecise**.
   - **Define "food freedom"**: The term is jargon; add a **one-sentence definition** in the abstract (e.g., "laws allowing unlicensed home food sales").

---

### **Final Verdict**
This is a **strong, policy-relevant paper** with a credible identification strategy and novel application of QWI data. With the **three essential fixes** (treatment heterogeneity, parallel trends, COVID confounding) and the **suggestions above**, it could make a **significant contribution** to the literature on deregulation and informal-formal sector linkages.

**Recommendation**: **Revise and resubmit** with the following priorities:
1. **Disaggregate treatment effects** (food freedom vs. cottage food).
2. **Add event-study plots** for parallel trends.
3. **Exclude COVID-era data** from the main specification.
4. **Clarify mechanisms** with product-level heterogeneity (e.g., perishable vs. non-perishable).
