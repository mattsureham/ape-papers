# Research Plan: Supply-Side Destruction in UK Payday Lending

## Research Question
Did the FCA's January 2015 high-cost short-term credit (HCSTC) price cap cause market collapse rather than marginal adjustment on the supply side? How large was the "supply destruction multiplier" — the ratio of actual firm exit to the regulator's cost-benefit prediction?

## Identification Strategy
**Two-phase event study exploiting the natural separation of exit channels.**

The cap took effect 2 January 2015. The identification exploits two facts:
1. **Phase 1 (Jan 2015 – mid 2018):** Exits are cap-driven. Firms unable to operate profitably under the 0.8%/day cap leave the market. These exits identify the direct supply-side effect of price regulation.
2. **Phase 2 (Aug 2018 – Oct 2019):** Exits are compensation-driven. Wonga (Aug 2018), QuickQuid (Oct 2019), The Money Shop (Jun 2019), Wageday Advance (Feb 2019) — all exited due to historical redress claims, not the cap. These provide a natural placebo/contrast group.

**Primary design:** Firm-level survival analysis using FCA Financial Services Register authorisation/cancellation dates. Cox proportional hazard model with pre-cap firm characteristics (entry date, permission scope, geographic footprint via Companies House registered office).

**Secondary design:** Regional event study using FCA Product Sales Data (PSD006) quarterly loan volumes across 12 UK regions. Regions with higher pre-cap concentration in marginal (later-exiting) firms experienced larger supply shocks — this provides cross-regional variation.

**Placebo:** Second-hand homes equivalent = compensation-wave exits. If Phase 2 exits show different regional patterns than Phase 1 exits, this confirms the cap mechanism is distinct from the compensation mechanism.

## Expected Effects and Mechanisms
- **Firm exit:** Massive — from 240+ to ~30 active lenders. The cap compressed margins below fixed operating costs for most firms.
- **Market concentration:** Surviving firms (mainly Provident Financial/Vanquis, Amigo, Sunny/Elevate) gained market share. HHI should spike.
- **Regional heterogeneity:** Regions with higher pre-cap payday lending penetration (North West: 125 loans/1000 adults) should experience larger supply shocks than low-penetration regions (Northern Ireland: 74 loans/1000 adults).
- **Supply destruction multiplier:** FCA CBA predicted 7-11% of borrowers would lose access; actual market contraction was ~86% in volume by 2022. The multiplier is 8-12x.

## Primary Specification
**Firm-level:** Discrete-time hazard model of exit. Unit = firm × quarter. Outcome = exit indicator (permission cancellation/withdrawal). Treatment = post-cap period interacted with pre-cap firm characteristics.

**Regional:** Y_rt = α_r + γ_t + β × PostCap_t × PreCapExposure_r + ε_rt
Where PreCapExposure_r is the pre-cap share of loans from firms that subsequently exited.

## Data Sources
1. **FCA Financial Services Register** — Firm-level authorisation/cancellation dates, HCSTC permission types. Public API: `https://register.fca.org.uk/s/`
2. **FCA Product Sales Data (PSD006)** — Quarterly HCSTC loan volumes by UK region. Published XLSX files from FCA website.
3. **Companies House Bulk Data** — SIC codes (6491, 6492), incorporation/dissolution dates, registered addresses. Monthly CSV snapshot.
4. **Bank of England** — RPQTFHE series: quarterly write-offs for consumer credit, 2010-2024.
5. **FCA publications** — FS17/2 (post-implementation review, 2017), CP14/10 (original CBA), annual data bulletins.

## Fetch Strategy
1. Scrape FCA Register for all firms with HCSTC-related permissions (using permission codes)
2. Download PSD006 XLSX files from FCA data pages
3. Download Companies House bulk snapshot for SIC 6491/6492
4. Fetch BoE RPQTFHE quarterly series via API
5. Extract key figures from FCA publications (FS17/2, annual bulletins) for calibration
