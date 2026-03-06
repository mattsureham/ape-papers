## Discovery
- **Policy chosen:** State gasoline tax increases (2013-2024) — 34+ states with staggered timing provide clean DiD variation for studying the most visible consumer price signal's effect on macroeconomic beliefs
- **Ideas rejected:** (1) WARN Act mass layoffs → national pessimism (identification too weak — layoffs endogenous to state conditions); (2) Newspaper closures → belief formation (closures endogenous to economic decline)
- **Data source:** CES cumulative (Harvard Dataverse, 700K+ respondents) for individual-level beliefs + Google Trends for high-frequency attention + EIA SEDS for first-stage validation. All freely accessible.
- **Key risk:** CES is annual (Sept-Nov), so timing of gas tax changes within the year may create measurement noise. Google Trends as secondary outcome helps capture higher-frequency dynamics.

## Review
- **Advisor verdict:** 3 of 4 PASS (took 5 rounds — consistency issues between text and code/data were the main blocker)
- **Top criticism:** All 3 external referees flagged TWFE-based heterogeneity as internally inconsistent with the paper's own argument that TWFE is biased. This was the single most impactful feedback.
- **Surprise feedback:** Both GPT-5.4 reviewers wanted an in-sample first stage (gas tax → retail prices), which was not originally part of the design. Without an EIA API key, this could only be addressed through literature-based discussion.
- **What changed:** (1) Replaced all TWFE heterogeneity with CS-DiD subgroup estimates, (2) Substantially narrowed all interpretive claims — "rational attribution" became "one interpretation", (3) Added 4 new citations (de Chaisemartin, Roth, Chetty-Looney-Kroft, Finkelstein), (4) Added treatment timing sensitivity results, (5) Added first-stage discussion using pass-through literature, (6) Acknowledged bundled policies as limitation.
- **Key lesson:** For null-result papers, the burden of proof is much higher. Reviewers want to be sure the null reflects "no effect" not "weak design." Every potential source of attenuation (timing misclassification, weak first stage, noisy outcome) must be explicitly addressed.
