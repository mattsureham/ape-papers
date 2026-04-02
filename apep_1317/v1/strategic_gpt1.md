# Strategic Feedback — GPT-5.4 (R1)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-04-02T13:38:04.159952
**Route:** OpenRouter + LaTeX
**Tokens:** 11336 in / 3767 out
**Response SHA256:** fe71ad5290b26fb8

---

## 1. THE ELEVATOR PITCH

This paper asks whether the threat of wartime conscription reduces boys’ human capital investment before they ever serve. Using Colombian exam data around the 2016 FARC peace agreement, it argues that male students in more conflict-exposed areas performed worse in math and quantitative reasoning when they belonged to cohorts exposed to the wartime draft environment, suggesting that conscription risk acts like a hidden tax on education.

A busy economist should care because this is, at least in principle, a big question about how states’ security institutions shape civilian investment behavior: not just whether military service lowers later earnings, but whether the prospect of being drafted into an active conflict distorts schooling choices years in advance.

**Does the paper articulate this pitch clearly in the first two paragraphs?**  
Not quite. The introduction is literate and polished, but it opens too much like a topic essay on Colombia plus a literature review on conscription. The core idea — “the threat of wartime conscription may depress pre-service educational investment” — is there, but it is diluted by throat-clearing and then partially muddied by later caveats that the design captures a broader “draft environment” rather than conscription per se. Right now the paper wants the reader to hear a sharp claim and a cautious claim at the same time.

**What the first two paragraphs should say instead:**  

> Governments often treat conscription as a tax on young men’s time: service interrupts work or schooling after induction. But in wartime, the more important cost may arise earlier. If young men expect to face a meaningful risk of military service in dangerous conflict zones — and if educational progression is entangled with draft compliance — they may reduce investment in schooling before they are ever called up.  
>   
> This paper studies that question in Colombia, where compulsory military service operated during decades of civil conflict and where the 2016 FARC peace agreement sharply reduced the salience of combat risk. Using administrative data on national high school and university exit exams, I compare male-female achievement gaps across more- and less-conflict-exposed departments for cohorts reaching draft age before versus after the peace agreement. I find that male students in more conflict-exposed places performed worse under the wartime draft regime, with effects already visible before draft age, consistent with a pre-service human capital penalty from the wartime conscription environment.

That is the pitch the paper should have. It is world-facing, intuitive, and honest about the object being estimated.

---

## 2. CONTRIBUTION CLARITY

**Contribution in one sentence:**  
The paper’s contribution is to argue that wartime conscription can depress educational achievement before service occurs, using Colombia’s transition from active conflict to post-peace conditions to estimate the reduced-form effect of the wartime draft environment on male students’ exam performance.

### Is this contribution clearly differentiated from the closest 3–4 papers?
Only partially. The paper distinguishes itself from classic conscription papers by emphasizing **wartime** rather than peacetime and **pre-service human capital** rather than later labor-market outcomes. That is potentially interesting. But the differentiation is still blurrier than it should be because:

1. It leans on the Angrist-style conscription literature even though it does **not** have draft-lottery variation or service records.
2. It claims at one point to “isolate the conscription channel from the general disruption of conflict,” but later correctly backs away and says the estimate is about the “draft environment.” Those are very different claims.
3. Relative to conflict-and-education papers, it has not yet persuasively staked out why this is not just another paper on male youth in conflict zones around a peace shock.

### Is the contribution framed as answering a question about the WORLD, or filling a gap in a LITERATURE?
It starts with the world question, which is good: does wartime conscription impose a hidden tax on human capital? But it quickly slips into “the literature has not studied wartime conscription.” For AER purposes, the stronger framing is not “there is a gap” but “states may be undercounting a major social cost of conscription because the cost shows up before induction.”

### Could a smart economist who reads the introduction explain what’s new?
Maybe, but not cleanly. Right now they might say:  
“It's a triple-difference paper using Colombian test scores to show that boys in conflict-heavy regions did slightly worse before the peace deal, and the author interprets that as a conscription effect.”  

That is not yet the crisp version you want. The desired reaction is:  
“This paper shows that the threat of wartime conscription can reduce human capital investment before service, which changes how we think about the cost of military manpower systems.”

### What would make this contribution bigger?
Several possibilities, in descending order of strategic value:

1. **Sharper outcome framing around educational choice, not just scores.**  
   Scores are okay, but the big idea is anticipatory disinvestment. Outcomes like exam-taking, graduation, college matriculation, field choice, dropout, delayed enrollment, or formal labor entry would make the anticipatory mechanism more legible and the paper more consequential.

2. **A cleaner demonstration that the effect is specifically about draft salience rather than generalized post-conflict change.**  
   This is the biggest conceptual gap. Even without redesigning the empirical strategy here, the framing should become more explicit that the paper estimates the effect of the wartime draft environment and why that object matters.

3. **Mechanism evidence tied to the libreta militar institution.**  
   The paper has a potentially distinctive institutional hook — the military booklet as a barrier to higher education and formal employment. That is more original than the generic “fear of combat” story, and it could make the paper feel less like a standard conflict paper and more like a paper about how state coercive institutions shape investment.

4. **A broader welfare/accounting frame.**  
   If the paper could convincingly reframe the result as “conventional estimates of conscription costs ignore anticipatory human-capital losses,” it becomes more than Colombia.

---

## 3. LITERATURE POSITIONING

### Closest neighbors
The nearest papers appear to be in two clusters:

**Conscription / military service**
- Angrist (1990) on Vietnam draft and earnings
- Angrist (1998) and Angrist (2011) on conscription and labor-market outcomes
- Bingley and others on Scandinavian conscription opportunity costs
- Ichino and Winter-Ebmer (2004) on war/disruption and career trajectories

**Conflict / education / Colombia**
- León (2012)
- Akresh, de Walque, and Kazianga (2012)
- Shemyakina (2011)
- Blattman and Annan / Blattman-related work on conflict exposure and youth human capital
- Rodríguez and Sánchez (2012/2016 range, depending exact citations)
- Prem, Vargas, Dube, etc. on Colombian conflict institutions and local exposure

There is also a third literature the paper gestures at but does not really exploit:
- **Anticipatory behavior / expectations / dynamic investment under risk**
- Potentially also papers on **policy uncertainty and human capital investment**

### How should the paper position itself relative to those neighbors?
It should **build on** the conscription literature, not pretend to be a direct substitute for lottery-based service papers. The correct line is:
- Those papers estimate effects of service on later outcomes.
- This paper studies a different margin: how the **risk and institutional burden** of wartime conscription affects educational accumulation before service.
- That makes it complementary, not competitive.

Relative to the conflict-and-education literature, the paper should **selectively differentiate**:
- Most conflict papers study violence exposure, displacement, school destruction, or child soldiering.
- This paper studies a state policy institution — compulsory service — as one channel through which conflict affects human capital, especially for young men nearing adulthood.

### Is it currently positioned too narrowly or too broadly?
Oddly, both.

- **Too broadly** in claiming to speak to conscription, conflict, anticipatory behavior, and hidden taxes all at once, with some claims stronger than the design supports.
- **Too narrowly** in the actual evidence base, which is a specific reduced-form pattern in Colombian test scores.

The paper needs one dominant conversation. The best one is:  
**“How do coercive state institutions in wartime distort civilian human-capital investment before direct treatment occurs?”**  
That is broader than Colombia, but more disciplined than “everything about conscription and conflict.”

### What literature does the paper seem unaware of?
It could do more with:
- Human capital investment under uncertainty
- Returns-to-education expectations
- Bureaucratic barriers to schooling/formal labor
- Gendered incidence of conflict institutions
- Peace-shock papers where the main effects operate through expectations rather than immediate treatment

### Is the paper having the right conversation?
Almost, but not quite. The most impactful framing may come less from “conscription literature gap” and more from connecting to a broader economics question:

**When do coercive or uncertain state policies depress private investment before they are ever implemented?**

That conversation includes military service, but also draft risk, migration risk, incarceration risk, and bureaucratic access barriers. That is a more interesting AER-level frame than “another paper on conflict and test scores in Colombia.”

---

## 4. NARRATIVE ARC

### Setup
Before this paper, the standard economic view of conscription is that it imposes costs mainly through time in service and later labor-market disruption. Conflict-and-education papers, meanwhile, show that war harms schooling through violence and instability.

### Tension
But wartime conscription may create a different margin of distortion: young men may underinvest in education **before** service because they expect conscription risk, combat danger, or bureaucratic blockage. That mechanism is important and underexplored.

### Resolution
Using Colombian exam data around the 2016 peace agreement, the paper finds that male students in higher-conflict departments from wartime cohorts have somewhat lower math-related achievement, including at ages prior to service eligibility.

### Implications
If this interpretation is right, the social cost of conscription is understated by analyses that count only time served or post-service earnings. Wartime manpower systems may reduce civilian human capital accumulation through anticipation and uncertainty.

### Does the paper have a clear narrative arc?
It has the bones of one, but it is not fully under control. The main problem is that the paper oscillates between two stories:

1. **Sharp story:** the threat of conscription causes anticipatory disinvestment.
2. **Diffuse story:** the estimate captures a broader draft environment bundle, including violence, labor-market shifts, migration, and institutional changes around the peace deal.

Those are not fatal tensions, but the paper must decide what story it wants to tell. Right now it sometimes sounds like a neat mechanism paper and sometimes like a broad-form reduced-form paper with many possible channels. For AER positioning, ambiguity is costly.

**What story should it be telling?**  
Not “I cleanly isolate conscription.” That overreaches.  
The right story is:

- Wartime conscription is not just actual service.
- It is an institutional environment that differentially burdens draft-eligible males.
- The paper shows that this environment is associated with lower male human capital accumulation before service age.
- That is economically important even if multiple sub-channels are bundled together.

That story is honest and still interesting.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with?
I would lead with this:  
**In Colombia, boys in more conflict-exposed places did worse on academic exams under the wartime draft regime, and the effect already appears before draft age.**

That is the memorable fact.

### Would people lean in or reach for their phones?
They would lean in briefly, but then ask a hard question almost immediately:  
**“How sure are we that this is really conscription risk rather than broader gender-specific effects of the peace deal or conflict exposure?”**

That is the right question, and the paper currently invites it.

### What follow-up question would they ask?
Likely one of these:
- Is the key channel fear of service, the libreta militar requirement, or broader conflict-induced expectations?
- Why are the effects visible in exam scores but not tied more directly to schooling choices?
- Why is the tertiary result framed as cumulative if the DDD at that level appears not to bite the same way?

That last point matters narratively: the paper puts weight on the Saber Pro result, but the design and interpretation there are less aligned with the central story than the prose suggests.

### If findings are modest, is the modesty okay?
Yes, but only if the paper owns it. The high-school effect is small in standardized terms. That is not a deal-breaker if the paper sells the result as:
- a reduced-form effect on a near-universal population,
- measured before service,
- on a margin economists typically ignore.

But if the paper wants to claim “order-of-magnitude amplification relative to peacetime estimates,” the modest size of the school-score effect works against it. Small effects can still matter; overstated rhetoric cannot.

---

## 6. STRUCTURAL SUGGESTIONS

### Without rewriting the paper, what would make it read better?

1. **Compress the literature review in the introduction.**  
   The second paragraph is too much like a seminar warm-up. Move some citation density later. Get to the claim faster.

2. **Front-load the conceptual contribution, not the design.**  
   The introduction should first tell me what wartime conscription changes about educational investment, then tell me why Colombia is a useful setting.

3. **Be much more disciplined about the object of interest.**  
   Replace any language about “isolating the conscription channel” with “estimating the reduced-form effect of the wartime draft environment on draft-eligible males.” Repeat this consistently.

4. **Do not bury the institutional hook.**  
   The libreta militar material is excellent and distinctive. It should appear earlier and more prominently, because it gives the paper a mechanism richer than generic fear-of-war.

5. **Trim passages that oversell magnitudes.**  
   Phrases like “stark” and “order of magnitude” feel inflated relative to the reported effect sizes.

6. **Reconsider the role of Saber Pro in the main narrative.**  
   The university result is potentially useful, but it currently risks confusing the story because it is not built on the same design logic. If kept front and center, it needs to be explicitly framed as complementary rather than cumulative proof of the same mechanism.

7. **The conclusion currently adds some value.**  
   It is better than a pure summary. Still, it should end less poetically and more explicitly on the paper’s general lesson: conscription policy can affect investment before treatment.

### Is the paper front-loaded with the good stuff?
Reasonably, but not enough. The key idea appears in the abstract and first paragraph, but the first two pages still spend too much time earning permission to ask the question.

### Are there results buried in robustness that should be in the main text?
The heterogeneity and the institutional discussion around pre-service timing are more central than some of the generic robustness prose. If the pre-service timing is the hook, then any evidence that sharpens that timing should be elevated.

### Is the conclusion adding value or just summarizing?
Some value. It articulates the hidden-tax idea clearly. But it should avoid sounding more certain than the paper is.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

Bluntly: in current form, this is **not yet an AER story**. The paper is competent and has an interesting instinct, but the gap is meaningful.

### What is the gap?
Mostly a **framing and ambition problem**, with some **novelty-risk**.

- **Framing problem:** The paper’s central insight is stronger than its current presentation, but the current presentation is internally inconsistent. It alternates between a precise causal story and a broad reduced-form one.
- **Ambition problem:** The evidence is narrower than the claims. For AER, the paper needs to make a bigger conceptual point than “test scores moved a bit for boys in conflict departments.”
- **Novelty problem:** Without stronger positioning, many readers will file this under “another reduced-form conflict/education paper using peace-agreement timing.”

### What would excite the top 10 people in this field?
A version that convincingly establishes one of these:
1. Wartime conscription alters **educational investment behavior before service**, not just achievement.
2. The **libreta militar / bureaucratic barrier channel** is first-order and generalizable.
3. The paper changes how we should **account for the welfare cost of conscription systems**, because pre-service human capital losses are quantitatively meaningful.

Right now it hints at all three without fully landing any of them.

### Single most impactful piece of advice
**Pick one claim and make the whole paper serve it: this is a paper about anticipatory human-capital distortion from the wartime draft environment, not a paper that cleanly identifies the effect of conscription itself.**

If they only change one thing, it should be this. A disciplined, honest, world-facing framing could materially improve the paper’s odds. Without that, the paper will be seen as overclaiming off a modest reduced-form result.

---

### Strategic Assessment

- **Current framing quality:** Adequate
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium-Far
- **Single biggest improvement:** Reframe the paper consistently around the reduced-form effect of wartime draft exposure on pre-service human capital investment, and stop implying it cleanly isolates conscription per se.