# Strategic Feedback — GPT-5.4 (R1)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-13T11:06:19.323393
**Route:** OpenRouter + LaTeX
**Tokens:** 11300 in / 3977 out
**Response SHA256:** e8068b16c0180241

---

## 1. THE ELEVATOR PITCH

This paper asks a simple, policy-relevant question: when U.S. firms lose the H-1B lottery for high-skilled workers, do they cut innovation investment? Using newly public petition-level lottery data linked to SEC filings for publicly traded firms, the paper finds essentially no effect of lottery win rates on firm R\&D spending, suggesting that large firms buffer immigration shocks through substitution rather than shrinking innovation budgets.

Why should a busy economist care? Because the H-1B debate is usually framed as one about U.S. innovation capacity. A credible null on firm R\&D, if properly framed, would shift the conversation from “do caps hurt firms?” toward “who actually bears the cost of rationing: firms, workers, or locations?”

### Does the paper itself articulate this pitch clearly in the first two paragraphs?

Not quite. The current introduction is competent, but it drifts too quickly into identification and literature bookkeeping. The pitch is there, but the paper does not fully capitalize on the most interesting aspect: **a clean lottery design delivering a substantively surprising null about innovation at large public firms**.

The first two paragraphs should say, more directly:

> U.S. immigration policy rations high-skilled labor through a literal lottery. If access to foreign STEM workers is essential for innovation, then firms that lose the H-1B lottery should scale back innovative investment. Yet if firms can substitute across hiring channels, locations, or worker types, then firm-level innovation spending may be largely insulated from immigration shocks.  
>   
> We study this question by linking newly released petition-level H-1B lottery records to SEC filings for publicly traded firms. Exploiting random variation in firms’ lottery success, we find little evidence that winning more H-1B slots increases R\&D spending. For large public firms, the immediate economic incidence of H-1B rationing appears not to be lower innovation budgets, but reallocation across margins outside the observed visa channel.

That is the pitch the paper should have. It foregrounds the world question, the surprise, and the stakes.

---

## 2. CONTRIBUTION CLARITY

### Contribution in one sentence

The paper’s contribution is to show, using firm-level random variation from the H-1B lottery linked to public-company financials, that lottery-induced differences in access to foreign skilled workers do not meaningfully change R\&D spending among publicly traded firms.

### Is this contribution clearly differentiated from the closest 3-4 papers?

Only partially. The paper names some neighbors, but the differentiation is still fuzzy. Right now the contribution risks sounding like: “another H-1B paper with a cleaner design and a different dataset.” That is not enough for AER. It needs to say much more sharply:

- prior work studies **patents, employment, wages, offshoring, or firm growth**;
- this paper studies **corporate innovation budgeting / financial policy**;
- prior firm-level causal evidence often uses restricted data or narrower settings;
- this paper shows that even when worker access is randomized, **firm-level R\&D expenditure is insulated**.

That last point is the real differentiator. But the paper has not yet made it feel like a big conceptual step.

### Is the contribution framed as answering a question about the world, or filling a gap in a literature?

It oscillates, but too often defaults to “we are the first to link X to Y” and “we provide causal estimates for corporate financial variables.” That is a **literature/data-gap framing**, which is weak.

The stronger framing is a **world question**:

- Does rationing skilled immigration actually constrain firm innovation spending?
- Or do firms substitute enough that observed innovation budgets do not move?

That should be the center of gravity.

### Could a smart economist who reads the introduction explain to a colleague what’s new?

At present, they might say: “It’s a clean lottery paper on H-1Bs and public-firm R\&D, and the effect is null.” That is decent, but not memorable enough. The introduction does not yet equip the reader to say the more interesting version: “The surprising thing is that random variation in access to H-1B workers doesn’t move the innovation budgets of large firms, so the cap may distort worker allocation more than firm-level R\&D.”

### What would make this contribution bigger?

Several possibilities, in order of strategic importance:

1. **A better outcome variable than R\&D expenditure alone.**  
   R\&D expense is very coarse and managerial. It may be deliberately smoothed. If the paper could connect to innovation output or organization of innovation—patents, inventor mobility, foreign affiliate activity, outsourcing, or segment/geographic reallocation—it would become much more important.

2. **Direct evidence on substitution margins.**  
   The discussion leans heavily on OPT, L-1, domestic hiring, offshore R\&D. But these are conjectural in the current draft. The paper would be much bigger if it showed where the missing adjustment occurs.

3. **Sharper incidence framing.**  
   If firms’ innovation budgets do not move, then who bears the burden? The paper hints “workers rather than firms,” but this is underdeveloped. Even descriptive evidence on worker outcomes, application behavior, or geographic relocation would enlarge the contribution.

4. **A cleaner distinction between large public firms and the margin where policy likely bites.**  
   Right now the paper sometimes sounds like it is answering the broad question “do H-1B caps affect innovation?” when really it answers a narrower and interesting question: “for established public firms, does lottery luck shift innovation budgets?” The contribution becomes stronger if it owns that scope and then interprets it.

---

## 3. LITERATURE POSITIONING

### Closest neighbors

The nearest conversation seems to include:

- **Kerr and Lincoln (2010)** on H-1B admissions and ethnic invention/patenting.
- **Peri, Shih, and Sparber (2015)** or adjacent high-skilled immigration papers on STEM labor and innovation/productivity.
- **Bound et al. (2017)** on the H-1B program and high-skilled labor markets / substitution.
- **Doran, Gelber, and Isen (2022)** on the H-1B lottery and firm employment outcomes.
- **Glennon (2020)** on H-1B restrictions and offshoring / foreign affiliate responses.

Depending on exact citations, there is also a broader corporate innovation finance literature and a personnel economics / firm adjustment literature that should be brought in.

### How should the paper position itself relative to those neighbors?

Mostly **build on and re-interpret**, not attack.

- Relative to **Kerr/Lincoln**: “Prior work suggests high-skilled immigration matters for innovation output. We ask whether that translates into shifts in firms’ internal innovation budgets.”
- Relative to **Doran et al.**: “They show worker- and employment-side effects from lottery variation; we ask whether those shocks propagate to firm financial policy.”
- Relative to **Glennon**: “If restrictions trigger offshoring, then a null on domestic public-firm R\&D budgets is plausible; our evidence is consistent with adjustment on unobserved margins.”
- Relative to **Bound et al.**: “We contribute to the substitution debate by showing that large firms’ innovation spending appears buffered.”

The current paper is a little too eager to sell “first causal estimates on corporate financial variables.” That is true but not very exciting. It should instead say: **we test whether worker-level visa rationing scales up into firm-level innovation retrenchment.**

### Is the paper positioned too narrowly or too broadly?

Paradoxically, both.

- **Too broad** in the introduction and conclusion, where it sometimes sounds like it settles whether H-1B caps constrain innovation.
- **Too narrow** in the actual empirical execution, because the main outcome is just public-firm R\&D expenditure.

It should narrow the claim and broaden the conversation:
- Narrow the claim to **public-firm innovation budgets**.
- Broaden the interpretation to **incidence, adjustment, and organizational margins of immigration policy**.

### What literature does the paper seem unaware of?

Two literatures seem underused:

1. **Corporate innovation / investment smoothing / internal organization**
   - Why might R\&D budgets be rigid?
   - What does it mean if labor shocks do not move line-item R\&D?
   - There is a rich finance and IO literature on how firms manage innovation spending strategically.

2. **Firm adjustment to labor supply shocks**
   - Not just immigration; more broadly, how firms respond to skill shortages through wages, offshoring, reorganization, automation, or delayed projects.

If positioned against those literatures, the null becomes more interesting: perhaps R\&D expenditure is a poor proxy for innovation production under labor rationing, because firms reallocate inputs while preserving budgets.

### Is the paper having the right conversation?

Not yet fully. It is currently having the standard immigration-econ conversation. That is necessary, but not sufficient for AER. The more impactful conversation is the intersection of:

- immigration policy,
- firm organization,
- innovation production,
- and incidence of labor-market rationing.

That unexpected bridge is where this could become more than a niche H-1B paper.

---

## 4. NARRATIVE ARC

### Setup

The world has intense excess demand for H-1B visas, and policymakers and economists worry that restricting high-skilled immigration reduces U.S. innovation.

### Tension

We have lots of suggestive evidence that high-skilled immigrants matter for innovation, but less credible evidence on whether exogenous visa rationing actually changes firm behavior—especially at the level of corporate innovation investment rather than employment or patent counts. And there are competing theories: maybe firms are constrained; maybe they substitute.

### Resolution

Using random variation from the H-1B lottery linked to SEC data, the paper finds that public firms’ R\&D spending does not respond detectably to lottery success.

### Implications

For large public firms, H-1B rationing may not compress innovation budgets; instead, firms may absorb the shock through substitution or reallocation. That shifts the incidence story away from firms’ visible innovation spending and toward workers or less visible organizational margins.

### Does the paper have a clear narrative arc?

It has the ingredients, but not yet a disciplined arc. Right now it reads somewhat like:

- nice institutional setup,
- clean randomization,
- null main result,
- a bunch of reasonable but under-evidenced interpretations.

So it is closer to **a collection of results looking for a story** than a fully realized AER narrative.

### What story should it be telling?

The story should be:

1. **Policy concern:** H-1B caps are said to threaten innovation.
2. **Test:** The lottery gives random shocks to access to foreign skilled labor.
3. **Surprise:** Those shocks do not move R\&D budgets at public firms.
4. **Interpretation:** The relevant margin is not “whether firms innovate” but “how they staff or locate innovation.”
5. **Implication:** Immigration rationing may distort careers and composition more than top-line innovation spending at large firms.

That story is coherent, surprising, and consequential. The current draft gets close but spends too much space proving competence and too little space developing the conceptual implications of the null.

---

## 5. THE "SO WHAT?" TEST

### What fact would I lead with?

I would lead with: **Even when firms are randomly denied H-1B slots, large public firms do not cut R\&D spending.**

That is the dinner-party line.

### Would people lean in or reach for their phones?

Economists would lean in initially, because the setting is strong and the result is surprising. But the second question would come fast:

> “Interesting—but then what actually adjusts?”

If the paper cannot answer that, enthusiasm will fade. A clean null is intriguing for about three minutes; after that, the paper needs either a mechanism or a strong reinterpretation of the policy debate.

### What follow-up question would they ask?

Likely one of:
- Is R\&D spending too coarse to capture innovation losses?
- Are firms substituting to domestic workers, other visas, or foreign affiliates?
- Is this just a statement about large public firms, not the firms where H-1B constraints matter most?
- Do patents, project timing, or inventor composition move even if budgets do not?

### If the findings are null or modest: is the null itself interesting?

Yes, but only conditionally. The null is interesting because:
- the treatment is credibly exogenous,
- the policy stakes are large,
- and the paper tests a first-order claim in the public debate.

However, the draft has not fully made the case that learning “R\&D budgets don’t move” is valuable in itself. It needs to say explicitly: **many commentators infer from H-1B scarcity that firms’ innovation capacity is directly constrained; our evidence rejects that mechanism for the large public-firm margin.**

Right now the null is presented as “precisely estimated,” but it is not yet elevated into a belief-revising result. Also, one should be careful with “precisely estimated” language when later the paper notes confidence intervals that still contain moderate effects found in prior work. Strategically, better to say the paper rules out large budget responses rather than making precision do more work than it can bear.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Shorten the institutional and data construction sections in the main text.**  
   The lottery mechanism is simple. The matching exercise is useful but currently over-described relative to the payoff. Some of this belongs in an appendix.

2. **Move the “we built a novel dataset” material down.**  
   Useful, but not the lead. The lead is the substantive question and the surprising null.

3. **Put the main result earlier and more starkly.**  
   The reader should know by page 2 or 3 exactly what the paper finds and why that changes the debate.

4. **Trim the contributions paragraph.**  
   Right now it lists three contributions in a standard style. That reads workshop-paper-ish. Better to integrate the contribution into a tighter narrative.

5. **Substantially rethink the robustness section in the main text.**  
   There is too much defensive material in the body, especially around thresholds and alternative standard errors. That material is referee-facing, not editor/reader-facing.

6. **Bring any mechanism-relevant evidence forward if it exists.**  
   If the weighted results or heterogeneity results suggest the null is concentrated among certain firms, that may be narratively important. Right now some potentially interesting patterns are buried and then waved away.

7. **Rewrite the conclusion to do more than summarize.**  
   The current conclusion largely repeats the findings. It should instead answer: what should economists now believe about immigration caps and firm innovation? What remains unresolved?

### Are there results buried in robustness that should be in the main results?

Potentially yes, but only if they can be framed constructively:
- The fact that the null is specific to R\&D while scale outcomes show mechanical correlation is important for interpreting the design.
- The weighted specification and high-registration thresholds may point to economically relevant heterogeneity among the most H-1B-intensive firms. Right now these are introduced as nuisances to be neutralized. But strategically, if the effects may emerge for the firms where the lottery truly bites, that is important—even if preliminary.

That said, the paper should not foreground every wrinkle. It should either:
- stay disciplined: “for the broad public-firm sample, no effect on R\&D budgets,” or
- pivot to heterogeneity as the main contribution if that is where the interesting action lies.

At present it tries to do both.

### Is the conclusion adding value or just summarizing?

Mostly summarizing. It should be reframed around the paper’s broader implication: **immigration policy may reshape staffing and location without moving top-line innovation spending at large firms.** That is the thought readers should leave with.

Also, the acknowledgements section declaring the paper was “autonomously generated” is obviously fatal in current form for serious journal positioning. Even as a private memo, this needs to be said plainly: it undermines credibility instantly and should not appear in any submission intended for a top journal.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

This is not primarily an identification problem. The core issue is **strategic ambition and framing**.

### What is the gap?

Mostly:

- **Framing problem:** The paper undersells the real question and overemphasizes data novelty.
- **Scope problem:** R\&D expenditure alone is too blunt an endpoint for a paper aspiring to top-tier general-interest significance.
- **Ambition problem:** The current draft is content to document a null, suggest plausible substitution channels, and stop there.

Less of a novelty problem—the setting is genuinely interesting. But novelty in data/linkage is not enough.

### What would excite the top 10 people in this field?

A version that says one of the following:

1. **Randomized H-1B shocks do not reduce public firms’ innovation spending because firms substitute across labor and location margins—and here is direct evidence of those margins.**
   
   or

2. **The incidence of H-1B rationing falls less on firm-level innovation than on workers and organizational geography—and here is evidence connecting those pieces.**

That is a much bigger paper than “null effect on R\&D in SEC data.”

### Single most impactful piece of advice

If the authors can only change one thing, it should be this:

**Reframe the paper from a “first linkage / clean null on R\&D” paper into a paper about the incidence and adjustment margins of high-skilled immigration rationing, and add at least one direct piece of evidence on where firms substitute when they lose the lottery.**

Without that, this is a solid field-journal paper with a clean design. With that, it has a chance to become a general-interest paper.

---

### Strategic Assessment

- **Current framing quality:** Adequate
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium
- **Single biggest improvement:** Recast the paper around the substantive puzzle—why randomized H-1B losses do not reduce large firms’ innovation budgets—and show at least one concrete substitution/incidence margin.