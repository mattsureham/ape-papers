# Research Idea Ranking

**Generated:** 2026-03-08T21:11:02.363744
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| The Regulatory Ratchet — Asymmetric Cros... | PURSUE (71) | — | PURSUE (70) |
| News Floods and Housing Supply — Testing... | CONSIDER (62) | — | CONSIDER (64) |
| The Regulatory Ratchet in Building Safet... | SKIP (55) | — | SKIP (52) |
| Idea 1: The Regulatory Ratchet — Asymmet... | — | PURSUE (65) | — |
| Idea 3: News Floods and Housing Supply —... | — | SKIP (52) | — |
| Idea 2: The Regulatory Ratchet in Buildi... | — | SKIP (35) | — |

---

## GPT-5.4 (A)

**Tokens:** 8524

### Rankings

**#1: The Regulatory Ratchet — Asymmetric Cross-Sectoral Response to Incident vs. Burden Coverage (idea_0450)**
- **Score:** 71/100
- **Strengths:** This is the most original of the three and the broadest in scope: a cross-agency test of whether media salience systematically pushes regulation up but rarely pulls it down. The Trump EO 13771 period gives the paper a strong narrative hook: even under an explicitly deregulatory administration, does incident-driven attention still dominate?
- **Concerns:** The main outcomes—rule counts, pages, proposals—are only imperfect proxies for economically meaningful regulation, and top journals will care a lot about whether these are real policy bite or just paperwork. The competing-news IV is clever but not obviously clean, since major unrelated news may also directly alter White House/OIRA attention and agency bandwidth.
- **Novelty Assessment:** **Moderately high novelty.** Media attention and policy response are well studied in political economy and political science, but this exact cross-sector federal rulemaking asymmetry test is not a crowded literature, and the application of salience crowd-out to federal regulation appears relatively fresh.
- **Top-Journal Potential:** **Medium.** This could plausibly land in a strong field journal, especially if the main outcome is tightened to economically significant rules or binding restrictions. For a top-5, the current version is probably too institutional and too focused on rulemaking volume rather than a harder downstream outcome.
- **Identification Concerns:** The exclusion restriction for competing-news shocks is the central issue: unrelated major events may directly change executive agenda-setting, not just media coverage. Inference is also delicate with only 12 agencies, so small-cluster methods and long distributed lags are essential.
- **Recommendation:** **PURSUE (conditional on: making economically significant rules / regulatory restrictions the main outcome; demonstrating IV validity with strong placebo and exclusion tests; using small-cluster-robust inference and richer lag structures)**

**#2: News Floods and Housing Supply — Testing the Deregulatory Media-to-Policy Channel (idea_0445)**
- **Score:** 62/100
- **Strengths:** Housing is a first-order policy area, and this idea at least aims for a more journal-friendly causal chain: media salience → deregulatory reform → housing supply. The policy relevance is very high, and the state-level scope is broader than the Surfside design.
- **Concerns:** The design is diffuse: many different reform types, a short 2018–2024 window, and annual permit data that may respond too slowly to recent laws. This could easily turn into a noisy, underpowered “media matters a bit” paper or a null result that is hard to interpret.
- **Novelty Assessment:** **Moderate novelty.** Housing regulation and housing supply are heavily studied, but the specific media-salience-to-deregulation channel is less worked over, especially with recent state reforms.
- **Top-Journal Potential:** **Medium-Low.** Housing gives this idea a chance, but only if the paper cleanly links salience to actual legal change and then to supply. If it stops at coverage and bill passage, it will likely read as a decent political communications paper rather than a field-shaping economics result.
- **Identification Concerns:** Media coverage is likely endogenous to reform pushes already underway, and generic competing-news intensity may affect legislative priorities and even construction conditions directly. Permit outcomes are also confounded by mortgage rates, COVID, migration, and macro cycles over exactly this period.
- **Recommendation:** **CONSIDER**  
  Best if reframed around legislative adoption as the primary outcome, with supply effects as a secondary longer-run analysis, and with a stronger instrument than broad competing-news crowd-out.

**#3: The Regulatory Ratchet in Building Safety — Champlain Towers and Asymmetric State Response (idea_0444)**
- **Score:** 55/100
- **Strengths:** The exact policy is very recent and likely lightly studied, so there is genuine novelty in the narrow sense. The Surfside collapse is also a vivid, plausibly exogenous focal event with clear policy salience.
- **Concerns:** This is badly underpowered for the claims it wants to make: only about 13 adopters, one national shock, and a cross-state salience design. The Olympics IV feels especially fragile and somewhat gimmicky, and the ADU/zoning comparison looks bolted on rather than arising naturally from the setting.
- **Novelty Assessment:** **High on the exact policy, low-to-moderate on the broader idea.** Post-Surfside condo inspection laws are new, but “disaster coverage affects regulation” is a familiar template.
- **Top-Journal Potential:** **Low.** The setting is niche, the sample is small, and the likely contribution is more descriptive policy diffusion than a decisive causal result. This feels more like a specialized field-journal or policy brief topic than a top economics paper.
- **Identification Concerns:** States with more coastal exposure, older condo stock, or greater engineering risk had stronger reasons both to cover Surfside and to legislate, so salience is tightly entangled with underlying need. Olympics attention is not plausibly random across states and may be weak as an instrument.
- **Recommendation:** **SKIP**

### Summary

This is a decent batch with one clearly stronger project. **Idea 1** is the only one I would actively push forward now, because it combines the broadest scope, the most defensible novelty, and a potentially publishable puzzle. **Idea 3** is worth keeping alive only if it is sharply narrowed and redesigned around cleaner outcomes and identification; **Idea 2** is too underpowered and too IV-fragile to be a good use of time.

---

## Gemini 3.1 Pro

**Tokens:** 7970

Here is the evaluation and ranking of the research proposals, applying the criteria and editorial patterns provided.

### Rankings

**#1: Idea 1: The Regulatory Ratchet — Asymmetric Cross-Sectoral Response to Incident vs. Burden Coverage**
- **Score**: 65/100
- **Strengths**: The theoretical framing—testing the availability cascade and regulatory ratchet cross-sectorally—is excellent and addresses a first-order political economy question. Applying the Eisensee-Strömberg (ES) competing-news IV to regulatory politics is a highly creative approach to isolating the causal effect of media salience.
- **Concerns**: There is a severe temporal mismatch between the high-frequency IV (daily/weekly news shocks) and the low-frequency outcome (federal rulemaking, which takes 18-36 months due to APA requirements). A news shock in Q1 cannot mechanically produce a published, economically significant rule in Q2.
- **Novelty Assessment**: High. The cross-sectoral asymmetry test of the regulatory ratchet using an IV for media salience is genuinely novel. Most literature in this space is qualitative, relies on endogenous time-series, or focuses on single-incident case studies.
- **Top-Journal Potential**: Medium. A top-5 journal would love the core question and the asymmetry test, but reviewers will immediately kill the paper over the mismatch between the fast IV and the slow APA rulemaking process. If the outcome were pivoted to fast-moving agency actions, it could be a strong *AEJ: Economic Policy* contender.
- **Identification Concerns**: The ES IV requires the outcome to be discretionary and immediate (like FEMA disaster relief). Federal rulemaking is heavily constrained by the Administrative Procedure Act, OIRA review, and long drafting periods, making the proposed lag structure highly implausible.
- **Recommendation**: PURSUE (conditional on: changing the outcome variable to high-frequency, discretionary agency actions like enforcement fines, guidance documents, or press releases rather than formal APA rulemaking).

**#2: Idea 3: News Floods and Housing Supply — Testing the Deregulatory Media-to-Policy Channel**
- **Score**: 52/100
- **Strengths**: Addresses a highly relevant policy area (housing deregulation) and attempts to isolate the causal role of media narratives, which is a missing link in the standard housing supply literature.
- **Concerns**: State legislative processes are rigid, calendar-bound, and slow, making them highly incompatible with a high-frequency "news flood" IV. A natural disaster in September does not causally impact a scheduled floor vote in April.
- **Novelty Assessment**: Moderate. While the media channel for housing is understudied, the application of the ES IV to state-level housing policy feels forced compared to its original disaster-relief context.
- **Top-Journal Potential**: Low. Top journals favor "first-order stakes + one sharp channel." The channel here is extremely blurry because legislative passage is a multi-year coalition-building exercise, not a discretionary executive response to a fleeting news cycle. 
- **Identification Concerns**: The exclusion restriction likely fails because state-level competing news (like a local natural disaster or major crisis) directly impacts state budgets and legislative priorities, independently of crowding out housing media coverage.
- **Recommendation**: SKIP

**#3: Idea 2: The Regulatory Ratchet in Building Safety — Champlain Towers and Asymmetric State Response**
- **Score**: 35/100
- **Strengths**: Capitalizes on a highly salient, tragic natural experiment (the Surfside collapse) to study the diffusion of building safety regulations across states.
- **Concerns**: The proposed instrumental variable (the Tokyo Olympics) lacks cross-sectional variation, as it occurred globally at the exact same time. Furthermore, the asymmetry test compares fundamentally unrelated policy domains (building safety vs. ADU zoning) driven by entirely different political coalitions.
- **Novelty Assessment**: Low to Moderate. Event studies of disasters leading to regulation are common (e.g., Fukushima and nuclear power, Enron and Sarbanes-Oxley). 
- **Top-Journal Potential**: Low. The empirical design is fundamentally broken. Top journals require clean causal identification, and an IV with no cross-sectional variation applied to a small N (13 treated states) will not survive desk review.
- **Identification Concerns**: The Tokyo Olympics is a pure time-series shock. Unless the author interacts it with some endogenous state-level variable (like Olympic viewership), it cannot predict *differential* state-level media coverage of Surfside. 
- **Recommendation**: SKIP

### Summary

This batch attempts to creatively apply the Eisensee-Strömberg competing-news IV to regulatory and legislative outcomes, but struggles heavily with the mechanical realities of how policy is actually made. The ES IV works beautifully for fast, discretionary executive actions, but fails when applied to slow, calendar-bound legislative or APA rulemaking processes. Idea 1 is the strongest because the theoretical framing (the regulatory ratchet) is compelling and the data is rich, but it requires a strict pivot to high-frequency agency outcomes (like enforcement or guidance) to be viable. Ideas 2 and 3 suffer from fatal identification flaws regarding the IV's application to slow-moving or cross-sectionally invariant settings and should not be pursued.

---

## GPT-5.4 (B)

**Tokens:** 9410

### Rankings

**#1: The Regulatory Ratchet — Asymmetric Cross-Sectoral Response to Incident vs. Burden Coverage (idea_0450)**
- **Score: 70/100**
- **Strengths:** This is the most original of the three in economics terms: a cross-agency test of incident-salience versus burden-salience, with a potentially interesting Trump-era stress test of whether explicit deregulation can overcome media-driven ratcheting. The Federal Register/RegData panel is feasible and broad enough to give the paper a general, not purely anecdotal, feel.
- **Concerns:** The outcome is still somewhat soft: rule counts and pages are not the same as economically meaningful regulatory tightening. The design also rests heavily on media-based treatment and an IV whose exclusion restriction is not automatic, especially with only 12 agencies.
- **Novelty Assessment:** **Moderately high.** I do not know of a well-known economics paper doing this exact multi-agency asymmetry test with an Eisensee-Strömberg-style crowd-out design, though adjacent political science/public administration literatures on focusing events, agenda-setting, and media salience are large.
- **Top-Journal Potential:** **Medium.** The “incident coverage moves regulation, burden coverage does not” result is a real puzzle with broad implications, and AEJ: Economic Policy is plausible. For a top-5, though, you would need a sharper causal chain and more substantive outcomes than document counts.
- **Identification Concerns:** Competing-news shocks may affect agency activity directly, not only media salience; elections are especially dangerous here. Inference is also fragile with 12 clusters, so wild-bootstrap/permutation methods and very careful instrument construction are essential.
- **Recommendation:** **PURSUE (conditional on: making substantive rule outcomes the main object, e.g. significant final rules or restriction changes; using only clearly unrelated crowd-out shocks for the IV; and handling small-cluster inference very carefully)**

**#2: News Floods and Housing Supply — Testing the Deregulatory Media-to-Policy Channel (idea_0445)**
- **Score: 64/100**
- **Strengths:** Housing is the biggest-policy-stakes setting in the batch, and the intended chain—media salience of regulatory burden → deregulatory law adoption → permits—is much more economically legible than a pure media-effects paper. There is real upside if you can show attention helps overcome entrenched anti-supply politics.
- **Concerns:** As written, the design is vulnerable: 2018-2024 is a short, turbulent window dominated by COVID, rate shocks, and construction-cost shocks, all of which hit both media and permits. If the punchline is a null on deregulation, publication value drops sharply unless power and design are exceptional.
- **Novelty Assessment:** **Moderate.** I do not know a clean economics paper on media-induced housing deregulation specifically, so the angle is fresh. But housing reform determinants are already a crowded area, so the novelty is in the identification strategy and channel, not the broad topic.
- **Top-Journal Potential:** **Medium.** Housing reform is absolutely top-journal territory in principle, and this could fit the “first-order stakes + sharp channel” template. But in its current form it looks more like an ambitious field-journal paper unless the legislative first stage is very strong and the downstream permit effects are persuasive.
- **Identification Concerns:** Competing news may directly affect legislative calendars, state politics, or construction activity, violating exclusion. Annual permits are also a delayed and noisy outcome; legislative adoption/intensity should be the main endpoint, with permits as a secondary mechanism.
- **Recommendation:** **CONSIDER (best if reframed around law adoption/intensity first, with permits as downstream evidence, and with a tighter monthly/state-level salience design that explicitly deals with COVID and interest-rate confounding)**

**#3: The Regulatory Ratchet in Building Safety — Champlain Towers and Asymmetric State Response (idea_0444)**
- **Score: 52/100**
- **Strengths:** The exact policy episode is very recent and likely understudied, and the question is concrete enough that policymakers could understand the result immediately. Surfside is also a vivid focusing event, which helps narrative clarity.
- **Concerns:** This is the narrowest and least credible design of the three. Only about 13 treated states is thin for the kind of IV claim being proposed, and the Olympics instrument is clever but not convincingly exogenous to the kinds of states that would act on condo-safety legislation.
- **Novelty Assessment:** **Narrowly high, broadly modest.** The Surfside-specific diffusion question is probably new because the event is recent, but that is “episode novelty,” not a major conceptual gap. The broader disaster/focusing-event literature is already substantial.
- **Top-Journal Potential:** **Low.** The setting is too episode-specific and underpowered to travel well to a top economics audience. At best this looks like a specialized policy paper unless expanded into a broader disaster-to-code-adoption design.
- **Identification Concerns:** State variation in Olympics coverage is unlikely to satisfy exclusion; it may reflect demographics, media markets, or political interest correlated with housing regulation. The asymmetry comparison to ADU/zoning deregulation also feels forced rather than organically identified.
- **Recommendation:** **SKIP (unless broadened into a larger multi-disaster/state-code diffusion project with a much stronger source of exogenous salience variation)**

### Summary

This is a decent batch, but only one idea currently looks worth serious development. **Idea 1** is the best bet because it is the most novel, scalable, and potentially general, though it still needs a sharper outcome and tighter IV to clear the “competent but not exciting” bar. **Idea 3** is worth keeping on the shelf because housing gives it bigger upside, but I would not lead with it unless the identification is substantially strengthened; **Idea 2** is too narrow and underpowered as currently framed.

