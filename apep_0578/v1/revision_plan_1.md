# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1): MAJOR REVISION

### 1. Inference at wrong level (Must-fix)
**Concern:** Region-level clustering is anti-conservative when treatment is assigned at 6 border segments.

**Response:** We now implement segment-level randomization inference alongside region-level RI. The segment-level RI permutes treatment across border segments (6 treated, 4 control pseudo-segments), preserving the assignment structure. Result: segment-level RI p=0.67, confirming that the naive TWFE estimate is not statistically distinguishable from chance at the correct level of assignment. This is a fundamental finding that we now highlight in the introduction, results, and conclusion. We also added citations to Conley and Taber (2011), Ferman and Pinto (2019), and MacKinnon and Webb (2018) on few-cluster inference.

### 2. CS estimator not aligned with identification (Must-fix)
**Concern:** CS estimate doesn't include country-year controls despite the paper arguing these are essential.

**Response:** We now estimate CS with country indicators as covariates in the DR specification (xformla = ~country_num). Result: ATT = -0.008 (SE = 0.005), essentially identical to baseline CS (-0.007). This indicates the CS estimator is not materially affected by country-level confounding, likely because the DR adjustment already flexibly accounts for group-level differences. Reported in new robustness table and text.

### 3. Within-country identification (Must-fix)
**Concern:** Need event studies and placebos under the credible specification.

**Response:** We now report placebos under country-by-year FE. Timing placebo (2010): resolved (coef -0.008, p=0.24 with C×Y FE vs -0.021, p=0.003 baseline). Border-type placebo: persists (-0.054, p<0.001 with C×Y FE). We transparently report that the border-type placebo persists, indicating structural differences between border and interior regions within country-year cells. We also report border-only + C×Y FE specification (coef +0.057, p<0.001), noting this likely reflects growth differences among the small set of untreated border segments.

### 4. Control group composition (Must-fix)
**Concern:** Interior regions are poor controls; border-only design should be central.

**Response:** We now include border-only + C×Y FE as a specification in Table 5 and discuss it extensively. The positive estimate (+0.057) under this specification, while statistically significant, likely reflects that the few untreated border regions experienced weaker within-country growth. We discuss why no single specification dominates.

### 5. Recalibrate claims (Must-fix)
**Concern:** "Precisely estimated null" overstates what the design can support.

**Response:** Substantially softened throughout. Abstract now says "no robust evidence of large negative effects on annual regional aggregates remains, though modest or localized effects cannot be ruled out." Conclusion acknowledges that costs at higher frequency or for specific subpopulations cannot be detected by annual NUTS3 GDP. Removed "precisely estimated null" language.

### 6-12. High-value improvements and polish
Treatment intensity, harmonized samples, and spillover tests require external data not available in Eurostat; noted as limitations. Literature citations expanded with few-cluster inference papers.

---

## Reviewer 2 (GPT-5.4 R2): MAJOR REVISION

The concerns largely overlap with Reviewer 1. Key unique points:

### Opposite-side exposure
**Concern:** Unclear how regions on opposite side of controlled border are classified.

**Response:** All treated NUTS3 regions are on the "implementing" side of the border only. Regions across the border in neighboring countries are not in our sample (the sample is restricted to the 6 implementing countries + their Schengen neighbors as control border regions). This is clarified in the treatment assignment appendix.

### Spillovers as first-order concern
**Response:** Acknowledged in the discussion. We note that spillovers could bias estimates toward zero (if displaced activity goes to control regions) or in unknown directions (if rerouting changes the spatial distribution of economic activity). Without higher-frequency or individual-level data, we cannot bound these effects.

---

## Reviewer 3 (Gemini): MAJOR REVISION

### Sectoral analysis with C×Y FE
**Concern:** Trade/transport result needs validation against national trends.

**Response:** We acknowledge in the text that country-year FE could not be estimated for the sectoral specification (too few observations per cell). The trade/transport result is now explicitly labeled as exploratory and not used as a headline mechanism claim.

### Clustering sensitivity
**Response:** Addressed via segment-level RI (p=0.67). This is now the primary inference result.

### Commuter-weighted intensity
**Response:** Pre-2015 commuter data is not available at the NUTS3 level from Eurostat. Noted as a valuable direction for future research with specialized data sources.
