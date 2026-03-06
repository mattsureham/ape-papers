## Discovery
- **Policy chosen:** Grand Paris Express construction-phase capitalization — first causal study of Europe's largest metro expansion using universe transaction data. The multi-milestone decomposition (announcement/construction/opening) is genuinely novel.
- **Ideas rejected:** (1) Energy transition plant closures — fatal N problem (France has ~4 coal plants), endogenous closure timing. (2) Open data mandate — 3,500 population threshold confounded with electoral rule changes (scrutin de liste + gender parity), making RDD exclusion restriction invalid.
- **Data source:** CEREMA DVF+ (2014-2025, geolocated universe transactions) + SmartIDF GPE station API + SIRENE establishment registry. DVF+ extends pre-period to 2014, critical for addressing anticipation concerns.
- **Key risk:** Announcement capitalization may be largely complete by 2014 (GPE announced 2010, DUP 2015-2017). Construction-phase effects may be small or masked by disamenities. Framing must emphasize the timing decomposition as the contribution, not the existence of capitalization per se.

## Review
- **Advisor verdict:** 3 of 4 PASS (after 6 rounds of fixes — internal consistency errors dominated early rounds)
- **Top criticism:** Limited pre-period for 5/8 early-treated lines means identification relies heavily on cross-sectional within-commune variation, not clean temporal pre/post. Both GPT reviewers flagged this as fatal to strong causal claims.
- **Surprise feedback:** The CS-DiD implementation was challenged not just for imprecision but for conceptual validity — commune-level aggregation blurs within-commune treatment variation. This is a real issue we had not fully appreciated.
- **What changed:** (1) Tempered all causal language to "suggestive evidence" / "association" throughout. (2) Added explicit within-commune spatial parallel trends discussion as primary threat. (3) Reframed CS as "suggestive only" with honest limitations. (4) Sharply reduced post-opening interpretation (exploratory only). (5) Qualified welfare calculations as illustrative upper bounds. (6) Applied prose review suggestions (hook opening, humanized magnitude, cleaner results narration).

## Summary
- **What worked:** Novel question (construction disamenity understudied), massive dataset (785K transactions), clean story with intuitive distance gradient. Leave-one-line-out stability was particularly compelling.
- **What didn't:** Data window starting in 2020 when 5/8 lines already under construction severely limits temporal identification. This was known from discovery but underestimated as a constraint.
- **Lesson for future:** When staggered treatment timing is the identification source, ensure the data window covers substantial pre-treatment periods for a majority of treated cohorts. A design where most units are "always treated" in the sample is closer to cross-sectional than DiD.
