# Revision Plan (Stage C)

## Overview
Addressing feedback from tri-model referee panel (GPT-5.4 R1, GPT-5.4 R2, Gemini-3-Flash).

## Key Changes

### 1. Measurement Error Discussion (Must-fix)
**Source:** All three reviewers
**Action:** Added dedicated paragraph in Results section discussing attenuation bias from NDC-based measurement error. Three counter-arguments provided: (1) non-parametric spec also flat, (2) min-price detects small effect, (3) consistency across specifications.
**Location:** Section 6.1, after Table 2 discussion

### 2. Soften Causal Claims (Must-fix)
**Source:** GPT R1 and R2
**Action:** Changed "causal effect" → "within-market effect" in abstract and introduction. Added caveat that null finding may partly reflect measurement limitations.
**Location:** Abstract, Introduction, Results

### 3. Prose Improvements
**Source:** Prose review (Gemini)
**Action:** Removed roadmap paragraph; strengthened conclusion's final sentence.
**Location:** Introduction (p4), Conclusion

### 4. Numerical Consistency (Already fixed in advisor rounds)
**Source:** All advisor reviews
**Action:** All coefficients, SEs, and table values now match precisely across text and tables. Key fixes: N=5 not N=6 for median price peak; 4-decimal precision in Table 2; SE columns added to robustness table.

## Changes NOT Made (with rationale)
- **Manufacturer-level competition measure:** Would require re-engineering the ANDA-to-NADAC crosswalk, which is complex due to naming conventions. Acknowledged as future work.
- **Persistent-entry filter:** Would substantially reduce already-small event sample. Noted in limitations.
- **Heterogeneity analysis:** The non-parametric specification already shows effects by N level; formal interaction terms would add complexity without changing the main finding.
- **Event study figure:** Individual coefficients have SEs ~2000; a figure would be uninformative. Honestly described as imprecise.
