# Research Plan: The Invoice Ledger as Detective — Lithuania's i.SAF Mandate and VAT Compliance

## Research Question

Does mandatory real-time invoice reporting reduce the VAT gap? Lithuania's October 2016 i.SAF mandate required all VAT-registered firms to submit monthly XML ledgers of every issued and received invoice, enabling automated cross-matching of buyer and seller records. We estimate the effect of this third-party verification technology on VAT compliance using cross-sector variation in B2B invoice intensity as continuous treatment in a Baltic-state difference-in-differences design.

## Motivation

Lithuania had one of the EU's largest VAT gaps (~26% of VTTL in 2015, vs. EU average ~15%). The i.SAF system creates a digital paper trail: every invoice is cross-referenced, and discrepancies trigger automated audit selection. This is the world's first universal B2B digital invoice ledger — predating Italy's SDI (2019) and the EU's ViDA directive (2030 target).

The EU's ViDA initiative projects EUR 11 billion in annual revenue gains from EU-wide e-invoicing. Lithuania provides the earliest, cleanest test of this mechanism in a European context.

## Identification Strategy

### Primary: Continuous-treatment DiD

**Treatment:** October 1, 2016 — all Lithuanian VAT-registered firms must submit i.SAF monthly.

**Treatment intensity:** Sector-level B2B invoice intensity from Eurostat input-output tables (naio_10_cp1700). Sectors where firms both issue and receive many domestic B2B invoices face stronger third-party verification.

**Control countries:** Latvia, Estonia (no equivalent all-firm invoice mandate in 2016). Finland and Poland as additional controls.

**Specification:**
Y_{s,c,t} = alpha_s + gamma_t + delta_c + beta(InvoiceIntensity_s × Lithuania_c × Post2016_t) + epsilon_{s,c,t}

### Cross-country DiD (simple)
Lithuania vs. Baltic controls, comparing VAT/GDP ratios and VAT gap estimates before/after October 2016.

## Expected Effects

1. **VAT gap reduction** in Lithuania relative to controls
2. **Sector GVA growth** concentrated in high-B2B-intensity sectors (formalization)
3. **Possible firm exit** among marginal firms facing compliance costs

## Exposure Alignment

The treatment operates at the country level (Lithuania's i.SAF mandate applies to all VAT-registered firms). The treated entities are Lithuanian sectors in the continuous-treatment design, where treatment intensity varies by B2B invoice share. Control countries (Latvia, Estonia, Finland, Poland) share the EU VAT legal framework but did not implement equivalent universal invoice reporting during the study period. Latvia introduced SAF-T for large firms only in 2019; Estonia relied on existing digital infrastructure without mandating invoice ledgers.

**Who is actually affected:** All Lithuanian VAT-registered firms (approximately 200,000 entities). Treatment intensity is strongest for firms in sectors with dense domestic B2B networks (manufacturing, construction, wholesale) and weakest for B2C and VAT-exempt sectors.

## Data Sources (all Eurostat, no authentication required)

| Dataset | Code | Content |
|---------|------|---------|
| VAT revenue | gov_10a_taxag (D211) | Country × year VAT collections |
| Sector GVA | nama_10_a64 | NACE sector × country × year value added |
| Business demography | bd_9bd_sz_cl_r2 | Firm births/deaths by country × sector |
| Input-output tables | naio_10_cp1700 | Lithuanian B2B intensity by sector |
| GDP | nama_10_gdp | For ratios |

Additionally: CASE/European Commission VAT Gap study reports (annual 2013-2022).

## Design Parameters

- Treated country: Lithuania (Oct 2016)
- Control countries: Latvia, Estonia, Finland, Poland
- Pre-periods: 2010-2016 (7 years)
- Post-periods: 2017-2022 (6 years)
- Sectors: 20 NACE A21 sectors
- Total observations: 1,300 sector-country-years
- Clustering: Country level (5 clusters → wild cluster bootstrap, randomization inference)

## Robustness Checks

1. Randomization inference (permuting treatment country)
2. Placebo treatment dates (2012-2015)
3. Leave-one-country-out analysis
4. Sector-type placebo (VAT-exempt vs. VAT-liable)
5. Log VAT revenue levels (to address GDP growth confound)
6. Log GDP as placebo outcome
