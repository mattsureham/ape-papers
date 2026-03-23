# Research Plan: The Goldilocks Examiner

## Research Question

Does examiner-driven patent claim narrowing during prosecution affect follow-on innovation by competitors? Specifically, do stricter examiners — who force applicants to narrow claims more — paradoxically promote technology diffusion by creating patents that are easier to design around?

## Identification Strategy

**Examiner IV design (two-stage):**

1. **Extensive margin (standard):** Leave-one-out examiner grant rate within Art Unit × year → patent grant. This replicates the standard Sampat-Williams (2019) / Farre-Mensa et al. (2020) design.

2. **Intensive margin (novel):** Leave-one-out examiner average claim narrowing (change in words per independent claim from application to grant) within Art Unit × year → patent scope → follow-on innovation. This is the paper's main contribution.

**Identifying assumption:** Within Art Unit × year, patent applications are quasi-randomly assigned to examiners. Conditional on Art Unit × year fixed effects, examiner identity is orthogonal to application quality. This is the standard assumption in the examiner-IV literature, supported by USPTO's assignment protocol.

**Key advantages:**
- Cross-sectional IV avoids pre-trends concerns entirely
- 9,253 examiner-Art Unit × year cells with 20+ patents each
- P10-P90 examiner spread of 91 words = large, credible first stage
- Separates extensive margin (grant vs. deny) from intensive margin (scope conditional on grant)

## Expected Effects and Mechanisms

**Primary hypothesis (Scope Paradox):** Stricter examiners → narrower patents → MORE follow-on citations by competitors, because narrow claims leave more "white space" for design-arounds and incremental improvements.

**Alternative:** Stricter examiners → narrower patents → FEWER follow-on citations, because narrow patents signal less valuable underlying inventions (selection) or because narrow scope discourages follow-on by making the original patent less blocking.

**Mechanism tests:**
- Self-citations vs. other-citations (narrow scope should increase OTHER-citations if design-around mechanism)
- Citations by small vs. large firms (small firms more constrained by broad patents)
- Technology classes with more vs. fewer substitution possibilities

## Primary Specification

**First stage:**
```
ClaimNarrowing_ij = α + β × ExaminerAvgNarrowing_{-i,j} + Art_Unit_Year_FE + ε_ij
```

**Second stage (reduced form preferred for V1):**
```
ForwardCitations_ij = α + γ × ExaminerAvgNarrowing_{-i,j} + Art_Unit_Year_FE + ε_ij
```

Where:
- i = patent application
- j = examiner × Art Unit × year cell
- ClaimNarrowing = change in words per independent claim (granted − filed)
- ExaminerAvgNarrowing = leave-one-out mean of ClaimNarrowing for examiner j
- ForwardCitations = citations received from other patents within 5 years

**Clustering:** Standard errors clustered at the examiner level (the level of treatment assignment).

## Data Source and Fetch Strategy

**All data from Google BigQuery** (project: scl-librechat, confirmed accessible):

1. `patents-public-data.uspto_oce_pair.application_data` — 9.8M applications with examiner identity, Art Unit, filing/grant dates
2. `patents-public-data.uspto_oce_office_actions.office_actions` — 4.4M office actions with rejection codes
3. `patents-public-data.patents.publications` — Patent documents with claim text (pre-grant publications + grants)

**Construction steps:**
1. Match pre-grant publications (kind_code = A1/A2) to granted patents (kind_code = B1/B2) by application number
2. Compute claim narrowing: words in independent claims at grant minus words at filing
3. Merge with PAIR application data for examiner identity and Art Unit
4. Compute leave-one-out examiner averages within Art Unit × year
5. Count forward citations within 5-year windows from grant date
6. Restrict to filing years 2005-2015 (to allow 5+ year citation windows)

**Sample:** ~1M granted patents with matched pre-grant publications, examiner identity, and forward citation counts.
