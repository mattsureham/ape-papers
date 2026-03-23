# Research Plan: apep_0827

## Research Question

Does legalizing the cannabis supply chain reduce drug-related crime? The Netherlands' *wietexperiment* randomly assigned 10 municipalities to a closed legal cannabis supply chain starting December 2023, while 10 matched comparison municipalities retained the status quo (legal retail, illegal supply). I estimate the causal effect of legal supply on drug crime, violence, and total crime.

## Identification Strategy

**Primary: Difference-in-Differences** with 10 treatment vs 10 WODC/RAND-matched control municipalities, exploiting the staggered rollout:
- Phase 1 (Dec 15, 2023): Breda and Tilburg begin transitional supply
- Phase 2 (Jun 17, 2024): All 10 treatment municipalities enter transitional phase
- Experimental phase (Apr 7, 2025): Legal cannabis only

The 10 control municipalities were specifically selected by WODC and RAND Europe to match treatment municipalities on observables. This gives a pre-registered comparison group.

**Robustness: Synthetic Control Method** with the ~350+ Dutch municipalities as donor pool, constructing counterfactuals for each treatment municipality individually. Permutation inference following Abadie et al. (2010).

**Inference:** With 10 treated clusters, standard clustered SEs are unreliable. I use:
1. Permutation/randomization inference (reassign treatment among the 20 municipalities)
2. Wild cluster bootstrap (Cameron, Gelbach, Miller 2008)
3. Individual SCM placebo tests

## Expected Effects and Mechanisms

**Ex ante predictions:**
- Drug crime: Ambiguous. Legal supply could reduce black market activity (substitution) or increase detection/enforcement during transition.
- Violence: Should decline if legal supply reduces criminal organization competition.
- Total crime: Small or null — drug crime is a small share of total.

**Key mechanisms to test:**
- Soft drug vs hard drug crime (supply chain only covers cannabis)
- Violence vs property crime (organized crime channels)
- Transition vs experimental phase (parallel illegal supply in transition)

## Primary Specification

$$Y_{mt} = \alpha_m + \gamma_t + \beta \cdot \text{Treat}_m \times \text{Post}_t + \varepsilon_{mt}$$

Where $m$ indexes municipalities (20 in main sample), $t$ indexes year-quarters, $Y$ is crime rate per 100,000 population. $\text{Treat}_m = 1$ for the 10 experiment municipalities. $\text{Post}_t = 1$ for quarters after June 2024 (full rollout).

## Exposure Alignment

The treatment operates at the municipality level: all coffeeshops within the 10 treatment municipalities must source from state-licensed growers during the transitional phase, and exclusively from them during the experimental phase. The unit of observation (municipality-year) aligns with the treatment assignment unit. The affected population is the entire municipality, since drug crime rates capture both supply-side offenses (cultivation, trafficking) and demand-side offenses (possession) occurring anywhere within the municipality. Coffeeshop customers, employees, and illegal suppliers are directly exposed; the broader population is indirectly exposed through changes in local drug markets and enforcement. The crime outcome is measured at the same geographic unit (municipality) as the treatment, avoiding the measurement-treatment mismatch that plagues designs where treatment varies at a different level than the outcome.

## Data Source and Fetch Strategy

**Primary data:** CBS StatLine table 83648NED — registered crimes by type and municipality, annual 2010–2024.

**Fetch method:** CBS OpenData API v4 (OData). Endpoint: `https://datasets.cbs.nl/odata/v4/CBS/83648NED/`. Filter by municipality codes for treatment/control municipalities plus full donor pool.

**Population data:** CBS StatLine table 03759NED — population by municipality and year.

**Variables:**
- CRI6000: Total drug crimes
- CRI6200: Soft drug crimes
- CRI6100: Hard drug crimes
- CRI3000: Violence crimes
- T001161: Total registered crimes

## Idea Source

idea_0625: "Legalizing the Back Door: Early Effects of the Dutch Controlled Cannabis Supply Chain Experiment on Crime"
