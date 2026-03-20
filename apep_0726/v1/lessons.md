## Discovery
- **Idea selected:** idea_0262 — Bridges fiscal federalism RDD (Brollo, Litschig, Corbi) and IPV economics (Aizer 2010) for the first time
- **Data source:** SIM mortality (DATASUS FTP via microdatasus) — 6.2M death records, 2015-2019
- **Key risk:** SINAN violence data unavailable through microdatasus package; female homicide is rare in small municipalities

## Execution
- **What worked:** FPM multi-cutoff RDD design is clean — McCrary density test passes (p=0.40), covariate balance is smooth. The identification is gold-standard.
- **What didn't:** SINAN violence notifications cannot be fetched through microdatasus (only disease-specific SINAN subsystems supported). SIM download is extremely slow (~7 min per year × 27 states). RAIS employment data requires restricted access, so the mechanism test was not possible.
- **Result:** Well-identified null. Point estimate on female homicide is negative (-0.386 per 100K) but imprecise (SE 0.288). With threshold + state FE, estimate is essentially zero (0.014, SE 0.328).
- **Review feedback adopted:** Removed duplicate DV/homicide outcomes (they were identical variables), fixed year discrepancies (2015-2019 not 2009-2022), acknowledged mechanism table limitations, added MDE discussion.
- **Key lesson:** For Brazilian DATASUS data, plan for multi-hour downloads. microdatasus only supports specific SINAN diseases, not SINAN-VIOL. The FPM population threshold design is well-validated but may lack power for rare outcomes (female homicide) in small municipalities.
