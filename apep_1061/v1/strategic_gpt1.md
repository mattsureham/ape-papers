# Strategic Feedback — GPT-5.4 (R1)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-27T11:28:59.283147
**Route:** OpenRouter + LaTeX
**Tokens:** 10860 in / 3799 out
**Response SHA256:** c68f808f8ddc0d8f

---

## 1. THE ELEVATOR PITCH

This paper asks a simple and potentially important question: when a country tightens abortion access, do births rise more in places that are farther from cross-border abortion providers? Using Poland’s 2021 near-ban and geographic variation in distance to clinics in Germany and the Czech Republic, the paper argues that open borders may blunt the demographic effects of domestic restrictions—and finds little detectable fertility gradient.

Why should a busy economist care? Because the broader issue is not Poland per se; it is whether national policy bites in an integrated area when people can arbitrage across borders. That question travels well beyond abortion to taxes, environmental regulation, healthcare, and migration.

**Does the paper itself articulate this pitch clearly in the first two paragraphs?**  
Reasonably, but not optimally. The current opening is vivid and intelligible, but it quickly narrows into a design description (“continuous treatment in DiD across 17 voivodships”) before fully establishing the larger economic question. The introduction should lead less with the econometric setup and more with the substantive proposition: domestic restrictions may fail to generate domestic behavioral responses when cross-border substitution is easy.

**The pitch the paper should have:**

> Governments often expect restrictions on access to a service to change domestic outcomes. But in integrated economic areas, people may evade those restrictions by going elsewhere. This paper studies that logic in the context of Poland’s 2021 abortion restriction: did fertility rise more in places farther from foreign abortion providers, where cross-border substitution is costlier?
>
> Using regional variation in distance to clinics in Germany and the Czech Republic, I test whether Poland’s near-ban produced a “border escape valve” in fertility. I find little evidence of such a gradient. The result suggests that when legal demand is small and cross-border or informal alternatives are available, even a dramatic domestic restriction may have limited aggregate demographic effects.

That is the AER-relevant pitch. It makes the paper about **policy incidence under geographic arbitrage**, with abortion as the setting.

---

## 2. CONTRIBUTION CLARITY

**One-sentence contribution:**  
The paper shows that Poland’s 2021 abortion restriction did not generate a clear regional fertility gradient by distance to foreign providers, suggesting that cross-border access and a small affected legal margin muted the policy’s aggregate demographic impact.

### Is this contribution clearly differentiated from the closest 3–4 papers?
Only partially.

The paper does differentiate itself from:
- US abortion-access/fertility papers,
- broad abortion liberalization/restriction papers,
- at least one paper on the same Polish policy,
- healthcare-distance papers.

But the differentiation is still too method-centric: “I exploit the spatial dimension” is not quite enough. A reader could still summarize it as “another reduced-form paper on abortion access and fertility, but in Poland with a distance interaction.”

What would sharpen differentiation is a clearer claim that this is **not primarily an abortion paper**; it is a paper about **whether cross-border arbitrage neutralizes domestic regulation**. That is more distinctive.

### Is the contribution framed as answering a question about the world, or filling a gap in a literature?
At present it is mixed, with too much “this contributes to three literatures.” That is usually a sign the paper is literature-led rather than question-led.

The stronger framing is world-first:
- **World question:** When domestic restrictions are imposed inside an integrated market, how much do they change local outcomes?
- **This case:** Poland’s abortion restriction inside the EU/Schengen area.
- **Finding:** Much less than simple policy arithmetic might suggest.

That is stronger than “there is little European evidence on abortion restrictions.”

### Could a smart economist who reads the introduction explain what’s new?
Not cleanly enough. Right now they might say:  
“It's a DiD on abortion restrictions in Poland using distance to foreign clinics, and it mostly finds a null.”

That is not fatal, but it is not memorable.

You want them instead to say:  
“It’s about whether open borders make national abortion restrictions demographically ineffective; the answer in Poland is basically yes, at least in aggregate fertility.”

### What would make this contribution bigger?
Several possibilities:

1. **Different outcome variable:**  
   Births/TFR is probably too distal and too low-signal here. A bigger paper would trace the mechanism with outcomes closer to the margin:
   - cross-border abortion volumes,
   - requests for abortion pills / telemedicine,
   - hospitalizations from pregnancy complications,
   - timing/composition of births,
   - maternal migration for care,
   - online search behavior by geography.

2. **Different comparison:**  
   The most powerful comparative framing would be: why did post-Dobbs US bans move births while Poland’s restriction did not? The answer could be about baseline legal margins, travel frictions, federal structure, and informal access.

3. **Different mechanism:**  
   The German-vs-Czech asymmetry is probably the most interesting result in the paper because it maps onto institutional corridors rather than generic distance. If that were developed into the central contribution—**what matters is access to actual cross-border networks, not kilometers per se**—the paper would feel fresher.

4. **Different framing:**  
   Frame it as a paper on **regulatory leakage in integrated markets**. That is broader and more ambitious than a country-specific fertility null.

---

## 3. LITERATURE POSITIONING

### Closest neighbors
The paper’s nearest neighbors appear to be:

1. **Myers (2017)** on abortion access and fertility in the US.
2. **Ananat, Gruber, Levine, Staiger (2007)** or related US abortion-access/fertility work.
3. **Lindo et al. (2020)** on distance to abortion providers and abortion demand in Texas.
4. **Dench et al. (2024)** or the emerging post-*Dobbs* birth-response literature.
5. **Pop-Eleches (2006)** on Romania’s abortion ban and long-run outcomes.
6. **Matysiak et al. (2025)** on the same Polish ruling, if this is indeed the relevant contemporary comparator.

### How should the paper position itself relative to them?
Mostly **build on and reframe**, not attack.

- Relative to the US literature: “Those papers show restrictions matter when the legal margin is large and domestic travel frictions matter. This paper asks when that logic breaks down in an integrated cross-border setting.”
- Relative to Pop-Eleches-style historical bans: “Those settings involved a much more binding change in a less integrated environment; Poland is almost the opposite.”
- Relative to the same-Poland paper: “That paper asks whether births changed nationally; I ask whether the impact varied with cross-border access.”

The paper should not overstate novelty against this literature. The novelty is conditional and contextual.

### Is the paper positioned too narrowly or too broadly?
Oddly, both.

- **Too narrowly** in design terms: lots of emphasis on a specific distance-based DiD in 17 voivodships.
- **Too broadly** in the “three literatures” paragraph, which reads like generic positioning rather than a disciplined intellectual home.

The right audience is not “all abortion papers” and not “all DiD methodology.” It is:
1. public economics / health economics on abortion access,
2. political economy/public economics on policy evasion and arbitrage,
3. spatial economics/regional economics on border effects and service access.

### What literature does the paper seem unaware of?
The missing conversation is the most important one:

- **Cross-border arbitrage / policy leakage / regulatory evasion**
  - taxes and shopping across borders,
  - environmental leakage,
  - healthcare mobility,
  - federalism and local policy incidence when people can travel.
  
That is the literature that can make this paper matter to more economists.

Also relevant:
- **Healthcare mobility within the EU**
- **Access to telemedicine and informal markets**
- **Policy incidence under low enforcement / underground alternatives**
- Possibly **border discontinuity / market integration** literatures, even if not used empirically.

### Is the paper having the right conversation?
Not yet. It is having a competent conversation with the abortion-access literature, but that alone likely keeps it in a crowded lane where the paper looks modest.

The more impactful conversation is:  
**When does domestic regulation fail because geography and integration create escape valves?**

That is the right conversation.

---

## 4. NARRATIVE ARC

### Setup
A government imposes a major abortion restriction and expects fewer abortions to mean more births. But people may evade domestic restrictions by traveling abroad, especially in an open-border area like Schengen.

### Tension
Poland’s 2021 ruling looked dramatic in legal terms, yet two features complicate the standard prediction:
1. the legal abortion margin was already tiny,
2. access to foreign and informal alternatives was heterogeneous but real.

So the tension is: **Should a dramatic legal change produce observable demographic effects at all? And if so, where?**

### Resolution
The paper finds little detectable fertility gradient by distance to foreign clinics. There is a suggestive result for Germany-specific access, but the main message is that the demographic footprint was too small to show up cleanly in regional fertility.

### Implications
The implications should be:
- legal restrictions do not mechanically translate into aggregate demographic change,
- policy effects depend on outside options and market integration,
- in integrated settings, distributional burdens may move more than aggregate births.

### Does the paper have a clear narrative arc?
A serviceable one, but not a fully convincing one.

The main problem is that the paper oscillates between three stories:
1. “There should be a border gradient and I test for it.”
2. “There is basically no effect.”
3. “Actually Germany shows a meaningful asymmetry.”

Those can coexist, but the current draft does not fully decide which is central.

It also undercuts itself rhetorically:
- It calls the finding a “well-powered null,”
- then says the maximum possible effect is below the minimum detectable effect,
- which means the paper is, by its own arithmetic, **not** well-powered to detect plausible fertility effects.

That is not a referee point about power calculation; it is a narrative problem. The reader is left unsure whether the paper’s claim is:
- “there is no meaningful effect,” or
- “there may be an effect, but aggregate fertility is the wrong place to look.”

Those are very different stories.

**What story should it be telling?**  
The best story is:

> Poland’s abortion restriction offers a test of whether domestic regulation changes aggregate outcomes in an integrated market. It largely does not—at least not in regional fertility—because the affected legal margin was tiny and cross-border/informal substitutes were available. The meaningful consequence of the policy is therefore likely distributional and access-related, not aggregate-demographic.

That is a coherent narrative. It turns a modest empirical result into a sharper substantive lesson.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with at a dinner party of economists?
“Poland enacted a near-total abortion ban, but births did not rise more in places farther from foreign clinics. In an open-border setting, even a dramatic legal restriction may have little aggregate demographic bite.”

That is the version that gets attention.

### Would people lean in or reach for their phones?
They would initially lean in because the setting is striking and policy-relevant. But if the next sentence is a detailed account of a null coefficient in a 17-region DiD, they will drift.

The hook is strong; the current packaging is not.

### What follow-up question would they ask?
Almost certainly:
- “So where did the demand go?”
- “Do women shift to Germany, telemedicine, or the underground market?”
- “If births didn’t rise, what *did* change?”

That question reveals the paper’s strategic limitation: the natural audience instinct is to ask for mechanism or alternative outcomes, and the paper cannot really answer.

### If the findings are null or modest: is the null itself interesting?
Potentially yes, but only if the paper owns the right claim.

The null is interesting **not** as “we estimated zero in Poland.”  
It is interesting as: **dramatic regulation can have trivial aggregate incidence when outside options are plentiful and the legally affected margin is small.**

That is valuable.

But the current draft does not make that case as sharply as it should. It occasionally sounds like a failed test of a hypothesized spatial effect, rescued after the fact by arithmetic. The paper needs to make the bounded-null argument front and center from the start.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Shorten the methodological throat-clearing in the introduction.**  
   The introduction spends too much time on design and inferential details too early. For AER-level positioning, the first two pages should be almost entirely about the economic question, the setting, the headline result, and why that result changes how we think about policy in integrated markets.

2. **Move most methodological contribution language out of the introduction.**  
   The paragraph on continuous-treatment DiD and few-cluster inference weakens the introduction strategically. It tells the reader this may be a methods-forward paper, but it is not enough of a methods paper for that to be the selling point.

3. **Front-load the arithmetic that makes the null interesting.**  
   The paper’s most important interpretive point is that the eliminated legal margin was tiny relative to total births and total abortion demand. That should appear in the introduction much earlier, maybe even in paragraph 2 or 3. Right now it arrives after the main estimates, when it should be helping readers understand from the outset what kind of effect size is economically plausible.

4. **Decide whether the Germany result is a headline or a footnote.**  
   Right now it is awkwardly in between. If the author believes the Germany-specific corridor is substantively important, then make the paper partly about institutional access networks rather than pure distance. If not, demote it and avoid over-selling a marginally significant heterogeneity result.

5. **Trim robustness from the main text.**  
   Too much of the reader’s experience is tables of alternative specifications. For editorial positioning, this makes the paper feel smaller and safer than it needs to. Keep the core result, one or two strategic heterogeneity checks, and one event-study figure/table. Push the rest back.

6. **Use a figure early.**  
   A map of Poland with distances to German/Czech clinics and perhaps border corridors would do more for the paper’s narrative than another regression table.

7. **Rewrite the conclusion.**  
   The current conclusion summarizes adequately, but it should do more conceptual work. It should end with the broader lesson: **policy effects depend on enforceability and substitutability; in integrated markets, restrictions may redistribute burdens more than they change totals.**

### Is the paper front-loaded with the good stuff?
Not fully. The setting is front-loaded, but the broader significance is not. The good stuff is currently half-buried under design language.

### Are there results buried in robustness that should be in main results?
Yes:
- the arithmetic on the tiny legal margin,
- the German-vs-Czech institutional asymmetry, if kept,
- perhaps a map/visual of geographic access.

### Is the conclusion adding value or just summarizing?
Mostly summarizing. It needs a clearer conceptual takeaway.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

Be honest: in current form, this is **not close** to an AER paper. The main issue is not polish; it is ambition and framing.

### What is the gap?

#### 1. Framing problem
Yes, strongly.  
The paper is better than its current self-presentation. It should be framed as a paper on **the limits of domestic regulation in integrated markets**, not as a niche estimate of a fertility-distance gradient in Poland.

#### 2. Scope problem
Also yes.  
For the paper to become genuinely top-journal compelling, it probably needs evidence on a more proximate outcome than fertility, or at least a much stronger mechanism section. Aggregate TFR at 17 regions is simply a blunt endpoint for this question.

#### 3. Novelty problem
Moderately.  
The underlying question—do abortion restrictions affect births, and does distance matter?—is already active and fairly well populated. A single-country null on regional fertility is not enough by itself. The novelty must come from the broader conceptual contribution on cross-border escape valves.

#### 4. Ambition problem
Yes.  
The paper is careful and competent, but it feels content to document a modest pattern and stop there. AER papers usually either:
- answer a big question cleanly, or
- use a setting to reveal a general mechanism with wider reach.

This draft is not yet doing either decisively.

### Single most impactful piece of advice
**Rebuild the paper around the broader claim that open borders and informal substitutes can neutralize the aggregate incidence of domestic regulation, and then support that claim with outcomes or evidence closer to actual substitution behavior—not just regional fertility.**

If they can only change one thing, that is the thing.

---

### Strategic Assessment

- **Current framing quality:** Needs rethinking
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Far
- **Single biggest improvement:** Reframe the paper as a broader study of policy leakage in integrated markets and bring in more direct evidence on substitution, because aggregate regional fertility alone is too distal to carry the claim.