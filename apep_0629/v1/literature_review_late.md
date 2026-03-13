# Late Literature Positioning Audit

**Date:** 2026-03-13
**Purpose:** Verify no critical omissions in bibliography after external reviews

---

## Reviewer-Suggested Additions

### GPT-5.4 (R1) suggestions:
1. **Grimmer, Roberts, and Stewart (2022), *Text as Data*** — measurement validity in political text
2. **Roberts, Stewart, and Tingley (2019)** — STM validation work
3. **Egami et al.** — text embeddings and causal inference with text
4. **Surprisal/psycholinguistics literature** — log-probability as meaningful quantity

### GPT-5.4 (R2) suggestions:
1. **Bommasani et al. (2021), "On the Opportunities and Risks of Foundation Models"** — contamination context
2. **Bender et al. (2021), "On the Dangers of Stochastic Parrots"** — what predictive performance means
3. **Grimmer, Roberts, and Stewart (2022)** — construct validity (repeated)

### Gemini suggestions:
- No specific literature additions requested

---

## Assessment

The paper's bibliography (30 entries) covers the six core strands identified in the research plan:
1. Democratic theory (Aristotle, Habermas, Rawls, Fishkin)
2. Institutional economics (Persson-Tabellini)
3. Computational political text (Gentzkow-Shapiro-Taddy, Monroe, Spirling, Zhou)
4. Deliberation measurement (Steiner, Bächtiger, Fournier-Tombs, Flores)
5. Political LMs (RooseBERT, ParlBERT, PoliBERTweet)
6. ML/infrastructure (Shannon, Vaswani, Karpathy)

### Omissions to consider for V2:
- **Grimmer et al. (2022)** — strongest case for addition; directly relevant to measurement validity arguments
- **Surprisal/psycholinguistics** — would strengthen the case for cross-entropy as the correct scale
- **Foundation model literature** — less critical since the paper trains from scratch specifically to avoid these issues

### Decision:
The current bibliography is adequate for V1 publication. The Grimmer et al. and surprisal literature are natural additions for a V2 that implements the cross-entropy DI scale.
