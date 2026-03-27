## Discovery
- **Idea selected:** idea_1912 — SVB + SCI shift-share; compelling because it separates real social ties from social media and balance-sheet channels
- **Data source:** SCI (Azure), FDIC SOD (API), BEA (API), QWI (API) — all free, no access issues
- **Key risk:** Confounding from tech sector concentration; addressed with NAICS 51 controls and JPM placebo

## Execution
- **What worked:** The JPMorgan non-failing-bank placebo (4,818 branches → precisely estimated zero) is the strongest piece of evidence. Five pre-period placebos all null.
- **What didn't:** Initial analysis included SVB deposits in the outcome, producing a negative coefficient consistent with contagion. Reviews correctly identified this as mechanical. Also miscoded tech_share by dividing NAICS 51 emp by NAICS 51 total emp (≈1.0) instead of by total county emp.
- **Review feedback adopted:** (1) Excluded SVB/Signature/First Republic deposits from outcome — revealed the sign flip from negative to positive. (2) Fixed tech employment share variable. (3) Extended SOD back to 2017 for 5 pre-periods.
- **Key lesson:** Always decompose aggregate outcomes before claiming contagion. The same data tells opposite stories depending on whether failed-institution deposits are included.
