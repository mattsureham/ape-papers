## Discovery
- **Idea selected:** idea_1827 — Good Samaritan Laws and treatment entry (novel angle on well-studied policy)
- **Data source:** CMS Medicaid SDUD (pivoted from TEDS-A due to access restrictions) — buprenorphine prescriptions as MAT proxy
- **Key risk:** Medicaid expansion as confound (both policies adopted ~2014)

## Execution
- **What worked:** The triple-difference (bup vs opioid painkillers) is a powerful built-in mechanism test. Clean pre-trends in the event study. The "sorting device" framing is compelling.
- **What didn't:** SAMHSA blocked all automated access to TEDS-A PUF files (403 on every URL pattern). Census population API was unreliable. The opioid placebo also trends up post-treatment, complicating the simple DiD interpretation.
- **Review feedback adopted:** Clarified 2.6 log-point magnitude interpretation; added explicit acknowledgment of data pivot from TEDS-A; expanded limitations section to address extensive vs. intensive margin, Medicaid expansion symmetry assumption, and alternative mechanisms.
