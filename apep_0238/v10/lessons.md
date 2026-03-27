# Lessons — apep_0238 v10

## Revision Summary
- **Parent:** apep_0238 v9
- **Key changes:** Killed structural DMP model (was rejected by J-test, contributed 9% of welfare). Rebuilt around duration-trap mechanism with CPS-derived evidence. Single estimand replaces horizon-by-horizon forest. Complete rewrite of all code (Python→R) and all prose. Added institutional background section on both episodes.
- **Biggest surprise:** The duration-trap attenuation (37-77% explained by UR persistence) was stronger than expected, becoming the paper's most compelling finding. The structural model's absence is not missed.
- **What to do differently:** Start with honest claim calibration. v9 overclaimed for 9 versions; v10 spent 6 advisor rounds learning that lesson. Write the "what this comparison can and cannot identify" paragraph FIRST, before any results.
- **Review feedback adopted:** Lowered claim register throughout (per GPT R1/R2 and Codex), explicit about bundling problem, transparent about pre-trend at h=-36, removed unsupported AR inference claim, removed JOLTS claims without table.

## Co-Author Collaboration (Codex via Duet)
- 5 Duet exchanges total. Codex's contributions:
  1. Identified that "duration/recall" is the empirical object, not "demand/supply" (session 1)
  2. Proposed the three-question filter for every exhibit (session 2)
  3. Caught the horse race sign issue and AR claim (pre-referee sign-off)
  4. Advised "disciplined downshift, not redesign" after referee reviews
  5. Proposed one-sentence revision of the paper's claim
- Fixed Codex CLI config (xhigh→high, -o→--output-last-message) — two rounds of debugging

## Key Methodological Notes
- N=50 is the fundamental power ceiling. Single estimand permutation p≈0.13 — honest but imprecise.
- Pre-trend at h=-36 (p=0.009) is a real limitation, not explained away by construction boom.
- Saiz IV F=11.4 is below Stock-Yogo — supporting evidence, not centerpiece.
- Duration-trap attenuation is the paper's strongest evidence: UR at h=24 absorbs 38%, UR at h=48 absorbs 77%.
