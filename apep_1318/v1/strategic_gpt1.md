# Strategic Feedback — GPT-5.4 (R1)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-04-02T14:08:40.756549
**Route:** OpenRouter + LaTeX
**Tokens:** 9660 in / 3925 out
**Response SHA256:** 8290990c51236380

---

## 1. THE ELEVATOR PITCH

This paper asks a simple, policy-relevant question: when governments force companies to reveal their ultimate owners to the public, does that chill legitimate business formation? Exploiting the EU’s staggered adoption of public beneficial-ownership registers and the 2022 court-induced rollback in some countries, the paper argues the answer is no: transparency does not appear to reduce aggregate new business registrations.

A busy economist should care because this is a clean test of one of the central political-economy claims used against transparency regulation: that disclosure deters legitimate economic activity, not just illicit actors. If true, the paper speaks to a broad issue well beyond AML—whether privacy-reducing disclosure rules meaningfully trade off against real economic activity.

### Does the paper articulate this pitch clearly in the first two paragraphs?

Not quite. The current introduction is competent, but it is too legalistic and too tied to the CJEU ruling. It starts with institutional detail before making the broader economic stakes vivid. The result is that the paper sounds like a niche paper on EU AML law, rather than a paper about the economic costs of transparency.

The first two paragraphs should say something more like:

> Governments around the world increasingly require firms to disclose who ultimately owns and controls them, on the theory that ownership transparency helps combat tax evasion, corruption, and money laundering. Critics argue that such disclosure also imposes real costs on legitimate firms by discouraging incorporation, reducing investment, and deterring entrepreneurship. Despite the centrality of this claim in policy debates, there is remarkably little evidence on whether ownership transparency actually reduces business activity.
>
> This paper studies that question using a rare policy reversal in Europe. Between 2019 and 2021, EU member states opened beneficial-ownership registers to the public under AMLD5; after a 2022 CJEU ruling, some countries shut public access back down while others did not. Using this adoption-and-reversal design, I show that public ownership transparency did not reduce aggregate business formation. The main implication is straightforward: a key empirical justification for limiting beneficial-ownership transparency—the claim that it burdens legitimate business—finds little support in the data.

That framing leads with the world question, not the court case.

---

## 2. CONTRIBUTION CLARITY

### Contribution in one sentence

The paper provides evidence from the EU that making beneficial-ownership information publicly accessible does not reduce aggregate business formation, challenging the common policy claim that ownership transparency imposes meaningful costs on legitimate firms.

### Is this contribution clearly differentiated from the closest 3–4 papers?

Only partially. The paper does state that there is little causal evidence on beneficial ownership transparency and business formation, which is useful. But right now the differentiation is not sharp enough. The introduction cites shell-company and tax-evasion papers, plus generic disclosure papers, but it does not clearly map where this paper sits relative to the closest empirical literatures:
1. beneficial ownership / shell company / AML enforcement,
2. disclosure and transparency regulation,
3. business entry regulation.

At present, a reader could still come away with: “this is another reduced-form policy paper on disclosure.” The novelty is there, but the paper undersells what is distinctive: **it is not just another disclosure paper—it studies disclosure of owner identity rather than firm performance, and it uses a rare adoption-plus-reversal setting.**

### Is the contribution framed as answering a question about the WORLD, or filling a gap in a LITERATURE?

Too much as a literature gap, not enough as a world question. “First causal evidence” and “fills a gap” are fine, but AER introductions need to answer a question about how the world works. The stronger framing is:

- Do firms avoid transparency when transparency reveals who is behind them?
- Is there a real efficiency cost to anti-anonymity regulation?
- Are policymakers facing a genuine tradeoff between illicit finance control and legitimate business formation?

That is a world question. The literature-gap framing should be secondary.

### Could a smart economist who reads the introduction explain to a colleague what’s new?

Not quite cleanly. Right now they might say: “It’s a DiD on beneficial ownership transparency and registrations in Europe, and it finds a null.” That is not enough.

What they should be able to say is: “This paper tests whether public identification of company owners deters legitimate firm creation. Using both the opening and the court-forced closing of ownership registers across Europe, it finds no detectable effect on aggregate entry—so one of the main objections to ownership transparency doesn’t seem empirically important.”

That version is memorable. The current version is not far off, but it needs sharpening.

### What would make this contribution bigger?

Most importantly: **better align the outcome with the underlying conceptual claim.** The paper wants to say transparency does not burden legitimate firms, but the outcome is aggregate registrations. That is broad, blunt, and almost certainly dilutes the effect. To make the contribution bigger, the paper should lean harder into one of two directions:

1. **Composition rather than quantity.**  
   The discussion already admits the key issue: transparency may not affect total entry but may affect the type of entities formed. If the paper could show that opacity-sensitive forms of incorporation are unchanged—or selectively decline—that would be much bigger and more substantively informative.

2. **A mechanism tied to anonymity-seeking entities.**  
   If the paper could examine sectors, legal forms, cross-border incorporations, holding companies, business services, or foreign-owned entities, the result would become about the economic incidence of transparency rather than just “no movement in a broad index.”

3. **Reframe away from “business formation” per se and toward the policy tradeoff.**  
   The bigger claim is not “registrations don’t move.” It is “the purported efficiency cost of anti-anonymity regulation is smaller than critics claim.” That can be an important paper if argued well.

As written, the contribution is real but modest. The aggregate outcome makes the result feel smaller than the question.

---

## 3. LITERATURE POSITIONING

### Closest neighbors

The closest neighbors seem to be drawn from a few overlapping literatures:

1. **Findley, Nielson, and Sharman (2015),** on the ease of forming anonymous shell companies globally.  
2. **Alstadsæter, Johannesen, and Zucman (2019)** and related offshore/tax-evasion work.  
3. **Christensen, Hail, and Leuz (2017)** on mandatory disclosure and capital-market effects.  
4. **Djankov et al. (2002),** on entry regulation and business formation.  
5. Possibly **Bennedsen et al.**-type work on disclosure, governance, and ownership transparency, depending on the exact paper intended.

The paper also cites the staggered-DiD econometrics literature, but that is not really its intellectual neighborhood; it is a tool, not the conversation.

### How should the paper position itself relative to those neighbors?

Mostly **build on and bridge** them, not attack them.

- Relative to the shell-company / illicit-finance literature: “That literature shows why beneficial ownership matters for enforcement; I ask whether transparency carries the claimed economic cost.”
- Relative to disclosure papers: “Most disclosure papers study firm performance or financial information; I study owner identity disclosure, where the privacy-efficiency tradeoff is different.”
- Relative to entry regulation: “Unlike classic entry barriers, this regulation changes anonymity, not the cost of incorporation itself.”

That three-way bridge is potentially interesting. Right now the paper gestures at all three but does not integrate them into one coherent intellectual conversation.

### Is the paper currently positioned too narrowly or too broadly?

Somehow both.

- **Too narrowly** because it is heavily organized around AMLD5 and the CJEU ruling, which gives it a public-law seminar feel.
- **Too broadly** because it makes generic claims about “transparency and disclosure” without showing why economists in that literature should see owner-identity disclosure as a first-order new setting.

The right level is: **a paper on the economic costs of anti-anonymity regulation, using Europe as a powerful setting.**

### What literature does the paper seem unaware of, or under-engaged with?

A few things are underdeveloped:

- **Firm entry and organizational form.** If the concern is incorporation deterrence, the paper should engage more with the entrepreneurship/entry literature, not just disclosure papers.
- **Crime/corruption enforcement and regulatory avoidance.** There is a broader literature on how illicit actors substitute across organizational forms and jurisdictions. Even if the paper cannot test substitution, it should acknowledge that this is the real margin.
- **Political economy of transparency/privacy.** The paper is very legal-institutional, but not very political-economy. Why do firms lobby against transparency? What margins are plausibly affected?
- **Tax haven / secrecy jurisdiction literature.** This seems like an obvious conversation partner, especially because the paper’s deeper question is whether secrecy has economic value for legitimate actors or mainly for dubious ones.

### Is the paper having the right conversation?

Not yet. The current conversation is “Does the CJEU’s proportionality logic hold in the registration data?” That is too lawyerly and too tied to one case.

The more impactful conversation is: **How costly is it to remove corporate anonymity?** That connects AML, tax evasion, entry regulation, disclosure, and political economy. That is the right conversation for AER readers.

---

## 4. NARRATIVE ARC

### Setup

Governments increasingly use beneficial-ownership transparency to combat illicit finance, but opponents argue that exposing owners publicly harms legitimate business activity.

### Tension

This claimed cost is central to policy debates and court reasoning, yet there is almost no direct evidence on whether public ownership disclosure actually deters firm creation.

### Resolution

Using the staggered opening and partial closing of public registers across Europe, the paper finds no evidence that public access reduced aggregate business registrations.

### Implications

The supposed tradeoff between ownership transparency and legitimate business formation may be much weaker than critics claim; policymakers may be giving up transparency benefits without avoiding meaningful economic costs.

### Does the paper have a clear narrative arc?

Serviceable, but not strong. The ingredients are all there, but the paper currently reads more like:
1. institutional background,
2. estimation,
3. null result,
4. a placebo to interpret the reversal.

That is closer to a collection of results than a compelling story.

### What story should it be telling?

The story should be:

- **Corporate anonymity is valuable to some actors.**
- **The policy question is whether that value extends to ordinary legitimate entrepreneurs.**
- **Europe inadvertently ran a rare experiment by both introducing and then partly reversing public ownership transparency.**
- **The data say aggregate legitimate business formation did not fall when anonymity was removed.**
- **Therefore, the main economic objection to transparency appears overstated, even if the paper cannot yet say which firms were most affected.**

That story is stronger because it turns the paper into a test of the value of secrecy rather than an event study of AMLD5 implementation.

One more point: the paper’s most intellectually honest sentence may be in the discussion—aggregate quantity may not move even if composition does. That is not a weakness to hide; it is the core interpretive tension. The paper should surface it earlier and organize the narrative around it.

---

## 5. THE "SO WHAT?" TEST

### What fact would I lead with?

“I looked at the opening and court-forced closing of public beneficial-ownership registers across Europe, and there is no evidence that making company owners public reduced business formation.”

That is the fact.

### Would people lean in or reach for their phones?

Among economists interested in public finance, development, law and economics, regulation, or political economy, they would lean in—briefly. The topic is genuinely important. But they will lean in only if the speaker immediately clarifies why this is not just a niche EU legal episode.

If presented as “a paper on AMLD5 and the CJEU,” phones come out.  
If presented as “a paper on whether corporate secrecy has real economic value for legitimate firms,” people pay attention.

### What follow-up question would they ask?

Almost certainly: **“Maybe aggregate entry doesn’t move, but what about the kinds of firms that rely on secrecy?”**

That is the right follow-up, and the paper should anticipate it more centrally. Right now that issue appears late in the discussion, when in fact it is the main conceptual response any serious reader will have.

### If the findings are null or modest, is the null itself interesting?

Yes, potentially very much so—but only if framed correctly. Nulls are interesting when they knock down a widely asserted tradeoff. This paper can do that. But then it must show that:
1. the “transparency deters legitimate business” claim is genuinely central in policy debates, and
2. aggregate entry is a meaningful enough margin that a null is informative.

At present, the paper does (1) decently and (2) only partially. Without more work, some readers will say: “Of course a broad registration index won’t pick up shell-company avoidance.” That reaction needs to be met head-on, early, and with confidence.

So the null is interesting, but it is walking a narrow line between “important falsification of a policy claim” and “failed attempt to detect an effect on too-aggregated an outcome.”

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Shorten the legal/institutional opening.**  
   The introduction spends too much time on the CJEU ruling before getting to the economic question. Compress the legal details and move some of them to the institutional section.

2. **Lead with the broad claim, then the design, then the result.**  
   The first page should give the reader the question, the quasi-experiment, and the headline finding immediately.

3. **Move econometric throat-clearing out of the introduction.**  
   The introduction is too detailed on specification mechanics. AER readers do not need “country and quarter fixed effects, clustering by country” before they know why they care.

4. **Surface the composition-vs-quantity issue much earlier.**  
   This is the key interpretive issue and currently appears too late. Put it in the introduction as a scope condition.

5. **Trim some of the methodological self-consciousness.**  
   The discussion of permutation inference, event-study caveats, and staggered-DiD estimators is over-salient for a paper whose bottleneck is framing, not econometric branding.

6. **Use the placebo more strategically.**  
   The manufacturing placebo is probably the most important interpretive result for the reversal analysis. It should be previewed early and perhaps elevated more in the main text, because it rescues the reversal from being confusing.

7. **Cut or rethink the “methodological contribution” paragraph.**  
   Claiming a methodological contribution because the setting features a reversal feels overstated. That paragraph weakens the paper by making it sound like it is reaching for extra novelty. Better to say the setting is unusually informative.

8. **The conclusion should do more than summarize.**  
   Right now it mostly restates results and caveats. It should instead crystallize the policy tradeoff: what exactly should economists update about the cost of anti-anonymity regulation?

### Is the paper front-loaded with the good stuff?

Not enough. The best part of the paper is the simple, punchy question and the politically salient null. That should be front and center. Right now the reader has to wade through institutional detail to get the broader point.

### Are there results buried in robustness that should be in the main results?

Conceptually, the event-study pre-trend issue matters for interpretation, but strategically it should not dominate the paper. The main buried point is not a robustness result, but the composition-vs-quantity issue currently buried in the discussion. That belongs in the introduction.

### Is the conclusion adding value?

Some, but not enough. It is thoughtful but too cautious and too inward-looking. It needs a stronger “what should we now believe?” paragraph.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

In its current form, this is **not yet an AER paper**. The main gap is not that the paper is incompetent; it is that the paper’s ambition is smaller than the stakes of its own question.

### What is the main gap?

Primarily a **framing problem**, secondarily a **scope problem**.

- **Framing problem:** The paper is written like an evaluation of an EU court ruling, not like a paper on the economics of corporate anonymity.
- **Scope problem:** The outcome is too aggregated to fully answer the most interesting version of the question.
- **Novelty problem:** The setting is novel, but the empirical contribution will still feel limited unless the paper better explains why aggregate nulls are informative.
- **Ambition problem:** The paper is careful and sensible, but currently too safe. It settles for “no effect on registrations” when the bigger claim is about the economic value of secrecy.

### What would excite the top 10 people in this field?

A paper that uses this setting to say something sharper like:

- public ownership transparency does not reduce legitimate entry,
- but it does change the composition of entry toward less opacity-seeking entities; or
- the private value of corporate secrecy is concentrated among a narrow set of firms rather than ordinary entrepreneurs; or
- the supposed efficiency cost of anti-anonymity regulation is small relative to the policy debate around it.

Right now the paper is one step short of that. It has the setting and the policy relevance, but not the fully developed punchline.

### Single most impactful piece of advice

**Reframe the paper as a test of the economic value of corporate anonymity—not as a comment on a CJEU ruling—and organize the entire introduction around the core interpretive question of whether transparency affects the composition, rather than the quantity, of firm entry.**

That one change would improve the paper even without new data. If the authors can add more composition-sensitive outcomes, so much the better. But even absent that, the paper needs to own the bigger question.

---

### Strategic Assessment

- **Current framing quality:** Needs rethinking
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium
- **Single biggest improvement:** Recast the paper as evidence on the economic value of corporate secrecy, not as an EU legal episode, and foreground the composition-versus-quantity issue from page 1.