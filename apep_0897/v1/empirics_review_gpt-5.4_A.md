# V1 Empirics Check — openai/gpt-5.4 (Variant A)

**Model:** openai/gpt-5.4
**Variant:** A
**Date:** 2026-03-25T11:37:57.548341

---

## 1. Idea Fidelity

The paper only partially pursues the original idea in the manifest, and in the most important respect it departs from it. The core manifest contribution was to use **coal seam depth from USGS NCRDS/USTRAT** as an instrument for the share of production from surface mining, leveraging plausibly exogenous geological variation determined deep in geological time. The paper instead uses the **historical fraction of mines ever opened in a county that were surface mines** as its instrument. That is not a minor implementation change; it materially alters the identification strategy.

This substitution weakens the design in two ways. First, the instrument is no longer clearly exogenous geology. Historical mine type reflects not just seam depth, but also local regulatory history, firm entry, technology adoption, labor relations, transport access, and the timing of county development. Second, it creates a mechanical concern that the instrument embeds the outcome of past economic choices that may themselves have persistent effects on present-day water quality. In other words, the paper has moved from a “nature’s randomizer” design to a “historical equilibrium” instrument, which is much harder to defend.

The paper also omits several key elements anticipated in the manifest that were important for exclusion: controls for **topography/slope/ruggedness**, **coal quality/reserves**, and placebos based on areas where mining ended before modern surface mining technology. The manifest’s strongest feature was an engineering-geology mechanism tied to seam depth thresholds; the current paper asserts that mechanism but does not measure seam depth directly.

## 2. Summary

This paper studies whether surface coal mining causes greater water-quality damage than underground mining in Appalachian counties. Using county-level data on coal production and Water Quality Portal conductance measures, the author instruments the current production-weighted surface mining share with the historical share of mines in the county that were surface operations, and finds that a higher surface-mining share increases stream specific conductance.

The question is important and the paper is clearly written. However, the current empirical design does not yet credibly isolate the causal effect of mining method, mainly because the instrument used in the paper is not plausibly exogenous in the way the paper claims.

## 3. Essential Points

1. **The instrument is not the one that delivers the paper’s identification claim.**  
   The paper repeatedly argues that its variation comes from Carboniferous-era geology, but the actual instrument is the historical share of mines ever opened that were surface mines. That variable is an outcome of economic and institutional history, not a direct measure of seam accessibility. It is therefore vulnerable to omitted variables and to direct persistence: places with many historical surface mines may have higher present conductance because of legacy environmental damage from past surface mining, even holding current surface share fixed. That is a direct violation of the exclusion restriction. To make the paper viable, the author needs either (i) to implement the manifest’s original instrument using seam-depth data, or (ii) to substantially narrow the claims and reconceptualize the design as using historical mining composition, while directly confronting legacy-mining channels.

2. **The exclusion restriction is not adequately addressed, especially given county-level aggregation.**  
   Even if seam depth were used, geology may affect water quality through channels other than mining method: hydrology, rock chemistry, stream gradients, and the location of monitoring stations. With the current historical-share instrument, these concerns are compounded. The placebo on non-coal counties is not persuasive because the instrument is not naturally defined there in the same way, and the paper does not actually report a regression-based placebo coefficient. More importantly, showing that coal counties have higher conductance than non-coal counties is not a placebo test of exclusion. The paper needs direct tests and controls for terrain, watershed structure, baseline hydrochemistry, coal rank/sulfur, and mining legacy, and ideally a design closer to watershed boundaries than counties.

3. **The empirical implementation does not yet match the research question tightly enough.**  
   The research question is about the environmental wedge between surface and underground mining, but the outcome is county-average conductance pooled over many stations and years, while treatment is county-level current production share. This introduces substantial spatial mismatch: water contamination is watershed-specific, while county boundaries do not align with drainage basins; counties with more intensive monitoring may mechanically differ in measured outcomes. The paper should either move to a watershed/station-level design or provide strong evidence that county aggregation does not drive the results. As written, interpretation of the 2SLS estimate as the causal effect of “moving from all-underground to all-surface extraction” is too strong.

## 4. Suggestions

The paper asks a worthwhile question, and I think there is a potentially publishable project here, but it needs a more credible design and a tighter empirical match between treatment and outcome. Below are concrete ways to improve it.

**1. Implement the seam-depth instrument directly.**  
This is the single most important revision. Use the NCRDS/USTRAT drill-hole records to construct county- or watershed-level measures such as: median depth to top of seam, shallowest major seam depth, share of seam observations within 200 feet, or predicted surface-mining feasibility based on overburden thresholds. If multiple seams exist, define exposure using economically relevant seams, perhaps weighted by thickness or reserve potential. A useful first-stage graph would show binned relationships between seam depth and current surface-production share, ideally highlighting the engineering nonlinearity around the surface-mining feasibility threshold. That would make the geology-to-method link transparent and much more credible.

**2. Distinguish geology from mining history.**  
If the author wants to retain the historical mine-type share, it should be reframed as an auxiliary measure or first-stage validation, not the main instrument. For example, show that seam depth strongly predicts historical mine composition and current mine composition. But the causal design should rest on geological variables, not on realized historical mine choices.

**3. Address legacy-mining contamination explicitly.**  
Even with a better instrument, historical surface mining can directly affect present conductance through unreclaimed sites, spoil, and valley fills. That is especially problematic when the current instrument is based on historical mine types. The paper should therefore construct controls for cumulative historical mining intensity, abandoned mine land exposure, or pre-2010 mine counts/acreage. More convincing still would be a specification where current conductance is related to current surface share while controlling flexibly for cumulative past mining, or a panel that uses changes over time in production composition. If the causal estimand is “current surface mining relative to underground,” legacy stock effects have to be separated from contemporaneous flow effects.

**4. Move the analysis closer to the hydrologic unit.**  
Counties are administratively convenient but environmentally coarse. Water-quality impacts travel along streams and watersheds, not county lines. The paper would be much stronger at the HUC-8/HUC-10 or monitoring-station level. One possible design: assign each station upstream mining exposure using mine coordinates and watershed flowlines, then instrument upstream surface-mining share with upstream seam-depth measures. Even a simpler watershed-level analysis would be a meaningful improvement over county means.

**5. Improve the outcome construction.**  
County averages of all conductance readings from 2005–2023 are likely sensitive to extreme observations, monitoring frequency, and agency-specific sampling practices. I recommend:  
- restricting the outcome period to align with the treatment period;  
- using median conductance, station-level means, and log conductance as standard alternatives;  
- weighting counties by number of stations or using station-level regressions with county/watershed treatment assignment;  
- reporting how many stations and readings each county contributes;  
- testing whether the instrument predicts monitoring intensity, number of stations, or station placement.

**6. Strengthen the first-stage and reduced-form presentation.**  
The current tables are hard to interpret, and some narrative descriptions do not match the reported coefficients. For example, Table 2 reports very imprecise 2SLS estimates, and Table 1’s reduced forms are mostly insignificant. The text nonetheless speaks as if the main effect is established. Please present:  
- the first-stage coefficient, standard error, and effective F-statistic in the preferred specification;  
- a clear reduced-form estimate;  
- a scatter/bin plot of treatment on instrument;  
- a map or histogram of the instrument;  
- confidence intervals prominently, not just point estimates.  
Given only seven state clusters, standard clustered inference is fragile. Wild-cluster bootstrap or randomization inference at the state level would be more appropriate.

**7. Revisit the balance and placebo exercises.**  
The balance table currently shows the instrument is strongly correlated with population, income, poverty, and production. That is not a reassuring finding; saying these are “absorbed by controls” is not enough. The relevant concern is correlation with unobservables, and strong imbalance makes that concern more serious, not less. If using seam depth, balance should improve; if it does not, the paper needs to say so and deal with it directly. Better placebo tests would include:  
- outcomes plausibly unrelated to mining method but measured similarly;  
- pre-period water quality where available;  
- counties/watersheds where mining ceased before the rise of modern surface mining;  
- outcomes upstream versus downstream of mines.  
For non-coal places, run the exact same regression and report the coefficient; do not just compare levels across coal and non-coal counties.

**8. Add geological controls if using a geology-based IV.**  
The manifest rightly anticipated this. Include terrain ruggedness, slope, elevation, stream density, watershed area, baseline hydrogeology, coal rank, sulfur content, and reserves. A good strategy would be to show that seam depth still predicts surface mining conditional on these variables, and that the reduced form is robust to them.

**9. Tighten the interpretation of the estimand.**  
The paper often interprets the coefficient as if it applies to moving an entire county from all-underground to all-surface extraction. In practice, the IV estimate is a local average treatment effect for counties whose mining method margin is shifted by geological accessibility. The paper should be explicit about that and avoid policy statements that imply universal substitution from underground to surface or vice versa.

**10. Moderate the rhetoric.**  
Claims such as “first causally identified estimate” and “Carboniferous randomization” are too strong for the current design. A more measured presentation would help. The paper is strongest as a promising attempt to exploit geological constraints to identify method-specific mining externalities; it is not yet a completed causal design.

Overall, I like the question and the intended geological logic. But the current version does not successfully execute the identification strategy it advertises. If the author can replace the historical mine-share instrument with direct seam-depth measures and bring the analysis closer to hydrologic exposure, the paper would become much more compelling. As it stands, I am not convinced the estimated effect can be interpreted causally.
