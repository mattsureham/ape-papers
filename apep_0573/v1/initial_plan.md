# Initial Research Plan: Did EU Procurement Reform Crowd Out Competition?

## Research Question

Did the 2014 EU Public Procurement Directives (2014/24/EU, 2014/25/EU, 2014/23/EU) reduce competitive bidding in public procurement markets? Specifically: did the regulatory complexity introduced by the reform — divide-or-explain mandates, ESPD requirements, mandatory e-submission — crowd out smaller and less-sophisticated bidders, paradoxically reducing the competition the reform was designed to increase?

## Motivation

Public procurement accounts for 14% of EU GDP (~EUR 2 trillion annually). The EU Court of Auditors (2023) documented a dramatic decline in average bidders per contract from 5.7 to 3.2 over the past decade, with single-bidder contracts rising above 30% in many member states. This is a first-order fiscal question: less competition in procurement means higher prices for taxpayers. Yet there is no causal evidence on whether the 2014 reform — the most significant overhaul of EU procurement rules in a generation — contributed to this decline.

## Identification Strategy

**Staggered DiD exploiting cross-country variation in transposition timing.**

The 2014 Directives had a deadline of April 18, 2016. Only 7 member states transposed on time (Denmark, France, Germany, Hungary, Lithuania, Spain, UK). The remaining 21 transposed between mid-2016 and 2018, with the Commission issuing formal infringement notices in May 2016. This creates staggered adoption across 28 countries.

**Estimator:** Callaway & Sant'Anna (2021), grouping by year-quarter of first transposition notification. Event study from t-8 to t+12 quarters relative to transposition.

**Unit of analysis:** Country × quarter panel, aggregating from contract-level TED data.

**Treatment variable:** Quarter in which the first national implementing measure for Directive 2014/24/EU was notified to the Commission (from EUR-Lex/CELLAR SPARQL).

## Primary Outcomes (hierarchy)

1. **Single-bidder share** — fraction of contracts receiving exactly one bid (primary)
2. **Log number of bids** — average competitive intensity per contract
3. **Cross-border bid share** — fraction with at least one foreign bidder

## Secondary Outcomes (mechanism tests)

4. **SME winner share** — fraction of contracts won by SMEs (tests if SME-friendly measures worked)
5. **Award-to-estimated value ratio** — procurement efficiency (price competitiveness)
6. **Procedure type shares** — open vs. restricted vs. negotiated (tests procedural channel)
7. **Processing time** — days from publication to award (tests administrative burden channel)

## Built-in Placebo

**Below-threshold contracts** (those below the directive's monetary thresholds) are NOT subject to the EU directives and should show no effect from transposition. If the reform causally affected competition, single-bidder shares should change for above-threshold contracts but NOT for below-threshold ones. This provides a difference-in-difference-in-differences (DDD) or a direct placebo test.

## Expected Effects and Mechanisms

**Hypothesis 1 (Complexity crowding-out):** The reform's administrative requirements (ESPD, e-submission, lot-splitting compliance) disproportionately burden smaller firms. Despite SME-friendly provisions, the net effect on competition is negative because compliance costs exceed the benefits of market access.

**Hypothesis 2 (Procedural shift):** Expanded use of negotiated and competitive-dialogue procedures (which have fewer bidders by design) mechanically reduces average bid counts without reducing effective competition.

**Hypothesis 3 (E-submission modernization):** Mandatory e-procurement reduces barriers for digitally-capable firms but excludes less-sophisticated bidders, especially in member states with lower digital infrastructure.

**Heterogeneity predictions (pre-specified):**
- Effects should be larger in countries with lower pre-reform administrative capacity (measured by Government Effectiveness Index)
- Effects should be larger in sectors with more SME participation at baseline
- Effects should be smaller in countries that already had advanced e-procurement systems

## Primary Specification

$$Y_{ct} = \alpha_c + \gamma_t + \sum_{k \neq -1} \beta_k \cdot D_{c,t-g_c=k} + \epsilon_{ct}$$

where $Y_{ct}$ is the single-bidder share in country $c$ quarter $t$, $\alpha_c$ are country FEs, $\gamma_t$ are quarter FEs, $g_c$ is the transposition quarter for country $c$, and $D$ are event-time indicators.

## Data

**TED (Tenders Electronic Daily):** Universe of above-threshold EU procurement notices, 2009-2023, freely downloadable as annual CSV files. Key variables: ISO_COUNTRY_CODE, NUMBER_OFFERS, B_CONTRACTOR_SME, AWARD_VALUE_EURO, TOP_TYPE (procedure), publication and award dates.

**EUR-Lex/CELLAR SPARQL:** National implementation measures for Directive 2014/24/EU, notification dates by member state.

**Eurostat:** Government expenditure (gov_10a_exp) for normalization; World Bank Governance Indicators for heterogeneity analysis.

## Planned Robustness Checks

1. **Pre-trend tests:** Joint F-test on pre-treatment event-study coefficients
2. **Rambachan-Roth sensitivity analysis** for violations of parallel trends
3. **Randomization inference** (permute transposition dates across countries)
4. **Leave-one-out:** Drop each country; verify no single-country dependence
5. **Below-threshold placebo:** No effect on contracts below directive thresholds
6. **CPV-sector composition controls:** Hold procurement categories fixed
7. **Alternative treatment timing:** Use entry-into-force date instead of notification date
8. **Bacon decomposition:** Show weight on clean (not-yet-treated vs treated) comparisons
9. **Wild cluster bootstrap** for small-N inference (28 clusters)
10. **Alternative aggregation:** Country-year instead of country-quarter

## Exposure Alignment (DiD Required)

- **Who is treated?** Public contracting authorities in member states that transposed the 2014 Directives
- **Primary estimand population:** Above-threshold public procurement contracts in transposing member states
- **Placebo/control population:** Below-threshold contracts (not subject to directives)
- **Design:** Staggered DiD (Callaway-Sant'Anna) with built-in DDD placebo

## Power Assessment

- **Pre-treatment periods:** ~28 quarters (2009-2016Q1 for early transposers)
- **Treated clusters:** 28 member states (7 early, 21 late)
- **Post-treatment periods:** ~28 quarters (through 2023)
- **Cluster count:** 28 (modest — requires wild cluster bootstrap + RI)
- **Contract-level N:** ~500K-1M per year → millions of observations
- **MDE:** With 28 clusters and 56 time periods, aggregate-level DiD can detect ~2-3pp changes in single-bidder share (baseline ~25-30%)

## Delta Statement (Novelty)

No existing causal study estimates the effect of the 2014 EU Public Procurement Directives on competitive bidding outcomes. The only causal DiD paper using TED data (Springer 2025) studies Green Public Procurement provisions, not competition/SME effects. EU Court of Auditors (2023) and OECD (2021) document declining competition descriptively but offer no causal attribution. This paper provides the first causal estimate using the staggered transposition of the largest procurement reform in EU history, with a built-in below-threshold placebo.
