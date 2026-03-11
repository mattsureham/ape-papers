# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T10:53:26.128461
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 27881 in / 4974 out
**Response SHA256:** d46e7dedcf4b7afd

---

This paper studies whether Erasmus+ student outflows reduce regional human capital in Europe, using a NUTS2 panel (2014–2022) and a shift-share IV based on pre-period bilateral destination shares interacted with destination growth shocks. The question is important and potentially suitable for a broad applied journal: the paper links a major EU policy to regional divergence, uses newly geolocated flow data, and engages with the shift-share identification literature in a transparent way. The paper is also commendably candid that the evidence is “suggestive rather than definitive.”

That said, in its current form the paper is not publication-ready for a top field or general-interest journal. The central empirical design does not yet support the strength of the causal claim, and several inference/reporting issues need to be resolved before the estimates can be interpreted with confidence. Most importantly: (i) the treatment is contemporaneous while the outcome is a stock outcome with inherently lagged adjustment; (ii) the identifying variation appears to come largely from cross-country differences rather than within-country regional exposure; (iii) the shift-share IV fails its own preferred randomization-inference diagnostic; and (iv) some key reported uncertainty measures and specification counts are internally inconsistent. My recommendation is therefore major revision.

## 1. Identification and empirical design

### A. The core timing mismatch is serious
The paper’s main estimating equation relates the contemporaneous annual outflow rate of 20–29 year-olds to the contemporaneous tertiary share of 25–34 year-olds (\S\ref{sec:strategy}, “Treatment Timing Caveat”). The paper itself acknowledges this as a limitation, but it is more than a caveat: it goes to the meaning of the coefficient.

The stated mechanism is that students participate around ages 20–24, then some do not return, and this later affects the stock of tertiary-educated 25–34 year-olds. That is a distributed-lag cohort process. A contemporaneous annual flow regressor is therefore not naturally interpretable as the causal dose affecting a stock outcome in the same year. The current design risks picking up correlated regional/country trends in education and migration rather than Erasmus-induced non-return.

This issue matters especially because the estimated magnitude is much larger than the paper’s own mechanical benchmark in \S\ref{sec:discussion}. The paper recognizes this and offers multiplier interpretations, but without a dynamic design these remain speculative.

**Bottom line:** the contemporaneous flow-on-stock specification is not convincing as a primary causal design. A credible revision would need a lag structure or cohort-linked exposure design.

### B. The identifying variation seems mostly cross-country, not within-country
The most damaging result in the paper is the attenuation to essentially zero after adding country-by-year fixed effects (Appendix Table \ref{tab:robustness}, col. 5; discussed in \S\ref{sec:robustness} and \S\ref{sec:discussion}). This indicates that the baseline result is largely driven by differences across countries over time, not within-country differences across regions exposed to different destination shocks.

For the paper’s central claim—regional human capital divergence due to Erasmus-induced mobility—this is a major problem. If the coefficient vanishes once national shocks are absorbed, then a plausible interpretation is that the baseline specification is capturing country-level divergence (e.g., Romania/Poland/Baltics vs. Germany/Netherlands) correlated with Erasmus intensity, rather than causal region-level effects of Erasmus outflows.

The paper is transparent about this, which is good. But the implication is stronger than the manuscript currently allows: it substantially undermines the causal interpretation of the baseline IV estimate.

### C. The shift-share IV is not yet convincingly justified
The paper tries to position the design under both Borusyak-Hull-Jaravel (BHJ) and Goldsmith-Pinkham-Sorkin-Swift (GPSS) interpretations. That is sensible in principle. In practice, however, the evidence currently weakens both stories.

1. **BHJ / shock-based interpretation:**  
   The randomization inference (RI) p-value of 0.446 (\S\ref{sec:robustness}) means the actual estimate is not unusual relative to permuted destination shocks. By the paper’s own account, this means the quasi-random shock component is not doing the identifying work. For a shock-based shift-share argument, this is very problematic.

2. **GPSS / share-based interpretation:**  
   If the identifying content instead comes from pre-period bilateral shares, then those shares must be defended as exogenous to subsequent human-capital trends. The current defense is thin. The paper argues the shares reflect historical institutional agreements, but those agreements can still be correlated with durable region characteristics and trajectories: university quality, language compatibility, historical migration corridors, western orientation, field composition, and broader convergence/divergence paths. A null placebo on 25–64 tertiary share is not enough to establish share exogeneity.

3. **Country-year FE result reinforces the concern:**  
   If historical shares are correlated with national development trajectories, then the attenuation under country×year FE is exactly what one would expect from a problematic share-based design.

### D. Instrument construction needs clarification and possibly correction
The leave-one-out growth formula in Equation (7) appears notationally inconsistent. The text defines \(G_{jt} = \sum_{k \neq i} \text{Flow}_{kj,t}\), but then writes \(g_{jt}^{(-i)} = \frac{G_{jt} - \text{Flow}_{ij,t} - G_{j,\text{pre}}}{G_{j,\text{pre}}}\), which seems to subtract region \(i\)'s flow again after already excluding it. The appendix gives a different formulation. This is not a cosmetic issue: if the implemented instrument differs from the text, readers cannot evaluate identification.

A top-journal empirical paper needs exact, unambiguous instrument construction. Right now, the formulas in \S\ref{sec:iv_construction} and the Data Appendix do not line up cleanly.

### E. Threats to identification are not fully addressed
The paper discusses correlated shocks, share endogeneity, serial correlation, SUTVA, and measurement error (\S\ref{sec:threats}), which is useful. But the empirical responses are limited.

- **Correlated destination shocks and sending-region trends:** GDP controls are unlikely to absorb the relevant concern. Education stocks, migration opportunities, macro convergence/divergence, and labor market openings are not well summarized by regional GDP per capita.
- **Policy/non-policy confounding:** Destination growth in Erasmus inflows may proxy for broader destination attractiveness or labor demand trends that simultaneously matter for origin-region emigration opportunities.
- **Exposure concentration:** The effective number of shocks is only 15–20 (Identification Appendix), so asymptotics are not especially comforting.

Overall, the paper is honest about limitations, but the design remains too vulnerable for the current causal framing.

## 2. Inference and statistical validity

This is the second major concern.

### A. Uncertainty reporting is internally inconsistent in places
Several reported standard errors and test statistics do not cohere.

1. **First-stage F-statistic inconsistency:**  
   In the text (\S\ref{sec:first_stage}), the preferred diagnostic is the cluster-robust first-stage \(t \approx 9.83\), implying \(F \approx 97\). But Figure \ref{fig:first_stage} and Table \ref{tab:main} report first-stage F-statistics around 1,376. These are not small differences in presentation; they imply very different inferential benchmarks. The paper notes that one is from joint 2SLS and one from standalone first stage, but the main tables still foreground the huge F-statistic. This is potentially misleading.

2. **Reduced-form SE appears implausibly small:**  
   The reduced-form coefficient is reported as \(-0.309\) with SE \(0.005\) (\S\ref{sec:results}, Figure \ref{fig:reduced_form}). Given the two-way clustered second-stage SE is 0.191 and the first-stage coefficient SE is 0.081 under region clustering, a reduced-form SE of 0.005 is hard to reconcile with the rest of the paper. This needs verification. If it is based on non-clustered or inappropriate residualized binscatter uncertainty, it should not be presented as inferential evidence.

3. **Sample sizes vary in ways that need explanation:**  
   Summary statistics report \(N=2796\) for most variables (Table \ref{tab:sumstats}), while main regressions use 2916 observations for OLS and 2792 for 2SLS (Table \ref{tab:main}). GDP per capita has only 2520 observations in the summary table, yet the main specification claims time-varying controls include GDP per capita and youth population. It is not clear whether the preferred 2SLS specification includes these controls, whether missing GDP is imputed, or whether the baseline drops GDP despite the text. A top empirical paper needs a transparent specification/sample map.

### B. The preferred inference standard should be more conservative than currently emphasized
Given:
- only 9 years,
- country-wide common shocks,
- shift-share exposure built from a limited number of effective shocks,
- RI failure under the shock-based interpretation,
- and the coefficient’s disappearance under country×year FE,

the paper should not lean on region-clustered p-values as the primary evidentiary basis. The two-way clustered inference is better, but even that may not fully solve the problem if the true dependence is at the shock/country level. More appropriate inference may require shock-level, AKM-type, or other shift-share-appropriate procedures depending on the exact identification interpretation.

The paper cites Adão-Kolesár-Morales in the introduction, but does not implement AKM/AKM0-type inference or an equivalent shock-level procedure. That omission is substantial for a shift-share paper targeting a top journal.

### C. The long-difference IV is weak and unstable
Appendix Table \ref{tab:cross_section} reports a long-difference first-stage \(F \approx 2.4\) and a sign-flipped, very imprecise 2SLS estimate. While not fatal on its own, this means the panel results are not corroborated by a medium-run specification closer to the stock-adjustment logic of the mechanism. This further reduces confidence.

## 3. Robustness and alternative explanations

### A. Some robustness checks are useful, but they do not rescue identification
The leave-one-country-out exercise is informative and reassuring on mechanical dominance by one destination (\S\ref{sec:robustness}). The null effect on the 25–64 tertiary share is also directionally consistent with age specificity.

But these checks do not address the main alternative explanation: that the instrument is proxying for broader cross-country patterns of convergence/divergence, migration opportunity, or university/labor-market integration rather than Erasmus-specific non-return.

### B. The placebo evidence is mixed, not uniformly supportive
The manuscript overstates the placebo strength.

- The **25–64 tertiary share** placebo is null (Table \ref{tab:placebo}, col. 2), which is helpful.
- But the **25–64 employment** outcome is not null: the coefficient is \(-4.387\) with SE \(1.932\), statistically significant at conventional levels (Table \ref{tab:placebo}, col. 4).

That matters. A nonzero effect on broader-cohort employment is inconsistent with a tightly youth-specific Erasmus channel, or at least suggests broader regional labor-market confounding. The text says “employment placebo for the 25–64 cohort is similarly null” (\S\ref{sec:placebo}), which directly contradicts Table \ref{tab:placebo}. This is a substantive inconsistency, not a style issue.

### C. Mechanism claims exceed the evidence
The paper frequently interprets the estimates as reflecting non-return, search-friction reduction, and stepping-stone migration. Those are plausible mechanisms, but the data do not observe return behavior, participant residence trajectories, or destination retention. The observed estimates are reduced-form relationships between origin-region outflow rates and subsequent regional stocks/labor aggregates. The mechanism discussion should be more carefully separated from what is identified.

### D. The labor market outcome interpretation is too strong
The negative labor force participation and employment coefficients are presented as evidence of “physical departure of workers rather than changes in labor demand” (\S\ref{sec:main_results}). That is not established. At the regional level, lower LFP/employment among 25–34 year-olds could reflect:
- out-migration,
- delayed labor-market entry,
- schooling composition changes,
- measurement or denominator issues,
- or broader macro conditions correlated with Erasmus intensity.

Given the country×year FE sensitivity and the broader-cohort employment result, the labor-market evidence should not be treated as clean corroboration of the migration channel.

### E. External validity and policy counterfactual remain underdeveloped
The paper is explicit that the estimates, if causal, are intensive-margin local effects. That is good. But some policy discussion still slips toward broader claims about the 2021 budget expansion and EU design. Since only one clear post-expansion year is in the estimation sample, the evidence is too limited to anchor strong claims about the consequences of the 2021–2027 scale-up.

## 4. Contribution and literature positioning

The topic is potentially important and the use of newly geolocated Erasmus flows is a real contribution. The paper sits at the intersection of:
- migration/brain drain,
- regional divergence,
- program evaluation of mobility policies,
- and shift-share econometrics.

That said, the current contribution claim is somewhat overstated relative to the evidence. The paper does not yet “provide causal evidence” that Erasmus amplifies regional divergence; it provides suggestive IV evidence with major identification caveats.

### Literature coverage: mostly good, but some important additions are needed
The paper cites many relevant references, but I would strongly recommend adding or engaging more directly with:

1. **Shift-share inference and identification**
   - Adão, Kolesár, Morales (2019), *Shift-Share Designs: Theory and Inference* — already cited, but should be operationalized, not just mentioned.
   - Borusyak, Hull, Jaravel (2022), *Quasi-Experimental Shift-Share Research Designs* — central, but the paper needs to align implementation and interpretation more tightly with BHJ diagnostics.
   - Goldsmith-Pinkham, Sorkin, Swift (2020), *Bartik Instruments: What, When, Why, and How* — already cited, but the paper should more explicitly decompose the identifying shares and discuss whether a shares-only design is plausible here.
   - Jaeger, Ruist, Stuhler (2018/2024 depending cited version) on shift-share/migration critiques — already present, but should play a larger role in framing the risks.

2. **Dynamic treatment / stock-flow migration effects**
   - The paper would benefit from literature on migration stock-flow timing and cohort exposure designs, even if outside Erasmus specifically. The current absence leaves the treatment-timing problem underdeveloped.

3. **Erasmus and mobility-to-migration evidence**
   - Parey and Waldinger (2011) and Oosterbeek and Webbink (2011) are good starts, but the paper should engage more with whether Erasmus raises international migration as opposed to merely sorting already-mobile individuals.

## 5. Results interpretation and claim calibration

To the paper’s credit, the abstract and conclusion are more calibrated than much applied work; they repeatedly call the evidence “suggestive.” Still, some claims remain too strong relative to the reported evidence.

### Over-claiming / miscalibration
1. **“Causal evidence” language** in the introduction and contribution discussion is too strong given the RI failure, country×year FE attenuation, timing mismatch, and lack of shift-share-appropriate inference.
2. **Mechanism claims** about non-return and stepping-stone migration go beyond what is observed.
3. **Policy framing around the 2021 expansion** is too definitive given the sample effectively has only a very short post-expansion window.
4. **Placebo interpretation** is overstated and partly contradicted by Table \ref{tab:placebo}.

### Magnitude interpretation needs tightening
The coefficient is large relative to mechanical benchmarks. That does not invalidate it, but it does mean the paper must do more to justify what parameter is being estimated. As written, the paper moves too quickly from a large reduced-form IV coefficient to claims about “brain drain” without enough structure linking annual outflows to stock changes.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

**1. Rebuild the empirical design around cohort timing / dynamics.**  
- **Why it matters:** The current contemporaneous flow-on-stock specification is the central weakness. Without fixing timing, the coefficient is hard to interpret causally.  
- **Concrete fix:** Estimate distributed-lag models of outflow exposure on later 25–34 outcomes; or construct cohort-specific exposure measures (e.g., region’s Erasmus outflow intensity for ages 20–24 in years \(t-3\) to \(t-1\) predicting age-appropriate stocks later). If possible, use stacked cohorts or event-time exposure windows.

**2. Make country-by-year FE a central benchmark and confront the attenuation directly.**  
- **Why it matters:** The disappearance of the effect under country×year FE currently undermines the main claim.  
- **Concrete fix:** Recast the paper around within-country identification if possible. Show whether any meaningful identifying variation remains at that level. If not, substantially soften the claim and reposition the paper as documenting a cross-country regional pattern rather than causal region-level effects.

**3. Implement shift-share-appropriate inference.**  
- **Why it matters:** Standard clustered SEs are likely insufficient in this design. A paper centered on shift-share IV cannot pass without credible inference.  
- **Concrete fix:** Implement AKM/AKM0 or comparable shock-level inference appropriate to the exact shift-share design, and report it prominently for first stage, reduced form, and 2SLS.

**4. Resolve all inconsistencies in instrument construction, standard errors, and sample counts.**  
- **Why it matters:** Internal incoherence on formulas and inference undermines trust in the entire empirical exercise.  
- **Concrete fix:** Provide a transparent specification table showing sample restrictions and observation counts by column; reconcile 2796/2792/2916/2520 counts; clarify whether GDP is included in preferred specs; verify the reduced-form SE; and correct the leave-one-out growth formula in text and appendix.

**5. Correct the placebo interpretation and reassess the broader-cohort employment result.**  
- **Why it matters:** The text currently claims a null broader-cohort employment placebo, but the reported estimate is significant. This directly affects interpretation of specificity.  
- **Concrete fix:** Correct the text, discuss why 25–64 employment moves if the mechanism is youth-specific, and examine whether this reflects broader labor-market confounding.

### 2. High-value improvements

**6. Strengthen the defense of share exogeneity or decompose the shift-share identifying content.**  
- **Why it matters:** After the RI result, the paper implicitly leans on shares. That requires much stronger evidence.  
- **Concrete fix:** Following GPSS logic, decompose the instrument into share components, examine whether baseline region characteristics and pre-trends predict exposure, and test whether historically western-oriented/language-linked/destination-linked regions were already on different trajectories.

**7. Add stronger falsification/pre-trend evidence on outcomes, not just levels.**  
- **Why it matters:** A null baseline balance test is weak relative to the concern about differential trends.  
- **Concrete fix:** Show whether future instrument exposure predicts pre-2014 to 2016 changes in tertiary share, employment, migration proxies, etc. If feasible, use leads/lags in a panel event-study style exposure framework.

**8. Reassess labor-market outcomes using rates rather than levels where appropriate.**  
- **Why it matters:** Levels in thousands mechanically scale with region size and population changes.  
- **Concrete fix:** Estimate effects on employment and activity rates for 25–34 year-olds, or normalize levels by cohort population.

**9. Clarify whether the paper is about Erasmus outflows or net flows.**  
- **Why it matters:** The mechanism is permanent loss net of inflows/returns, but the treatment is gross outflows.  
- **Concrete fix:** Make gross-outflow estimates primary only if justified; otherwise present net-outflow or inflow-adjusted analyses as central robustness.

**10. Tone down policy implications unless supported by post-2021 evidence.**  
- **Why it matters:** The paper cannot convincingly evaluate the 2021 budget expansion with effectively one post-expansion year in the main sample.  
- **Concrete fix:** Reframe the policy discussion around the general design of mobility programs, not the realized impact of the 2021–2027 expansion.

### 3. Optional polish

**11. Distinguish reduced-form findings from mechanism interpretation more sharply.**  
- **Why it matters:** This will improve credibility.  
- **Concrete fix:** Use language like “consistent with” rather than “indicates” or “operates through,” unless directly observed.

**12. Report denominator and units more consistently.**  
- **Why it matters:** The text alternates between “percentage-point increase” and “per 1,000 youth” scaling in ways that can confuse magnitude interpretation.  
- **Concrete fix:** State clearly in every main table note what one unit of Outflow rate means.

## 7. Overall assessment

### Key strengths
- Important, policy-relevant question with broad appeal.
- Novel regional Erasmus flow data are a real empirical contribution.
- The paper is unusually transparent about limitations.
- Heterogeneity patterns are substantively interesting and plausibly connected to regional divergence.

### Critical weaknesses
- Main design has a serious timing mismatch between annual flows and stock outcomes.
- Identification appears to rely mainly on cross-country variation; effect vanishes with country×year FE.
- Shift-share IV fails its own shock-randomization diagnostic.
- Inference is not yet appropriate for a shift-share design.
- Some substantive claims are contradicted by the reported tables (notably the 25–64 employment placebo).
- Key reporting details on formulas, SEs, and sample sizes are inconsistent.

### Publishability after revision
There is a potentially publishable paper here, especially given the novelty of the data and the importance of the question. But it would require substantial redesign and much more rigorous inferential treatment. In current form, I do not think it is close to acceptance at a top general-interest or AEJ: Economic Policy outlet. A successful revision would likely need to reposition the empirical strategy around dynamic/cohort exposure, strengthen within-country identification, and implement proper shift-share inference.

DECISION: MAJOR REVISION