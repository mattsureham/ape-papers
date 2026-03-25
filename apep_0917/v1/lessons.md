## Discovery
- **Idea selected:** idea_1892 — regulatory leakage through federal equitable sharing, chosen for 37+ treated states, agency-level microdata, and portable mechanism
- **Data source:** DOJ ESAC FOIA (29MB zip, relational database format) — required joining certification, income, and agency tables
- **Key risk:** Federal policy changes (Holder 2015, Sessions 2017) could confound, but absorbed by year FEs

## Execution
- **What worked:** The ESAC data is excellent — 67K records, 7,600 agencies, 9 fiscal years. The relational structure was initially confusing but well-organized once parsed. CS-DiD ran cleanly with never-treated comparison group.
- **What didn't:** CS-DiD standard errors are ~10x larger than TWFE (1.60 vs 0.15), making the robust estimator uninformative on its own. The smoke test patterns (NE +59%, MT +167%) did not survive causal analysis — a reminder that descriptive pre/post comparisons mislead.
- **Review feedback adopted:** Added event-study table, MDE discussion, conditional-on-positive intensive margin check, clarified CS-DiD SE inflation.
