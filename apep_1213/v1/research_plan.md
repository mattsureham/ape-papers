# Research Plan: Moldova's 'Stolen Billion' — Bank Branch Exposure and Firm Employment

## Research Question

Does the destruction of credit supply through state-bank fraud cause persistent employment losses in dependent regions? Specifically, did Moldova's November 2014 banking crisis — in which three banks holding 60% of branch network were placed under administration after $1B in fraudulent loans — cause larger employment declines in raions more dependent on Banca de Economii (BEM)?

## Identification Strategy

**Continuous-treatment DiD** exploiting cross-raion variation in dependence on the collapsed banks.

**Treatment variable:** BEM branch dependence, measured as the share of total banking branches in each raion attributable to BEM and its two co-conspirator banks prior to the crisis. BEM's branch network was inherited from the Soviet-era Savings Bank (Sberbank), whose geographic footprint was determined by 1940s–1980s administrative planning — orthogonal to contemporary firm productivity and employment trends.

**Key identifying assumption:** Conditional on raion and year fixed effects, raions with higher pre-crisis BEM branch shares would have followed parallel employment trends absent the fraud. Supported by:
1. BEM's Soviet-era footprint was determined decades before the outcomes
2. The fraud was a supply-side shock (banks were healthy from borrowers' perspective)
3. 9 pre-periods (2005–2013) allow visual pre-trends validation

**Estimating equation:**
y_{rt} = α_r + λ_t + β · (BEM_share_r × Post_t) + ε_{rt}

where r indexes raions, t indexes years, and Post_t = 1{t ≥ 2015}.

## Expected Effects and Mechanisms

**Primary hypothesis:** Higher BEM dependence → larger employment declines post-2014.
- **Mechanism 1 (Credit channel):** Small firms in BEM-dependent raions lost their primary credit source, constraining working capital and investment.
- **Mechanism 2 (Branch closure):** Physical closure of branches raised transaction costs and reduced financial access for local businesses.
- **Mechanism 3 (Confidence shock):** Depositor losses and uncertainty depressed local economic activity beyond the direct credit channel.

**Expected magnitude:** Based on Chodorow-Reich (2014) and Huber (2018), a 10pp increase in exposure typically produces a 1–3% employment decline. Moldova's shock was more severe (60% of banking system), so effects could be larger.

## Primary Specification

```
log(employment)_{rt} = α_r + λ_t + β · (BEM_share_r × Post_t) + ε_{rt}
```

Clustered at the raion level (35 clusters → wild cluster bootstrap for inference). Event-study version interacts BEM_share with year dummies for pre-trends.

## Data Sources and Fetch Strategy

### Outcome data (confirmed)
- **Moldova NBS StatBank** (PxWeb API): `http://statbank.statistica.md/PxWeb/api/v1/en/`
  - Table `ANT030200reg` (2005–2014): Annual employment by raion
  - Table `ANT030055reg` / `ANT020200reg` (2015–2017+): Post-crisis employment by raion
  - Variables: Number of employees, number of enterprises, turnover

### Treatment variable
- **National Bank of Moldova (NBM):** Banking supervision reports contain branch counts by institution. Annual reports 2012–2013 list licensed credit institutions and branch networks.
- **Proxy construction:** If raion-level branch data is unavailable via API, use population size / urbanization as a proxy for banking competition (small rural raions ≈ high BEM dependence). The correlation between rurality and BEM dependence is well-documented — BEM's Rural Business Development Program explicitly targeted peripheral areas.

### Secondary/robustness data
- **World Bank WDI:** Moldova GDP, credit-to-GDP ratio (for context)
- **NBM monetary statistics:** Policy rate changes (3.5% → 19.5%) for narrative

## Robustness Checks
1. Event-study pre-trends (interactions of BEM_share × year dummies, 2005–2013)
2. Placebo: Chisinau excluded (capital may respond differently)
3. Placebo: Wine-producing raions (Russian wine embargo 2013)
4. Leave-one-out jackknife (with 35 clusters, check no single raion drives results)
5. Wild cluster bootstrap (Cameron, Gelbach & Miller 2008)
6. Binary treatment version (rural vs. urban raions)
