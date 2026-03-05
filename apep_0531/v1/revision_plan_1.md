# Revision Plan (Round 1)

## Summary of Reviewer Feedback

Three external reviewers (GPT-5.2: R&R, Grok-4.1-Fast: Minor Revision, Gemini-3-Flash: Minor Revision) plus one internal review (Minor Revision). Key themes:

### Must-Address Issues

1. **Population denominator (all reviewers):** The fixed-share population allocation using 2010 officer shares is unconventional. Acknowledge limitation more formally; note ONS force-area estimates as future robustness check.

2. **Bell et al. (2016) citation (Grok):** Add citation to Section 6.2 comparing civilian vs. sworn staff effects. **Done — added to paper.tex and references.bib.**

3. **Fraud panel clarity (Grok):** Clarify in Table 3 caption that fraud data runs 2008-2013 only. **Done — updated table footnote.**

### Addressed in Reply (No Code Changes Needed)

4. **Identification without IV (GPT):** Acknowledged as limitation. The continuous dose-response design, flat pre-trends, and conservative null interpretation collectively strengthen the TWFE approach. Shift-share design noted as future work.

5. **Bad control concern for sworn officers (GPT):** Clarified that Columns 1 and 2 represent different estimands (total vs. direct effect).

6. **Only 2 pre-treatment years (GPT):** Data constraint — crime data begins 2007/08.

7. **Welsh forces exclusion (Grok):** Manual harmonization feasible but risks measurement error; noted explicitly.

8. **Reporting rates / CSEW data (Gemini):** Expanded limitations discussion; CSEW at PFA level not publicly available.

9. **Task substitution (Gemini):** Already discussed in Section 6.1.

## Changes Made

- Added Bell et al. (2016) citation to Section 6.2
- Added `bell2016police` bib entry
- Recompiled PDF (32 pages, no undefined references)
- Updated lessons.md with Review section
