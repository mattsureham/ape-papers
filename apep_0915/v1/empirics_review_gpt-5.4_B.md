# V1 Empirics Check — openai/gpt-5.4 (Variant B)

**Model:** openai/gpt-5.4
**Variant:** B
**Date:** 2026-03-25T13:02:10.831552

---

## 1. Idea Fidelity

The paper largely pursues the original idea in the manifest: it studies the 2018 withdrawal of the OIAI guidance, uses EPA NEI facility-level emissions data, and frames identification around a difference-in-bunching design at the 10-ton single-HAP and 25-ton combined-HAP major-source thresholds. The core research question—whether the policy reversal induced strategic emissions management to escape MACT obligations—is faithful to the manifest.

That said, several important elements of the original design are either dropped or only partially implemented. First, the manifest emphasized a clear panel from 2012–2021, but the paper actually uses 2012, 2014, 2016, 2017, 2018, 2019, 2020, and 2021; this is not necessarily fatal, but it should be transparently reconciled because it changes the timing structure and pre-trend interpretation. Second, the placebo strategy in the paper differs from the manifest: the proposed criteria-pollutant placebo and below-median-emitter placebo are absent, replaced by placebo thresholds and placebo timing. Third, the mechanism test linking reclassifying facilities to ambient HAP concentrations via AQS is not carried out. Finally, the manifest’s strongest identification logic concerned strategic behavior by facilities for whom OIAI actually changed incentives—especially previously major sources—but the empirical implementation largely analyzes the full emissions distribution without directly identifying that margin.

## 2. Summary

This paper asks whether the EPA’s 2018 withdrawal of the “Once In Always In” guidance created a regulatory escape hatch that induced facilities to bunch emissions just below Clean Air Act Section 112 major-source thresholds. Using NEI facility-level emissions and a difference-in-bunching approach, the paper reports no detectable response at the 10-ton single-HAP threshold but a significant increase in excess mass below the 25-ton combined-HAP threshold.

The topic is important and potentially publishable: the policy change is meaningful, the question is causal in spirit, and the paper’s main asymmetry across thresholds is interesting. However, the current draft does not yet establish a convincing causal contribution because the link between the institutional treatment and the observed density changes remains too loose, and several internal inconsistencies and measurement issues weaken confidence in the findings.

## 3. Essential Points

1. **The treatment is not sharply assigned to the facilities most affected by OIAI, so the causal interpretation is currently too weak.**  
   OIAI changed incentives primarily for facilities that had previously been classified as major sources. The current design instead compares overall distributions before and after 2018, which mixes treated and untreated facilities and makes it hard to know whether post-2018 bunching near 25 tons reflects OIAI-induced reclassification behavior, broader changes in reporting, industry composition, or inventory methods. The paper needs a design that more directly isolates facilities plausibly exposed to the policy—e.g., facilities previously above the threshold, facilities with prior major-source permits/status, or at minimum facilities with pre-period emissions histories indicating likely major-source status.

2. **The NEI measurement structure and changing coverage/reporting rules are not adequately handled for a bunching design.**  
   Bunching designs are very sensitive to heaping, rounding, imputation, and changes in reporting conventions. Here the paper uses NEI emissions estimates, which are compiled from multiple sources and are not annual census-quality measurements in the same way across years and states. The paper acknowledges this generally, but not with enough empirical validation. In particular, the transition from triennial to annual inventories, possible changes in facility inclusion, and state-level estimation practices could mechanically affect density near thresholds. Without stronger evidence on comparability across years and across states, the reported 25-ton bunching result is not yet persuasive.

3. **The paper contains substantive inconsistencies that must be fixed before the results can be evaluated.**  
   Most importantly, the Discussion section states the opposite of the main result at one point (“Facilities that were marginally above the 10-ton single-HAP threshold increased the frequency with which they reported emissions below that threshold”), contradicting the abstract, results, and conclusion. There are also table and sample issues that raise concern about execution (e.g., “Facilities = 4,287.6” in Table 2; mismatches between stated polynomial order in text and tables; pre/post sample descriptions that are not fully coherent). These may be correctable, but in a short empirical paper they materially affect credibility.

## 4. Suggestions

This is a promising paper, and I think the best path forward is to tighten the design around the actual regulatory margin rather than trying to do many things at once.

**First, refocus the empirical strategy on exposure to OIAI.** The strongest version of this paper would not ask whether the unconditional emissions distribution changed near 10 and 25 tons after 2018; it would ask whether facilities for whom OIAI newly mattered behaved differently from otherwise similar facilities. If you can link NEI facilities to any measure of prior major-source status—Title V permits, NESHAP/MACT applicability, state permit records, FRS program flags, or anything similar—that would substantially improve the paper. Even an imperfect proxy would help. For example, you might define likely exposed facilities as those that exceeded the threshold in a pre-period year and later moved below it, or those in source categories commonly subject to major-source MACT. A triple-difference or stacked event-study comparing likely exposed versus unlikely exposed facilities around the policy change would be much more convincing than aggregate difference-in-bunching alone.

**Second, do much more to validate the NEI as a running variable for bunching.** Right now the reader is asked to trust that a density change around 25 tons reflects behavior rather than data construction. I would recommend several concrete diagnostics:
- Show histograms at fine bin widths separately by year, not just pre/post pooled.
- Report the extent of heaping at integer tons, especially 9, 10, 24, 25, and 26.
- Show whether bunching is visible in pounds before conversion to tons.
- Test whether there are discontinuities at thresholds in years before 2018 separately, rather than only pooled pre-period.
- Show whether the result is robust to excluding states or years with apparent reporting changes.
- Re-estimate using only years with more comparable inventory methods, or using only facilities continuously observed throughout the sample.
- Consider whether winsorization of total HAP emissions affects the polynomial fit around 25 tons; likely it should not, but the paper should show that.

**Relatedly, the bunching implementation itself needs to be documented more carefully.** The text says fourth-degree polynomial; Table 1 reports fifth-order polynomial. The text describes excluded windows \([c-2,c]\) and \([c-3,c]\), while the table notes \([8,12]\) and \([20,30]\), which are symmetric windows spanning both sides of the threshold. Those are not minor presentational slips: they change the estimand. Please clearly define:
- bin width,
- excluded region,
- fitting region,
- polynomial order,
- whether excess mass above the threshold is reallocated,
- and how bootstrapping is implemented in pooled pre/post samples.

A simple figure with observed counts and fitted counterfactual densities for each threshold would also help considerably. For AER: Insights format, one clean figure per threshold may be more persuasive than a long methodological discussion.

**Third, streamline and improve the auxiliary DiD analysis.** In its current form it is not doing much for identification and may even distract. The “Near × Post” setup uses a near-threshold indicator based on pre-period emissions, but it is not clear why the omitted “far” facilities are an appropriate counterfactual for the near group; they differ mechanically in emission level and probably in industry and reporting practices. Moreover, the outcome “Below 10 tons” is broad and not tied tightly to strategic bunching just below the threshold. If you keep this section, I would suggest:
- narrowing the outcome to being in a tight band just below the threshold versus just above;
- reporting event-study coefficients in the main text, not just the appendix;
- clustering at a level that matches the source of policy variation and serial correlation, but also discussing the small number of state clusters if relevant;
- and avoiding TWFE language unless the design really requires it, since this is a single national shock.

More fundamentally, if the DiD is only confirming a null at 10 tons and does not speak to the positive 25-ton result, it may be better to either extend it to 25 tons or cut it back.

**Fourth, improve the placebo and falsification strategy in a way that aligns with the institutional story.** The current placebo thresholds are useful but not sufficient. Stronger placebo exercises would include:
- criteria pollutants not governed by Section 112;
- thresholds that matter under other regulations but not OIAI;
- facilities far below either threshold that should not respond;
- source categories never plausibly eligible for major-source MACT;
- and states with their own binding HAP rules, used not just for heterogeneity but as a quasi-placebo if federal reclassification has less bite there.

The state-stringency heterogeneity is one of the more interesting pieces of the paper, but it currently rests on a coarse and somewhat ad hoc classification. It would be stronger if the paper explained and documented exactly which state rules attenuate the federal escape hatch and why. Right now the interpretation that this pattern rules out misreporting is too strong; state regulatory environments could also affect reporting scrutiny and estimation methods.

**Fifth, be much more disciplined about interpretation.** The most persuasive claim in the current paper is modest: there appears to be an increase in mass below the 25-ton combined-HAP threshold after the OIAI withdrawal, consistent with strategic response. The paper goes beyond that in several places. In particular:
- it cannot distinguish real abatement from strategic reporting;
- it does not observe actual reclassification;
- it does not yet provide ambient air evidence;
- and it does not support large welfare claims about compliance savings or health consequences.

I would therefore tone down language such as “reveals” or “confirms” and instead use “suggests” or “is consistent with.” This is especially important given the data source. For a short paper, a careful causal claim is better than an expansive but fragile one.

**Sixth, fix presentation issues and internal contradictions.** The paper needs a thorough edit before it can be properly assessed. At minimum:
- correct the contradiction in the Discussion regarding the 10-ton result;
- reconcile the sample years used in the abstract, data section, and appendices;
- fix impossible entries like fractional facility counts;
- ensure all tables correspond to claims in the text;
- and either provide the appendix tables/figures referenced or avoid citing unavailable evidence.

I would also encourage the authors to sharpen the contribution relative to the emerging literature. The comparison to Ozaltun, Shapiro, and Walker is sensible, but the current draft needs to be clearer on what is learned from emissions rather than permit data, and what OIAI uniquely contributes beyond “another threshold generates bunching.” The most compelling angle is not bunching per se, but how a policy change that creates an *exit option* alters behavior among incumbently regulated facilities. To make that contribution land, the empirical design has to follow the treatment more closely.

Overall, I see a good paper trying to emerge here. The policy question is strong, the asymmetry between 10 and 25 tons is potentially interesting, and the NEI is a useful starting point. But the paper needs a tighter treatment definition, stronger validation of the emissions data for bunching analysis, and more disciplined interpretation before the conclusions can be viewed as securely causal.
