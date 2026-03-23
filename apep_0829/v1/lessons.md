## Discovery
- **Idea selected:** idea_0595 — Examiner-driven patent claim variation as IV for scope → follow-on innovation
- **Data source:** PatentsView bulk S3 downloads — BigQuery ADC not configured, pivoted successfully
- **Key risk:** Claim count ≠ patent breadth; total claims conflate independent and dependent claims

## Execution
- **What worked:** PatentsView bulk data is reliable, fast (5 files, ~3GB compressed). First stage F = 3,560 — spectacularly strong instrument. 1.3M patent sample with clean merge across 5 datasets. The "scope dividend" framing gives the paper a named economic object.
- **What didn't:** BigQuery credentials missing forced a pivot from claim-text-narrowing (the original idea) to claim-count-at-grant. This weakens the identification story: we measure examiner leniency on claim count rather than examiner-induced prosecution narrowing. The original manifest's key contribution was using claim narrowing as a continuous scope measure, not just claim count.
- **Review feedback adopted:** (1) Moderated policy conclusion substantially — added caveats about claim count as imperfect scope proxy, examiner IV capturing bundle of behaviors, selection into grant. (2) Acknowledged independent vs. dependent claim distinction. (3) Toned down "scope dividend" language from causal certainty to "consistent with" framing.
