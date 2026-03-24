# Research Plan: Croatia's 2013 Fiscalization and Cash-Sector Tax Compliance

## Research Question

Did Croatia's 2013 mandatory electronic cash register fiscalization — rolled out in three sector-staggered phases — increase reported business turnover and VAT compliance? How large was the "formalization dividend," and did it persist over the medium run?

## Policy Background

Croatia's **Law on Fiscalization of Cash Transactions** (Official Gazette 133/2012) mandated all cash-receiving businesses to install certified electronic cash registers communicating real-time with the Tax Administration and issue digitally-signed fiscal receipts.

**Staggered implementation within 2013:**
- **Phase 1 (Jan 1):** Accommodation (NACE I55) + food/beverage (NACE I56)
- **Phase 2 (Apr 1):** Wholesale (G46), retail (G47), motor vehicle repair (G45)
- **Phase 3 (Jul 1):** All remaining obligated entities

**Permanently exempt:** Agriculture (A), financial services (K), real estate (L), postal services, vending machines, banking/insurance.

## Identification Strategy

### Primary: Cross-Country Difference-in-Differences

Croatia (treated) vs. 5 control countries that maintained existing compliance systems without introducing a new electronic receipt mandate in 2013: **Slovakia, Austria, Slovenia, Romania, Hungary**.

- Unit: country × year
- Pre-period: 2008–2012 (5 years)
- Post-period: 2013–2023 (11 years)
- Outcome: VAT revenue as % of GDP (Eurostat `gov_10a_taxag`)
- FE: country + year

### Secondary: Within-Croatia Sector-Stagger

Callaway-Sant'Anna staggered DiD exploiting the 3-phase rollout across NACE sectors.

- Cohort 1 (Jan 2013): NACE I55, I56
- Cohort 2 (Apr 2013): NACE G45, G46, G47
- Cohort 3 (Jul 2013): Remaining sectors
- Never-treated: Agriculture, finance, real estate
- Outcome: Reported sector turnover (Eurostat SBS `sbs_na_ind_r2`)
- Pre-period: 2008–2012

### Key Threats and Mitigation

1. **EU accession (Jul 1, 2013):** Same day as Phase 3. Mitigated by: (a) Phases 1–2 predate accession; (b) accession affects all sectors equally while fiscalization is sector-specific; (c) cross-country DiD absorbs level shifts via year FE.
2. **Concurrent VAT rate change:** Croatia raised standard VAT from 23% to 25% in March 2012, a year before fiscalization. This is pre-treatment for all specifications.
3. **Small number of treated units (sector-level):** Addressed via cross-country specification as primary; sector stagger as mechanism.

## Exposure Alignment

**Who is treated:** All cash-receiving businesses in Croatia, classified by NACE sector into three treatment cohorts. Phase 1 (Jan 2013): ~30,000 accommodation and food/beverage establishments. Phase 2 (Apr 2013): ~50,000 wholesale, retail, and motor vehicle businesses. Phase 3 (Jul 2013): ~50,000 remaining entities in construction, transport, services, etc. Total: ~130,000 mandated businesses.

**Who is exempt:** Agricultural producers selling own produce, financial/insurance services, real estate activities, public administration, and automated vending. These sectors either conduct negligible cash transactions or are already subject to separate monitoring regimes.

**Outcome measurement alignment:** The cross-country DiD measures aggregate VAT/GDP at the country level — this captures the total fiscal effect of fiscalization on all treated businesses. The sector-level DDD measures gross value added by NACE sub-sector — this aligns treatment assignment (sector-specific mandate) with the outcome (sector-specific reported activity). Treatment is sector-wide within Croatia; all businesses in a treated sector face the mandate simultaneously, so there is no within-sector selection into treatment.

**Potential exposure leakage:** If fiscalized businesses in treated sectors interact with exempt businesses (e.g., hospitality purchasing from agriculture), the mandate could indirectly affect exempt sectors through supply chains. This would bias the within-Croatia sector DiD downward if exempt sectors also increase reported activity. The cross-country DiD captures the full economy-wide effect including any spillovers.

## Expected Effects and Mechanisms

1. **Formalization effect:** Reported turnover rises in treated sectors as electronic monitoring reduces under-reporting.
2. **Compliance persistence:** If monitoring creates habit formation, gains persist; if purely deterrence, gains may decay with enforcement intensity changes.
3. **Size heterogeneity:** Micro-enterprises in cash-intensive sectors face largest compliance cost → may show exits alongside revenue formalization.

## Data Sources

1. **Eurostat `gov_10a_taxag`** — Government revenue by tax category. VAT (D211) as % of GDP, all countries, 2008–2024. Confirmed accessible via REST API.
2. **Eurostat `sbs_na_ind_r2`** — Structural Business Statistics. Turnover, value added, number of enterprises by NACE 2-digit, Croatia + controls, 2008–2021.
3. **Eurostat `sts_trtu_m`** — Monthly retail trade turnover index by NACE division (for higher-frequency robustness).
4. **Eurostat `nama_10_a64`** — National accounts by NACE A64 activity (gross value added by sector).

## Primary Specification

Cross-country DiD:
$$\text{VAT}_{ct} = \alpha_c + \gamma_t + \beta \cdot \text{Post}_t \times \text{Croatia}_c + X'_{ct}\delta + \varepsilon_{ct}$$

Where $c$ indexes countries, $t$ indexes years, Post = 1{t ≥ 2013}, Croatia = 1{c = HR}.

Sector-level:
$$Y_{sct} = \alpha_{sc} + \gamma_t + \beta \cdot D_{st} + \varepsilon_{sct}$$

Where $s$ indexes NACE sectors, $D_{st}$ = 1{sector s treated by time t}, using Callaway-Sant'Anna for heterogeneous timing.
