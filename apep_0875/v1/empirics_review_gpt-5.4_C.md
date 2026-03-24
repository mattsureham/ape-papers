# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-03-24T21:44:51.668532

---

## 1. **Idea Fidelity**

The paper only partially pursues the original idea in the manifest, and in ways that materially weaken the design.

Most importantly, the manifest’s key identifying variation was **within-for-profit, program-level heterogeneity in GE risk using the DOE disclosure files** (Pass/Zone/Fail or debt-to-earnings measures), ideally merged by OPEID × CIP × award level, with the 2019 repeal as a second quasi-experiment. That is the promising design. The paper instead estimates a much coarser **for-profit versus public DiD**, without using the GE disclosure files at all. As written, it does not exploit the core source of quasi-experimental variation described in the manifest.

Second, the manifest emphasized several outcomes: program survival, institutional enrollment contraction, and student substitution to public community colleges. The paper delivers survival and some completions evidence, but the enrollment substitution exercise is reduced to a brief, inconclusive paragraph. The repeal is used, but not in the more convincing “high-risk vs low-risk program” framework suggested by the manifest.

Third, the manifest recognized that all for-profit programs were not equally exposed: some programs were at much greater risk of sanctions because of debt-to-earnings performance. The paper instead uses coarse CIP-based “risk” categories, which are not a substitute for the actual program-level GE results. That is a major missed opportunity.

So: the paper addresses the same broad question, but it abandons the strongest identification strategy in the manifest and replaces it with a much weaker one.

## 2. **Summary**

This paper studies whether the 2015 Gainful Employment rule accelerated exit of for-profit educational programs and whether the 2020 repeal reversed that effect. Using IPEDS program-level completions data, it reports large relative declines in for-profit program survival and completions after 2015, with no rebound after repeal, and interprets this as evidence of an irreversible “disclosure chill.”

The topic is important and timely, and the descriptive facts are interesting. But in its current form, the econometric design does not support the paper’s causal interpretation, especially the claim that the estimates isolate disclosure rather than broader secular decline or contemporaneous regulatory pressure on the for-profit sector.

## 3. **Essential Points**

1. **The identification strategy is not credible as a causal design in its current form.**  
   The paper openly acknowledges substantial pre-trends: the placebo estimate is very large and highly significant, and for-profit survival is already falling much faster than public survival before 2015. That is not a minor blemish; it is a direct failure of the core DiD assumption. Once that is true, the headline estimate of a 25–30 percentage-point post-2015 survival effect cannot be interpreted causally. The current language—“causal effect,” “disclosure chill,” “driven by information”—is much too strong. To make progress, the authors need to return to the design promised in the manifest: use actual program-level GE risk/disclosure results, estimate within-for-profit differential effects, and ideally compare programs more versus less exposed to sanctions and negative disclosure.

2. **The treatment-control comparison is poorly matched and likely conflates GE with sector-wide collapse.**  
   Public programs are a weak control group for for-profit programs over this period. The sectors differ dramatically in program mix, demand shocks, business model, financing, chain structure, exposure to CFPB/state AG actions, and vulnerability to major chain closures. Comparing for-profit cosmetology/business/health programs to public programs in the same 2-digit CIP field is not enough. A 2-digit CIP is too coarse, and sector-specific shocks were enormous in precisely these years. The estimated magnitudes—roughly a 30 percentage-point drop in survival—are plausible as a **reduced-form description of for-profit contraction**, but not as an effect of GE disclosure per se. The paper needs either (i) a within-for-profit design using Pass/Zone/Fail or debt-to-earnings scores, or (ii) a much more flexible event-study/trend-adjusted framework with narrower field controls and serious sensitivity analysis.

3. **The outcome definition and inference need much more scrutiny.**  
   Defining a program as “alive” only if it reports positive completions is problematic. Programs can have zero completions in a year without being closed, especially for longer-duration programs, small programs, or programs with lumpy graduation timing. This creates mechanical overstatement of “death,” especially in annual panels. It may also differ systematically by sector. In addition, standard errors clustered at the state level are not obviously appropriate for a treatment that varies mainly at the sector-by-time level and uses highly persistent program panels. With only about 50 states, and with treatment effectively common within sector-year cells, the reported SEs likely overstate precision. The paper should report wild-cluster/bootstrap inference, randomization-style placebo tests, and aggregation to a level closer to the identifying variation.

If these issues cannot be addressed, I do not think the paper is publishable in AER: Insights. The descriptive patterns may still be valuable, but the current causal claims are too strong for the design.

## 4. **Suggestions**

The good news is that there is a potentially strong paper here if the authors narrow the claim and rebuild the empirical strategy around the actual GE program-level data.

**First, use the DOE GE disclosure files directly.** This is the paper’s biggest missing element. Merge programs by OPEID × CIP × award level and estimate whether **Fail** or **Zone** programs experienced larger post-2015 exit and enrollment declines than **Pass** programs, ideally within the same institution or chain where possible. A design such as
\[
Y_{pjt} = \sum_k \beta_k 1[t=k]\times Risk_p + \alpha_p + \gamma_t + \varepsilon_{pjt}
\]
or a post × fail/zone specification within the for-profit sector would be much more persuasive. That is the variation most plausibly tied to GE rather than to the sector’s general decline.

**Second, distinguish disclosure from sanction more carefully.** Right now the paper claims to identify information effects because repeal did not generate recovery. That logic is too weak. No rebound after repeal is also consistent with sunk costs, declining demand, financing frictions, borrower-defense enforcement, chain failure, and pandemic-era disruption. A better test would compare programs that were publicly revealed to be high-risk versus low-risk, and programs close to sanction thresholds versus far from them. If low-risk but disclosed programs also contract, that would be more suggestive of disclosure spillovers. If only fail/zone programs contract, the sanction channel is more likely.

**Third, rethink the survival measure.** IPEDS completions are useful, but “positive completions” is an imperfect closure indicator. At minimum:
- show how often programs disappear for one year and then reappear;
- require two consecutive zero-completion years before coding death;
- examine alternative definitions using program presence in the directory/completions file, not just positive graduates;
- stratify by award length or average program size, since lumpiness is worse for small programs.  
A hazard model for exit from an “active” state may fit the outcome better than a linear probability model on alive/dead status.

**Fourth, the magnitudes need clearer benchmarking.** A 29.7 percentage-point survival decline is enormous. It may be true descriptively, but the paper should benchmark it against:
- pre-2015 annual hazard rates by sector;
- the implied cumulative number of excess closures;
- chain-level events such as Corinthian and ITT, which could account for a large share of the estimated effect;
- effects after dropping the years of major chain collapses or excluding affected chains entirely.  
If the estimate falls sharply when excluding Corinthian/ITT years or chains, the current headline interpretation is overstated.

**Fifth, make the event-study central, not ancillary.** Given the obvious pre-trend problem, the reader needs a transparent graph with confidence intervals and coefficient tables. The event-study should be shown at annual resolution, and the paper should avoid simple “post-2015” pooling until the dynamic pattern is clear. I would also recommend including sector-specific linear trends, perhaps sector × field trends, as a sensitivity exercise. These are not a cure for bad controls, but they are necessary here.

**Sixth, improve the control group or drop it.** The public-sector comparison is convenient but not convincing. Better alternatives:
- compare for-profit programs by GE risk within sector;
- compare for-profit programs to the subset of public certificate programs that were also covered by GE;
- use private nonprofit programs as an additional comparison, while being clear about limitations;
- work within chain × field or institution × broad field cells where feasible.  
The closer the control group is to actual GE exposure, the better.

**Seventh, standard errors and dependence structure need more serious treatment.** Because treatment is effectively sector-by-time, with repeated outcomes for the same program and strong common shocks, conventional state-clustered SEs are unlikely to be enough. I would like to see:
- wild-cluster bootstrap p-values by state;
- clustering by institution or chain as a robustness check;
- aggregation to sector × CIP × year or institution × year panels;
- perhaps a Donald-Lang style approach at the relevant aggregate level.  
Given the enormous sample size, the current tiny SEs are not informative about true uncertainty.

**Eighth, the paper should be more careful with sample accounting.** Several numbers do not line up cleanly. The abstract says 181,136 programs tracked from 2011 to 2023, but the manifest suggested much smaller for-profit counts and the panel observation counts imply a very unbalanced structure. The summary table reports 52 states and 59 states, which is not possible in the usual sense and suggests coding problems with territories/jurisdictions. These issues are fixable but need cleaning because they undermine confidence in the empirical implementation.

**Ninth, the heterogeneity analysis is too coarse to support the “broad chill” interpretation.** Labeling CIP 51 as “low-risk” and CIP 12/52 as “high-risk” is much too blunt. Healthcare contains both very strong and weak programs; business is similarly heterogeneous. The actual GE data contain the relevant risk measure. Use that. Also, if low-risk programs are estimated to suffer larger declines than high-risk ones, one should first worry about composition and measurement error before concluding sector-wide stigma.

**Tenth, the enrollment substitution piece should either be developed properly or dropped.** A one-sentence statement that the estimate is positive but imprecise does not add much. If the paper wants to make welfare-relevant claims, displaced students are central. Use county or commuting-zone exposure measures based on pre-period for-profit program presence and estimate public two-year enrollment responses. If that cannot be done convincingly in this format, I would remove the section and keep the paper tightly focused on supply-side exit.

**Finally, moderate the rhetoric.** Terms like “disclosure chill,” “irreversible market restructuring,” and “information remained” may eventually be justified, but not by the current design. The evidence currently supports a more restrained claim: **for-profit program exit accelerated after the GE era began and did not reverse after repeal**. That is already an interesting stylized fact. The stronger mechanism claim requires stronger identification.

In short: interesting topic, important policy relevance, and potentially novel data linkage. But the present paper is much more convincing as a descriptive account of for-profit contraction than as a causal estimate of the effect of GE disclosure. The path forward is clear: use the actual GE program-level risk/disclosure data, tighten the outcome definition, strengthen inference, and scale back the causal rhetoric unless the new design supports it.
