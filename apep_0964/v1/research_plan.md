# Research Plan: The Debt Bias Correction

## Research Question
Does coordinated limitation of interest deductibility — the EU's Anti-Tax Avoidance Directive (ATAD I), capping deductible interest at 30% of EBITDA — actually shift aggregate corporate financing from debt toward equity? Or do firms restructure within the rules, leaving the macro debt bias unchanged?

## Why It Matters
Tax-induced debt bias is a canonical result in public finance (Modigliani-Miller with taxes). Decades of theory predict that limiting interest deductibility should reduce corporate leverage. But virtually all existing evidence uses firm-level data (Orbis/Amadeus) requiring commercial access. No paper has tested whether the aggregate financing structure of entire economies actually responds. ATAD is the largest coordinated reform of interest deductibility in history — 27 countries, simultaneously — making it the natural testing ground.

## Identification Strategy
**Dose-response DiD** exploiting cross-country variation in de minimis thresholds:
- **High-dose group** (nil or EUR 1M threshold): IT, LV, SK, NL, PT, RO, SI, ES — the rule binds for many firms
- **Medium-dose group** (EUR 3M threshold): 15 countries — standard implementation
- **Low-dose/derogation group** (EUR 5M or delayed): SE, FR, EL, SK, SI, ES (derogation until 2022-2024)

Treatment intensity = inverse of de minimis threshold (lower threshold → more firms constrained → stronger expected effect).

**Staggered DiD** using derogation countries (FR, EL, SK, SI, ES, IE) as late adopters vs. 2019 early adopters.

**Built-in placebo**: Derogation countries should show no effect in 2019-2021 (they hadn't adopted yet).

## Expected Effects
- Interest-to-EBITDA ratio should decline (mechanical + behavioral)
- Debt securities (F3) should decline relative to equity
- Loan composition may shift (bank loans → bond substitution unclear)
- Effects should be larger in high-dose countries (low de minimis)

## Primary Specification
Y_{ct} = α_c + γ_t + β · (Adopted_{ct} × DoseIntensity_c) + X_{ct}'δ + ε_{ct}

Where:
- Y_{ct}: interest/EBITDA ratio, debt composition ratios for country c, year t
- α_c, γ_t: country and year fixed effects
- Adopted_{ct}: binary indicator = 1 after ATAD adoption in country c
- DoseIntensity_c: treatment intensity based on de minimis threshold
- X_{ct}: GDP growth, inflation, ECB policy rate (controls for macro conditions)

Cluster SEs at country level (27 clusters). Wild cluster bootstrap for inference robustness.

## Data Sources
1. **Eurostat Annual Sector Accounts** (nasa_10_f_bs): Non-financial corporations (S11)
   - F3 (debt securities liabilities), F4 (loan liabilities)
   - Dataset: nasa_10_f_bs, 27 countries, 2012-2023
2. **Eurostat Sector Accounts Transactions** (nasa_10_nf_tr):
   - D41 PAID (interest paid), B2A3G (gross operating surplus ≈ EBITDA proxy)
3. **ATAD implementation details**: Hard-coded from KPMG/EY surveys + directive text
   - De minimis thresholds, EBITDA cap percentages, adoption dates by country
4. **Macro controls**: Eurostat (GDP growth), ECB SDW (policy rate)

## Exposure Alignment
The treatment — ATAD interest limitation — directly constrains firms whose net borrowing costs exceed the de minimis threshold. The outcome (aggregate interest/GOS ratio from Eurostat sector accounts) captures economy-wide corporate financing flows, including both constrained and unconstrained firms. The unit of observation is the country-year, meaning the estimated effect is the average treatment effect on the treated economy's aggregate financing structure, not on individual firms. This aggregate approach intentionally measures whether ATAD changes the macro debt-equity mix, which is the relevant object for financial stability policy. The dose variable (inverse of de minimis) proxies the share of the corporate sector facing binding constraints: lower thresholds expose more firms. Countries with zero de minimis (IT, LV, SK) have universal exposure; countries with EUR 3M thresholds only constrain large firms. This heterogeneous exposure is a feature of the design, not a confounder.

## Robustness
1. Event study (leads and lags) for parallel trends
2. Derogation-country placebo (no 2019 effect expected)
3. Wild cluster bootstrap (27 clusters is borderline)
4. Leave-one-out (drop each country)
5. Alternative treatment timing (use actual transposition date vs. directive deadline)
6. Alternative outcome: ratio of total interest paid to GDP
