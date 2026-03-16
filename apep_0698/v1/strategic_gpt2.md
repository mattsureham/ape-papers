# Strategic Feedback — GPT-5.4 (R2)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-16T00:35:27.990573
**Route:** OpenRouter + LaTeX
**Tokens:** 10658 in / 3336 out
**Response SHA256:** e8a4a5e99c4c70ca

---

## 1. THE ELEVATOR PITCH

This paper asks a potentially interesting question: when a major emergency aid program is extended from firms to nonprofits, do the program’s eligibility rules actually map onto the way nonprofits are organized and documented? Using linked PPP and IRS Form 990 data, the paper argues that the Second Draw PPP’s 25 percent revenue-loss threshold did not meaningfully structure nonprofit participation, because the rule was built around quarterly revenue documentation while nonprofits are observed in annual filings; the paper also shows that simple positive PPP-employment correlations are likely just selection.

Why should a busy economist care? Not because this is “the first Form 990 study of nonprofits under PPP,” but because it raises a broader issue of policy design: eligibility rules can be formally precise yet operationally irrelevant when they are misaligned with the administrative infrastructure of the target sector.

Does the paper articulate this clearly in the first two paragraphs? Not really. The opening is competent, but it leads with scale and a literature/data gap (“no study has examined…”), then with generic ways nonprofits differ from firms. That is not the sharpest hook. The real hook is that a celebrated, rules-based federal program may have had an eligibility threshold that was effectively non-allocative for an entire sector. That should be the first paragraph, not page 2 material.

### The pitch the paper should have

A stronger opening would say something like:

> The Paycheck Protection Program’s Second Draw was supposed to target organizations hit hardest by the pandemic, using a bright-line rule: borrowers had to show a 25 percent revenue decline. This paper asks whether that rule actually governed access for nonprofits, or whether it was largely beside the point because nonprofits do not produce the kind of quarterly revenue records around which the program was designed.
>
> Linking SBA PPP microdata to IRS Form 990 filings, I show that among nonprofits there is no detectable increase in Second Draw take-up around the statutory threshold. The broader lesson is not just about PPP: policy rules depend on administrative measurement, and when governments import firm-oriented eligibility criteria into sectors with different reporting systems, those rules may be decorative rather than allocative.

That is the story. Everything else is subordinate.

---

## 2. CONTRIBUTION CLARITY

### One-sentence contribution

The paper’s core contribution is to show that PPP Second Draw’s statutory revenue-loss threshold did not meaningfully govern nonprofit loan receipt, implying a mismatch between emergency program design and the administrative data infrastructure of the nonprofit sector.

### Is this clearly differentiated from the closest papers?

Only partially. The paper does identify three candidate points of novelty:
1. nonprofit sector rather than firms,
2. Form 990 linked microdata,
3. testing whether the threshold was binding.

But these are presented more as “firsts” than as conceptual differentiation. “First linked dataset” is not, by itself, an AER contribution. “First nonprofit PPP paper” is field-journal language unless attached to a broader proposition about targeting, state capacity, administrative burden, or policy design.

The paper needs to distinguish itself more cleanly from:
- PPP papers estimating employment effects,
- PPP papers on targeting/misallocation,
- papers on administrative burden/access to public programs,
- nonprofit finance papers on organizational capacity and funding volatility.

Right now a smart economist might summarize it as: “It’s a PPP paper using nonprofit data, and the RD first stage is zero.” That is not enough.

### World question or literature-gap question?

Currently too much of the framing is “there is a gap in the literature” and “no study has examined X using Y data.” That is weak. The stronger framing is a world question:

**When government deploys emergency aid using eligibility rules designed for one organizational form, do those rules actually govern access in other sectors?**

That is a real question about the world. It travels beyond PPP and beyond nonprofits.

### Could a smart economist explain what is new?

Not yet with confidence. They would probably say: “It’s another quasi-experimental PPP paper, but in nonprofits, and the intended design doesn’t bite.” That is better than nothing, but still sounds niche and diagnostic rather than agenda-setting.

### What would make the contribution bigger?

Most importantly, the paper would be bigger if it pivoted from “estimating PPP’s nonprofit employment effect” to **documenting the failure of formal eligibility rules to structure allocation**. Specific ways to enlarge the contribution:

- **Different framing:** Make this a paper about administrative design failure, not about an unsuccessful attempt to estimate treatment effects.
- **Different outcomes:** Show how allocation actually worked if not through the threshold: by lender relationships, organization size, subsector, state capacity, or organizational sophistication. Right now the paper gestures at these mechanisms but does not make them central.
- **Different comparison:** Compare nonprofits to for-profits or to sectors with stronger quarterly reporting capacity. Even a descriptive comparison would sharpen the claim that the rule was sector-misaligned rather than just empirically weak.
- **Different mechanism:** Push harder on documentation mismatch and administrative burden. The most interesting claim here is not “no discontinuity in annual data,” but “the state used an eligibility metric that was not naturally legible in the target sector’s reporting environment.”
- **Different framing of null:** The null is only publishable at AER level if it is recast as positive evidence of a more general design principle.

---

## 3. LITERATURE POSITIONING

### Closest neighbors

The nearest neighbors seem to be:

- **Autor et al.** on PPP and employment effects.
- **Chetty et al. / Opportunity Insights-related PPP work** on small employment effects and high cost per job saved.
- **Granja et al. (2022)** on PPP targeting and misallocation.
- **Bartik et al. (2020)** on banking relationships and PPP access.
- On the nonprofit side, papers like **Calabrese**, **Hager**, **LeRoux**, and broader nonprofit finance/governance work on fiscal vulnerability and administrative capacity.

There is also a literature the paper should probably engage more directly:
- **Administrative burden / state capacity / policy implementation**: Moynihan, Herd, Heinrich-adjacent public administration work; in economics, work on take-up, administrative frictions, program access, and bureaucratic design.
- **Market design / screening / mechanism implementation under imperfect observability**.
- **Public finance and tax administration** papers on how policy effectiveness depends on observable/verifiable measures.

### How should it position itself?

It should **build on** the PPP-targeting literature and **connect** it to administrative capacity/measurement. It should not “attack” prior PPP papers; rather, it should say those papers largely ask whether PPP preserved jobs and whether funds were well targeted geographically or via banks, while this paper asks whether one of the program’s own explicit targeting rules was operational in a sector with different reporting infrastructure.

That is a clean complement.

### Too narrow or too broad?

At present, oddly both:
- **Too narrow** in its empirical self-presentation: a nonprofit-specific RD null.
- **Too broad** in some claims: “designed for firms,” “orthogonal to nonprofit data infrastructure,” “eligibility rules become decorative” — these are big claims not yet fully developed into a broad contribution.

The paper needs a more disciplined broad framing. Not “this changes how we think about emergency programs” in general, but “this illustrates a general implementation problem: eligibility rules only allocate when they map onto verifiable and routinely produced information.”

### What literature is it unaware of?

Most obviously, it feels underconnected to:
- administrative burden / take-up frictions,
- implementation and state capacity,
- public economics of verification and documentation,
- nonprofit organizational capacity and compliance burden,
- possibly health/education/public economics literatures where nonprofits are major service providers.

If this paper wants to matter, it should speak not just to “PPP economists” and “nonprofit scholars,” but also to economists interested in how governments operationalize targeting.

### Is it having the right conversation?

Not yet. It is currently having a conversation with the PPP effects literature when its comparative advantage is a conversation about **policy design under mismatched observability**. That is the more interesting and less crowded lane.

---

## 4. NARRATIVE ARC

### Setup

The world before this paper: PPP was an enormous emergency program; Second Draw added a targeted rule meant to channel aid toward harder-hit organizations; economists have debated whether PPP preserved jobs and whether funds were well targeted.

### Tension

The puzzle is not merely that nonprofits are under-studied. The deeper tension is that Second Draw’s targeting logic relied on quarterly revenue verification, while nonprofits live in an annual-reporting ecosystem and often have different administrative capacity. So did the rule that was supposed to target need actually govern nonprofit access?

### Resolution

The paper finds that, in linked nonprofit administrative data, there is no detectable jump in Second Draw receipt at the 25 percent revenue-decline threshold. Meanwhile, positive PPP-employment correlations look like selection, not causal effects.

### Implications

The implication is that policy targeting is only as real as the administrative measurement technology behind it. Formal statutory rules can fail to allocate when they are imported into sectors whose records, intermediaries, and compliance practices do not match the rule’s informational requirements.

### Does the paper have a clear narrative arc?

It has the ingredients, but the current paper is still too much a collection of empirical sections:
- data contribution,
- threshold test,
- OLS with placebo,
- robustness,
- discussion.

The most coherent story is not “Can we estimate PPP’s effect in nonprofits?” because the answer is basically no. The story is “A major federal targeting rule appears not to have structured nonprofit access, revealing an implementation mismatch.” The OLS section should support that story, not compete with it.

Right now the paper still feels a bit like it discovered a null first stage and then built a narrative around it. To get to AER-level storytelling, the author needs to make the design-mismatch thesis the organizing principle from line 1.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with?

I would lead with:

**A $67 billion federal program for nonprofits had a statutory targeting threshold that appears not to have differentiated nonprofit recipients at all.**

That is the dinner-party line.

### Would people lean in?

Some would. Public economists, labor economists, and economists interested in state capacity or policy implementation would lean in. But if you instead lead with “I linked PPP data to Form 990s and found a null first stage at 25 percent annual revenue decline,” many will reach for their phones.

### What follow-up question would they ask?

Immediately:

**If the threshold didn’t allocate funds, what did?**

That is the question the paper currently cannot answer strongly enough. It waves toward banking relationships and organizational capacity, but those need to be more central if the paper is to feel complete.

A second follow-up:
**Is this because the threshold truly didn’t matter, or because your administrative proxy is mismeasured?**

The paper addresses this, but for editorial positioning purposes, this concern will remain front and center. Since the paper’s main claim is interpretive, it needs to be exceptionally sharp about what exactly is and is not being claimed.

### Is the null itself interesting?

Yes, but only conditionally. A null can be interesting when it reveals a deeper positive fact: that statutory targeting was not operational in practice for a major sector. The paper is close to making that case, but not fully there. If framed simply as “we found no effect at the threshold,” it will feel like a failed design. If framed as “the threshold was not the operative margin because policy design ignored sector-specific observability,” it becomes much more interesting.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Rewrite the introduction around one question.**  
   Right now the intro has too many moving parts: nonprofit distinctiveness, data construction, threshold test, OLS selection, literature review, program design. Strip it down.

2. **Demote the “first linked dataset” language.**  
   Mention it, but do not sell the paper on it.

3. **Move much of the OLS material later and shrink it.**  
   The OLS section currently gets a lot of space for what is effectively a cautionary appendix to the main story. The reader should not think the paper is mainly about employment effects.

4. **Elevate the policy-design mechanism.**  
   The current “reporting mismatch” subsection in institutional background is actually conceptually central. It belongs earlier and more forcefully.

5. **Pull any direct evidence on actual application/documentation practices into the main text if available.**  
   If there is any institutional detail on how lenders verified nonprofit eligibility, that should be front-loaded. This is not robustness; it is the mechanism for the main claim.

6. **Shorten generic PPP background.**  
   Most AER readers do not need a tutorial on PPP.

7. **Tighten the conclusion.**  
   The conclusion has a nice line—eligibility rules can become decorative—but it mostly restates. It would add more value if it generalized carefully: when should policymakers use annual versus quarterly measures, standardized filings versus bespoke documentation, sector-specific versus one-size-fits-all rules?

### Is the paper front-loaded with the good stuff?

Moderately, but not enough. The best idea is in the paper, but not at maximum prominence. The reader still has to traverse setup before getting to the genuinely interesting claim.

### Are important results buried?

Yes: the interpretation that this is about administrative mismatch rather than simply null treatment effects is somewhat buried across the intro, background, and discussion. That should be the spine of the paper.

### Is the conclusion adding value?

Some, but limited. It gestures toward a broader principle but does not fully capitalize on it.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

At present, the gap is mainly a combination of **framing**, **scope**, and **ambition**.

- **Framing problem:** Definitely. The paper is better than its current intro suggests.
- **Scope problem:** Yes. The nonprofit-only RD null is too narrow unless connected to a broader mechanism and comparative logic.
- **Novelty problem:** Somewhat. PPP is heavily studied, and “another paper on PPP allocation” is a hard sell unless the conceptual contribution is unmistakable.
- **Ambition problem:** Yes. The paper is competent and tidy, but still too safe. It presents a null and a placebo, then stops. A top-field paper would turn that into a larger statement about implementation, targeting, and administrative observability.

### What is the gap between current form and an AER paper?

The top 10 people in this field will ask:
1. What general lesson does this teach beyond nonprofits and PPP?
2. Can you show what margin actually governed allocation instead?
3. Is the key contribution empirical novelty, or a broader theory of policy design under mismatched administrative data?

Right now the paper only partially answers these.

### Single most impactful piece of advice

**Rebuild the paper around the general claim that policy targeting fails when eligibility criteria are not aligned with the routinely produced, verifiable data of the target sector, and use PPP nonprofits as the sharp empirical case study—not as the entire reason the paper matters.**

If the author changes only one thing, it should be that.

---

### Strategic Assessment

- **Current framing quality:** Needs rethinking
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium-Far
- **Single biggest improvement:** Reframe the paper from a nonprofit PPP null-result study into a broader paper about administrative-data mismatch and the failure of formal eligibility rules to govern allocation.