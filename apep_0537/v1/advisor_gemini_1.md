# Advisor Review - Gemini-3-Flash

**Role:** Academic advisor checking for fatal errors
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T13:14:24.233511
**Route:** Direct Google API + PDF
**Paper Hash:** 74e3a7029c0eed10
**Tokens:** 20918 in / 841 out
**Response SHA256:** d19b63142bfefdbc

---

I have reviewed the draft paper "Is Generative AI Seniority-Biased? Evidence from U.S. Occupational Employment Data" for fatal errors.

**FATAL ERROR 1: Internal Consistency**
- **Location:** Table 1 (page 10) vs. Figure 1 (page 11) and Abstract (page 1).
- **Error:** The employment shares for seniority tiers are inconsistent. Table 1 reports the "Mean" share for Entry-Level as 0.483 and Senior as 0.306. However, Figure 1 and the Abstract state that in 2015, Entry-Level was 50.2% and Senior was 29.0%, and by 2024, they were 45.7% and 33.3% respectively. A mean of 0.483 is mathematically impossible if the values never exceed 0.502 and 0.457 (the average of the 2015 and 2024 endpoints alone is 0.4795, and the figure shows a decline, suggesting the mean should be lower than the starting point but higher than the endpoint). More importantly, Figure 5 (page 38) shows "High AI Exposure" senior shares starting near 50%, while Table 1 says the "Max" senior share is 0.333.
- **Fix:** Ensure the summary statistics in Table 1 correctly reflect the data used in the figures and the text.

**FATAL ERROR 2: Internal Consistency**
- **Location:** Figure 3 (page 21) and text in Section 5.5 (page 20).
- **Error:** The text on page 20 states "High-AI-exposure industries had markedly lower entry-level shares throughout the sample (22–27%), while low-exposure industries maintained shares around 77–80%." However, Figure 3 shows the *red* line (High AI) at the bottom (20% range) and the *green* line (Low AI) at the top (80% range). This contradicts the national averages in Table 1, where the Entry-Level mean is ~48%. If one-third of industries (a tercile) are at 20% and another third are at 80%, the mean would be at least 33% from those two groups alone, but the aggregate trends in Figure 1 show the Entry-Level share is the *higher* line (starting at 50%), while Figure 3 shows the High-AI Entry-Level share is the *lower* line.
- **Fix:** Re-check the labeling of Figure 3 and the calculation of tercile shares to ensure they aggregate to the national figures shown in Figure 1.

**FATAL ERROR 3: Regression Sanity**
- **Location:** Table 3, Column 4 (page 16).
- **Error:** The coefficient for "High AI × Jr. × Post" is reported as -0.2705 with a t-stat of -5.30. In log-employment specifications (ln(Occ Emp)), a coefficient of -0.27 implies a ~24% decline ($1 - e^{-0.27}$) in employment for that group. However, the Abstract and Main Results (page 14) claim the effect is "1.8 percentage points." While shares and logs are different units, the text on page 18 refers to this specific -0.27 coefficient as the "strongest result," but it is an order of magnitude larger than the shifts described in the employment share levels.
- **Fix:** Verify if the dependent variable in Table 3 Column 4 is scaled correctly or if there is a units mismatch between the text's description and the table.

**ADVISOR VERDICT: FAIL**