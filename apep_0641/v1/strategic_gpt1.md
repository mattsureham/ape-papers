# Strategic Feedback — GPT-5.4 (R1)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-13T17:41:00.370200
**Route:** OpenRouter + LaTeX
**Tokens:** 9645 in / 3858 out
**Response SHA256:** 2910222a015f87f3

---

## 1. THE ELEVATOR PITCH

This paper studies whether salary history bans reduce gender pay gaps, using staggered state adoption and state-industry-sex-quarter data on new-hire earnings. Its central claim is not that these bans simply help women on average, but that they have sharply heterogeneous effects: they appear to reduce gender pay gaps in industries with large preexisting gaps and worsen them in industries where gaps were already relatively small, consistent with an information/substitution story.

A busy economist should care because salary history bans are now a standard labor-market policy, and the paper is trying to say something broader than one policy evaluation: anti-discrimination policies that remove information can have opposite effects depending on whether the removed signal primarily encodes discrimination or useful information.

**Does the paper articulate this clearly in the first two paragraphs?**  
Not cleanly enough. The raw ingredients are there, but the introduction is too eager to jump into design, estimands, and significance before it has stabilized the main substantive claim. Worse, it is imprecise about the magnitude: the abstract and intro repeatedly blur the distinction between the *effect in high-gap industries* and the *difference between high-gap and low-gap industries*. That is fatal for the pitch. A top-journal introduction cannot leave the reader unsure what the headline finding actually is.

**What the first two paragraphs should say instead:**

> Salary history bans are meant to stop past discrimination from following workers from job to job. But removing salary history also removes information that employers use when setting pay, raising a basic question: when does this policy reduce inequality, and when does it instead induce employers to rely more heavily on group averages?
>
> This paper shows that the answer depends sharply on the industry. Using staggered state adoption of salary history bans and new-hire earnings data by state, industry, and sex, I find that bans narrow gender pay gaps in industries with large preexisting gaps but widen them in industries where gender pay gaps were already relatively small. The broader implication is that information-removing regulation does not have a uniform effect: it helps when the removed information is contaminated by past discrimination and can backfire when that information was relatively informative.

That is the pitch the paper should have. It is simpler, world-facing, and makes the “why should I care?” obvious.

---

## 2. CONTRIBUTION CLARITY

**One-sentence contribution:**  
The paper argues that salary history bans have heterogeneous effects across industries, reducing gender pay gaps where pre-ban gaps were large and increasing them where pre-ban gaps were small, which it interprets through a statistical-discrimination framework.

### Is this contribution clearly differentiated from the closest 3–4 papers?
Partly, but not sharply enough. The paper says “first industry-level decomposition” and “full panel of U.S. states,” which is fine as a factual literature distinction, but that is not yet an AER-level contribution. The real differentiation should be:

1. Existing salary-history-ban papers ask whether the policy changes wages/hiring on average.
2. This paper asks a different question: **when does removing salary information help versus hurt?**
3. The answer depends on the **informational environment of the market**, proxied here by preexisting industry gender gaps.

That is stronger than “first industry-level decomposition.” Right now the paper undersells the conceptual shift and oversells the mechanical novelty.

### Is the contribution framed as answering a question about the world, or filling a gap in a literature?
It starts with a question about the world, which is good, but it repeatedly slides back into literature-gap language (“first industry-level decomposition”). The world question is better: **Do information-removal policies reduce discrimination uniformly, or do their effects depend on where information was biased versus useful?**

That is the version that belongs in AER territory.

### Could a smart economist who reads the introduction explain to a colleague what’s new?
Not reliably. Right now they might say: “It’s a DiD/DDD paper on salary history bans with industry heterogeneity.” That is not enough.

You want them to say: “It shows salary history bans are not uniformly pro-equality; they help in high-gap industries and can hurt in low-gap industries, so the effect of information-removal policy depends on whether the removed information mostly reflects discrimination or productivity.”

That is memorable.

### What would make this contribution bigger?
Several possibilities:

- **Frame the paper as about information-removal policy generally**, not just salary history bans. Salary history bans become the clean empirical setting for a broader claim.
- **Bring alternative information-provision policies into the frame**, especially pay transparency / posted salary ranges. The natural bigger question is: can information-removal policies backfire unless paired with alternative credible signals?
- **Make the heterogeneity more structural and less binary.** The current high-gap/low-gap split risks looking ad hoc or merely descriptive. A more continuous or theoretically motivated measure of “how contaminated salary history is” would make the contribution feel bigger.
- **Show implications for market-level reallocation or welfare-relevant outcomes**, not just wage ratios. If the story is about equilibrium information substitution, readers will want to know whether this changes who gets hired, where women move, or whether firms adjust posted pay.
- **Clarify whether the core object is the gender gap, female wages, or relative female wages at hiring.** The introduction currently toggles among these. AER readers need one clean estimand in the pitch.

The single biggest enlargement would be to **turn this from a policy-effect paper into a paper about when removing private information reduces versus increases discrimination**.

---

## 3. LITERATURE POSITIONING

### Closest neighbors
The paper’s closest neighbors seem to be:

1. **Barach and Horton (2021)** on salary history and wage setting / anchoring.
2. **Agan and Starr** on employer information and labor-market discrimination, especially the broader information-policy angle.
3. **Doleac and Hansen (2020)** on ban-the-box and statistical discrimination.
4. **Hansen and McNichols (2020)** or adjacent salary-history-ban evidence.
5. The broader **gender wage gap / labor-market institutions** literature: **Goldin**, **Blau and Kahn**, **Olivetti and Petrongolo**.

Depending on exact paper identities, it also probably should engage with:
- audit / correspondence evidence on employer learning and wage setting,
- job-posting/pay transparency work,
- statistical discrimination and employer learning more broadly.

### How should it position itself relative to those neighbors?
**Build on and synthesize**, not attack. The paper is strongest when it says:

- salary history bans are one instance of a broader class of policies that change employers’ information sets;
- the salary history literature has mostly asked whether the average effect is positive;
- ban-the-box taught us that removing information can induce substitution toward group priors;
- this paper brings those two literatures together and shows that even within one policy, the sign of the effect depends on the initial degree of inequality.

That is a valuable synthesis. It should not posture as overturning the existing salary-history-ban literature unless it genuinely does so.

### Is it positioned too narrowly or too broadly?
Currently, oddly, both.

- **Too narrowly** in the empirical framing: “industry-level decomposition of salary history bans using QWI.”
- **Too broadly** in the normative claims: “broader lesson for labor market regulation,” “welfare consequences,” etc., without fully earning those generalizations in the narrative.

The sweet spot is: **a labor paper with a general information-economics lesson**.

### What literature does the paper seem unaware of?
It feels underconnected to:
- the **employer learning / screening / information asymmetry** literature;
- the **pay transparency / salary posting** literature, which is a natural complement or foil;
- the broader **design of anti-discrimination policy under imperfect information** literature;
- possibly organizational economics work on internal equity and compensation-setting, if the incumbents result is kept central.

Also, if the paper wants to talk about “information removal triggers statistical discrimination,” it should likely speak more directly to classic and modern models of statistical discrimination beyond Phelps/Arrow name-checking.

### Is the paper having the right conversation?
Almost, but not quite. The current conversation is “salary history bans: average effect, plus some industry heterogeneity.” The better conversation is: **what happens when regulation removes signals from labor markets?**

That is a larger and more surprising conversation, and it is where the paper has a shot at broader impact.

---

## 4. NARRATIVE ARC

### Setup
Before this paper, the prevailing policy intuition is straightforward: salary history anchors wages to past discrimination, so banning salary-history questions should reduce gender wage inequality.

### Tension
But removing salary history also removes an individualized signal. If employers respond by substituting toward group priors, then the same policy could reduce discrimination in some settings and worsen it in others. The puzzle is whether salary history bans are uniformly equalizing or whether their effect depends on the market environment.

### Resolution
The paper’s core result is that the effects differ sharply across industries: in industries with large preexisting gender gaps, bans appear to compress the gap; in industries with smaller preexisting gaps, bans appear to widen it.

### Implications
The implications are potentially important: anti-discrimination policies that remove information may not work uniformly, and policymakers may need to pair them with alternative information-provision tools such as pay transparency.

### Does the paper have a clear narrative arc?
**Serviceable but unstable.** The broad story is there, but the execution is muddled by three problems:

1. **The headline fact is not stated consistently.**  
   The abstract and introduction confuse the differential effect with the total effect in high-gap industries. This makes the paper look either careless or strategically slippery.

2. **There are too many mini-stories.**  
   The paper wants to be about:
   - salary history bans,
   - industry heterogeneity,
   - statistical discrimination,
   - race heterogeneity,
   - incumbents versus new hires,
   - aggregate near-zero effects,
   - welfare and policy design.  
   That is too much for a paper whose real asset is one sharp heterogeneity result.

3. **The mechanism story outruns the evidence in the prose.**  
   The paper speaks as if it has shown the information-substitution mechanism, when strategically it has shown a **pattern consistent with** that mechanism. Referees can fight over mechanism. As editor, I’d say the paper should narrate the mechanism more carefully.

### What story should it be telling?
The right story is:

- salary history bans are intended to sever the link between past and future discrimination;
- but they also alter the employer’s information set;
- whether that helps or hurts depends on whether salary history was mostly a contaminated anchor or a useful individual signal;
- the industry heterogeneity is the empirical manifestation of that tradeoff.

Everything else should support that story, not compete with it.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with?
I would lead with this:

**“Salary history bans do not uniformly reduce gender pay gaps: they appear to narrow them in high-gap industries and widen them in low-gap industries.”**

That is the dinner-party fact. Not the triple-difference coefficient, not the p-values, not the number of states.

### Would people lean in or reach for their phones?
They would lean in—**if** it is presented crisply. This is a surprising result because the conventional policy intuition is one-directional.

### What follow-up question would they ask?
Immediately:

- “Why would the same policy hurt in some industries?”
- Then: “Is that really statistical discrimination, or something about composition / occupational sorting / bargaining / measurement?”
- And also: “So should salary history bans be paired with pay transparency?”

Those are good follow-up questions. They indicate the paper has a live issue.

### If the findings are modest or near-zero in aggregate, is that still interesting?
Yes. The paper is strongest when it says the average effect is near zero **because positive and negative effects offset across industries**. That is interesting—not a failed experiment—because it explains why aggregate studies may disagree or find small effects.

But the paper needs to make that point more elegantly. Right now it first trumpets large effects and only later admits the aggregate effect is basically zero. Strategically, the better move is to say up front: **the average effect hides important heterogeneity.**

That is an intellectually mature contribution.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

#### 1. Rewrite the introduction around one estimand and one fact.
The first three pages should stop juggling:
- female wages,
- female/male ratios,
- “compression by 8 log points,”
- differential effects of 8 log points,
- average earnings vs new-hire earnings.

Pick the main object. Most likely it should be **the gender gap in new-hire earnings**, with average earnings and other outcomes as secondary.

#### 2. Fix the headline magnitude language everywhere.
This is the biggest presentational problem in the paper. The abstract says bans “compressed the gender gap in high-gap industries by 8.0 log points but widened it by 5.4 log points in low-gap industries.” But the table implies:
- low-gap effect = -5.4
- differential high-vs-low effect = +8.0
- therefore high-gap total effect = +2.6

Those are three different quantities. The paper currently blurs them. That will destroy reader confidence before referees even start.

#### 3. Move some method detail out of the introduction.
The introduction is overpacked with:
- sample size,
- number of observations,
- exact fixed effects,
- p-values,
- estimator names,
- placebo details.

AER introductions need discipline. The introduction should sell the question, result, mechanism, and implication. Save the econometric menu for later.

#### 4. Demote the race results unless they become central.
As currently written, the race analysis is suggestive and by the paper’s own admission not as well isolated. Strategically, it weakens the paper because it introduces another claim that is not fully integrated. Either:
- make race a fully developed second application of the same information logic, or
- reduce it to one paragraph of suggestive external validity / scope.

Right now it feels like an extra result looking for importance.

#### 5. Shorten the “Threats to Validity” section in the main text.
This is not a referee report. The paper reads like it is pre-defending itself rather than telling a story. Some of that belongs later or in the appendix.

#### 6. Promote the aggregate-near-zero point earlier.
This is an important strategic point because it reconciles the paper with mixed prior evidence. It should appear in the introduction, not buried in Discussion.

#### 7. The conclusion should do more than summarize.
The current conclusion is decent, but it mostly restates the claim. It should end on the broader lesson:
- policies that remove information are not monotone in their equity effects,
- policy design must consider the signal being removed and the substitute signals employers will use.

That is the durable takeaway.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

At present, the paper’s gap to AER is mostly **framing plus ambition**, with some novelty risk.

### What is the main gap?

#### 1. Framing problem
The science may be there, but the story is not yet presented at the right altitude. Right now it reads like a competent applied labor paper with a DDD and an interesting interaction. To feel like AER, it needs to become a paper about **how labor-market regulation changes informational equilibria**.

#### 2. Ambition problem
“Industry-level decomposition of salary history bans” is not ambitious enough as a headline contribution. “Information-removal policies have sign-changing effects depending on whether they suppress biased or informative signals” is much more ambitious.

#### 3. Novelty problem
The danger is that readers will say: this is another staggered-adoption policy paper showing heterogeneity across industries. The paper must get ahead of that by making the intellectual move explicit: it is not documenting generic heterogeneity; it is testing a conceptual prediction about when information removal should help or hurt.

#### 4. Scope problem
The paper may be slightly too narrow in outcomes and too broad in claims. It needs either:
- a tighter scope with cleaner claims, or
- a broader empirical scope that fully supports the general claims about information design.

For AER, I would prefer the first if the authors cannot do the second convincingly.

### Be honest: how far is it?
**Medium-to-far in current form.** There is a publishable idea here, and possibly a very good field-journal paper, but the manuscript in front of me does not yet read like a paper that would excite the top people in labor/public/applied micro. The core reason is not identification; it is that the paper has not yet crystallized its big question and keeps tripping over its own headline.

### The single most impactful piece of advice
**Reframe the paper around one sharp claim—that salary history bans are an information-removal policy with opposite effects depending on whether prior salary primarily encoded discrimination or useful individual information—and make every part of the paper serve that claim, starting by fixing the inconsistent statement of the main result.**

---

### Strategic Assessment

- **Current framing quality:** Needs rethinking
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium
- **Single biggest improvement:** Recast the paper from “industry heterogeneity in salary history bans” to “when information-removal policies reduce versus increase discrimination,” and state the headline result consistently and unambiguously.