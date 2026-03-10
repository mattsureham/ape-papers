# Strategic Feedback — GPT-5.4 (R1)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-10T14:54:48.577799
**Route:** OpenRouter + LaTeX
**Tokens:** 20356 in / 3938 out
**Response SHA256:** e9fd8aa599efeaf3

---

## 1. THE ELEVATOR PITCH

This paper asks whether making uninsured household deposits explicitly bail-inable under the EU BRRD changed how households hold bank deposits. Using staggered national transposition across EU countries, it argues that households modestly shifted deposit composition after bail-in risk became salient, with larger compositional changes in countries where more deposits were uninsured.

Why should a busy economist care? Because the paper speaks to a first-order policy tradeoff in bank resolution: making creditors bear losses may alter the composition of bank funding, potentially changing financial fragility even if the regulation is meant to reduce moral hazard.

**Does the paper articulate this pitch clearly in the first two paragraphs?** Not quite. The current introduction is informed and serious, but it is too policy-institutional and too diffuse. It opens with a vivid hook, but then quickly lists three reasons the question matters, introduces methods, and only later gets to the genuinely interesting point: resolution policy may reshape the liability side of banks through household behavior. The first two paragraphs should be much sharper, less “here are the literatures/methods,” and more “here is the world-level question and why it matters.”

### The pitch the paper should have

> Modern bank resolution regimes are meant to end bailouts by making bank creditors absorb losses. But once uninsured deposits become credibly loss-absorbing, households may respond by changing how they hold deposits—potentially altering the maturity structure of banks’ funding and, with it, financial stability itself.  
>  
> This paper studies that margin using the EU Bank Recovery and Resolution Directive, which for the first time made uninsured deposits explicitly exposed to bail-in. Exploiting staggered national transposition across EU countries, I ask whether households moved toward more liquid deposits or instead re-optimized within deposit insurance limits. The broader question is whether resolution policy changes not just bank incentives, but depositor behavior and the composition of bank liabilities.

That is the AER story. The current intro gets there, but too slowly and with too much econometric throat-clearing.

---

## 2. CONTRIBUTION CLARITY

**One-sentence contribution:**  
The paper provides evidence that the introduction of bail-in risk under the BRRD changed household deposit composition, implying that resolution policy can affect bank funding structure through depositor responses.

### Is this clearly differentiated from the closest 3–4 papers?
Only partially. The paper says “existing work studies banks or bond prices; I study depositors,” which is directionally correct, but the differentiation is still thin. Right now the contribution risks sounding like: “another regulatory DiD, but with deposit shares.” What needs sharpening is **what exact unknown about the world** this paper resolves.

The paper’s distinctive angle is not merely “household-side response” but something like:

- resolution regimes may alter **maturity transformation indirectly**, through depositor portfolio choice;
- the relevant behavioral margin is not just withdrawal/flight, but **re-optimization around deposit insurance boundaries**.

That is stronger and more memorable than “there is little evidence on depositors.”

### World question or literature gap?
It is mixed, but too often framed as filling a literature gap. The stronger framing is plainly about the world:

- When governments make uninsured deposits credibly bail-inable, how do households react?
- Does a policy designed to reduce bailout moral hazard inadvertently shorten bank funding or otherwise reshape liability composition?

That is much better than: “the depositor-response literature is scarce.”

### Could a smart economist explain what’s new after reading the intro?
Not confidently. They could probably say: “It studies BRRD transposition and household deposit composition with staggered DiD.” That is not enough. They may not come away with a crisp sense of the conceptual novelty, especially because the paper itself emphasizes estimator choice almost as much as the economic idea.

At present, many readers would indeed summarize it as “a DiD paper about EU banking regulation and deposits.”

### What would make the contribution bigger?
A few specific possibilities:

1. **Center the paper on the insurance-boundary mechanism.**  
   The most interesting result is not the average overnight effect; it is the heterogeneity by uninsured exposure and the possibility that households optimize within insurance limits rather than simply run toward liquidity. If that is the real insight, it should be the paper.

2. **Bring in outcomes that better map to the mechanism.**  
   The current outcomes are maturity shares. That is reasonable, but indirect. A bigger paper would show responses on margins more tightly tied to the theory:
   - number of deposit accounts or accounts per bank,
   - shifts toward smaller insured balances across institutions,
   - bank-level inflows/outflows by depositor size class,
   - changes in distribution around the €100,000 threshold,
   - deposit pricing/yield spreads if the claim is about “insured return optimization.”

3. **Reframe from “maturity composition” to “how resolution policy changes the effective stability of retail funding.”**  
   That is a larger object than the maturity buckets themselves.

4. **Use a cleaner comparative contrast.**  
   Corporate deposits are a weak comparison because they are also subject to BRRD and differ on many dimensions. A stronger design would compare:
   - households in high- vs low-uninsured-exposure environments,
   - banks with different retail deposit distributions,
   - countries/banks where the insurance boundary is more behaviorally relevant.

---

## 3. LITERATURE POSITIONING

### Closest neighbors
The paper seems to sit nearest to five strands/papers:

1. **Deposit insurance and depositor discipline**
   - Demirgüç-Kunt and Huizinga (2004)
   - Egan, Hortaçsu, and Matvos (2017)
   - Bonfim and coauthors on deposit behavior / deposit market responses

2. **Depositor behavior under bank distress**
   - Iyer and Puri / Iyer et al. on bank runs and depositor responses
   - This literature gives the behavioral benchmark of depositor flight under perceived bank risk.

3. **Bank resolution / bail-in regulation**
   - Schäfer et al. on bail-in pricing / market consequences
   - Conlon and Cotter / Berndt and others on BRRD or bail-in pricing
   - Crespi et al. on liability structure under bail-in-related regulation

4. **Bank funding structure and liquidity**
   - Diamond and Dybvig / Kashyap-Rajan-Stein–type motivation
   - This is not the direct empirical neighbor, but it supplies the macro relevance.

5. **EU banking-union institutional work**
   - Véron and policy papers on BRRD/Banking Union

### How should it position itself?
Mostly **build on**, not attack. The right move is:

- Build on the bail-in literature by saying it has focused on bank securities, funding costs, and bank-side balance sheet adjustments.
- Build on the deposit-insurance literature by showing that depositor behavior responds not only to bank fundamentals and explicit guarantee levels, but also to changes in the legal loss hierarchy in resolution.
- Build on bank-run/depositor-discipline work by emphasizing a different behavioral margin: not just withdrawals, but portfolio composition and insurance optimization.

It should not posture as overturning a literature. It does not.

### Too narrow or too broad?
Currently it is oddly both.

- **Too narrow** in empirical presentation: EU directive, transposition dates, maturity buckets, estimator comparisons.
- **Too broad** in implication claims: “maturity transformation capacity of the banking system,” “financial stability worldwide,” etc., given the evidence is modest and indirect.

The sweet spot is to position it as a **banking/regulation paper with implications for retail funding stability**, not as a sweeping general statement about global deposit insurance design.

### What literature does it seem unaware of?
Not unaware, exactly, but under-engaged with:

- **Household finance / salience / financial sophistication**  
  If the mechanism is household learning and insurance optimization, this should connect to how households process complex financial risk and salient policy thresholds.
  
- **Contract design / product choice in retail banking**  
  If maturity reallocation is central, the paper should engage more with why households choose transaction vs term products in the first place.

- **Public economics of notches and thresholds**  
  The €100,000 guarantee threshold is effectively a salient kink/notch. There is a potentially fruitful connection to behavior around policy thresholds.

- **Law and finance / legal implementation**  
  Since the paper leans heavily on transposition timing, it could better connect to work on staggered legal implementation and credibility of policy regimes.

### Is the paper having the right conversation?
Not fully. Right now it is mostly in conversation with:
- BRRD institutional papers,
- staggered DiD papers,
- a generic deposit-insurance literature.

The more impactful conversation is:
**How does creditor-loss-allocation policy feed back into the liability structure of banks through household behavior?**

That is a better conversation than “here is a new application of heterogeneity-robust DiD to BRRD.”

---

## 4. NARRATIVE ARC

### Setup
Before this paper, the standard view is that bank resolution policy affects banks, bondholders, and taxpayer exposure. Depositor behavior matters for financial stability, but most evidence concerns crises, runs, or explicit deposit insurance changes—not how a new bail-in regime alters ordinary household deposit choices.

### Tension
BRRD was designed to make losses credible for private creditors and reduce moral hazard. But once uninsured deposits become potentially loss-absorbing, households may react in ways that reshape bank funding. The tension is that a policy aimed at making banking safer ex post may change the stability of funding ex ante.

### Resolution
The paper finds modest average movement in household deposit composition after BRRD transposition and stronger heterogeneity in countries with more uninsured exposure. The most interesting interpretation is that households do not simply flee to liquidity; some appear to re-optimize around the insurance boundary.

### Implications
Resolution policy may have underappreciated general-equilibrium effects on banks’ retail funding mix. Regulators should think not just about who bears losses in failure, but how the anticipation of that loss-sharing changes depositor behavior beforehand.

### Does the paper have a clear arc?
Only partially. There is a real story here, but the paper often reads like **a collection of estimates plus estimator comparisons plus institutional detail**, rather than a tightly controlled narrative. The main culprit is that the paper cannot quite decide what its core finding is:

- average shift toward overnight deposits?
- heterogeneity by uninsured exposure?
- insurance optimization?
- a methodological lesson about TWFE?

All four appear, and they do not fully cohere.

### What story should it be telling?
It should pick one:

**Preferred story:**  
“Bail-in risk changed household deposit composition, and the pattern suggests households responded to the insurance boundary rather than merely running for liquidity.”

That story makes the intensity result central and the average effect secondary. The current paper does the reverse.

If the author does not believe the insurance-optimization interpretation is strong enough to carry the paper, then the fallback story is:

“Resolution policy changes retail funding structure.”

But that is less distinctive and, with the current evidence, less exciting.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with at dinner?
Probably this:

> “When Europe made uninsured deposits bail-inable, households appear to have changed how they hold deposits—and the strongest shifts show up where more deposits were above the insurance threshold.”

That is the interesting fact. Not the exact 0.67 pp number.

### Would people lean in?
Some would, especially banking and macro-finance economists. But many would only lean in if the presenter immediately made clear why this is bigger than a narrow EU institutional exercise. The present version does not yet guarantee that.

### What follow-up question would they ask?
Most likely:

- “Is this really about depositors optimizing around the insurance threshold, or just a noisy maturity-composition result?”
- Or: “Why should I believe this changed household behavior rather than reflecting other contemporaneous banking-union reforms?”

Even though you asked me not to referee identification, that is still the natural audience reaction. Strategically, the paper should preempt this by making the conceptual payoff large enough that readers want the answer.

### If findings are modest, is that okay?
Yes, but only if the paper leans into **why modest but systematic behavioral adjustment matters**. In banking, small shifts in the composition of trillions of euros can matter. The paper says this, but it still sounds a bit like an attempt to rescue a modest reduced-form estimate with scale rhetoric.

The null-ish or modest average result is acceptable if the paper sells the heterogeneity result as the real contribution. If instead the headline is “overnight share rose by 0.67 pp,” that feels small and fragile.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Shorten the institutional background substantially.**  
   The background is overgrown. Much of Section 2 reads like a policy note rather than a journal article. The details on Italian episodes, article numbering, transposition groupings, and legal chronology should be trimmed hard or moved to an appendix/online appendix. The reader does not need this much law to understand the question.

2. **Move methodology down and demote the estimator tutorial.**  
   The introduction currently advertises Callaway-Sant’Anna, Sun-Abraham, Goodman-Bacon/TWFE problems, etc., too prominently. For AER-level positioning, the economic question should dominate, and the estimator choice should feel like professional competence, not the main event.

3. **Front-load the substantive result and the puzzle.**  
   By page 2, the reader should know:
   - average response modest,
   - heterogeneity stronger where uninsured exposure is larger,
   - this points to insurance-boundary optimization rather than simple liquidity flight.

4. **Consolidate results.**  
   Right now the reader works through TWFE, then robust estimators, then event studies, then intensity, then corporate placebo, then more robustness. This ordering makes the paper feel methodological and defensive. Better order:
   - main substantive fact,
   - heterogeneity/intensity,
   - event-study support,
   - alternative sectors/comparisons,
   - appendix-level robustness.

5. **Cut repeated caveats in the main text.**  
   The paper repeatedly tells the reader the evidence is “suggestive,” “aggregate data cannot observe within-household behavior,” “small clusters,” “caution,” etc. Some caution is appropriate, but the repetition weakens the narrative voice. State the limitations once clearly, then move on.

6. **The conclusion should do more than summarize.**  
   The current conclusion is decent, but it still partially replays the findings. It should end with the one real idea the paper wants the literature to remember: resolution policy affects depositor portfolio choice and therefore the liability structure of banks.

### Are good results buried?
Yes. The **treatment-intensity result** is the most interesting substantive finding and should be elevated much earlier—possibly into the introduction as the headline. At present it is presented as a later nuance.

### What could move to the appendix?
- detailed BRRD legal exposition,
- long discussion of transposition cohorts,
- some estimator implementation details,
- leave-one-out and TWFE-centric robustness,
- randomization inference for the biased estimator,
- extensive data-retrieval detail.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

Honest answer: in its current form, this is **not yet an AER paper**, and the main issue is not technical polish. It is a combination of **framing, ambition, and evidence-to-claim match**.

### What is the main gap?

#### 1. Framing problem
Yes. The paper’s best idea is stronger than its current framing. The contribution should be about the behavioral incidence of resolution policy on retail funding stability, not mainly about BRRD transposition and staggered DiD implementation.

#### 2. Scope problem
Also yes. The current outcomes are too narrow to fully sustain the larger claims. If the paper wants to say households optimize around deposit insurance and thereby alter bank funding structure, it needs either:
- more direct outcomes tied to that mechanism, or
- a narrower set of claims.

#### 3. Novelty problem
Moderate. The underlying policy setting is interesting, but the empirical move—staggered policy timing plus aggregate outcomes—is familiar. To rise to AER level, the paper needs either a sharper mechanism or a more surprising fact.

#### 4. Ambition problem
Definitely. The paper is careful, competent, and somewhat cautious to a fault. It feels like a good field-journal paper trying to sound top-five by adding more literatures and methods, rather than by sharpening the central economic insight.

### What would excite the top 10 people in this field?
Probably one of these:

- convincing evidence that households actively **manage around the insurance threshold** when bail-in risk becomes credible;
- evidence that resolution reform materially changes the **stability and pricing of retail bank funding**;
- a broader conceptual contribution showing that creditor-loss-allocation rules have important ex ante behavioral effects on household portfolios, not just ex post distributional effects in failure.

Right now the paper gestures at all three, but cleanly nails none.

### Single most impactful advice
**Rebuild the paper around one big idea: BRRD changed depositor behavior at the deposit-insurance boundary, and that is the channel through which resolution policy affects bank funding structure.**  

Everything else—especially the estimator discussion, long legal background, and weak sectoral comparison—should be subordinated to that story. If the author cannot make that mechanism more concrete, then the paper should scale down its ambition and target a strong field journal rather than AER.

---

### Strategic Assessment

- **Current framing quality:** Needs rethinking
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Far
- **Single biggest improvement:** Reframe the paper around the deposit-insurance-boundary mechanism and make the heterogeneity result—not the average DiD estimate or the estimator choice—the central contribution.