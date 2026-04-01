## Discovery
- **Idea selected:** idea_0596 — Cross-EU staggered adoption of VAT receipt lotteries with 3 cancellation reversals
- **Data source:** Eurostat API (VAT revenue, GDP) + EC/CASE VAT Gap Reports (hand-coded from published tables)
- **Key risk:** Only 9 treated countries (small N); VAT gap is an estimated construct, not directly observed

## Execution
- **What worked:** Eurostat API fetched data cleanly; balanced panel of 27 EU member states × 17 years. Callaway-Sant'Anna estimator produced clear group-time ATTs.
- **What didn't:** CS estimator had convergence issues with small cohort sizes (many groups produced NA standard errors). The never-treated group warning suggests the data structure was borderline for CS. Sun-Abraham event study had severe collinearity.
- **Key finding:** Credible null. TWFE shows -2.05 pp (marginal) but CS shows +1.29 pp (insignificant). Sign reversal is a clean TWFE contamination example. Cancellation reversals in all 3 countries show gaps FALLING after cancellation — strong falsification.
- **Review feedback adopted:** Added explicit event-study dynamics paragraph reporting CS pre-treatment coefficients; strengthened cancellation discussion with concurrent reforms context; added power calculation paragraph (MDE ~4-5 pp).
- **Lesson for future:** Cross-country DiD with EU member states as units works methodologically but small N limits power. The design is best for detecting large effects. For subtler mechanisms, within-country variation (firm-level, sector-level) would be more powerful.
