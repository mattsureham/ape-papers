# Strategic Feedback — GPT-5.2

**Role:** Journal editor (AER perspective)
**Model:** openai/gpt-5.2
**Timestamp:** 2026-03-05T16:53:45.711070
**Route:** OpenRouter + LaTeX
**Tokens:** 20773 in / 2751 out
**Response SHA256:** 91704179565c334e

---

## 1. The Elevator Pitch (Most Important)

This paper asks whether high-income households “sort” across U.S. state borders to avoid higher state income taxes, using ZIP-code–level IRS SOI data near eight high-tax/low-tax borders from 2012–2021. The punchline is that large cross-border differences in the local concentration of high-income filers mostly reflect economic geography rather than taxes, and the 2017 SALT cap delivers at most a modest additional border-sorting effect that is hard to cleanly separate from the COVID/remote-work era.

**Does the paper itself articulate this pitch clearly in the first two paragraphs?** The opening anecdote is strong and concrete. But paragraph 2 immediately pivots to a standard literature tour and only later reveals the paper’s *actual* distinctive value proposition: that (i) the “naïve border discontinuity” is misleading due to geography, and (ii) the SALT cap is used as the within-border shock to isolate the tax channel. Right now the introduction reads like it’s going to deliver a clean border-RDD estimate of tax-driven sorting; only later does it emphasize diagnostic failure and “upper bound” interpretation. That mismatch risks disappointing the reader.

**What the first two paragraphs should say instead (the pitch the paper should have):**

> Large state income tax gaps create seemingly enormous incentives for affluent households to live on the low-tax side of a border. Using ZIP-code IRS data at eight high-tax/low-tax borders from 2012–2021, I show that the raw “border discontinuity” in rich-household concentration is large but mostly reflects persistent cross-border economic geography rather than tax avoidance.  
>  
> I then use the 2017 TCJA SALT deduction cap—an abrupt increase in the effective price of living in high-tax states for affluent itemizers—to isolate the incremental tax channel within the same border framework, yielding a modest change in high-income concentration and an empirical upper bound on tax-driven sorting at state borders.

That is the honest, AER-suitable framing: the paper is not “a clean border RDD of millionaire flight,” but “here’s what borders *can and cannot* tell you about tax sorting, and here’s what SALT adds.”

---

## 2. Contribution Clarity

**One-sentence contribution:** The paper uses ZIP-code IRS data at multiple state borders and the SALT-cap shock to separate tax-driven sorting from confounding economic geography, concluding that the large raw border discontinuity is mostly non-tax and that any incremental tax-induced border sorting is modest (an upper bound).

**Is it clearly differentiated from the closest 3–4 papers?** Only partially. The paper does distinguish itself on *data granularity* (ZIP SOI rather than state flows or individual panels) and on the *border-stock* perspective (stocks near borders rather than mover flows). But the “what’s new” vis-à-vis (i) millionaire-migration panel work and (ii) border-based local public finance designs needs a sharper contrast: the paper’s novelty is less “we do a border discontinuity” (many do) and more “we show why the border discontinuity is deceptive for this question, and we offer a SALT-based within-border approach that yields a bound.”

**World vs. literature gap framing:** The strongest version is about the **world**: policymakers and the public infer tax causality from border patterns (“look at NJ vs PA suburbs”), but those patterns embed deep geography; the paper quantifies how misleading that inference is and how much incremental sorting appears after a policy shock that changes the tax price. The current introduction still spends too much time sounding like it is “filling a gap” (ZIP-level tool; boundary design) rather than overturning a common inference about how to read border evidence.

**Could a smart economist summarize what’s new after reading the intro?** Today they might say: “It’s a border RDD on rich households and SALT.” They may miss that the *core* result is diagnostic: the border RDD fails the tests and therefore should be interpreted as geography; SALT is used to rescue a limited tax signal.

**What would make the contribution bigger (specific):**
- **Reframe the central object** from “estimate the border discontinuity” to “decompose border discontinuities into (i) persistent place differences vs (ii) tax-price shocks,” with SALT as the headline instrument-like shock.
- **Outcome scope:** The paper currently focuses on the ≥$200k share. A bigger contribution would be to foreground an outcome with clearer policy bite and interpretability in the public finance conversation (e.g., implied change in high-income *counts* or high-income *AGI* near borders), while keeping the share as a composition measure.
- **Mechanism leverage:** The most promising “bigger” mechanism is explicitly: *remote work reduces the moving cost near borders*, and SALT interacts with that. If the post effect is COVID-era, the paper could own that as the main insight rather than treating it as contamination.

---

## 3. Literature Positioning

**Closest neighbors (3–5):**
- Young et al. (2016) “Millionaire Migration and State Taxation of Top Incomes” (or related IRS-panel millionaire flight work).
- Moretti & Wilson (2017) on star scientists and state taxes.
- Kleven, Landais, Saez-style mobility of top earners / preferential tax schemes (Denmark; athletes; inventors).
- Black (1999) and Keele & Titiunik (2015) on geographic/boundary discontinuity designs.
- A broader “tax capitalization / local public finance borders” set (e.g., Notowidigdo-style border designs; property-value capitalization at boundaries—many papers, depending on which the authors choose as canonical).

**How to position relative to neighbors:**
- **Build on** Young/Moretti/Wilson by saying: “Mover panels find small flow responses; border-stock evidence seems huge; here’s why those border patterns are mostly geography, and here is a policy-shock design that yields a number consistent with the panel literature.”
- **Synthesize and discipline** the boundary-design literature: “State borders are especially problematic because they bundle many discontinuous policies and historical development; here’s an applied template for diagnosing when borders mislead.”
- Avoid “attacking” the panel literature; instead, position as reconciling two types of evidence that otherwise look contradictory.

**Too narrow or too broad?** It is currently **too method-forward and diffuse**: it wants to speak to public finance, regional/urban, and methods simultaneously, but the paper’s empirical core is a public-finance question with a methods lesson. The best AER positioning is: **public finance/fiscal federalism first**, with the methods contribution as a disciplined secondary contribution.

**What literature does it seem unaware of / should speak to?**
- The **SALT-cap empirical literature** (there is a growing post-TCJA literature on SALT incidence, housing markets, and high-income location choice). Even if ZIP-level deductions aren’t available, the paper needs to cite and distinguish from SALT-related work, otherwise it looks oddly isolated.
- The **remote work / migration post-2020** literature (especially since the event-study timing points there). If the result shows up mainly in 2020–2021, that literature becomes part of the conversation, not a confound.

**Right conversation / unexpected connection?** The most impactful reframing may be to connect the paper to the broader theme: **“Why naïve border comparisons are tempting but wrong for policy incidence questions”**—a general lesson for applied micro, not just tax.

---

## 4. Narrative Arc

**Setup:** Big, salient tax differences across state borders; common belief that rich households can arbitrage them (“millionaire flight”), especially near borders where moving is cheap.

**Tension:** Border comparisons look like the perfect quasi-experiment (similar labor markets/amenities, different taxes), but state borders also separate different urban systems, housing markets, and histories—so the naïve discontinuity may be mostly geography.

**Resolution:** The naïve border discontinuity is large but unstable and fails placebos/balance; when using SALT as a within-border tax-price shock, the incremental change in affluent concentration is small/modest and concentrated late in the sample.

**Implications:** Policymakers should be cautious inferring tax avoidance from cross-sectional border patterns; the credible magnitude of tax-driven sorting at borders appears limited (upper bound), potentially increasing when moving costs fall (remote work).

**Does the paper have a clear arc?** It’s close, but it currently reads like **two papers stitched together**:
1) a border-RDD paper that discovers it doesn’t work cleanly, and  
2) a SALT-DDD paper that gives a modest estimate with timing complications.

To feel like one coherent AER narrative, it should be explicitly a paper about **“what border evidence means”** and use SALT as the disciplined way to extract the tax component. Right now, the “diagnostic failure is a feature” line is good, but it needs to become the organizing principle of the paper rather than a defensive aside.

---

## 5. The “So What?” Test

**Dinner-party lead fact:** “At rich/poor tax borders, the raw ZIP-level discontinuity in rich-household concentration is huge—but low-income households show an even bigger discontinuity the other way, implying the border pattern is mostly urban geography, not tax avoidance.”

**Would people lean in?** Yes—because it punctures a common casual inference (“just look across the river”). The second hook is: “Using the SALT cap as a tax-price shock, the incremental effect on border sorting is modest and shows up mostly during COVID/remote work.”

**Follow-up question economists will ask:** “So is this a SALT effect or a remote-work effect—and what does that imply about tax competition going forward?” The current draft treats this as a threat; strategically, it may be the most interesting implication: tax sensitivity may be *state-dependent* on moving frictions.

**If effects are modest/null:** The paper does a decent job arguing why “small” is informative (it bounds the tax channel). But it needs to be more explicit that the **main empirical value** is to discipline exaggerated claims and to explain why “border evidence” is not prima facie causal.

---

## 6. Structural Suggestions

- **Move faster to the diagnostic result.** The introduction is long and somewhat conventional; the paper’s “hook” is the placebo/bandwidth instability and what that implies for interpreting border designs. That should appear on page 2, not as a later “third finding.”
- **Reorganize Results into two pillars:**
  1) *Why the naïve border discontinuity is not interpretable as a tax effect* (placebos, covariate imbalance, bandwidth sign flip, border heterogeneity).
  2) *What the SALT shock reveals about the incremental tax channel* (DDD + timing + interpretation as bound).
- **Shrink/streamline the conceptual framework.** It’s fine but generic; the paper’s value is empirical interpretation and design diagnostics, not a two-location utility model.
- **Clarify sign conventions and keep one estimand in the foreground.** The paper repeatedly warns about different sign conventions across nonparametric vs parametric. For readers, this is friction. Pick a convention and normalize everything to it in the text and tables.
- **Conclusion:** Currently it adds value by emphasizing limitations and diagnostics; keep that, but tighten the “future work” list so it doesn’t read like an admission that the paper is incomplete.

---

## 7. What Would Make This an AER Paper?

The gap is **not** primarily technical execution; it is strategic: the paper is trying to be (a) a border-RDD estimate of tax sorting and (b) a methods cautionary tale and (c) a SALT paper and (d) a COVID/remote-work paper. AER papers can do multiple things, but they need one dominant message.

Most impactful single advice: **Own the “border discontinuities are mostly geography” result as the headline contribution, and present the SALT analysis as the disciplined *decomposition* that extracts an upper bound on the tax component—explicitly engaging both the SALT-cap literature and the remote-work/migration literature as part of the interpretation rather than as confounds.**

If the paper makes that pivot cleanly, it becomes a paper that top public-finance people will discuss because it changes how they read a commonly invoked piece of evidence (border comparisons) and offers a template for extracting policy-relevant signal.

---

### Strategic Assessment

- **Current framing quality:** Adequate  
- **Contribution clarity:** Somewhat fuzzy  
- **Literature positioning:** Could be stronger  
- **Narrative arc:** Serviceable  
- **AER distance:** Medium  
- **Single biggest improvement:** Reframe the paper around a single message—border discontinuities are not evidence of tax-driven sorting unless paired with a within-border tax-price shock (SALT), which here implies only a modest upper bound—and integrate COVID/remote-work as an economically meaningful interaction rather than a nuisance.