# Strategic Feedback — GPT-5.4 (R1)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-13T17:45:21.398149
**Route:** OpenRouter + LaTeX
**Tokens:** 8881 in / 4038 out
**Response SHA256:** 2f1f10de1b5a2f5b

---

This paper is trying to answer an important and policy-relevant question, and it has a potentially AER-worthy ingredient: unusually broad administrative data on a politically central topic. But in its current form, the paper is still more “competent empirical note” than “field-defining article.” The main issue is not the design per se; it is that the paper has not yet decided whether it is about immigration enforcement, formal-sector measurement, ethnic incidence, or the boundaries of the underground economy. Right now it gestures at all four and fully lands on none.

## 1. THE ELEVATOR PITCH

This paper asks whether state mandates requiring employers to use E-Verify reduce formal employment among Hispanic workers. Using Census administrative employment records rather than household survey data, it finds suggestive evidence that mandatory verification lowers Hispanic formal employment by about 6 percent, with larger declines in industries that rely heavily on immigrant labor and little effect on non-Hispanic workers.

A busy economist should care because this is not just a paper about one immigration policy: it is about whether administrative screening technologies can meaningfully reallocate workers out of the formal labor market, and whether those effects show up where theory says they should.

### Does the paper itself articulate this pitch clearly in the first two paragraphs?

Not quite. The current opening is decent, but it undersells the broader economic question and oversells precision too early. It starts with unauthorized immigrants and employer discretion, which is fine, but then quickly narrows into “what happens next?” before clearly establishing why this is a general economics question rather than a niche immigration-policy exercise. The second paragraph is too focused on the number of Hispanic workers in mandate states and not enough on the core conceptual issue: do verification mandates change who can access formal labor markets?

Also, the introduction waits too long to say what is genuinely novel: not just “I use QWI,” but “for the first time we can measure formal-sector displacement using near-universe payroll data, rather than inferring it from surveys that undersample the population of interest.”

### The pitch the paper should have

Here is the pitch the paper should have in the first two paragraphs:

> Governments increasingly use digital verification systems to police eligibility for work, benefits, and public services. A central economic question is whether these systems actually exclude targeted workers from formal markets, or whether firms and workers simply adapt in ways that blunt enforcement. State E-Verify mandates provide a natural setting to study this question because they make work-authorization screening compulsory at hiring.
>
> This paper studies whether mandatory E-Verify reduces formal employment among Hispanic workers, the group most exposed to unauthorized-status screening, and whether any effects are concentrated in sectors where unauthorized labor is most prevalent. Using Census administrative payroll data covering nearly the universe of formal private-sector employment, I find suggestive evidence that mandates reduce Hispanic formal employment by about 6 percent, with larger effects in high-immigrant industries and no corresponding effect for non-Hispanic workers. The broader implication is that verification mandates may operate less by raising wages for substitute workers than by pushing vulnerable workers out of the formal sector.

That is a sharper AER-style pitch: broad question, setting, data advance, main fact, implication.

## 2. CONTRIBUTION CLARITY

### Contribution in one sentence

The paper’s contribution is to provide the first multi-state administrative-data evidence that mandatory E-Verify appears to reduce formal Hispanic employment, especially in immigrant-intensive industries, suggesting that verification mandates displace workers from the formal sector rather than simply reshuffling employment within it.

### Is this contribution clearly differentiated from the closest papers?

Only partially. The paper does say prior work uses CPS and that this paper uses QWI, but the differentiation is still too data-centric and too incremental in tone. “First study to exploit these data for E-Verify” is not, by itself, an AER contribution. The contribution has to be: the administrative data let us observe formal-sector employment and worker flows more directly and at scale, which changes the substantive conclusion we can draw about enforcement.

Right now, the paper risks sounding like: “same question as earlier papers, better data, similar answer.” That is not enough unless the better data materially sharpen the conceptual claim.

### Is the contribution framed as answering a question about the world, or filling a gap in a literature?

It is mixed, but too often framed as filling a gap in a literature. Phrases like “no study has used administrative employer-reported data” and “I fill this gap” are useful supporting points, but they should not be the centerpiece. The stronger framing is about the world:

- Do verification mandates actually reduce formal employment for exposed workers?
- Are their effects concentrated where unauthorized labor is likely to matter?
- Do these policies contract the formal labor market rather than producing standard wage gains for competing workers?

Those are world questions. The paper should lean harder into them.

### Could a smart economist explain what’s new after reading the intro?

At present, they would probably say: “It’s a staggered DiD on E-Verify using QWI instead of CPS, and it finds a negative effect on Hispanic employment.” That is not yet distinctive enough.

You want them to say: “It shows that mandatory work-authorization screening appears to push Hispanic workers out of payroll employment in exactly the sectors where unauthorized labor is concentrated, with little sign of offsetting gains for others. So the policy may shrink the formal labor market rather than simply improving matching or raising wages.”

That is a memorable claim.

### What would make the contribution bigger?

Several possibilities:

1. **Lean into formalization/informality more explicitly.**  
   The paper’s most interesting latent question is not “does Hispanic employment fall?” but “does enforcement reallocate workers from the formal to the informal sector?” The paper cannot fully observe informal work, but it can frame the measured outcome explicitly as formal-sector employment and organize the discussion around formal-sector displacement.

2. **Make worker flows central, not peripheral.**  
   The hiring/separation distinction is potentially one of the most valuable contributions, because it speaks to mechanism. Right now it appears late and reads as an auxiliary result. If the story is “verification binds at hiring,” then that flow result belongs near the front.

3. **Use the non-Hispanic result less as a placebo and more as incidence.**  
   “No effect on non-Hispanics” can be framed as evidence about who bears the burden and whether there is replacement/substitution. That broadens the paper from immigration enforcement to labor-market incidence.

4. **Clarify the economic stake beyond Hispanic workers.**  
   The paper hints at tax revenue, production adjustment, and market power, but these are underdeveloped. Even without adding new empirical sections, the framing could connect the findings to labor supply shocks, production responses, and policy incidence in regulated labor markets.

The biggest way to make the contribution feel larger would be to center the paper on a general proposition: **digital eligibility enforcement changes access to formal labor markets, and the main margin is reduced entry into formal jobs.**

## 3. LITERATURE POSITIONING

### Closest neighbors

The most obvious neighbors are:

- **Bohn, Lofstrom, and Raphael (2014)** on Arizona’s Legal Arizona Workers Act.
- **Orrenius and Zavodny (2016)** or similar multi-state CPS-based E-Verify work.
- **Amuedo-Dorantes and Bansak (2012)** on E-Verify / interior enforcement effects.
- The broader **interior immigration enforcement** literature, including work on 287(g), Secure Communities, and related policies.
- A second ring of neighbors includes labor-market regulation papers like **Doleac and Hansen (2020)** on ban-the-box, though that analogy is suggestive rather than central.

### How should the paper position itself relative to them?

Mostly **build on and sharpen**, not attack. The right posture is:

- prior work established that E-Verify may reduce employment for likely unauthorized workers;
- this paper can measure the formal-sector margin more directly and at much larger scale;
- the administrative data also let the author examine whether the impact appears at hiring and whether it is concentrated in sectors with greater likely exposure.

That is a strong “next step” contribution.

The paper should avoid overstating that everything before was inadequate. Survey-based work was not wrong; it was limited in its ability to observe formal payroll employment among a hard-to-measure population. That is the cleaner comparative advantage.

### Is the paper positioned too narrowly or too broadly?

Right now, oddly, it is both.

- **Too narrowly** in that it often reads like a specialized immigration-policy evaluation.
- **Too broadly** in that it throws in workplace regulation, QWI as a platform, tax revenue, underground economy, bargaining power, and labor-market restructuring without making one of these the central conversation.

It needs one main conversation and one secondary one.

My recommendation:

- **Primary conversation:** immigration enforcement and labor-market incidence of work authorization screening.
- **Secondary conversation:** administrative enforcement technologies as determinants of formal labor-market access.

That is broad enough for AER readers, but not diffuse.

### What literature does the paper seem unaware of?

It should likely speak more to:

1. **Formal vs. informal labor markets.**  
   The paper repeatedly says displacement may go to informal work, but it does not position itself relative to the literature on informality, labor market segmentation, and enforcement.

2. **Administrative burden / screening / exclusion.**  
   There is a broader economics and public administration conversation about how verification and compliance technologies alter take-up and access. This paper sits naturally beside those themes.

3. **Labor supply shocks and production adjustment.**  
   If non-Hispanic employment does not rise, that is informative about substitution elasticities and adjustment margins. The paper should connect to labor demand and production response literatures.

4. **Immigration enforcement beyond labor markets.**  
   There is a large body of work on how interior enforcement affects mobility, household behavior, and local economies. Even if this paper remains labor-focused, it should acknowledge that wider landscape.

### Is the paper having the right conversation?

Not fully. The most impactful conversation is probably **not** “here is another estimate of E-Verify.” It is: **what happens when the state digitizes eligibility checks for work, and what margin does that move?** E-Verify is the application; formal-sector exclusion is the concept.

That reframing would give the paper a broader audience.

## 4. NARRATIVE ARC

### Setup

Before this paper, economists know that state and federal immigration enforcement may affect unauthorized workers’ employment, but the evidence has relied heavily on household surveys and on case studies like Arizona. We know less about whether mandatory verification visibly reduces formal payroll employment at scale and where in the labor market those effects appear.

### Tension

There is a real puzzle: if work authorization checks become mandatory, do unauthorized workers disappear from formal jobs, shift into other sectors or states, get replaced by other workers, or leave little trace because employers and workers adapt? Existing data are poorly suited to measuring formal-sector displacement directly.

### Resolution

Using QWI administrative payroll data, the paper finds suggestive evidence that mandatory E-Verify reduces Hispanic formal employment by about 6 percent, with stronger declines in high-immigrant industries, no corresponding effect for non-Hispanics, and patterns consistent with reduced hiring rather than increased separation.

### Implications

The implication is that verification mandates may be an effective tool for reducing access to formal employment among targeted workers, but they do not obviously produce offsetting gains for other workers. More broadly, the paper suggests that digital screening technologies can contract formal labor-market participation rather than simply reallocate jobs within it.

### Does the paper have a clear narrative arc?

It has the ingredients, but the arc is only partially developed. The introduction is basically a list of findings plus literature review. The paper does not yet fully organize itself around one central tension. Instead it reads like:

- policy background,
- data upgrade,
- main estimate,
- heterogeneity,
- placebo,
- mechanism,
- welfare arithmetic.

That is serviceable, but not elegant.

### What story should it be telling?

The story should be:

1. **States turn work authorization from a discretionary process into a mandatory digital screen.**
2. **The key economic question is whether this screen actually shuts exposed workers out of formal employment.**
3. **Administrative payroll data finally let us observe that formal-sector margin directly.**
4. **The main effect is not a broad labor-market shock; it is a targeted contraction in formal employment in sectors where unauthorized labor matters most, operating mainly through hiring.**
5. **This changes how we think about enforcement: less as generic deterrence, more as formal-sector exclusion.**

That is a coherent narrative. Right now, the paper contains that story but does not foreground it consistently.

## 5. THE “SO WHAT?” TEST

### What fact would I lead with?

I would lead with: **When states make E-Verify mandatory, Hispanic payroll employment appears to fall by about 6 percent, and by about 10 percent in immigrant-intensive industries, with no comparable change for non-Hispanic workers.**

That is the memorable fact.

### Would people lean in or reach for their phones?

They would lean in initially, because the topic is politically salient and economically important. But the next question would come very quickly: **is this really about unauthorized workers and formal-sector displacement, or just about Hispanic employment in states that passed conservative legislation?** Since I am not writing a referee report, I won’t litigate design; strategically, the issue is that the paper must answer that conceptual concern in framing, not just in tables.

### What follow-up question would they ask?

Probably one of these:

- “So are these workers leaving the state, moving into informality, or just not getting hired?”
- “Why don’t non-Hispanics gain if Hispanic employment falls?”
- “Is the contribution really bigger than what we already learned from Arizona and CPS papers?”

The strongest of these is the first. That tells you where the paper’s strategic opportunity is: the formal-vs-informal margin.

### If findings are modest or null-ish, is the paper making the case well?

The paper is in a delicate position because its headline estimate is economically large but inferentially cautious. It handles this honestly, which is good. But strategically, this means the paper **cannot** sell itself as “we nail down the average treatment effect with precision.” It has to sell itself as:

- providing the best available direct measurement of formal-sector displacement,
- showing a pattern of incidence and heterogeneity consistent with the screening mechanism,
- and advancing the conversation even if point identification remains imperfect.

That is a respectable AER strategy. But then the paper should stop overplaying certainty in some paragraphs and lean into pattern, mechanism, and conceptual contribution.

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Shorten the methods discussion in the introduction.**  
   The intro currently spends too much real estate on estimator names and assumptions. For editorial positioning, that material is not carrying the paper. The introduction should emphasize the question, why the data matter, and the main substantive findings.

2. **Move the “QWI as a research platform” contribution way down or cut it.**  
   That reads like a side sales pitch. Unless the paper is fundamentally methodological, AER readers do not need a separate contribution claim that the dataset is useful. That is obvious from the paper itself.

3. **Promote the hiring/separation result.**  
   If the mechanism is “verification bites at hiring,” then the flow decomposition should appear in the main result sequence earlier, not as the fourth finding after placebo and industry heterogeneity.

4. **Demote some policy rhetoric in the conclusion.**  
   The final paragraph veers into op-ed mode. “Whether that tradeoff is worth making is a political question” is not harmful, but it is not adding much analytically. A stronger conclusion would state what economists should update: mandatory screening can reduce formal employment for exposed groups without obvious offsetting gains elsewhere.

5. **Trim the welfare calculation unless it becomes more central.**  
   Right now the back-of-the-envelope is plausible but not especially illuminating. It feels like an appendix thought placed in the main text. If retained, it should serve a clear purpose: benchmark the magnitude against plausible exposure shares. Otherwise shorten it.

6. **Front-load the strongest conceptual result.**  
   Readers should not have to wait to understand that the paper’s real value is observing formal-sector displacement in administrative payroll data and linking it to hiring in high-exposure industries.

### Are there buried results that should be in the main text?

Yes: the hiring versus separation channel has more strategic value than the paper currently gives it. If that result is solid enough to feature, it should be part of the paper’s main identity.

### Is the conclusion adding value?

Only moderately. It mostly summarizes. The conclusion should instead do more interpretive work:
- what this changes in the literature,
- what it implies for how economists think about enforcement technology,
- and why formal-sector exclusion is the key economic margin.

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

At the moment, the paper’s distance from AER is driven mostly by **framing and ambition**, with some **scope** concerns.

### Framing problem?

Yes, strongly. The science may be fine enough for field review, but the current story is too close to “an administrative-data replication/extension of prior E-Verify work.” That is not how you get AER attention.

### Scope problem?

Moderately. The paper has multiple outcomes, but it still feels narrow because the outcomes are not marshaled into a larger conceptual claim. It needs either:
- a stronger mechanism-centered story around hiring and formal-sector exclusion, or
- a broader incidence story about who absorbs the labor-market shock and how.

### Novelty problem?

Somewhat. The question itself is not new. E-Verify has been studied. The novelty lies in the data and the resulting ability to measure formal-sector effects more directly. That is real novelty, but it must be presented as yielding a new economic conclusion, not just a cleaner estimate.

### Ambition problem?

Yes. The paper is careful, competent, and safe. AER papers usually make a reader feel that the author is trying to change how we think about a first-order issue. This one currently feels like it is trying to produce a solid estimate in an important policy area. That is not enough.

### Single most impactful advice

**Reframe the paper around formal-sector exclusion by digital work-authorization screening, with hiring as the central mechanism, rather than around “the effect of E-Verify on Hispanic employment” narrowly conceived.**

That one change would improve the introduction, the literature positioning, the narrative arc, and the perceived contribution all at once.

---

### Strategic Assessment

- **Current framing quality:** Adequate
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium
- **Single biggest improvement:** Recast the paper as evidence that mandatory digital verification restricts access to the formal labor market—primarily through hiring—rather than as a better-data estimate of an already-studied immigration policy.