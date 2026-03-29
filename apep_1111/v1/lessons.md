## Discovery
- **Idea selected:** idea_1919 — FEMA Risk Rating 2.0 and residential construction. High-stakes climate adaptation question with 3,000+ county panel and novel angle (supply-side construction response vs. standard housing price studies).
- **Data source:** FEMA OpenFEMA NFIP Claims API (2M records), Census Building Permits Survey (2010-2024), Census population API. FEMA NRI ArcGIS API and NFIP Communities v1 API were down — had to pivot to claims data for treatment intensity.
- **Key risk:** Using claims per capita as a proxy for premium shock rather than direct FEMA premium change data. Reviewers correctly flagged this as the paper's main limitation.

## Execution
- **What worked:** The continuous-treatment DiD with county + state×year FE produced clean pre-trends and a plausible pattern — single-family decline (p=0.07), multifamily non-response (good placebo), binary treatment significant at 5%. Event study showed sharp first-year effect.
- **What didn't:** The effect is modest (SDE = -0.006, "Small negative") and only marginally significant for the continuous specification. The proxy treatment introduces measurement error. LAUS unemployment data was unavailable.
- **Review feedback adopted:** (1) Tempered all causal language to "suggestive evidence" framing throughout the paper. (2) Added treatment proxy limitation paragraph in Threats to Validity. (3) Strengthened pre-trends discussion to acknowledge weakly negative pre-coefficients. (4) Added NFIP rate cap discussion to explain fading event study dynamics.
