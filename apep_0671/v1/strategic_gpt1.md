# Strategic Feedback — GPT-5.4 (R1)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-14T12:34:26.399580
**Route:** OpenRouter + LaTeX
**Tokens:** 10575 in / 3621 out
**Response SHA256:** 6714ab66af0e3e6b

---

## 1. THE ELEVATOR PITCH

This paper asks a big, durable question: when the U.S. sharply restricted immigration in 1924, did native-born workers move up the occupational ladder because competition fell, or did they lose because immigrant labor had been complementary to their work? Using linked census records to follow individual native workers before and after the Johnson-Reed Act, the paper argues that cutting immigration slowed natives’ occupational advancement, suggesting that complementarity dominated competition.

The question is absolutely AER-relevant. It speaks to one of the central empirical disputes in labor economics, with unusually important historical variation and unusually rich data.

Does the paper itself articulate this clearly in the first two paragraphs? Partly, but not cleanly enough. The current opening gets the history right and states the competition-versus-complementarity tension, but it quickly slips into design language and coefficient reporting before the reader has a crisp sense of the core contribution. The first two paragraphs should lead with the world question, the shock, and the surprising answer—not the machinery.

### The pitch the paper should have

“In 1924, the United States abruptly shut down one of the largest immigration waves in its history. A basic question—still central to current policy debates—is whether native-born workers benefited when immigrant labor disappeared, or whether cutting immigration instead disrupted productive complementarities that had helped natives move into better jobs.

This paper answers that question by tracking millions of native-born workers across linked census records before and after the Johnson-Reed Act. I show that in places most exposed to the quota, native occupational mobility slowed rather than accelerated, implying that the lost complementarity from reduced immigration outweighed any gains from reduced labor-market competition.”

That is the AER story. Right now, the introduction is too eager to tell me how the estimate works before it has made me care about what is being estimated.

---

## 2. CONTRIBUTION CLARITY

**One-sentence contribution:**  
The paper provides individual-level historical evidence that the 1924 immigration quotas reduced, rather than increased, native-born workers’ occupational advancement in more exposed local labor markets.

That is a real contribution. But the paper does not yet present it with enough discipline.

### Is it clearly differentiated from the closest 3–4 papers?
Not really. The paper names literatures, but the differentiation is still mushy. Right now the reader gets something like: historical immigration paper + linked census data + DiD-ish county exposure design + task complementarity interpretation. That is adjacent to a lot of recent work. The novelty is not “I also study immigration with census links.” The novelty is:

1. **Policy shock**: a major federal immigration restriction, not inflows.
2. **Unit of observation**: individual workers and occupational trajectories, not city/county averages.
3. **Outcome**: career mobility, not wages/employment/political attitudes.
4. **Finding**: restriction appears to have hurt natives’ advancement.

The paper should hammer those four distinctions much harder.

### World question or literature gap?
It starts with a world question, which is good. But it repeatedly falls back into “first individual-level evidence” and “this contributes to several literatures.” That is weaker. AER introductions should say: here is a major question about how labor markets work; here is a historical episode that cleanly illuminates it; here is what we learn about the world. “No one has done this at the individual level” is supporting material, not the headline.

### Could a smart economist explain what’s new?
At present, maybe only vaguely. Too many readers would summarize it as “another immigration paper using historical county exposure and linked census data.” That is the danger. The introduction needs to make the new object of interest unmistakable: **native occupational mobility as the margin through which immigration restrictions may backfire**.

### What would make the contribution bigger?
Several concrete ways:

- **Lean harder into career ladders** rather than OCCSCORE alone. If the paper can show movement into supervisory, clerical, or skilled jobs specifically, the contribution becomes much sharper and more economically interpretable.
- **Make task complementarity more tangible.** Right now complementarity is asserted from the sign pattern. A more direct framing around transitions into communication/supervisory roles versus manual roles would enlarge the paper conceptually.
- **Clarify the policy counterfactual**: restriction versus continued inflows. The paper’s contribution gets bigger if it is framed as evidence on what is lost when labor-market complementarities are interrupted, not merely a historical treatment effect.
- **Connect more directly to modern restriction episodes**. The Bracero comparison helps, but the paper could more explicitly position itself as part of a broader lesson: labor-market adjustments to immigration cuts may differ from simple competition models even in very different eras.

There is also a serious presentational problem: the paper currently contains conflicting empirical messages in different sections. Early cross-sectional results and heterogeneity tables tell a competition story; later stacked results tell a complementarity story. That may be empirically resolvable, but editorially it muddies the contribution badly. A paper cannot be strategically positioned around one headline while spending pages generating the opposite headline first.

---

## 3. LITERATURE POSITIONING

### Closest neighbors
The closest neighbors appear to be:

- **Foged and Peri (2016)** on immigration-induced native occupational upgrading.
- **Clemens, Lewis, and Postel (2022)** on the end of the Bracero program and whether restricting immigrant labor helped natives.
- **Tabellini (2020)** on historical immigration and local outcomes/political economy.
- **Lewis (2011)** on immigration, skill mix, and production technology/task complementarity.
- **Abramitzky, Boustan, Eriksson et al. / Price et al.** on linked historical census data and immigrant/native adjustment.

Classic background references like **Borjas (2003)** and **Card (2001)** matter, but they are not the real neighboring conversation. They are the big debate being entered, not the immediate comparison set.

### How should it position itself?
Mostly **build on and bridge**, not attack.

- Build on **Foged-Peri** by showing the mirror image: restricting low-skill immigration can slow native upgrading.
- Build on **Clemens et al.** by bringing in a different historical setting, different labor-market margin, and individual occupational trajectories.
- Build on **Tabellini** and the historical immigration literature by shifting the outcome from politics or aggregate local development to individual career mobility.
- Use **Lewis/Peri task-specialization** as the conceptual lens, not just a cite.

The paper should not posture as overturning the entire Borjas/Card literature. That would be overbroad and not credible from this design alone. Better to say it illuminates one under-measured adjustment margin: occupational progression.

### Too narrow or too broad?
Oddly, both. The underlying question is broad and important, but the current positioning is too narrow in its mechanics and too broad in its claims.

- Too narrow because it reads like a historical immigration design paper.
- Too broad because it sometimes implies a general verdict on immigration restriction and “the labor market is not a zero-sum contest,” which outruns what is strategically safest.

The right audience is labor/public/historical economics broadly—not just migration historians.

### What literature does it seem unaware of?
It should be speaking more directly to:

- **Career mobility / labor-market ladders** literature, not just immigration.
- **Adjustment margins under labor-supply shocks**—occupations, industries, geography, mechanization—not just wages and employment.
- Possibly **economic history of industrial organization of labor** in the 1920s: how immigrant manual labor and native supervisory roles fit within production systems.

That unexpected connection—to career mobility rather than just immigration incidence—may be the most impactful reframing available.

### Is it having the right conversation?
Not quite. It is currently having the “who is right, Borjas or Peri?” conversation. That conversation is important, but crowded and repetitive. The more interesting conversation is: **what happens to workers’ career ladders when a major input to local production disappears?** Immigration is the shock; occupational mobility is the margin. That is fresher and more AER-like.

---

## 4. NARRATIVE ARC

### Setup
Before this paper, economists know that immigration may generate both competition and complementarities, but most evidence focuses on wages/employment or aggregate outcomes rather than individual career trajectories. The 1924 Act provides a major national restriction shock with heterogeneous local exposure.

### Tension
The intuitive political claim is that restricting immigration should help natives, especially lower-skill natives who compete most directly. But the task-specialization view says the opposite may happen: cutting immigrant manual labor may collapse the ladder into better native jobs.

### Resolution
The paper’s intended resolution is that native occupational advancement slowed in more exposed places after the quota, indicating complementarity losses. That is potentially a strong resolution.

### Implications
If true, the paper implies that immigration restrictions can harm natives not just through wages or output, but by reducing opportunities for advancement along occupational ladders. That matters for both policy and labor-market theory.

### Does the paper have a clear arc?
Only partially. Right now it reads too much like a collection of specifications searching for a stable headline. There is a good story in there, but it is obscured by the sequencing.

The biggest narrative problem is that the paper first walks the reader through a set of cross-sectional and heterogeneity results that imply one story, then later asks the reader to discard them in favor of a stacked before/after story implying the opposite. That creates whiplash. A busy reader comes away thinking: “I’m not actually sure what the result is.”

### What story should it be telling?
The story should be:

1. The 1924 quotas abruptly cut immigrant labor supply in places where immigrants were heavily concentrated.
2. A simple post-quota comparison is misleading because immigrant destinations were already on different trajectories.
3. The central empirical object is therefore not the post-1924 cross-section, but the **change in the relationship between exposure and native mobility relative to the pre-quota decade**.
4. That change is negative, pointing to lost complementarity.
5. The economically important implication is that immigration affected natives through career ladders.

That means the current cross-sectional results should be demoted to motivation/diagnostics, not presented as major “main results.”

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with?
“I’d lead with: when the U.S. slammed the door on Southern and Eastern European immigration in 1924, native-born workers in the most exposed places did not climb the occupational ladder faster—they climbed more slowly.”

That is a good dinner-party fact. Economists would lean in.

### Would people lean in or reach for phones?
They’d lean in at first, because the historical episode is dramatic and the answer cuts against a simple competition narrative. But the very next question would be: **what margin is driving that—wages, occupations, industrial restructuring, migration, or selective linkage?** If the paper cannot answer that in the framing, the interest fades.

### What follow-up question would they ask?
Probably one of these:
- “Is it really complementarity, or just that immigrant-heavy counties were on different trajectories in the 1920s?”
- “What occupations specifically did natives stop moving into?”
- “Why are the key outcomes career-based rather than wage-based?”
- “Does this show a broad labor-market lesson or only something special about 1920s industrial America?”

Those are good questions. The paper should anticipate them in the framing, not wait for them.

### If findings are modest
The effect sizes are not enormous, and some secondary outcomes are mixed. That is fine if the paper owns the right claim: the result is interesting because it reveals the sign on an important adjustment margin, not because the magnitude is spectacular. But the paper should stop overselling some pieces and underexplaining others. The null on some binary upgrading outcomes is not a problem if the main message is about overall occupational progression and reallocation patterns. Still, the paper needs tighter discipline around what the core finding is.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Move the stacked before/after design to the center immediately.**  
   The current paper makes the reader traverse a cross-sectional exercise that the paper itself later says is misleading. That is poor architecture. The main specification should appear in the introduction and then in the first results table.

2. **Demote the naïve post-1924 cross-section.**  
   Keep it as a short motivating diagnostic: “If one looked only post-1924, one would conclude X; but the same pattern existed even more strongly before the Act.” Do not make it Table 1-style “main results” if it is not the paper’s real estimand.

3. **Shorten the institutional background.**  
   The background is competent but generic. It can be tighter. Everyone who needs to read this paper can understand the quota logic in a page.

4. **Reorganize the results around one headline.**  
   Suggested order:
   - Main before/after stacked result
   - Interpretation and magnitude
   - Heterogeneity/mechanism-consistent patterns
   - Secondary margins
   - Simpler post-only results as cautionary contrast or appendix

5. **Stop front-loading coefficients in the introduction.**  
   One or two numbers are enough. The introduction currently feels like a rolling regression table.

6. **Bring any occupation-content results forward.**  
   If the paper has evidence on movement into supervisory/clerical/skilled roles, that belongs in the main text. Right now the mechanism discussion is more verbal than evidentiary.

7. **Tighten the conclusion.**  
   The conclusion currently reads like a policy op-ed. It should instead state the contribution more precisely: this paper identifies occupational mobility as an important channel through which immigration restrictions may harm natives. Let the reader infer broader policy resonance.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

The gap is mostly **framing plus ambition of the empirical object**, with some **novelty risk** if not sharpened.

### Is it a framing problem?
Yes, substantially. There is a paper here with an A-level question and potentially AER-worthy angle, but the current draft obscures it. It presents too many intermediate results that conflict with the headline and therefore weaken confidence in what the paper is actually about.

### Is it a scope problem?
Somewhat. For AER, the paper likely needs a richer demonstration of what “occupational advancement” means in economically concrete terms. OCCSCORE is okay, but not enough by itself to make the contribution feel definitive. The paper would be bigger if it showed sharper reallocations across task content or role categories.

### Is it a novelty problem?
Potentially. Historical immigration with county exposure and linked census data is now a recognizable genre. To feel new at the AER level, this cannot just be “another paper about immigration restriction.” It has to be **the paper that shows immigration restriction affects natives through career ladders**, using a dramatic federal shock.

### Is it an ambition problem?
A little. The paper is safer than it should be. It has a chance to make a bigger conceptual claim about labor-market organization and worker advancement, but it stays close to standard immigration-incidence language.

### Single most impactful advice
**Rebuild the paper around one central claim: the 1924 Act disrupted native career ladders in immigrant-dependent local labor markets, and the stacked before/after design—not the post-only cross-section—is the paper’s true empirical core.**

If they do only one thing, it should be that.

---

### Strategic Assessment

- **Current framing quality:** Needs rethinking
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium
- **Single biggest improvement:** Recenter the paper on native occupational mobility as the key margin and make the stacked pre/post contrast the unmistakable main result from page 1.