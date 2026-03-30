# Strategic Feedback — GPT-5.4 (R1)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-30T11:40:55.683102
**Route:** OpenRouter + LaTeX
**Tokens:** 8211 in / 3677 out
**Response SHA256:** bf7f4f52d4d21b00

---

## 1. THE ELEVATOR PITCH

This paper asks a simple, policy-relevant question: when one country legalizes cannabis and its neighbor does not, does that policy difference create enforcement spillovers across the border? Using Canada’s 2018 legalization and U.S. county arrest data near the northern border, the paper finds essentially no detectable increase in recorded drug arrests in nearby U.S. prohibition counties, suggesting that at least along a heavily monitored international border, legalization may be more geographically contained than many feared.

Why should a busy economist care? Because this is a clean test of whether cross-border policy asymmetries generate real externalities, and that question matters far beyond cannabis: it speaks to when countries need policy coordination and when they can safely diverge.

### Does the paper articulate this pitch clearly in the first two paragraphs?

Reasonably well, but not optimally. The current introduction gets to the question quickly, but it undersells the core economic issue: **policy interdependence across borders**. It also leans too fast into cannabis-specific motivation and policy examples, rather than making the broader conceptual point first. The best version of this paper is not “a DiD on cannabis arrests”; it is “a test of whether national policy divergence creates local enforcement externalities across an international border.”

### The pitch the paper should have in the first two paragraphs

> Countries often worry that liberalizing a regulated market will export costs to their neighbors. If legalization in one jurisdiction increases trafficking, enforcement, or crime in nearby prohibition areas, then national policy autonomy is limited by cross-border externalities. Yet despite the centrality of this concern in debates over drugs, migration, taxation, and environmental policy, there is little direct evidence on whether a sharp international policy divergence actually changes local enforcement outcomes across a border.
>
> Canada’s 2018 cannabis legalization created an unusually clean test: a single national reform along the world’s longest international border, with cannabis legal on one side and prohibited in many adjacent U.S. counties on the other. This paper studies whether that policy shock increased recorded drug-enforcement activity in nearby U.S. prohibition counties. It finds no detectable increase in drug arrests near the border, and the estimates rule out anything but modest positive spillovers. The broader lesson is that even salient international policy asymmetries may generate less local enforcement disruption than critics predict when borders are formal, monitored, and institutionally thick.

That is a stronger AER-style opening because it begins with a general economic question, uses cannabis as the empirical laboratory, and ends with a take-home lesson about the world.

---

## 2. CONTRIBUTION CLARITY

### Contribution in one sentence

The paper provides the first evidence, to my knowledge, on whether a sharp international cannabis legalization shock generated local enforcement spillovers across the U.S.-Canada border, and finds that it did not measurably increase recorded drug arrests in adjacent U.S. prohibition counties.

### Is this contribution clearly differentiated from the closest papers?

Partially, but not sharply enough. The paper says “no published paper uses the international U.S.-Canada border,” which is a factual novelty claim, but novelty of setting is not enough. The introduction currently differentiates itself mostly by geography and treatment timing. That is weaker than differentiating itself by **question**.

The closest distinction should be:

- Domestic border-spillover papers ask whether legalization in one U.S. state displaces activity into neighboring states.
- This paper asks whether **international** legalization spillovers are contained by border institutions, federal enforcement, and port-of-entry monitoring.
- Therefore the paper is not just another spillover paper in a different setting; it is a test of whether border thickness and state capacity mediate cross-jurisdiction externalities.

That is the intellectually meaningful differentiation.

### Is the contribution framed as answering a question about the WORLD, or filling a gap in a LITERATURE?

Mixed, but too much on the literature-gap side. The better frame is about the world:

- Weak frame: “No paper has studied the international border case.”
- Strong frame: “When neighboring countries diverge in drug policy, are spillovers large enough to constrain national sovereignty?”

The latter is much more AER-relevant.

### Could a smart economist who reads the introduction explain to a colleague what’s new?

Right now, they would probably say: “It’s a DiD on whether Canada’s legalization affected drug arrests in nearby U.S. counties, and it finds basically nothing.”

That is not fatal, but it is not strong enough. You want them to say: “It’s a clean test of whether an international policy divergence created enforcement externalities across a real border, and the answer appears to be no.”

### What would make this contribution bigger?

Most importantly: **broaden the object from drug arrests to cross-border externalities more generally**, or at least make clear why arrests are the right margin for the paper’s claim.

Specific ways to make the contribution bigger:

1. **Different outcome variable**
   - The paper’s current outcome is narrow: recorded drug arrests.
   - Bigger contribution if paired with outcomes that better capture the concern policymakers actually have: seizures, trafficking incidents, DUI, ER visits, property crime, customs activity, or local public safety measures.
   - If those data are unavailable, the paper needs to justify more aggressively why arrests are still the right revealed-outcome for enforcement costs.

2. **Different mechanism framing**
   - The current mechanism discussion is somewhat negative: “COVID closure does not support trafficking.”
   - Bigger paper if it explicitly argues that **formal borders plus centralized screening contain arbitrage**.
   - That turns the paper into evidence on when policy spillovers are institutionally dampened.

3. **Different comparison**
   - A stronger contribution would compare the international border result to known domestic-border spillovers and ask: why are domestic spillovers larger than international ones?
   - That comparative framing would elevate the paper considerably.

4. **Different framing**
   - The big question is not cannabis per se.
   - The big question is: **When does policy divergence across jurisdictions require coordination?**
   - The cannabis setting is the clean application.

---

## 3. LITERATURE POSITIONING

### Closest neighbors

Based on the citations and field, the closest neighbors seem to be:

1. **Hansen, Miller, and Weber (2020)** on within-U.S. border spillovers from recreational cannabis legalization.
2. **Adda, McConnell, and Rasul (2014)** on depenalization and crime/policing.
3. **Gavrilova, Kamada, and Zoutman (2019)** on medical marijuana laws and violent crime via trafficking channels.
4. **Dragone et al. (2019)** on market effects of decriminalization/legalization.
5. Possibly **Masera-type neighboring-state spillover work** and **DeAngelo-type work on arrest declines within legalizing states**.

### How should the paper position itself relative to those neighbors?

Build on them, but sharpen the contrast.

- Relative to domestic-border papers: “Those papers show spillovers can exist when borders are porous and institutional environments are similar. This paper asks whether the same is true across an international border with formal screening and federal enforcement.”
- Relative to depenalization/crime papers: “Those papers study within-jurisdiction effects of cannabis reform on crime or policing. This paper studies cross-jurisdiction externalities.”
- Relative to trafficking papers: “Those papers emphasize market reallocation and criminal organization responses. This paper studies whether those forces are strong enough to show up in local enforcement on the other side of a national border.”

So: build, don’t attack. But be much more explicit that the paper’s comparative advantage is **institutional context**, not merely “Canada instead of Colorado.”

### Is the paper currently positioned too narrowly or too broadly?

Currently too narrowly in empirical execution and a bit too broadly in rhetorical policy extrapolation.

- Too narrow because it is really about one outcome: county-level drug arrests.
- Too broad when it implies lessons for Germany, Thailand, Mexico, etc. That leap feels generic and unearned given the narrowness of the measured outcome and the specificity of the U.S.-Canada border.

The right level is: **an international-border spillover paper with implications for policy coordination under strong border institutions**.

### What literature does the paper seem unaware of? What fields should it be speaking to?

It should engage more clearly with:

1. **Fiscal federalism / interjurisdictional externalities**
   - Oates/Tiebout-style logic is not directly about drugs, but the broader issue is policy competition and spillovers across jurisdictions.
   - That is a more foundational economics conversation than just the cannabis literature.

2. **Border economics / market integration**
   - Literature on how thick borders attenuate arbitrage, trade, and pass-through.
   - The paper’s result is really about border frictions limiting spillovers.

3. **Law and economics of enforcement substitution**
   - Arrests reflect both activity and effort. There is a broader literature on policing margins, enforcement priorities, and administrative responses that could help motivate the outcome choice.

4. **Political economy of policy coordination**
   - The paper hints at international coordination, but doesn’t anchor itself in that literature.

### Is the paper having the right conversation?

Not quite. It is currently having a somewhat narrow “cannabis and crime” conversation. The more impactful conversation is:

- cross-jurisdiction policy externalities,
- when borders contain spillovers,
- and when policy harmonization is actually necessary.

That is the conversation that could make the paper matter beyond specialists.

---

## 4. NARRATIVE ARC

### Setup

Countries increasingly diverge in cannabis policy. Many policymakers fear that legalization in one place exports enforcement burdens to nearby prohibition areas.

### Tension

We have lots of within-jurisdiction evidence and some domestic-border evidence, but we do not know whether a sharp **international** policy asymmetry creates local enforcement spillovers, especially when the border is formal and monitored. Canada’s legalization generated a dramatic and politically salient discontinuity, while seizure data suggest something changed at the border.

### Resolution

Despite increased federal seizures, nearby U.S. prohibition counties do not experience detectable increases in recorded drug arrests after legalization. The paper’s preferred estimates bound any positive spillover at a modest level.

### Implications

The burden of policy divergence may be smaller than critics assume, at least where borders are institutionally thick. This implies that national policy autonomy may be more feasible than coordination arguments suggest.

### Does the paper have a clear narrative arc?

It has the ingredients, but the arc is only partially assembled. Right now the most vivid narrative element is the “CBP seizure paradox,” which is good and should be elevated. That is the natural tension in the paper:

- federal border seizures spike,
- but local arrests do not.

That juxtaposition is memorable and helps the reader understand why the paper matters.

At present, the paper is somewhat close to “a collection of sensible estimations around a null result.” To become a stronger paper, it should tell a more explicit story:

> **International policy divergence looked likely to create spillovers; federal seizure data reinforced that concern; but local enforcement did not rise, implying that the border absorbed the shock rather than transmitting it inland.**

That is the story.

The COVID closure material is less central than the paper thinks. It may be a useful diagnostic, but it is not the main narrative engine and should not be allowed to dominate the story.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with at a dinner party of economists?

“Canada legalized cannabis, border seizures jumped sharply, but drug arrests in neighboring U.S. prohibition counties did not.”

That is a good lead fact. It creates immediate tension.

### Would people lean in or reach for their phones?

Some would lean in, especially applied micro people interested in crime, policy spillovers, and borders. But the response depends heavily on presentation. If presented as “a null DiD on drug arrests,” phones. If presented as “evidence that an international border contained what looked like an obvious policy externality,” people lean in.

### What follow-up question would they ask?

Almost certainly: “Does that mean there were truly no spillovers, or just none in arrests?”  
And then: “Why did seizures rise without local enforcement rising?”

Those are exactly the questions the paper needs to foreground, not dodge.

### Is the null interesting?

Yes, conditionally. A bounded null can be very interesting when:
- the prior expectation of a positive spillover is real,
- the setting is unusually clean,
- and the paper can rule out effects of policy-relevant magnitude.

This paper is close to that, but it needs to work harder to establish the prior. Right now the paper says the question matters, but it does not fully convince the reader that many informed observers expected meaningful local spillovers. The CBP seizure increase helps here; it should be deployed earlier and more forcefully as evidence that the concern was not hypothetical.

The null feels informative, not like a failed experiment. But only if the authors keep emphasizing: **we can rule out more than trivial local enforcement spillovers in a setting where many people expected them.**

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Shorten the literature review in the introduction**
   - The current citation parade slows momentum.
   - Replace the long list with a more analytical paragraph grouping papers into:
     - within-jurisdiction effects,
     - domestic-border spillovers,
     - trafficking/crime effects.
   - The reader does not need a catalog in paragraph 7 of the introduction.

2. **Move some design detail later**
   - The introduction currently gets technical fairly early.
   - In the intro, keep only the essential design intuition: border vs interior within prohibition states, before and after legalization.

3. **Front-load the “seizure paradox”**
   - This is one of the most interesting aspects of the paper and should appear in the introduction, not after the main tables.
   - It helps the reader understand both why the question matters and why the result is surprising.

4. **Demote the COVID regime from starring role to supporting role**
   - The paper currently gives the three-regime structure a lot of emphasis.
   - But because the authors themselves acknowledge COVID confounds, it cannot carry too much interpretive weight.
   - Present it as a suggestive mechanism diagnostic, not a headline innovation.

5. **Tighten the conclusion**
   - The conclusion is competent but mostly summarizing.
   - It should end with a sharper general takeaway: policy divergence does not automatically imply local externality when borders are formal and monitored.

6. **Possibly move the standardized effect-size appendix material out of the manuscript**
   - It adds little to the strategic positioning.

### Is the paper front-loaded with the good stuff?

Moderately. The reader learns the main result in the introduction, which is good. But the most interesting interpretive hook—the divergence between federal seizures and local arrests—is not front-loaded enough.

### Are there results buried in robustness that should be in the main results?

Not exactly buried, but the leave-one-state-out insight that the weighted result is basically a New York story is important and should be integrated more directly into the discussion of preferred estimates.

### Is the conclusion adding value or just summarizing?

Mostly summarizing. It should do more conceptual work.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

At present, the main gap is **framing plus ambition**, with some scope limitations.

### What is the gap?

#### 1. Framing problem
Yes. The science, at least as presented, is competent and coherent, but the paper is still framed too much as a narrow cannabis enforcement study. AER wants a paper that uses a specific empirical setting to answer a broader economic question. That broader question is here, but not fully claimed.

#### 2. Scope problem
Also yes. One outcome—drug arrests—is probably too narrow for a top general-interest placement unless the framing is exceptionally strong. The paper needs either:
- broader outcomes,
- stronger comparative framing,
- or a more explicit conceptual contribution about borders and externality containment.

#### 3. Novelty problem
Partial. The setting is novel; the empirical design is conventional. Novel setting plus null result plus conventional design is usually not enough for AER unless the paper is clearly answering a first-order question.

#### 4. Ambition problem
Yes. The paper feels careful but safe. It is satisfied with saying “there is no detectable effect on arrests.” The more ambitious paper would say:
- what this teaches us about cross-border externalities,
- why domestic and international spillovers differ,
- and what conditions make policy externalities containable.

### The single most impactful piece of advice

**Reframe the paper as a test of when cross-jurisdiction policy externalities are contained by borders and institutions—not as a cannabis-arrest paper—and reorganize the introduction and discussion around the seizure-arrest divergence as the central puzzle.**

If the author can only change one thing, that is it.

Because if the framing is fixed, the current evidence becomes more interesting. If the framing is not fixed, this remains “a nice null result in a narrow setting.”

---

### Strategic Assessment

- **Current framing quality:** Adequate
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium-Far
- **Single biggest improvement:** Recast the paper as evidence on whether formal international borders contain policy externalities, using cannabis as the setting rather than the topic.