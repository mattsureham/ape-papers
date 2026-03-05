# Research Idea Ranking

**Generated:** 2026-03-05T10:44:13.341109
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Does Geographic Targeting of Housing Sub... | PURSUE (79) | — | — |
| The Rental Ban Penalty: Energy Labels an... | PURSUE (72) | — | — |
| Encadrement des Loyers: Staggered Rent C... | CONSIDER (62) | — | — |
| Flood Risk Designation and Housing Price... | CONSIDER (55) | — | — |
| SRU Social Housing Quotas and Private Ho... | SKIP (50) | — | — |
| Idea 1: Does Geographic Targeting of Hou... | — | PURSUE (88) | PURSUE (82) |
| Idea 2: The Rental Ban Penalty: Energy L... | — | PURSUE (78) | PURSUE (74) |
| Idea 4: Flood Risk Designation and Housi... | — | SKIP (52) | SKIP (54) |
| Idea 3: SRU Social Housing Quotas and Pr... | — | SKIP (45) | CONSIDER (64) |
| Idea 5: Encadrement des Loyers: Staggere... | — | SKIP (35) | SKIP (57) |

---

## GPT-5.2

**Tokens:** 6622

### Rankings

**#1: Does Geographic Targeting of Housing Subsidies Matter? Evidence from France's PTZ Reform**
- Score: **79/100**
- Strengths: Big, first-order policy with **universe transactions + construction permits** and a **multi-shock/reversal** design that naturally supports internal replication (2018 cut, 2020 elimination, 2024 partial restoration). The B1/B2 boundary design + ineligible-property placebo can make the causal story unusually legible (subsidy removal → demand/composition → prices/construction/migration).
- Concerns: PTZ/Pinel changes coincide with other housing/macro shifts (rates, COVID-era composition, local planning constraints), so clean separation of channels will require careful diagnostics and robustness. Border comparisons can still be confounded if B1/B2 lines correlate with unobserved fundamentals (urbanization gradients) unless you tightly localize and show flat pre-trends.
- Novelty Assessment: **High (France-specific policy shock looks under-studied in top outlets);** “housing subsidy capitalization” is studied, but this exact *removal/retargeting* with French universe data + multi-stage shocks is meaningfully new.
- Top-Journal Potential: **Medium-High.** It can read as a sharp boundary test of a major policy lever (place-based housing subsidies) with credible internal replication and mechanisms; that’s the kind of “shock → bite → mechanism → welfare” arc top journals like.
- Identification Concerns: Main threats are **differential pre-trends across zones**, endogenous zone classification (even if mostly predetermined), and concurrent shocks. The strongest version leans on **border event-studies**, narrow bandwidths, and showing the **first stage** (eligible transactions/loan take-up) moved where expected.
- Recommendation: **PURSUE (conditional on: convincing border-based parallel trends; explicit handling of 2019–2021 disruptions; a demonstrated first-stage “bite” measure—e.g., share of eligible new-build purchases/permits shifting as predicted).**

---

**#2: The Rental Ban Penalty: Energy Labels and Housing Asset Values in France**
- Score: **72/100**
- Strengths: Clear, high-stakes mechanism: **regulatory removal of rental option value** (not just information), with a **sharp technical cutoff (450 kWh/m²/year)** and multi-cutoff future bans (G now, F later, E later) enabling internal replication/anticipation tests. If matching works, it’s a clean “policy restricts use rights → asset price” design that policymakers will care about.
- Concerns: Biggest risk is **measurement/manipulation and selection** in DPE: DPE values may be noisy, strategically updated around sale, or missing/non-random; and enforcement/market awareness may ramp gradually (so “January 2023” may not be a true sharp shock). The post period is still short, and retrofit subsidies/renovation behavior may confound interpretation.
- Novelty Assessment: **Medium-High.** Energy efficiency capitalization is heavily studied internationally, but **a binding rental ban with a hard threshold** is less saturated and materially different from disclosure-only settings.
- Top-Journal Potential: **Medium.** Could be very publishable if you can convincingly show (i) no bunching/manipulation around 450, (ii) enforcement is real, (iii) results replicate across later thresholds or via clean anticipation patterns—otherwise it risks reading as “another EPC/DPE capitalization paper.”
- Identification Concerns: Potential violations come from **sorting into getting a DPE**, changes in DPE methodology, bunching at the cutoff, and policy endogeneity via renovations. You’ll need density tests, “donut” RD, pre-policy placebo cutoffs, and a strategy for **address matching error** that doesn’t induce differential misclassification.
- Recommendation: **PURSUE (conditional on: credible matching at scale; clear evidence against manipulation/bunching; and a design that addresses selection into DPE availability and renovations).**

---

**#3: Encadrement des Loyers: Staggered Rent Control and Housing Sales**
- Score: **62/100**
- Strengths: Rent control remains top-journal-interest, and **Paris’s on–off–on reversal** is genuinely valuable for credibility and narrative (rare chance to test persistence/expectations). Using DVF universe data gives precision for within-market heterogeneity (by neighborhood, unit size, investor share proxies).
- Concerns: The proposal’s headline design (city-level staggered DiD) is **few treated clusters**, which is a recurring “referee-killer” for credible inference; adoption is also politically endogenous. Effects on *sales* may be indirect unless you tightly connect the policy to expected rent streams (e.g., investor vs owner-occupier segments).
- Novelty Assessment: **Medium-Low.** Rent control is extensively studied; the French institutional setting is a twist, but not automatically a field-changer without a new mechanism or measurement contribution.
- Top-Journal Potential: **Medium-Low.** To reach top-5/AEJ:Policy, it likely needs a stronger design than “few cities DiD”—e.g., **micro quasi-experimental exposure gradients** (pre-policy rent distributions, share of units above reference rent, investor intensity) and a welfare/market-supply angle.
- Identification Concerns: Besides few clusters, major threats are **endogenous adoption**, contemporaneous local housing policies, and macro shocks. You’d need randomization inference, synthetic control variants, and/or within-Paris designs that create many effective “treated intensity” units.
- Recommendation: **CONSIDER (only if you can move beyond city-level treated/control into credible within-market exposure/intensity designs and can pre-specify inference robust to few clusters).**

---

**#4: Flood Risk Designation and Housing Price Capitalization**
- Score: **55/100**
- Strengths: Within-commune comparisons across red/blue/white zones are appealing and can control for a lot of unobserved local trend heterogeneity. If you can build the GIS overlay cleanly, the design can be tight and the welfare stakes (risk + building restrictions) are real.
- Concerns: The international literature on flood risk capitalization is **very large**, so novelty is limited unless France’s PPRi creates a uniquely sharp/credible shock. Practically, **most PPRi adoption predates DVF (2014)** and plan timing is likely endogenous to flood events and local politics; GIS/data engineering risk is high.
- Novelty Assessment: **Low-Medium.** “Flood maps → prices” is crowded; “France PPRi with universe transactions” is a setting contribution, not a conceptual leap.
- Top-Journal Potential: **Low-Medium.** More likely a solid field/outlet paper unless you can (i) exploit a substantial number of post-2014 adoptions, (ii) show strong, policy-relevant heterogeneity (e.g., credit constraints/insurance), or (iii) uncover a counterintuitive substitution mechanism.
- Identification Concerns: Plan adoption correlates with **recent floods** (which directly affect prices) and with changing beliefs about climate risk. Without a strong strategy to separate “map causes price change” from “flood causes both map and price change,” estimates may not be causal.
- Recommendation: **CONSIDER (conditional on: enough post-2014 PPRi adoptions; a credible strategy to net out flood events; and a realistic GIS plan with validated zone assignment).**

---

**#5: SRU Social Housing Quotas and Private Housing Markets**
- Score: **50/100**
- Strengths: Institutional setting is important (mandatory quotas + penalties) and could speak directly to the “inclusionary zoning / social mix” debate. Linking SRU compliance and RPLS to DVF could produce informative descriptive facts about supply responses and market segmentation.
- Concerns: The proposed main shock (2013 move 20→25% and penalty increase) is poorly timed for DVF (starts 2014), leaving **insufficient pre-trends**—a common reason these papers fail. The alternative (2022 3DS exemptions) risks **high endogeneity/selection** into exemptions (“zones détendues”), making causal interpretation difficult without a sharp rule-based cutoff.
- Novelty Assessment: **Medium.** Compared to rent control/floods, SRU-specific causal evidence is less saturated internationally, but in France the policy is well-known and has been discussed/analyzed; the key issue is not novelty but credible identification.
- Top-Journal Potential: **Low.** With weak pre-period and likely endogenous treatment, it’s hard to see this clearing the bar unless you find a genuinely sharp discontinuity (eligibility thresholds, court-imposed “carence” designations with plausibly exogenous timing, etc.).
- Identification Concerns: Missing pre-period for the main reform; treatment intensity (non-compliance/penalties) is tightly linked to local demand, land constraints, and politics—all of which also drive private prices and construction.
- Recommendation: **SKIP (unless you can redesign around a sharp, rule-driven assignment with a long pre-period—otherwise it’s likely to be judged as under-identified).**

---

### Summary

This is a strong batch on data scale (DVF) and policy importance, but only two ideas currently combine **novelty + credible identification + top-journal narrative**. I would start with **Idea 1 (PTZ spatial retargeting)** as the lead “flagship” project, and run **Idea 2 (rental ban threshold)** in parallel as a high-upside second project—provided you can clear the DPE measurement/manipulation hurdles. Ideas 3–5 are either too saturated (rent control), too crowded/technically risky (flood maps), or too under-identified given the data window (SRU as currently framed).

---

## Gemini 3.1 Pro

**Tokens:** 8576

Here is my evaluation of the research proposals, ranked from most to least promising, based on the provided criteria and editorial patterns.

### Rankings

**#1: Idea 1: Does Geographic Targeting of Housing Subsidies Matter? Evidence from France's PTZ Reform**
- **Score**: 88/100
- **Strengths**: Leverages universe-level administrative data with a multi-shock design—including a rare policy reversal—to test a massive spatial reallocation of subsidies. The built-in commercial property placebo and border discontinuity design provide highly credible, multi-layered identification.
- **Concerns**: The 2020 and 2024 shocks overlap with COVID-19 and subsequent interest rate hikes, which could confound the later stages of the event study if local housing markets reacted heterogeneously to these macro shocks.
- **Novelty Assessment**: Highly novel. While the capitalization of the US Mortgage Interest Deduction has been studied, testing the *removal* and spatial targeting of a massive subsidy using universe transaction data is rare and highly valuable.
- **Top-Journal Potential**: High. It perfectly aligns with editorial preferences for "universe admin data," "internal replication" (via multiple shocks/reversals), and a clear causal chain from subsidy removal to price/supply/sorting. 
- **Identification Concerns**: The main threat is macroeconomic confounding during the 2020/2024 shocks, though the B1 vs B2/C control group and border discontinuity should absorb most aggregate shocks.
- **Recommendation**: PURSUE (conditional on: demonstrating parallel trends prior to 2018; ensuring the border discontinuity has sufficient transaction density).

**#2: Idea 2: The Rental Ban Penalty: Energy Labels and Housing Asset Values in France**
- **Score**: 78/100
- **Strengths**: Tests a first-order climate policy (asset stranding via regulatory ban) rather than mere information disclosure, using a multi-cutoff design that provides internal replication. The anticipation analysis for F-rated properties adds a compelling dynamic element.
- **Concerns**: Matching DVF transaction data to the DPE database via addresses is notoriously lossy and could introduce sample selection bias if certain types of properties fail to match.
- **Novelty Assessment**: Very novel. Shifting the literature from "energy label information premiums" to "hard regulatory rental bans and asset stranding" is a significant leap that changes how the field thinks about climate housing policy.
- **Top-Journal Potential**: High. It addresses a first-order policy question with a legible causal channel (asset stranding) and uses a multi-cutoff design that top journals favor as a storytelling device for repeated trials.
- **Identification Concerns**: There is a severe risk of density manipulation at the RDD threshold (e.g., assessors fraudulently bumping a 455 kWh property to 449 kWh to avoid the G-rating ban), which the appendix notes is a fatal flaw that invalidates RDDs.
- **Recommendation**: PURSUE (conditional on: passing McCrary density tests at the G/F thresholds; achieving a high-quality, non-biased match between DVF and DPE data).

**#3: Idea 4: Flood Risk Designation and Housing Price Capitalization**
- **Score**: 52/100
- **Strengths**: The within-commune triple-difference design elegantly controls for local macroeconomic trends and unobservables by comparing adjacent zones.
- **Concerns**: Most PPRi plans were approved well before the DVF data begins in 2014, leaving very little "new" variation to study and severely limiting statistical power.
- **Novelty Assessment**: Low to Medium. The capitalization of flood risk into housing prices is a heavily saturated literature, making it hard to stand out without a groundbreaking mechanism.
- **Top-Journal Potential**: Low. This reads exactly as the modal loss pattern described in the appendix: "technically competent but not exciting" (a standard DiD with an unsurprising sign on a saturated topic).
- **Identification Concerns**: The lack of post-2014 PPRi approvals means the study might be severely underpowered, and GIS matching errors could attenuate any measurable effects.
- **Recommendation**: SKIP

**#4: Idea 3: SRU Social Housing Quotas and Private Housing Markets**
- **Score**: 45/100
- **Strengths**: Addresses a highly relevant policy mechanism (mandatory quotas with financial penalties) that differs fundamentally from US incentive-based systems like LIHTC.
- **Concerns**: The DVF dataset starts in 2014, meaning there is zero pre-treatment data to test parallel trends for the crucial 2013 Loi Duflot reform.
- **Novelty Assessment**: Medium. The institutional setting is unique compared to the US, but the general topic of social housing spillovers is well-trodden.
- **Top-Journal Potential**: Low. The appendix explicitly notes that "data window starts after announcement/implementation" is a fatal flaw, making the 2013 reform unpublishable in a top journal.
- **Identification Concerns**: Without pre-2014 data, it is impossible to verify parallel trends or rule out anticipation effects for the 2013 reform, fatally compromising the DiD design.
- **Recommendation**: SKIP

**#5: Idea 5: Encadrement des Loyers: Staggered Rent Control and Housing Sales**
- **Score**: 35/100
- **Strengths**: The "on-off-on" judicial reversal in Paris provides a theoretically fascinating natural experiment.
- **Concerns**: With only 10-15 treated cities, the study suffers from a severe lack of clusters, making reliable statistical inference nearly impossible.
- **Novelty Assessment**: Low. Rent control is one of the most heavily studied topics in urban economics, and this proposal does not offer a new mechanism or counter-intuitive finding.
- **Top-Journal Potential**: Low. The appendix explicitly warns against "few-cluster designs" and "underpowered nulls," which this would almost certainly become given the small number of treated cities.
- **Identification Concerns**: Standard errors will be vastly understated due to the small number of treated clusters, and city-specific shocks cannot be adequately absorbed.
- **Recommendation**: SKIP

### Summary

This batch contains two highly promising ideas and three that suffer from fatal empirical or conceptual flaws. I strongly recommend pursuing the PTZ subsidy reform (Idea 1) and the DPE rental ban (Idea 2), as both leverage universe-scale data to answer first-order policy questions with clean, multi-shock identification strategies that top journals reward. The remaining ideas should be skipped due to insufficient clusters, lack of pre-treatment data, or being overly saturated in the literature.

---

## Grok 4.1 Fast

**Tokens:** 5858

### Rankings

**#1: Idea 1: Does Geographic Targeting of Housing Subsidies Matter? Evidence from France's PTZ Reform**
- Score: 82/100
- Strengths: Exceptional novelty as the first analysis of France's major PTZ subsidy removal using universe transaction data, with a multi-shock design (halving, elimination, restoration) and built-in mechanisms like price capitalization and supply response. Strong policy stakes on reallocating €3.5B/year from loose to tight markets, paired with clean data feasibility and border discontinuity for robustness.
- Concerns: Relies on zone classifications that may have some endogeneity in original designations, though border analysis mitigates this; long panel is a strength but requires careful COVID controls.
- Novelty Assessment: Highly novel— no known papers on France's 2018/2020 PTZ reforms with DVF universe data; closest is US-focused Hilber & Turner (2014), making this a clean "mirror test" of subsidy removal.
- Top-Journal Potential: High. Fits winning patterns with a legible causal chain (spatial reallocation → supply/prices/population flows), universe-scale data (3.5M sales/year), multi-shock internal replication, and trade-off discovery (loose vs. tight markets), challenging conventional wisdom on housing subsidies with clear welfare implications.
- Identification Concerns: Zone borders may not be fully exogenous if driven by local lobbying, but within-département border DD and commercial placebo address this; parallel trends testable over ample pre-period (2014-2017).
- Recommendation: PURSUE (conditional on: robust COVID sensitivity checks; full mechanism decomposition in first draft)

**#2: Idea 2: The Rental Ban Penalty: Energy Labels and Housing Asset Values in France**
- Score: 74/100
- Strengths: Novel regulatory ban mechanism (asset stranding via rental prohibition) distinct from prior disclosure studies, with sharp multi-cutoff RDD/DiD and anticipation tests for credibility. Public DPE/DVF data enables precise capitalization estimates on a timely climate policy affecting millions of units.
- Concerns: Short post-period (2.5 years for G-ban) risks underpowering dynamics; address matching adds noise and potential selection bias in DPE coverage.
- Novelty Assessment: Novel for France and bans specifically—no APEP or other papers; differentiates from UK EPC info effects, though energy labeling capitalization has some international precedents.
- Top-Journal Potential: High. Delivers a tight causal channel (ban threshold → rental value loss → price drop) with internal replication across cutoffs (G/F/E), akin to praised multi-cutoff designs; first-order climate policy stakes with counterintuitive asset stranding for investors.
- Identification Concerns: Enforcement may be uneven initially, risking attenuation bias; F-rated anticipation helps but needs pre-trend tests, and DPE data starts 2021 limiting deep pre-period.
- Recommendation: PURSUE (conditional on: successful address matching validation; power calculations for post-period)

**#3: Idea 3: SRU Social Housing Quotas and Private Housing Markets**
- Score: 64/100
- Strengths: Interesting institutional contrast to US LIHTC (mandatory quotas + penalties), with potential to unpack supply spillovers using accessible SRU/DVF data. 2022 exemptions offer a cleaner recent shock.
- Concerns: Critically short pre-period for 2013 reform (DVF starts 2014), undermining parallel trends; 2022 variation too recent for long-horizon effects.
- Novelty Assessment: Moderately novel—builds on Diamond & McQuade (2019 AER) but France's quota penalties are underexplored; no direct SRU-DVF papers, though social housing effects have scattered lit.
- Top-Journal Potential: Medium. Competent DiD on policy-relevant quotas, but lacks a belief-changing pivot or tight mechanism map; risks reading as "another housing spillover" without strong diagnostics, per modal loss patterns.
- Identification Concerns: Few newly non-compliant communes post-2013 may limit power; exemptions help but staggered timing invites rollout endogeneity without long pre-trends.
- Recommendation: CONSIDER (if pivot to 2022 exemptions with extended outcomes)

**#4: Idea 5: Encadrement des Loyers: Staggered Rent Control and Housing Sales**
- Score: 57/100
- Strengths: Paris on-off-on reversal adds identification power to staggered DiD, leveraging universe DVF for sales effects in a hot policy area.
- Concerns: Only 10-15 treated cities is a fatal few-cluster problem, explicitly penalized in reviews; competes directly with Diamond et al. (2019 AER) without a fresh angle.
- Novelty Assessment: Low to moderate—staggered rent control well-studied (e.g., Diamond McQuade Qian 2019 AER on SF); French reversals add a twist but not transformative.
- Top-Journal Potential: Low. Technically sound but "competent not exciting" per appendix—standard DiD on saturated topic without mechanism decomposition or scale to change field views; few clusters ensure RI fragility.
- Identification Concerns: Few clusters violate DiD assumptions (e.g., Sun-Abraham heterogeneity), likely collapsing under robust SEs; city-level confounders like local booms unaddressed.
- Recommendation: SKIP

**#5: Idea 4: Flood Risk Designation and Housing Price Capitalization**
- Score: 54/100
- Strengths: Within-commune triple-diff controls confounds well; PPRi data accessible for a clean risk capitalization story.
- Concerns: GIS parcel matching is highly complex and error-prone; most variation pre-DVF (2014), leaving scant post-period power.
- Novelty Assessment: Low—rich international lit on flood risk capitalization (e.g., US/EU RDDs); France PPRi underexplored but not a field puzzle.
- Top-Journal Potential: Low. Saturated topic without counterintuitive mechanism or welfare pivot; data complexity overshadows "standard capitalization" ATE, risking "niche without takeaway."
- Identification Concerns: Limited post-2014 PPRi adoptions underpower design; GIS errors could manipulate density at zone edges, a fatal RDD flaw.
- Recommendation: SKIP

### Summary
This is a strong batch overall, with two genuinely top-journal contenders (Ideas 1 and 2) leveraging France's rich housing data for novel policy shocks—far better than average submissions. Pursue Idea 1 first for its scale, reversals, and mechanisms; Idea 2 as a close second if matching works. The rest suffer fatal ID flaws (few clusters, short pre/post) or saturation, typical of appendix "losing matches."

