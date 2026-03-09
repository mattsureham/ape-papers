# Research Idea Ranking

**Generated:** 2026-03-09T15:35:58.963562
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Does Aid Stabilize Government Spending? ... | PURSUE (68) | CONSIDER (60) | PURSUE (67) |
| Foreign Aid and Conflict — Geocoded Evid... | CONSIDER (56) | SKIP (42) | CONSIDER (55) |
| When the Wells Run Dry — Oil Revenue Sho... | SKIP (49) | SKIP (28) | SKIP (49) |

---

## GPT-5.4 (A)

**Tokens:** 7837

### Rankings

**#1: Does Aid Stabilize Government Spending? High-Frequency Evidence from Nigeria's Oil Crisis**
- **Score: 68/100**
- **Strengths:** This is the only idea with a clearly first-order, economically legible main outcome: government spending. If the pre-crisis treasury microdata exist, the paper has a strong causal-chain narrative — aid exposure buffers ministry spending during an exogenous fiscal collapse, potentially affecting downstream conflict.
- **Concerns:** The proposal is currently hostage to one make-or-break feasibility issue: whether usable ministry-level payment data exist for 2012-2016. Even if they do, treated ministries are not random, the number of MDAs is limited, and “aided sectors” may have been politically protected even without aid.
- **Novelty Assessment:** The broader aid fungibility/fiscal response literature is old and crowded, but this exact design — within-country, high-frequency, ministry-level spending responses to a commodity shock using administrative payment data — does look meaningfully novel. The “first use of Open Treasury” claim is valuable only if the relevant historical window actually exists.
- **Top-Journal Potential: Medium-High.** If the data are real and the pre-trends look good, this could be packaged as a sharp A→B→C paper: external aid cushions state capacity during a revenue crash, with implications for violence. That said, it is still a Nigeria-specific setting, and without the spending data it downgrades quickly to a much less distinctive crisis paper.
- **Identification Concerns:** The oil shock is plausibly exogenous, but the treatment margin is not: ministries with World Bank projects differ systematically from those without, and they may have had different crisis spending priorities regardless of aid. Inference may also be fragile with only roughly a couple dozen MDAs and one aggregate shock.
- **Recommendation:** **PURSUE (conditional on: verifying ministry-level treasury/payment data for 2012-2016; showing strong pre-trends and a defensible World Bank-project-to-MDA crosswalk; having a plan that does not rely on the 2020 COVID shock as the main design)**

---

**#2: Foreign Aid and Conflict — Geocoded Evidence from World Bank Project Closures in Nigeria**
- **Score: 56/100**
- **Strengths:** The closure margin is more novel than the generic “aid and conflict” question, and staggered project endings could generate many events rather than relying on one macro shock. If geocoded well, this could speak directly to whether aid creates local dependency or whether project withdrawal destabilizes fragile areas.
- **Concerns:** The treatment is less sharp than it sounds: project endings are often gradual, anticipated, extended, or administratively messy, so “closure” may be a noisy and partly endogenous shock. State-level conflict is also a coarse outcome for what is fundamentally a local project-level intervention.
- **Novelty Assessment:** Aid and conflict is a very crowded literature. The specific focus on planned World Bank project closures is less studied and gives the paper some originality, but it is still operating in a heavily worked area.
- **Top-Journal Potential: Low-Medium.** There is a potentially interesting design here, but the likely paper reads as “project closure timing affects conflict counts,” which is not yet a naturally top-5 object. To travel farther, it would need a much sharper mechanism and more local treatment-outcome alignment than state-month conflict alone.
- **Identification Concerns:** Planned closing dates are set in advance, but actual implementation and extensions are often responsive to project performance or local conditions, which muddies exogeneity. A before/after event study at the state level also risks contamination from overlapping projects, anticipation effects, and unrelated state-specific shocks.
- **Recommendation:** **CONSIDER**  
  *(Best as a backup project if geocoded Nigeria coverage is rich and you can work at a finer spatial unit than state-level.)*

---

**#3: When the Wells Run Dry — Oil Revenue Shocks, Aid Buffering, and State-Level Conflict in Nigeria**
- **Score: 49/100**
- **Strengths:** The policy question is real and important: whether aid insures subnational governments against commodity-driven fiscal stress. The triple-difference framing is intuitive and could, in principle, separate oil exposure, aid exposure, and crisis timing.
- **Concerns:** This feels like a weaker, noisier version of Idea 1. The outcome is indirect, the sample is small, the treatment margins are highly endogenous, and the state-level design is likely too coarse to cleanly identify an “aid buffering” mechanism.
- **Novelty Assessment:** The exact Nigeria specification may be new, but conceptually this sits close to existing literatures on commodity shocks, conflict, resource dependence, and aid in fragile settings. It does not feel like a genuinely new object.
- **Top-Journal Potential: Low.** This is the kind of paper that can be technically competent but still not excite editors: a broad triple-diff on conflict with limited treated units and many moving parts. It lacks the sharp, first-order causal narrative that typically helps these papers break through.
- **Identification Concerns:** Oil-producing states are structurally different and have direct channels from oil prices to conflict beyond state budgets, violating the clean fiscal-buffer interpretation. Pre-crisis aid intensity is also likely targeted to need, fragility, or conflict risk, so the key interaction is not plausibly exogenous.
- **Recommendation:** **SKIP**

---

### Summary

This is a mixed batch with **one genuinely worth-prioritizing idea and two much weaker backups**. **Idea 1** is the clear front-runner because it has the best combination of novelty, a first-order main outcome, and a plausible mechanism story — but only if the historical treasury microdata actually exist. **Idea 2** is a reasonable fallback if the geocoded closure data are strong and the analysis can be pushed below the state level; **Idea 3** is dominated by Idea 1 and not worth prioritizing.

---

## Gemini 3.1 Pro

**Tokens:** 7949

Here is my evaluation of the research proposals, ranked from most to least promising. 

### Rankings

**#1: Does Aid Stabilize Government Spending? High-Frequency Evidence from Nigeria's Oil Crisis**
- **Score**: 60/100
- **Strengths**: This proposal introduces a genuinely novel, untapped administrative dataset (daily treasury payments) to test a sharp, first-order mechanism (fiscal fungibility at the ministry level). Moving the aid-fungibility literature from annual cross-country regressions to high-frequency microdata is a major step forward.
- **Concerns**: There is a fatal temporal mismatch: the proposed 2014-2016 shock predates the 2019 start of the Open Treasury data. The fallback 2020 COVID shock is severely confounded, as pandemic-driven spending will naturally spike in heavily-aided ministries (like Health) for reasons entirely unrelated to aid buffering.
- **Novelty Assessment**: High. The use of daily administrative payment data to track intra-governmental aid fungibility is highly original and much better than the standard cross-country panel approach.
- **Top-Journal Potential**: Medium. Top journals love papers that introduce new administrative data to solve an old, sticky problem. If the data aligned with a clean shock, this could be a top-tier paper. However, the current data-shock mismatch prevents a higher rating.
- **Identification Concerns**: Ministries with World Bank projects (Health, Education, Infrastructure) are fundamentally different from those without (Defense, Foreign Affairs). Assuming parallel spending trends between these groups during a massive macroeconomic crisis is highly heroic.
- **Recommendation**: CONSIDER (conditional on: abandoning the 2014 and 2020 shocks; finding a clean, non-COVID exogenous fiscal shock that occurred strictly after 2019).

**#2: Foreign Aid and Conflict — Geocoded Evidence from World Bank Project Closures in Nigeria**
- **Score**: 42/100
- **Strengths**: It flips the standard "aid and conflict" question to look at aid withdrawal and dependency, utilizing predetermined project timelines rather than endogenous disbursement flows.
- **Concerns**: State-level aggregation is far too coarse; a $10M project closing in a state of 10 million people is unlikely to move aggregate state-level conflict. Furthermore, planned closures are often endogenous to local conditions.
- **Novelty Assessment**: Medium. The aid-and-conflict literature is extremely crowded. Looking at closures rather than disbursements is a slightly fresh angle, but not a paradigm shift.
- **Top-Journal Potential**: Low. As noted in the editorial patterns, diffuse "policy affects many things" stories lose. Without a sharper mechanism or overturning a canonical fact, this reads as a competent but unexciting field-journal paper.
- **Identification Concerns**: Project extensions are not a valid placebo—they are highly endogenous (projects are extended precisely because of local delays or conflict). The spatial mismatch between a localized project and state-level outcomes will severely attenuate any real effect.
- **Recommendation**: SKIP (unless redesigned at a much finer spatial resolution, such as the Local Government Area or grid-cell level, with a better instrument for actual closure).

**#3: When the Wells Run Dry — Oil Revenue Shocks, Aid Buffering, and State-Level Conflict in Nigeria**
- **Score**: 28/100
- **Strengths**: It attempts to address a macro-level policy question with clear welfare implications for resource-dependent developing nations.
- **Concerns**: The research design suffers from a severe small-N problem (only ~9 oil-producing states in Nigeria) and massive violations of the exclusion restriction. 
- **Novelty Assessment**: Low. Triple-differences on resource shocks are incredibly common, and adding an "aid buffering" interaction isn't enough to save a fundamentally flawed design.
- **Top-Journal Potential**: Low. Top journals demand pristine identification and sufficient statistical power. A kitchen-sink triple-difference relying on a handful of treated clusters will not survive a desk rejection.
- **Identification Concerns**: The exclusion restriction fails completely. A drop in global oil prices directly affects local employment, militant activity, and the shadow economy in oil-producing states (the Niger Delta). The conflict outcome is driven by this direct local economic shock, not just the fiscal revenue/aid buffering channel.
- **Recommendation**: SKIP.

### Summary

This is a generally weak batch of proposals that suffers from a common graduate-student mistake: proposing complex econometric machinery before verifying basic data feasibility and institutional realities. Idea 1 is the only proposal worth salvaging, purely because the Open Treasury Portal is a genuinely novel administrative dataset that could yield a "first-order stakes + one sharp channel" paper. I recommend pursuing Idea 1, but only after the researchers completely discard the 2014 oil shock and find a clean, post-2019 exogenous variation in fiscal capacity to match their data.

---

## GPT-5.4 (B)

**Tokens:** 8536

### Rankings

**#1: Does Aid Stabilize Government Spending? High-Frequency Evidence from Nigeria's Oil Crisis**
- **Score: 67/100**
- **Strengths:** This asks a first-order policy question with a well-matched primary outcome: whether aid actually stabilizes government spending during a major revenue shock, or is simply fungible. If the ministry-level spending data exist for the right years, the design has a credible exogenous shock and a potentially compelling causal chain from aid exposure to spending protection to downstream instability.
- **Concerns:** The entire project lives or dies on whether usable pre-2017 federal payment data exist; if not, the proposed COVID-era fallback is much less credible because the pandemic changed spending needs, aid flows, and conflict simultaneously. Even with data, the number of ministries/MDAs may be small, treated sectors may be systematically different, and mapping WB projects to MDAs could be contestable.
- **Novelty Assessment:** The aid fungibility/fiscal insurance question is not new, but this exact within-country, high-frequency, ministry-level test appears genuinely novel. The data angle is the strongest source of novelty here.
- **Top-Journal Potential:** **Medium.** This is the only idea in the set that could plausibly be framed for AEJ: Economic Policy or a strong field journal, and maybe more if the spending effects are large and clearly tied to welfare-relevant downstream consequences. But “aid buffers spending” by itself is not enough for a top-5 unless the paper delivers a very sharp new fact and a tight mechanism.
- **Identification Concerns:** WB project exposure is predetermined but not random; aided ministries are likely concentrated in politically protected or donor-salient sectors that may have different spending dynamics even absent the oil shock. With a limited number of MDAs, inference and parallel-trends diagnostics could be fragile.
- **Recommendation:** **PURSUE (conditional on: verifying ministry-level spending data for at least 2012-2016; confirming enough treated and control MDAs for credible inference; keeping conflict as a secondary mechanism rather than the core outcome)**

**#2: Foreign Aid and Conflict — Geocoded Evidence from World Bank Project Closures in Nigeria**
- **Score: 55/100**
- **Strengths:** The “aid dependency” angle is more original than another generic aid-conflict paper, and project closures are a policy-relevant margin for donor design. If geocoded project footprints are usable, staggered planned closures could generate an interesting event-study design.
- **Concerns:** As currently framed, the outcome geography is too coarse: state-month conflict is a weak match for project-level closures. Project closing dates are also less clean than advertised, since extensions, delays, and implementation problems may be correlated with local conditions.
- **Novelty Assessment:** The broader aid-conflict literature is crowded, but the specific focus on project termination/closure as a destabilizing shock is relatively understudied. So this is novel on the margin, though not in a new literature.
- **Top-Journal Potential:** **Low-Medium.** There is a contrarian story here—aid may create fragility rather than resilience—but the current design is too loose for top-journal standards. With sub-state outcomes and cleaner closure timing, it could become a respectable field-journal paper.
- **Identification Concerns:** “Planned” closure dates are not automatically exogenous if projects are extended or closed differently in response to implementation or security conditions. A simple before/after around closures risks confounding project life-cycle dynamics with treatment effects.
- **Recommendation:** **CONSIDER (conditional on: moving to sub-state outcomes near project locations; using planned closure dates as the treatment clock; verifying sufficient Nigeria coverage in geocoded WB data)**

**#3: When the Wells Run Dry — Oil Revenue Shocks, Aid Buffering, and State-Level Conflict in Nigeria**
- **Score: 49/100**
- **Strengths:** The underlying question is important: whether aid buffers fiscally exposed states during commodity shocks. The oil price collapse is exogenous to Nigerian states, and the instinct to exploit differential oil dependence is sensible.
- **Concerns:** This is the weakest package overall because it combines familiar ingredients into a noisy reduced form. Conflict is too far downstream from the policy margin, aid intensity is plainly endogenous, and the number of truly oil-dependent states is small.
- **Novelty Assessment:** Commodity shocks, aid, and conflict have all been heavily studied. The exact Nigeria triple-difference is new, but it feels more like a recombination of existing ideas than a genuinely new object.
- **Top-Journal Potential:** **Low.** In its current form this would read as a competent regional triple-diff rather than a field-shaping paper. Without direct fiscal outcomes—state spending, payroll, service delivery, FAAC allocations—it is unlikely to stand out.
- **Identification Concerns:** Pre-crisis aid intensity is likely correlated with fragility, donor targeting, and state capacity. With only 36 states, and very few strongly oil-dependent ones, both power and parallel-trends credibility are real problems.
- **Recommendation:** **SKIP**

### Summary

This is a mixed batch: one idea with real upside if the data cooperate, and two that currently look too coarse for a strong causal paper. I would **prioritize Idea 1 immediately with a fast data audit**, because it has the best combination of novelty, policy relevance, and outcome alignment; if that data check fails, I would **rework Idea 2 at a much finer geography** rather than pursue Idea 3 in its current form.

