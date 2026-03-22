## Discovery
- **Idea selected:** idea_1652 — "Who Counts the Dead?" — coroner vs ME and opioid death misclassification. Chosen for sharp within-state identification, massive sample (3,143 counties), theory-matched placebos, and memorable "detection gap" mechanism.
- **Data source:** CDC COMEC county MDI classifications + NCHS model-based drug overdose estimates. COMEC CSV URL was not at the Socrata endpoint guessed from the manifest; required web search to find the correct CDC COMEC page. The model-based estimates (dataset rpvx-m2md) were a better find than the range-based data initially identified.
- **Key risk:** Outcome is total OD rate, not unspecified share — this limits the directness of the misclassification claim.

## Execution
- **What worked:** Border-county pair design with 331 cross-MDI pairs across 13 mixed states. Detection gap of -2.58 per 100K is robust across specs. Time-varying result (widening from -2.0 to -4.5) is the strongest evidence for the measurement-error interpretation. RI p-value of 0.005 addresses few-cluster concern.
- **What didn't:** Could not access county-level ICD-10 contributing cause codes (T50.9 vs T40.x) through free APIs — this limits the paper to indirect evidence. County-level non-drug cause-specific mortality for placebos also not freely available. Balance within border pairs shows population and racial composition differ, which requires reliance on controls.
- **Review feedback adopted:** Added balance test results, limitations paragraphs on model-based smoothing and outcome measurement, sensitivity range for national undercount (766-2,356), and softened extrapolation language.
