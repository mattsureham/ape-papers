# Strategic Feedback — GPT-5.4 (R2)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-10T14:54:48.579142
**Route:** OpenRouter + LaTeX
**Tokens:** 20356 in / 3795 out
**Response SHA256:** d98c12be8fefe99f

---

## 1. THE ELEVATOR PITCH

This paper asks whether exposing uninsured household deposits to bail-in under the EU BRRD changed how households held bank deposits—specifically, whether they shifted between overnight and term deposits when deposits above €100,000 became explicitly loss-absorbing. A busy economist should care because the question sits at the intersection of bank resolution design, deposit insurance, and financial stability: if resolution policy changes depositor behavior, it may reshape banks’ funding structure in ways regulators did not intend.

The paper does articulate a version of this pitch in the first two paragraphs, but not as cleanly or sharply as it should. Right now the introduction tries to do too much at once: bank liquidity risk, Banking Union, deposit insurance design, staggered transposition, estimator choice. The result is that the core economic question—how households respond to newly salient resolution risk—gets diluted by implementation details and methodological throat-clearing.

### The pitch the paper should have in the first two paragraphs

“Bank resolution regimes are meant to make creditors bear losses rather than taxpayers. But once uninsured deposits become credibly bail-inable, households may not sit still: they may reallocate deposits toward more liquid accounts, or restructure savings to remain within deposit-insurance protection. This paper studies whether the EU’s Bank Recovery and Resolution Directive changed the maturity structure of household deposits across member states as bail-in risk became law.

Using staggered national transposition of the BRRD across EU countries, I show that household deposit composition did shift after bail-in risk was introduced, and that the response was strongest in countries with greater uninsured deposit exposure. The central implication is that resolution policy does not just discipline banks ex post; it changes depositor portfolios ex ante, with potential consequences for bank funding stability and the effective scope of deposit insurance.”

That is the story. The current draft gets there, but too slowly and with too much emphasis on empirical machinery relative to the economic stakes.

---

## 2. CONTRIBUTION CLARITY

### One-sentence contribution

The paper’s contribution is to show that making uninsured household deposits bail-inable under the BRRD changed the composition of household deposits, suggesting that bank resolution rules can alter depositor portfolio choices and thus banks’ liability structure.

### Is this clearly differentiated from the closest papers?

Only partially. The paper distinguishes itself from work on bank liability structure, bond pricing, and bank behavior, and says “I examine the household-side response.” That is directionally right. But the differentiation is still weaker than it should be because the draft often sounds like: “existing papers study X; I study Y using DiD.” That is a literature slotting exercise, not a sharp substantive distinction.

It needs to be clearer about the precise novelty:

- Not just “effects of BRRD.”
- Not just “depositor response.”
- But: **whether a resolution regime changes household portfolio composition before bank failure occurs**, and **whether the response runs through insurance boundaries rather than simple flight.**

That is more interesting and more distinct.

### Is the contribution framed as answering a question about the world, or filling a literature gap?

It starts as a world question, which is good, but repeatedly falls back into literature-gap framing. The strongest version is: **When policymakers credibly expose deposits to losses, what do households do?** The weaker version is: **There is limited evidence on depositor responses to bail-in.** The paper too often reverts to the latter.

For AER positioning, it should stay relentlessly on the former.

### Could a smart economist explain what’s new after reading the intro?

At present, maybe, but not confidently. The likely summary would be: “It’s a staggered DiD paper on BRRD and deposit composition.” That is not enough. The reader should instead come away saying: “It shows that resolution rules changed household deposit maturity choice, and the pattern suggests households respond through deposit-insurance optimization, not just liquidity demand.”

That is a sharper and more memorable contribution.

### What would make this contribution bigger?

Several possibilities:

1. **Sharper mechanism outcome:**  
   The paper’s most interesting idea is insurance optimization via deposit splitting / staying under the guarantee threshold. But the data cannot observe this directly. The contribution would become much bigger if the authors could bring in an outcome that more directly tracks the insurance-boundary mechanism—for example, number of accounts, distribution around the €100,000 threshold, cross-bank household reallocation, or bank-level growth in deposits just below insured limits.

2. **Better comparative framing:**  
   Compare the response to households versus depositor categories where insurance incentives differ more sharply than “corporates.” Right now the corporate comparison is not a clean contrast, and the paper itself admits that. A cleaner contrast would make the story more persuasive.

3. **Tie to bank funding consequences:**  
   The paper motivates funding stability, but the main outcomes are only deposit shares. If it could show effects on banks’ liability maturity, liquidity ratios, pass-through to funding costs, or deposit pricing, the contribution would feel materially larger.

4. **Anchor the paper around a puzzle:**  
   The really interesting fact here is not the modest average shift into overnight deposits; it is the heterogeneity suggesting more agreed-maturity deposits in high-exposure countries. If that result is the core, the paper should be built around the puzzle: why does a policy that should increase liquidity demand instead generate behavior consistent with insurance optimization?

Right now the paper’s biggest contribution is buried inside its own secondary specification.

---

## 3. LITERATURE POSITIONING

### Closest neighbors

Based on the paper’s citations and field, the closest neighbors seem to be:

- Crespi et al. (2020?) on bail-in and banks’ liability structure
- Schäfer et al. (2016) on bail-in expectations / pricing
- Conlon et al. (2020) on the effect of bail-in regulation on bank funding / securities markets
- Berndt et al. (2020) on bail-in and market pricing
- Egan, Hortaçsu, and Matvos (2017) on depositors and deposit insurance / depositor discipline
- Bonfim and coauthors on deposits and depositor behavior
- More distantly: Iyer and Puri / bank-run and depositor-response literatures; Diamond-Dybvig / bank-liability maturity literatures

### How should the paper position itself relative to those neighbors?

Mostly **build on**, not attack.

The paper should say:

- Relative to the bail-in literature: “Most evidence studies funding costs, bond pricing, or bank choices. We ask whether households themselves adjust portfolios when deposits become credibly exposed.”
- Relative to the deposit-insurance literature: “This paper shows that the insurance boundary matters not only in crises or withdrawals, but in routine portfolio composition after regulatory reform.”
- Relative to financial intermediation: “Resolution design changes the effective maturity of bank funding through depositor behavior.”

That’s a productive triangulation: resolution policy + depositor discipline + bank funding structure.

### Is the paper positioned too narrowly or too broadly?

Currently, somewhat too broadly in aspiration and too narrowly in execution.

Broadly, it invokes:
- Banking Union
- deposit insurance
- bank runs
- DiD methodology
- household finance
- financial stability

But empirically it is a country-level panel of deposit composition over a short staggered policy window. That is a narrower object. The paper would benefit from **fewer conversations, but deeper engagement with the right ones**.

My sense is the right audience is:
1. banking / financial intermediation,
2. household/depositor behavior,
3. public/regulatory economics of resolution regimes.

The methodological positioning should be demoted. Right now the introduction gives the estimator frontier too much status relative to the economic question.

### What literature does the paper seem unaware of?

Not entirely unaware, but under-engaged with:

- **Depositor discipline / bank-run / depositor response** literature beyond deposit insurance per se
- **Household portfolio response to salience and regulation**
- **Safe asset demand / liquidity preference in household financial choice**
- Possibly **public finance/regulatory incidence**: who actually adjusts when formal loss allocation changes

There is also a missed chance to connect to the broader literature on how legal priority rules and protection thresholds shape behavior ex ante. That framing could make the paper feel less like a narrow EU regulatory episode.

### Is the paper having the right conversation?

Not fully. The most impactful framing is probably not “another paper on the BRRD” or “an application of modern staggered DiD.” The best conversation is:

**How do households respond when the state redraws the boundary between safe and risky bank claims?**

That is much bigger than the BRRD, and it links finance, household behavior, and policy design.

---

## 4. NARRATIVE ARC

### Setup

Before this paper, the standard view is that bank resolution policy determines who bears losses after a bank fails, while household deposits—especially retail deposits—are often treated as relatively inert and sticky. The BRRD changed the legal environment by explicitly exposing uninsured deposits to loss absorption.

### Tension

If households understand and respond to this change, resolution policy could affect bank funding structure before any failure occurs. But we do not know whether households actually react, and if they do, whether they seek more liquidity or instead reorganize savings around deposit-insurance protection.

### Resolution

The paper finds modest average evidence of a shift toward overnight deposits after transposition, but its more provocative result is heterogeneous response: in countries with more uninsured exposure, households appear to shift toward agreed-maturity deposits, consistent with insurance optimization rather than simple liquidity flight.

### Implications

Resolution regimes can have ex ante behavioral effects on retail savers, which means policymakers may be changing not only loss allocation in failure but also banks’ funding structure in normal times. Deposit insurance boundaries and resolution design are therefore jointly important for financial stability.

### Does the paper have a clear narrative arc?

It has the ingredients, but the current draft is still too much **a collection of estimates plus caveats** rather than a disciplined story.

The biggest narrative problem is that the paper starts by promising one story—households may move toward liquidity—and ends up with a more interesting but under-theorized story—high-exposure countries move toward term deposits. That could be fine if the paper embraced this as a puzzle. Instead, it reads a bit like the results forced the story to change midstream.

The paper should tell one of two stories clearly:

1. **Liquidity-hedging story**  
   BRRD made deposits less safe, so households shortened maturity.  
   This is simpler, but the evidence here seems too modest to carry the whole paper.

2. **Insurance-boundary story**  
   BRRD made the insurance threshold more salient, so households reoptimized deposit portfolios around it, which may look like more term deposits where uninsured exposure is high.  
   This is more original and more AER-relevant.

I would strongly advise the second. It is the better story and better fits the most interesting result.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with?

I would lead with something like:

“When Europe made uninsured deposits bail-inable, households changed how they held deposits—and in countries with more uninsured exposure, they shifted in ways consistent with optimizing around deposit insurance, not merely fleeing into liquidity.”

That is a real conversation starter.

### Would people lean in or reach for their phones?

They would lean in—conditionally. Not because the average 0.67 pp shift is itself thrilling, but because the broader implication is interesting: **resolution law may reshape household portfolio choice and bank funding ex ante.**

If instead you present it as “I estimate a small but significant change in the overnight deposit share using Callaway-Sant’Anna,” people will absolutely reach for their phones.

### What follow-up question would they ask?

Likely one of these:

- “Is this really households reacting, or just other contemporaneous Banking Union reforms?”
- “Can you show they were optimizing around the insurance threshold rather than just changing liquidity demand?”
- “Does this matter for banks—funding stability, deposit pricing, or liquidity regulation?”

Those are exactly the questions the paper should anticipate in its framing.

### Are the modest findings themselves interesting?

Yes, but only if the paper makes the right case. A modest average effect is not a problem if it is attached to a first-order institutional implication. The null-ish average effect with strong heterogeneity can be interesting if the paper says: **the main lesson is not “everyone ran to liquidity,” but “policy made the insurance boundary behaviorally salient.”**

If the paper insists on selling the average effect as the headline, it will feel modest. If it sells the heterogeneity as revealing the mechanism, it becomes more interesting.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Shorten and sharpen the introduction.**  
   The intro is overloaded with:
   - methodological detail,
   - multiple estimators,
   - robustness previews,
   - caveats about cluster counts,
   - too many numbers too early.

   For positioning purposes, this is costly. The intro should get to the question, the finding, and the implication faster.

2. **Move most estimator discussion out of the introduction.**  
   The Callaway-Sant’Anna / Sun-Abraham material is important for referees, but it is not what makes the paper belong in AER. Give one sentence in the intro, not a paragraph-length methods roadmap.

3. **Condense institutional background.**  
   Section 2 is too long for what the paper needs strategically. The stories about Italian resolutions and Banco Popular are useful, but the section feels overdeveloped relative to the contribution. Keep only the institutional facts necessary to understand:
   - when deposits became bail-inable,
   - what the insurance threshold is,
   - why staggered transposition exists.

4. **Elevate the treatment-intensity result.**  
   Right now the paper says the “headline result” is the average overnight shift. Strategically, I think that is wrong. The most interesting result is the heterogeneous shift by uninsured exposure. Put that much closer to the front.

5. **Kill some self-undermining language.**  
   The paper repeatedly says “suggestive,” “lacks power,” “aggregate data cannot directly observe,” “estimation instability,” etc. Some caution is good, but strategically it is overdone. In a private memo: the paper is talking itself out of importance. Referees can force caveats later; the editor needs to see the central idea first.

6. **Shorten the discussion of TWFE bias.**  
   The paper spends too much narrative energy on showing that TWFE is wrong-signed. That may be true, but it is not the contribution. If readers remember “this is a paper about modern DiD” rather than “this is a paper about depositor response to bail-in risk,” the framing has failed.

7. **Conclusion should do more than summarize.**  
   The conclusion is reasonably thoughtful, but it still reads as summary-plus-future-research. It should leave the reader with one strong takeaway: resolution policy changes depositor behavior through insurance boundaries, so the design of bail-in and deposit insurance cannot be analyzed separately.

### Is the good stuff front-loaded?

Not enough. The reader has to get through a lot of setup and methodology before understanding what is really interesting. The more surprising heterogeneity result is not foregrounded early enough.

### Are there results buried in robustness that should be in the main text?

Conceptually, yes: the tension between national transposition and the common 2016 activation date seems central to interpretation, not just robustness. Also, if there is any cleaner visual or decomposition that helps explain the high-uninsured-share countries’ term-deposit shift, that belongs in the main text.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

At present, the gap is mostly a **framing and ambition** problem, with some **scope** limitations.

### Framing problem

Yes. The science may be competent, but the paper is underselling and partially misdescribing its own core contribution. It is not mainly about:
- a small shift in overnight deposit share,
- or the superiority of CS over TWFE,
- or a niche EU transposition episode.

It is about:
**how households respond when policy changes what counts as a safe bank claim.**

That is the AER framing.

### Scope problem

Also yes. The data are aggregate and the mechanism remains inferred rather than observed. That limits how far the paper can go as currently constituted. To make this feel like AER rather than solid field-journal work, the paper ideally needs either:
- more direct evidence on the insurance-boundary mechanism, or
- more direct evidence on consequences for bank funding/liquidity.

### Novelty problem

Moderate, not fatal. BRRD has been studied; depositor response and deposit insurance have been studied. The novelty lies in connecting the two. But that novelty will feel thin unless the paper sharpens the mechanism and frames the question broadly.

### Ambition problem

Yes. The paper is careful, earnest, and technically aware—but safe. It reads like a well-done dissertation chapter that wants credit for being careful. AER papers typically stake out a bigger claim about how the world works. This paper has such a claim available, but it is not committing to it.

### Single most impactful piece of advice

**Recenter the paper around the insurance-boundary mechanism—how bail-in made the deposit-insurance threshold behaviorally salient—and treat the average overnight effect as secondary rather than headline.**

That one change would improve the title, introduction, contribution, and narrative arc all at once.

---

### Strategic Assessment

- **Current framing quality:** Needs rethinking
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium
- **Single biggest improvement:** Reframe the paper as evidence that resolution policy changes household behavior by making the deposit-insurance boundary salient, not primarily as a small average-effect DiD on deposit maturity.