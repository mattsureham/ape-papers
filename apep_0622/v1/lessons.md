## Discovery
- **Idea selected:** idea_0032 — EV registration fees as natural experiment for "stick" side of EV policy
- **Data source:** DOE AFDC Experian vehicle registrations — not available via API, had to scrape annual web tables via WebFetch for all 50 states across 8 years
- **Key risk:** Low statistical power from state-level panel (N=400, 50 states × 8 years) with a small treatment signal relative to massive EV growth trends

## Execution
- **What worked:** CS-DiD with 32 treated states and 10+ adoption cohorts was a clean application of staggered DiD. The PHEV placebo provided compelling evidence for the fee mechanism. The TWFE vs. CS-DiD divergence was itself an informative finding.
- **What didn't:** EIA SEDS API required debugging (facet name was `seriesId`, not `msn`). AFDC data not available via standard API — required manual web scraping. The dose-response specification yielded a contradictory positive sign under TWFE, highlighting the TWFE bias problem but weakening the intensity story.
- **Review feedback adopted:** Added event-study table (Table 4) with pre-trend diagnostics and joint test. Expanded threats to validity: stock vs. flow attenuation, early-adopter identification concern. Reframed dose-response contradiction as consistent with TWFE bias. Fixed LaTeX package ordering bug (titlesec before titleformat).

## Key Takeaways
- When data APIs fail, WebFetch of official government web tables is a viable fallback
- Cumulative stocks as outcomes mechanically attenuate treatment effects — future papers should prefer flow measures when available
- The TWFE vs. robust DiD comparison is itself a publishable finding when the divergence is dramatic
- With 50 clusters, state-level DiD achieves adequate clustering but limited power for small effect sizes
