# Strategic Feedback — Grok-4.1-Fast

**Role:** Journal editor (AER perspective)
**Model:** x-ai/grok-4.1-fast
**Timestamp:** 2026-03-05T16:49:55.799247
**Route:** OpenRouter + LaTeX
**Tokens:** 14818 in / 2568 out
**Response SHA256:** 44af70555e5ad9e0

---

## 1. THE ELEVATOR PITCH (Most Important)

This paper examines whether Medicaid waivers lifting the 50-year-old Institutions for Mental Diseases (IMD) exclusion—a ban on federal funding for residential addiction treatment—increase the supply of behavioral health and SUD-specific providers, using novel provider-level claims data from the newly released T-MSIS dataset and staggered state adoption. It finds imprecise evidence of a modest increase in broad behavioral health providers but a puzzling decline in SUD-specific ones, concluding that coverage expansions alone do not build treatment capacity amid the opioid crisis. Busy economists should care because it challenges the assumption that payment reforms can solve supply shortages in a $78 billion annual crisis, with implications for ongoing debates over repealing the IMD exclusion and broader healthcare workforce policy.

The paper itself articulates this pitch clearly and compellingly in the first two paragraphs: the opening hooks with overdose stats and the core supply-side question, while the second nails the policy, data, and finding. No major rewrite needed, but the first two paragraphs could tighten by explicitly naming the "coverage-creates-capacity hypothesis" in para 1 and foreshadowing the null result there to heighten tension.

**Suggested first two paragraphs:**
> Between 2018 and 2024, opioid overdoses killed more than 500,000 Americans. For every death, dozens sought residential addiction treatment—but for half a century, Medicaid's Institutions for Mental Diseases (IMD) exclusion blocked federal funding for such care in facilities with >16 beds, forcing states into costly workarounds. This paper tests the coverage-creates-capacity hypothesis: when Medicaid lifts this payment ban via Section 1115 SUD waivers (adopted by 37 states post-2017), does the behavioral health provider supply expand?  
> 
> Using the newly released T-MSIS Provider Spending file (227 million records, 2018–2024) and Callaway-Sant'Anna DiD on staggered adoption, I find no robust supply response: broad behavioral health providers rise imprecisely by 25% ($p=0.12$), SUD-specific providers decline ($p=0.07$), and entry/access are null. Lifting payment bans expands coverage but does not build clinics—workforce shortages and regulations bind tighter.

## 2. CONTRIBUTION CLARITY

The paper's contribution is the first supply-side causal evidence showing that Medicaid SUD waivers lifting the IMD exclusion produce no robust increase in behavioral health or SUD-specific providers, despite prior demand-side gains.

- It differentiates modestly from closest papers (e.g., Maclean 2020, Wen 2022 on utilization; Saloner 2019 on MAT) by pivoting to supply, but could sharpen by tabling their ATTs next to this paper's nulls to quantify the "demand up, supply flat" wedge. Less differentiated from general Medicaid provider participation lit (e.g., Decker 2012, Alexander 2020), where it feels like "another paper on payment elasticities, but for IMDs."
- Framed mostly as answering a world question ("does coverage create capacity?")—strong—but slips into lit-gap mode ("tests expectation from prior demand papers").
- A smart economist could explain: "It's the supply response to IMD waivers—no dice, unlike demand." But a colleague might shorthand as "null DiD on BH providers post-waivers."
- To make bigger: Frame around a different outcome like *actual treatment beds/capacity* (not just billing NPIs, which proxy imperfectly); test mechanisms like workforce attraction via clinician NPIs by specialty; compare to non-Medicaid private SUD supply; or reframe as "why demand rose without supply: crowd-in from uninsured/self-pay?"

## 3. LITERATURE POSITIONING

This paper sits in the intersection of Medicaid policy expansions (post-ACA), opioid crisis response, and healthcare provider supply elasticities.

- Closest neighbors: Maclean et al. (2020, AER Papers & Proceedings: demand effects of SUD waivers); Wen et al. (2022: utilization); Saloner et al. (2019: MAT post-expansion); Decker (2012: Medicaid physician participation); Alexander et al. (2020: reimbursement rates and supply). Also adjacent: Haffajee et al. (2019: geographic gaps in opioid treatment access).
- Position as *building on* demand papers (their utilization gains set up this supply null, creating a policy puzzle) and *challenging* provider supply lit (payment eligibility less elastic than rate hikes). Synthesize by quantifying the demand-supply mismatch.
- Currently positioned too narrowly (health policy wonks on IMD waivers) rather than broadly appealing to general-interest health economists.
- Seems unaware of: workforce lit beyond physicians (e.g., behavioral health-specific shortages in Andrilla et al. 2019 QJM, or rural access in Cummings et al. 2019 Health Affairs); recent AER-adjacent opioid papers (e.g., Alpert et al. 2018 on overdoses, or Finkelstein et al. 2022 on Marketplace effects). Should speak to public economics (federalism in waiver adoption) and labor (healthcare workforce inelasticity).
- Right conversation? Mostly yes (opioids timely), but most impactful would connect to unexpected lit like urban econ/regulation (zoning/CON laws binding supply, à la Kleiner 2015) or IO (MCO contracting frictions as market failure).

## 4. NARRATIVE ARC

- Setup: Medicaid's IMD exclusion starved residential SUD treatment for 50 years amid opioid surge; waivers opened payment floodgates, expecting supply boom.
- Tension: Demand rose (cite prior papers), but does supply follow? Or do deeper constraints (workforce, regs) bind?
- Resolution: No—imprecise null/decline in providers, null entry/access; placebo clean.
- Implications: Rethink IMD repeal; target workforce/regs directly; demand-supply wedge means crowd-in, not expansion.

Strong narrative arc overall: intro sets stakes, results resolve soberingly, discussion/policymaking unpacks why/then-what. Not a "collection of results"—event studies, mechanisms, and demand juxtaposition cohere around "coverage ≠ capacity." To sharpen: foreground the SUD decline puzzle earlier (e.g., in abstract/intro) as "perverse compositional shift," making resolution more surprising.

## 5. THE "SO WHAT?" TEST

At a dinner party, lead with: "Medicaid finally pays for residential opioid treatment after 50 years—demand jumps 15%, but providers? Crickets. Even SUD-specific ones *decline*."

People would lean in—opioids are visceral, null challenges easy policy fixes, new data is cool, puzzling negative is quirky.

Follow-up: "But if demand rose without supply, what gives—waitlists? Price spikes? Or just rebilling the same patients?"

The null *is* interesting: precisely argues why "X doesn't work" matters (payment not binding constraint; misallocated policy effort amid 500k deaths). Makes the case well via demand contrast, power calcs, and mechanisms—but feels slightly like a failed positive experiment without harder evidence on alternatives (e.g., no bed counts or wait times).

## 6. STRUCTURAL SUGGESTIONS

- Institutional background: Way too long (20% of paper)—cut to 5 pages max, move waiver timeline/details to appendix.
- Data/empirical strategy: Front-load key summary stats and event-study visuals into intro or right after results; bury T-MSIS schema/NPPES matching in appendix.
- Results: Good front-loading (main table/figures early), but mechanism decomp (Fig 5) and heterogeneity deserve main-text promotion over some robustness.
- Robustness: Move most to appendix (e.g., estimator comparisons, RI)—keep only placebo, COVID exclusion, per-capita in main.
- Discussion: Excellent value-add (mechanisms, policy)—keep as-is.
- Conclusion: Adds little beyond summary—merge into discussion or shorten to 1 para.
- Overall: Paper front-loaded enough, but trim 20% fat (institutional/data appendices) to hit AER length.

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

Frankly: Medium-to-far. AER wants framing that reframes a field (e.g., "we thought payment was key—turns out regs/workforce bind harder") with crystal-new data/insight; this is competent policy analysis but ambition feels safe (state DiD on billing NPIs → imprecise null). Science solid (new data shoutout), but story underplays novelty (first supply test of waivers) and puzzle (SUD decline?).

Gap is mostly *framing/ambition*: Scope narrow (providers only; no beds/prices/access metrics); novelty ok but not "AER moment" without bigger hook (e.g., quantify policy waste/misallocation).

Single most impactful advice: **Reframe around the demand-supply paradox with new outcomes like treatment beds (via external facility data) or prices/caseloads per provider, and test one mechanism (e.g., MCO penetration heterogeneity) to explain the SUD decline—turn null into "why coverage failed supply, and what would work."**

### Strategic Assessment

- **Current framing quality:** Compelling
- **Contribution clarity:** Crystal clear
- **Literature positioning:** Could be stronger
- **Narrative arc:** Strong
- **AER distance:** Medium
- **Single biggest improvement:** Reframe around demand-supply paradox with added outcomes (beds/prices) and one mechanism test to diagnose the null and SUD decline.