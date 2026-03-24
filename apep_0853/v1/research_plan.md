# Research Plan: Cottage Food Law Liberalization and Micro-Entrepreneurship

## Research Question
Does removing regulatory barriers to home food production — through state cottage food law adoption and liberalization — increase food micro-entrepreneurship? And does deregulation come at a food safety cost?

## Background
Between 2010 and 2023, all 50 US states adopted or significantly liberalized cottage food laws, which permit individuals to produce and sell certain foods (typically baked goods, jams, pickles) from home kitchens without commercial licensing, health inspections, or facility requirements. The regulatory variation is enormous: Wyoming's 2015 Food Freedom Act allows virtually any food sale with no permit, inspection, or sales cap, while New Jersey maintained a complete prohibition until October 2021. This creates a natural experiment in the regulatory cost of the smallest possible food businesses.

Despite the policy's direct relevance to entrepreneurship, occupational licensing, and food safety — all active research frontiers — there are ZERO economics papers on cottage food laws (confirmed via NBER, IDEAS/RePEc, PubMed).

## Identification Strategy
**Primary:** Callaway-Sant'Anna (2021) staggered DiD, using the year each state first adopted or significantly liberalized its cottage food law as the treatment timing. Never-treated states (those that had cottage food laws before the panel window) serve as the comparison group.

**Event study:** Dynamic treatment effects to assess pre-trends and the timing of entry responses.

**Continuous treatment:** A permissiveness index (0-3 scale based on sales cap, product range, venue restrictions) as an intensive margin measure.

**Placebo:** Employer food manufacturing establishments (NAICS 311 from County Business Patterns), which should not be affected by laws targeting unlicensed home producers.

## Expected Effects and Mechanisms
- **Positive effect on nonemployer food establishments:** Removing barriers to entry should increase the number of sole-proprietor food businesses, especially in subcategories like bakeries (NAICS 3118).
- **Revenue effect ambiguous:** Could increase (more legal activity) or decrease (if new entrants are very small).
- **Food safety (CDC NORS):** Theory predicts either null (cottage foods are inherently low-risk: baked goods, jams) or small positive effect on private-home outbreaks.

## Primary Specification
Y_{st} = α_s + α_t + β × CottageFoodLaw_{st} + X_{st}γ + ε_{st}

Where:
- Y_{st}: log nonemployer establishments in NAICS 311 for state s, year t
- CottageFoodLaw_{st}: binary indicator = 1 after state s adopts/liberalizes
- α_s, α_t: state and year fixed effects
- X_{st}: state-level controls (population, income)
- Standard errors clustered at the state level

## Data Sources
1. **Census Nonemployer Statistics API** (2012-2022): State-level NAICS 311 (food manufacturing) nonemployer establishments and receipts. Also NAICS 3118 (bakeries/tortilla) as mechanism.
2. **Census Business Formation Statistics** (2004-2024): State-level business applications (BA) and high-propensity business applications (HBA) for additional entry measure.
3. **County Business Patterns API** (2012-2022): Employer food manufacturing establishments (placebo).
4. **CDC NORS** (National Outbreak Reporting System, 2009-2023): Foodborne outbreaks by state and setting, with private-home outbreaks as food safety outcome.
5. **Treatment coding:** Hand-coded from Institute for Justice reports, Harvard Food Law and Policy Clinic compilations, and state legislative records.

## Exposure Alignment
The treatment—state cottage food law adoption or expansion—directly affects individuals who wish to produce and sell food from home kitchens. The outcome—nonemployer food manufacturing establishments—captures precisely this population: sole proprietors in food production with no paid employees. The unit of analysis (state-year) matches the unit of policy variation (state-level legislation). The comparison group (states with pre-existing cottage food laws or no in-panel policy change) provides the counterfactual trend. Potential misalignment: NAICS 311 nonemployer establishments include non-cottage-food producers (e.g., food trucks, solo caterers), so the estimated effect is an intent-to-treat on the broader category. The placebo on employer establishments (NAICS 311 from CBP) addresses whether broader food manufacturing trends, rather than cottage food entry, drive the result.

## Robustness
- Sun-Abraham (2021) interaction-weighted estimator
- Bacon decomposition to assess TWFE bias
- HonestDiD/Rambachan-Roth sensitivity for pre-trend violations
- Leave-one-state-out (especially Wyoming and NJ)
- Permutation/randomization inference for cluster-level inference
