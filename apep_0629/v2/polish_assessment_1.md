# Polish Assessment — GPT-5.4 (Round 1)

**Verdict:** POLISH_SAFE
**Model:** openai/gpt-5.4
**Paper:** paper.tex
**Timestamp:** 2026-03-13T16:15:01.283102
**Route:** OpenRouter + LaTeX
**Tokens:** 8785 in / 4635 out
**Response SHA256:** c1ab72c38e79a516

---

## Section 1: Escalation Check

**VERDICT: POLISH_SAFE**

I do **not** find any clear exhibit-text factual inconsistency that would require analytical revision rather than polishing.

The core text-to-exhibit claims line up:

- **House vs. Senate predictability:**  
  The text says House speech is more predictable than Senate speech in every holdout year and that the gap is **3–8 perplexity points**.  
  - **Table 2** (“Perplexity by Chamber, Selected Years”) shows House PPL below Senate PPL in every listed year, with gaps from **4.3 to 6.2**, which is consistent with that summary.
  - **Figure 1** is described as showing the same pattern over time; nothing in the manuscript’s own description contradicts this.

- **COVID / January 6 spikes:**  
  The text says perplexity rises in 2020 and 2021, and gives a specific 2019-to-2020 increase:
  - House: **40.1 to 44.2** = **+4.1**
  - Senate: **46.3 to 49.1** = **+2.8**  
  These match **Table 2** exactly.

- **Deliberation Index overall and by chamber:**  
  The text says:
  - mean **DI = +2.52**
  - positive in **85%** of turns
  - House **+2.76**
  - Senate **+2.00**  
  These match **Table 3** and its notes.

- **Sampling description for DI:**  
  The text says the DI is computed on a stratified sample of **832 turns from five holdout years**.  
  - **Table 3** totals to **832** and lists **2015, 2017, 2019, 2021, 2023**, consistent with the statement.

Because I do not see an exhibit contradicting the text that describes it, this paper is **safe to polish**.

---

## Section 2: Structural Plan

Overall, the paper is already organized like a standard empirical economics paper, but it is **not yet optimally ordered for reader absorption or tournament performance**. The main problem is that the paper spends too much time teaching perplexity mechanics before the reader has seen the payoff, and it keeps some validation material in the appendix that could help establish credibility earlier.

### 1. Section ordering

### Current order
1. Introduction  
2. Related Literature  
3. Data  
4. Measurement Framework  
5. Model  
6. Results  
7. Discussion  
8. Conclusion  
Appendix

### Assessment
This is serviceable, but not optimal. The biggest structural drag is that **Section 4 (“Measurement Framework”) is long and pedagogical**, and it appears before the reader sees any empirical result. That is risky for a busy economist: the paper can start to feel like a methods note rather than a result-driven economics paper.

### Recommended order
A stronger order would be:

1. **Introduction**
2. **Data and Institutional Setting**  
   - combine current Data with a brief institutional motivation for House vs. Senate differences
3. **Measurement Framework and Empirical Design**  
   - shorten current Section 4 substantially
4. **Main Results**
5. **Interpretation and Limitations**
6. **Related Literature**
7. **Conclusion**

Why move literature later? Because this draft’s comparative advantage is a clean idea and memorable findings, not a long literature map. For a tournament audience, the literature should clarify contribution, not interrupt momentum after the intro.

If you want a more conventional econ ordering, a compromise is:
- Intro
- Related lit (shorter)
- Data
- Framework/method
- Results
- Discussion
- Conclusion

But the current **full-length literature review before the reader sees data or design** is not helping.

---

### 2. Main vs. appendix balance

### Main text exhibits currently in main
- Table 1: Corpus Summary Statistics
- Figure 1: Perplexity by year and chamber
- Table 2: Perplexity by chamber, selected years
- Table 3: Deliberation Index Summary

This is a reasonable core set. But there is some duplication and one missing credibility exhibit.

#### What should stay in main
- **Figure 1 (perplexity time series)** — essential visual headline result
- **Table 3 (Deliberation Index Summary)** — essential second headline result
- **Table 1 (Corpus Summary Statistics)** — probably keep, but tighten

#### What could move out of main
- **Table 2 (Perplexity by Chamber, Selected Years)** is partly redundant with Figure 1.  
  The figure already communicates the pattern; the table mainly supplies a few exact values. If space is tight, this table belongs in the appendix or online appendix.

#### What appendix exhibit deserves promotion
The strongest candidate is:
- **Figure A1 / current appendix Figure “Speaker identification accuracy over time”**  
  This is not a main result, but it is a **credibility/validation exhibit** showing the model has learned something nontrivial from the debate stream. Right now the paper asks the reader to trust the model before showing any validation evidence beyond a single validation perplexity number. A compact version of this validation—possibly just one panel or one sentence plus a small figure—would strengthen the paper early.

A good solution:
- Promote a **single compact validation figure** or a brief panel into the main text, perhaps at the end of the Model section or beginning of Results.
- Keep the rest of the appendix validation material in the appendix.

---

### 3. Length balance

### Too long relative to importance
- **Section 4: Measurement Framework**  
  This is the most overgrown section. It has six subsections, including gallery thought experiments, Shannon history, transformer explanation, and caveats. Much of this belongs in a shorter conceptual setup or appendix-style exposition.
  
- **Section 2: Related Literature**  
  This section is not excessively long in absolute terms, but it is long relative to the paper’s need. It can be cut by about one-third and become sharper.

### Too short relative to importance
- **Section 6: Results**  
  Surprisingly short relative to the paper’s contribution. The core findings deserve a bit more interpretation, especially:
  - why the House can be both more predictable and more context-responsive
  - what exactly a +2.52 DI means in substantive terms
  - what kind of turns are likely to have negative DI

- **Introduction (especially contribution paragraph)**  
  The intro should do more work distinguishing:
  - what this paper measures,
  - why perplexity is the right object,
  - what is genuinely new relative to text-as-bag-of-words approaches and DQI-style coding.

---

### 4. Redundancy

There is substantial repetition of the same core claims.

#### Repeated multiple times
- “House more predictable than Senate”
- “DI positive in 85% of turns”
- “House more formulaic but more context-responsive”
- “Perplexity measures predictability, not deliberative quality”

These claims appear in:
- abstract
- introduction
- results
- discussion
- conclusion

Repetition itself is not bad, but the draft often repeats the same sentence-level idea rather than **advancing the argument** each time.

#### Concrete redundancies
- The distinction between **raw predictability** and **context-responsiveness** is explained in the Introduction, again in Results, and again in Discussion with very similar language.
- The caveat that perplexity is not the same as deliberative quality appears in both Section 4 and Discussion; one fuller version is enough.
- The pedagogy on entropy/perplexity/transformers in Section 4 is more extensive than needed for this audience.

---

### 5. Missing transitions

There are several points where the reader can lose the thread.

#### Intro → Related Literature
The introduction ends with contribution; then the paper drops into a literature survey without a transition that frames the literature around the paper’s specific gap.

#### Data → Measurement Framework
The reader moves from corpus construction to a didactic explanation of Shannon/entropy. This feels like a pivot into a different paper.

#### Model → Results
This jump is abrupt. The Model section gives architecture details but does not bridge to: “What exactly do we compute from this model, on which sample, and what are the first-order facts?”

#### Results → Discussion
The transition is decent (“These patterns are descriptive…”), but the Discussion partly re-explains findings rather than interpreting them.

---

## Concrete restructuring plan

### Recommended revised structure

### 1. Introduction
- First paragraph: motivating question + why it matters
- Second paragraph: measurement idea in one sentence, then headline findings
- Third paragraph: contribution relative to existing political text methods and DQI
- Fourth paragraph: roadmap

### 2. Data and setting
- corpus
- training/holdout split
- key comparability issue between HF and GovInfo
- brief institutional contrast between House and Senate

### 3. Measurement framework and empirical design
Condense current Section 4 into:
- one paragraph on conditional and marginal perplexity
- one paragraph defining DI
- one paragraph on interpretation and limits
Move the Shannon/transformer tutorial material to an appendix or footnote-level exposition.

### 4. Model and validation
- short model description
- one compact validation exhibit (speaker identification or some other sanity check)

### 5. Main results
- first subsection: raw predictability by chamber/year
- second subsection: DI summary
- third subsection: interpretation of decomposition

### 6. Discussion and limitations
- what can and cannot be inferred
- sampling limitations
- model-size sensitivity
- speaker-entry issue

### 7. Related literature
Shorter, more contribution-oriented

### 8. Conclusion

This plan would make the paper feel much more like an economics paper with a memorable empirical object, rather than a computational methods walkthrough.

---

## Section 3: Prose Priorities

Below are the **top 10 rewrite actions**, ordered by **tournament impact**.

---

### 1. Rewrite the opening two paragraphs to lead with the empirical question and payoff, not democratic theory
**What:** Replace the current opening with a sharper hook that states the measurement problem and the paper’s answer immediately.  
**Where:** Introduction, first two paragraphs.  
**Why:** The first two paragraphs are the highest-value real estate. Right now the opening is thoughtful but slightly seminar-like. A busy economist should know, within 20 seconds, the paper’s question, method, and punchline.  
**Example:**

**Before:**  
> How predictable is legislative speech? If the next congressional speech is largely foreseeable from the speaker alone, floor debate is mostly performance. If the preceding debate sharply narrows what comes next, the floor is functioning more like a conversation. The distinction matters for democratic theory...

**After:**  
> How much of floor debate is actual exchange, and how much is scripted performance? We answer that question by measuring how predictable each congressional speech is to a language model trained only on floor debate. If prior debate sharply reduces uncertainty about the next turn, the floor is functioning like a conversation; if not, legislators are mostly delivering prepackaged speeches.

A second sentence or paragraph should then give the findings:
> In holdout data from 2015–2024, House speech is consistently more predictable than Senate speech, but it is also more responsive to prior turns: the gap between speaker-only and context-conditioned predictability is larger in the House.

---

### 2. Rewrite the abstract to be tighter, more result-forward, and less definitional
**What:** Cut setup language; keep only question, method, findings, contribution.  
**Where:** Abstract.  
**Why:** The current abstract is good but still spends too much space defining terms. Tournament readers want a quick answer: what was done, what was found, why should I care?  
**Example:**

**Before:**  
> We measure the predictability of U.S. Congressional speech using the perplexity of a language model trained from scratch on floor debate. Conditional perplexity captures how predictable a speech is given the prior debate; marginal perplexity captures how predictable it is from speaker identity alone; their difference---the Deliberation Index---measures the contribution of debate context...

**After:**  
> We measure how conversational U.S. Congressional floor debate is using a language model trained only on floor speech. We compare each turn’s predictability given prior debate to its predictability from speaker identity alone; the difference isolates how much debate context matters. In holdout data from 2015–2024, House speech is 3–8 perplexity points more predictable than Senate speech in every year. Yet the House also has a larger context effect: the debate context lowers perplexity more in the House than in the Senate. Overall, the context effect is positive in 85% of turns. The framework provides a scalable measure of conversational structure in legislatures.

That lands the same substance with more economy.

---

### 3. Rewrite results paragraphs so they interpret findings instead of narrating exhibits
**What:** Replace “Table/Figure shows…” prose with “what we learn is…” prose.  
**Where:** Results section, both subsections.  
**Why:** Readers remember claims, not exhibit references. Exhibit narration makes the paper feel mechanical and lower-status.  
**Example:**

**Before:**  
> House speech has lower perplexity in every year---a gap of 3--8 points (\Cref{tab:perplexity}). This is consistent with institutional design...

**After:**  
> The first fact is that House speech is systematically easier to predict than Senate speech. That pattern is stable across the entire holdout period, with annual gaps of roughly 3–8 perplexity points. A natural interpretation is institutional: the House’s tighter agenda control and more structured floor process generate more formulaic speech.

And:

**Before:**  
> The Deliberation Index is positive in 85\% of turns, with a mean of $+2.52$---context reduces the effective number of plausible next words by approximately 2.5.

**After:**  
> In most turns, prior debate materially sharpens what the next speaker will say. On average, conditioning on the preceding debate lowers the effective set of plausible continuations by about 2.5 words on the perplexity scale, and that context effect is positive in 85% of sampled turns.

---

### 4. Cut the Shannon/transformer tutorial by at least half
**What:** Compress the pedagogical exposition on Shannon entropy, perplexity, and transformer mechanics.  
**Where:** Section 4, especially “Shannon’s Insight,” “From Entropy to Perplexity,” and “How a Language Model Computes Perplexity.”  
**Why:** The current exposition is lucid, but too much of it reads like a methods explainer rather than an economics paper. It slows momentum before the results.  
**Example action:**  
- Keep one compact paragraph defining perplexity.
- Keep one paragraph defining conditional PPL, marginal PPL, and DI.
- Move the rest to an appendix or online supplement.

---

### 5. Sharpen the contribution paragraph into a true “why this paper is new” statement
**What:** Make the contribution more contrastive and specific.  
**Where:** Final paragraph of Introduction.  
**Why:** Right now the contribution is broadly stated but somewhat diffuse. The reader should leave the intro knowing exactly what this paper can do that prior work cannot.  
**Suggested rewrite direction:**  
Frame the novelty as a three-part contrast:
1. prior text methods score speeches independently,
2. deliberation coding captures interaction but is expensive and small-scale,
3. this paper scores speeches sequentially and decomposes speaker predictability from context predictability.

---

### 6. Add strong transitions at the start of Data, Framework, Model, and Results
**What:** Each section should open by saying what job it does in the overall argument.  
**Where:** First paragraph of Sections 3, 4, 5, and 6.  
**Why:** The current draft is modular, but the links between modules are weak. Strong transitions reduce reader fatigue.

Examples:
- Data: “We next construct the debate corpus and define the holdout period on which all substantive claims rest.”
- Framework: “With the corpus in place, the remaining task is to formalize what it means for debate context to matter.”
- Model: “We then estimate that object using a small domain-specific autoregressive model.”
- Results: “We use the holdout set to document two facts: raw predictability differs sharply by chamber, and debate context usually matters.”

---

### 7. Remove throat-clearing and generic reassurance language
**What:** Cut sentences that restate obvious points or defensively explain too much.  
**Where:** Throughout, especially Section 4 and Discussion.  
**Why:** This type of filler lowers perceived confidence and burns attention.

Candidates:
- “To interpret perplexity substantively, we define the three quantities we estimate.”
- “The model is not a black box. It is a conditional probability estimator.”
- “The honest summary: ...”
- “These patterns are descriptive; we now clarify...”

These can be replaced by direct statements.

---

### 8. Make the House-vs.-Senate decomposition more memorable
**What:** Rewrite the core contrast into a repeatable line.  
**Where:** Introduction, Results, Conclusion.  
**Why:** Tournament performance depends on whether a reader can remember the paper a week later. The current key insight is good but not yet phrased as a memorable takeaway.

Suggested phrasing:
- “The House is more scripted, but also more tethered to the immediately preceding turn.”
- “The House is easier to predict overall, yet more sensitive to conversational context.”
- “More formulaic does not mean less responsive.”

Pick one and repeat it consistently.

---

### 9. Tighten the Discussion so it interprets rather than re-summarizes
**What:** Remove duplicate summary sentences and focus the section on what the findings mean and what they cannot identify.  
**Where:** Discussion.  
**Why:** The Discussion currently repeats several earlier claims almost verbatim. That weakens pacing.

Suggested structure:
1. what the chamber contrast suggests,
2. why raw predictability and DI can move differently,
3. limitations,
4. next extensions.

---

### 10. Shorten captions and make them more informative
**What:** Rewrite captions to say what the exhibit establishes, not just what is plotted.  
**Where:** All tables and figures.  
**Why:** Strong captions let a skimming reader understand the argument from exhibits alone.

Example:
- Current: “Perplexity of Congressional speech by year and chamber (1994–2024).”
- Better: “House floor speech is more predictable than Senate speech in every holdout year; both chambers become less predictable during major political shocks.”

---

## Section 4: Exhibit Placement

For each exhibit:

- **Table 1: KEEP** — Core descriptive statistics for the corpus are useful in the main text, especially because the paper hinges on a temporal split and different data sources pre/post-2011. However, the table could be slightly tightened.

- **Figure 1 (Perplexity of Congressional speech by year and chamber): KEEP** — This is the paper’s main visual result. It belongs in the main text and should remain prominent.

- **Table 2 (Perplexity by Chamber, Selected Years): MOVE_TO_APPENDIX** — It is informative, but largely redundant with Figure 1. The figure already carries the narrative; this table mainly supplies selected exact values.

- **Table 3 (Deliberation Index Summary): KEEP** — This is the second central result and should remain in the main text.

- **Appendix Table A1 / Table “Model Specifications”: MOVE_TO_APPENDIX** — Correctly placed. Important for replication, not central to the main narrative.

- **Appendix Table A2 / Table “Training Progression”: MOVE_TO_APPENDIX** — Correctly placed. Training-loss progression is not essential for the main story.

- **Appendix Figure A1 / Figure “Speaker identification accuracy over time”: PROMOTE_TO_MAIN** — Best candidate for promotion. It provides model validation and would help reassure readers that the model has learned meaningful legislative structure rather than only generic language regularities.

- **Appendix Table A3 / Table “Speaker Identification Accuracy”: MOVE_TO_APPENDIX** — Keep in appendix. The summary numbers support the validation exercise, but if the figure is promoted, the table can stay supplementary.

- **Appendix Figure A2 / Figure “Party classification accuracy: neural model versus classical baselines”: MOVE_TO_APPENDIX** — Interesting, but tangential to the main paper. It supports a side comparison rather than the central contribution.

- **Appendix Figure A3 / Figure “Party identification versus individual identification”: MOVE_TO_APPENDIX** — Supplementary and not central enough for the main narrative.

- **Appendix Table A4 / Table “Party Classification Accuracy: All Methods”: MOVE_TO_APPENDIX** — Supplementary baseline comparison; not needed in the main text.

If you want, I can next turn this into a **line-editing memo** with proposed revised abstract, intro opening, and section-by-section rewrite language.