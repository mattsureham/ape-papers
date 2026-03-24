# Research Plan: Does Mandated Ethnic Mixing Erode the Minority Housing Discount?

## Research Question

Singapore's Ethnic Integration Policy (EIP, 1989) caps each ethnic group's share per HDB block and neighborhood, restricting the buyer pool when blocks hit quota limits. Wong (2013, ReStat) documented a 3-5% minority price discount in 1990s-2000s data. After 35+ years of mandated integration, has this discount converged toward zero — evidence that the contact hypothesis operates in housing markets?

## Identification Strategy

**Design:** RDD at EIP neighborhood-level quota thresholds using Census 2020 ethnic composition as the running variable.

**Running variable:** Distance between subzone ethnic share and EIP neighborhood limit. For Chinese: limit ~84% at neighborhood level. For Malay: ~22%. For Indian: ~10%.

**Treatment:** In subzones above the threshold, blocks face binding sale constraints — sellers from the over-represented group cannot sell to same-ethnicity buyers, restricting the buyer pool and depressing prices.

**Key advantage over Wong (2013):** Wong used phonebook name-matching for individual-level ethnic identification (1990s-2000s). We use 9 years of transaction microdata (2017-2026) matched to Census 2020 subzone ethnic composition. The temporal comparison (Wong's 3-5% gap vs our current estimate) directly tests whether 35 years of mandated integration changed preferences.

**Validity:**
- Subzone ethnic composition is a slow-moving demographic variable — no precise manipulation
- McCrary test on subzone ethnic share distribution near thresholds
- Covariate balance: flat type, floor area, lease remaining should be smooth through cutoff
- Bandwidth sensitivity with rdrobust optimal + manual choices
- Placebo cutoffs at non-policy thresholds

## Expected Effects and Mechanisms

**Primary hypothesis:** The minority price discount has narrowed (contact hypothesis). If mandated integration changes preferences, the price gap between constrained and unconstrained neighborhoods should be smaller than Wong's 3-5%.

**Alternative:** The discount persists or widened (preference persistence). If preferences are deep and stable, EIP only reshuffled households without changing attitudes.

**Mechanism:** Constrained blocks → restricted buyer pool → lower effective demand → price discount. Magnitude reflects the strength of ethnic preferences.

## Primary Specification

For transaction i in subzone s at time t:
log(price_{ist}) = α + τ · Above_s + f(EthnicShare_s - Threshold) + X_{ist}β + γ_t + ε_{ist}

Where:
- Above_s = 1 if subzone ethnic share exceeds EIP threshold
- f(·) = local polynomial (1st order) in distance from threshold
- X_{ist} = flat type, floor area, floor level, remaining lease
- γ_t = year-quarter fixed effects
- Bandwidth: MSE-optimal (Cattaneo, Idrobo & Titiunik 2020)

## Data Source and Fetch Strategy

1. **HDB Resale Transactions** (data.gov.sg API): 226,800 transactions 2017-2026, with block, street, town, flat type, floor area, resale price, month, lease commence date, storey range
2. **Census 2020 Ethnic Composition** (data.gov.sg): 332 subzone records with Chinese/Malay/Indian/Others population counts
3. **Matching:** Join transactions to subzones via town/street/block → subzone crosswalk (HDB building-subzone mapping)

## Feasibility Risks and Mitigations

- **Subzone vs block mismatch:** EIP operates at block level; we observe ethnic composition at subzone level. Mitigation: subzone-level analysis captures neighborhood effects; interpret as reduced-form ITT.
- **Census 2020 is a snapshot:** Ethnic composition may change over 2017-2026 period. Mitigation: ethnic composition is slow-moving; robustness check restricting to years near 2020.
- **Subzone-block matching:** Need reliable crosswalk. Mitigation: HDB addresses include town and block, which map to URA subzones; can use Singapore geocoding.
