# Lessons: apep_1436 — Fact-Checking and Media Tone

## Discovery
- GDELT GKG V2Themes + V2Tone at topic-day resolution is a reliable workhorse for questions about the news environment, but V2Tone is a lexicon-based sentiment score and cannot detect factual content updates. If the hypothesized channel is factual correction rather than emotional register, this measure will under-detect the effect. Future work in the same family should consider article-level text similarity, claim-keyword prevalence, or embedding-based measures.
- ClaimReview via the Google Fact Check Tools API is a large but messy corpus. Textual ratings are heterogeneous ("false", "mostly false", "pants on fire", "four pinocchios", "miscaptioned", ...) and require a curated dictionary mapping. Query topics do not cleanly correspond to GDELT V2Themes, forcing a many-to-one mapping and some attrition of events in foreign-policy categories (china, israel, russia, ukraine).

## Execution
- The Eisensee-Strömberg competing-news IV, while thematically appropriate, was weak on this sample (first-stage F = 1.69). Sports + disaster events do not strongly crowd out fact-check publication at daily frequency, at least conditional on topic + topic x month fixed effects. Next time: either strengthen the instrument with explicit major-event shocks (Olympics, natural disasters) coded by hand, or drop IV and frame the paper as a descriptive null.
- Event-study leads pointed positive, which is the wrong sign for a corrective treatment interpretation. Pre-trend failure on day-level panels is the norm, not the exception, when the treatment is an editorial choice that co-moves with the news cycle. This should be anticipated at the planning stage.
- Small-coefficient null results can still be precise. The TWFE point estimate is $-0.019$ tone points per false fact-check with clustered s.e. $0.007$; the null interpretation survives on both statistical and economic grounds.

## Review Pass
- Advisor (codex-mini) and both empirics reviewers (kimi-k2.5, mistral-large) converged on the same diagnosis: endogenous timing + weak IV preclude causal interpretation, and the paper should lean into a descriptive framing. Reviews also asked for attrition transparency (64k raw -> 6226 used).
- Adopted in a single revision pass: (i) added an attrition paragraph to the data section, (ii) softened causal language in the introduction's reading paragraph to a descriptive stance, (iii) kept the IV table with an explicit weak-IV caveat. Did not adopt: cross-topic within-day design, topic-disaggregated estimates, article-level content measures — out of scope for V1 time budget.

## Summary
Honest null. Fact-check publication does not visibly move daily topic-level GDELT tone in the 2017-2024 window. The lead pattern and the weak IV together preclude a clean causal interpretation, but the point estimate is precise enough to rule out economically meaningful equilibrium media-environment effects at this resolution. The interesting open question the null raises is whether a corrective channel exists at finer resolution — article-level, sentence-level, or in factual rather than tonal content.
