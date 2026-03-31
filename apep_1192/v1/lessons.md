## Discovery
- **Idea selected:** idea_2048 — NHTSA defect queue congestion IV. Selected for examiner-style IV design (tournament winners), first-order stakes (auto safety/deaths), and zero prior literature.
- **Data source:** NHTSA static flat files (static.nhtsa.gov) — free, no auth required. 389MB investigations, 1.5GB complaints, 386MB recalls. Correct URLs at /odi/ffdd/ not /nhtsa/downloads/flatfiles/.
- **Key risk:** Instrument relevance — would other-manufacturer queue predict own-investigation outcomes after absorbing time FEs?

## Execution
- **What worked:** Reduced-form strategy clean and robust. Recall probability is the headline result (-0.0014, p<0.001). Leave-one-out across 8 major manufacturers rock solid. PE vs EA heterogeneity tells a compelling triage story. The Kleibergen-Paap first-stage F of 83 makes the IV credible despite initial confusion with overall model F-stat.
- **What didn't:** The severity "placebo" doesn't work cleanly for recall probability — high-severity cases also show a significant negative effect. Works for duration but not recall. Had to rewrite honestly. The complaint-to-investigation linking was very slow with naive grepl approach; aggregating to manufacturer-month first solved it.
- **Review feedback adopted:** Fixed F-stat contradiction (most critical — was reporting wrong statistic). Added sample construction explanation (5,330 → 1,362 attrition). Added welfare back-of-envelope ($16M/year). Rewrote severity discussion to be honest about mixed results.
