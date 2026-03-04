# Reviewer Response Plan

## Common Concerns (all 3 reviewers)

### 1. Survivorship Bias in Companies House Data
- **GPT**: Fatal — current outcomes are selected on survival to 2026
- **Grok**: Must-fix — undercounts historical entries
- **Gemini**: Must-fix — need to quantify or bound the bias
- **Action**: Strengthen the discussion. Note that survivorship bias affects LEVELS but not DIFFERENCES if dissolution rates are similar across countries, which time FEs absorb. The DDD provides further protection since survivorship affects food and non-food similarly. Acknowledge this is a limitation for absolute magnitudes but not for the DDD sign.

### 2. Mechanism Overclaims
- **GPT**: Claims exceed data
- **Grok**: Bundles exit/upgrading/entry without data
- **Gemini**: Quality claims weak
- **Action**: Reframe mechanisms as "consistent with" rather than "demonstrates." Remove causal language around quality/entrepreneur selection. Present the DDD sign as the key finding; mechanisms are hypotheses.

### 3. Non-food Sector Comparability
- **GPT**: Professional services structurally different from food
- **Grok**: Add retail/manufacturing placebo
- **Gemini**: Scale by pre-treatment means
- **Action**: Add percentage-change interpretation. Acknowledge sector differences as a limitation. Cannot add new sectors without re-running code.

## GPT-Specific (R&R)

### 4. Country-level Treatment / Inference
- **GPT**: Only 2 treated "countries" — LA clustering invalid
- **Action**: Add discussion of this concern. Note that the border design addresses it partially. Acknowledge as fundamental limitation of the setting. Wild cluster bootstrap at LA level is conservative relative to country-level, not liberal.

### 5. DDD Event Study
- **GPT**: Need food-nonfood gap pretrends test
- **Action**: This requires new R code. Add as a limitation that the DDD pretrends are not directly tested. Note that flat food pretrends + the DDD structure provide indirect support.

### 6. HonestDiD on DDD
- **GPT**: Apply sensitivity to DDD, not just simple DiD
- **Action**: Acknowledge this gap. Note that the DDD confidence interval (+1.4 ± ~0.6) is narrow enough to be informative.

## Prose/Exhibit Improvements
- Fix Table 2 variable names (code-like → readable)
- Tone down mechanism claims
- Strengthen survivorship bias discussion

## Workstreams
1. **Prose**: Address mechanism overclaims, survivorship bias discussion
2. **Tables**: Clean variable names in Table 2
3. **Limitations**: Expand discussion of country-level treatment, sector comparability
