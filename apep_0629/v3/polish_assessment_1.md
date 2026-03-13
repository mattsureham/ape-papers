# Polish Assessment — GPT-5.4 (Round 1)

**Verdict:** POLISH_SAFE
**Model:** openai/gpt-5.4
**Paper:** paper.tex
**Timestamp:** 2026-03-13T16:28:07.345380
**Route:** OpenRouter + LaTeX
**Tokens:** 8568 in / 4616 out
**Response SHA256:** fadaed8892ee87e1

---

## Section 1: Escalation Check

**VERDICT: POLISH_SAFE**

I do **not** see any clear exhibit-text factual inconsistency that would require analytical revision rather than polishing.

What I checked:

- **House vs. Senate predictability claims**  
  The abstract, introduction, and results all say House speech is more predictable than Senate speech in every holdout year, with a **3–8 perplexity point gap**.  
  - **Table 2** (“Perplexity by Chamber, Selected Years”) shows gaps of **4.3 to 6.2** in the displayed years, which is consistent with the stated 3–8 range for the full holdout period.
  - **Figure 1** caption also supports the broader time-series claim.

- **2020 disruption claim**  
  The text says: “In 2020, the House rises 4.1 points and the Senate 2.8 points above their 2019 levels.”  
  - **Table 2** supports this exactly: House **40.1 → 44.2 = +4.1**; Senate **46.3 → 49.1 = +2.8**.

- **Deliberation Index claims**  
  The abstract/introduction/results claim:
  - **DI positive in 85% of turns**
  - **Mean DI = +2.52 overall**
  - **House DI = +2.76**, **Senate DI = +2.00**
  - **N = 832 turns**
  - **Five holdout years**
  
  These all match **Table 3**.

- **Training/model claims**  
  Main-text model description says:
  - **40.6M parameters**
  - **6 layers**
  - **384 embedding dimension**
  - **6 attention heads**
  - **2,048 token context**
  - **32,768 vocabulary**
  - **best validation perplexity 43.1 at step 11,000**
  
  These match **Appendix Table A1** and **A2**.

- **Corpus/data claims**  
  Main text says:
  - 1994–2024
  - **473M tokens**
  - **38,006 conversations**
  - **1,701 speakers**
  - training 1994–2014 with **386M** tokens
  - holdout 2015–2024 with **87M** tokens
  
  These match **Table 1**.

So this paper can be safely assessed as a **polish-only** project.

---

## Section 2: Structural Plan

### 1. Section ordering

The current order is serviceable but not optimal for a busy economics reader.

**Current order**
1. Introduction  
2. Related Literature  
3. Data  
4. Measurement Framework  
5. Model  
6. Results  
7. Discussion  
8. Conclusion

**Problem:**  
The paper asks the reader to hold a somewhat unusual concept—conditional vs. marginal perplexity and the Deliberation Index—through literature and data before the empirical payoff arrives. The introduction explains the basic idea, but the **full operational object** is not crystallized until Section 4. That delays the moment when the reader feels they really know what is being estimated.

**Recommended order**
1. Introduction  
2. **Measurement Framework**  
3. Data  
4. Model  
5. Results  
6. Discussion  
7. Related Literature  
8. Conclusion

**Why this is better**
- This is a **measurement paper** more than a literature-synthesis paper.
- The central object is the **Deliberation Index**, so the reader should get the conceptual and formal framework immediately after the intro.
- Moving literature later reduces front-loaded throat-clearing and gets the reader to the “what exactly do you measure?” question faster.

If the target outlet strongly prefers conventional literature placement, a compromise is:
1. Introduction  
2. **Very short related-literature bridge** (1–1.5 pages max)  
3. Measurement Framework  
4. Data  
5. Model  
6. Results  
7. Discussion  
8. Conclusion

### 2. Main vs. appendix balance

The current main text is fairly disciplined, but there are still opportunities to sharpen the narrative.

#### Main text exhibits
- **Table 1 (Corpus Summary Statistics): KEEP**
- **Figure 1 (Perplexity by year and chamber): KEEP**
- **Table 2 (Perplexity by Chamber, Selected Years): KEEP**
- **Table 3 (Deliberation Index Summary): KEEP**

That said, the main text currently has **four exhibits across a short paper**, which is reasonable. No urgent need to move any of them out.

#### Appendix exhibits
- **Figure A1 / Table A? Speaker identification results**: likely stay in appendix.
- **Figure A3 / Table on neural vs classical methods**: appendix is appropriate unless the paper wants to make “our model captures something different from party vocabulary” a coequal contribution.
- **Model specs / training progression**: appendix is the right place.

#### Possible promotion candidate
- **Figure showing DI distribution** is missing. If such a figure exists in the underlying materials, it would be a stronger main-text exhibit than some appendix diagnostics. Because the argument hinges on “positive in 85% of turns” and “heterogeneity across turns,” a histogram or density of DI would be very useful.  
  Since it does **not currently exist in the LaTeX**, this is not a placement change, but it is the single most notable exhibit gap.

### 3. Length balance

#### Too long relative to importance
- **Section 4: Measurement Framework**  
  This section is conceptually important, but it is a bit long and rhetorically expansive relative to the rest of the paper. The opening gallery vignette is vivid, but the section then spends a lot of words on explaining perplexity mechanics in a way that some economists may skim.

- **Section 7: Discussion**  
  The discussion is thoughtful, but somewhat repetitive of what the introduction and results already say: House more formulaic but more context-responsive; interpretation is descriptive not causal; limitations are real. This can be tightened by about 20–30%.

#### Too short relative to importance
- **Section 6: Results**  
  This is the heart of the paper, but it is brief. The key issue is not adding new analyses—it is adding **interpretation and signposting**:
  - what exactly does the time series teach us?
  - what does DI imply substantively?
  - why is the House/Senate decomposition surprising?
  
  The section should feel more like the payoff, not just a summary of numbers.

- **Conclusion**  
  Slightly too generic. It restates findings but does not leave the reader with one memorable sentence about why this measurement changes what we can learn about legislative institutions.

### 4. Redundancy

Several ideas are repeated in near-identical form:

1. **“House is more formulaic but more context-responsive”**  
   Appears in:
   - Introduction
   - Results
   - Discussion
   - Conclusion  
   This is the central result, so repetition is fine—but the wording is too similar each time. It starts to feel circular.

2. **“Perplexity measures predictability, not deliberative quality”**  
   Appears in:
   - Measurement Framework
   - Discussion
   - Conclusion (implicitly)  
   Again, important caveat, but can be stated crisply once and then referred back to.

3. **Institutional-rule interpretation of House/Senate differences**  
   Appears in both Results and Discussion.  
   Better division:
   - **Results:** state the empirical pattern and one sentence of interpretation.
   - **Discussion:** unpack the interpretation and caveats.

4. **Data-source difference motivating holdout restriction**  
   Mentioned in Data and Appendix C.  
   That’s okay, but main-text phrasing can be cleaner and less repetitive.

### 5. Missing transitions

This paper’s biggest structural weakness is not missing sections; it is **missing “why now this?” transitions**.

#### Specific gaps
- **Introduction → Related Literature**  
  The intro ends with contribution. Then the paper shifts to literature without telling the reader what question the literature review is setting up.

- **Data → Measurement Framework**  
  This jump is awkward. After corpus construction, the reader wants: “With the corpus in hand, we define the object we measure.” That bridge is absent.

- **Measurement Framework → Model**  
  The reader needs one sentence explaining why this architecture is sufficient for the measurement task, rather than feeling like the model section is just technical reporting.

- **Model → Results**  
  This is the biggest gap. It should say something like: “We now show what this measure reveals about institutional differences in congressional speech.”

### Concrete restructuring plan

### Proposed revised structure

**1. Introduction**
- Paragraph 1: hook + big question
- Paragraph 2: what you do
- Paragraph 3: headline findings
- Paragraph 4: contribution and roadmap

**2. Measurement Framework**
- 2.1 Conceptual idea: deliberation as context-sensitive predictability
- 2.2 Formal definitions: conditional PPL, marginal PPL, DI
- 2.3 Interpretation and limits

**3. Data**
- Corpus construction
- Train/holdout split
- Why DI uses holdout GovInfo only

**4. Model**
- One concise paragraph on architecture and training
- Push most implementation detail to appendix

**5. Results**
- 5.1 House vs Senate raw predictability
- 5.2 DI summary and interpretation
- 5.3 Why lower raw perplexity and higher DI can coexist

**6. Discussion**
- Descriptive institutional interpretation
- Limits
- External/generalization implications

**7. Related Literature**
- Trim to 3 focused subsections, each ending with “what this paper adds”

**8. Conclusion**
- End on one memorable line about what becomes measurable now

---

## Section 3: Prose Priorities

Below are the **top 10 rewrite actions**, ordered by tournament impact.

---

### 1. Rewrite the opening two paragraphs to foreground the empirical payoff faster

**What:**  
Make the opening less philosophical and more tournament-oriented: big question, measurement innovation, main result, why it matters.

**Where:**  
Introduction, first two paragraphs.

**Why:**  
The first two paragraphs are the paper’s most valuable real estate. Right now they are strong but slightly essayistic. A busy economist should know within 20 seconds:
- what is measured,
- why existing measures miss it,
- what the paper finds.

**Example**

**Before**  
“How predictable is legislative speech? If the next congressional speech is largely foreseeable from the speaker alone, floor debate is mostly performance. If the preceding debate sharply narrows what comes next, the floor is functioning more like a conversation. The distinction matters for democratic theory...”

**After**  
“Is floor debate actually a conversation, or mostly a sequence of prepared speeches? We answer that question by measuring how much the previous debate helps predict the next congressional speech. Using a language model trained only on Congressional Record text, we show that House speech is consistently more predictable than Senate speech, but also more responsive to immediately preceding turns.”

---

### 2. Tighten the abstract to a sharper 3-part structure: question, method, findings

**What:**  
Compress and sharpen the abstract so every sentence earns its place.

**Where:**  
Abstract.

**Why:**  
The abstract is already decent, but it can be more economical and more memorable. Right now it explains the mechanics before fully stating the payoff.

**Example**

**Before**  
“We measure the predictability of U.S. Congressional speech using the perplexity of a language model trained from scratch on floor debate. Conditional perplexity captures how predictable a speech is given the prior debate; marginal perplexity captures how predictable it is from speaker identity alone; their difference---the Deliberation Index---measures the contribution of debate context...”

**After**  
“We measure whether congressional speech responds to prior debate or merely reflects who is speaking. Using a language model trained from scratch on floor debate, we compare the predictability of each speech with and without prior conversational context. Their gap—the Deliberation Index—captures how much debate context matters. In holdout data from 2015–2024, House speech is 3–8 perplexity points more predictable than Senate speech in every year, yet the House also has a higher Deliberation Index. Overall, prior debate improves prediction in 85% of turns. The framework provides a scalable measure of conversational structure in legislatures.”

---

### 3. Rewrite results narration so it interprets findings instead of walking through exhibits

**What:**  
Replace exhibit-led prose (“Table X shows…”) with argument-led prose (“The key substantive fact is…”).

**Where:**  
Section 6, especially paragraphs around Table 2 and Table 3.

**Why:**  
Top readers remember interpretations, not table navigation. The current prose is already better than many drafts, but it still leans too much on reported numbers and not enough on “what did we learn?”

**Example**

**Before**  
“The Deliberation Index, computed on a stratified sample of 832 turns from five holdout years (\Cref{tab:deliberation}), is positive in 85\% of turns, with a mean of +2.52...”

**After**  
“Most congressional turns are easier to predict once the preceding debate is observed. In our holdout sample, adding debate context lowers effective uncertainty in 85% of turns, by 2.52 perplexity points on average. This is the paper’s core empirical result: floor speech usually depends on what was just said, not only on who is speaking.”

---

### 4. Make the contribution paragraph more pointed about what is genuinely new

**What:**  
Clarify that the novelty is not “using AI on political text,” but **measuring sequential context dependence in debate** and decomposing predictability into speaker-driven vs debate-driven components.

**Where:**  
Introduction, final paragraph.

**Why:**  
The current contribution paragraph is good but still reads a bit literature-review-like. It should claim a distinct measurement contribution more forcefully.

---

### 5. Cut or compress explanatory material on perplexity mechanics

**What:**  
Trim the middle of Section 4, especially the long explanation of entropy/perplexity and token probabilities.

**Where:**  
Measurement Framework, subsection “Perplexity as a measure of surprise.”

**Why:**  
For economists, a concise explanation is enough. The current version is lucid but a bit long relative to its payoff. Overexplaining the ML object risks making the paper feel more like a methods note than an economics paper.

---

### 6. Add explicit bridge sentences at the start and end of major sections

**What:**  
Insert one-sentence transitions that orient the reader:
- why the next section follows,
- what question it answers.

**Where:**  
End of Introduction, start of Data, start of Model, start of Results, start of Discussion.

**Why:**  
This improves flow dramatically at very low cost. Right now the paper is readable paragraph by paragraph but less smooth section by section.

---

### 7. Differentiate the roles of Results and Discussion

**What:**  
Keep empirical facts in Results; move fuller institutional interpretation and caution to Discussion.

**Where:**  
Sections 6 and 7.

**Why:**  
Currently the same interpretive point appears in both places. Sharper division will make both sections feel more purposeful.

---

### 8. Reduce throat-clearing and hedging where the paper can be direct

**What:**  
Cut phrases like:
- “These patterns are descriptive; we now clarify...”
- “The honest summary...”
- “What is missing is the combination...”
when they can be written more cleanly.

**Where:**  
Measurement Framework, Discussion, Related Literature.

**Why:**  
The voice should sound confident without overstating. Some current phrasing feels like workshop talk rather than polished journal prose.

---

### 9. Make the paper more memorable by using one stable verbal contrast

**What:**  
Choose one simple contrast and repeat it consistently:
- “prepared speech vs responsive speech”
or
- “performance vs conversation”
or
- “formulaic vs context-responsive”

**Where:**  
Abstract, introduction, results, conclusion.

**Why:**  
Right now the paper uses several overlapping formulations. A single recurring contrast improves retention.

My recommendation: use **“formulaic vs context-responsive”** for the main result, and **“performance vs conversation”** once in the opening as the hook.

---

### 10. Rewrite the conclusion to end on the paper’s durable takeaway, not just a summary

**What:**  
Make the final paragraph answer: what can scholars now study that they could not study before?

**Where:**  
Conclusion.

**Why:**  
The current conclusion is competent but not sticky. The paper needs a stronger final line.

Possible direction:
- this creates a scalable measure of conversational structure in institutions;
- it lets researchers compare legislatures, shocks, reforms, and arenas of speech using a common metric.

---

## Section 4: Exhibit Placement

For each exhibit currently in the paper:

- **Table 1: KEEP** — Essential orientation for the corpus, train/holdout split, and chamber coverage. Readers need this in the main text because the paper’s design depends on the 1994–2014 vs 2015–2024 split and on source differences.

- **Figure 1 (Perplexity of Congressional speech by year and chamber): KEEP** — This is the main visual result and should remain in the main text. It communicates the House–Senate gap and the 2020 disruption pattern at a glance.

- **Table 2 (Perplexity by Chamber, Selected Years): KEEP** — Useful companion to Figure 1 because it gives concrete magnitudes for the gap and the 2019–2020 jump. If the paper were shorter, this could move to appendix, but in the current draft it helps anchor the verbal claims.

- **Table 3 (Deliberation Index Summary): KEEP** — Core result. This belongs in the main text because the DI is the paper’s main conceptual contribution.

- **Appendix Table A1 (Model Specifications): KEEP in appendix** — Appropriate technical detail; not central enough for the main narrative.

- **Appendix Table A2 (Training Progression): MOVE_TO_APPENDIX / already appendix** — Correctly placed in appendix. It is not needed for the main paper’s argument.

- **Appendix Figure B1 / Figure on Speaker Identification Accuracy: KEEP in appendix** — This is a diagnostic/validation exercise, interesting but not part of the main narrative. Good appendix material.

- **Appendix Table B1 (Speaker Identification Accuracy): KEEP in appendix** — Same reason. Supports the appendix validation exercise.

- **Appendix Figure B2 (Neural versus Classical Methods): KEEP in appendix** — Interesting comparison, but it opens a secondary argument about what neural vs TF-IDF methods capture. Unless the authors want to reposition the paper partly as a comparison to polarization classifiers, this should remain in appendix.

- **Appendix Figure B3 (Party identification versus individual identification): RELABEL** — Keep in appendix, but the caption should do more work. The current caption is a bit generic. It should explain what is plotted and why this matters for the interpretation of speaker fingerprints and party homogeneity.

- **Appendix Table B2 (Party Classification Accuracy: All Methods): KEEP in appendix** — Correctly placed. Useful reference, not central.

### Caption relabel suggestions

A few exhibits would benefit from stronger captions even if they stay in place:

- **Figure 1: RELABEL** — Current caption is fine but could be more informative. Suggested style:  
  “Annual perplexity of House and Senate floor speech, 1994–2024. Lower values indicate more predictable speech. The House is more predictable in every holdout year (2015–2024), with both chambers showing a sharp increase in unpredictability in 2020.”

- **Table 2: RELABEL** — Caption should emphasize that these are **selected holdout years** and that the full pattern is annual and monotone in sign.  
  Suggested style:  
  “Selected holdout-year perplexity by chamber. In every year from 2015–2024, House speech is more predictable than Senate speech; the rows shown illustrate the typical 3–8 point gap.”

- **Table 3: RELABEL** — Caption should foreground the empirical takeaway, not just the object.  
  Suggested style:  
  “Debate context usually improves prediction of the next speech. The Deliberation Index is positive in 85% of sampled holdout turns and is larger in the House than in the Senate.”

---

### Bottom line

This paper is **safe to polish**. The main opportunities are not analytical corrections but:
- front-loading the contribution,
- clarifying the measurement object earlier,
- making results more interpretive and memorable,
- tightening redundancy,
- and sharpening exhibit captions and transitions.

If you want, I can next turn this assessment into a **line-by-line revision blueprint** or directly produce a **polished rewrite of the abstract and introduction**.