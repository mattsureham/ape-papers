# Strategic Feedback — GPT-5.4 (R2)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-13T11:06:19.325718
**Route:** OpenRouter + LaTeX
**Tokens:** 11300 in / 3679 out
**Response SHA256:** 8c4a688da1757db6

---

## 1. THE ELEVATOR PITCH

This paper asks a simple, important question: when U.S. firms randomly lose access to high-skilled foreign workers through the H-1B lottery, do they cut innovation investment? Using newly public lottery microdata linked to SEC filings, the paper finds that for publicly traded firms, random variation in H-1B lottery success does not measurably change R\&D spending. A busy economist should care because this speaks directly to whether high-skill immigration constraints bind at the firm level or whether large firms can substitute around them.

Does the paper itself articulate this pitch clearly in the first two paragraphs? Not quite. The current introduction gets to the question, but it takes too long to arrive at the paper’s actual claim, and it initially sounds like another H-1B/innovation paper with cleaner identification. The stronger story is not “we exploit true randomization,” but “even true randomization delivers a substantively surprising null: large firms appear insulated.”

### The pitch the paper should have

Every year, the H-1B cap forces firms to allocate high-skilled foreign hiring through a lottery. If access to global STEM talent is central to innovation, then losing that lottery should depress firms’ innovative investment. We test this directly by linking petition-level H-1B lottery outcomes to SEC filings for public firms and find the opposite of the usual presumption: random lottery losses do not reduce firm R\&D spending. This suggests that, at least for established public firms, immigration rationing reshuffles hiring channels and workers more than it constrains innovation budgets.

That is the pitch. Lead with the surprising world-facing fact, not the FOIA linkage.

---

## 2. CONTRIBUTION CLARITY

**One-sentence contribution:**  
The paper provides the first direct evidence, using randomized H-1B lottery outcomes linked to public-firm financials, that lottery-driven shocks to high-skilled foreign hiring do not materially change publicly traded firms’ R\&D spending.

### Is this contribution clearly differentiated from the closest papers?
Only partially. The paper names prior H-1B studies, but the differentiation is still muddy. A reader could easily come away thinking: “So this is an H-1B lottery paper with a new firm-level outcome.” That is not enough for AER-level positioning unless the outcome is made to seem decisive and the contrast with prior findings is sharpened.

The paper needs to distinguish itself from at least three adjacent strands:

1. **Papers linking H-1B/high-skilled immigration to innovation outcomes like patents**  
   The difference here is not just “we use R\&D instead of patents,” but that the paper studies a more upstream, budgetary margin within firms.

2. **Papers using H-1B lotteries to study employment substitution**  
   The difference is that this paper is about firm investment decisions, not hiring counts or composition.

3. **Papers on immigration restrictions inducing offshoring or substitution across locations/visa channels**  
   The paper’s substantive claim is that these substitution margins appear strong enough to preserve headline R\&D budgets.

4. **Papers on innovation finance/organization**  
   The paper should be clearer that it is informing how rigid or flexible R\&D budgets are when faced with labor-supply shocks.

### Is the contribution framed as answering a question about the world, or filling a literature gap?
Right now it oscillates. Too much of the introduction is “first linkage,” “first causal estimate on corporate financial variables,” “publicly available data.” Those are useful supporting points, but they are not the main event. The stronger framing is a question about the world:

- Do high-skill immigration constraints actually bind on innovation investment at large firms?
- Or do firms substitute enough to protect innovation spending?

That is much stronger than “there is limited causal evidence on firm financial outcomes.”

### Could a smart economist explain what’s new after reading the introduction?
At the moment, maybe, but not crisply. They might say: “It’s a nice H-1B lottery paper showing no effect on public firms’ R\&D.” That is serviceable, but it still risks sounding like “another DiD/lottery paper about immigration.”

To get to a cleaner takeaway, the intro has to foreground the substantive surprise:
- The H-1B lottery is often treated as a choke point for innovation.
- But for public firms, random losses do not move R\&D budgets.
- Therefore the binding margin may be worker allocation, hiring composition, or geography—not firm-level innovation spending.

### What would make this contribution bigger?
Several possibilities:

1. **A more consequential outcome variable**
   R\&D spending is conceptually upstream, but it is also very coarse. If the paper could connect lottery shocks to a more innovation-proximate output—patents, patent quality, product announcements, scientific publications, or segment-level innovation—that would make the paper much bigger.

2. **A sharper mechanism/comparison**
   The public-firm null becomes more interesting if paired with evidence that startups, private firms, or firms with thin substitution margins are affected. Right now the paper gestures at this in the discussion, but that is exactly where the action is.

3. **A stronger theory of what is being insulated**
   Is it budgets, projects, or domestic activity? The paper currently infers substitution but does not build the conceptual distinction sharply enough. A bigger contribution would explicitly frame the paper as estimating the net effect after firm adjustment and then show which margins are plausibly doing the work.

4. **A broader welfare framing**
   The most interesting line in the paper may be that the main costs of the lottery fall on workers rather than firms. If developed carefully, that reframes the policy debate in a way that could travel beyond the H-1B literature.

---

## 3. LITERATURE POSITIONING

### Closest neighbors
The likely closest neighbors are:

- **Kerr and Lincoln (2010)** on H-1B admissions and innovation/patenting
- **Peri, Shih, and Sparber (2015)** or related Peri papers on STEM immigration and innovation/productivity
- **Doran, Gelber, and Isen (2022)** on H-1B lotteries and firm hiring/substitution
- **Glennon (2020)** on immigration restrictions and offshoring of innovation
- **Bound et al. (2015, 2017)** on H-1B, high-skilled labor markets, and broader equilibrium/substitution issues

Depending on exact references intended, the paper also sits near the organizational/innovation literature on R\&D adjustment and labor constraints, though it currently does not exploit that conversation enough.

### How should it position itself relative to those neighbors?
Mostly **build on and reinterpret**, not attack.

- Relative to **Kerr/Peri**: “Those papers show that high-skilled immigration is linked to innovation outcomes; we test whether one especially clean, randomized hiring shock changes the most visible firm-level innovation input: R\&D spending.”
- Relative to **Doran et al.**: “They show worker/hiring substitution; we show that this substitution appears sufficient to insulate public-firm innovation budgets.”
- Relative to **Glennon**: “Our null is consistent with reallocation across locations or channels rather than a collapse in innovative activity.”
- Relative to **Bound et al.**: “Our evidence supports the view that firms have meaningful substitution margins.”

The paper should not overstate that it overturns the prior literature. It is better seen as isolating which margin moves and which margin does not.

### Is the paper positioned too narrowly or too broadly?
At present, oddly both.

- **Too narrowly** in the sense that it often reads like a data note about matching FOIA lottery data to SEC filings.
- **Too broadly** when it gestures at “innovation” writ large while only measuring accounting R\&D for public firms.

The right audience is not “all innovation economists” in the abstract. It is the intersection of immigration, firms, and innovation organization. The paper should own that niche and then explain why it matters broadly.

### What literature does the paper seem unaware of?
It could speak more to:

- **Firm organization / innovation management**: how rigid are R\&D budgets and project pipelines?
- **Labor adjustment within firms**: substitution across skill groups, geographies, and employment channels
- **Public finance / political economy of immigration policy**: if the main incidence is on workers, not firms, that changes policy framing
- **International/offshoring innovation** literature: the null on domestic public-firm R\&D is especially meaningful if innovation migrates geographically

### Is the paper having the right conversation?
Not fully. The current conversation is “clean causal immigration design + firm outcome.” The more impactful conversation is:

**When do labor-supply shocks actually move firm innovation investment, and when are firms organizationally capable of insulating core budgets?**

That framing connects immigration to a larger economics question about firms’ adjustment margins. It is a more AER-type conversation than a narrowly administrative-data H-1B contribution.

---

## 4. NARRATIVE ARC

### Setup
There is intense concern that U.S. caps on high-skilled immigration constrain innovation because firms need specialized STEM labor and H-1B demand vastly exceeds supply.

### Tension
The literature suggests H-1B access matters, but it remains unclear whether firm-level innovation investment itself is sensitive to these shocks, especially because firms may substitute through other channels. The H-1B lottery provides a rare randomized shock to labor access.

### Resolution
For publicly traded firms, random variation in H-1B lottery success does not translate into meaningful differences in R\&D spending.

### Implications
The cap may matter less for large-firm innovation budgets than commonly assumed; the main adjustment may happen through hiring composition, visa substitution, offshoring, or worker-level career disruptions rather than reductions in firm R\&D spending.

### Does the paper have a clear narrative arc?
It has one, but it is not yet fully controlled. Right now the paper sometimes reads like:
- nice data linkage,
- clean design,
- null main result,
- then a discussion section trying to decide what the null means.

That is a common structure for competent empirical papers, but not for the strongest AER narratives. The story should be tighter from page 1:

1. People think H-1B rationing may choke innovation.
2. A randomized test lets us isolate that claim.
3. Surprisingly, public firms’ R\&D budgets do not move.
4. Therefore the relevant economic margin is not “does innovation investment fall?” but “how do firms and workers absorb the shock?”

That is the story. Everything else should support it.

---

## 5. THE "SO WHAT?" TEST

### What fact would I lead with at a dinner party?
“Even when public firms randomly lose H-1B slots, their R\&D spending doesn’t budge.”

That is a decent opening fact. Better than many papers, though not instantly electrifying.

### Would people lean in or reach for their phones?
Some would lean in—especially immigration, labor, and innovation economists—because the result cuts against a common presumption. But many would immediately ask whether this is just because the sample is large, public firms that can easily absorb the shock. In other words, the result is interesting, but it naturally invites a boundary-condition question rather than immediate general excitement.

### What follow-up question would they ask?
Almost certainly:
- “So where does the adjustment happen instead?”
or
- “Would the effect be bigger for startups/private firms?”
or
- “Does R\&D spending stay flat while innovation output or domestic activity shifts?”

Those are exactly the questions the paper needs to anticipate and partially answer in its framing.

### Is the null itself interesting?
Yes—but only if the authors make the null do conceptual work. A null can be AER-worthy when it overturns an important prior belief or sharply narrows the set of plausible mechanisms. Here, the null is potentially interesting because:
- the shock is genuinely randomized,
- the policy object is high-profile,
- the prior rhetoric around H-1B often implies strong firm-level innovation consequences,
- and the null points toward substitution and incidence on workers rather than firm budgets.

But the paper cannot present the null as “we looked and didn’t find anything.” It must present it as:
**“The surprising fact is that this supposed innovation bottleneck does not move the budgetary margin at large firms.”**

Right now it is close, but not fully there.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Shorten the institutional and identification chest-thumping**
   The paper repeats “true randomization” too often. Once is powerful; five times starts to sound insecure. For editorial purposes, this is a framing issue: the paper should spend less time advertising design purity and more time explaining why the null matters.

2. **Move some data-construction detail out of the introduction**
   “First linkage,” “FOIA lawsuit,” “EIN matching,” “public replication” are worth one concise paragraph, not center stage.

3. **Front-load the main substantive takeaway**
   The introduction should tell the reader by paragraph 2 or 3 that the central result is a null on R\&D for public firms and why that is surprising.

4. **Elevate the substitution/incidence interpretation**
   The discussion currently contains the most interesting economics. Some of that belongs in the introduction: this is a paper about where immigration shocks bite.

5. **De-emphasize table-by-table procedural narration**
   Several result paragraphs read like guided tours of regression tables. The paper needs more synthesis and fewer coefficient recitations.

6. **Be more disciplined about secondary outcomes**
   Revenue, assets, PP&E, operating income do not currently help the narrative much, especially since the paper itself says some of those patterns are mechanical artifacts. If those outcomes mainly distract or introduce unresolved tension, push them back or trim them.

7. **Conclusion should do more than summarize**
   The current conclusion is clean but modest. It should end with the big implication: immigration lotteries may distort worker allocation much more than firm-level innovation budgets at large firms.

### Are there results buried in robustness that should be in the main text?
Potentially yes: the paper’s most consequential nuance is that weighted or high-registration subsamples may suggest larger estimates. Even if not emphasized as the headline, that boundary condition matters for strategic positioning. A top-journal paper cannot look like it is hiding the possibility that effects exist precisely where H-1B dependence is strongest. This needs to be integrated into the main narrative carefully: “average public-firm budgets are insulated, but the upper tail may be different.”

### Is the reader forced to wade too long before learning something interesting?
Somewhat. The abstract is actually sharper than the opening pages. The introduction should move faster to the big fact.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

At present, the gap is mostly **framing plus ambition**, with some **scope** concerns.

### Framing problem?
Yes. The paper undersells the strongest version of its own result. It should not sell itself as “a neat clean design with a null.” It should sell itself as:
- a randomized test of whether high-skill immigration constraints move innovation budgets,
- with the answer being no for public firms,
- implying strong firm substitution and shifting the incidence discussion toward workers and possibly location choice.

### Scope problem?
Yes. R\&D spending alone may be too coarse to carry the whole paper at AER level, especially with a null. The paper would be much stronger if it could show at least one of the following:
- no effect on budgets but effect on innovation output/composition,
- no effect for public firms but effect for firms with fewer substitution margins,
- evidence on offshoring or geographic reallocation,
- stronger mechanism evidence on alternative hiring channels.

### Novelty problem?
Moderate. The design and linkage are novel, but the substantive question is adjacent to a crowded literature. To clear the novelty bar, the paper has to be explicit that it isolates a distinct margin—firm innovation investment—not just “innovation” in a generic sense.

### Ambition problem?
Yes. The paper feels like a careful, competent paper that stopped one step short of the deeper question. The deeper question is not whether lottery wins affect one accounting variable; it is whether immigration constraints change the organization, location, and incidence of innovation. The current paper points in that direction without fully going there.

### Single most impactful piece of advice
**Reframe the paper around a sharper claim: randomized H-1B shocks do not move public firms’ innovation budgets, implying that the key economic margin is substitution and worker incidence rather than firm-level R\&D contraction—and then build the introduction, result hierarchy, and discussion entirely around that claim.**

If they can do only one thing, it is that.

---

### Strategic Assessment

- **Current framing quality:** Adequate
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium-Far
- **Single biggest improvement:** Recast the paper from “first clean linkage with a null result” to “a randomized test showing that large firms insulate innovation budgets from immigration shocks, shifting the policy incidence story toward substitution and workers.”