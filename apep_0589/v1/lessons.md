## Discovery
- **Policy chosen:** EU ERDF 75% GDP/capita threshold graduation — treatment withdrawal provides a novel angle on a well-known institutional feature
- **Ideas rejected:** Geo-Blocking DDD (HICP too indirect for online prices), PSD2 (thin data, soft outcome), Posted Workers Directive (COVID-19 confound fatal), Schengen 2007 (GFC confound, single treatment date), Bank Branch Closures (complex Bartik identification, political outcome)
- **Data source:** Eurostat tgs00006 + cohesiondata.ec.europa.eu — both open, no API keys, confirmed working
- **Key risk:** Mean reversion — regions crossing 75% may naturally slow in growth. Addressed via donut holes, pre-trend tests, and fuzzy specification using actual ERDF payments

## Review
- **Advisor verdict:** 4 of 4 PASS (after 6 rounds of fixes)
- **Top criticism:** Running variable (2008-2010) overlaps with pre-period outcome (2007-2013), creating mean-reversion concern. Also: no formal first-stage funding discontinuity at cutoff.
- **Surprise feedback:** Both GPT reviewers identified the event study as "not a true RD event study" — it's a panel comparison, not a local RD design. Valid critique.
- **What changed:** (1) Added EU-only sample and non-overlapping outcome in new appendix, (2) Added first-stage ERDF discontinuity estimate, (3) Relabeled event study as "descriptive complement", (4) Changed all formal labels from "Graduated" to "Above 75%", (5) Expressed Mfg GVA in pp for unit consistency, (6) Removed placeholder contributor fields, (7) Softened language throughout from "withdrawal" to "threshold classification"
