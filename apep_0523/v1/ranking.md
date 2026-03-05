# Research Idea Ranking

**Generated:** 2026-03-05T14:24:16.872341
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Does Taxing Vacant Housing Put Homes on ... | PURSUE (78) | PURSUE (85) | — |
| Did Removing France's Famous Growth Barr... | PURSUE (67) | SKIP (35) | — |
| The Price of an Energy Label: How France... | CONSIDER (62) | CONSIDER (68) | — |
| Low Emission Zones and Urban Property Ma... | CONSIDER (56) | CONSIDER (58) | — |
| Rent Control Returns: The Staggered Expa... | SKIP (49) | SKIP (52) | — |
| Idea 1: Does Taxing Vacant Housing Put H... | — | — | PURSUE (82) |
| Idea 4: Did Removing France's Famous Gro... | — | — | PURSUE (72) |
| Idea 5: Rent Control Returns: The Stagge... | — | — | CONSIDER (65) |
| Idea 2: Low Emission Zones and Urban Pro... | — | — | CONSIDER (58) |
| Idea 3: The Price of an Energy Label: Ho... | — | — | SKIP (52) |

---

## GPT-5.2

**Tokens:** 6943

### Rankings

**#1: Does Taxing Vacant Housing Put Homes on the Market? Evidence from France's 2023 TLV Expansion**
- **Score: 78/100**
- **Strengths:** Large, sharp, plausibly policy-driven expansion with thousands of newly treated communes and a credible universe outcome (DVF transactions) that directly maps to “put homes on the market.” Built-in placebo groups (already-treated; lost-TLV communes) and heterogeneity (touristic vs. tight markets) create a strong internal replication narrative.
- **Concerns:** The key regulated margin is *vacancy*, but DVF only sees *sales*—so you must show bite via intermediate evidence (e.g., vacancy proxies, listing/rental-market indicators, or differential effects by property types most likely to be “kept vacant”). General equilibrium spillovers (displacement of demand/supply to nearby untreated communes) could attenuate or confound commune-level estimates.
- **Novelty Assessment:** **High**. Vacancy taxes are discussed a lot, but credible causal work using a nationwide, sharp expansion + universe transactions is still thin; this is notably less saturated than rent control or standard property-value amenity papers.
- **Top-Journal Potential: High.** If you can document a clear first stage (“vacancy-holding becomes costly → sale/rent market entry rises”) and quantify welfare-relevant margins (supply release vs. price capitalization vs. composition), this has AEJ:EP/top-field upside and an outside shot at top-5 because the design is unusually clean and the policy debate is global.
- **Identification Concerns:** Main threats are (i) differential local housing cycles correlated with the zone classification and (ii) anticipation/strategic timing around the decree. Your already-treated placebo + event-study pre-trends help, but you’ll want strong robustness (donut around announcement, border comparisons, and spillover checks).
- **Recommendation:** **PURSUE (conditional on: demonstrating a “bite” proxy for vacancy; implementing spillover/border checks; showing robustness to COVID/post-COVID housing-cycle heterogeneity).**

---

**#2: Did Removing France's Famous Growth Barrier Work? Firm Size Dynamics After Loi PACTE**
- **Score: 67/100**
- **Strengths:** First-order policy question with a well-known pre-existing distortion (bunching at 49) and a clean, interpretable reform (5-year grace period) that should shift transition hazards; if effects are null/persisting, that’s belief-changing (salience vs. compliance-cost mechanism). Long pre/post horizon is feasible.
- **Concerns:** The “treatment” is not instantaneous—full bite only after 5 years—so naive post-2019 comparisons risk mis-timing, and COVID is a major confound exactly in the early post period. Sirene’s size variable is bracketed, which can blur transitions and reduce power/interpretability (you may need complementary sources with exact employment counts).
- **Novelty Assessment:** **Medium-High.** The 50-employee threshold is heavily studied, but a credible ex post evaluation of PACTE is still relatively scarce; novelty comes from testing whether a famous distortion actually relaxes when the rule is softened.
- **Top-Journal Potential: Medium.** A top-field journal could like this if you nail timing (hazard/event-study aligned to the 5-year rule) and provide a mechanism test (persistent bunching implies salience/fear rather than static costs). Top-5 is less likely unless you can generalize to “why size-dependent regulation distorts firm dynamics” with unusually sharp evidence.
- **Identification Concerns:** Policy coincides with COVID and other contemporaneous business-policy changes; also, firm growth is highly endogenous to sectoral shocks. A credible design needs careful cohort construction (firms near threshold pre-reform), sector×time controls, and ideally a complementary placebo threshold that truly has no policy bite.
- **Recommendation:** **CONSIDER (upgrade to PURSUE if you can: align identification to the 5-year implementation logic; obtain/merge exact employment data or validate bracket transitions; show results are not COVID-driven).**

---

**#3: The Price of an Energy Label: How France's Rental Ban Announcements Capitalized into Property Values**
- **Score: 62/100**
- **Strengths:** The “label becomes regulation” twist is genuinely interesting: moving from information to a binding constraint should generate strong capitalization and renovation incentives. Multiple dates (2021 announcement; 2023 rent freeze; 2025 ban) allow a richer event structure than the typical energy-label paper.
- **Concerns:** The proposed shift-share (exposure = share of G/F/E) is vulnerable: DPE composition is correlated with unobserved housing quality, local income trends, and differential post-2021 demand shocks—exactly what can generate spurious “capitalization.” Also, commune-level exposure is coarse; within-commune sorting and compositional changes in transactions can mechanically move average prices.
- **Novelty Assessment:** **Medium.** Energy-label capitalization is a well-developed literature; what’s newer is the *rental-ban* regulatory bite in a large country, but the question will still be compared to many EPC/DPE studies.
- **Top-Journal Potential: Medium-Low.** Could be a strong top-field paper if you convincingly isolate regulation from confounding and show a mechanism chain (ban risk → renovation investment → price changes by segment). For top-5, editors will likely demand more granular identification (property-level DPE, sharp discontinuities, or institutional discontinuities) than commune shift-share.
- **Identification Concerns:** Exposure shares are plausibly endogenous and may change with measurement (DPE coverage expands over time). You’ll need Goldsmith-Pinkham-style diagnostics, stability checks on shares, and ideally micro-level linkage (transaction-level DPE) or quasi-random variation in inspection/retrofit programs to strengthen the design.
- **Recommendation:** **CONSIDER (conditional on: moving toward property-level DPE linkage or a sharper design; implementing strong share-IV diagnostics and composition adjustments).**

---

**#4: Low Emission Zones and Urban Property Markets: Spatial Evidence from France's ZFE Expansion**
- **Score: 56/100**
- **Strengths:** A boundary-based design is a natural fit for a geographically defined policy, and DVF micro-geo data can support tight spatial comparisons. The welfare question is legible (amenity gains from cleaner air vs. mobility/access costs), and “green gentrification” is a compelling mechanism narrative if you can observe sorting.
- **Concerns:** ZFE boundaries are not randomly placed—they often coincide with dense, already-trending neighborhoods—and cities choose timing/stringency endogenously. Without very strong local trend controls (and perhaps only using narrow boundary bands), you risk re-labeling neighborhood change as policy effect; also, you may lack the demographic microdata needed to credibly show “gentrification” rather than pure price capitalization.
- **Novelty Assessment:** **Medium.** LEZ/ZFE impacts on air quality are well studied; property-value capitalization is less saturated but not new (related literatures on congestion charges, clean-air regs, and amenity capitalization).
- **Top-Journal Potential: Low-Medium.** Likely publishable in a good field journal if executed tightly, but top-5 excitement requires unusually compelling quasi-random boundary variation or a strong general welfare decomposition—otherwise it risks reading as “competent amenity capitalization.”
- **Identification Concerns:** Diff-in-disc at boundaries hinges on no differential pre-trends inside vs. outside near the boundary; this is frequently violated in urban settings. You’ll want boundary-segment fixed effects, flexible distance-to-boundary trends, and pre-policy event studies within narrow bands.
- **Recommendation:** **CONSIDER (only if: you can obtain high-quality official boundary shapefiles + precise implementation/enforcement dates; and you commit to narrow-band boundary designs with strong pre-trend diagnostics).**

---

**#5: Rent Control Returns: The Staggered Expansion of France's Encadrement des Loyers**
- **Score: 49/100**
- **Strengths:** High policy salience, and Paris’s on–off–on pattern is intrinsically appealing as a “reversal” test that could, in principle, be very persuasive. If you can tie to mechanisms (rental supply, conversion, quality, misallocation), the topic is inherently consequential.
- **Concerns:** This is a heavily mined topic internationally, so the bar for novelty is high; France alone may not clear it unless the reversal is exploited cleanly. Data constraints are severe: DVF 2020–2025 misses the key 2015 adoption and 2017 removal windows unless you secure earlier DVF+, and the number of treated cities is small—making inference fragile and sensitive to specification/controls.
- **Novelty Assessment:** **Low.** Rent control is among the most saturated policy evaluation literatures; “France adds another setting” is not enough unless the reversal plus French institutional details generate a new mechanism or overturn a consensus.
- **Top-Journal Potential: Low.** Without long pre-period data spanning the Paris reversal and a convincing mechanism chain beyond prices (e.g., quality degradation, misallocation, shadow rents), this is unlikely to be seen as field-shaping.
- **Identification Concerns:** Few treated clusters + endogenous adoption (cities that choose rent control differ systematically) + COVID-era housing disruptions create a triple threat. A credible design likely needs a Paris-focused reversal with long pre-trends and/or a synthetic-control style design with transparent sensitivity.
- **Recommendation:** **SKIP (unless you can: secure pre-2015 DVF+/notarial data; focus tightly on the Paris reversal; and measure mechanisms beyond transaction prices).**

---

### Summary

This is a strong batch in the sense that several ideas use large administrative data and real policy discontinuities, but only **Idea 1 (TLV expansion)** combines high novelty with a large treated sample and clean quasi-experimental timing in a way that could plausibly clear a top-field bar. I would start with **Idea 1 immediately**, and keep **Idea 4 (PACTE)** as the next-best option if you can solve the timing/COVID and measurement issues.

---

## Gemini 3.1 Pro

**Tokens:** 11710

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, focusing on identification viability, data realities, and the empirical patterns that actually drive top-journal publication.

### Rankings

**#1: Does Taxing Vacant Housing Put Homes on the Market? Evidence from France's 2023 TLV Expansion**
- **Score**: 85/100
- **Strengths**: Exploits a massive, sharp policy expansion with universe-level administrative data and built-in placebos (already-treated communes). It addresses a first-order global policy debate with a highly legible causal channel (tax → holding cost → supply release).
- **Concerns**: The post-period is very short (1.5 years); real estate markets are illiquid, and the full supply response may take years to materialize.
- **Novelty Assessment**: High. While vacancy taxes are hotly debated globally, rigorous quasi-experimental evidence using universe transaction data is virtually non-existent.
- **Top-Journal Potential**: High. A top-5 journal would find this exciting because it tests a highly salient policy using a massive scale of data ("universe" admin data) and includes an "opponent-killer" placebo (the 1,100 already-treated communes). If it can precisely bound the supply and price effects, it is a major contribution.
- **Identification Concerns**: Anticipation effects are the main threat (was the August 2023 decree leaked or expected?). Additionally, the short post-window might only capture short-run panic selling rather than long-run equilibrium supply shifts.
- **Recommendation**: PURSUE (conditional on: extending the post-period data as it becomes available; verifying the exact timing of tax liability vs. transaction dates).

**#2: The Price of an Energy Label: How France's Rental Ban Announcements Capitalized into Property Values**
- **Score**: 68/100
- **Strengths**: Tests a radical climate policy that converts an information friction (energy labels) into a hard regulatory constraint (rental ban). The "scarlet letter" mechanism is compelling and has clear welfare implications for the green transition.
- **Concerns**: The proposed commune-level shift-share design is weak and highly vulnerable to endogenous exposure (communes with many G-rated homes are likely poorer or declining).
- **Novelty Assessment**: Medium-High. Capitalization of energy labels is well-studied, but evaluating a hard rental ban based on these labels is a novel, aggressive policy lever.
- **Top-Journal Potential**: Medium-High. If the identification is fixed, this has top-field (AEJ: Policy) potential because it uncovers the hidden costs of green transition policies. However, the currently proposed empirical strategy would be rejected.
- **Identification Concerns**: Severe Goldsmith-Pinkham critique risks on the shift-share design. Because you have property-level transaction data, aggregating to the commune level throws away the best variation; you should use a property-level DiD (e.g., G-rated vs. D-rated within the same neighborhood) to control for local economic trends.
- **Recommendation**: CONSIDER (conditional on: abandoning the commune-level shift-share in favor of a property-level DiD or boundary design).

**#3: Low Emission Zones and Urban Property Markets: Spatial Evidence from France's ZFE Expansion**
- **Score**: 58/100
- **Strengths**: Combines spatial and temporal variation to study a highly salient urban policy, looking beyond standard air quality outcomes to property market capitalization.
- **Concerns**: The spatial boundary design is highly susceptible to SUTVA violations (spillovers), and the small number of pre-2025 treated cities limits statistical power.
- **Novelty Assessment**: Medium. LEZs are heavily studied. While looking at property values and "green gentrification" is slightly fresher, environmental amenities capitalizing into housing is a very crowded literature.
- **Top-Journal Potential**: Low-Medium. It reads as a "competent but not exciting" standard spatial DiD. To hit a top journal, it needs to uncover a substitution/offset that changes how we view LEZs (e.g., proving that pollution is merely displaced to poorer neighborhoods just outside the boundary).
- **Identification Concerns**: Traffic and pollution displacement. Cars that cannot enter the ZFE may park or route just outside the boundary, negatively treating the control group and artificially inflating the DiD estimate.
- **Recommendation**: CONSIDER (conditional on: explicitly modeling spatial spillovers and proving the first-stage air quality/traffic shock).

**#4: Rent Control Returns: The Staggered Expansion of France's Encadrement des Loyers**
- **Score**: 52/100
- **Strengths**: The "on-off-on" reversal in Paris provides a rare natural experiment (de-control) in a literature that usually only studies policy adoption.
- **Concerns**: The proposed dataset (DVF) measures property *sales prices*, not *rents*, meaning the study misses the direct first-stage effect of the policy.
- **Novelty Assessment**: Low-Medium. Rent control is one of the most saturated topics in empirical economics.
- **Top-Journal Potential**: Low. Without rent data to prove the first stage, this will read as incomplete. A top journal will demand to see the full mechanism map (Shock → Rents → Condo Conversions/Sales Prices), which this data cannot provide.
- **Identification Concerns**: The small number of treated clusters (~10 cities) makes standard DiD inference problematic. Furthermore, using sales prices without observing rents makes it impossible to separate anticipation effects from actual capitalization.
- **Recommendation**: SKIP (unless high-quality, granular rental price data can be acquired to prove the first stage).

**#5: Did Removing France's Famous Growth Barrier Work? Firm Size Dynamics After Loi PACTE**
- **Score**: 35/100
- **Strengths**: Attempts to follow up on a famous, top-journal paper (Garicano et al. 2016) by evaluating the removal of the very friction that paper documented.
- **Concerns**: The proposed data has a fatal flaw: Sirene only provides employee size *brackets* (20-49, 50-99), making it impossible to observe the actual bunching at 49 or the precise crossing of the threshold.
- **Novelty Assessment**: High conceptually, but empirically unviable with the proposed data.
- **Top-Journal Potential**: Low. A top journal will immediately reject a threshold/bunching paper that cannot measure the running variable precisely. Furthermore, the 5-year grace period means the true bite of the policy won't be visible until 2024-2025.
- **Identification Concerns**: You cannot study a 50-employee threshold with data that is binned at 50. The transition rate between broad brackets is too noisy and confounded by general firm growth trends to isolate the policy effect.
- **Recommendation**: SKIP (fatal data limitation; requires exact employee counts like DADS/DSN data).

### Summary

This batch contains one outstanding proposal (Idea 1) and one highly promising but methodologically flawed proposal (Idea 3). I strongly recommend pursuing Idea 1 immediately, as it leverages universe-level data to answer a first-order policy question with a clean, defensible design and built-in placebos. Idea 3 should be sent back for a redesign to utilize property-level variation rather than commune-level aggregates, while the remaining ideas suffer from fatal data limitations regarding their primary outcomes (Ideas 4 and 5) or operate in overly saturated literatures without a novel mechanism (Idea 2).

---

## Grok 4.1 Fast

**Tokens:** 6533

### Rankings

**#1: Idea 1: Does Taxing Vacant Housing Put Homes on the Market? Evidence from France's 2023 TLV Expansion**
- **Score**: 82/100
- **Strengths**: Exceptional causal identification with a massive treatment group (2,555 communes), built-in placebos (already-treated and reverse-treated units), long pre/post periods, and universe transaction data enabling precise mechanism decomposition (supply release, price capitalization, composition, construction). Addresses a first-order global policy debate on vacancy taxes with no prior rigorous causal evidence, packaged as a clear causal chain with welfare implications for housing supply.
- **Concerns**: Post-period is relatively short (~6 quarters so far), though ongoing data collection mitigates this; potential for anticipation effects pre-2023 decree, though event studies can test.
- **Novelty Assessment**: Highly novel—vacancy taxes are politically hot (e.g., Vancouver, Barcelona) but lack any quasi-experimental causal evaluations at scale; prior French work (Bono & Trannoy 2012) used weak data/design.
- **Top-Journal Potential**: High. Fits editorial winners: universe-scale admin data (5M+ transactions), tight shock-to-mechanism map (TLV bite → supply/price channels → housing welfare), live global policy stakes, and opponent-killers (already-treated/reverse placebos); could challenge conventional wisdom on tax-induced supply release.
- **Identification Concerns**: Staggered DiD with CS estimator is robust, but needs careful handling of dynamic effects across heterogeneous zones (touristique vs. tendue); commune clustering sufficient given large N.
- **Recommendation**: PURSUE (conditional on: confirming no pre-2023 anticipation via high-freq event study; extending post-period to 2026+)

**#2: Idea 4: Did Removing France's Famous Growth Barrier Work? Firm Size Dynamics After Loi PACTE**
- **Score**: 72/100
- **Strengths**: Leverages universe firm data (Sirene) to causally test a celebrated bunching phenomenon (Garicano et al. 2016) post-reform, with clean triple-diff (treated vs. placebo boundary) and long horizons (6+ years post); could reveal counterintuitive persistence of bunching due to salience, informing labor regulation debates.
- **Concerns**: Categorical size brackets limit precision (no exact counts), and full 5-year grace period effects emerge only post-2024, delaying conclusive results; outcome focuses on transitions rather than employment/welfare.
- **Novelty Assessment**: Moderately novel—pre-reform bunching well-studied, reform theoretically discussed, but no empirical causal evaluation of PACTE's growth effects using firm-level data.
- **Top-Journal Potential**: High. Universe data + boundary test of field puzzle (regulatory thresholds) with substitution discovery potential (grace period offsets vs. persistent kinks); aligns with "niche boundary test" wins if framed as adjudicating cost vs. salience mechanisms.
- **Identification Concerns**: Bracket coarseness may mask transitions; needs robustness to sector/region heterogeneity, as reform is national but firm dynamics vary.
- **Recommendation**: PURSUE

**#3: Idea 5: Rent Control Returns: The Staggered Expansion of France's Encadrement des Loyers**
- **Score**: 65/100
- **Strengths**: Rare Paris on-off-on reversal provides a natural de-control experiment, complementing staggered DiD across ~10 cities; speaks to saturated rent control literature with France-specific variation and potential for price/quantity effects on transactions.
- **Concerns**: Few treated units (~10 cities) risks DiD bias/power issues (below 20-unit threshold); requires pre-2020 DVF data access, and controls may not fully match on housing market trends.
- **Novelty Assessment**: Low to moderate—rent control heavily studied (e.g., Diamond 2019, Autor 2014), but Paris reversal is exceptionally rare and unexploited.
- **Top-Journal Potential**: Medium. Reversal is a strong hook for "internal replication," but topic saturation and standard ATE framing (without deep mechanisms/welfare) read as "competent but not exciting" per editorial patterns.
- **Identification Concerns**: Staggered timing with few clusters vulnerable to heterogeneous trends; synthetic control needed for inference, and COVID confounding in 2020+ post-period.
- **Recommendation**: CONSIDER (conditional on: strong pre-trends and RI diagnostics for few clusters)

**#4: Idea 2: Low Emission Zones and Urban Property Markets: Spatial Evidence from France's ZFE Expansion**
- **Score**: 58/100
- **Strengths**: Combines spatial boundary DiD with staggering for property value capitalization and green gentrification sorting; timely with 2025 expansions, using geocoded DVF for precise within-city variation.
- **Concerns**: Limited pre-2025 implementations (~12 cities) yields low temporal N and power; boundary design assumes no spillovers, and air quality amenity vs. access cost channels hard to separate without pollution data.
- **Novelty Assessment**: Moderate—LEZs well-studied for air quality (e.g., London, Berlin), property effects less so, but spatial capitalization not groundbreaking.
- **Top-Journal Potential**: Low. Lacks universe-scale bite or belief-changing pivot; "broad amenity/cost" diffuse outcomes without tight causal chain, risking "technically competent but unsurprising" rejection.
- **Identification Concerns**: Few treated cities + spatial reliance risks underpowering (below DiD thresholds); unverified boundary data and potential endogenous city selection.
- **Recommendation**: CONSIDER

**#5: Idea 3: The Price of an Energy Label: How France's Rental Ban Announcements Capitalized into Property Values**
- **Score**: 52/100
- **Strengths**: Exploits national announcement with commune exposure for shift-share design, testing capitalization of regulatory "scarlet letters" in a novel ban context; links to DPE open data.
- **Concerns**: Exposure (DPE shares) likely endogenous to local markets, weakening instrument relevance; short post-windows around dates limit power, and no spatial/temporal quasi-experiment.
- **Novelty Assessment**: Low—energy labels studied (e.g., Brounen & Kok 2011), bans add twist but shift-share on announcement capitalization is incremental.
- **Top-Journal Potential**: Low. Shift-share endogeneity risks + missing full announcement pre-period (per appendix losses); no mechanisms or scale to elevate beyond niche capitalization paper.
- **Identification Concerns**: Core threat is endogenous exposure (poor DPE correlates with market conditions); lacks strong diagnostics or placebos, vulnerable to omitted variables.
- **Recommendation**: SKIP

### Summary
This is a strong batch overall, with two ideas (1 and 4) leveraging universe French admin data for clean, novel tests of high-stakes policies—far better than typical proposals. Pursue Idea 1 first for its scale, mechanisms, and global relevance; Idea 4 second as a puzzle-solving complement. The rest suffer from identification/power issues or saturation, fitting ≤65 scores.

