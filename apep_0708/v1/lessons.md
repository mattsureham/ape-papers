## Discovery
- **Idea selected:** idea_0168 — The 1924 Immigration Act's effect on women's LFP via the domestic servant channel. Selected for first-order stakes (gender revolution), massive data (7.65M linked women), and sharp mechanism.
- **Data source:** Azure MLP linked panel — fetched seamlessly via DuckDB. No API issues.
- **Key risk:** Bartik exposure validity; pre-trends for unmarried women.

## Execution
- **What worked:** The Azure MLP infrastructure is excellent for historical census papers. DuckDB queries against 5GB parquet files complete in minutes. The individual-level panel (vs. county aggregates) is the key advantage.
- **What didn't:** The smoke test in the idea manifest was misleading — raw exposure quartile means showed married women GAINING LFP, but this reflected omitted state FE and controls. The actual regression showed the opposite. Lesson: never trust unconditional means from smoke tests when state FE are needed.
- **Surprising finding:** The Cortes-Tessada mechanism runs in the same direction historically, not in reverse. Immigration restriction reduced (not increased) women's LFP by eliminating complementary domestic labor. This is actually a better paper than the original hypothesis.
- **Review feedback adopted:** (1) Added sample size discrepancy explanation (linking rates), (2) added conservative bounding exercise for unmarried women's placebo, (3) strengthened caveats about exposure measure and Great Depression confounding.
- **Key weakness for V2:** The unmarried women's placebo (~40% of main effect) is the biggest vulnerability. A V2 should add heterogeneity by number of children, construct a tighter quota-shock instrument, and add occupational transition matrices.
