# Research Plan: Accord vs. Alliance — Private Governance and Factory Safety After Rana Plaza

## Research Question

Did binding private governance (the Bangladesh Accord) produce better factory safety outcomes than voluntary self-regulation (the Alliance for Bangladesh Worker Safety) after the 2013 Rana Plaza collapse? We estimate the causal effect of enforcement regime design on structural remediation completion rates and factory survival.

## Identification Strategy

**Triple Difference-in-Differences:**

Three factory groups defined by buyer nationality of primary export destination (pre-Rana Plaza, circa 2012):
- **T1 (Accord):** ~1,600 factories supplying European brands → legally binding inspections + mandatory remediation
- **T2 (Alliance):** ~600 factories supplying North American brands → voluntary inspections + self-reporting
- **C (Neither):** ~1,800 BGMEA member factories with <15% EU/US buyer exposure → no international safety regime

Key identification assumption: conditional on factory size, district, and sub-sector, the assignment to Accord vs. Alliance was driven by *buyer nationality*, not factory quality. European brands joined the Accord; North American brands joined the Alliance. A factory's primary buyer composition in 2012 determines treatment — this is plausibly exogenous to post-2013 safety outcomes.

**Treatment timing:** Accord (May 2013), Alliance (July 2013). Sharp, common timing.

**Placebos and robustness:**
1. Pre-Rana Plaza balance: factory size, district, export value should be similar across groups conditional on controls
2. Factories that switched between regimes (rare) as falsification
3. Alliance disbandment (Dec 2018) as a "treatment removal" test
4. Within-Accord variation by remediation urgency classification

## Expected Effects and Mechanisms

**H1:** Accord factories have higher remediation completion rates than Alliance factories (binding > voluntary enforcement).
**H2:** Both Accord and Alliance factories outperform non-signatory factories (any international pressure > none).
**H3:** Accord factories have higher survival rates (sustained buyer relationships conditional on compliance).
**Mechanism:** Binding enforcement + buyer commitment → remediation investment → continued export access. Voluntary regime → incomplete remediation → brand switching → factory exit.

## Primary Specification

```
Y_ft = β₁(Accord_f × Post_t) + β₂(Alliance_f × Post_t) + α_f + δ_t + X_ft'γ + ε_ft
```

Where Y is remediation completion rate or factory survival indicator. Factory and year FE absorb time-invariant factory characteristics and common shocks. The coefficient of interest is β₁ − β₂ (Accord premium over Alliance).

## Data Sources and Fetch Strategy

1. **International Accord inspection database** (bangladeshaccord.org) — factory-level inspection records with remediation percentages. Web scrape or download CSV if available.

2. **BGMEA factory registry** (bgmea.com.bd/member_list) — ~4,000 RMG factories with membership number, district, employment size. Web scrape.

3. **UN Comtrade** (comtradeplus.un.org) — Bangladesh RMG exports by destination country (HS chapters 61-62). API access confirmed. Used for aggregate export trends, not factory-level assignment.

4. **World Bank Development Indicators** — Bangladesh GDP, manufacturing value added, total exports. API confirmed.

**Fallback if web scraping fails:** Use aggregate published statistics from Accord annual reports (publicly available PDFs with summary tables) + academic papers that have tabulated the data (Bossavie et al. 2023).
