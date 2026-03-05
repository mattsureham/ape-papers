# Conditional Requirements

**Generated:** 2026-03-05T19:14:30.545492
**Status:** RESOLVED

---

## SYNTHESIS OF MODEL FEEDBACK

**Key disagreement:** Gemini argues local weather is already exogenous, making the Bartik "over-engineered." GPT and Grok endorse the Bartik but flag exclusion restriction concerns (national salience confounds).

**Resolution — Hybrid Design:**
1. **Primary specification:** Reduced-form OLS with local weather anomalies (rainfall/temperature deviations from long-run mean). Weather is plausibly exogenous, so this is clean.
2. **Bartik as mechanism test:** Interact local weather shocks with pre-period agricultural crop shares. This tests whether states more economically dependent on weather-sensitive agriculture show amplified belief updating — isolating the **economic exposure channel** from pure experiential salience.
3. **Full Bartik IV reported as robustness** — instrumenting actual weather with crop-share-weighted national weather, for completeness.

This addresses all three models: Gemini gets the clean reduced-form; GPT/Grok get the shift-share mechanism test; the paper contributes both an OLS "does it happen?" and a Bartik "is it the economic channel?"

---

## When the Monsoon Fails — GPT-5.2 Conditions

### Condition 1: a strong first stage

**Status:** [x] RESOLVED

**Response:** The primary specification is reduced-form OLS (no first stage needed). The Bartik IV is reported as a mechanism test alongside, where first-stage F-stats will be reported and weak-IV diagnostics (Anderson-Rubin confidence sets) will be provided. If the first stage is weak, we interpret the Bartik as suggestive and lean on the OLS.

### Condition 2: a convincing argument/diagnostics that national salience doesn't drive the reduced form

**Status:** [x] RESOLVED

**Response:** Three strategies: (a) Month-year fixed effects absorb national-level climate salience shocks (media coverage, COP events, etc.), so the reduced form exploits within-month cross-state variation; (b) Placebo outcomes — search interest for non-climate topics (e.g., "cricket," "Bollywood," "election") should show zero effect of weather anomalies; (c) The Bartik interaction term directly tests whether agricultural exposure amplifies the effect — if national salience drove everything, the interaction would be zero.

### Condition 3: a clear interpretation focusing on "attention" vs "belief" with persistence tests

**Status:** [x] RESOLVED

**Response:** Google Trends measures climate **attention** (information-seeking). WVS measures stated **beliefs**. We frame the paper as studying both — weather → attention (Google Trends, high frequency) → beliefs (WVS, cross-section). Persistence tests: estimate effects at 1, 3, 6, and 12 months post-shock using distributed lag models. This directly tests Egan and Mullin's (2012) finding of rapid decay in US.

---

## Gemini 3.1 Pro Conditions

### Condition 1: dropping the Bartik instrument to use local weather shocks directly

**Status:** [x] RESOLVED

**Response:** Accepted. The primary specification uses local weather anomalies directly with state + time FE. The Bartik is retained as a secondary mechanism test (interaction of weather × agricultural share), not as the primary identification. This addresses Gemini's valid point that weather is naturally exogenous.

### Condition 2: validating Google Trends for Hindi/regional languages

**Status:** [x] RESOLVED

**Response:** We search for climate-related terms in both English ("global warming," "climate change") and Hindi ("जलवायु परिवर्तन," "ग्लोबल वार्मिंग"). We also test terms in regional languages for major states (Tamil, Telugu, Bengali, Marathi). We acknowledge that Google Trends captures internet-using populations (disproportionately urban, educated, English-speaking) and discuss this limitation. We test heterogeneity by state internet penetration rates.

---

## Grok 4.1 Fast Conditions

### Condition 1: robust weak IV F-stats >10

**Status:** [x] RESOLVED

**Response:** The Bartik IV specification reports first-stage F-statistics with Kleibergen-Paap and effective F-statistics (Olea-Pflueger). If F < 10, we report Anderson-Rubin confidence sets and emphasize the OLS reduced-form as primary. The paper does not depend on the IV being strong.

### Condition 2: placebo tests for non-agricultural outcomes

**Status:** [x] RESOLVED

**Response:** We test Google Trends search interest for non-climate topics (cricket, Bollywood, election, inflation) using identical specifications. These should show zero effects if the design captures climate-specific attention rather than general search activity.

### Condition 3: WVS state sample boosts

**Status:** [x] RESOLVED

**Response:** We acknowledge WVS sample size limitations (1,500-3,000 per India wave, ~50-100 per state). The WVS analysis is framed as a **validation exercise** for the Google Trends primary analysis, not the main identification. We pool all India waves and estimate cross-sectional regressions with state-level weather exposure.

---

## Verification Checklist

- [x] All conditions above are marked RESOLVED
- [x] Evidence/plans provided for each resolution
- [x] This file is ready for commit

**RESOLVED — Proceed to Phase 4**
