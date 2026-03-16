# Strategic Feedback — GPT-5.4 (R1)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-16T00:35:27.987333
**Route:** OpenRouter + LaTeX
**Tokens:** 10658 in / 3532 out
**Response SHA256:** c8af401ed9f446fa

---

## 1. THE ELEVATOR PITCH

This paper asks whether the PPP Second Draw’s headline eligibility rule—a 25% revenue-loss threshold—actually shaped which nonprofits got aid, and whether that aid preserved nonprofit employment. Using linked SBA PPP records and IRS Form 990 data, the paper’s core claim is that for nonprofits the threshold was effectively irrelevant: organizations just on either side of the cutoff looked the same in loan receipt, suggesting a mismatch between program design and the administrative reality of the nonprofit sector.

A busy economist should care because this is, potentially, not just another PPP paper. The bigger idea is that policy rules only matter if they map onto the information systems of the populations they target; otherwise statutory eligibility can be functionally decorative.

### Does the paper articulate this pitch clearly in the first two paragraphs?

Not really. The current opening starts with PPP’s scale, then says no one has studied nonprofits using Form 990. That is a literature/data pitch, not a world/question pitch. The interesting idea arrives later: emergency programs can fail not because funds are too small or misallocated geographically, but because eligibility rules are designed around the wrong administrative infrastructure.

### What the first two paragraphs should say instead

The paper should open with something like:

> Emergency relief programs are implemented through administrative systems, not in the abstract. When policymakers define eligibility using information that target organizations do not routinely generate, statutory rules may exist on paper but not in practice. This paper studies that problem in the nonprofit sector by examining the Paycheck Protection Program’s Second Draw requirement that applicants show a 25% quarterly revenue decline.
>
> Linking SBA PPP microdata to IRS Form 990 filings, I ask whether that threshold actually governed nonprofit access to aid and whether the resulting funding preserved employment. The central result is that the threshold does not appear to structure nonprofit borrowing at all: organizations just above and below the cutoff are equally likely to receive Second Draw loans. The broader implication is that emergency program design can break when eligibility rules are misaligned with the reporting technology of the sector being targeted.

That is the pitch. The dataset is supporting infrastructure, not the lead.

---

## 2. CONTRIBUTION CLARITY

### Contribution in one sentence

The paper’s contribution is to argue that the PPP Second Draw’s revenue-loss eligibility rule did not meaningfully govern nonprofit access to aid, revealing a broader design failure from misalignment between policy rules and sector-specific administrative data.

### Is this contribution clearly differentiated from the closest 3-4 papers?

Only partially. The paper says it is “the first” to study nonprofits with Form 990 and “the first” to test whether the threshold was binding. Those are fine priority claims, but they are not enough for AER positioning. “First nonprofit PPP paper” is a niche claim; “first to show that policy eligibility can be non-operative when administrative systems are mismatched” is potentially broader and more important.

Right now the differentiation is too method/data-specific:
- first linked dataset,
- first nonprofit application,
- first threshold test.

That reads like a competent field-journal contribution. For AER, the paper needs to differentiate on an idea:
- eligibility rules can fail to allocate when they are built for one organizational form and transplanted onto another;
- administrative capacity and documentation regimes can dominate formal statutory criteria in crisis policy;
- sectoral heterogeneity in reporting technologies matters for policy incidence.

### Is the contribution framed as answering a question about the WORLD, or filling a gap in a LITERATURE?

Mostly as a literature gap. The introduction literally says no study has used Form 990. That is weak framing. The stronger framing is a world question: **When do eligibility rules actually bind?** Or: **Can administrative mismatch render formal policy rules ineffective for entire sectors?**

### Could a smart economist explain what’s new after reading the introduction?

Not cleanly. Right now they would probably say: “It’s a PPP paper on nonprofits using linked tax data, and the threshold doesn’t show up.” That is better than “another DiD paper,” but it is still too close to “another administrative-data paper about PPP.”

The intro does not yet make the reader say: “Ah, this is about policy design under administrative constraints.”

### What would make the contribution bigger?

Several possibilities:

1. **Make the object of study policy design, not nonprofit PPP per se.**  
   The paper should explicitly frame the nonprofit setting as a test case for a general proposition: targeting rules only work when they use verifiable, routinely produced information.

2. **Show what *did* allocate funds instead of just what did not.**  
   The paper gestures toward banking relationships and organizational capacity. If the paper can more sharply document the actual margin of allocation, the story gets much bigger: formal eligibility did not allocate; informal/administrative capacity did.

3. **Expand beyond employment to a more sector-relevant outcome.**  
   Nonprofit employment is not obviously the most important margin. Outcomes like organizational survival, service provision, fundraising composition, expenses, program spending, or liquidity would better fit the nonprofit context and make the story less like an awkward transplant of a firm-employment paper.

4. **Compare nonprofits to for-profits.**  
   This would be the biggest possible expansion in scope. If the same rule appears to bind in for-profit settings but not in nonprofit settings, the paper becomes much more compelling as evidence of sector-specific administrative mismatch rather than just a null in one sample.

5. **Lean into the “decorative rule” idea.**  
   The most memorable contribution is not a null first stage; it is that a major federal program had an eligibility rule that may have been practically irrelevant for a large class of organizations.

---

## 3. LITERATURE POSITIONING

### Closest neighbors

The obvious nearby papers/literatures are:

- **Autor et al.** on PPP employment effects.
- **Chetty et al.** / Opportunity Insights style work on PPP and small business employment.
- **Granja et al.** on PPP targeting and who got funds.
- **Bartik et al.** on banking relationships and access to PPP.
- On nonprofits: papers on nonprofit financial vulnerability and organizational behavior, e.g. **Calabrese**, **Hager**, **LeRoux**.

There is also a broader public economics / state capacity / administrative burden conversation that the paper should enter more directly, even if it does not yet cite it fully.

### How should it position itself relative to those neighbors?

Mostly **build on** the PPP allocation literature and **bridge** it to public administration/state capacity/administrative burden. It should not “attack” the existing PPP papers. Those papers asked different questions, often for firms; this paper asks whether the statutory rule itself mattered in a sector with different reporting and organizational technology.

The paper should say, in effect:
- Existing PPP work studies aggregate employment effects, targeting, and bank-mediated allocation.
- This paper adds a different lens: whether the program’s formal screening rule actually operated as screening in the nonprofit sector.
- The answer appears to be no, implying that implementation capacity and documentation regimes may matter more than legal design.

### Is the paper positioned too narrowly or too broadly?

Currently, too narrowly in substance and oddly broad in ambition. It is narrow because it is framed as “PPP for nonprofits using Form 990.” It is broad because it sometimes implies sweeping claims about program design generally without enough narrative scaffolding.

It should be positioned as:
- a nonprofit paper substantively,
- but a policy design / administrative-state paper conceptually.

That is the right combination.

### What literature does the paper seem unaware of?

It seems under-engaged with:
- **administrative burden** and take-up literatures,
- **state capacity / implementation** literatures,
- **screening/targeting under imperfect information**,
- potentially **public administration** work on nonprofit-government interfaces,
- possibly disaster relief / emergency aid design literatures.

Right now the paper speaks mainly to PPP and nonprofit finance. That is too small a conversation for the claim it wants to make.

### Is it having the right conversation?

Not yet. The most impactful framing may come from connecting PPP to the economics of administration: a rule that cannot be verified from standard sectoral records may not discipline allocation the way policymakers imagine. That is a much better conversation than “here is a nonprofit-specific PPP null.”

---

## 4. NARRATIVE ARC

### Setup

PPP Second Draw used a 25% revenue-loss rule to target aid to distressed organizations. Nonprofits were a major recipient group, but they differ from firms in revenue structure, reporting, and financial administration.

### Tension

A rule designed around quarterly revenue documentation may not map well onto nonprofits, which typically generate annual IRS filings rather than quarterly financial reporting. So the formal targeting architecture may not have actually governed who got money.

### Resolution

In the linked data, the threshold does not appear to separate recipients from non-recipients among nonprofits; meanwhile, simple positive employment correlations look like selection rather than treatment.

### Implications

The broader implication is that policy design has to fit the information environment of target sectors. Otherwise, formal eligibility rules may not allocate in practice, and program incidence may be driven by capacity, intermediaries, or relationships instead.

### Does the paper have a clear narrative arc?

It has the ingredients, but the arc is underpowered. At present it feels like:
1. here is a new dataset,
2. here is an RD that is null,
3. here is an OLS showing selection,
4. therefore program design mattered.

That is closer to a collection of findings than a fully worked story. The OLS-selection section in particular feels tacked on: it is interesting, but it is not yet integrated into the main narrative. Is the paper about a nonbinding threshold, or about selection into PPP, or about what outcomes PPP had? It wants to be all three.

### What story should it be telling?

The clean story is:

- **Setup:** Policymakers attempted to target emergency aid with a simple revenue-loss rule.
- **Tension:** But targetability depends on whether the rule matches the accounting and reporting systems of recipients.
- **Resolution:** For nonprofits, the rule appears not to structure observed access at all.
- **Implication:** Allocation likely ran through organizational/banking capacity rather than formal revenue screening, so emergency aid design must be built around sector-specific administrative realities.

In that version, the OLS/placebo evidence is not a second paper hiding inside the first; it is corroborating evidence that something other than the formal rule drove allocation.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with?

I would lead with: **A $67 billion nonprofit aid program had a statutory eligibility threshold that appears not to have governed nonprofit access at all.**

That is a good dinner-party fact. Better than “the first stage is zero.” The latter is econometric; the former is substantive.

### Would people lean in or reach for their phones?

Some would lean in—especially people interested in public economics, state capacity, nonprofits, and crisis policy. But many economists will only lean in if the paper makes the general lesson vivid. If it stays at “in Form 990 data I don’t detect a discontinuity,” they will reach for their phones. If it becomes “formal targeting rules can fail when they are incompatible with sectoral reporting systems,” they will pay attention.

### What follow-up question would they ask?

Probably one of these:
1. “So what actually determined who got the money?”
2. “Is this specific to nonprofits, or a more general implementation problem?”
3. “Did this mismatch matter for outcomes, or just for observability?”
4. “Would the rule have looked binding in for-profit data?”

Those are exactly the questions the paper should anticipate and organize itself around.

### If the findings are null or modest, is the null itself interesting?

Yes—but only if the paper sells it correctly. A null first stage is interesting here because it speaks to whether the formal policy mechanism operated at all. That is not a failed attempt to find an effect; it is a finding about policy implementation. But the paper needs to make that case much more sharply and repeatedly. Right now it still sometimes reads like an evaluation that could not identify an effect, rather than a diagnosis that the official allocation rule was not the operative margin.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Shorten the data-construction self-description.**  
   The “first linked dataset” point should remain, but the introduction spends too much energy on linkage mechanics relative to the conceptual contribution.

2. **Front-load the main substantive claim earlier.**  
   The paper gets to the strong line—“the rule was invisible to the administrative data nonprofits generate”—too late. That should appear on page 1, not after the empirical setup.

3. **Demote some econometric throat-clearing.**  
   Since this is an editorial memo about positioning: the paper currently devotes too much valuable real estate to proving that the author knows the RD is imperfectly measured. That may be necessary somewhere, but it should not dominate the narrative.

4. **Integrate the OLS/placebo section more tightly or cut it back.**  
   As written, it feels like a second contribution. Either explicitly present it as evidence that non-statutory factors determined allocation, or shorten it substantially. Right now it muddies the paper’s center of gravity.

5. **Move some robustness material out of the main text.**  
   Placebo cutoffs and bandwidth sensitivity can stay, but the paper should not interrupt the main story with too much detail before the reader fully understands why the null matters.

6. **Strengthen the conclusion.**  
   The conclusion has the right instinct—“eligibility rules become decorative rather than allocative”—but the paper should earn that line earlier and then extend it to a broader class of policy problems.

### Is the paper front-loaded with the good stuff?

Not enough. The most interesting idea is buried under setup about nonprofit differences and data novelty. The reader should learn by paragraph 2 that the central claim is: **a major federal eligibility rule may have been operationally irrelevant in this sector.**

### Are there results buried in robustness that belong in the main text?

The strongest supporting result, conceptually, is whatever most directly shows that allocation was governed by something other than the threshold. If there is any simple descriptive evidence by lender type, prior banking relationships, organization size bins, or administrative sophistication, that belongs front and center more than another placebo cutoff.

### Is the conclusion adding value?

Somewhat. It has a strong sentence, but mostly summarizes. It should do more to generalize: when government targets through documentation, the relevant unit is not just the economic actor but the actor’s reporting technology.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

At the moment, the gap is mainly a **framing plus ambition** problem, with a secondary **scope** problem.

- **Framing problem:** The paper understates its big idea and overstates its dataset/literature-gap story.
- **Ambition problem:** It is content to show a null threshold and a selection placebo, but AER would want the paper to more directly answer the deeper question: if formal eligibility did not allocate, what did?
- **Scope problem:** Employment may not be the most natural or richest outcome in nonprofits, and the paper would be stronger if it broadened outcomes or added a comparison showing the nonprofit result is distinctive.

I do **not** think the central obstacle is novelty in the narrow sense. The idea is novel enough if framed correctly. The issue is that the paper currently presents a potentially important idea in the format of a careful but modest specialty-field paper.

### Single most impactful advice

**Reframe the paper around a general proposition—eligibility rules only allocate when they fit the administrative data environment of the target sector—and make the nonprofit PPP analysis the sharp empirical demonstration of that proposition, not the proposition itself.**

If they only change one thing, it should be that.

---

### Strategic Assessment

- **Current framing quality:** Needs rethinking
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium
- **Single biggest improvement:** Recast the paper from “the first nonprofit PPP study using Form 990” into “a demonstration that policy eligibility rules can be non-operative when they are misaligned with sectoral administrative infrastructure.”