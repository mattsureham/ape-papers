## Discovery
- **Policy chosen:** France's DPE reform (2021) and progressive rental bans on energy-inefficient properties — provides a unique information-to-regulation transition absent in any other country
- **Ideas rejected:** Taxe d'Habitation abolition (CONSIDER — saturated literature, existing IPP report, parallel trends concern with continuous dose); Loi SRU social housing (SKIP — fuzzy threshold, compound treatments at 3,500 pop cutoff, timing predates DVF)
- **Data source:** DVF (transaction-level prices, open) + ADEME DPE database (energy certificates, open) — both have GPS coordinates for matching; INSEE RP for commune-level rental shares
- **Key risk:** DVF-DPE matching quality; DPE methodology change concurrent with regulatory change requires DiDisc or multi-cutoff design to separate information from regulation

## Review Phase
- Advisor review required 9 attempts to pass (3/4 needed). Key recurring issues:
  - DPE matching: explicit "without filtering by issue date" language triggered false fatal errors — rewriting to emphasize legal pre-listing requirement resolved it
  - D/C vs E/D threshold mislabeling: 250 kWh is E/D boundary, not D/C
  - Treatment date inconsistency (July 1 vs Aug 22, 2021): standardize to July 1 (DPE enforceability)
  - Codex-Mini caught real code bug: `month()` used without lubridate loaded
- External reviews (GPT R2: R&R, Gemini: Major Revision) correctly identified overclaiming — "first clean experiment" language too strong given methodology change confound

## Summary
- When a reform bundles multiple changes (regulatory + methodological), be honest about identification limits from the start
- Heterogeneity results (houses > apartments, rural > urban) are as informative as the headline estimate — they directly test the regulatory mechanism
- McCrary density tests (manipulation finding) are the paper's most novel contribution
- French data ecosystem excellent for empirical work: DVF + ADEME both publicly accessible with GPS coordinates
