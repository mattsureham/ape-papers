# Research Plan: The Safety Dividend — Positive Train Control and Railroad Accident Prevention

## Research Question

Does mandated automation technology reduce the specific accidents it targets? We estimate the causal effect of Positive Train Control (PTC) adoption on railroad accidents, exploiting staggered railroad-level implementation of PTC across 68 railroads (2011–2020) mandated by the Rail Safety Improvement Act of 2008.

## Identification Strategy

**Design:** Staggered difference-in-differences at the railroad-by-year level, using Callaway and Sant'Anna (2021) heterogeneity-robust estimator.

**Treatment:** First year a railroad reports PTC presence in FRA Form 54 adjunct signal codes. 68 railroads with 15 adoption-year cohorts (2011–2025) vs. never-PTC railroads.

**Key identification test — built-in placebo:** PTC specifically prevents human-factor accidents (FRA cause codes H*: overspeed, signal violations, switch misalignment). It should NOT prevent track defects (T*), equipment failures (E*), or environmental causes (S*). We estimate effects separately by cause category:
- **Treatment outcomes:** Human-factor accident rate (H-codes)
- **Placebo outcomes:** Non-human-factor accident rate (T/E/S codes)

A finding that PTC reduces H-code accidents but not T/E/S-code accidents strongly supports a causal interpretation.

## Expected Effects and Mechanisms

**Primary mechanism:** PTC enforces speed restrictions, signal compliance, and track authority limits automatically — removing human error from the causal chain for specific accident types.

**Expected direction:** Negative effect on human-factor accidents (H-codes). Null effect on non-human-factor accidents. Possible negative effect on fatalities/injuries conditional on human-factor cause.

**Magnitude prior:** GAO and FRA estimated PTC could prevent ~30% of human-factor main-track accidents. We expect an SDE in the moderate-negative range (−0.05 to −0.15).

## Primary Specification

$$Y_{rt} = \text{ATT}(g,t) \text{ via Callaway-Sant'Anna}$$

Where:
- $Y_{rt}$: accident count (or rate per train-mile) for railroad $r$ in year $t$
- Treatment group $g$: first year railroad $r$ adopts PTC
- Never-treated comparison group: railroads that never adopt PTC through end of sample
- Outcome variants: (1) total accidents, (2) human-factor accidents, (3) non-human-factor accidents, (4) fatalities, (5) injuries, (6) damage costs

**Clustering:** At railroad level (68 clusters). Wild cluster bootstrap for inference given moderate cluster count.

**Event study:** Dynamic ATT estimates for leads/lags to verify parallel pre-trends.

## Data Source and Fetch Strategy

**Primary data:** FRA Form 54 Rail Equipment Accident/Incident Data
- Source: data.transportation.gov (Socrata API)
- Endpoint: `https://data.transportation.gov/resource/85tf-25kj.json`
- Records: ~223,913 (1975–2025)
- No API key required
- Key fields: reportingrailroadcode, date, adjunctname1/adjunctname2 (PTC presence), primaryaccidentcause, accidentcausecode, totalpersonskilled, totalpersonsinjured, totaldamagecost, subdivision

**Treatment identification:** PTC presence identified from adjunct signal system fields (adjunctname1, adjunctname2 containing "PTC" or equivalent codes).

**Panel construction:** Railroad × year panel. Collapse accident records to annual counts by railroad and cause category. Treatment onset = first year PTC appears in adjunct codes for a given railroad.

## Exposure Alignment

**Who is actually treated?** PTC is deployed on specific route segments, not entire railroad networks. A railroad coded as "treated" may have PTC on only a fraction of its route-miles. The treatment indicator (any PTC presence in adjunct codes) captures the extensive margin (has the railroad begun PTC deployment?) but not the intensive margin (what share of the network is covered?). This creates measurement error that biases toward attenuation.

**Exposure mismatch:** Accident counts include incidents on all segments (yards, sidings, branches) regardless of PTC coverage. Since PTC only operates on equipped main lines, the outcome measure is diluted by accidents on non-PTC segments. The null finding on frequency is therefore conservative.

## Robustness Checks

1. Event-study pre-trend visualization (Callaway-Sant'Anna dynamic effects)
2. Placebo cause-category test (T/E/S codes should show null)
3. Leave-one-out: drop each Class I railroad and re-estimate
4. Alternative treatment definition: use FRA PTC implementation milestones instead of adjunct codes
5. Wild cluster bootstrap p-values (Cameron, Gelbach, and Miller 2008)
6. Bacon decomposition to check for problematic 2×2 comparisons
