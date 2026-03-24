## Discovery
- **Idea selected:** idea_1805 — NWS WFO boundary discontinuity for tornado warning quality. Selected for clean spatial RDD, large public datasets, first-order welfare question (deaths/injuries), and zero prior economics work.
- **Data source:** SPC tornado records + IEM Cow API + NWS CWA shapefiles + Census ACS — SPC downloaded cleanly; IEM API needed rate-limiting workaround (0.5s delays, 4-year windows); NCEI bulk download was 404 but SPC had equivalent data; NWS shapefile URL had changed from manifest.
- **Key risk:** Power for mortality (rare event). Addressed by using injuries as primary outcome.

## Execution
- **What worked:** Boundary-pair FE design produced clean results — both placebos (property damage, EF-scale) were null. Leave-one-WFO-out was rock-solid. The counterintuitive positive coefficient on lead time was a genuine finding, not a bug.
- **What didn't:** IEM API field names have units in brackets (avg_leadtime[min]) which broke first parsing attempt. NWS shapefile URL changed since idea generation. Time-invariant treatment is the main identification weakness — reviewers rightly flagged this.
- **Review feedback adopted:** Toned down mechanism claims (FAR is imprecise, not a smoking gun). Added explicit discussion of WFO-level omitted variables as alternative explanation. Expanded limitations section. Did not add event-level lead time (not feasible in V1 scope).
