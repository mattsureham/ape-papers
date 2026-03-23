# Strategic Feedback — GPT-5.4 (R2)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-23T13:38:06.261411
**Route:** OpenRouter + LaTeX
**Tokens:** 9942 in / 4008 out
**Response SHA256:** cdfeb661a70b4513

---

## 1. THE ELEVATOR PITCH

This paper asks a simple policy question with broad appeal: when the U.S. sharply reduced the H-1B visa cap in 2003, did native skilled workers benefit or get hurt? Using quarterly county-level labor-market data, the paper argues that in more tech-exposed places, the restriction lowered young native professionals’ earnings and reduced labor-market churn, consistent with skilled immigrants being complements rather than substitutes.

A busy economist should care because this is a first-order question in immigration, labor, innovation, and policy design: if restricting high-skill immigration harms rather than helps the intended beneficiaries, that changes how we think about one of the central labor-market policy debates of the last two decades.

### Does the paper articulate this clearly in the first two paragraphs?

Reasonably well, but not optimally. The current opening is competent and readable, but it still sounds too much like “another immigration paper testing substitutes vs complements” and too little like “a major policy reversal that lets us observe the anatomy of local adjustment to cutting skilled immigration.” The first two paragraphs should do less literature scene-setting and more agenda-setting.

Right now the introduction gets to the core fact fairly quickly, but it overinvests in generic framing (“standard framing treats workers as substitutes”) and underinvests in making the reader feel the stakes: this was a large national contraction in skilled labor supply, and the paper claims the intended beneficiaries lost earnings rather than gained them. That is the headline.

### The pitch the paper should have

> In 2003, the United States cut the H-1B cap by two-thirds. Many policymakers viewed this as a test of whether restricting skilled immigration would raise native workers’ wages. This paper shows the opposite: in counties more dependent on H-1B-type labor, young native professionals experienced lower earnings and less job-to-job mobility after the cap reduction, suggesting that skilled immigrants raise natives’ productivity rather than simply competing for their jobs.  
>
> The contribution is not just the sign of the effect, but its timing. Using quarterly administrative data, the paper traces how the earnings penalty emerges within a few quarters and persists, offering a dynamic picture of how local labor markets adjust when firms lose access to skilled immigrant labor.

That is the AER-facing version: sharp question, important fact, broad implication, clear novelty.

---

## 2. CONTRIBUTION CLARITY

### One-sentence contribution

The paper’s contribution is to show, using quarterly administrative labor-market data around the 2003 H-1B cap reduction, that cutting skilled immigration appears to reduce rather than raise the earnings of young native professionals in more exposed local labor markets.

### Is this clearly differentiated from the closest papers?

Only partially. The paper gestures at novelty—quarterly data, local dynamics, DDD—but the differentiation is not yet sharp enough. The reader can see that this is “another paper on H-1B and native outcomes,” but not yet why this one is decisively different from the best-known papers.

The introduction should more crisply separate itself from at least four nearby strands:

1. **Peri, Shih, and Sparber (STEM immigration and native wages/productivity)**  
   Difference: they study broader STEM immigration and annual outcomes; this paper studies a discrete H-1B restriction and quarterly adjustment.

2. **Kerr and Lincoln (H-1B and innovation/employment)**  
   Difference: they focus heavily on firms/cities and innovation responses; this paper focuses on native labor-market outcomes and adjustment dynamics.

3. **Bound et al. / Doran et al. on H-1B incidence and lottery-based or quasi-experimental evidence**  
   Difference: those papers study firm-level or program-level responses; this paper studies geographically heterogeneous local labor-market incidence.

4. **Borjas-style immigration incidence papers**  
   Difference: this is about high-skill immigration restrictions, and the main margin is earnings/churn rather than employment.

At present the introduction lists literatures rather than drawing battle lines. It needs a sentence of the form: “Relative to X, we observe Y; relative to Z, we identify local native incidence rather than firm innovation; relative to W, we trace dynamic adjustment at quarterly frequency.”

### Is the contribution framed as answering a question about the world, or filling a gap in a literature?

Mostly the former, which is good. The world question is strong: do high-skill immigration restrictions help native workers? But the paper periodically slips back into “first quarterly-frequency evidence” language. “First” claims are fragile and rarely what makes a paper matter. The stronger framing is not “there is a literature gap in quarterly evidence,” but “policymakers routinely defend H-1B restrictions as worker protection; this paper asks whether that claim is true.”

### Could a smart economist explain what’s new after reading the introduction?

Barely. They could probably say: “It’s a DDD paper using QWI showing H-1B restrictions hurt young native workers in tech counties.” That is decent, but still too method-tagged. The goal is for them to say: “It shows that a major cut in skilled immigration reduced native earnings where exposure was highest, and the interesting thing is that the harm shows up quickly in wages and turnover rather than employment.”

Right now there is still some risk of the “another DiD paper about immigration” reaction.

### What would make this contribution bigger?

Three possibilities, in descending order of strategic value:

1. **Make the paper about the incidence of high-skill immigration restrictions on native workers broadly, not just quarterly dynamics.**  
   The dynamics are a nice feature, not the main event. The core contribution is the sign and incidence of the policy.

2. **Bring mechanisms closer to center stage.**  
   Right now “complementarity” is plausible but not yet vivid. A bigger paper would show whether the earnings effects are strongest in occupations/industries/tasks where immigrant-native team production should matter most, or in tradable/innovation-intensive sectors, or in counties with more H-1B-reliant employers.

3. **Connect local labor outcomes to broader economic margins.**  
   The paper hints at reallocation into retail/healthcare. If framed properly, that could become a more ambitious claim: restrictions may not just lower earnings; they may push skilled natives away from high-productivity sectors. That is a much bigger “so what” than a 1.5 percentage-point earnings decline alone.

The single biggest way to enlarge the contribution is to pivot from “quarterly evidence on complementarity” to “the incidence of skilled immigration restrictions falls on the very natives they are supposed to protect, partly through reduced dynamism and sectoral misallocation.”

---

## 3. LITERATURE POSITIONING

### Closest neighbors

The closest neighbors appear to be:

- **Kerr and Lincoln (2010)** on H-1B admissions and employment/innovation.
- **Peri, Shih, and Sparber (2015)** on STEM workers, wages, and productivity.
- **Bound et al. (2017)** on H-1B and firms/universities/innovation-related margins.
- **Doran, Gelber, and Isen (2022)** or related lottery-based H-1B papers on firm and worker outcomes.
- More broadly, **Borjas (2003, 2017)** and **Card (2009)** as reference points in the immigration-wage debate.

Depending on exact references, the paper may also want to speak to **Glennon** on offshoring/substitution when firms cannot hire foreign talent domestically.

### How should it position itself relative to those neighbors?

Mostly **build on and sharpen**, not attack. This is not a “the entire prior literature is wrong” paper. It is better positioned as:

- **Building on** Peri/Kerr by showing a labor-market incidence result consistent with complementarity.
- **Complementing** firm-level H-1B papers by shifting the lens to local native workers.
- **Clarifying** the timing of adjustment, which annual data miss.
- **Speaking to** the broader substitution-vs-complementarity debate with a policy-induced contraction, not expansion.

It should avoid overclaiming “this resolves the debate.” It does not. But it can reasonably say it provides unusually policy-relevant evidence from a sharp contraction episode.

### Is the paper positioned too narrowly or too broadly?

At the moment, oddly, both.

- **Too narrowly** in method and data: QWI, county-age-industry DDD, quarterly event study.
- **Too broadly** in its rhetoric: “these findings contribute to three literatures,” which reads like a generic job-market-paper template.

For AER positioning, it should be narrower in claim and broader in relevance. One central conversation, not three equal ones. The right core audience is not “people interested in QWI methods”; it is economists interested in immigration, labor demand, innovation, and the incidence of policy restrictions.

### What literature does the paper seem unaware of?

Two missing or underdeveloped conversations:

1. **Misallocation / organization / team production**  
   If the paper wants to make complementarity the mechanism, it should speak more directly to literatures on production complementarities, teams, and constrained factor combinations—not just immigration. That makes the paper less niche.

2. **Local adjustment and labor-market dynamism**  
   The separations result is interesting, but the paper does not fully connect it to broader work on job ladders, outside options, matching, and reallocation. “Restrictions reduce churn” could matter beyond immigration.

Also, if the paper wants to lean into reallocating natives from tech to lower-productivity sectors, it should nod to sectoral reallocation/misallocation literatures, not just H-1B papers.

### Is the paper having the right conversation?

Not quite. It is currently having the “immigration paper” conversation. The more impactful conversation is:

> What happens to native workers when policy constrains firms’ access to complementary high-skill labor?

That connects immigration to labor demand, production complementarities, and innovation. It broadens the audience meaningfully.

---

## 4. NARRATIVE ARC

### Setup

Before this paper, the policy debate often treated H-1B restrictions as protection for native skilled workers, while the academic literature had mixed evidence and often emphasized annual, lower-frequency, or different units of analysis.

### Tension

A large, discrete cut in the H-1B cap should reveal whether natives were mainly competing with or benefiting from skilled immigrants. But prior evidence does not clearly show how local native labor markets adjust in the short and medium run, or whether any effects appear in wages, employment, or labor-market dynamism.

### Resolution

The paper finds that in more tech-exposed counties, young native professionals saw lower earnings and lower separations after the cap reduction, with little evidence of employment gains. The wage penalty builds over time rather than dissipating.

### Implications

The main implication is that restricting high-skill immigration may hurt the native workers the policy is supposed to help. More broadly, labor-supply restrictions on one input can lower the returns to complementary domestic labor and reduce labor-market dynamism.

### Does the paper have a clear narrative arc?

It has the ingredients, but the arc is not fully disciplined. Too often the paper reads as a sequence of results—main DDD, event study, industry heterogeneity, robustness—with “complementarity” attached after the fact. The story is there, but it is not yet governing the structure.

The paper should be telling one clean story:

1. Policymakers cut H-1B to help natives.
2. If natives and immigrants are substitutes, wages and employment should rise.
3. Instead, earnings and dynamism fall where exposure is highest.
4. The timing and sectoral pattern suggest complementarity/reduced team productivity.
5. Therefore, the incidence of the restriction fell partly on natives.

That is a story. Right now the paper sometimes drifts into “look at this extra result too” mode.

One symptom: the industry heterogeneity section is under-integrated. It could be central to the story—showing reallocation away from H-1B-reliant sectors—or it could be appendix material. In its current form it feels halfway between mechanism and robustness.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with?

“I’d lead with this: when the U.S. cut the H-1B cap by two-thirds, young native professionals in more exposed local labor markets did not benefit—they earned less.”

That is the dinner-party fact.

### Would people lean in?

Yes, though not automatically for the current version. The headline has real bite because it runs against popular policy rhetoric. Economists will lean in if you present it as a reversal of expected incidence, not as a quarterly DDD exercise.

### What follow-up question would they ask?

Almost certainly:

1. **Is this really complementarity, or just reduced local labor demand in tech?**
2. **How economically large is the effect?**
3. **Did workers leave tech for other sectors, places, or occupations?**

Those are exactly the questions the paper should anticipate strategically. Referees can litigate causal interpretation; editorially, the key point is that the paper needs to sound like it knows the audience’s natural second question. Right now it partly does, but not sharply enough.

### If findings are modest, is that okay?

Yes, but only if the paper stops overselling the magnitudes and starts selling the incidence. The estimated earnings effect, when translated, is not enormous. That is fine. The interesting thing is not “huge wage collapse”; it is that the sign goes the wrong way for the protectionist view, and that the adjustment shows up in earnings/churn rather than employment.

Null employment results are also fine if presented properly: “the policy did not create jobs for natives; instead it reduced wage growth and mobility.” That is informative, not a failed experiment.

The danger is that the paper currently sounds more dramatic than the magnitudes warrant. Phrases like “the surgery harmed the patient” are rhetorically strong for a paper with fairly modest effect sizes. AER readers will punish mismatch between rhetoric and scale. Better to emphasize sign, mechanism, and policy incidence.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Compress the institutional background.**  
   It is useful, but too long relative to what it adds. Readers do not need several subsubsections to understand the cap sunset. One tightly written section would do.

2. **Move the empirical strategy details later, and simplify the prose around them.**  
   The introduction spends too much energy proving seriousness. The first 3–4 pages should be mostly question, policy event, core result, and why it matters.

3. **Bring the main findings forward even more aggressively.**  
   The introduction does report the results, which is good. But the prose should prioritize one headline result and one secondary margin, rather than listing multiple coefficients.

4. **Decide whether industry heterogeneity is a main result or a robustness check.**  
   Right now it is ambiguous. If it is part of the mechanism/reallocation story, it needs stronger framing and perhaps earnings outcomes there too. If not, shorten it and push it back.

5. **Shorten the generic “three literatures” paragraph.**  
   It reads like a submission to a field journal. AER introductions should feel less checklist-driven.

6. **Rewrite the conclusion.**  
   The current conclusion is stylish but too editorialized. It summarizes effectively, but the metaphors (“slow bleed,” “surgery harmed the patient”) are a bit much. A stronger AER conclusion would use the final space to widen the implications: immigration restrictions as constraints on complementary inputs, implications for labor demand and sectoral allocation, and what future work should pin down.

### Is the paper front-loaded with the good stuff?

Mostly yes, more than many submissions. That is a strength. But the “good stuff” is diluted by too much method-signaling in the introduction. The introduction should feel less like a referee prebuttal and more like a compelling economic argument.

### Are there buried results that should be in the main text?

Potentially yes: the reallocation story is more interesting than some of the current robustness material. If there is stronger evidence on natives moving into less exposed sectors, that belongs in the main narrative. By contrast, some robustness details can move out.

### Is the conclusion adding value?

Some, but not enough. It currently restates. It should instead do one of two things:
- either elevate the paper into a broader claim about policy incidence under input complementarities,
- or candidly delimit the mechanism while stressing the robust policy lesson.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

This is primarily a **framing and ambition problem**, with some **scope** issues.

The paper has a potentially AER-worthy question and a plausible headline result. What keeps it from feeling like an AER paper right now is not mainly the empirical design per se; it is that the manuscript still presents itself as a well-executed labor paper rather than a paper that changes how economists think about the incidence of high-skill immigration restrictions.

### What is the gap?

- **Framing problem:** The paper is too attached to “quarterly evidence” as the contribution. Quarterly dynamics are nice, but they are not the reason this belongs in AER.
- **Scope problem:** The mechanism and broader implications are underdeveloped. The paper has the beginnings of a bigger claim—reduced dynamism, possible sectoral reallocation, native incidence—but does not fully cash it out.
- **Ambition problem:** The manuscript is somewhat safe. It presents results competently, but it does not yet make the reader feel that this policy episode teaches a general lesson.

### Is it a novelty problem?

Not fatally, but there is some risk. The question “do skilled immigrants complement natives?” is not new. The author must therefore make the novelty reside in the **policy episode + native incidence + dynamic adjustment + sectoral consequences**, not merely in using a different design on the same debate.

### Single most impactful advice

If the author changes only one thing, it should be this:

**Reframe the paper around the incidence of skilled-immigration restrictions on native workers—using the quarterly dynamics as supporting evidence—rather than around being the first quarterly DDD study of the 2003 H-1B cap cut.**

That one change would improve the introduction, the literature positioning, the narrative, and the paper’s claim to general interest.

---

### Strategic Assessment

- **Current framing quality:** Adequate
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium
- **Single biggest improvement:** Recast the paper as evidence that restricting complementary high-skill labor hurts the native workers such policies are meant to protect, with quarterly dynamics as corroboration rather than the headline contribution.