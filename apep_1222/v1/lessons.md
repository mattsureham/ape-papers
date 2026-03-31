## Discovery
- **Idea selected:** idea_1859 — Mexico's Fondo Minero elimination provides a rare "reverse resource curse" experiment
- **Data source:** SESNSP municipal crime data (GitHub mirror, 519K rows) + SEDATU Fondo Minero distribution PDF (gob.mx)
- **Key risk:** COVID timing (Nov 2020 treatment overlaps pandemic); state×year FE is the insurance

## Execution
- **What worked:** SEDATU PDF parsing with pdftools yielded clean treatment assignment (216 municipalities extracted, 178 matched to INEGI codes). The "violence dividend" narrative emerged from the data — homicides falling while total crime stayed null was the surprising finding that made the paper.
- **What didn't:** DENUE API and datamexico.org API were both unresponsive; had to fall back to PDF extraction + GitHub municipality catalogue for treatment assignment. Population data unavailable (CONAPO URLs dead), used log(count+1) instead.
- **Review feedback adopted:** Added MHT acknowledgment (p=0.048 won't survive Bonferroni), noted cleaner homicide pre-trends, fixed overclaim about CI interpretation. Reviewers unanimously flagged: (1) treatment matching (178/277), (2) no dose-response, (3) mechanism needs fiscal data, (4) control group too broad. All valid V2 priorities.
