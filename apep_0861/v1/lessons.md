## Discovery
- **Idea selected:** idea_0961 — UK police austerity and domestic abuse justice
- **Data source:** Home Office Workforce Open Data + Supplementary Crime Outcomes Metrics — both clean, programmatically accessible
- **Key risk:** Original IV strategy (precept share) couldn't be implemented due to lack of force-level funding data. Pivoted to panel FE design.

## Execution
- **What worked:** The placebo test (non-victim offenses = precise null) is the strongest result and key differentiator. The leave-one-out stability analysis (range 7.55-10.31) was clean. The event study timing with uplift reversal is compelling narratively.
- **What didn't:** ONS file downloads were blocked by Cloudflare (size 0 responses). DA-specific outcomes were only available as a 2024 cross-section, not a panel. The precept share instrument data was not programmatically accessible.
- **Review feedback adopted:** Tempered causal language throughout, added explicit limitations paragraph (no IV, truncated panel, no DA-specific outcomes), adjusted title to remove "domestic abuse" framing, reframed identification section to honestly describe the FE design rather than overclaiming exogeneity.

## Key Lessons
- UK Home Office data is excellent when you can find the right file, but the ONS website is hostile to programmatic access (Cloudflare blocks, inconsistent URL patterns)
- The Supplementary Crime Outcomes Metrics file is an underused gem: force-level outcome rates from 2015-2024 in a single clean XLSX
- For UK policing papers, the victim-based vs. non-victim-based offense split creates a natural placebo that judges value highly
- With 43 clusters, event study coefficients will be individually imprecise — plan for joint tests and narrative patterns rather than per-year significance
