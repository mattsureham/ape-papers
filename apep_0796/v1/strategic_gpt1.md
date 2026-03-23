# Strategic Feedback — GPT-5.4 (R1)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-23T11:26:48.894236
**Route:** OpenRouter + LaTeX
**Tokens:** 9363 in / 3040 out
**Response SHA256:** e99fe8ed493d5ecb

---

## 1. THE ELEVATOR PITCH

This paper studies a Swiss constitutional rule that bans new second homes in municipalities where second homes exceed 20 percent of the housing stock. The question is whether banning vacation-home construction actually changes who lives in tourist towns, or whether development simply shifts into other legal housing categories; that matters because many housing regulations are sold as ways to change community composition, not just prices.

The paper does articulate a version of this pitch early, but not as sharply as it should. Right now the introduction leads with “did it work?” and then quickly becomes an empirical-design tour. For AER positioning, the first two paragraphs should make clearer that the core issue is a general one: when regulators ban one use of housing, do they actually reallocate housing toward residents, or just relabel and redirect supply?

### The pitch the paper should have

“Governments increasingly restrict vacation homes and short-term rental uses in the hope of turning high-amenity places back into communities for permanent residents. But whether such rules change the composition of housing—or simply redirect construction into permitted categories—is largely unknown. This paper studies Switzerland’s nationwide second-home ban, which creates a sharp 20 percent threshold, and shows that the policy did not meaningfully convert resort towns into year-round communities near the cutoff; instead, construction shifted toward other dwellings, revealing an important substitution margin in housing regulation.”

That is a world question. It is bigger than “here is an RDD on a Swiss law.”

---

## 2. CONTRIBUTION CLARITY

**One-sentence contribution:**  
The paper’s contribution is to show that a hard supply restriction on vacation homes did not materially change local housing composition near the regulatory threshold, but instead appears to have redirected construction toward permitted housing types.

That contribution is reasonably clear, but not yet clearly differentiated from the nearest literature. The paper is trying to distinguish itself from work on price effects of housing regulation and from short-term-rental regulation, but the distinction still feels a bit mechanical: “they study prices, I study composition.” That is not enough on its own for AER unless the paper makes composition itself feel like the central economic object.

A few specifics:

- **Differentiation from neighbors:** Partial. The paper distinguishes itself from Hilber-type price-capitalization work, but it does not yet tell me why this is a first-order conceptual advance rather than a new outcome variable.
- **World question vs literature gap:** It mostly frames as a world question, which is good. But there are stretches where it slips into “fills a gap because prior papers study prices.” The stronger frame is: many place-based housing restrictions are justified by claims about occupancy and local community composition; this paper tests whether those claims are true.
- **Would a smart economist know what’s new?** Some would; others would summarize it as “another threshold design on a local housing regulation.” That is the danger. The novelty is not the design. It is the idea that the relevant margin is **compositional substitution** across housing categories.
- **What would make the contribution bigger?**
  1. **Better outcome framing:** Move from “primary-home share” to a more direct concept of occupancy, use intensity, or resident population if possible. The current main outcome is a ratio that naturally muddies interpretation because the denominator moves.
  2. **Mechanism:** Show more directly that the extra housing growth above the cutoff is in categories plausibly intended for primary use, not just infer this from accounting.
  3. **General comparison:** Connect explicitly to other regulations that target “who lives there” via restrictions on one housing use—second homes, STRs, pied-à-terres, foreign-buyer restrictions.
  4. **Stronger framing of substitution:** The big idea is not “ban didn’t work.” It is “category-specific housing restrictions can expand supply in adjacent categories without delivering the intended reallocation.”

Right now the contribution is decent, but still narrower than it needs to be.

---

## 3. LITERATURE POSITIONING

Closest neighbors, as best I can tell, are something like:

1. **Hilber and Schöni / Hilber et al. on the Swiss Second Home Initiative** and related price effects/capitalization.
2. **Büechler (2024)** on capitalization of zoning or local housing regulations in Switzerland.
3. **Barron, Kung, and Proserpio (2021)** on Airbnb and housing markets.
4. **Garcia-López et al.** on short-term rental restrictions and local housing outcomes.
5. More conceptually, **Saiz (2010)** and **Gyourko/Glaeser** on supply constraints, though these are not the closest empirical neighbors.

How should the paper position itself? Mostly **build on** the Swiss-policy papers and **bridge** them to the short-term-rental/regulatory-substitution literature. It should not “attack” the price papers; the right move is to say they answered a different question. The paper is strongest if it says: “price effects are not enough, because these policies are politically sold on compositional grounds.”

Current positioning is somewhat too broad in one sense and too narrow in another.

- **Too broad:** The fintech/shadow-bank analogy is rhetorically clever but a little strained. It feels imported to create generality.
- **Too narrow:** The paper should speak more directly to the rapidly growing literature on regulations intended to alter occupancy and neighborhood composition: Airbnb restrictions, vacant-home taxes, second-home taxes, foreign ownership restrictions, and local anti-touristification policies.

What literature does it seem somewhat unaware of?

- The paper needs more contact with the literature on **housing use regulation** and **occupancy/vacancy policy**, not just housing supply and prices.
- It should also speak more to the **political economy of local housing regulation**: these policies are often enacted because voters care about community character, not only affordability.
- If possible, connect to literature on **misclassification, regulatory avoidance, and margin shifting** in urban economics and public economics. “Substitution” is the key idea, but right now the paper invokes it more than it situates it.

Is it having the right conversation? Not quite yet. The most impactful conversation is not “RDD evidence from Switzerland” and not even “housing supply restrictions affect prices.” It is:

> Can governments engineer resident composition by banning one type of housing demand, or do markets simply reroute around the ban?

That is a more interesting conversation.

---

## 4. NARRATIVE ARC

### Setup
High-amenity tourist communities often worry that vacation homes hollow out local life, and policymakers increasingly restrict such uses to restore year-round residency.

### Tension
These policies are justified as changing housing composition, but we actually do not know whether they convert communities into more resident-heavy places or merely alter the form of new development.

### Resolution
Near Switzerland’s regulatory threshold, the ban does not deliver a clear increase in primary-home share, but municipalities above the cutoff see more dwelling-stock growth, consistent with substitution toward permitted housing categories.

### Implications
Supply restrictions aimed at one housing use may fail at their stated compositional goal unless they also target underlying occupancy incentives or demand. Policymakers should not infer social success from price effects alone.

There is a narrative arc here, but it is not fully under control. Parts of the paper read like a coherent story; other parts read like a set of RDD outputs with interpretation layered on afterward.

The biggest storytelling problem is that the paper wants the headline to be “the ban fails,” but the actual findings are more nuanced and somewhat less decisive: a null on composition, a positive on dwelling growth, and a suggested substitution mechanism. That is still an interesting story—but it is **not** the same as a conclusive debunking of the policy.

So the story should be:

- Not: “We test whether the initiative worked, and it didn’t.”
- But: “We test the mechanism policymakers cared about—conversion to resident use—and find little evidence of that margin, while finding evidence that regulation pushed activity into adjacent permitted categories.”

That is subtler and more believable.

A second narrative issue: the dynamic section somewhat muddies the story. It introduces time variation that appears stronger than the pooled headline estimate, then partly undoes it. For strategic positioning, the paper should avoid looking like it is shopping for a more exciting result than its main design delivers.

---

## 5. THE “SO WHAT?” TEST

At a dinner party of economists, the fact I would lead with is:

**“Switzerland banned new second homes in resort municipalities, but near the cutoff it didn’t clearly turn them into places with more permanent residents; instead, construction seems to have shifted into allowed housing types.”**

That would get some people to lean in, especially urban, public, and political-economy economists. The setting is vivid and the policy is real. But they will lean in only if the paper sells this as a general lesson about regulation-induced substitution, not as a narrow institutional curiosity.

The immediate follow-up question would be:

**“Fine—but what exactly changed? Did permanent occupancy rise in levels, did resident population rise, or did developers just game the classification?”**

That question matters because the paper’s current main outcome is a share, and the interpretation of the growth result as “primary-home construction” is still somewhat inferential. Again, referees can judge identification details, but strategically the paper must anticipate that readers will want a more direct mechanism.

Is the null itself interesting? Potentially yes. AER can publish an important null when it overturns a common policy presumption. Here, learning that a highly salient constitutional ban did not deliver the promised compositional transformation could matter. But the paper needs to make the null feel like a substantive revelation, not a failed attempt to find an effect. The current draft comes close, but sometimes overstates the strength of what the null establishes.

---

## 6. STRUCTURAL SUGGESTIONS

1. **Shorten the design-validation material in the introduction.**  
   The intro spends too much scarce real estate on McCrary, placebo thresholds, kernel choice, and bandwidths. Those are not the selling point. In a top-journal narrative, the intro should be question → answer → why surprising → why important.

2. **Bring the conceptual contribution forward.**  
   The idea of compositional versus price effects should appear in paragraph 1 or 2, not after the headline estimates.

3. **Trim the robustness parade in the main text.**  
   Much of the bandwidth sensitivity, kernel variation, and donut discussion can be compressed or moved. AER readers do not need a full audit trail before they understand why they should care.

4. **Be careful with the dynamic section.**  
   Right now it distracts from the cleaner main message and risks looking opportunistic. Unless the time pattern is central to the paper’s economic point, this section may be better shortened, moved later, or partly appended.

5. **Promote the total-dwelling-growth result earlier.**  
   This is the paper’s most intriguing result because it gives the null on composition economic content. It should appear immediately after the headline null, and probably in the abstract even more prominently than it already does.

6. **The conclusion should do more than summarize.**  
   Right now it lands on a neat slogan, but it should finish with a broader lesson about the limits of regulating housing categories when the policy target is occupancy or local community structure.

7. **Drop some defensive prose.**  
   Phrases like “well-identified null,” long discussions of p-values, and repeated design reassurances are not helping the strategic case. They make the paper sound anxious.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

At present, the paper is not mainly suffering from a technical-presentation problem. It is suffering from a mix of **framing** and **ambition** problems.

- **Framing problem:** Yes. The paper’s biggest asset is the general lesson about substitution across housing categories, but it still presents itself too much as an evaluation of one Swiss initiative.
- **Scope problem:** Also yes. The paper needs either a more direct occupancy/residency outcome or stronger evidence on the substitution mechanism to elevate the contribution.
- **Novelty problem:** Moderate. The setting is nice, but “local housing regulation near a threshold” is not enough novelty by itself. The conceptual novelty must carry the piece.
- **Ambition problem:** Yes. The paper is competent, but the current version feels like it is content to show one null and one positive reduced-form result. AER would want either a stronger conceptual payoff or a richer demonstration of the mechanism.

The gap between current form and an AER paper is that the paper does not yet make the top people in housing/public/urban economics revise a broad belief. To do that, it needs to say—and show—something like:

> “Policies that target housing composition through use-specific supply restrictions are systematically vulnerable to substitution, so observed price effects are a poor guide to whether these policies achieve their stated social objective.”

That is an AER-scale claim if supported.

### Single most impactful advice

**Reframe the paper around substitution and occupancy, not around a null test of a Swiss ban: make the central question whether use-specific housing restrictions can change who lives in a place, and marshal the evidence around that broader claim.**

---

### Strategic Assessment

- **Current framing quality:** Adequate
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium-Far
- **Single biggest improvement:** Rebuild the introduction and results around the general economic question of regulatory substitution in housing use, rather than around a narrow “did the Swiss ban work?” framing.