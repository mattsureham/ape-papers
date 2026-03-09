# Research Ideas

## Idea 1: Market Discipline and Mining Safety — Stock Market Contagion from Tailings Dam Failures
**Policy:** The Global Industry Standard on Tailings Management (GISTM), adopted August 2020 by UNEP/PRI/ICMM, backed by $25 trillion investor coalition. Tests whether voluntary standards reduce systemic risk pricing in mining stocks. Pre-GISTM: no coordinated global standard. Post-GISTM: firms face disclosure requirements and engineering mandates.
**Outcome:** Cumulative abnormal returns (CARs) for peer mining firms following tailings dam failures worldwide (1970-2025). Uses market model with [-250,-30] estimation window and [-1,+5] event window. Stock return data from Yahoo Finance for ~50-80 publicly traded global mining firms.
**Identification:** Event study methodology — tailings dam failures are plausibly exogenous shocks to peer firms' stock prices in the short run. Cross-sectional regressions on CARs exploit within-event variation: firms with tailings dams vs. without (built-in placebo), same-commodity vs. cross-commodity peers, pre-GISTM vs. post-GISTM regime. Placebo tests using pseudo-random event dates and non-mining firms.
**Why it's novel:** No systematic global study of stock market contagion from tailings dam failures exists. Kowalewski & Spiewanowski (2020) cover potash only. Pereira et al. (2024) compare just two Brazilian events. Nobody has tested whether the GISTM reduced contagion — the key market discipline question.
**Feasibility check:** Confirmed: WISE database has 300+ events globally. Yahoo Finance provides free daily stock data for all major mining firms. Global Tailings Portal (tailing.grida.no) has 1,800+ geocoded facilities with company linkages. GISTM adoption date (Aug 2020) is well-defined. N = 100+ events × 50+ peer firms = thousands of firm-event observations.

## Idea 2: Environmental Justice and Tailings Dam Siting — Who Bears the Risk?
**Policy:** US tailings dam siting decisions and regulatory oversight across communities with different demographic profiles. Tests whether tailings facilities are disproportionately located near minority/low-income communities.
**Outcome:** Census tract demographics (race, income, education) around geocoded tailings dam locations from the Global Tailings Portal (1,800+ facilities worldwide).
**Identification:** Cross-sectional analysis comparing demographic composition of tracts hosting tailings dams vs. matched comparison tracts. Weaker identification than event study — relies on selection-on-observables.
**Why it's novel:** Nobody has applied the Bullard (1987) / Banzhaf et al. (2019) EJ framework specifically to tailings dams. Nehiba (2026 EPA) studied failure risk factors, not siting equity.
**Feasibility check:** Data available but identification is cross-sectional (weaker). US-only analysis limits N to ~200 facilities.

## Idea 3: Property Value Impacts of Tailings Dam Failures — A US Event Study
**Policy:** Tailings dam failures as environmental shocks to local property markets. Tests the hedonic capitalization of acute mining disasters.
**Outcome:** FHFA county-level house price index or Zillow ZHVI around ~27-34 US tailings dam failure events (1970-2025).
**Identification:** Event study around failure dates. Housing price trajectories before/after failure in affected vs. unaffected counties.
**Why it's novel:** Nobody has done a systematic hedonic study of tailings failures. Greenstone & Gallagher (2008) studied Superfund designation, not acute failure events.
**Feasibility check:** Tight — only ~27-34 US events, many in thin housing markets. FHFA data starts ~1975. Power concerns with modest N.
