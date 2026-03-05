# Strategic Feedback — GPT-5.2

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.2
**Timestamp:** 2026-03-05T16:49:55.796654
**Route:** OpenRouter + LaTeX
**Tokens:** 15782 in / 2682 out
**Response SHA256:** d303698be9b36ef0

---

## 1. THE ELEVATOR PITCH (Most Important)

**What the paper is about (2–3 sentences).**  
This paper asks whether expanding Medicaid payment *eligibility* for residential substance use disorder (SUD) treatment—via states’ Section 1115 “SUD waivers” that relax the long-standing IMD exclusion—actually increases the supply of behavioral health providers. Using newly released, near-universe Medicaid provider-claims data (T‑MSIS Provider Spending) and staggered waiver adoption, it studies whether “coverage creates capacity” or whether workforce/licensing/contracting constraints prevent supply from responding. A busy economist should care because many policy debates implicitly assume that expanding coverage translates into real treatment capacity; the paper’s central message is that this translation may fail.

**Does the paper itself articulate this pitch clearly in the first two paragraphs?**  
Mostly yes: the intro leads with the opioid crisis, then states the core “coverage vs capacity” question cleanly. What’s missing is an immediate, concrete statement of the paper’s novelty and stakes in economists’ terms: (i) this is the first paper using the new T‑MSIS Provider Spending release to measure *provider supply/entry* in Medicaid at scale, and (ii) it tests a widely asserted policy mechanism (lifting IMD payment restrictions) rather than “another waiver paper.”

**What the first two paragraphs should say instead (the pitch it should have).**  
> Medicaid policy often assumes that expanding coverage will automatically expand treatment capacity. This paper tests that premise in the most consequential recent U.S. behavioral health reform: states’ Section 1115 SUD waivers that (partly) lifted the IMD exclusion and allowed Medicaid to reimburse residential addiction treatment.  
>  
> Using the first public, near-universe provider-level Medicaid claims panel (T‑MSIS Provider Spending, 2018–2024) and staggered waiver adoption across states, I estimate whether opening this payment channel increased provider participation and entry. The answer is largely no: provider supply does not expand reliably, implying that workforce, licensure, and managed-care contracting frictions—not payment eligibility alone—likely bind in this sector.

---

## 2. CONTRIBUTION CLARITY

**Contribution in one sentence.**  
The paper provides the first Medicaid-wide, provider-level evidence on whether relaxing the IMD exclusion through 1115 SUD waivers increased behavioral health/SUD provider supply, and it finds little detectable supply or entry response.

**Is it clearly differentiated from the closest 3–4 papers?**  
Partially. The intro cites demand-side waiver papers (utilization, MAT receipt) and says “this is supply-side,” which is the right differentiation. But it needs sharper separation along *measurement* and *margin*: prior papers largely use discharges/utilization/enrollment aggregates; this paper uses claims-defined provider participation and entry/exit at scale. It should also be explicit that the key novelty is *provider-market outcomes in Medicaid using newly available data*, not the DiD apparatus.

**World vs literature framing?**  
It is mostly framed as a world question (“does payment create capacity?”), which is strong. The text occasionally drifts into “first to use T‑MSIS Provider Spending” as a contribution unto itself; that can be a secondary contribution, but the AER pitch must be the economic question about supply constraints and policy effectiveness.

**Could a smart economist summarize what’s new after reading the intro?**  
They could say: “It uses new claims data to test whether 1115 SUD waivers increased provider supply; looks like not.” That is more distinctive than “another DiD,” but the paper should make the novelty *crisper*: the outcome is provider participation/entry (a market-supply object), and the policy is unusually clean as a shift from zero-coverage to coverage eligibility for a facility class.

**What would make the contribution bigger? (specific, non-identification suggestions)**  
1. **Make “capacity” more literal.** Provider counts are a proxy; adding a main outcome that more directly corresponds to *treatment capacity* (e.g., residential bed capacity, facility size, or episodes in residential settings) would elevate the paper from “provider billing response” to “infrastructure response.” Even a carefully framed “capacity proxy” (share of claims in residential codes; intensity per provider; concentration; “top-10 providers’ share”) would help.  
2. **Separate “who pays” from “how much care exists.”** The paper hints at crowd-in/relabeling. If it can more prominently document a payment-source substitution story (Medicaid replacing other payers; coding shifts), that becomes a substantive economic contribution about incidence and financing rather than just a null.  
3. **Tie results to constraints.** The discussion mentions workforce/licensure/MCO friction; making one of these constraints empirically central (even descriptively) would increase the “so what” (e.g., heterogeneity by managed care penetration, baseline provider scarcity, CON laws/zoning, licensure stringency).

---

## 3. LITERATURE POSITIONING

**Closest neighbors (3–5).**  
Likely neighbors include:  
- Papers on **1115 SUD waivers and utilization/treatment** (the paper cites Maclean et al. 2020; Wen et al. 2022; and related waiver/MAT receipt work).  
- **Medicaid physician participation / supply response to payment**: Decker (2012), Alexander & Schnell (various Medicaid participation papers), Candon et al. (Medicaid fees and supply).  
- **Behavioral health access / provider shortages / geography** (e.g., county-level treatment deserts; opioid treatment program access; mental health workforce distribution).  
- More broadly: work on **coverage expansions vs real resource constraints** (the Oregon Health Insurance Experiment’s supply-side/queueing implications; Medicaid expansions and provider capacity; rationing/wait times).

**How should it position relative to those neighbors?**  
Build on demand-side waiver papers rather than “attack” them: the paper’s best role is as the missing supply-side piece that completes the equilibrium story. But it should be more explicit that earlier utilization increases do not imply capacity increases—utilization can rise via payer substitution, coding changes, or reallocations—so the paper is clarifying mechanism, not contradicting facts.

**Too narrow or too broad?**  
Currently a bit narrow in *outcome choice* (provider counts) but broad in *claimed implication* (“coverage doesn’t create capacity”). For AER-level positioning, it should either (i) broaden the capacity measurement, or (ii) tighten the claim to “payment eligibility alone doesn’t expand the Medicaid-billing provider base; adjustment occurs on other margins.”

**What literature does it seem unaware of?**  
It does not visibly engage with:  
- The **equilibrium/wait time** literature in health care markets (coverage expansions with fixed short-run supply).  
- A more explicit **industrial organization of health care providers** angle (entry costs, contracting frictions, managed care networks).  
- **Long-term care / HCBS workforce** literature might be useful for placebo/benchmarking, since the paper uses personal care as placebo but not as a conceptual comparison point.

**Is it having the right conversation?**  
The highest-impact conversation is not “waivers” per se; it’s **whether insurance expansions translate into real resource expansion in constrained health care markets**. The paper should lean harder into that umbrella and use the SUD waiver setting as a clean, policy-relevant test case.

---

## 4. NARRATIVE ARC

**Setup.** Opioid crisis + historic IMD exclusion blocked Medicaid payment for residential SUD treatment; waivers open payment channel.  
**Tension.** Policymakers assume payment eligibility will induce entry/capacity, but workforce/regulatory frictions may prevent supply response.  
**Resolution.** Provider supply/entry in Medicaid claims does not robustly increase; targeted SUD-code providers even decline; beneficiary counts don’t move.  
**Implications.** Repealing/lifting payment bans may reallocate financing without expanding real capacity; complementary supply-side interventions needed.

**Evaluation.** The arc is present and basically coherent. The risk is that the narrative currently relies on “sobering null” without fully owning what the paper can most defensibly claim: it measures Medicaid-billing provider participation (and possibly coding), not beds, staffed capacity, or clinical access. The paper’s best story is: **opening a reimbursement channel changes billing/financing much more than it changes provider entry**, consistent with binding non-price constraints.

---

## 5. THE "SO WHAT?" TEST

**Dinner-party lead fact.**  
“After 37 states got federal approval to let Medicaid pay for residential addiction treatment, we don’t see a clear increase in the number of providers participating in Medicaid—entry is basically flat.”

**Would people lean in?**  
Yes, because it challenges a common policy presumption and speaks to the broader issue of whether insurance reforms translate into real resources. But they’ll lean in *only if* the paper quickly clarifies what “provider supply” means here (billing NPIs; Medicaid participation) and doesn’t overclaim about physical capacity.

**Follow-up question economists will ask.**  
“Is this a measurement/coding story (billing shifts), a contracting lag story (implementation timing), or true absence of capacity response—and can you distinguish those?”

**If findings are null/modest: is the null interesting?**  
Potentially very interesting—this is a marquee policy lever in opioid policy. The paper does make a case for why learning “payment eligibility alone doesn’t expand provider participation” matters. To maximize the value of the null, it should foreground the alternative margins of adjustment (payer substitution, coding reclassification, intensive-margin caseload changes, network contracting) as *substantive economic mechanisms*, not post-hoc excuses.

---

## 6. STRUCTURAL SUGGESTIONS

1. **Shorten the methods/robustness in the main text; move some estimator comparison to appendix.** The paper is at risk of reading like “modern DiD + new data + null.” For AER positioning, the main text should privilege the economic question, institutional mechanism, and key empirical facts; the estimator horse-race can be compressed.  
2. **Bring forward one “diagnostic” that speaks to mechanism.** Right now, the main results arrive reasonably quickly, but the paper’s most valuable added content would be an early, prominent decomposition: organizational vs individual NPIs; residential-related codes vs outpatient; or anything that maps more tightly to the IMD channel.  
3. **Reframe the SUD-provider decline.** The “decline” is currently a surprise without a crisp economic interpretation. Either: (i) treat it as evidence of coding/composition and show a corresponding offset in broader BH codes, or (ii) downweight it and focus on the more defensible null on entry/access.  
4. **Conclusion: less summary, more implication discipline.** Tighten claims: “doesn’t expand Medicaid-billing provider base” is strong; “doesn’t build clinics” is rhetorically great but may be too literal given outcomes.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

**Gap diagnosis.** Medium-to-far from AER as currently written—not because the question is unimportant, but because the paper’s core outcome (billing-provider counts) may feel one step removed from “capacity,” and because the paper risks being read as a careful but underpowered null in a well-mined policy space (opioid/Medicaid waivers). The AER version needs either (i) a more direct measure of real capacity/access, or (ii) a sharper equilibrium/mechanism contribution about why coverage expansions fail to translate into capacity in regulated, labor-constrained provider markets.

**Single most impactful advice (if the author changes only one thing).**  
Make the paper explicitly about **equilibrium adjustment and constraints** by adding (and foregrounding) at least one main piece of evidence that distinguishes *true capacity expansion* from *billing/payer substitution/coding reclassification*—e.g., organizational NPIs tied to residential treatment, residential-code intensity, or an external capacity proxy (beds/facilities)—so the paper answers “what changed in the world?” rather than “what happened to billing-provider counts?”

---

### Strategic Assessment

- **Current framing quality:** Adequate  
- **Contribution clarity:** Somewhat fuzzy  
- **Literature positioning:** Could be stronger  
- **Narrative arc:** Serviceable  
- **AER distance:** Medium  
- **Single biggest improvement:** Recast the central result from “null on provider counts” to a mechanism-resolving equilibrium story by directly separating true capacity changes from coding/payer-substitution/contracting-lag channels (and elevate that evidence to the main results).