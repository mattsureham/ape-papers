# Strategic Feedback — GPT-5.4 (R2)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-26T12:01:25.639098
**Route:** OpenRouter + LaTeX
**Tokens:** 9627 in / 3464 out
**Response SHA256:** 84fec092a9b737d0

---

## 1. THE ELEVATOR PITCH

This paper asks a simple and important question: when governments make it much easier for prosecutors to obtain evidence across borders, does crime fall? Using the staggered rollout of the European Investigation Order across EU countries, the paper argues that faster cross-border evidence sharing did not deter fraud, drug crime, or theft, and may instead have increased measured cross-border crime by improving detection.

A busy economist should care because this is really a paper about whether back-end state capacity in criminal justice changes behavior or mainly changes what the state can see. That is a broad question with implications far beyond EU law.

**Does the paper itself articulate this pitch clearly in the first two paragraphs?**  
Not quite. The current opening is vivid and informed, but it starts too deep inside the legal-institutional weeds. It foregrounds the “prosecution gap” nicely, but the paper’s real hook is not “here is an EU directive”; it is “does improving prosecutorial state capacity deter crime, or just raise detection?” That broader stakes-first pitch should arrive immediately.

**What the first two paragraphs should say instead:**  
> Criminal enforcement depends not only on police catching offenders, but also on prosecutors being able to assemble admissible evidence before cases collapse. This is especially hard for crimes that cross borders. If better enforcement cooperation raises the probability of conviction, standard deterrence logic predicts less crime; but if these reforms mostly help authorities uncover and classify cases that previously went unrecorded, measured crime could rise even when enforcement improves.  
>  
> This paper studies that question using the European Investigation Order, a major EU reform that sharply reduced the time required to obtain evidence from another member state. Exploiting staggered adoption across countries, I show that the reform did not reduce reported fraud, drug offenses, or theft, and that cross-border crimes rose relative to domestic crimes after adoption—suggesting that prosecutorial cooperation may improve detection more than deterrence.

That is the pitch the paper should have. Start with the economics question, not the legal anecdote.

---

## 2. CONTRIBUTION CLARITY

**One-sentence contribution:**  
The paper provides evidence that a major improvement in cross-border prosecutorial cooperation in the EU did not deter reported cross-border crime and may instead have increased measured crime through improved detection.

### Is this contribution clearly differentiated from the closest 3–4 papers?
Only partially. The paper says, reasonably, that there is no prior causal economics paper on the EIO. But “first paper on a policy” is rarely enough for AER unless the policy is a vehicle for answering a larger question. Right now the paper is differentiated at the policy level more than at the conceptual level.

The introduction gestures toward that broader conceptual contribution—conviction probability versus apprehension probability, deterrence versus detection—but it does not sharply distinguish itself from adjacent literatures on policing, prosecutorial discretion, or bureaucratic state capacity. A reader could still walk away thinking: “interesting DiD on an EU legal reform” rather than “important evidence on a neglected margin of criminal enforcement.”

### Is the contribution framed as answering a question about the WORLD, or filling a gap in a LITERATURE?
Mixed, but too much on the literature-gap side. “First causal estimate of the EIO” is a literature gap. “Do backend enforcement-capacity reforms deter crime, or mostly raise detection?” is a world question. The latter is much stronger and should dominate.

### Could a smart economist who reads the introduction explain to a colleague what’s new?
Not cleanly enough. They could probably say: “It studies whether the EU’s evidence-sharing reform reduced crime; it finds mostly null effects and maybe more detection.” That is decent. But they might also say: “It’s another staggered DiD on a criminal justice reform.” The paper has not yet earned a sharper identity.

### What would make this contribution bigger?
Several concrete possibilities:

1. **Reframe around state capacity and measurement, not the EIO per se.**  
   The biggest move is conceptual. The paper should be sold as evidence that procedural enforcement capacity can raise measured crime even when it plausibly improves enforcement effectiveness.

2. **Bring prosecution-side outcomes to the center if available.**  
   The current outcome—police-recorded crime—is strategically awkward because it is only indirectly linked to the reform. If the author could add any direct outcome on case processing, requests executed, prosecutions, convictions, clearance rates, or case duration, the paper becomes much bigger. Right now the detection interpretation is intriguing but inferentially thin.

3. **Sharpen the cross-border intensity comparison.**  
   “Fraud, drugs, theft” versus “homicide, assault” is intuitive but coarse. A stronger version would exploit preexisting exposure to cross-border evidence frictions—say countries with more cross-border trade, migration, border permeability, or prior MLA delays. That would make the question feel more about the world and less about category labeling.

4. **Make the finding more surprising with a stronger fact.**  
   If the paper can credibly show something like: “a reform that cut evidence transfer time from 18 months to 90 days had no detectable deterrent effect,” that is memorable. Right now that fact is present, but the magnitude of the institutional change is not fully exploited rhetorically.

---

## 3. LITERATURE POSITIONING

### Closest neighbors
Based on the paper’s framing, the nearest literatures and papers seem to be:

1. **Becker (1968)** on deterrence and conviction probability.
2. **Draca, Machin, and Witt (2011)** on policing and crime after the London bombings.
3. **Chalfin and McCrary / Chalfin and coauthors** on policing, deterrence, and crime measurement.
4. **Mello (2019)** or similar papers on police intensity and recorded crime.
5. **Helland and Tabarrok (2007)** and **Agan et al. (2023)** on punishment/prosecution margins and deterrence.

There is also a public economics / state capacity literature the paper should be speaking to, even if not via one canonical citation:
- papers on bureaucratic capacity, legal capacity, court efficiency, and administrative modernization;
- papers on how institutions change measured outcomes rather than underlying behavior;
- possibly trade/migration-border enforcement work if the author can connect criminal evidence frictions to broader cross-border governance.

### How should the paper position itself relative to those neighbors?
**Build on them, not attack them.**  
The right positioning is: the policing literature has mostly focused on visible front-end enforcement; this paper studies a less visible but increasingly important back-end margin—prosecutorial access to evidence across jurisdictions. The contribution is not that prior papers were wrong; it is that they emphasized a different part of the enforcement chain.

### Is it currently positioned too narrowly or too broadly?
It is currently **too narrow in subject matter and too broad in claim structure**.

- Too narrow because much of the introduction reads like an evaluation of one EU directive for specialists in European criminal law.
- Too broad because some of the paper’s conceptual claims (“enforcement-infrastructure reforms may not deter crime”) are asserted without enough direct evidence beyond this one setting and these noisy outcomes.

The sweet spot is: one important policy episode used to illuminate a broader but bounded economic question.

### What literature does the paper seem unaware of?
It seems under-engaged with:
- **state capacity / administrative capacity**;
- **courts and legal institutions**;
- **measurement of crime and detection versus incidence**;
- possibly **cross-border governance / international cooperation** beyond criminal law.

Right now the paper cites legal scholars for institutional detail and crime economists for deterrence, but misses the chance to connect to a wider institutional economics conversation.

### Is the paper having the right conversation?
Not yet fully. The current conversation is “EU judicial cooperation and crime deterrence.” The more impactful conversation is “what parts of the enforcement apparatus change criminal behavior, and what parts primarily change state observability?” That is a better conversation for AER readers.

---

## 4. NARRATIVE ARC

### What is the setup?
Cross-border crime is hard to prosecute because evidence is held in multiple jurisdictions, and pre-EIO systems were slow and fragmented.

### What is the tension?
Economic theory says increasing conviction probability should deter crime. But a reform like the EIO is largely invisible to offenders and may instead improve authorities’ ability to detect and record cases.

### What is the resolution?
The paper finds no reduction in reported fraud, drug offenses, or theft after EIO adoption, while cross-border crimes rise relative to domestic crimes.

### What are the implications?
Backend enforcement cooperation may be a weak deterrence tool but an important detection tool; evaluating such reforms using recorded crime alone can be misleading.

### Does the paper have a clear narrative arc?
**Serviceable, but not yet fully coherent.**  
The ingredients are all there. The problem is that the paper is not fully sure whether its story is:
1. a null-result evaluation of the EIO,
2. a test of Becker through the conviction-probability channel,
3. a measurement/detection paper,
4. or a state-capacity paper.

At present it is a bit of all four, which creates blur.

### What story should it be telling?
It should tell this story:

- **Setup:** modern crime often crosses borders, but prosecution does not travel well.
- **Tension:** making prosecution easier should raise punishment risk, but because the reform is procedural and low-visibility, deterrence may be limited; instead recorded crime may rise if hidden cases become legible.
- **Resolution:** exactly that pattern appears—little deterrence, suggestive detection.
- **Implication:** some institutional reforms improve the state’s informational capacity rather than immediately suppressing offending, so outcome choice is central to evaluating law enforcement.

That is a real story. Right now the paper only half-commits to it.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with at a dinner party of economists?
“I have a paper on an EU reform that cut cross-border evidence-sharing delays from roughly a year to 90 days, and reported cross-border crime didn’t fall—in relative terms it may even have risen.”

That is a good lead. People will lean in, at least initially.

### Would people lean in or reach for their phones?
They would **lean in for the first sentence**, because the institutional change is large and concrete. They may reach for their phones if the conversation quickly turns into transposition dates, opt-outs, and estimator branding. The hook is strong; the exposition risks losing it.

### What follow-up question would they ask?
Probably one of these:
- “So did it actually increase crime, or just detection?”
- “Why should offenders respond if they don’t know this legal reform happened?”
- “Do you have prosecution or conviction data?”
- “Is this really about crime, or about measurement?”

Those are exactly the right questions. The paper needs to show it knows that these are the questions.

### If the findings are null or modest: is the null itself interesting?
Yes—but only if sold correctly. The null is interesting because the institutional reform was large and because deterrence theory would give many readers a prior that conviction-probability improvements should matter. A null after such a dramatic procedural acceleration is informative. But the paper must make the case that this was a serious test of a meaningful mechanism, not just a failed attempt to find effects in noisy aggregate data.

At the moment, the paper is close to making that case, but not all the way there. The phrase “well-powered null” helps rhetorically, though the paper’s own discussion later admits limited precision. Strategically, I would avoid overclaiming power and instead emphasize **ruling out large deterrence effects despite a substantial institutional shock**.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Rewrite the first two pages around the big question.**  
   This is by far the most important change. Open with the economics question and the headline finding. The legal detail should come after the stakes are clear.

2. **Move method branding down.**  
   The Callaway-Sant’Anna material arrives too prominently in the introduction. For AER positioning, the first page should be about the world, not estimator selection.

3. **Promote the most interesting result earlier and more cleanly.**  
   The triple-difference is the paper’s most conversation-starting result. It should appear as a headline contribution in the introduction, but with more disciplined interpretation: “consistent with improved detection” rather than leaning too hard on a mechanism the paper cannot directly observe.

4. **Tighten the institutional background.**  
   It is informative but somewhat repetitive. Compress it substantially. The paper does not need multiple paragraphs on legal plumbing in the main text.

5. **Cut the robustness parade in the main text.**  
   For editorial purposes, the robustness section reads like standard workshop defense. Much of it can move to the appendix unless one of those results materially changes interpretation.

6. **Reconsider the contribution list.**  
   Three numbered contributions are fine, but the current list is a little diffuse and literature-gap heavy. Better would be: one big substantive contribution, one conceptual implication, one measurement implication.

7. **Fix minor inconsistencies that undermine confidence in the storytelling.**  
   The paper says domestic crimes are homicide and serious assault, but a summary table also lists robbery. There are various small signals of assembly rather than curation. For a top journal, this matters more than authors think because it affects whether the reader trusts the paper’s command of its own narrative.

8. **The conclusion should do more than summarize.**  
   The current conclusion is decent, but it repeats the “detection dividend” line without widening the aperture enough. It should end with a broader point about evaluating institutional reforms with outcomes that can move in the wrong direction mechanically when state capacity improves.

### Is the paper front-loaded with the good stuff?
Reasonably, but not optimally. The good stuff is there by page 2–3, yet the prose still makes the reader work too hard before it lands on the central contribution.

### Are interesting results buried?
Yes—the conceptual significance of the detection-versus-deterrence distinction is still buried beneath a lot of design exposition.

### Is the conclusion adding value?
Some, but not enough. It should leave the reader with a broader lesson for economics, not only for EU criminal justice.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

Be honest: the gap is meaningful.

### What is the main problem?
Primarily **a framing problem**, secondarily **a scope problem**.

- **Framing problem:** The paper has a better question than it realizes. It should be about how hidden, procedural improvements in enforcement capacity affect behavior versus measurement. Right now it is too often framed as “the first paper on the EIO.”
- **Scope problem:** The outcomes are not yet rich enough to fully support the most interesting interpretation. Without prosecution-side outcomes, the paper can suggest detection but not really demonstrate it. For AER, that limitation bites.

There is also some **ambition problem**: the paper is competent and knows the modern design vocabulary, but it is intellectually safer than it should be. It could make a bolder move into state capacity, measurement, and the anatomy of deterrence.

### Is it a novelty problem?
Not fatal, but some. The specific policy is novel; the empirical template is not. So the paper must win on question and insight, not on design novelty.

### What is the single most impactful piece of advice?
**Stop selling this as a paper about an EU directive and start selling it as a paper about whether improvements in prosecutorial state capacity deter crime or primarily increase detection—and, if at all possible, add one direct prosecution-side outcome that lets you prove the latter rather than merely suggest it.**

That is the fork in the road. If the author does only one thing, it should be that.

---

### Strategic Assessment

- **Current framing quality:** Needs rethinking
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium to Far
- **Single biggest improvement:** Reframe the paper around the broader economic question of backend enforcement capacity—deterrence versus detection—and support that framing with at least one direct prosecution-side outcome if possible.