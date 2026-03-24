# Strategic Feedback — GPT-5.4 (R2)

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.4
**Timestamp:** 2026-03-13T11:21:22.539560
**Route:** OpenRouter + LaTeX
**Tokens:** 10740 in / 3718 out
**Response SHA256:** 3b9e586de04559ba

---

## 1. THE ELEVATOR PITCH

This paper asks whether banning employers from asking about applicants’ prior pay reduces the gender wage gap at the point of hire. Using administrative data on new-hire earnings across U.S. states that adopted salary history bans between 2017 and 2023, it argues that these laws modestly narrow the gender gap in starting pay, with no clear evidence of the kind of statistical-discrimination backlash seen in the ban-the-box context.

Why should a busy economist care? Because the paper speaks to a first-order question about labor-market inequality: how much of today’s pay gap is mechanically inherited from yesterday’s wage-setting process, and can a relatively light-touch information policy interrupt that transmission?

Does the paper itself articulate this pitch clearly in the first two paragraphs? Partly, but not sharply enough. The current introduction has the right ingredients—intertemporal wage anchoring, a salient policy, and the Doleac-Hansen comparison—but it leads with a familiar “women earn 83 cents” setup and then quickly slips into a policy-description mode. The core question is more interesting than that: **does prior salary function as a transmission mechanism for inequality?** That should be the front-door framing.

### The pitch the paper should have

A good first two paragraphs would say something like:

> Labor markets do not just price workers; they inherit prices from prior employers. If firms use past salary to anchor new offers, then any earlier wage disadvantage can persist across job transitions even when it no longer reflects productivity. Salary history bans are designed to sever that link, making them a direct test of whether inequality is transmitted through wage-setting itself.
>
> This paper studies whether those bans changed the wages firms offer to newly hired workers. Using administrative data on new-hire earnings across U.S. states and industries, I find that salary history bans modestly narrow the gender gap in starting pay, with effects that grow over time and no detectable evidence of racial statistical discrimination. The broader implication is that information restrictions in labor markets can either reduce inequality or induce substitution toward stereotypes; here, the former appears more important than the latter.

That version foregrounds the world question, not the estimator or the data architecture.

---

## 2. CONTRIBUTION CLARITY

### Contribution in one sentence

The paper’s contribution is to show, using administrative state-industry-quarter data on new-hire earnings, that salary history bans modestly reduce the gender gap in starting pay and do not appear to generate a ban-the-box-style racial backlash.

### Is this contribution clearly differentiated from the closest papers?

Only somewhat. The introduction says this is the “first industry-level decomposition” using QWI and distinguishes itself from survey, tax-record, and audit-study work, but that is still a bit too data-centric. “First industry-level decomposition” is not, by itself, an AER-level contribution. The real differentiator has to be one of these:

1. **The paper identifies the margin most directly affected by the policy—new-hire pay rather than annual earnings.**
2. **It reframes salary history bans as a test of dynamic wage transmission, not just as another pay-equity policy evaluation.**
3. **It puts salary history bans in the broader class of information-removal policies and shows they behave differently from ban-the-box.**

Those are stronger than “I use QWI.”

### Is the contribution framed as answering a question about the world, or filling a gap in the literature?

At present, it is mixed, leaning too much toward literature gap/data gap language. “First industry-level decomposition” and “QWI uniquely provide…” are literature/data-framed contributions. The stronger frame is about the world:

- Do wages inherit prior discrimination through employer use of salary history?
- Can removing one piece of information change pay-setting without causing offsetting discrimination?
- Are information restrictions in labor markets generally dangerous, or does that depend on the kind of information removed?

That is the conversation the paper should center.

### Could a smart economist explain what’s new after reading the intro?

Right now, they might say: “It’s a staggered-DiD paper on salary history bans using QWI; they find a modest narrowing in the new-hire gender gap.” That is competent, but not memorable.

You want them to say: “It shows that prior salary acts like a transmission channel for inequality: once states ban employers from using that information, the gender gap in starting pay falls, and unlike ban-the-box there’s no obvious substitution toward racial discrimination.”

That is much better.

### What would make the contribution bigger?

Most importantly: **make the paper about wage transmission and the hiring margin, not about the existence of one more policy effect.**

Specific ways to make it bigger strategically:

- **Emphasize starting wages as the key outcome.** The paper already uses new-hire earnings, which is the right margin. It should lean much harder into why that matters conceptually: this is the offer-setting stage, where salary history is actually used.
- **Strengthen the comparison to broader earnings measures.** If existing work studies annual earnings or broader wage outcomes, the paper should explicitly say why effects should show up first and most cleanly in new-hire pay.
- **Push the information-economics angle.** The bigger question is not “do these bans work?” but “when does removing information reduce inequality rather than increase statistical discrimination?”
- **Sharpen mechanism language.** “Anchoring” is the story, but the current industry heterogeneity exercise does not really establish it. The paper needs either a more direct mechanism framing or more humility. Strategically, better to say this is consistent with interrupting wage-history transmission than to oversell a loose industry pattern.
- **De-emphasize the estimator contribution.** The TWFE-versus-CS contrast is useful, but it is not the main reason the paper belongs in AER. As written, the paper risks sounding like a methods application stapled to a policy question.

---

## 3. LITERATURE POSITIONING

### Closest neighbors

The closest papers appear to be:

1. **Agan et al. (2022)** on salary history bans and labor-market outcomes.
2. **Barach and Horton (2021)** on salary history / wage setting / negotiation, likely in online labor market context.
3. **Sinha (2024)** or similar recent paper on salary history bans.
4. **Doleac and Hansen (2020)** on ban-the-box and statistical discrimination.
5. Possibly **Agan and Starr (2018)** and related information-removal/disclosure papers.

There is also a broader pay transparency / wage-setting literature that the paper should probably engage more seriously, since salary history bans sit near that family of interventions.

### How should it position itself relative to those neighbors?

Mostly **build on and bridge**, not attack.

- Relative to the salary-history-ban literature: “Existing work asks whether the policy affects overall earnings or hiring; I isolate the new-hire wage-setting margin where the mechanism should bite most directly.”
- Relative to ban-the-box: “Not all information-removal policies are alike; removing prior salary appears to differ materially from removing criminal history.”
- Relative to the wage-setting/pay-transparency literature: “This policy changes the information set used in bilateral wage bargaining and offer formation.”

It should not overstate that it overturns prior work unless there is a genuine contradiction. Right now the positioning is too much “this is first with these data” and not enough “this resolves an important conceptual ambiguity.”

### Is it currently positioned too narrowly or too broadly?

A bit of both, oddly.

- **Too narrowly** in the sense that it often sounds like a state-policy evaluation paper for labor economists who care about gender gaps.
- **Too broadly** when it gestures at methods and multiple literatures without choosing the central conversation.

The paper needs one primary conversation and one secondary one.

My view:
- **Primary conversation:** labor-market inequality and wage-setting.
- **Secondary conversation:** information-removal policies and statistical discrimination.

The methods point should be tertiary.

### What literature does the paper seem unaware of?

Two areas need fuller engagement:

1. **Wage-setting / bargaining / salary anchoring / monopsony-style employer discretion** literatures.
   - The paper currently invokes anchoring somewhat behaviorally, but the broader economics of wage setting is underdeveloped.
2. **Pay transparency and related compensation-policy reforms.**
   - Salary history bans are conceptually adjacent to pay transparency, posted salary ranges, and restrictions on employer information. There may be a bigger conversation here about how institutional changes reshape bargaining power and wage compression.

It may also benefit from speaking more to:
- discrimination and statistical discrimination theory,
- dynamic persistence of inequality over the life cycle,
- employer learning and information frictions.

### Is the paper having the right conversation?

Not quite. It is having three conversations at once and none forcefully enough.

The most impactful framing is probably:
**salary history bans as a natural experiment on whether labor-market inequality is propagated through wage-history-dependent offer setting.**

That conversation then naturally links to:
- gender wage gaps,
- information frictions,
- statistical discrimination,
- compensation policy.

That is richer than “another staggered DiD on a state law.”

---

## 4. NARRATIVE ARC

### Setup

Before this paper, we know that gender pay gaps persist and that employers often use prior salary in setting compensation. Policymakers introduced salary history bans to stop past underpayment from carrying forward into new jobs, but it remains unclear whether these bans meaningfully affect wages at hire or simply induce employers to use other proxies.

### Tension

There are two tensions, both good:
1. **Mechanism tension:** If salary history transmits inequality, bans should reduce gender gaps in starting pay.
2. **Substitution tension:** If employers lose useful information, they may substitute toward group-level priors, potentially harming minority workers—as in ban-the-box.

That is a strong narrative spine.

### Resolution

The paper finds that the gender gap in new-hire earnings narrows modestly after adoption, the effect grows over time, and there is no clear evidence of worsening Black-white gaps or hiring differences.

### Implications

The implication is that some inequality is embedded in wage-setting institutions rather than solely in worker characteristics or occupational sorting, and that information restrictions can sometimes reduce inequality without triggering harmful substitution.

### Does the paper have a clear narrative arc?

It has the ingredients of one, but currently feels somewhat like a collection of decent results arranged linearly:

- main effect,
- event study,
- industry heterogeneity,
- race test,
- TWFE comparison,
- placebo.

That is a standard applied micro sequence, not yet a memorable story.

### What story should it be telling?

The story should be:

1. **Wages can inherit inequality across jobs.**
2. **Salary history bans sever that inheritance at the exact moment firms set new pay.**
3. **The key empirical test is therefore at the new-hire margin.**
4. **If the policy merely removes information, employers may substitute toward stereotypes.**
5. **The evidence suggests the inheritance channel matters more than the substitution channel.**

That is a real narrative. The current draft gets close, but it lets the design and estimator occupy too much narrative space.

---

## 5. THE “SO WHAT?” TEST

### What fact would I lead with?

I would lead with this:

**When states ban employers from asking about prior pay, the gender gap in starting wages for new hires falls—suggesting that part of the wage gap is literally carried from one job to the next through salary-history-based offers.**

That is the dinner-party fact.

### Would people lean in?

Yes, somewhat. This is an intuitively interesting policy and a live economic question. But they will only lean in if the paper presents it as a finding about how labor markets function, not as a narrow estimate on one state policy.

### What follow-up question would they ask?

Probably one of these:
- “How big is that relative to the overall pay gap?”
- “Is the effect really on women’s wages, or just compositional?”
- “Why doesn’t this produce ban-the-box-style statistical discrimination?”
- “Does it matter more in negotiation-heavy occupations or higher-wage labor markets?”

The paper should anticipate those questions in its framing, even if referees later judge the underlying evidence.

### If findings are modest: is that okay?

Yes, but only if the paper embraces why a modest effect is still informative.

A 2.3 log point reduction is not earth-shattering. For AER, modest effects can be fine if they settle an important conceptual question. The value here is not that salary history bans “solve” the gender gap; it is that they reveal one identifiable mechanism by which pay inequality persists.

The paper does make this point a bit in the discussion (“closes 8.5 percent”), but it should go further. The message should be:

- This is a **small-to-moderate policy effect**,
- on a **very specific and theoretically central margin**,
- which tells us something large about **dynamic inequality transmission**.

That is how modest findings become interesting rather than deflating.

---

## 6. STRUCTURAL SUGGESTIONS

### What would make it read better?

1. **Compress the institutional background.**
   - The adoption chronology is overlong for the main text. Readers do not need a state-by-state legislative parade this early.
   - Move more of the legal detail to an appendix or a short table.

2. **Shorten the empirical-strategy exposition in the introduction.**
   - The Callaway-Sant’Anna discussion is too prominent up front.
   - For editorial positioning, this reads as method-forward when it should be question-forward.

3. **Move the TWFE comparison out of the starring role.**
   - Keep it, but demote it. Right now it risks making the contribution sound like “TWFE gets this wrong,” which is old news unless the underlying substantive finding is itself major.

4. **Front-load the conceptual contribution.**
   - The introduction should say early that the paper studies **new-hire earnings**, the margin at which salary history should matter most.
   - That is much more compelling than waiting until the data section to clarify the outcome.

5. **Be more selective with heterogeneity.**
   - The industry section as presented is not especially persuasive narratively, especially given the null DDD interaction and mixed industry results.
   - Either tighten it substantially or relegate parts of it to the appendix. It currently weakens the anchoring story more than it strengthens it.

6. **Integrate the race mechanism more tightly into the main narrative.**
   - This is actually one of the more interesting parts of the paper because it broadens the audience beyond gender-pay-gap readers.
   - It should be framed as a second headline result, not just “robustness and mechanism tests.”

7. **Trim generic conclusion rhetoric.**
   - The “Yesterday’s wage need not be tomorrow’s anchor” line is fine, but the conclusion mostly summarizes.
   - A stronger conclusion would say what this changes in how economists think about wage persistence and information restrictions.

### Are there results buried that should be in the main results?

Yes:
- The race/backlash result deserves more prominence.
- The conceptual importance of the new-hire outcome should be elevated from a data detail to a headline contribution.

### Is the conclusion adding value?

Only modestly. It is cleanly written, but not doing enough intellectual work. It should end with a sharper claim about what this teaches us about labor-market institutions.

---

## 7. WHAT WOULD MAKE THIS AN AER PAPER?

At present, the gap is mostly a **framing and ambition problem**, with some **scope** issues.

This is not obviously a novelty failure: salary history bans are an active topic, and the new-hire margin is genuinely appealing. But in current form the paper reads like a solid field-journal paper because it presents itself as:
- another staggered-DiD state-policy evaluation,
- with an administrative-data angle,
- plus a methods warning about TWFE.

That is not enough for AER.

### What would excite the top people in the field?

A version of this paper that clearly claims:

- salary history is a mechanism that propagates inequality across jobs;
- the relevant place to test that is starting wages for new hires;
- removing this information changes offers in a measurable way;
- and information-removal policies are not uniformly prone to discriminatory substitution.

That is potentially an AER conversation.

### Is the problem framing, scope, novelty, or ambition?

- **Framing problem:** Yes, primarily.
- **Scope problem:** Somewhat. The paper needs to decide what is core and what is peripheral.
- **Novelty problem:** Not fatal, but the current draft undersells the novelty it does have and leans on weak novelty claims (“first industry-level decomposition”).
- **Ambition problem:** Yes. The paper is too content to be a careful estimate of a state policy. It should make a bigger claim about wage-setting and inequality transmission.

### Single most impactful piece of advice

**Reframe the paper around the substantive idea that prior salary transmits inequality across jobs, and that new-hire earnings provide a direct test of whether removing that information changes wage-setting without inducing discriminatory substitution.**

That is the one change that could most alter the paper’s trajectory.

---

### Strategic Assessment

- **Current framing quality:** Adequate
- **Contribution clarity:** Somewhat fuzzy
- **Literature positioning:** Could be stronger
- **Narrative arc:** Serviceable
- **AER distance:** Medium
- **Single biggest improvement:** Recast the paper from a state-policy DiD into a broader claim about wage-history-based transmission of inequality, using new-hire earnings as the decisive margin.