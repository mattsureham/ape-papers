# Research Plan: From the Ballot Box to the Bureau

## Research Question

Did the 2003 Swiss Federal Court ruling (BGE 129 I 232) that banned ballot-vote naturalization increase aggregate naturalization rates in affected municipalities? If so, which nationality groups benefited most — and does the magnitude reveal the "procedural discrimination tax" imposed by direct-democratic gatekeeping?

## Identification Strategy

**Design:** Difference-in-Differences exploiting the July 9, 2003 Federal Court ruling.

**Treatment group:** Municipalities that previously used ballot-vote (Gemeindeversammlung or Urnenabstimmung) naturalization procedures — approximately 400–600 communes concentrated in German-speaking cantons (ZH, AG, LU, SG, AR, AI, SO).

**Control group:** Municipalities that already used administrative (written, anonymous) naturalization procedures prior to 2003.

**Treatment classification approach:** 
1. Primary: Cantonal-level classification from cantonal legislation — some cantons (GE, VD, TI, NE) prohibited ballot naturalization before 2003; others (ZH, AG, LU, SG) allowed it. This gives a clean cantonal binary.
2. Refinement: Language region as proxy (German-speaking cantons overwhelmingly used ballot procedures; French/Italian cantons used administrative procedures).

**Estimator:** 
- Two-way fixed effects (municipality + year FE) with treatment × post interaction
- Sun & Abraham (2021) for staggered treatment (some cantons prohibited ballot naturalization before 2003)
- Event-study specification with leads/lags around 2003

**Key assumption:** Parallel trends in naturalization rates between ballot and non-ballot municipalities absent the ruling. Testable with 22 pre-treatment years (1981–2002).

## Expected Effects and Mechanisms

**Primary hypothesis:** Naturalization rates increase in former ballot municipalities post-2003, as removing discriminatory gatekeeping reduces rejection risk and encourages applications.

**Mechanism:** Hainmueller & Hangartner (2013) document that Ex-Yugoslav and Turkish applicants faced 40% higher rejection rates in ballot municipalities. Removing the ballot should disproportionately increase naturalization of these groups → differential effect by nationality of origin.

**Alternative channels:**
- Demand-side: If applicants self-select out of ballot municipalities, the ruling may increase applications (not just approval rates)
- Supply-side: Administrative procedures may have different standards than popular votes
- Null result possible: If demand-side barriers (language, cost, residency requirements) dominate, removing the ballot may not change aggregate flows — this would be an important finding

## Primary Specification

```
naturalization_rate_{mt} = α + β(Ballot_m × Post_t) + μ_m + λ_t + ε_{mt}
```

Where:
- `naturalization_rate_{mt}` = naturalizations / foreign population in municipality m, year t
- `Ballot_m` = 1 if municipality used ballot-vote naturalization pre-2003
- `Post_t` = 1 if year ≥ 2004 (allow 1 year for implementation)
- `μ_m` = municipality fixed effects
- `λ_t` = year fixed effects

## Data Sources

1. **BFS PXWeb API** — Dataset `px-x-0102020000_201`: Municipal demographic balance 1981–2024
   - Component 12: "Acquisition of Swiss citizenship" (naturalization counts)
   - Components 0, 4: Population and immigration (denominators)
   - ~2,305 geographic units × 44 years

2. **Treatment classification:** Cantonal legislation coding
   - French-speaking cantons (GE, VD, NE, JU, FR-French, VS-French) + TI → control (administrative)
   - German-speaking cantons (ZH, BE-German, LU, SZ, OW, NW, GL, ZG, SO, BS, BL, SH, AR, AI, SG, GR, AG, TG) → treatment (ballot)
   - Some cantons mixed or reformed before 2003 → requires careful coding

3. **Swissvotes / referendum data** — Municipal-level voting patterns as balance checks

## Fetch Strategy

1. Query BFS PXWeb API for full municipal demographic panel (1981–2024)
2. Construct treatment classification from cantonal language/legislation
3. Build balanced panel of municipality-year naturalization rates
4. Handle municipal mergers using BFS SMMT concordance table
