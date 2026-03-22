## Discovery
- **Idea selected:** idea_0816 — Multi-threshold bunching at charitable audit thresholds. "Hidden compliance costs in nonprofit filing thresholds" was explicitly called out as a winning hook in tournament judge feedback.
- **Data source:** IRS Exempt Organizations Business Master File — clean download, 1.94M organizations, no API issues
- **Key risk:** Revenue vs. contributions measurement mismatch (EO BMF has total revenue, some states threshold on contributions)

## Execution
- **What worked:** The multi-state design provided 34 independent replications. The difference-in-bunching comparison with no-mandate states is a clean placebo. The $500K threshold is modal (29 states), giving good power.
- **What didn't:** The pooled bunching estimate is an honest null — no systematic audit-avoidance behavior detected. The result is sensitive to polynomial order, suggesting the counterfactual density is not well-identified.
- **Review feedback adopted:** Increased bootstrap from 200 to 500 replications, added DiB standard errors (t=0.28), added $500K no-mandate placebo (b=-0.019), tightened null-result language, added honest caveats about measurement error attenuation.
- **Key lesson:** For bunching designs, the revenue/contributions distinction matters enormously when the null is the finding. Future work should use Form 990 XML to construct the correct running variable per state.
