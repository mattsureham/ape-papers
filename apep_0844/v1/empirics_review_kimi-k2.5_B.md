# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant B)

**Model:** moonshotai/kimi-k2.5
**Variant:** B
**Date:** 2026-03-24T15:43:02.747423

---

**Referee Report**

**Manuscript:** "The Sticky Sticker Price: State Disinvestment, Tuition Rigidity, and Student Body Recomposition at Public Universities"

**Format:** AER: Insights

---

### 1. Idea Fidelity

The paper deviates substantially from the research design outlined in the original manifest. The manifest proposed a Bartik-style instrumental variables strategy—interacting initial state higher-education budget shares with national economic shocks—to identify the causal effect of state appropriation cuts on tuition and enrollment composition. This instrument was specifically designed to address the endogeneity of state fiscal choices, leveraging plausibly exogenous variation in recession exposure.

The executed paper instead employs a reduced-form continuous treatment difference-in-differences (DiD) design, using the realized percentage decline in state appropriations as the treatment variable. This abandonment of the IV strategy is consequential: the "cut intensity" measure is almost certainly endogenous to local economic conditions that directly determine family incomes and Pell eligibility. Furthermore, the manifest hypothesized that low-income students would be displaced by tuition increases (the "pricing out" mechanism), whereas the paper finds the opposite—Pell shares *increase* with cuts—and interprets this as evidence of "sticky" tuition prices and quality degradation. While empirical findings should guide the narrative, the shift from a supply-side IV strategy to a reduced-form DiD that cannot separate supply and demand shocks undermines the paper's ability to make causal claims about institutional responses to disinvestment.

---

### 2. Summary

This paper examines how public universities responded to differential state appropriation cuts during the Great Recession (2008–2012). Using IPEDS data on 702 public four-year institutions (2004–2022) in a continuous treatment DiD framework, the author finds that institutions in states with larger cuts did not increase in-state tuition significantly, but instead experienced increases in the share of Pell-eligible and minority students. These results challenge the conventional narrative that state disinvestment mechanically raises tuition and prices out low-income students, suggesting instead that tuition is politically "sticky" and that fiscal shocks are absorbed through enrollment composition changes.

---

### 3. Essential Points

**1. Endogeneity of Treatment and Missing Instrumental Variables.** The paper’s central causal claim—that institutions absorb fiscal shocks through compositional change rather than price adjustment—rests on the assumption that variation in cut intensity is exogenous to enrollment composition. This assumption is untenable. States experiencing deeper recessions (and thus larger cuts) also experienced larger income shocks to families, mechanically increasing Pell eligibility and potentially altering college demand independently of institutional supply responses. The manifest’s proposed Bartik instrument (interacting initial budget shares with national shocks) was specifically intended to address this confound. Without it, the estimated effects conflate demand-side recession impacts with supply-side institutional adaptation. The paper cannot support its title claim that tuition "rigidity" causes enrollment recomposition without exogenous variation in the fiscal shock.

**2. Failure to Establish Parallel Trends.** The credibility of the continuous DiD design requires evidence that institutions in high-cut and low-cut states followed parallel trends in tuition and enrollment composition prior to the Great Recession. The paper references an event study specification but provides no graphical or tabular evidence of pre-trends (the "Smoke Test Log" from the manifest is absent). Given that cut intensity correlates with the severity of state-level business cycles that have persistent effects on higher education markets, the absence of pre-trend analysis is fatal to the identification strategy. The robustness check trimming outliers (Table 3, Column 2) shows the Pell result becomes insignificant (p > 0.20), further undermining confidence.

**3. Unresolved Demand vs. Supply Decomposition.** The paper acknowledges that the positive coefficient on Pell share could reflect either (i) recession-induced income declines increasing eligibility (demand) or (ii) quality degradation at underfunded institutions driving away high-income students (supply). These mechanisms have opposite policy implications: the former suggests public universities served as a safety net during the recession, while the latter suggests fiscal austerity degraded institutional quality. The paper offers no strategy to separate these channels—such as exploiting variation in institutional reliance on state funds conditional on state-level income shocks, or using individual-level income data. Without this decomposition, the paper cannot conclude that "institutions absorb the shock" through composition rather than simply observing a correlation between recession severity and student poverty.

---

### 4. Suggestions

**Implement the Proposed Bartik Instrument.** To salvage the causal claims, the authors should implement the Bartik-style instrument described in the original manifest: interact the state’s initial (2003) higher-education budget share with national GDP growth or state tax revenue shortfalls. This would isolate variation in cuts driven by exposure to national shocks rather than state-specific economic conditions. A two-stage least squares design (first stage: instrumented appropriations → per-student funding; second stage: funding → tuition/composition) would provide credible identification for the price passthrough and composition channels.

**Present Event Study Evidence.** The authors should include event study plots showing the dynamic path of tuition, Pell shares, and
