# Research Plan: Animal Welfare Havens

## Research Question

Do unilateral fur farming bans in European countries reduce global fur production, or do they simply relocate it to unregulated jurisdictions? This paper tests the "animal welfare haven" hypothesis — the analog of the pollution haven hypothesis applied to animal welfare regulation.

## Identification Strategy

**Staggered Difference-in-Differences.** 15+ European countries enacted fur farming bans between 2000 and 2024, creating staggered treatment at the country-year level. The outcome is bilateral mink furskin trade (HS 430110) from UN COMTRADE.

**Treatment variable:** Binary indicator for whether country *i* has an active fur farming ban in year *t*. Treatment dates:
- UK: 2000 (England/Wales), 2002 (Scotland)
- Austria: 2004
- Netherlands: 2013 (enacted), 2021 (phase-out complete)
- Belgium (Wallonia/Flanders): 2019
- Czech Republic: 2019
- Hungary: 2020
- Ireland: 2022
- Latvia: 2022
- Lithuania: 2023
- Norway: 2025 (phase-out)
- Denmark: 2020 (COVID mink cull — treated as separate shock)

**Control countries:** Finland, Poland, Greece (active fur farming, no ban). Also non-EU fur producers (China, Russia) as trade partners.

**Estimator:** Callaway-Sant'Anna (2021) for heterogeneous treatment timing. Group-time ATTs with never-treated (Finland, Poland) as comparison group.

**Key outcomes:**
1. Domestic fur exports (HS 430110) of banning countries — should decline
2. Fur imports of banning countries — should increase if demand persists
3. Exports of non-banning EU producers (Poland, Finland) — trade diversion test
4. Global trade volume — total welfare effect

## Expected Effects and Mechanisms

**Direct effect:** Banning countries should see near-complete elimination of fur exports (large negative SDE expected).

**Trade diversion:** If demand persists, production shifts to non-banning countries. Poland's mink exports surged from $122M (2010) to $407M (2014) as neighbors banned. This is the "animal welfare haven" channel.

**Global effect:** If trade diversion fully offsets domestic bans, aggregate global fur trade should be unchanged — the regulation reshuffles production geography without reducing animal welfare harm.

**Mechanism:** The key economic mechanism is whether fur farming bans operate on the supply side (reducing production) or merely on the location side (relocating production). With free trade in furskins, unilateral bans face the same leakage problem as carbon taxes without border adjustment.

## Primary Specification

```
Y_it = α_i + γ_t + β * Ban_it + ε_it
```

Where Y_it is log fur trade value for country i in year t, Ban_it is the staggered ban indicator, and α_i and γ_t are country and year fixed effects.

For trade diversion: test whether non-banning neighbor countries see export increases when adjacent countries ban.

## Data Source and Fetch Strategy

1. **UN COMTRADE API** (primary): Bilateral trade in HS 430110 (mink furskins, raw) and HS 4301 (raw furskins, all types). Reporter × Partner × Year × Value/Quantity. COMTRADE API key available in .env.

2. **Eurostat APRO_MT_LSPIG** (secondary): Livestock statistics for cross-validation of production.

3. **Placebo commodities:** HS 4101 (raw hides/skins of bovine), HS 5101 (wool) — not subject to farming bans, should show no differential effect.

## Key Risks

1. **Small cluster count:** ~20 countries. Mitigated with wild cluster bootstrap.
2. **COVID contamination:** Denmark's 2020 mink cull + general COVID trade disruption. Mitigated by treating Denmark separately and robustness excluding 2020-2021.
3. **HS code changes:** Ensure consistent commodity classification across years.
4. **Anticipation effects:** Bans often announced years before phase-out completion. Use announcement date vs. effective date robustness.
