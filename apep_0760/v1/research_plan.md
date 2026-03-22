# Research Plan: Clearing the Deck — SEC Chair Transitions and Capital Market Integrity

## Research Question

Do SEC Chair transitions create measurable enforcement distortions — pre-departure surges followed by post-arrival vacuums — that undermine securities fraud deterrence and capital market integrity?

## Identification Strategy

**Design 1: RD-in-time.** Running variable = calendar days from Chair transition date. 6 transitions since 2009 (Schapiro→White 2012, White→Clayton 2017, Clayton→Lee 2020, Lee→Gensler 2021, Gensler→Uyeda 2025, Uyeda→Atkins 2025). Estimate discontinuity in daily/weekly enforcement filing rates at the transition date.

**Design 2: Difference-in-discontinuities.** Cross-party transitions (different political party) vs. same-party transitions. Cross-party transitions should show larger enforcement vacuums if incoming Chair has different enforcement priorities and dismisses predecessor's cases. Same-party transitions serve as a natural placebo with smaller disruption.

**Design 3: Event-study around transitions.** Pool all 6 transitions, center at transition date t=0, estimate dynamic effects on enforcement intensity ±90 days (or ±180 days). Test for pre-departure surge (negative t) and post-arrival vacuum (positive t).

## Expected Effects and Mechanisms

- **Pre-departure surge:** Outgoing Chair rushes to file pending cases before losing authority → elevated filing rates in final 2-3 months
- **Post-arrival vacuum:** New Chair reviews priorities, staffing, case pipeline → depressed filing rates for 3-6 months
- **Market response:** During enforcement vacuum, firms engage in more aggressive financial reporting → more restatements and class actions 6-12 months later
- **Deterrence decay:** Stock market response to enforcement actions is smaller during surges (market discounts rushed cases) and restored during normal periods

## Primary Specification

$$Y_{t} = \alpha + \beta \cdot \mathbf{1}[t \geq T_{transition}] + f(t - T_{transition}) + \gamma \cdot X_t + \epsilon_t$$

Where:
- $Y_t$ = weekly enforcement action count (or daily dummy for any filing)
- $T_{transition}$ = Chair transition date
- $f(\cdot)$ = local polynomial in running variable (calendar time)
- $X_t$ = controls (fiscal year dummies, market conditions)

For stock-market outcomes:
$$CAR_{i,w} = \alpha + \beta_1 \cdot \text{Surge}_{w} + \beta_2 \cdot \text{Vacuum}_{w} + \gamma \cdot X_{i,w} + \epsilon_{i,w}$$

Where CARs are cumulative abnormal returns around enforcement action filings for firm $i$ in week $w$.

## Data Sources and Fetch Strategy

1. **SEC Enforcement Actions:** sec-api.io API for litigation releases and administrative proceedings. Confirmed 10,000+ actions. Supplement with Cornerstone Research annual reports for aggregate counts and SEED database for academic-quality data.

2. **CRSP Daily Stock Returns:** For CARs around enforcement events. ~4,000 public companies in SEC jurisdiction.

3. **Stanford Securities Class Action Clearinghouse (SCAC):** Class action filings data from securities.stanford.edu. Public, well-maintained.

4. **Audit Analytics / AAERs:** Financial restatements from the AAER dataset (4,278 AAERs, 1982-2021, USC hosted). Public.

5. **Chair Transition Dates:** Hand-coded from SEC website. 6 exact dates.

### Fetch Order
1. SEC enforcement data (sec-api.io) — primary outcome
2. Chair transition dates — treatment variable
3. CRSP stock returns — secondary outcome (if accessible)
4. Stanford SCAC — secondary outcome
5. AAER — robustness/mechanism

### Fallback Strategy
- If sec-api.io requires paid access → use SEC EDGAR full-text search for litigation releases
- If CRSP not available → use Yahoo Finance daily returns for S&P 500 firms
- If SCAC down → use Federal court docket data (PACER) as proxy

## Key Risks
1. **Few transitions (6):** Mitigated by daily/weekly unit of observation within each transition window, providing hundreds of observations per transition
2. **Confounding events:** Market crashes, legislative changes near transition dates. Use fiscal-year FE and market controls
3. **Mechanical correlation:** FY boundaries coincide with some transitions (Oct 1). Test with calendar-month dummies
