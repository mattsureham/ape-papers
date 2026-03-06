# Revision Plan — Round 1

Based on three external referee reviews (2 Major Revision, 1 Minor Revision).

## Key Changes Made

### 1. CS-DiD Design Clarity (GPT-1, GPT-2)
- Rewrote Section 4.3 and appendix to unambiguously define the CS-DiD unit (commune-quarter), treatment assignment (inside=city adoption quarter, outside=0), and control group
- Explicitly stated the identifying assumption: inside-boundary price trends parallel across cities
- Referenced CS-DiD dynamic effects (Figure 2) as supportive evidence

### 2. CS-DiD Robustness (GPT-1, GPT-2)
- Added leave-one-city-out CS-DiD analysis in Section 6
- ATT ranges from -0.031 to +0.026, all insignificant
- Null is not driven by any single city

### 3. Air Quality First Stage (GPT-1, GPT-2)
- Added month-of-year FE to absorb seasonal pollution cycles
- Added caveat about 10km CAMS resolution being too coarse for boundary-level inference

### 4. Language Calibration (GPT-1, GPT-2)
- Changed "precisely estimated null" to "precisely estimated near-zero" throughout
- Added note that CI cannot exclude small-to-moderate effects of 2-3%
- Characterized conclusions as "rules out large effects"

### 5. Treatment Intensity and Limitations (All reviewers)
- Added explicit acknowledgment that binary first-adoption indicator may attenuate estimates
- Strengthened discussion of measurement horizon and enforcement limitations
