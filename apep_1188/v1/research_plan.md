# Research Plan: The Brussels Effect on American Hiring

## Research Question

Does the EU's General Data Protection Regulation (GDPR), enforced May 25, 2018, reshape US labor markets through extraterritorial compliance demands? Specifically: did GDPR enforcement cause differential changes in hiring, separations, and earnings in the US Information sector (NAICS 51) relative to less data-intensive sectors, concentrated in states with greater EU trade exposure?

## Identification Strategy

**Triple-difference (DDD):** County × Quarter × Industry panel.

- **Diff 1 (Time):** Pre-enforcement (2016Q1–2018Q1) vs. post-enforcement (2018Q3–2020Q1). Drop 2018Q2 as transition quarter.
- **Diff 2 (Industry):** Information (NAICS 51) vs. control sectors — Finance (52), Professional Services (54), Accommodation (72). These share county-level labor market conditions but are not directly subject to EU data regulation.
- **Diff 3 (Geography):** States with high vs. low EU trade exposure. Measured by pre-period (2016) state export share to EU-28, from Census Foreign Trade Division. Continuous treatment intensity.

**Primary specification:**
$$Y_{ciqt} = \alpha + \beta_1 \cdot \text{Info}_i \times \text{Post}_t \times \text{EU\_Exposure}_s + \gamma_{cq} + \delta_{it} + \epsilon_{ciqt}$$

where $c$ = county, $i$ = industry, $q$ = quarter, $t$ = year-quarter, $s$ = state. County-by-quarter FE absorb all local labor market shocks. Industry-by-time FE absorb national industry trends.

**Clustering:** State level (51 clusters). Wild cluster bootstrap for robustness.

## Expected Effects and Mechanisms

**Primary hypothesis:** GDPR compliance demands increase hiring in Information-sector jobs (compliance officers, data engineers, privacy counsel) in high-EU-exposure states, but may also increase separations as firms restructure. The net effect on employment depends on whether the "compliance tax" creates more jobs than it destroys.

**Mechanisms:**
1. **Compliance hiring:** Firms need DPOs, privacy engineers, legal staff → increased hires
2. **Restructuring:** Firms exit EU markets or shut data-intensive units → increased separations
3. **Wage premium:** Scarcity of compliance expertise → rising earnings in Information sector

**Expected signs:** Positive effect on hires, ambiguous on net employment, positive on earnings. Larger in high-EU-exposure states.

## Data Sources

1. **QWI (Quarterly Workforce Indicators):** Azure `derived/qwi/sa/ns/*.parquet`. County × quarter × NAICS 2-digit. Variables: Emp, HirA, Sep, EarnS. 2016Q1–2020Q1.
2. **QWI 3-digit:** Azure `derived/qwi/sa/n3/*.parquet`. For placebo tests within Information sector (518 Data Processing vs 512 Motion Picture).
3. **State EU trade exposure:** Census USA Trade Online — state exports to EU-28, 2016. Construct share of total state exports going to EU.
4. **GDELT (optional mechanism):** BigQuery `gdelt-bq.gdeltv2.gkg_partitioned`. GDPR media salience as event-study validation.

## Primary Specification Details

- **Outcomes:** log(Emp), log(HirA), log(Sep), log(EarnS)
- **Sample:** Counties with non-missing employment in all 4 industries across all 16 quarters (balanced panel)
- **Fixed effects:** County × quarter, industry × quarter
- **Inference:** Cluster at state level; wild cluster bootstrap (fwildclusterboot)
- **Event study:** Replace Post × Info × EU_Exposure with quarter-specific interactions, normalized to 2018Q1

## Robustness

1. **CCPA event (Jan 2020):** California-specific shock. Test whether California Information sector diverges further post-CCPA.
2. **3-digit NAICS placebos:** 518 (Data Processing) should respond most; 512 (Motion Picture) should not.
3. **Alternative control industries:** Manufacturing (31-33), Retail (44-45).
4. **Binary treatment:** Above/below median EU export share instead of continuous.
5. **Dropping transition quarter:** Including vs excluding 2018Q2.
6. **Leave-one-out:** Drop each treated state, verify stability.
