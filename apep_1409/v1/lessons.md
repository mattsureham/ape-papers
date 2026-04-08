## Discovery
- **Idea selected:** idea_1311 — Swiss Federal Court naturalization ruling. Chosen for sharp institutional variation, 43-year panel, and potential to name a portable empirical object ("procedural discrimination tax").
- **Data source:** BFS PXWeb API (dataset px-x-0102020000_201) — Live, free, no API key needed. Covered 2,134 municipalities × 44 years.
- **Key risk:** Parallel trends between language regions. German-speaking cantons (ballot) and French-speaking cantons (admin) have structurally different naturalization dynamics.

## Execution
- **What worked:** Canton-specific linear trends resolve the pre-trend issue cleanly. The sign flip from baseline (-0.62) to trends (+4.65) tells a compelling methodological story. Size heterogeneity (small municipalities drive the effect) maps perfectly onto the mechanism.
- **What didn't:** BFS API data structure required debugging — citizenship categories code naturalizations as +/- flows (Swiss gains, Foreign loses), not absolute counts. Initial attempt used citizenship=total, which nets to zero. Fixed by using citizenship=Swiss (category 1).
- **Review feedback adopted:** Prose review praised the opening hook and "procedural discrimination tax" framing. Adopted: sharper Results phrasing (kill "Table X shows"), added human aggregate number (2,350 residents) in intro, removed throat-clearing. Exhibit review suggested consolidating tables — noted for V2.
- **OpenRouter API key expired:** Could not run empirics reviews (Codex-Mini, Qwen, GPT-5.4). Exhibit and prose reviews ran via Google API (Gemini 3 Flash).
