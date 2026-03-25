## Discovery
- **Idea selected:** idea_1898 — AVR and jury acquittal rates. Chose for the "administrative pipeline" mechanism and built-in falsification potential.
- **Data source:** FJC Integrated Database — free, massive (6.28M records), well-documented. Download used deflate64 compression which required system unzip (R's unzip() can't handle it).
- **Key risk:** Effect size too small to detect. Confirmed: MDE ≈ 5.6pp, null estimated at -0.003.

## Execution
- **What worked:** FJC data was clean and matched the manifest exactly (DISP1 codes 3 and 9). District-to-state mapping required knowing FJC's alphanumeric district codes (3L, 3N, 3A etc.) which aren't purely numeric. CS DiD ran smoothly with 90 districts, 41 treated, 49 control.
- **What didn't:** Triple-difference requires district-level jury plan data (voter-only vs DMV-supplemented) that isn't available in standardized form. HonestDiD failed due to too many event-time coefficients from Sun-Abraham.
- **Review feedback adopted:** Added MDE/power calculation, first-stage discussion citing prior literature, triple-diff as future work limitation, softened precision claims.
