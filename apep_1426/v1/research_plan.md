# Research Plan: The Visibility Deterrent — TV News Amplification and Workplace Safety

## Research Question

Does organic television news coverage of workplace safety incidents deter OSHA violations at nearby establishments? If so, how much of enforcement deterrence operates through media visibility rather than direct regulatory contact?

## Motivation

Johnson (AER 2020) established that OSHA press releases about enforcement actions deter violations at neighboring firms. But press releases are a narrow, agency-controlled channel (~200/year). Organic TV news coverage of workplace incidents — plant explosions, mine collapses, chemical spills — occurs in thousands of broadcasts annually and reaches far larger audiences. If this organic coverage independently deters violations, then enforcement effectiveness depends on the media environment. The 25% decline in local TV news employment since 2008 may be invisibly eroding workplace safety — a regulatory externality of media consolidation that no one has measured.

**Named empirical object: the "visibility deterrent"** — the causal effect of media exposure on regulatory compliance, operating through employer awareness of enforcement consequences rather than through direct regulatory contact.

## Identification Strategy

### Design: Instrumental Variables (Competing-News)

**Endogenous variable:** Weekly TV news coverage intensity of workplace safety topics in DMA $d$ at week $t$, measured from Internet Archive TV News Closed Caption Corpus.

**Instrument:** Volume of non-safety mega-event TV coverage (Olympics, Super Bowl, presidential impeachment proceedings, major natural disasters) that mechanically crowds out safety coverage. Following Eisensee and Strömberg (2007), pre-scheduled events that consume broadcast time exogenously reduce the airtime available for workplace safety stories.

**Exclusion restriction:** The Olympics do not make factories more dangerous; they make existing violations less visible. Pre-scheduled entertainment and political spectacles shift news allocation without affecting workplace hazard conditions. We test this by showing no effect on actual workplace hazard conditions (inspection-initiated complaints, referrals) during high-competing-news weeks.

**Outcome:** DMA-week violation rates from OSHA inspection data (DOL Enforcement Data Catalog). Primary outcome: total serious violations per 100 establishments. Secondary: injury/illness rates from OSHA ITA 300A (2016+).

### Key Design Parameters
- **Unit of observation:** DMA × week
- **Treatment:** Continuous — TV segments mentioning workplace safety keywords per DMA-week
- **Instrument:** Count of segments on pre-scheduled mega-events (Olympics, Super Bowl, impeachment, elections) per week
- **Sample period:** 2010-2023 (intersection of TV caption data and OSHA inspection data)
- **N treated units:** ~210 DMAs with measurable TV coverage variation
- **Pre-periods:** N/A for IV (not a DiD design); but we show balance across high/low competing-news weeks
- **Clustering:** DMA level (210 clusters)

### First Stage Story
In weeks with mega-events (Olympics, Super Bowl), total broadcast minutes are fixed but safety coverage gets crowded out. We expect a strong negative first stage: more mega-event coverage → less safety coverage. The first stage is mechanical (zero-sum broadcast allocation) rather than behavioral.

### Reduced Form
The reduced form directly tests: do OSHA violations increase in weeks when mega-events crowd out safety news? This is itself a policy-relevant estimand — it measures the deterrence value of organic media coverage.

### Estimand
The IV identifies a Local Average Treatment Effect (LATE) for the margin of safety coverage that is displaced by competing news. This is the deterrence effect of the marginal TV segment about workplace safety — the coverage that would have aired but was crowded out by the Olympics.

## Primary Specification

**Second stage:**
$$\text{Violations}_{dt} = \alpha + \beta \cdot \widehat{\text{SafetyCoverage}}_{dt} + \mathbf{X}_{dt}\gamma + \delta_d + \mu_t + \varepsilon_{dt}$$

**First stage:**
$$\text{SafetyCoverage}_{dt} = \pi_0 + \pi_1 \cdot \text{MegaEventCoverage}_{t} + \mathbf{X}_{dt}\phi + \delta_d + \mu_t + \nu_{dt}$$

Where:
- $d$ indexes DMAs, $t$ indexes weeks
- $\delta_d$ = DMA fixed effects (absorb time-invariant DMA characteristics)
- $\mu_t$ = year-quarter fixed effects (absorb secular trends in enforcement)
- $\mathbf{X}_{dt}$ = time-varying controls (DMA employment, industry composition)
- Standard errors clustered at DMA level

## Expected Effects

- **First stage:** Strong negative — mega-events crowd out safety coverage ($\pi_1 < 0$, F > 10)
- **Main effect:** Negative $\beta$ — more safety coverage reduces violations (deterrence)
- **Magnitude benchmark:** Johnson (2020) found press releases reduce violations by 2-4% at neighboring firms. Organic TV coverage reaches more people but is less targeted, so we expect a smaller per-segment effect but larger aggregate effect.

## Heterogeneity (Pre-Registered)

1. **Union density:** Johnson found press releases only deter in unionized areas. Does TV break this pattern? (Union workers may be more attentive to safety news.)
2. **Network type:** Fox News vs. CNN/MSNBC market share. Does the ideological framing of safety coverage matter?
3. **Penalty severity:** High-penalty vs. low-penalty OSHA cases covered. Does severity of the televised case matter for deterrence?
4. **Industry hazard:** High-hazard (construction, manufacturing) vs. low-hazard industries.

## Data Sources

| Dataset | Source | Format | Access |
|---------|--------|--------|--------|
| OSHA Inspections | DOL Enforcement Data Catalog | Bulk CSV | Public, no key |
| OSHA ITA 300A | dataset_0003 | CSV | Public, no key |
| TV News Captions | Internet Archive TV News | API + bulk | Public, no key |
| notnews corpus | Harvard Dataverse | Compressed CSV | Public, no key |
| GDELT GKG | BigQuery | SQL query | ADC (scl-librechat) |
| County-DMA Crosswalk | Census/Nielsen | CSV | Public |
| BLS QCEW | BLS | CSV | Public, no key |

## Data Fetch Strategy

1. **OSHA inspections:** Download bulk CSV from DOL Enforcement Data Catalog (osha_inspection.csv, osha_violation.csv). ~2M inspections, ~4M violations.
2. **TV news captions:** Query Internet Archive TV News API for segments mentioning OSHA/workplace safety keywords. Also download notnews processed corpus from Harvard Dataverse for validation.
3. **Competing-news instrument:** Query GDELT BigQuery GKG for weekly total article counts and mega-event article counts (Olympics, Super Bowl, impeachment, elections).
4. **County-DMA crosswalk:** Download from Census or USDA ERS.
5. **Employment controls:** BLS QCEW for DMA-level employment by industry.

## Kill-Shot Concerns

1. **Weak first stage:** If mega-events don't actually crowd out safety coverage at the DMA-week level, the IV fails. Mitigation: verify first-stage F > 10 before proceeding.
2. **Exclusion violation:** Mega-events could affect workplace behavior directly (e.g., Super Bowl parties → Monday absenteeism → fewer inspections). Mitigation: show no effect on OSHA-initiated inspections (programmed, referrals) which are not complaint-driven.
3. **Measurement error:** TV caption keyword matching is noisy. A segment mentioning "OSHA" in passing vs. a 5-minute feature story are treated equally. Mitigation: weight by segment duration; validate against manual coding of a subsample.
4. **Geographic mismatch:** TV news is broadcast at the DMA level but enforcement is establishment-level. Aggregation to DMA-week may wash out effects. Mitigation: this is the natural level of TV exposure — the question is whether DMA-level media environment affects DMA-level violation rates.

## Falsification Tests

1. **Placebo outcomes:** Effect on non-safety OSHA outcomes (wage/hour violations) — should be null.
2. **Placebo treatment:** Coverage of non-enforcement topics (weather, sports) on violation rates — should be null.
3. **Pre-event trends:** No differential violation trends in DMAs that will vs. won't receive heavy mega-event coverage.
4. **Inspection composition:** No effect on OSHA-initiated (programmed) inspections — only complaint-driven inspections should respond to news.
