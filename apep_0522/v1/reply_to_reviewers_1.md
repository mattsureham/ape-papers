# Reply to Reviewers — Round 1

## Response to All Reviewers: Pre-Trends

All three reviewers identified the pre-existing differential trends as the paper's central identification challenge. We agree this is the most important issue and have addressed it through:

1. **Trend-adjusted specification** (new): We augment the baseline DiD with a linear trend interacted with flood risk. The trend-adjusted treatment effect is 0.045 (SE=0.008), substantially larger than the unadjusted 0.021. The linear trend is negative (-0.005/year), indicating that after detrending, the Flood Re effect is larger, not smaller. This is now reported in Table 4 and discussed in the robustness section.

2. **Honest framing**: We frame the placebo tests as failures of the parallel trends test, not as passing placebos. We explicitly state that the pre-period coefficients are significant and positive.

3. **Dose-response as primary identification**: We emphasize the dose-response specification as the most robust identification strategy, since it exploits within-flood-risk variation and is difficult to explain with generic confounders.

## Response to GPT-5.2 (Reviewer 1)

**1.1 Baseline DiD not credible**: Addressed via trend-adjusted specification. The dose-response is now framed as the primary identification.

**1.2 Treatment timing/anticipation**: We note that the Water Act 2014 announcement creates a potential anticipation window but that event-study coefficients show no sharp break at 2014.

**1.3 EA classification endogeneity**: We use the current EA classification, which is a potential concern. We add a note that the EA RoFRS is based on topographic and hydrological modeling, not historical claims data, reducing the concern about post-treatment updating.

**1.4 DDD imprecision**: Acknowledged as a limitation. The eligibility proxy is noisy and the DDD serves as suggestive rather than definitive evidence. We note that VOA Council Tax data with exact build dates could sharpen this in future work.

**1.5 Composition/sorting**: Valid concern. With postcode sector FE and hedonic controls (type, tenure, new-build), composition changes within sectors are partially controlled. A formal decomposition is beyond the current data structure.

## Response to Grok-4.1-Fast (Reviewer 2)

**Pre-trends**: Addressed as above with trend-adjusted specification.

**Triple-diff strengthening**: Acknowledged as imprecise; framed appropriately in text.

**Placebo interpretation**: Reframed as "consistent with level shift, not divergence" with explicit acknowledgment that placebos are positive and significant.

**Volume/liquidity**: The volume specification with postcode sector FE yields problematic results due to the unbalanced within-sector panel. We describe the volume evidence as descriptive.

**Citations**: Added Kousky and Michel-Kerjan context in the discussion of NFIP parallels.

## Response to Gemini-3-Flash (Reviewer 3)

**Pre-trends**: Addressed via trend-adjusted DiD.

**Eligibility data**: We note EPC certificates as a potential data source for future work to improve the eligibility proxy.

**Extensive margin**: Reported as descriptive given specification challenges.

**Mechanism (subsidy vs. liquidity)**: We strengthen the welfare discussion, noting that if the price increase equals the discounted subsidy value, this reflects capitalization rather than market-failure correction. The dose-response pattern and the fact that effects concentrate in High-risk areas where insurance was genuinely unavailable (not just expensive) supports the market-failure interpretation.
