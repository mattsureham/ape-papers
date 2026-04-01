## Discovery
- **Idea selected:** idea_1726 — Medicaid doula reimbursement and population-level birth outcomes. Chosen for first-order stakes (maternal health crisis), clean staggered variation, and massive microdata.
- **Data source:** CDC NCHS Natality Microdata (2018-2023). ~230MB/year compressed, 5GB/year uncompressed. R's built-in download/unzip failed on large files; needed curl + system unzip.
- **Key risk:** Only 8 treated states in sample window (many states adopted in 2024). Pre-trend at t-3 was the main identification concern.

## Execution
- **What worked:** NCHS state code mapping (alphabetical, not FIPS) once figured out. Callaway-Sant'Anna worked cleanly. Triple-diff with private insurance as placebo was a strong design choice — zero placebo effect builds credibility.
- **What didn't:** Fixed-width file parsing was tricky (column positions not immediately obvious). HonestDiD sensitivity failed due to NA reference period. Always need to verify column positions against raw data before parsing.
- **Review feedback adopted:** Added MDE calculation, cluster inference discussion, and treatment maturity caveat. All three reviewers liked the "coverage-to-care gap" framing but wanted more on mechanisms (take-up data) — unavailable in NCHS for V1.
