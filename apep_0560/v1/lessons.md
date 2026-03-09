## Discovery
- **Policy chosen:** GISTM (Global Industry Standard on Tailings Management, 2020) — a rare global voluntary standard with clean adoption date and $25T investor backing. Enables test of market discipline.
- **Ideas rejected:** (1) Property values near tailings failures — N too small for US (~27-34 events), thin housing markets. (2) Environmental justice + tailings siting — cross-sectional identification weak, data assembly complex.
- **Data source:** WISE Chronology of Tailings Dam Failures (HTML table, 206 events) + Yahoo Finance (42 mining firms, 256K obs). Both freely accessible, no API keys needed.
- **Key risk:** Post-GISTM subsample is small (30 events). The GISTM interaction test has limited power.

## Key Findings
- Overall CAR is slightly positive (+0.23%) — competitive reallocation, not sector crash. Aggregate not robustly significant (event-clustered t=0.61, permutation p=0.57).
- Tailings-owning firms suffer -0.79 pp relative to streaming/royalty companies (event FE, t=-2.25)
- Post-GISTM × tailings interaction: -1.39 pp (p<0.05) — GISTM increased market scrutiny
- Pre-event placebo is clean (t=0.82)
- Results stable: LOO, winsorization, mega-event exclusion, XME benchmark all confirm

## Review
- **Advisor verdict:** 3 of 4 PASS (6 attempts to fix issues)
- **Top criticism:** Two different SE procedures (event-clustered vs cross-sectional) gave contradictory significance for the aggregate mean. Reporting both honestly and framing the cross-sectional heterogeneity as the main story resolved this.
- **Surprise feedback:** Table 5 (SDE) was clipped in PDF — needed adjustbox wrapper. Appendix firm list was wrong (7 firms listed that weren't in the data).
- **What changed:** (1) Removed misleading t=1.99 from abstract, (2) Added explicit SE explanation distinguishing cross-sectional vs event-clustered, (3) Fixed firm list to match actual data, (4) Added concrete XME benchmark results, (5) Reconciled figure/text GISTM CARs, (6) Fixed dates to 1996-2025
