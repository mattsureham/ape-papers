# Strategic Feedback — GPT-5.4 (R2)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-23T11:26:48.908161
**Route:** OpenRouter + LaTeX
**Tokens:** 9363 in / 3667 out
**Response SHA256:** 7d64de597a4864b1

---

## 1. THE ELEVATOR PITCH

This paper asks whether banning new vacation homes changes who actually lives in tourist communities. Using the sharp 20% threshold in Switzerland’s second-home law, it argues that the ban did not meaningfully increase the share of primary residences, but did increase total housing construction, consistent with substitution into permitted housing types rather than conversion of resort towns into year-round communities.

Why should a busy economist care? Because this is not just a Swiss housing story: it speaks to a broad question about regulation—when policymakers ban one margin of activity, do they actually change economic allocation, or just relabel and redirect it?

**Does the paper itself articulate this pitch clearly in the first two paragraphs?**  
Partly, but not well enough. The opening is competent, but it undersells the general-interest question and overstates the institutional detail before telling the reader why the result matters beyond Swiss resort towns. The current intro reads like a neat quasi-experimental policy evaluation. An AER paper needs to open with the larger economic problem: category-specific regulation often aims to reshape allocation, but may instead induce substitution. Switzerland is the test case, not the whole point.

**What the first two paragraphs should say instead:**

> Governments increasingly try to reshape local housing markets by restricting specific uses—short-term rentals, investor-owned units, second homes—on the theory that limiting one type of demand will free housing for local residents. But it is not obvious that such category-specific restrictions change who occupies housing, rather than simply redirecting construction and investment into nearby permitted forms.
>
> This paper studies one of the starkest such policies: Switzerland’s constitutional ban on new second-home construction in municipalities where second homes exceed 20% of the housing stock. Exploiting the sharp regulatory cutoff, I show that the ban did not measurably increase the share of primary residences in affected municipalities. Instead, municipalities just above the threshold expanded total housing stock more than those just below, suggesting that the policy induced substitution toward permitted housing rather than converting resort communities into year-round ones.

That is the pitch. Clear question, clear answer, broad reason to care.

---

## 2. CONTRIBUTION CLARITY

**Contribution in one sentence:**  
The paper shows that a hard cap on second-home construction did not materially alter housing composition in Swiss municipalities, but appears to have redirected development toward other dwelling types, highlighting substitution as a central incidence channel of housing-use regulation.

### Is this contribution clearly differentiated from the closest 3–4 papers?
Not yet sharply enough. The paper distinguishes itself from prior work on price effects and zoning capitalization, but mostly in the language of “we study composition, they study prices.” That is a start, not a memorable differentiation. The contribution becomes interesting only if framed as: **use-specific supply restrictions may fail on their intended allocation margin because housing supply re-optimizes across categories.** That is broader and stronger than “this paper studies composition instead of prices.”

### Is the contribution framed as answering a question about the WORLD, or filling a gap in a LITERATURE?
Mostly as a literature gap. That weakens it. The paper repeatedly says this is the “first test” of the policy’s “stated compositional objective.” That is useful, but “first test” is not a top-journal contribution in itself. The stronger framing is a world question:

- Do restrictions on one housing use actually free up housing for locals?
- Can category-specific bans change community composition, or do markets substitute around them?
- What do such regulations do when the targeted margin is easy to replace with adjacent margins?

That is the frame that makes the paper feel larger than Switzerland.

### Could a smart economist explain what’s new after reading the intro?
Right now, they would probably say: “It’s an RD on the Swiss second-home ban, with a null on primary-home share and some evidence of substitution into total construction.” That is better than “another DiD paper,” but still too design-first and not concept-first.

You want them to say:  
**“It shows that targeted housing-use restrictions can fail to change occupancy composition because supply substitutes into allowed categories.”**

That is a paper. The current introduction does not quite elevate it to that level.

### What would make this contribution bigger?
A few possibilities, in descending order of importance:

1. **Reframe the outcome hierarchy.**  
   The main object should not just be “primary-home share.” The real question is whether policy changes the **allocation of housing across uses and users**. If the data permit, counts or occupancy rates are more natural than shares alone. The current main outcome is vulnerable narratively because a ratio can move little even when levels move a lot. The paper partially notices this, but too late.

2. **Make substitution the central contribution, not a side interpretation.**  
   Right now the headline result is a null, and the growth result feels like the “interesting extra.” For AER positioning, the substitution result has to be the headline. The null is then part of the mechanism: the policy fails on composition because builders substitute.

3. **Connect more directly to current policy debates beyond second homes.**  
   The paper mentions short-term rentals, but that comes off as a final paragraph add-on. It should be a core part of the framing. This is a use-restriction paper, not merely a vacation-home paper.

4. **If possible, distinguish new primary construction from relabeling/reclassification.**  
   Conceptually, not econometrically. The paper needs to persuade the reader that this is genuine substitution in supply rather than an accounting shift. Even if referees judge the evidence, the story needs that mechanism front and center.

---

## 3. LITERATURE POSITIONING

### Closest neighbors
Based on what is cited and the field, the nearest neighbors are probably:

- **Hilber (and coauthors) on the Swiss Second Home Initiative / price effects**
- **Buechler (2024) on capitalization of zoning regulations**
- **Saiz (2010)** on housing supply elasticity and constraints
- **Glaeser and Gyourko / Glaeser, Gyourko, Saks** on regulation and housing supply
- **Barron, Kung, and Proserpio (2021)** and related short-term rental papers
- Potentially also papers on **regulatory substitution / leakage** outside housing, including **Buchak et al. (2018)**

There are also literatures the paper should probably be in conversation with but currently only nods at:
- housing misallocation / occupancy constraints
- regulation with margin substitution
- place-based tourism and local resident displacement
- short-term rental regulation as a form of use-specific housing policy

### How should the paper position itself relative to those neighbors?
Mostly **build on and connect**, not attack.

- Relative to **Hilber**: “They show price capitalization; I show that price effects do not imply compositional success.”
- Relative to the **housing regulation literature**: “Most work studies prices, quantities, and incidence of regulation; I study whether use-specific restrictions achieve their intended occupancy reallocation.”
- Relative to **short-term rental regulation**: “This is an extreme test case of use-specific restriction; if a hard construction ban does not reallocate occupancy, lighter restrictions may face similar substitution problems.”
- Relative to **regulatory avoidance/leakage**: “Housing should be viewed as another domain where regulated activity flows into proximate unregulated forms.”

That is a promising interdisciplinary bridge. It should lean into it.

### Is the paper positioned too narrowly or too broadly?
Currently **too narrowly in substance, too broadly in citation**.

It is narrow because it is very tied to a specific Swiss constitutional rule and its institutional details. It is broad in an unhelpful way because it name-checks finance, environmental leakage, Airbnb, zoning, and supply elasticity without organizing those literatures into one coherent conversation.

It needs a cleaner center:  
**This is a paper about category-specific housing regulation and substitution.**

Then Swiss second homes, short-term rentals, and regulatory leakage all fit naturally.

### What literature does the paper seem unaware of?
Without doing an exhaustive bibliography audit, the paper seems under-engaged with:
- urban papers on occupancy, vacancy, and housing utilization
- work on use restrictions versus quantity restrictions in local public finance / urban economics
- papers on unintended consequences of targeted housing regulation
- possibly tourism economics and amenity-driven place demand

It also may be missing some of the newer reduced-form housing regulation papers that emphasize heterogeneity in supply responses across margins, not just aggregate supply elasticity.

### Is the paper having the right conversation?
Almost. But the best conversation is not “Swiss second homes + local RD.” It is:

**What happens when policy targets a label rather than a market equilibrium?**

That is the unexpected but powerful literature connection. This is fundamentally about the incidence of category-based regulation.

---

## 4. NARRATIVE ARC

### Setup
Policymakers worry that vacation homes hollow out tourist communities, leaving “cold beds” and displacing permanent residents. A natural policy response is to ban new second homes, with the expectation that housing will shift back toward year-round occupancy.

### Tension
That intuition may be wrong. Restricting one housing category may not convert existing stock or change who lives in a place if developers, investors, and municipalities can substitute into nearby permitted categories. So the puzzle is whether a very strict use-specific ban actually changes community composition.

### Resolution
The paper finds little evidence that municipalities above the threshold became meaningfully more primary-residence oriented, but some evidence that they built more housing overall. The implied resolution is that the policy redirected rather than reduced development.

### Implications
Housing-use restrictions may produce visible price or construction responses without achieving their core political objective of changing local occupancy patterns. Policymakers who want permanent residency may need instruments that target use or occupancy directly, not just one construction category.

### Does the paper have a clear narrative arc?
It has the bones of one, but at present it still feels a bit like **a collection of RD tables with a discussion section attached**. The paper knows what the story is, but it does not fully organize itself around that story.

The main issue is ordering. The current narrative is:
1. here is a Swiss ban,
2. here is an RD,
3. here is a null,
4. surprisingly here is a positive quantity result,
5. maybe that means substitution.

For a stronger arc, it should be:
1. category-specific housing regulation is meant to reshape occupancy,
2. theory suggests it may instead induce substitution,
3. Switzerland offers a clean test,
4. the policy fails on composition and succeeds only in redirecting construction,
5. this changes how we should think about housing-use regulation.

That is a much more coherent narrative.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with at a dinner party of economists?
“Switzerland banned new second homes in resort municipalities, and it didn’t really make those places more lived-in—it just seems to have pushed construction into other housing categories.”

That is the line.

### Would people lean in or reach for their phones?
Some would lean in—especially urban, public, and political economy economists—but not all. As currently framed, it risks sounding like a niche Swiss policy null. As reframed around substitution in targeted regulation, it becomes much more broadly interesting.

### What follow-up question would they ask?
Immediately:  
**“So did the policy actually change occupancy behavior, or just the classification and composition of new builds?”**

That is the right question, and the paper should anticipate it as the central conceptual issue.

### If the findings are null or modest, is the null itself interesting?
The null alone is only moderately interesting. “Ban didn’t move the share significantly” is not enough for AER. The paper avoids being a failed experiment only because it also has the positive quantity result and the substitution interpretation.

So the paper should stop selling this as a “well-identified null.” That is not an AER hook. The interesting result is not the null per se; it is the **combination** of null composition and positive total growth, which points to substitution. That is what makes the paper publishable somewhere good, and potentially relevant to AER if developed convincingly.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Shorten the method-defense in the introduction.**  
   The third paragraph of the intro is overloaded with McCrary tests, placebo thresholds, kernel choices, and bandwidth language. That is referee bait, not reader bait. It drains momentum. Save almost all of it for the empirical section.

2. **Move literature review later or make it tighter.**  
   The three-paragraph contribution section currently reads like a standard field-journal intro. For AER positioning, it should be compressed and subordinated to the main idea. One concise paragraph is enough in the intro; fuller placement can come after the setup.

3. **Bring the surprising result forward faster.**  
   The dwelling-growth finding is the most interesting result in the paper. It should appear in the abstract and intro as the core finding, not as a secondary “however.”

4. **Reduce institutional background.**  
   The institutional section is competent but somewhat over-detailed for the story being told. You do not need a mini legal history of the ZWG for this audience. A shorter, cleaner background would improve pacing.

5. **Promote interpretation out of the subsubsection.**  
   “Interpretation” is currently buried as a short subsection after the main table. That is the paper’s core intellectual content. It should be integrated into the main results narrative, not treated as a small add-on.

6. **Cut robustness from the main text unless it changes meaning.**  
   For editorial positioning, the paper currently feels too much like it is trying to prove competence. Robustness can be streamlined aggressively. The only robustness that belongs in the main text is whatever most clarifies the economic meaning of the findings.

7. **Rewrite the conclusion.**  
   The current conclusion is punchy but a bit glib: “changes the label on new construction, not the character of the community.” That overreaches and sounds op-ed-ish. The paper needs a conclusion that sharpens the broader lesson about targeted regulation and substitution, not a slogan.

### Is the paper front-loaded with the good stuff?
Not enough. The good stuff is there, but the reader has to wade through too much design reassurance before the broader point comes into focus.

### Are results buried in robustness that should be in the main text?
Not obviously. If anything, too much robustness is in the main text already relative to how much conceptual development there is.

### Is the conclusion adding value?
Some, but not much. It mostly summarizes. It should instead answer: what does this change about how economists should think about use-specific housing regulation?

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

Frankly, the gap is meaningful.

This does **not** currently read like an AER paper. It reads like a solid, clever urban/public economics paper with a nice institutional setting and one intriguing mechanism. The reasons are mostly about framing and ambition, not technical competence.

### What is the main gap?

- **Framing problem:** Yes, substantially.  
  The paper is still framed as a Swiss policy evaluation rather than a broader paper on substitution under category-specific regulation.

- **Scope problem:** Somewhat.  
  The paper’s main outcomes are a ratio and total dwellings. For AER, the scope likely needs to expand conceptually—if not with entirely new data, at least with a stronger treatment of what “conversion” and “substitution” mean economically.

- **Novelty problem:** Moderate.  
  The general idea that regulation induces substitution is not new. The novelty has to come from showing it in a setting where policymakers explicitly aimed to change occupancy composition and where prior work focused on prices. Right now that novelty is there, but not yet forcefully enough.

- **Ambition problem:** Yes.  
  The paper is careful, competent, and sensible—but safe. It does not yet make a bold claim about how economists should rethink a broader class of policies.

### What would excite the top 10 people in this field?
A version of this paper that says:

> Use-specific housing restrictions are often justified as tools for reallocating housing toward local residents, but they may be fundamentally ill-suited to that task because supply adjusts along untargeted margins. Switzerland’s second-home ban shows this in an unusually clean setting.

That could get attention. But to do so, the paper must stop behaving like a design memo and start behaving like a conceptual contribution.

### Single most impactful piece of advice
**Reframe the paper around substitution in category-specific housing regulation—make the positive dwelling-growth result the headline and the null on housing composition the consequence, not the main event.**

That one change would do the most to move it toward AER territory.

---

### Strategic Assessment

- **Current framing quality:** Adequate
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium
- **Single biggest improvement:** Recast the paper as a general study of substitution under targeted housing-use regulation, with Switzerland as the clean test case rather than the whole story.